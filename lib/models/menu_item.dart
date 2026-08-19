/// SkyFLASH — MenuItem Model
/// 
/// Data model สำหรับรายการอาหาร
/// ใช้ทั้งตอนดึงจาก API และส่งข้อมูลระหว่างหน้า
library;

class MenuItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;

  MenuItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.price = 35.0,
    this.quantity = 1,
  });

  /// สร้างจาก JSON (TheMealDB API format)
  factory MenuItem.fromMealDbJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      imageUrl: json['strMealThumb'] ?? '',
    );
  }

  /// สร้างจาก JSON (Supabase / FastAPI format - สำหรับอนาคต)
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 35.0,
    );
  }

  /// แปลงเป็น Map สำหรับส่งระหว่างหน้า
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'price': price,
      'quantity': quantity,
    };
  }

  /// คำนวณราคารวมของรายการนี้
  double get subtotal => price * quantity;
}
