import 'package:flutter/material.dart';
import 'package:flutter_order/routers/router.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // 1. ตรวจสอบว่า Binding ของ Flutter พร้อมทำงานก่อนเริ่ม Async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. โหลด Environment Variables จากไฟล์ .env
  await dotenv.load(fileName: ".env");

  try {
    // 3. ตั้งค่าการเชื่อมต่อกับ Supabase (ดึงค่าจาก .env แทน hardcode)
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
      title: 'SkyFLASH',
      
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