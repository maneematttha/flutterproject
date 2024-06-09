import 'package:flutter/material.dart';
import 'package:flutter_order/routers/router.dart';
import 'package:get/route_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialRoute: '/LoginPage',
      defaultTransition: Transition.leftToRight,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Order',
      //ฟังก์ชันสำหรับจัดการแต่ละหน้า
      getPages: AppPages.pages,
    );
  }
}
