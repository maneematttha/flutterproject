import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  // รายการเมนูทั้งหมด
  List<Map<String, dynamic>> _menuItems = [];
  // รายการเมนูที่ค้นหา/กรองแล้ว
  List<Map<String, dynamic>> _filteredMenuItems = [];
  // รายการที่เลือกในตะกร้า
  List<Map<String, dynamic>> selectCart = [];
  bool _isLoading = true;
  String _selectedCategory = 'ทั้งหมด';

  // รายการเมนูเริ่มต้น (อาหารไทยพร้อมราคาเฉพาะตัว)
  final List<Map<String, dynamic>> _defaultMenus = [
    {
      'id': '1',
      'name': 'ข้าวกะเพราหมูกรอบ ไข่ดาว',
      'price': 65.0,
      'category': 'อาหารจานเดียว',
      'image_url': 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '2',
      'name': 'ข้าวผัดต้มยำกุ้งแม่น้ำ',
      'price': 85.0,
      'category': 'อาหารจานเดียว',
      'image_url': 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '3',
      'name': 'ผัดไทยกุ้งสด ห่อไข่',
      'price': 75.0,
      'category': 'อาหารจานเดียว',
      'image_url': 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '4',
      'name': 'ข้าวหมูกรอบ คั่วพริกเกลือ',
      'price': 60.0,
      'category': 'อาหารจานเดียว',
      'image_url': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '5',
      'name': 'ต้มยำกุ้งน้ำข้น หม้อไฟ',
      'price': 120.0,
      'category': 'ต้ม/แกง',
      'image_url': 'https://images.unsplash.com/photo-1548946526-f69e2424cf45?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '6',
      'name': 'ส้มตำไทยไข่เค็ม + ไก่ย่าง',
      'price': 80.0,
      'category': 'ยำ/ส้มตำ',
      'image_url': 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '7',
      'name': 'ข้าวหน้าเนื้อย่าง ซอสแจ่ว',
      'price': 95.0,
      'category': 'อาหารจานเดียว',
      'image_url': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '8',
      'name': 'ข้าวขาหมูตุ๋นยาจีน พิเศษ',
      'price': 55.0,
      'category': 'อาหารจานเดียว',
      'image_url': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '9',
      'name': 'ชาไทยเย็น หวานมัน',
      'price': 35.0,
      'category': 'เครื่องดื่ม',
      'image_url': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': '10',
      'name': 'น้ำมะพร้าวน้ำหอมปั่นนมสด',
      'price': 45.0,
      'category': 'เครื่องดื่ม',
      'image_url': 'https://images.unsplash.com/photo-1556881286-fc6915169721?w=500&auto=format&fit=crop&q=60',
    },
  ];

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. ลองดึงข้อมูลจากตาราง 'menus' ใน Supabase
      final data = await Supabase.instance.client
          .from('menus')
          .select()
          .order('created_at', ascending: true);

      if (data.isNotEmpty) {
        final parsed = (data as List).map((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'name': item['name']?.toString() ?? '',
            'price': (item['price'] as num?)?.toDouble() ?? 35.0,
            'category': item['category']?.toString() ?? 'ทั่วไป',
            'image_url': item['image_url']?.toString() ?? '',
          };
        }).toList();

        setState(() {
          _menuItems = parsed;
          _filteredMenuItems = parsed;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // หากยังไม่ได้สร้างตาราง menus ใน Supabase ให้ใช้เมนูเริ่มต้น
    }

    // 2. ใช้รายการเมนูเริ่มต้น
    setState(() {
      _menuItems = List.from(_defaultMenus);
      _filteredMenuItems = List.from(_defaultMenus);
      _isLoading = false;
    });
  }

  void _filterMenus() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredMenuItems = _menuItems.where((item) {
        final matchesQuery = item['name'].toString().toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'ทั้งหมด' ||
            item['category'] == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['ทั้งหมด', 'อาหารจานเดียว', 'ต้ม/แกง', 'ยำ/ส้มตำ', 'เครื่องดื่ม'];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pink[400],
        title: const Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'SkyFLASH เมนูอาหาร',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'หน้าร้านค้า (Restaurant Mode)',
            icon: const Icon(Icons.storefront_rounded, color: Colors.white),
            onPressed: () => Get.toNamed('/RestaurantDashboard'),
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Get.defaultDialog(
                title: 'การแจ้งเตือน',
                middleText: 'คุณต้องการออกจากระบบหรือไม่?',
                textConfirm: 'ยืนยัน',
                textCancel: 'ยกเลิก',
                confirmTextColor: Colors.white,
                buttonColor: Colors.red,
                onConfirm: () async {
                  await Supabase.instance.client.auth.signOut();
                  Get.offAllNamed("/LoginPage");
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: Colors.pink[400],
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      // ช่องค้นหา
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => _filterMenus(),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาเมนูอาหาร...',
                          prefixIcon: const Icon(Icons.search, color: Colors.pink),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterMenus();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                // หมวดหมู่เมนู (Category Pills)
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: Colors.pink[400],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          backgroundColor: Colors.grey[200],
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                              _filterMenus();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),

                // รายการอาหาร GridView
                Expanded(
                  child: _filteredMenuItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fastfood_outlined, size: 60, color: Colors.grey[400]),
                              const SizedBox(height: 10),
                              Text('ไม่พบเมนูที่คุณค้นหา', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredMenuItems.length,
                          itemBuilder: (context, index) {
                            final menuItem = _filteredMenuItems[index];
                            final isSelected = selectCart.any((item) => item['id'] == menuItem['id']);
                            final price = (menuItem['price'] as num?)?.toDouble() ?? 0.0;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectCart.removeWhere((item) => item['id'] == menuItem['id']);
                                  } else {
                                    selectCart.add(Map<String, dynamic>.from(menuItem));
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? Colors.pink[400]! : Colors.grey[200]!,
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.pink.withValues(alpha: 0.15)
                                          : Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // รูปภาพเมนู
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                            child: Image.network(
                                              menuItem['image_url'] ?? '',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Colors.pink[50],
                                                child: const Icon(Icons.restaurant, color: Colors.pink, size: 40),
                                              ),
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Container(
                                                  color: Colors.grey[100],
                                                  child: const Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.pink,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.check, color: Colors.white, size: 16),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // รายละเอียดเมนู
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            menuItem['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.pink[50],
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '฿${price.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    color: Colors.pink[700],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                isSelected ? Icons.remove_circle : Icons.add_circle,
                                                color: isSelected ? Colors.red : Colors.pink[400],
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // แถบสรุปการเลือกและปุ่มชำระเงิน
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[400],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          if (selectCart.isNotEmpty) {
                            Get.toNamed("/PaymentPage", arguments: selectCart);
                          } else {
                            Get.snackbar(
                              'คำแนะนำ',
                              'กรุณาเลือกเมนูที่ต้องการอย่างน้อย 1 รายการ',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.orangeAccent,
                              colorText: Colors.white,
                              margin: const EdgeInsets.all(16),
                              borderRadius: 12,
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'ชำระเงิน (${selectCart.length} รายการ)',
                              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}