import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter_order/view/register_webview.dart'; // Removed 

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  // 1. กำหนด Controller และ Key
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // 2. ดึง Supabase Instance
  final supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // ดักฟังสภาพ AuthState เมื่อเข้าสู่ระบบสำเร็จ (รวมถึง Google OAuth)
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null && data.event == AuthChangeEvent.signedIn) {
        final user = session.user;
        
        // ดึงชื่อผู้ใช้และรูปโปรไฟล์จาก Google หรือ Auth Metadata อัตโนมัติ
        final fullName = user.userMetadata?['full_name'] ?? 
                         user.userMetadata?['name'] ?? 
                         user.email?.split('@').first ?? 
                         'ผู้ใช้งาน SkyFLASH';
        final avatarUrl = user.userMetadata?['avatar_url']?.toString() ?? '';

        try {
          // บันทึก/อัปเดตลงตาราง profiles ใน Supabase ทันที
          await supabase.from('profiles').upsert({
            'id': user.id,
            'username': fullName,
            'email': user.email,
            'avatar_url': avatarUrl,
          });
        } catch (_) {
          // หากตาราง profiles ยังไม่มี column avatar_url ให้ลองบันทึกเฉพาะฟิลด์มาตรฐาน
          try {
            await supabase.from('profiles').upsert({
              'id': user.id,
              'username': fullName,
              'email': user.email,
            });
          } catch (_) {}
        }

        // นำทางไปยังหน้าหลัก
        Get.offAllNamed("/HomePage");
      }
    });
  }

  // ฟังก์ชัน: เปิดหน้า Register
  void _openRegisterPage() {
    Get.toNamed('/RegisterPage');
  }



  // ฟังก์ชัน: ส่งอีเมลรีเซ็ตรหัสผ่าน
  Future<void> _resetPassword() async {
    final TextEditingController resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    Get.defaultDialog(
      title: "ลืมรหัสผ่าน",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const Text(
              "กรุณากรอกอีเมลของคุณเพื่อรับลิงก์รีเซ็ตรหัสผ่าน",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "อีเมลของคุณ",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
      textConfirm: "ส่งลิงก์",
      textCancel: "ยกเลิก",
      confirmTextColor: Colors.white,
      buttonColor: Colors.pink[400],
      onConfirm: () async {
        final email = resetEmailController.text.trim();
        if (email.isEmpty) {
          Get.snackbar("แจ้งเตือน", "กรุณากรอกอีเมล",
              snackPosition: SnackPosition.BOTTOM);
          return;
        }

        Get.back(); // ปิด Dialog กรอกอีเมล

        // แสดง Loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // ส่งอีเมล Reset Password ผ่าน Supabase
          await supabase.auth.resetPasswordForEmail(
            email,
            redirectTo: 'io.supabase.flutterorder://login-callback',
          );
          if (mounted) Navigator.of(context, rootNavigator: true).pop(); // ปิด Loading
          _showErrorDialog("ระบบได้ส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ไปยังอีเมล $email แล้ว กรุณาตรวจสอบกล่องจดหมาย");
        } on AuthException catch (error) {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          
          if (error.message.contains('Error sending recovery email') || error.statusCode == '500') {
            _showErrorDialog(
              "ไม่สามารถส่งอีเมลรีเซ็ตรหัสผ่านได้:\n\n"
              "📌 สาเหตุ: Supabase Free Tier มีข้อจำกัดในการส่งอีเมล (Rate Limit) หรือยังไม่ได้ตั้งค่า Custom SMTP\n\n"
              "💡 วิธีแก้: แนะนำเข้า Supabase Dashboard -> Authentication -> Email -> เปิด Custom SMTP (เช่น Resend หรือ Gmail)",
            );
          } else {
            _showErrorDialog("เกิดข้อผิดพลาด: ${error.message}");
          }
        } catch (e) {
          if (mounted) Navigator.of(context, rootNavigator: true).pop();
          _showErrorDialog("ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาลองใหม่อีกครั้ง");
        }
      },
    );
  }

  // ฟังก์ชันหลัก: Login ด้วย Email + Password
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // แสดง Loading ระหว่างทำงาน
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ขั้นตอนที่ 1: Login เข้า Supabase Auth
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user == null) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _showErrorDialog("ไม่พบข้อมูลผู้ใช้งาน");
        return;
      }

      // ขั้นตอนที่ 2: ตรวจสอบ/สร้างข้อมูลในตาราง 'profiles'
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', res.user!.id)
          .maybeSingle();

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (data == null) {
        // หากยังไม่มี Profile ให้สร้างให้อัตโนมัติ
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'username': res.user!.email?.split('@').first ?? 'User',
          'email': res.user!.email,
        });
      }

      Get.offAllNamed("/HomePage");

    } on AuthException catch (error) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); 

      String messageThai = "";
      switch (error.message) {
        case 'Invalid login credentials':
          messageThai = "อีเมลหรือรหัสผ่านไม่ถูกต้อง\nกรุณาตรวจสอบและลองใหม่อีกครั้ง";
          break;
        case 'Email not confirmed':
          messageThai = "อีเมลนี้ยังไม่ได้ทำการยืนยัน\nกรุณาตรวจสอบกล่องจดหมายของคุณ";
          break;
        case 'User not found':
          messageThai = "ไม่พบชื่อผู้ใช้งานนี้ในระบบ";
          break;
        default:
          messageThai = "เกิดข้อผิดพลาด: ${error.message}";
      }

      _showErrorDialog(messageThai); 

    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showErrorDialog("ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้\nกรุณาลองใหม่อีกครั้ง");
    }
  }

  void _showErrorDialog(String message) {
    Get.defaultDialog(
      title: "แจ้งเตือน",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: message,
      middleTextStyle: const TextStyle(fontSize: 15),
      textConfirm: "ตกลง",
      confirmTextColor: Colors.white,
      buttonColor: Colors.pink[400],
      onConfirm: () => Get.back(),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[300],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- ส่วนแสดงโลโก้และข้อความ SkyFLASH ---
                  Image.asset(
                    'assets/images/logo.png',
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.rocket_launch, size: 100, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'SkyFLASH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ช่อง Email
                  _buildTextField(
                    controller: _emailController,
                    hint: 'อีเมลผู้ใช้',
                    icon: Icons.email,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  
                  // ช่อง Password
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'รหัสผ่าน',
                    icon: Icons.lock,
                    isObscure: true,
                  ),
                  
                  // ปุ่มลืมรหัสผ่าน
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text(
                        'ลืมรหัสผ่าน?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // ปุ่ม Login ด้วย Email
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _submitForm,
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ปุ่มสมัครสมาชิก
                  TextButton(
                    onPressed: _openRegisterPage,
                    child: const Text(
                      'ยังไม่มีบัญชี? ลงทะเบียนที่นี่',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget ตัวช่วยสร้างช่องกรอกข้อมูล
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: type,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue[300]),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'กรุณากรอกข้อมูลให้ครบถ้วน' : null,
    );
  }
}