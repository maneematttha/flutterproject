import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_order/view/register_webview.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. กำหนด Controller และ Key
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // 2. ดึง Supabase Instance
  final supabase = Supabase.instance.client;

  // ฟังก์ชัน: เปิดหน้า Register (WebView)
  void _openRegisterPage() {
    Get.to(() => const RegisterWebView());
  }

  // ฟังก์ชันหลัก: Login และตรวจสอบข้อมูลใน Database
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // แสดง Loading ระหว่างทำงาน
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ขั้นตอนที่ 1: พยายาม Login เข้า Supabase Auth
      final AuthResponse res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ขั้นตอนที่ 2: ตรวจสอบว่ามีข้อมูลในตาราง 'profiles' หรือไม่
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', res.user!.id)
          .maybeSingle();

      if (mounted) Navigator.pop(context); // ปิด Loading

      if (data == null) {
        // กรณีมี User ในระบบ Auth แต่ยังไม่มีข้อมูลใน Table profiles
        await supabase.auth.signOut();
        _showErrorDialog("ไม่พบข้อมูลผู้ใช้ในระบบ\nกรุณาลงทะเบียนให้ครบถ้วนก่อนเข้าใช้งาน");
      } else {
        // ข้อมูลครบ ไปหน้าหลัก
        Get.offAllNamed("/HomePage");
      }

    } on AuthException catch (error) {
      if (mounted) Navigator.pop(context); 

      // แปลข้อความ Error จาก Supabase เป็นภาษาไทย
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
        case 'Network password error':
          messageThai = "การเชื่อมต่อเครือข่ายขัดข้อง";
          break;
        default:
          messageThai = "เกิดข้อผิดพลาด: ${error.message}";
      }

      _showErrorDialog(messageThai); 

    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog("ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้\nกรุณาลองใหม่อีกครั้ง");
    }
  }

  // ฟังก์ชัน: สร้าง Popup แจ้งเตือน (ภาษาไทย)
  void _showErrorDialog(String message) {
    Get.defaultDialog(
      title: "แจ้งเตือน",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      middleText: message,
      middleTextStyle: const TextStyle(fontSize: 16),
      textConfirm: "ตกลง",
      confirmTextColor: Colors.white,
      buttonColor: Colors.pink[400],
      onConfirm: () => Get.back(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'อาหารตามสั่ง',
                    style: TextStyle(
                      fontSize: 44,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // ช่อง Email
                  _buildTextField(
                    controller: _emailController,
                    hint: 'อีเมลผู้ใช้',
                    icon: Icons.email,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  
                  // ช่อง Password
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'รหัสผ่าน',
                    icon: Icons.lock,
                    isObscure: true,
                  ),
                  const SizedBox(height: 30),
                  
                  // ปุ่ม Login
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _submitForm,
                    child: const Text('เข้าสู่ระบบ', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ปุ่มสมัครสมาชิก
                  TextButton(
                    onPressed: _openRegisterPage,
                    child: const Text(
                      'ยังไม่มีบัญชี? ลงทะเบียนที่นี่',
                      style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.underline),
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
      validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกข้อมูลให้ครบถ้วน' : null,
    );
  }
}