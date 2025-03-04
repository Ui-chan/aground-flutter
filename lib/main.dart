// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aground/WebViewPage.dart';
import 'package:aground/BluetoothPage.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color.fromARGB(255, 238, 239, 243),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aground App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color.fromARGB(255, 238, 239, 243),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 화면 목록: 0 -> WebViewPage
  late List<Widget> _screens; // List를 late로 선언

  @override
  void initState() {
    super.initState();
    // initState 내에서 _screens 초기화
    _screens = [
      WebViewPage(onBluetoothRequest: _switchToBluetooth), // 웹뷰 화면, 콜백 전달
    ];
  }

  // 웹뷰에서 블루투스 화면으로 전환 요청 시 호출되는 함수
  void _switchToBluetooth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BluetoothPage()), // 블루투스 페이지 푸시
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color.fromARGB(255, 238, 239, 243),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 238, 239, 243),
        body: SafeArea(
          child: _screens[0], // 웹뷰 화면만 표시
        ),
      ),
    );
  }
}
