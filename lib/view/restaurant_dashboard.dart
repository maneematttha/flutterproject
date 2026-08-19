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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _subscribeToOrderChanges();
  }

  void _subscribeToOrderChanges() {
    // ฟัง Real-time เมื่อมีออเดอร์ใหม่เข้ามา
    supabase.from('orders').stream(primaryKey: ['id']).listen((data) {
      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data);
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final ordersRes = await supabase.from('orders').select().order('created_at', ascending: false);
      final menusRes = await supabase.from('menus').select().order('created_at', ascending: true);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(ordersRes);
        _menus = List<Map<String, dynamic>>.from(menusRes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
        // อัปเดตสถานะโดรนและออเดอร์
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
                      'Order #${orderId.substring(0, 8)}',
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menus.length,
      itemBuilder: (context, index) {
        final menu = _menus[index];
        final price = (menu['price'] as num?)?.toDouble() ?? 0.0;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                menu['image_url'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
              ),
            ),
            title: Text(menu['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('฿${price.toStringAsFixed(0)} • ${menu['category'] ?? ''}'),
            trailing: const Icon(Icons.edit_note, color: Colors.pink),
          ),
        );
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