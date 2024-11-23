import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPage extends StatefulWidget {
  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  List<ScanResult> _scanResults = [];

  @override
  void initState() {
    super.initState();
    // 블루투스 어댑터 상태 구독
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        _adapterState = state;
      });
    });
  }

  @override
  void dispose() {
    // 구독 취소
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    super.dispose();
  }

  Future<void> enableBluetooth() async {
    try {
      // 권한 요청
      if (await Permission.bluetooth.isDenied) {
        await Permission.bluetooth.request();
      }

      // 블루투스 활성화 시도
      if (_adapterState != BluetoothAdapterState.on) {
        if (Platform.isAndroid) {
          await FlutterBluePlus.turnOn();
        } else if (Platform.isIOS) {
          throw PlatformException(
            code: 'iOSBluetooth',
            message: 'iOS에서는 블루투스를 수동으로 활성화해야 합니다.',
          );
        }

        if (_adapterState != BluetoothAdapterState.on) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('블루투스를 수동으로 활성화해주세요.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is PlatformException
              ? e.message ?? '알 수 없는 오류가 발생했습니다.'
              : '블루투스를 활성화하는 중 오류가 발생했습니다: $e'),
        ),
      );
    }
  }

  void scanForDevices() {
    try {
      setState(() {
        _scanResults.clear(); // 이전 결과 초기화
      });

      // 스캔 시작
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      // 스캔 결과 구독
      _scanResultsSubscription =
          FlutterBluePlus.onScanResults.listen((results) {
            setState(() {
              _scanResults = results;
            });
          });

      // 스캔 종료 후 정리
      FlutterBluePlus.isScanning
          .where((isScanning) => !isScanning)
          .first
          .then((_) => _scanResultsSubscription?.cancel());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('디바이스 검색 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      // 연결 상태 구독
      device.connectionState.listen((connectionState) {
        if (connectionState == BluetoothConnectionState.connected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${device.name} 연결됨'), backgroundColor: Colors.green,),
          );
        } else if (connectionState == BluetoothConnectionState.disconnected) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${device.name} 연결 끊김'), backgroundColor: Colors.red,),
          );
        }
      });

      // 디바이스에 연결
      await device.connect();

      // 서비스 검색 (필요 시)
      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        print('Service UUID: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          print('Characteristic UUID: ${characteristic.uuid}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('디바이스 연결 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Widget _buildBluetoothStatusIcon() {
    IconData iconData;
    Color iconColor;

    switch (_adapterState) {
      case BluetoothAdapterState.on:
        iconData = Icons.bluetooth;
        iconColor = Colors.blue;
        break;
      case BluetoothAdapterState.off:
        iconData = Icons.bluetooth_disabled;
        iconColor = Colors.red;
        break;
      case BluetoothAdapterState.unauthorized:
        iconData = Icons.lock;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.help_outline;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor, size: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Example'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBluetoothStatusIcon(),
          const SizedBox(height: 10),
          Text(
            _adapterState == BluetoothAdapterState.on
                ? "블루투스가 활성화되었습니다."
                : "블루투스가 꺼져있습니다.",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: enableBluetooth,
            child: const Text('블루투스 활성화', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _adapterState == BluetoothAdapterState.on
                ? scanForDevices
                : null,
            child: const Text('디바이스 검색', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final device = _scanResults[index].device;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(
                      device.name.isNotEmpty
                          ? device.name
                          : 'Unknown Device',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('ID: ${device.remoteId}'),
                    onTap: () {
                      connectToDevice(device); // 디바이스 연결 함수 호출
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  // 로그 레벨 설정 (디버깅용)
  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
  runApp(MaterialApp(
    home: BluetoothPage(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}