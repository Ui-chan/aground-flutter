import 'package:flutter/material.dart';
import 'BluetoothPage.dart'; // BluetoothPage를 import합니다.
class DataListPage extends StatelessWidget {
  final List<String> fileList;
  final Function(String fileName, String endTimeString) sendReadCommand;


  const DataListPage({Key? key, required this.fileList, required this.sendReadCommand}) : super(key: key);

  /// 파일 이름을 DateTime 형식으로 변환하는 함수
  DateTime parseFileTime(String fileTime) {
    final year = "20${fileTime.substring(0, 2)}";
    final month = fileTime.substring(2, 4);
    final day = fileTime.substring(4, 6);
    final hour = fileTime.substring(6, 8);
    final minute = fileTime.substring(8, 10);

    return DateTime.parse("$year-$month-$day $hour:$minute:00");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          '데이터',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '총 ${fileList.length}개의 데이터',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: fileList.isEmpty
                  ? const Center(
                      child: Text(
                        '데이터가 없습니다.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: fileList.length,
                      itemBuilder: (context, index) {
                        final fileName = fileList[index];
                        final parts = fileName.split('|');
                        final startTimeString = parts[0].substring(0, 12);
                        final endTimeString = parts[1];
                        
                        final startTime = parseFileTime(startTimeString);
                        final endTime = parseFileTime(endTimeString);

                        final playDuration = endTime.difference(startTime).inMinutes;

                        return InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('파일 정보'),
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('파일명: $fileName', style: const TextStyle(fontSize: 14)),
                                      Text('시작 시간: ${startTime.toLocal()}', style: const TextStyle(fontSize: 14)),
                                      Text('종료 시간: ${endTime.toLocal()}', style: const TextStyle(fontSize: 14)),
                                      Text('플레이 시간: $playDuration분', style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('닫기'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('전송'),
                                      onPressed: () {
                                        if (playDuration >= 2) {
                                          print("endTimeString: " + endTimeString);
                                          Navigator.of(context).pop();
                                          sendReadCommand(parts[0].split('.').first,endTimeString);
                                          
                                        } else {
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title:
                                                    const Text('전송 불가', style: TextStyle(color: Colors.red)),
                                                content:
                                                    const Text('플레이 시간이 2분 이상이여야 전송할 수 있습니다.'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child:
                                                        const Text('확인'),
                                                    onPressed:
                                                        () => Navigator.of(context).pop(),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // 왼쪽 상단 날짜 및 시간 정보
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 날짜 표시 (YYYY.MM.DD)
                                      Text(
                                        '${startTime.year}.${startTime.month.toString().padLeft(2, '0')}.${startTime.day.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      // 시작-종료 시간 표시 (HH:mm - HH:mm)
                                      Text(
                                        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ),
                                // 오른쪽 하단 플레이 시간 표시
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: Text(
                                    '$playDuration분',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
