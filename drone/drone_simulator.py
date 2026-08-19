"""
🛸 SkyFLASH Drone GPS Simulator (โปรแกรมจำลองการบินของโดรน)
- ใช้สำหรับทดสอบระบบ GPS Real-time และการสตรีมพิกัดไปยัง FastAPI / Supabase
- จำลองการบินจาก 'ร้านอาหาร' ➔ ไปยัง 'พิกัดลูกค้า' ➔ บินกลับฐาน (Return to Base)
"""

import time
import math
import requests
import json

# ตั้งค่า URL ของ Backend ที่ออนไลน์แล้วบน Render
API_BASE_URL = "https://skyflash-backend-api-omh2.onrender.com/api/drones/telemetry"

DRONE_ID = "DRONE-01"

# พิกัดร้านอาหาร (จุดเริ่มต้น)
RESTAURANT_LAT = 13.7563
RESTAURANT_LNG = 100.5018

# พิกัดลูกค้า (จุดปลายทางส่งอาหาร)
CUSTOMER_LAT = 13.7620
CUSTOMER_LNG = 100.5080

def interpolate_coordinates(start_lat, start_lng, end_lat, end_lng, steps=30):
    """คำนวณจุดพิกัดเส้นทางการบินแบบเป็นขั้นบันได (Waypoints)"""
    points = []
    for i in range(steps + 1):
        ratio = i / steps
        lat = start_lat + (end_lat - start_lat) * ratio
        lng = start_lng + (end_lng - start_lng) * ratio
        points.append((lat, lng))
    return points

def simulate_delivery_mission(order_id: str = "sample-order-001"):
    print(f"🚀 เริ่มต้นภารกิจโดรน {DRONE_ID} สำหรับ Order: {order_id}")
    print("=" * 60)

    # 1. จำลองการบินไปหาลูกค้า (Delivery Leg)
    waypoints = interpolate_coordinates(RESTAURANT_LAT, RESTAURANT_LNG, CUSTOMER_LAT, CUSTOMER_LNG, steps=25)
    battery = 100
    
    print("🛫 โดรน Takeoff กำลังบินออกจากร้านอาหาร...")
    for idx, (lat, lng) in enumerate(waypoints):
        altitude = 25.0 if 0 < idx < len(waypoints) else 0.0 # ไต่ระดับที่ 25 เมตร
        speed = 12.5 if 0 < idx < len(waypoints) else 0.0    # ความเร็ว 12.5 m/s (45 km/h)
        battery -= 0.5

        payload = {
            "drone_id": DRONE_ID,
            "order_id": order_id,
            "lat": round(lat, 6),
            "lng": round(lng, 6),
            "altitude": altitude,
            "battery": int(battery),
            "speed": speed,
            "status": "delivering" if idx < len(waypoints) else "completed"
        }

        try:
            res = requests.post(API_BASE_URL, json=payload, timeout=2)
            progress = int((idx / len(waypoints)) * 100)
            print(f"[{progress:3d}%] 🛸 พิกัด: ({lat:.5f}, {lng:.5f}) | สูง: {altitude}m | แบต: {battery:.0f}% | ส่งข้อมูล: {res.status_code}")
        except Exception as e:
            print(f"⚠️ ไม่สามารถเชื่อมต่อ Backend ได้: {e}")

        time.sleep(1.0) # ส่งข้อมูลทุกๆ 1 วินาที

    print("=" * 60)
    print("✅ โดรนลงจอดและส่งมอบอาหารสำเร็จเรียบร้อย! (Mission Completed)")

if __name__ == "__main__":
    simulate_delivery_mission()
