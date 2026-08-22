import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RestaurantDashboardPage extends StatefulWidget {
  const RestaurantDashboardPage({Key? key}) : super(key: key);

  @override
  RestaurantDashboardPageState createState() => RestaurantDashboardPageState();
}

class RestaurantDashboardPageState extends State<RestaurantDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _menus = [];
  bool _isLoading = true;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {})); // อัปเดต FAB เมื่อสลับแท็บ
    _loadData();
  }

  // ดึง restaurant_id ของร้านที่ user คนนี้เป็นเจ้าของ
  Future<String?> _getRestaurantId() async {
    if (_restaurantId != null) return _restaurantId;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final restaurantRes = await supabase
        .from('restaurants')
        .select('id')
        .eq('owner_id', userId)
        .maybeSingle();

    if (restaurantRes == null) return null;

    _restaurantId = restaurantRes['id'].toString();
    return _restaurantId;
  }

  void _subscribeToOrderChanges() {
    // ฟัง Real-time เมื่อมีออเดอร์ใหม่เข้ามา (เฉพาะร้านตัวเอง)
    supabase.from('orders').stream(primaryKey: ['id']).listen((data) {
      if (mounted && _restaurantId != null) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(
            data.where((o) => o['restaurant_id'] == _restaurantId),
          )..sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final restaurantId = await _getRestaurantId();

      if (restaurantId == null) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'แจ้งเตือน',
          'ไม่พบข้อมูลร้านของคุณ กรุณาติดต่อผู้ดูแลระบบ',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final ordersRes = await supabase
          .from('orders')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false);

      final menusRes = await supabase
          .from('menus')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: true);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(ordersRes);
        _menus = List<Map<String, dynamic>>.from(menusRes);
        _isLoading = false;
      });

      _subscribeToOrderChanges();
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Error', 'โหลดข้อมูลไม่สำเร็จ: $e');
    }
  }

  // ฟังก์ชันเปลี่ยนสถานะออเดอร์
  Future<void> _updateOrderStatus(String orderId, String newStatus, {String? droneId}) async {
    try {
      final payload = {'status': newStatus};
      if (droneId != null) {
        payload['drone_id'] = droneId;
      }
      await supabase.from('orders').update(payload).eq('id', orderId);

      Get.snackbar(
        'สำเร็จ',
        'อัปเดตสถานะออเดอร์เป็น: $newStatus เรียบร้อยแล้ว',
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      _loadData();
    } catch (e) {
      Get.snackbar('Error', 'ไม่สามารถอัปเดตได้: $e');
    }
  }

  // ฟังก์ชันเรียกโดรนมารับอาหาร
  Future<void> _dispatchDrone(String orderId) async {
    Get.defaultDialog(
      title: 'เรียกโดรน SkyFLASH',
      middleText: 'ต้องการเรียกลำ DRONE-01 มารับอาหารเพื่อบินส่งลูกค้าทันทีหรือไม่?',
      textConfirm: 'สั่งการโดรนบิน',
      textCancel: 'ยกเลิก',
      confirmTextColor: Colors.white,
      buttonColor: Colors.pink[400],
      onConfirm: () async {
        Get.back();
        await supabase.from('drones').update({'status': 'delivering'}).eq('id', 'DRONE-01');
        await _updateOrderStatus(orderId, 'delivering', droneId: 'DRONE-01');
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[400],
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'SkyFLASH จัดการร้านอาหาร',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'ออเดอร์เข้า'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'จัดการเมนู'),
            Tab(icon: Icon(Icons.bar_chart), text: 'สรุปยอดขาย'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(),
                _buildMenusTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              backgroundColor: Colors.pink[400],
              onPressed: () => _showEditMenuSheet(null),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // --- แท็บที่ 1: รายการออเดอร์ ---
  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 10),
            const Text('ยังไม่มีออเดอร์ในขณะนี้', style: TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final orderId = order['id']?.toString() ?? '';
        final status = order['status'] ?? 'pending';
        final grandTotal = (order['grand_total'] as num?)?.toDouble() ?? 0.0;
        final items = (order['items'] as List?) ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${orderId.substring(0, orderId.length >= 8 ? 8 : orderId.length)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                const Divider(height: 16),
                ...items.map((item) {
                  final name = item['name'] ?? 'อาหาร';
                  final qty = item['quantity'] ?? 1;
                  return Text('• $name x $qty', style: const TextStyle(fontSize: 14));
                }),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ยอดรวม:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('฿${grandTotal.toStringAsFixed(0)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink[700])),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (status == 'pending')
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white, size: 18),
                          label: const Text('รับออเดอร์ & เริ่มปรุง', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                          onPressed: () => _updateOrderStatus(orderId, 'cooking'),
                        ),
                      ),
                    if (status == 'cooking')
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.flight_takeoff, color: Colors.white, size: 18),
                          label: const Text('ปรุงเสร็จ ➔ เรียกโดรน', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[400]),
                          onPressed: () => _dispatchDrone(orderId),
                        ),
                      ),
                    if (status == 'delivering')
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flight, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('โดรนกำลังบินนำส่ง...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    String text = 'รอรับออเดอร์';
    if (status == 'cooking') {
      color = Colors.blue;
      text = 'กำลังปรุงอาหาร';
    } else if (status == 'delivering') {
      color = Colors.pink;
      text = 'โดรนกำลังส่ง';
    } else if (status == 'completed') {
      color = Colors.green;
      text = 'สำเร็จ';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  // --- แท็บที่ 2: จัดการเมนู ---
  Widget _buildMenusTab() {
    if (_menus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 10),
            const Text('ยังไม่มีเมนูอาหาร', style: TextStyle(fontSize: 16, color: Colors.black54)),
            const SizedBox(height: 4),
            const Text('กดปุ่ม + มุมล่างขวาเพื่อเพิ่มเมนู', style: TextStyle(fontSize: 13, color: Colors.black38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menus.length,
      itemBuilder: (context, index) {
        final menu = _menus[index];
        final price = (menu['price'] as num?)?.toDouble() ?? 0.0;
        final isAvailable = menu['is_available'] ?? true;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => _showEditMenuSheet(menu),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: isAvailable ? 1.0 : 0.4,
                child: Image.network(
                  menu['image_url'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                ),
              ),
            ),
            title: Text(
              menu['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isAvailable ? Colors.black87 : Colors.black45,
                decoration: isAvailable ? TextDecoration.none : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Text(
              isAvailable
                  ? '฿${price.toStringAsFixed(0)} • ${menu['category'] ?? ''}'
                  : '฿${price.toStringAsFixed(0)} • ${menu['category'] ?? ''} • งดขายชั่วคราว',
              style: TextStyle(color: isAvailable ? Colors.black54 : Colors.red[400]),
            ),
            trailing: const Icon(Icons.edit_note, color: Colors.pink),
          ),
        );
      },
    );
  }

  // Bottom Sheet: menu == null -> เพิ่มเมนูใหม่ / menu != null -> แก้ไขเมนูเดิม
  void _showEditMenuSheet(Map<String, dynamic>? menu) {
    final isNew = menu == null;
    final nameController = TextEditingController(text: menu?['name'] ?? '');
    final priceController = TextEditingController(text: menu != null ? '${menu['price']}' : '');
    final imageController = TextEditingController(text: menu?['image_url'] ?? '');
    String selectedCategory = menu?['category'] ?? 'อาหารจานเดียว';
    bool isAvailable = menu?['is_available'] ?? true;

    final categories = ['อาหารจานเดียว', 'ของทอด', 'ของหวาน', 'เครื่องดื่ม'];
    if (!categories.contains(selectedCategory)) categories.add(selectedCategory);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isNew ? 'เพิ่มเมนูใหม่' : 'แก้ไขเมนู',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'ชื่อเมนู', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'ราคา (บาท)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'หมวดหมู่', border: OutlineInputBorder()),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setSheetState(() => selectedCategory = val ?? selectedCategory),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'ลิงก์รูปภาพ (URL)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('เปิดขายเมนูนี้'),
                      subtitle: Text(isAvailable ? 'ลูกค้าเห็นและสั่งได้' : 'ซ่อน / งดขายชั่วคราว'),
                      value: isAvailable,
                      activeThumbColor: Colors.pink[400],
                      onChanged: (val) => setSheetState(() => isAvailable = val),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink[400],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                          if (name.isEmpty) {
                            Get.snackbar('แจ้งเตือน', 'กรุณากรอกชื่อเมนู');
                            return;
                          }
                          Navigator.pop(sheetContext);
                          if (isNew) {
                            _addMenu(
                              name: name,
                              price: price,
                              category: selectedCategory,
                              imageUrl: imageController.text.trim(),
                              isAvailable: isAvailable,
                            );
                          } else {
                            _updateMenu(
                              menuId: menu['id'].toString(),
                              name: name,
                              price: price,
                              category: selectedCategory,
                              imageUrl: imageController.text.trim(),
                              isAvailable: isAvailable,
                            );
                          }
                        },
                        child: Text(
                          isNew ? 'เพิ่มเมนู' : 'บันทึก',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    if (!isNew) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('ลบเมนูนี้'),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _confirmDeleteMenu(menu['id'].toString(), menu['name'] ?? '');
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addMenu({
    required String name,
    required double price,
    required String category,
    required String imageUrl,
    required bool isAvailable,
  }) async {
    if (_restaurantId == null) {
      Get.snackbar('Error', 'ไม่พบข้อมูลร้าน ไม่สามารถเพิ่มเมนูได้');
      return;
    }
    try {
      await supabase.from('menus').insert({
        'restaurant_id': _restaurantId,
        'name': name,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'is_available': isAvailable,
      });

      Get.snackbar(
        'สำเร็จ',
        'เพิ่มเมนู "$name" เรียบร้อยแล้ว',
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      _loadData();
    } catch (e) {
      Get.snackbar('Error', 'ไม่สามารถเพิ่มเมนูได้: $e');
    }
  }

  Future<void> _updateMenu({
    required String menuId,
    required String name,
    required double price,
    required String category,
    required String imageUrl,
    required bool isAvailable,
  }) async {
    try {
      await supabase.from('menus').update({
        'name': name,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'is_available': isAvailable,
      }).eq('id', menuId);

      Get.snackbar(
        'สำเร็จ',
        'อัปเดตเมนู "$name" เรียบร้อยแล้ว',
        backgroundColor: Colors.green[600],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      _loadData();
    } catch (e) {
      Get.snackbar('Error', 'ไม่สามารถอัปเดตเมนูได้: $e');
    }
  }

  void _confirmDeleteMenu(String menuId, String menuName) {
    Get.defaultDialog(
      title: 'ยืนยันการลบเมนู',
      middleText: 'ต้องการลบ "$menuName" ออกจากรายการหรือไม่?\nการลบไม่สามารถย้อนกลับได้',
      textConfirm: 'ลบเลย',
      textCancel: 'ยกเลิก',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await supabase.from('menus').delete().eq('id', menuId);
          Get.snackbar(
            'ลบสำเร็จ',
            'ลบ "$menuName" ออกจากเมนูแล้ว',
            backgroundColor: Colors.green[600],
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          _loadData();
        } catch (e) {
          Get.snackbar('Error', 'ไม่สามารถลบเมนูได้: $e');
        }
      },
    );
  }

  // --- แท็บที่ 3: สรุปยอดขาย ---
  Widget _buildAnalyticsTab() {
    final totalSales = _orders
        .where((o) => o['status'] == 'completed' || o['status'] == 'delivering')
        .fold(0.0, (sum, o) => sum + ((o['grand_total'] as num?)?.toDouble() ?? 0.0));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            color: Colors.pink[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('ยอดขายรวมทั้งหมด', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '฿${totalSales.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.pink[700]),
                  ),
                  const SizedBox(height: 8),
                  Text('จำนวนคำสั่งซื้อ: ${_orders.length} ออเดอร์', style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}