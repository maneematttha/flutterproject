/// SkyFLASH — Order Model
/// 
/// Data model สำหรับคำสั่งซื้อ
/// ใช้สำหรับบันทึกลง Supabase และแสดงผลในหน้า Checkout
library;

import 'package:flutter_order/models/menu_item.dart';

enum OrderStatus {
  pending,    // รอรับออเดอร์
  preparing,  // กำลังเตรียม
  delivering, // กำลังจัดส่ง (โดรน)
  completed,  // สำเร็จ
  cancelled,  // ยกเลิก
}

class Order {
  final String? id;
  final String userId;
  final List<MenuItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;

  Order({
    this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// คำนวณราคารวมจากรายการทั้งหมด
  static double calculateTotal(List<MenuItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// แปลงเป็น Map สำหรับบันทึกลง Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'total_amount': totalAmount,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// แปลง status เป็นข้อความภาษาไทย
  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'รอรับออเดอร์';
      case OrderStatus.preparing:
        return 'กำลังเตรียมอาหาร';
      case OrderStatus.delivering:
        return 'โดรนกำลังจัดส่ง';
      case OrderStatus.completed:
        return 'ส่งสำเร็จ';
      case OrderStatus.cancelled:
        return 'ยกเลิกแล้ว';
    }
  }
}
