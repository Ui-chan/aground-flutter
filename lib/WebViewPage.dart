import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aground/BluetoothPage.dart'; // BluetoothPage import

class WebViewPage extends StatefulWidget {
  final Function(BuildContext) onBluetoothRequest;

  const WebViewPage({Key? key, required this.onBluetoothRequest}) : super(key: key);

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  String? userCode;
  String? matchCode;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'UploadChannel',
        onMessageReceived: (JavaScriptMessage message) {
          var data = jsonDecode(message.message);

          setState(() {
            userCode = data['user_code'];
            matchCode = data['match_code'];
            imageUrl = data['url'];
          });

          print('User Code: $userCode');
          print('Match Code: $matchCode');
          print('Image URL: $imageUrl');

          // user_code가 존재하는 경우에만 블루투스 화면으로 전환 요청
          if (userCode != null) {
            // BluetoothPage로 imageUrl 전달
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BluetoothPage(imageUrl: imageUrl, userCode: userCode),
                
              ),
            );
          }
        },
      )
      ..loadRequest(Uri.parse('https://agrounds.com/app/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller), // AppBar 제거
    );
  }
}
