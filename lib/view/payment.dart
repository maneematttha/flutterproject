import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // เก็บรายการอาหาร
  List _filteredMenuItems = [];

  @override
  void initState() {
    super.initState();
    // รับข้อมูลและเพิ่มฟิลด์ 'quantity' เป็น 1 เริ่มต้นให้กับทุกรายการ
    var rawData = Get.arguments as List;
    _filteredMenuItems = rawData.map((item) {
      var newItem = Map<String, dynamic>.from(item);
      newItem['quantity'] = newItem['quantity'] ?? 1; // ถ้ายังไม่มีให้เป็น 1
      return newItem;
    }).toList();
  }

  // ฟังก์ชันคำนวณราคารวมทั้งหมด
  double _calculateTotal() {
    double total = 0;
    for (var item in _filteredMenuItems) {
      // สมมติว่าราคาจานละ 35 บาทตามโค้ดเดิมของคุณ
      total += (item['quantity'] as int) * 35; 
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[400],
        title: const Text('รายการอาหารที่สั่ง'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _filteredMenuItems.length,
                itemBuilder: (context, index) {
                  final menuItem = _filteredMenuItems[index];
                  return Card( // เพิ่ม Card เพื่อความสวยงามและแบ่งสัดส่วน
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ส่วนชื่ออาหาร
                          Expanded(
                            child: Text(
                              '${index + 1}. ${menuItem['strMeal']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // --- ส่วนเพิ่ม/ลด จำนวน ---
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.pink),
                                onPressed: () {
                                  setState(() {
                                    if (menuItem['quantity'] > 1) {
                                      menuItem['quantity']--;
                                    }
                                  });
                                },
                              ),
                              Text(
                                '${menuItem['quantity']}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () {
                                  setState(() {
                                    menuItem['quantity']++;
                                  });
                                },
                              ),
                            ],
                          ),

                          // ปุ่มลบรายการ
                          IconButton(
                            onPressed: () {
                              _showDeleteDialog(index);
                            },
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // ส่วนสรุปค่าใช้จ่าย
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              child: Text(
                'สรุปค่าใช้จ่าย ทั้งหมด ${_calculateTotal().toInt()} บาท',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // ปุ่มชำระเงิน
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('เงินสด'),
                const SizedBox(width: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _handlePayment(),
                  child: const Text('Next To logout', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // แยกฟังก์ชัน Dialog ออกมาเพื่อให้โค้ดดูสะอาดขึ้น
  void _showDeleteDialog(int index) {
    Get.defaultDialog(
      title: 'การแจ้งเตือน',
      middleText: 'คุณต้องการลบรายการนี้หรือไม่?',
      textConfirm: 'ยืนยัน',
      textCancel: 'ยกเลิก',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        setState(() {
          _filteredMenuItems.removeAt(index);
        });
        Get.back();
      },
    );
  }

  void _handlePayment() {
    if (_filteredMenuItems.isNotEmpty) {
      Get.defaultDialog(
        title: 'การแจ้งเตือน',
        middleText: 'คุณต้องการชำระเงินหรือไม่?',
        textConfirm: 'ยืนยัน',
        textCancel: 'ยกเลิก',
        confirmTextColor: Colors.white,
        buttonColor: Colors.red,
        onConfirm: () => Get.offAllNamed("/CheckOutPage"),
      );
    } else {
      Get.snackbar('การแจ้งเตือน', 'กรุณาเลือกรายการก่อน!',
          backgroundColor: Colors.pink[200], colorText: Colors.white);
    }
  }
}