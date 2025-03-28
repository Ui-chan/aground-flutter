import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'package:aground/DataListPage.dart';
import 'package:http/http.dart' as http; // HTTP 패키지 추가

StreamSubscription<List<int>>? _responseSubscription;

class BluetoothPage extends StatefulWidget {
  final String? imageUrl; // WebViewPage에서 받아올 imageUrl
  final String? userCode; // WebViewPage에서 받아올 userCode

  const BluetoothPage({Key? key, this.imageUrl, this.userCode}) : super(key: key);

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _responseCharacteristic;
  String responseText = "No response yet";
  bool isDeviceConnected = false;
  bool isScanning = false; // 검색 중인지 여부
  String? _bluetoothDeviceNumber; // 추출된 Bluetooth 장치 번호
  String connectionStatus = ""; // 연결 상태 ("success", "failure")

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
      });
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    _disconnectDevice();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request();
    } else if (Platform.isIOS) {
      await Permission.bluetooth.request();
    }
  }

  void scanForDevices() {
    try {
      print("🔵 [DEBUG] 블루투스 검색 시작...");
      setState(() {
        isScanning = true;
        _scanResults.clear(); // 이전 결과 초기화
        connectionStatus = ""; // 연결 상태 초기화
      });

      FlutterBluePlus.startScan();

      _scanResultsSubscription = FlutterBluePlus.onScanResults.listen((results) {
        setState(() {
          for (var result in results) {
            if (result.device.name.startsWith("AGROUNDS_")) {
              // 중복 제거
              if (!_scanResults.any((r) => r.device.remoteId == result.device.remoteId)) {
                _scanResults.add(result);
              }
            }
          }
        });
      });

      Future.delayed(const Duration(seconds: 3)).then((_) {
        FlutterBluePlus.stopScan();
        _scanResultsSubscription?.cancel();
        setState(() {
          isScanning = false;
          connectionStatus = _scanResults.isEmpty ? "failure" : "";
        });
        print("✅ [DEBUG] 블루투스 검색 완료. 총 ${_scanResults.length}개 디바이스 발견됨.");
      });
    } catch (e) {
      print("❌ [ERROR] 블루투스 검색 중 오류 발생: $e");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print("🔵 [DEBUG] ${device.name} (ID: ${device.remoteId}) 연결 시도...");

      if (_connectedDevice != null) {
        print("🟠 [DEBUG] 기존 연결 해제: ${_connectedDevice!.name}");
        await _connectedDevice!.disconnect();
        setState(() {
          _connectedDevice = null;
        });
      }

      await device.connect();
      setState(() {
        _connectedDevice = device;
        isDeviceConnected = true;
        connectionStatus = "success";
      });

      print("✅ [DEBUG] ${device.name} 연결 성공!");

      // 연결된 장치 이름에서 숫자 부분 추출
      if (device.name.startsWith("AGROUNDS_")) {
        _bluetoothDeviceNumber = device.name.substring(9); // "AGROUNDS_" 이후의 문자열 추출
        print("✅ [DEBUG] 추출된 Bluetooth 장치 번호: $_bluetoothDeviceNumber");
      } else {
        _bluetoothDeviceNumber = null;
        print("⚠️ [DEBUG] 연결된 Bluetooth 장치 이름이 'AGROUNDS_'로 시작하지 않습니다.");
      }

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            _commandCharacteristic = characteristic;
          }
          if (characteristic.properties.notify) {
            _responseCharacteristic = characteristic;
          }
        }
      }
    } catch (e) {
      print("❌ [ERROR] ${device.name} 연결 실패: $e");
      setState(() {
        connectionStatus = "failure";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${device.name} 연결 실패: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      if (_connectedDevice != null) {
        print("🔴 [DEBUG] ${_connectedDevice!.name} 연결 해제 중...");
        await _connectedDevice!.disconnect();
        print("✅ [DEBUG] ${_connectedDevice!.name} 연결이 정상적으로 해제됨.");

        setState(() {
          _connectedDevice = null;
          _commandCharacteristic = null;
          _responseCharacteristic = null;
          isDeviceConnected = false;
          responseText = "No response yet";
          _scanResults.clear();
          _bluetoothDeviceNumber = null; // 연결 해제 시 Bluetooth 장치 번호 초기화
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🔴 ${_connectedDevice!.name} 연결 해제됨"), backgroundColor: Colors.red),
        );
      } else {
        print("⚠️ [DEBUG] 연결된 블루투스 기기가 없습니다.");
      }
    } catch (e) {
      print("❌ [ERROR] 연결 해제 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 연결 해제 중 오류 발생: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> sendListCommand() async {
    if (_connectedDevice == null || _commandCharacteristic == null || _responseCharacteristic == null) {
      print("❌ [ERROR] 블루투스 연결 또는 특성이 설정되지 않았습니다.");
      return;
    }

    try {
      print("🔵 [DEBUG] 'list' 명령어 전송 중...");

      // 이전 리스너 제거
      await _responseSubscription?.cancel();

      String fullResponse = "";
      bool isResponseComplete = false;

      await _responseCharacteristic!.setNotifyValue(false);
      await _responseCharacteristic!.setNotifyValue(true);

      _responseSubscription = _responseCharacteristic!.value.listen((value) {
        String response = utf8.decode(value);
        print("✅ [DEBUG] 받은 응답: $response");

        if (response.trim() != "list") {
          fullResponse += response;
        }

        if (response.contains(".bin")) {
          // 파일 목록을 모두 받았다고 가정
          isResponseComplete = true;
          print("🏁 [DEBUG] 최종 응답: $fullResponse");
          List<String> fileList = fullResponse
              .split(',')
              // .where((file) => file.trim().endsWith('.bin'))
              .toList();
          setState(() {
            responseText = fullResponse;
          });
          _responseSubscription?.cancel(); // 리스너 제거

          // DataListPage로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DataListPage(
                fileList: fileList,
                sendReadCommand: sendReadCommand, // 콜백 함수 전달
              ),
            ),
          );
        }
      });

      await _commandCharacteristic!.write(utf8.encode("list"));

      // 5초 후에도 응답이 완료되지 않으면 타임아웃 처리
      await Future.delayed(Duration(seconds: 20));
      if (!isResponseComplete) {
        print("⏰ [DEBUG] 응답 타임아웃");
        _responseSubscription?.cancel();
      }
    } catch (e) {
      print("❌ [ERROR] 'list' 명령어 전송 중 오류 발생: $e");
    }
  }

  Future<void> sendReadCommand(String fileName) async {
    if (_connectedDevice == null || _commandCharacteristic == null || _responseCharacteristic == null) {
      print("❌ [ERROR] 블루투스 연결 또는 특성이 설정되지 않았습니다.");
      return;
    }

    String fullGPSDataText = ""; // 모든 GPS 데이터를 저장할 변수
    String? imageUrl = widget.imageUrl;
    String? userCode = widget.userCode;

    try {
      final command = "read,/$fileName.bin"; // 파일 확장자 다시 추가
      print("🔵 [DEBUG] '$command' 명령어 전송 중...");
      await _commandCharacteristic!.write(utf8.encode(command));

      // 이전에 구독중인 스트림이 있다면 취소
      await _responseSubscription?.cancel();

      // 마지막 데이터 수신 시간을 기록할 변수
      DateTime lastDataReceivedTime = DateTime.now();

      // 스트림 종료 여부를 확인할 변수
      bool isStreamClosed = false;

      _responseSubscription = _responseCharacteristic!.value.listen((value) async {
        // GPS 데이터 변환 및 출력
        List<GPSData> gpsDataList = parseGPSData(value);
        if (gpsDataList.isNotEmpty) {
          // 파일명에서 확장자 제거 (예: 2502211355.bin -> 2502211355)
          String baseName = fileName; // 변경된 파일 이름 사용

          // 추출된 Bluetooth 장치 번호 가져오기
          String? bluetoothDeviceNumber = _bluetoothDeviceNumber;

          // GPS 데이터를 텍스트로 변환
          String gpsDataText = gpsDataList.map((gpsData) => "${bluetoothDeviceNumber}/$baseName/${gpsData.latitude}/${gpsData.longitude}").join("\n");

          fullGPSDataText += gpsDataText; // 모든 GPS 데이터를 하나의 문자열에 추가

          // 지정된 형식으로 출력
          gpsDataList.forEach((gpsData) {
            print("✅ [DEBUG] $baseName/${gpsData.latitude}/${gpsData.longitude}");
          });

          // 마지막 데이터 수신 시간 갱신
          lastDataReceivedTime = DateTime.now();
        }

        fullGPSDataText += "\n";
      }, onDone: () async {
        print("✅ [DEBUG] 스트림 완료");
        _responseSubscription?.cancel();
        isStreamClosed = true;
      }, onError: (error) {
        print("❌ [ERROR] 스트림 오류: $error");
        _responseSubscription?.cancel();
        isStreamClosed = true;
      });

      // 1초 동안 데이터가 수신되지 않으면 스트림을 종료
      Timer.periodic(Duration(seconds: 1), (timer) async {
        if (DateTime.now().difference(lastDataReceivedTime).inSeconds >= 1 && !isStreamClosed) {
          await _responseSubscription?.cancel();
          isStreamClosed = true;
          timer.cancel();

          print("✅ [DEBUG] 스트림 종료 후 데이터 업로드 시작");
          final String filePath = "${imageUrl}${userCode}_$fileName.txt";
          final response = await http.put(
            Uri.parse(filePath),
            headers: {"Content-Type": "text/plain"},
            body: fullGPSDataText,
          ).timeout(Duration(seconds: 30));

          if (response.statusCode == 200) {
            print("✅ [DEBUG] 텍스트 파일 저장 성공: ${imageUrl}");
          } else {
            print("❌ [ERROR] 텍스트 파일 저장 실패 (Status Code: ${response.statusCode}): ${imageUrl}");
            print("❌ [ERROR] Response body: ${response.body}");
          }
        }
      });
    } catch (e) {
      print("❌ [ERROR] 'read' 명령어 전송 중 오류 발생: $e");
      await _responseSubscription?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Example')),
      body: Center(
        child: isScanning
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("기기를 찾는 중...", style: TextStyle(fontSize: 18)),
                ],
              )
            : connectionStatus == "success"
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 100, color: Colors.green),
                      SizedBox(height: 20),
                      Text("기기가 연결되었습니다!", style: TextStyle(fontSize: 18)),
                      ElevatedButton(
                        onPressed: sendListCommand,
                        child: Text("확인"),
                      ),
                    ],
                  )
                : connectionStatus == "failure"
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 100, color: Colors.grey),
                          SizedBox(height: 20),
                          Text("연결된 기기가 없습니다.", style: TextStyle(fontSize: 18)),
                          ElevatedButton(
                            onPressed: scanForDevices,
                            child: Text("재확인"),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _adapterState == BluetoothAdapterState.on ? Icons.bluetooth : Icons.bluetooth_disabled,
                            color: _adapterState == BluetoothAdapterState.on ? Colors.blue : Colors.red,
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            _adapterState == BluetoothAdapterState.on ? "블루투스가 활성화되었습니다." : "블루투스가 꺼져있습니다.",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _adapterState == BluetoothAdapterState.on ? scanForDevices : null,
                            child: Text('디바이스 검색'),
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: _scanResults.isEmpty
                                ? Text("검색된 디바이스가 없습니다.")
                                : ListView.builder(
                                    itemCount: _scanResults.length,
                                    itemBuilder: (context, index) {
                                      final device = _scanResults[index].device;
                                      return ListTile(
                                        leading: Icon(Icons.bluetooth),
                                        title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
                                        subtitle: Text('ID: ${device.remoteId}'),
                                        onTap: () => connectToDevice(device),
                                      );
                                    },
                                  ),
                          ),
                          SizedBox(height: 20),
                          Text('응답: $responseText'),
                        ],
                      ),
      ),
    );
  }
}

