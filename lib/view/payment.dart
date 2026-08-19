import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  PaymentPageState createState() => PaymentPageState();
}

class PaymentPageState extends State<PaymentPage> {
  // เก็บรายการอาหารในตะกร้า
  List<Map<String, dynamic>> _cartItems = [];
  String _selectedPaymentMethod = 'qr_code'; // 'qr_code' หรือ 'cash'
  final double _droneDeliveryFee = 20.0; // ค่าจัดส่งด้วยโดรน

  @override
  void initState() {
    super.initState();
    var rawData = Get.arguments;
    if (rawData is List) {
      _cartItems = rawData.map((item) {
        var newItem = Map<String, dynamic>.from(item);
        newItem['quantity'] = newItem['quantity'] ?? 1;
        newItem['price'] = (newItem['price'] as num?)?.toDouble() ?? 35.0;
        return newItem;
      }).toList();
    }
  }

  // คำนวณราคารวมอาหารทั้งหมด
  double _calculateFoodTotal() {
    double total = 0;
    for (var item in _cartItems) {
      final price = (item['price'] as num?)?.toDouble() ?? 35.0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      total += price * qty;
    }
    return total;
  }

  // ราคารวมสุทธิ (ค่าอาหาร + ค่าจัดส่งโดรน)
  double _calculateGrandTotal() {
    if (_cartItems.isEmpty) return 0.0;
    return _calculateFoodTotal() + _droneDeliveryFee;
  }

  void _showDeleteDialog(int index) {
    Get.defaultDialog(
      title: 'การแจ้งเตือน',
      middleText: 'คุณต้องการลบรายการนี้ออกจากตะกร้าหรือไม่?',
      textConfirm: 'ยืนยัน',
      textCancel: 'ยกเลิก',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        setState(() {
          _cartItems.removeAt(index);
        });
        Get.back();
      },
    );
  }

  void _handlePayment() {
    if (_cartItems.isEmpty) {
      Get.snackbar('การแจ้งเตือน', 'กรุณาเลือกรายการอาหารก่อน!',
          backgroundColor: Colors.pink[200], colorText: Colors.white);
      return;
    }

    if (_selectedPaymentMethod == 'qr_code') {
      _showQrPaymentBottomSheet();
    } else {
      _confirmAndProceed();
    }
  }

  void _confirmAndProceed() {
    Get.defaultDialog(
      title: 'ยืนยันการสั่งซื้อ',
      middleText: 'ยอดชำระสุทธิ ${_calculateGrandTotal().toStringAsFixed(0)} บาท\nต้องการส่งออเดอร์ไปยังโดรนหรือไม่?',
      textConfirm: 'ยืนยันสั่งซื้อ',
      textCancel: 'ยกเลิก',
      confirmTextColor: Colors.white,
      buttonColor: Colors.pink[400],
      onConfirm: () {
        Get.back();
        Get.offAllNamed(
          "/CheckOutPage",
          arguments: {
            'items': _cartItems,
            'total': _calculateGrandTotal(),
            'payment_method': _selectedPaymentMethod,
          },
        );
      },
    );
  }

  void _showQrPaymentBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: Colors.pink, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'สแกน QR เพื่อชำระเงิน (PromptPay)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ยอดชำระ: ฿${_calculateGrandTotal().toStringAsFixed(2)} บาท',
                style: TextStyle(fontSize: 16, color: Colors.pink[700], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Mock PromptPay QR Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[900]!, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'พร้อมเพย์ | PromptPay',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Icon(Icons.qr_code_2_rounded, size: 180, color: Colors.grey[900]),
                    const SizedBox(height: 8),
                    const Text(
                      'SkyFLASH Delivery Co., Ltd.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Get.offAllNamed(
                      "/CheckOutPage",
                      arguments: {
                        'items': _cartItems,
                        'total': _calculateGrandTotal(),
                        'payment_method': 'qr_code',
                      },
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'ตรวจสอบการโอนเงินแล้ว',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodTotal = _calculateFoodTotal();
    final grandTotal = _calculateGrandTotal();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[400],
        title: const Text('สรุปรายการและชำระเงิน', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 70, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('ไม่มีรายการในตะกร้า', style: TextStyle(fontSize: 18, color: Colors.black54)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[400]),
                    child: const Text('กลับไปเลือกเมนู', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายการอาหารที่คุณเลือก',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // รายการอาหารในตะกร้า
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      final name = item['name'] ?? item['strMeal'] ?? 'เมนูอาหาร';
                      final price = (item['price'] as num?)?.toDouble() ?? 35.0;
                      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                      final subtotal = price * qty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // รูปขนาดเล็ก
                              if (item['image_url'] != null || item['strMealThumb'] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item['image_url'] ?? item['strMealThumb'] ?? '',
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 55,
                                      height: 55,
                                      color: Colors.pink[50],
                                      child: const Icon(Icons.fastfood, color: Colors.pink),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),

                              // ชื่อและราคาต่อชิ้น
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '฿${price.toStringAsFixed(0)} / จาน',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                    ),
                                    Text(
                                      'รวม: ฿${subtotal.toStringAsFixed(0)}',
                                      style: TextStyle(color: Colors.pink[700], fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),

                              // ปุ่มเพิ่มลด
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.pink, size: 22),
                                    onPressed: () {
                                      setState(() {
                                        if (qty > 1) {
                                          item['quantity'] = qty - 1;
                                        } else {
                                          _showDeleteDialog(index);
                                        }
                                      });
                                    },
                                  ),
                                  Text(
                                    '$qty',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
                                    onPressed: () {
                                      setState(() {
                                        item['quantity'] = qty + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // วิธีการชำระเงิน
                  const Text(
                    'วิธีการชำระเงิน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        ListTile(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                          ),
                          leading: Icon(
                            _selectedPaymentMethod == 'qr_code'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: Colors.pink[400],
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.qr_code_scanner, color: Colors.pink),
                              SizedBox(width: 10),
                              Text('สแกน QR Code (PromptPay)', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          subtitle: const Text('ตรวจสอบยอดเงินเข้าทันที'),
                          onTap: () => setState(() => _selectedPaymentMethod = 'qr_code'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                          ),
                          leading: Icon(
                            _selectedPaymentMethod == 'cash'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: Colors.pink[400],
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.payments_outlined, color: Colors.green),
                              SizedBox(width: 10),
                              Text('ชำระเงินสดปลายทาง', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          subtitle: const Text('ชำระเมื่อโดรนนำส่งถึงจุดรับ'),
                          onTap: () => setState(() => _selectedPaymentMethod = 'cash'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // สรุปยอดเงิน
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    color: Colors.pink[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ค่าอาหารทั้งหมด', style: TextStyle(fontSize: 14)),
                              Text('฿${foodTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.flight_takeoff_rounded, size: 18, color: Colors.pink),
                                  SizedBox(width: 6),
                                  Text('ค่าจัดส่งด้วยโดรน SkyFLASH', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              Text('฿${_droneDeliveryFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดชำระสุทธิ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(
                                '฿${grandTotal.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink[700]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ปุ่มยืนยันชำระเงิน
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[400],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      onPressed: _handlePayment,
                      child: Text(
                        _selectedPaymentMethod == 'qr_code'
                            ? 'สแกน QR Code ชำระเงิน (฿${grandTotal.toStringAsFixed(0)})'
                            : 'ยืนยันสั่งอาหาร (฿${grandTotal.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}