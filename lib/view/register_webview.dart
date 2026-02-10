import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RegisterWebView extends StatefulWidget {
  const RegisterWebView({Key? key}) : super(key: key);

  @override
  State<RegisterWebView> createState() => _RegisterWebViewState();
}

class _RegisterWebViewState extends State<RegisterWebView> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // --- เพิ่มส่วนนี้เข้าไป ---
      ..addJavaScriptChannel(
        'NavigationChannel', // ชื่อต้องตรงกับ window.NavigationChannel ใน HTML
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'back_to_login') {
            // เมื่อได้รับข้อความ 'back_to_login' ให้ปิดหน้า WebView ทันที
            Navigator.pop(context);
          }
        },
      )
      // -----------------------
      ..loadFlutterAsset('assets/register_page.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียน'),
        backgroundColor: Colors.blue[300], // ใส่สีให้เข้ากับหน้า Login
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}