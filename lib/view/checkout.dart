import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckOutPage extends StatefulWidget {
  const CheckOutPage({Key? key}) : super(key: key);

  @override
  CheckOutPageState createState() => CheckOutPageState();
}

class CheckOutPageState extends State<CheckOutPage> {
  final supabase = Supabase.instance.client;

  // สถานะปัจจุบัน: 0 = รับออเดอร์, 1 = โดรนกำลังบินนำส่ง, 2 = สำเร็จ
  final int _currentStep = 1;
  List<Map<String, dynamic>> _orderedItems = [];
  double _totalAmount = 0.0;
  String _paymentMethod = 'qr_code';
  String? _restaurantId;
  String? _deliveryAddress;
  double? _deliveryLat;
  double? _deliveryLng;

  bool _isPlacingOrder = true; // กำลังส่งออเดอร์เข้า Supabase อยู่
  String? _orderId; // เก็บ id ของออเดอร์ที่สร้างสำเร็จ

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
      _restaurantId = args['restaurant_id']?.toString();
      _deliveryAddress = args['delivery_address']?.toString();
      _deliveryLat = (args['delivery_lat'] as num?)?.toDouble();
      _deliveryLng = (args['delivery_lng'] as num?)?.toDouble();
    } else if (args is List) {
      _orderedItems = args.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // ยิง insert ทันทีที่เข้าหน้านี้
    _placeOrder();
  }

  // ฟังก์ชันหลัก: บันทึกออเดอร์ลง Supabase
  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('ยังไม่ได้เข้าสู่ระบบ กรุณา login ก่อนสั่งอาหาร');
      }
      if (_restaurantId == null) {
        throw Exception('ไม่พบข้อมูลร้านค้า (restaurant_id)');
      }
      if (_orderedItems.isEmpty) {
        throw Exception('ไม่มีรายการอาหารที่สั่ง');
      }

      final foodTotal = _orderedItems.fold<double>(
        0.0,
        (sum, item) {
          final qty = (item['quantity'] as num?)?.toDouble() ?? 1;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          return sum + (price * qty);
        },
      );
      const deliveryFee = 0.0; // ปรับตามจริงถ้ามีค่าส่ง
      final grandTotal = _totalAmount > 0 ? _totalAmount : (foodTotal + deliveryFee);

      final itemsPayload = _orderedItems
          .map((item) => {
                'name': item['name'] ?? item['strMeal'] ?? 'อาหาร',
                'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
                'price': (item['price'] as num?)?.toDouble() ?? 0.0,
              })
          .toList();

      final response = await supabase
          .from('orders')
          .insert({
            'customer_id': userId,
            'restaurant_id': _restaurantId,
            'items': itemsPayload,
            'food_total': foodTotal,
            'delivery_fee': deliveryFee,
            'grand_total': grandTotal,
            'delivery_lat': _deliveryLat,
            'delivery_lng': _deliveryLng,
            'delivery_address': _deliveryAddress,
            'status': 'pending',
            'payment_method': _paymentMethod,
            'payment_status': _paymentMethod == 'qr_code' ? 'paid' : 'unpaid',
          })
          .select()
          .single();

      setState(() {
        _orderId = response['id']?.toString();
        _isPlacingOrder = false;
      });
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      Get.snackbar(
        'สั่งอาหารไม่สำเร็จ',
        'เกิดข้อผิดพลาด: $e',
        backgroundColor: Colors.red[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
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
        child: _isPlacingOrder
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังส่งคำสั่งซื้อ...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // การ์ดสถานะความสำเร็จ / ล้มเหลว
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
                          Icon(
                            _orderId != null ? Icons.check_circle_rounded : Icons.error_rounded,
                            size: 70,
                            color: _orderId != null ? Colors.green : Colors.red,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _orderId != null ? 'ส่งคำสั่งซื้อสำเร็จแล้ว!' : 'ส่งคำสั่งซื้อไม่สำเร็จ',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _orderId != null
                                ? 'ระบบได้ส่งข้อมูลไปยังร้านค้าและเตรียมส่งโดรน SkyFLASH'
                                : 'กรุณาลองใหม่อีกครั้ง หรือติดต่อร้านค้าโดยตรง',
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
                          if (_orderId == null) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[400]),
                                onPressed: _placeOrder,
                                label: const Text('ลองส่งคำสั่งซื้ออีกครั้ง',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_orderId != null) ...[
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
                    ],

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

                    if (_orderId != null) ...[
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
                          onPressed: () => Get.toNamed("/TrackingPage", arguments: {'order_id': _orderId}),
                          label: const Text(
                            'ดูแผนที่ติดตามโดรน (Live Map)',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

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