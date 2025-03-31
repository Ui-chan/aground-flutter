import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReWebViewPage extends StatelessWidget {
  final String url;

  const ReWebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url)); // 전달받은 URL 로드

    return Scaffold(
      appBar: AppBar(
        title: Text("웹 페이지"),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
