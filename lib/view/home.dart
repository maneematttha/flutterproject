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

  // ตัวแปรสำหรับเก็บข้อมูลหลัก
  List _menuItems = [];
  // แปลในการค้นหาข้อมูล
  List selectCart = [];
  // ตัวแปรที่ใช้สำหรับแปลงข้อมูลหลักให้สามารถค้นหาได้
  List _filteredMenuItems = [];
  final String apiUrl =
      'https://www.themealdb.com/api/json/v1/1/filter.php?c=Seafood';

//ฟังก์ชันสำหรับ API
  Future<void> _fetchData() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      //เก็บ Data ทั้งหมดมาไว้ในตัวแปรหลังจาก API
      setState(() {
        _menuItems = data['meals'];
        _filteredMenuItems = data['meals'];
      });
    } else {
      throw Exception('Failed to load data from API');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Initialize filtered menu items with all menu items
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[400],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ทุกอย่าง 35 บาท'),
            Row(
              children: [
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 18),
                //   child: GestureDetector(
                //       onTap: () {
                //         Get.offAllNamed("/LoginPage");
                //       },
                //       child: const Icon(Icons.shopping_cart_rounded)),
                // ),
                GestureDetector(
                    onTap: () {
                      Get.defaultDialog(
                        title: 'การแจ้งเตือน',
                        middleText: 'คุณต้องการออกจากระบบหรือไม่?',
                        backgroundColor: Colors.white,
                        titleStyle: const TextStyle(color: Colors.red),
                        middleTextStyle: const TextStyle(color: Colors.grey),
                        radius: 6,
                        textConfirm: 'ยืนยัน',
                        textCancel: 'ยกเลิก',
                        cancelTextColor: Colors.grey,
                        confirmTextColor: Colors.white,
                        buttonColor: Colors.red,
                        onConfirm: () {
                          Get.offAllNamed("/LoginPage");
                        },
                      );
                    },
                    child: const Icon(Icons.logout)),
              ],
            ),
          ],
        ),
      ),
      body: _filteredMenuItems.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        // กรองรายการเมนูตามคำค้นหา
                        _filteredMenuItems = _menuItems
                            .where((menuItem) => menuItem['strMeal']
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'เมนูค้นหา',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 15,
                        crossAxisCount: 2,
                      ),
                      itemCount: _filteredMenuItems.length,
                      itemBuilder: (context, index) {
                        final menuItem = _filteredMenuItems[index];
                        //  ตรวจสอบข้อมูลว่ามีการเลือกอาหารในตัวแปรมีหรือยัง
                        final check = selectCart.where(((element) =>
                            element['idMeal'] == menuItem['idMeal']));

                        return GestureDetector(
                          onTap: () {
                            //ตรวจสอบว่ามีเมนูอาหารหรือยัง
                            if (check.isEmpty) {
                              //เพิ่มเมนูอาหาร
                              setState(() {
                                selectCart.add(menuItem);
                              });
                            } else {
                              //ลบเมนูอาหาร
                              setState(() {
                                selectCart.removeWhere((element) =>
                                    element['idMeal'] == menuItem['idMeal']);
                              });
                            }
                          },
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            color: check.isNotEmpty
                                ? Colors.pink[100]
                                : Colors.white,
                            child: Column(
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.network(
                                    width: 190,
                                    height: 90,
                                    menuItem['strMealThumb'].toString(),
                                    fit: BoxFit.cover),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(menuItem['strMeal'].toString(),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.pink[400])),
                      onPressed: () {
                        //ตรวจสอบว่ามีเมนูอาหารหรือยัง
                        if (selectCart.isNotEmpty) {
                          Get.toNamed("/PaymentPage", arguments: selectCart);
                        } else {
                          //ถ้าไม่มีข้อมูลให้แจ้งเตือน
                          Get.snackbar(
                            'การแจ้งเตือน',
                            'กรุณาเลือกรายการก่อน!',
                            backgroundColor: Colors.pink[200],
                            colorText: Colors.white,
                            icon: const Icon(Icons.warning_rounded,
                                color: Colors.white),
                            snackPosition: SnackPosition.TOP,
                          );
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Next'),
                      ))
                ],
              ),
            )
          : Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('กำลังโหลด...'),
                )
              ],
            )),
    );
  }
}
