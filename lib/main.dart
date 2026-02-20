import 'package:flutter/material.dart';
import 'package:flutter_order/routers/router.dart';
import 'package:get/get.dart'; // เปลี่ยนจาก get/route_manager.dart เพื่อให้ใช้ความสามารถ GetX ได้เต็มที่
import 'package:supabase_flutter/supabase_flutter.dart'; 

void main() async {
  // 1. ตรวจสอบว่า Binding ของ Flutter พร้อมทำงานก่อนเริ่ม Async
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. ตั้งค่าการเชื่อมต่อกับ Supabase
    await Supabase.initialize(
      url: 'https://igipojhbetjhgufxbvgs.supabase.co', 
      anonKey: 'sb_publishable_tEmbm32nMcjG0gVPFQtT8A_Cz64sK8T',
    );
  } catch (e) {
    // จัดการกรณีที่การเชื่อมต่อเริ่มต้นมีปัญหา
    debugPrint('Supabase Initialization Error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // ปิดแถบ Debug สีแดงที่มุมขวาบน
      debugShowCheckedModeBanner: false,
      
      // ชื่อแอปพลิเคชัน
      title: 'Flutter Order',
      
      // กำหนดค่าธีมเบื้องต้นเพื่อให้แอปดูสวยงาม (Material 3)
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        fontFamily: 'Kanit', // หากคุณมีการลงฟอนต์ภาษาไทยไว้
      ),
      
      // ตั้งค่าหน้าแรก (Route แรกที่จะเปิด)
      initialRoute: '/LoginPage',
      
      // รายการหน้าทั้งหมดที่จัดการผ่าน GetX (ดึงมาจากไฟล์ router.dart)
      getPages: AppPages.pages,
      
      // ตั้งค่าการเปลี่ยนหน้า (Transition) ให้เป็นมาตรฐานเดียวกันทั้งแอป
      defaultTransition: Transition.cupertino,
      
      // กรณีมีการใส่ Route ผิด ให้เด้งกลับไปหน้าแรก (Error Prevention)
      unknownRoute: AppPages.pages.first, 
    );
  }
}