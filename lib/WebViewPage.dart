import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aground/BluetoothPage.dart';

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
      ..setNavigationDelegate(
        NavigationDelegate(
          // 필요시 콜백 추가
        ),
      )
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

          if (userCode != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BluetoothPage(
                  imageUrl: imageUrl,
                  userCode: userCode,
                  matchCode: matchCode,
                ),
              ),
            );
          }
        },
      );

    // loadRequest 이후에 enableZoom(false) 호출
    _controller.loadRequest(Uri.parse('https://agrounds.com/app/')).then((_) {
      _controller.enableZoom(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(controller: _controller),
    );
  }
}
