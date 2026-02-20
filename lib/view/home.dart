import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  List _menuItems = [];
  List selectCart = [];
  List _filteredMenuItems = [];
  bool _isLoading = true; // เพิ่มตัวแปรเช็คสถานะการโหลด

  final String apiUrl = 'https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood';

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _menuItems = data['meals'];
          _filteredMenuItems = data['meals'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'ไม่สามารถโหลดข้อมูลได้: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose(); // ล้าง Controller เพื่อคืน Memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pink[400],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ทุกอย่าง 35 บาท', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                Get.defaultDialog(
                  title: 'การแจ้งเตือน',
                  middleText: 'คุณต้องการออกจากระบบหรือไม่?',
                  textConfirm: 'ยืนยัน',
                  textCancel: 'ยกเลิก',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () => Get.offAllNamed("/LoginPage"),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) // แสดง Loading ถ้ายังโหลดไม่เสร็จ
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ช่องค้นหาแบบสวยงาม
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _filteredMenuItems = _menuItems
                            .where((item) => item['strMeal']
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'ค้นหาเมนูอาหาร...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // แสดงรายการอาหาร
                  Expanded(
                    child: _filteredMenuItems.isEmpty 
                    ? const Center(child: Text('ไม่พบเมนูที่คุณค้นหา'))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          childAspectRatio: 0.9, // ปรับสัดส่วนให้เห็นชื่อชัดขึ้น
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          crossAxisCount: 2,
                        ),
                        itemCount: _filteredMenuItems.length,
                        itemBuilder: (context, index) {
                          final menuItem = _filteredMenuItems[index];
                          // เช็คว่าอยู่ในตะกร้าไหม (ใช้ any จะเร็วกว่า where ในแง่ประสิทธิภาพ)
                          final isSelected = selectCart.any((item) => item['idMeal'] == menuItem['idMeal']);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectCart.removeWhere((item) => item['idMeal'] == menuItem['idMeal']);
                                } else {
                                  selectCart.add(menuItem);
                                }
                              });
                            },
                            child: AnimatedContainer( // เพิ่ม Animation เวลาเลือก
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.pink[50] : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: isSelected ? Colors.pink : Colors.transparent, width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                      child: Image.network(
                                        menuItem['strMealThumb'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      menuItem['strMeal'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (isSelected) 
                                    const Icon(Icons.check_circle, color: Colors.pink, size: 20),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ),
                  
                  // ปุ่มถัดไปพร้อมแสดงจำนวนที่เลือก
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[400],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (selectCart.isNotEmpty) {
                          Get.toNamed("/PaymentPage", arguments: selectCart);
                        } else {
                          Get.snackbar('คำแนะนำ', 'กรุณาเลือกเมนูที่ต้องการอย่างน้อย 1 รายการ', 
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.orangeAccent,
                            colorText: Colors.white);
                        }
                      },
                      child: Text(
                        'ชำระเงิน (${selectCart.length} รายการ)', 
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}