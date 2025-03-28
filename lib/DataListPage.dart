import 'package:flutter/material.dart';

class DataListPage extends StatelessWidget {
  final List<String> fileList;
  final Function(String) sendReadCommand;

  const DataListPage({Key? key, required this.fileList, required this.sendReadCommand}) : super(key: key);

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
                                      Text('파일명: $fileName'),
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
                                        Navigator.of(context).pop();
                                        // 파일 이름에서 확장자 제거 (.bin)
                                        String fileNameWithoutExtension = fileName.split('.').first.split('|').first;
                                        print("✅ fileNameWithoutExtension: "  + fileNameWithoutExtension);
                                        String fileNameWithoutbin = fileName.split('|')[1];

                                        // 시작 시간과 종료 시간을 DateTime 형식으로 변환
                                        DateTime startTime = DateTime.parse('25${fileNameWithoutExtension.substring(0, 6)} ${fileNameWithoutExtension.substring(6, 8)}:${fileNameWithoutExtension.substring(8, 10)}');
                                        DateTime endTime = DateTime.parse('25${fileNameWithoutbin.substring(0, 6)} ${fileNameWithoutbin.substring(6, 8)}:${fileNameWithoutbin.substring(8, 10)}');

                                        // 시간 차이 계산
                                        Duration timeDifference = endTime.difference(startTime);

                                        // 조건에 따른 명령어 전송
                                        if (timeDifference.inMinutes >= 2) {
                                          sendReadCommand(fileNameWithoutExtension);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('❌ 2분 이상의 시간 차이가 필요합니다.')),
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
                            child: Center(
                              child: Text(
                                fileName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
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
