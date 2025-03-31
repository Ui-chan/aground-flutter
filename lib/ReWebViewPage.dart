import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReWebViewPage extends StatelessWidget {
  const ReWebViewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // WebViewController 초기화 및 설정
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://agrounds.com/app/main')); // 새로운 경로 설정

    return Scaffold(
      appBar: AppBar(
        title: Text("웹 페이지"),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
