import uuid
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from typing import Optional
from services.supabase_service import get_supabase
from services.connection_manager import manager

router = APIRouter(prefix="/api/drones", tags=["Drones"])

class TelemetryReport(BaseModel):
    drone_id: str
    order_id: Optional[str] = None
    lat: float
    lng: float
    altitude: float = 25.0
    battery: int = 100
    speed: float = 12.5
    status: str = "delivering"

@router.get("/")
def get_all_drones():
    """ดึงสถานะโดรนทุกลำ (พิกัดล่าสุด, แบตเตอรี่, สถานะการบิน)"""
    supabase = get_supabase()
    res = supabase.from_("drones").select("*").execute()
    return {"status": "success", "data": res.data}

@router.post("/telemetry")
async def report_telemetry_http(data: TelemetryReport):
    """API สำหรับโดรนส่งพิกัดผ่าน HTTP POST"""
    supabase = get_supabase()
    try:
        # 1. อัปเดตพิกัดล่าสุดของโดรน
        supabase.from_("drones").update({
            "current_lat": data.lat,
            "current_lng": data.lng,
            "current_altitude": data.altitude,
            "battery_level": data.battery,
            "speed": data.speed,
            "status": data.status
        }).eq("id", data.drone_id).execute()

        # 2. บันทึก Log ประวัติเส้นทางบิน
        log_entry = {
            "drone_id": data.drone_id,
            "lat": data.lat,
            "lng": data.lng,
            "altitude": data.altitude,
            "battery": data.battery,
            "speed": data.speed
        }
        
        # ตรวจสอบว่า order_id เป็น UUID ถูกต้องหรือไม่ก่อนบันทึก
        if data.order_id:
            try:
                uuid.UUID(str(data.order_id))
                log_entry["order_id"] = str(data.order_id)
            except (ValueError, TypeError):
                pass

        supabase.from_("drone_telemetry_logs").insert(log_entry).execute()

        # 3. บรอดแคสต์ผ่าน WebSocket ไปยังแอปมือถือ
        if data.order_id:
            await manager.broadcast_drone_telemetry(data.order_id, data.dict())

        return {"status": "success", "message": "Telemetry received and updated", "data": data.dict()}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# ==============================================================================
# 🛰️ WebSockets: สตรีมพิกัด GPS Real-time
# ==============================================================================

@router.websocket("/ws/drone/{drone_id}")
async def websocket_drone_endpoint(websocket: WebSocket, drone_id: str):
    await manager.connect_drone(drone_id, websocket)
    supabase = get_supabase()
    try:
        while True:
            data = await websocket.receive_json()
            order_id = data.get("order_id")
            lat = data.get("lat")
            lng = data.get("lng")
            altitude = data.get("altitude", 25.0)
            battery = data.get("battery", 100)
            speed = data.get("speed", 10.0)

            supabase.from_("drones").update({
                "current_lat": lat,
                "current_lng": lng,
                "current_altitude": altitude,
                "battery_level": battery,
                "speed": speed
            }).eq("id", drone_id).execute()

            if order_id:
                telemetry = {
                    "drone_id": drone_id,
                    "order_id": order_id,
                    "lat": lat,
                    "lng": lng,
                    "altitude": altitude,
                    "battery": battery,
                    "speed": speed
                }
                await manager.broadcast_drone_telemetry(order_id, telemetry)
    except WebSocketDisconnect:
        manager.disconnect_drone(drone_id)

@router.websocket("/ws/tracking/{order_id}")
async def websocket_client_tracking_endpoint(websocket: WebSocket, order_id: str):
    await manager.connect_client(order_id, websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect_client(order_id, websocket)
