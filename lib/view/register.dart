import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      Get.snackbar(
        "ข้อผิดพลาด",
        "รหัสผ่านไม่ตรงกัน",
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ลงทะเบียนผู้ใช้ด้วย Supabase
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (res.user != null) {
        // อัปเดตข้อมูลเพิ่มเติมลงในตาราง profiles
        try {
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'username': _usernameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
          });
        } catch (_) {}

        Get.snackbar(
          "สำเร็จ",
          "สมัครสมาชิกเรียบร้อยแล้ว",
          backgroundColor: Colors.green[400],
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        // กลับไปหน้า Login
        Get.offAllNamed("/LoginPage");
      }
    } on AuthException catch (e) {
      Get.snackbar(
        "ลงทะเบียนไม่สำเร็จ",
        e.message,
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        "ข้อผิดพลาด",
        "เกิดข้อผิดพลาดไม่ทราบสาเหตุ",
        backgroundColor: Colors.red[400],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
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
      validator: validator ??
          (value) => (value == null || value.isEmpty)
              ? 'กรุณากรอกข้อมูลให้ครบถ้วน'
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[300],
      appBar: AppBar(
        title: const Text('ลงทะเบียนบัญชีใหม่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                  const Icon(Icons.person_add_alt_1, size: 80, color: Colors.white),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'ชื่อผู้ใช้งาน (Username)',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'อีเมล (Email)',
                    icon: Icons.email,
                    type: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
                      if (!GetUtils.isEmail(value)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _phoneController,
                    hint: 'เบอร์โทรศัพท์มือถือ',
                    icon: Icons.phone,
                    type: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
                      if (value.length < 10) return 'เบอร์โทรศัพท์ต้องมีอย่างน้อย 10 หลัก';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'รหัสผ่าน (Password)',
                    icon: Icons.lock,
                    isObscure: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                      if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'ยืนยันรหัสผ่าน (Confirm Password)',
                    icon: Icons.lock_outline,
                    isObscure: true,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : _submitRegister,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : const Text(
                            'ลงทะเบียน',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
}
