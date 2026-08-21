import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  LatLng dronePosition = LatLng(13.7563, 100.5018); // เริ่มที่ร้าน
  final LatLng customerPosition = LatLng(13.7620, 100.5080); // พิกัดลูกค้า
  
  String droneStatus = 'Loading...';
  int battery = 100;
  double speed = 0.0;
  
  MapController mapController = MapController();
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchInitialPosition();
    _subscribeToDroneUpdates();
  }

  Future<void> _fetchInitialPosition() async {
    try {
      final data = await supabase
          .from('drones')
          .select()
          .eq('id', 'DRONE-01')
          .single();
          
      if (data != null && mounted) {
        setState(() {
          dronePosition = LatLng(data['current_lat'] ?? 13.7563, data['current_lng'] ?? 100.5018);
          droneStatus = data['status'] ?? 'unknown';
          battery = data['battery_level'] ?? 100;
          speed = (data['speed'] ?? 0.0).toDouble();
        });
        mapController.move(dronePosition, 16.0);
      }
    } catch (e) {
      print('Error fetching initial position: $e');
    }
  }

  void _subscribeToDroneUpdates() {
    _subscription = supabase.channel('public:drones')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'drones',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: 'DRONE-01'),
        callback: (payload) {
          final newData = payload.newRecord;
          if (mounted) {
            setState(() {
              dronePosition = LatLng(newData['current_lat'], newData['current_lng']);
              droneStatus = newData['status'];
              battery = newData['battery_level'];
              speed = (newData['speed'] ?? 0.0).toDouble();
            });
            mapController.move(dronePosition, 16.0);
          }
        }
      )
      .subscribe();
  }

  @override
  void dispose() {
    if (_subscription != null) {
      supabase.removeChannel(_subscription!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ติดตามโดรนจัดส่ง (Live Tracking)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: dronePosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.skyflash.app',
              ),
              MarkerLayer(
                markers: [
                  // ร้านอาหาร
                  Marker(
                    point: LatLng(13.7563, 100.5018),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.store, color: Colors.blue, size: 30),
                  ),
                  // ลูกค้า
                  Marker(
                    point: customerPosition,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.home, color: Colors.green, size: 30),
                  ),
                  // โดรน
                  Marker(
                    point: dronePosition,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.flight, color: Colors.pinkAccent, size: 40),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Panel แสดงข้อมูลด้านล่าง
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DRONE-01', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            droneStatus.toUpperCase(), 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(Icons.battery_charging_full, '$battery%', 'แบตเตอรี่'),
                        _buildInfoItem(Icons.speed, '${speed.toStringAsFixed(1)} m/s', 'ความเร็ว'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[700]),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }
}
