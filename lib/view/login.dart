import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //ใช้สำหรับตรวจสอบที่ไม่กรอกข้อมูล
  final _formKey = GlobalKey<FormState>();
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      //ถ้ามีข้อมูลให้ไปหน้าใหม่
      Get.offAllNamed("/HomePage");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[300],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 55),
                  child: Text(
                    'อาหารตามสั่ง',
                    style: TextStyle(fontSize: 44, color: Colors.white),
                  ),
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6))),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'ชื่อผู้ใช้',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'กรุณาใส่ชื่อผู้ใช้ของคุณ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6))),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'รหัสผ่าน',
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'กรุณาใส่รหัสผ่านของคุณ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.pink[400])),
                  onPressed: _submitForm,

                  // {
                  //   // Perform login with credentials
                  //   String username = _usernameController.text;
                  //   String password = _passwordController.text;
                  //   // Validate credentials and navigate to next page
                  //   Get.offAllNamed("/HomePage");
                  // },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 44),
                    child: Text('Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
