import 'package:flutter_order/view/checkout.dart';
import 'package:flutter_order/view/home.dart';
import 'package:flutter_order/view/login.dart';
import 'package:flutter_order/view/payment.dart';
import 'package:get/route_manager.dart';

//ฟังก์ชันสำหรับจัดการแต่ละหน้า
class AppPages {
  static final List<GetPage> pages = [
    GetPage(
      name: '/LoginPage',
      page: () => const LoginPage(),
    ),
    GetPage(
      name: '/HomePage',
      page: () => const HomePage(),
    ),
    GetPage(
      name: '/PaymentPage',
      page: () => const PaymentPage(),
    ),
    GetPage(
      name: '/CheckOutPage',
      page: () => const CheckOutPage(),
    ),
  ];
}
