import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final data = Get.arguments;

  // Filtered menu items based on search query
  List _filteredMenuItems = [];

  @override
  void initState() {
    super.initState();
    _filteredMenuItems = data;
    print(data);
    // Initialize filtered menu items with all menu items
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[400],
        title: const Text('รายหารอาหารที่สั่ง'),
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
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('${index + 1} .'),
                          Text(menuItem['strMeal'].toString(),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      IconButton(
                          onPressed: () {
                            if (_filteredMenuItems.isNotEmpty) {
                              Get.defaultDialog(
                                title: 'การแจ้งเตือน',
                                middleText: 'คุณต้องการลบรายการนี้หรือไม่?',
                                backgroundColor: Colors.white,
                                titleStyle: const TextStyle(color: Colors.red),
                                middleTextStyle:
                                    const TextStyle(color: Colors.grey),
                                radius: 6,
                                textConfirm: 'ยืนยัน',
                                textCancel: 'ยกเลิก',
                                cancelTextColor: Colors.grey,
                                confirmTextColor: Colors.white,
                                buttonColor: Colors.red,
                                onConfirm: () {
                                  Get.back();
                                  setState(() {
                                    _filteredMenuItems.removeWhere((element) =>
                                        element['idMeal'] ==
                                        menuItem['idMeal']);
                                  });
                                },
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_forever))
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 29),
              child: Text(
                  'สรุปค่าใช้จ่าย ทั้งหมด ${_filteredMenuItems.length * 35} บาท',
                  overflow: TextOverflow.ellipsis),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('เงินสด', textAlign: TextAlign.center),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.pink[400])),
                      onPressed: () {
                        //ถ้ามีข้อมูลแล้วให้สามารถสั่งได้
                        if (_filteredMenuItems.isNotEmpty) {
                          Get.defaultDialog(
                            title: 'การแจ้งเตือน',
                            middleText: 'คุณต้องการชำระเงินหรือไม่?',
                            backgroundColor: Colors.white,
                            titleStyle: const TextStyle(color: Colors.red),
                            middleTextStyle:
                                const TextStyle(color: Colors.grey),
                            radius: 6,
                            textConfirm: 'ยืนยัน',
                            textCancel: 'ยกเลิก',
                            cancelTextColor: Colors.grey,
                            confirmTextColor: Colors.white,
                            buttonColor: Colors.red,
                            onConfirm: () {
                              Get.offAllNamed("/CheckOutPage");
                            },
                          );
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
                        child: Text('Next To logout'),
                      )),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
