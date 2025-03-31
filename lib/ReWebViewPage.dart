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
      body: PopScope(
        canPop: false, // 뒤로가기 제스처를 비활성화
        child: WebViewWidget(controller: controller), // WebView 화면
      ),
    );
  }
}
 