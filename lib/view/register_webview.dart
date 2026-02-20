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
      // กำหนดสีพื้นหลังของ WebView ให้เป็นสีขาว เพื่อป้องกันการเห็นหน้าจอขาวตอนโหลด
      ..setBackgroundColor(const Color(0x00000000)) 
      ..addJavaScriptChannel(
        'NavigationChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'back_to_login') {
            // ตรวจสอบ mounted เพื่อความปลอดภัยก่อนสั่ง Navigator.pop
            if (mounted) {
              Navigator.pop(context);
            }
          }
        },
      )
      ..loadFlutterAsset('assets/register_page.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // เปลี่ยนสีตัวอักษรเป็นสีขาวให้ตัดกับพื้นหลัง
        title: const Text('ลงทะเบียน', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[300],
        // เปลี่ยนสีไอคอนย้อนกลับเป็นสีขาว
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0, // ทำให้เงาหายไป ดูทันสมัยขึ้น
      ),
      // ใส่ SafeArea คลุมไว้เพื่อป้องกันเนื้อหาทับกับแถบสถานะด้านล่าง (ถ้ามี)
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}