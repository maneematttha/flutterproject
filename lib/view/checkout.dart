import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckOutPage extends StatefulWidget {
  const CheckOutPage({Key? key}) : super(key: key);

  @override
  CheckOutPageState createState() => CheckOutPageState();
}

class CheckOutPageState extends State<CheckOutPage> {
  // สถานะปัจจุบัน: 0 = รับออเดอร์, 1 = โดรนกำลังบินนำส่ง, 2 = สำเร็จ
  final int _currentStep = 1;
  List<Map<String, dynamic>> _orderedItems = [];
  double _totalAmount = 0.0;
  String _paymentMethod = 'qr_code';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _orderedItems = (args['items'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [];
      _totalAmount = (args['total'] as num?)?.toDouble() ?? 0.0;
      _paymentMethod = args['payment_method']?.toString() ?? 'qr_code';
    } else if (args is List) {
      _orderedItems = args.map((e) => Map<String, dynamic>.from(e)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.pink[400],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.offAllNamed("/HomePage"),
        ),
        titleSpacing: 0,
        title: const Text('กลับสู่หน้ารายการเมนู',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.normal)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // การ์ดสถานะความสำเร็จ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 70, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text(
                      'ส่งคำสั่งซื้อสำเร็จแล้ว!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ระบบได้ส่งข้อมูลไปยังร้านค้าและเตรียมส่งโดรน SkyFLASH',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flight_takeoff_rounded, color: Colors.pink, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'วิธีชำระ: ${_paymentMethod == 'qr_code' ? 'PromptPay QR (ยืนยันแล้ว)' : 'เงินสดปลายทาง'} • ฿${_totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.pink[800], fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // การ์ด Timeline สถานะการจัดส่งโดรน
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.radar_rounded, color: Colors.pink),
                        SizedBox(width: 8),
                        Text(
                          'สถานะการจัดส่งด้วยโดรน (Real-time)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTimelineStep(
                      index: 0,
                      title: 'ร้านค้ารับออเดอร์แล้ว',
                      subtitle: 'กำลังปรุงอาหารตามออเดอร์',
                      icon: Icons.restaurant,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      index: 1,
                      title: 'โดรน SkyFLASH กำลังบินจัดส่ง',
                      subtitle: 'กำลังบินนำส่งด้วยความเร็วอัตโนมัติ (GPS)',
                      icon: Icons.flight,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      index: 2,
                      title: 'ส่งอาหารสำเร็จ ณ จุดรับ',
                      subtitle: 'โดรนลงจอดและส่งมอบอาหารเรียบร้อย ทานให้อร่อยครับ!',
                      icon: Icons.done_all,
                      isLast: true,
                    ),
                  ],
                ),
              ),

              if (_orderedItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                // สรุปรายการอาหารที่สั่ง
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สรุปรายการอาหาร',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      ..._orderedItems.map((item) {
                        final name = item['name'] ?? item['strMeal'] ?? 'อาหาร';
                        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                        final price = (item['price'] as num?)?.toDouble() ?? 35.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('$name x $qty', style: const TextStyle(fontSize: 14)),
                              ),
                              Text('฿${(price * qty).toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ยอดรวมสุทธิ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '฿${_totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ปุ่มติดตามโดรนแบบ Real-time
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Get.toNamed("/TrackingPage"),
                  label: const Text(
                    'ดูแผนที่ติดตามโดรน (Live Map)',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ปุ่มกลับสู่หน้าหลัก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Get.offAllNamed("/HomePage"),
                  child: const Text(
                    'สั่งอาหารเพิ่ม / กลับสู่หน้าหลัก',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
    required IconData icon,
    required bool isLast,
  }) {
    bool isCompleted = _currentStep > index;
    bool isActive = _currentStep == index;
    Color color = (isCompleted || isActive) ? Colors.pink[400]! : Colors.grey[300]!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.pink[400] : (isActive ? Colors.pink[50] : Colors.white),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check : icon,
                    size: 16,
                    color: isCompleted ? Colors.white : color,
                  ),
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
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: (isCompleted || isActive) ? Colors.black87 : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: (isCompleted || isActive) ? Colors.black54 : Colors.grey[400],
                  ),
                ),
                if (!isLast) const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}