/// SkyFLASH — Supabase Service
/// 
/// Helper class สำหรับจัดการการสื่อสารกับ Supabase
/// รวมฟังก์ชัน Auth, CRUD profiles, orders ไว้ที่เดียว
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._(); // ป้องกันการสร้าง instance

  /// Supabase Client Instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Current User (null ถ้ายังไม่ login)
  static User? get currentUser => client.auth.currentUser;

  /// ตรวจสอบว่า Login อยู่หรือไม่
  static bool get isLoggedIn => currentUser != null;

  // ============================================
  // Authentication
  // ============================================

  /// Login ด้วย Email + Password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Logout
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// ส่งอีเมลรีเซ็ตรหัสผ่าน
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // ============================================
  // Profiles
  // ============================================

  /// ดึงข้อมูล Profile ของ User ตาม ID
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    return await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  // ============================================
  // Orders (สำหรับเฟสถัดไป)
  // ============================================

  /// บันทึก Order ใหม่ลง Database
  static Future<void> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    await client.from('orders').insert({
      'user_id': userId,
      'items': items,
      'total_amount': totalAmount,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
