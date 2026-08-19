/// SkyFLASH — App Configuration
/// 
/// ศูนย์กลางค่าคงที่และการตั้งค่าทั้งหมดของแอป
/// ใช้สำหรับ API URLs, Supabase config, และค่าคงที่อื่นๆ
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._(); // ป้องกันการสร้าง instance

  // --- Supabase ---
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // --- App Info ---
  static const String appName = 'SkyFLASH';
  static const String appVersion = '1.0.0';

  // --- ราคาอาหาร (จะย้ายไป Supabase ในอนาคต) ---
  static const double defaultItemPrice = 35.0;

  // --- API URLs (FastAPI Backend บน Render ที่ออนไลน์แล้ว) ---
  static const String apiBaseUrl = 'https://skyflash-backend-api-omh2.onrender.com';
  static const String wsBaseUrl = 'wss://skyflash-backend-api-omh2.onrender.com';
  
  // --- ข้อมูลชั่วคราว: TheMealDB API (จะเปลี่ยนเป็น FastAPI ภายหลัง) ---
  static const String tempMenuApiUrl = 'https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood';
}
