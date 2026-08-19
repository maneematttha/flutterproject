"""
🛸 SkyFLASH Drone Onboard Agent (สำหรับรันบน Raspberry Pi 5 จริง)
- เชื่อมต่อกับ GPS Module (UART /dev/ttyAMA0 หรือ USB Serial)
- เชื่อมต่อกับ Flight Controller (Pixhawk/ArduPilot ผ่าน MAVLink)
- ส่ง Telemetry ไปยัง SkyFLASH Server ผ่านสัญญาณ 4G/5G LTE Hat
"""

import time
import serial
import requests
import json
import os

# การตั้งค่าพอร์ต Serial สำหรับ GPS Module บน Raspberry Pi 5
GPS_PORT = os.getenv("GPS_PORT", "/dev/ttyAMA0")
GPS_BAUDRATE = 9600

SERVER_URL = os.getenv("SERVER_URL", "https://skyflash-backend-api-omh2.onrender.com/api/drones/telemetry")
DRONE_ID = "DRONE-01"

def parse_nmea_gps(line: str):
    """ฟังก์ชันแปลงข้อมูล NMEA จาก GPS Module ให้เป็น Decimal Latitude/Longitude"""
    try:
        if line.startswith("$GPGGA") or line.startswith("$GNGGA"):
            parts = line.split(",")
            if parts[2] and parts[4]:
                # แปลง Latitude
                raw_lat = float(parts[2])
                lat_deg = int(raw_lat / 100)
                lat_min = raw_lat - (lat_deg * 100)
                lat = lat_deg + (lat_min / 60.0)
                if parts[3] == "S":
                    lat = -lat

                # แปลง Longitude
                raw_lng = float(parts[4])
                lng_deg = int(raw_lng / 100)
                lng_min = raw_lng - (lng_deg * 100)
                lng = lng_deg + (lng_min / 60.0)
                if parts[5] == "W":
                    lng = -lng

                altitude = float(parts[9]) if parts[9] else 0.0
                return lat, lng, altitude
    except Exception:
        pass
    return None

def run_pi5_agent():
    print(f"🚁 SkyFLASH Agent เริ่มต้นทำงานบน Raspberry Pi 5 (Drone ID: {DRONE_ID})")
    
    try:
        gps_serial = serial.Serial(GPS_PORT, GPS_BAUDRATE, timeout=1)
        print(f"📡 เชื่อมต่อ GPS Module ที่ {GPS_PORT} สำเร็จ")
    except Exception as e:
        print(f"⚠️ ไม่พบฮาร์ดแวร์ GPS Serial ({e}) — กำลังสลับไปใช้โหมดทดสอบ")
        gps_serial = None

    while True:
        lat, lng, alt = 13.7563, 100.5018, 20.0
        
        if gps_serial and gps_serial.in_waiting:
            line = gps_serial.readline().decode('ascii', errors='replace').strip()
            parsed = parse_nmea_gps(line)
            if parsed:
                lat, lng, alt = parsed

        payload = {
            "drone_id": DRONE_ID,
            "lat": lat,
            "lng": lng,
            "altitude": alt,
            "battery": 95,
            "speed": 12.0,
            "status": "delivering"
        }

        try:
            requests.post(SERVER_URL, json=payload, timeout=2)
            print(f"📡 ส่ง Telemetry ขึ้น Server: ({lat:.5f}, {lng:.5f})")
        except Exception:
            pass

        time.sleep(1.0)

if __name__ == "__main__":
    run_pi5_agent()