/// 📌 GPS 데이터 클래스
class GPSData {
  final String utc;
  final double latitude;
  final double longitude;

  GPSData({required this.utc, required this.latitude, required this.longitude});
}

/// 📌 UTC 값 (hhmmss)을 시, 분, 초로 변환하는 함수
String convertUTCtoTime(int utc) {
  int hours = (utc ~/ 10000) % 24; // 시 (24시간제)
  int minutes = (utc ~/ 100) % 100; // 분
  int seconds = utc % 100; // 초
  return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
}

double convertDMMtoDD(double dmm) {
  int degrees = (dmm / 100).floor();
  double minutes = dmm % 100;
  return degrees + (minutes / 60);
}

/// 📌 GPS 데이터를 변환하는 함수 (UTC 시간 포함)
List<GPSData> parseGPSData(List<int> value) {
  List<GPSData> gpsDataList = [];
  for (int i = 0; i < value.length; i += 12) {
    if (i + 12 > value.length) break;
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(value.sublist(i, i + 12)));

    // UTC 시간 변환
    int rawUtc = byteData.getUint32(0, Endian.little);
    String utcTime = convertUTCtoTime(rawUtc);

    // 위도 (DMM to DD)
    double latitudeDMM = byteData.getFloat32(4, Endian.little);
    double latitude = convertDMMtoDD(latitudeDMM);

    // 경도 (DMM to DD)
    double longitudeDMM = byteData.getFloat32(8, Endian.little);
    double longitude = convertDMMtoDD(longitudeDMM);

    // 유효 범위 검사: 위도는 -90 ~ 90, 경도는 -180 ~ 180
    if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
        && latitude != 0.0 && longitude != 0.0 // 위도, 경도가 0인 경우 제외
        && latitude.abs() < 1000 && longitude.abs() < 1000
        && latitudeDMM.abs() > 0.0001 && longitudeDMM.abs() > 0.0001) { // DMM 값이 너무 작은 경우 제외
      gpsDataList.add(GPSData(utc: utcTime, latitude: latitude, longitude: longitude));
    } else {
      print("❌ [ERROR] 유효하지 않은 GPS 데이터 발견 (Latitude: $latitude, Longitude: $longitude, LatitudeDMM: $latitudeDMM, LongitudeDMM: $longitudeDMM)");
    }
  }
  print("✅ [DEBUG] GPSData 변환 완료 -> 총 ${gpsDataList.length}개의 데이터 포인트");
  return gpsDataList;
}
