import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckOutPage extends StatefulWidget {
  const CheckOutPage({Key? key}) : super(key: key);

  @override
  _CheckOutPageState createState() => _CheckOutPageState();
}

class _CheckOutPageState extends State<CheckOutPage> {
  // สถานะปัจจุบัน: 0 = รับออเดอร์, 1 = กำลังส่ง, 2 = สำเร็จ
  final int _currentStep = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.pink[400],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAllNamed("/HomePage"),
        ),
        titleSpacing: 0,
        title: const Text('กลับสู่หน้าหลัก',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.normal)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 25), // ปรับลดจาก 40
              // ส่วนหัว: Icon สำเร็จ
              const Icon(Icons.check_circle_rounded, size: 85, color: Colors.green), // ปรับลดจาก 100
              const SizedBox(height: 12),
              const Text('ขอบคุณที่ใช้บริการ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), // ปรับลด vertical จาก 20
                child: Divider(thickness: 1, color: Colors.black12),
              ),

              const Text('สถานะการจัดส่ง',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
              
              const SizedBox(height: 20), // ปรับลดจาก 30

              // --- Custom Timeline Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    _buildTimelineStep(
                      index: 0,
                      title: 'รับออเดอร์แล้ว',
                      subtitle: 'ร้านค้ากำลังเตรียมอาหารของคุณ',
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      index: 1,
                      title: 'กำลังนำส่ง',
                      subtitle: 'โดรนกำลังเดินทางไปหาคุณ',
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      index: 2,
                      title: 'ส่งอาหารสำเร็จ',
                      subtitle: 'ทานให้อร่อยนะครับ!',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // เพิ่ม Padding ด้านล่างสุดกันติดขอบ
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required int index,
    required String title,
    required String subtitle,
    required bool isLast,
  }) {
    bool isCompleted = _currentStep > index;
    bool isActive = _currentStep == index;
    Color color = (isCompleted || isActive) ? Colors.pink[400]! : Colors.grey[300]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนเส้นและจุด
          Column(
            children: [
              Container(
                width: 26, // ปรับลดจาก 28
                height: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.pink[400] : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${index + 1}', 
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? Colors.pink[400] : Colors.grey[200],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15), // ปรับลดจาก 20
          // ส่วนข้อความ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 15, // ปรับลดจาก 16
                      fontWeight: FontWeight.bold,
                      color: (isCompleted || isActive) ? Colors.black87 : Colors.grey,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 13, // ปรับลดจาก 14
                      color: (isCompleted || isActive) ? Colors.black54 : Colors.grey[400],
                    )),
                if (!isLast) const SizedBox(height: 25), // ปรับลดระยะห่างระหว่าง Step จาก 30
              ],
            ),
          ),
        ],
      ),
    );
  }
}