from typing import Dict, List
from fastapi import WebSocket

class ConnectionManager:
    """
    จัดการการเชื่อมต่อ WebSocket แบบ Real-time
    - เชื่อมต่อระหว่าง โดรน (Pi 5) ➔ Server ➔ แอปพลิเคชัน (ลูกค้า/ร้านค้า)
    """
    def __init__(self):
        # เก็บการเชื่อมต่อแยกตาม order_id หรือ drone_id
        # { "order_id": [ WebSocket1, WebSocket2, ... ] }
        self.order_rooms: Dict[str, List[WebSocket]] = {}
        # { "drone_id": WebSocket }
        self.active_drones: Dict[str, WebSocket] = {}

    async def connect_client(self, order_id: str, websocket: WebSocket):
        await websocket.accept()
        if order_id not in self.order_rooms:
            self.order_rooms[order_id] = []
        self.order_rooms[order_id].append(websocket)

    def disconnect_client(self, order_id: str, websocket: WebSocket):
        if order_id in self.order_rooms:
            if websocket in self.order_rooms[order_id]:
                self.order_rooms[order_id].remove(websocket)
            if not self.order_rooms[order_id]:
                del self.order_rooms[order_id]

    async def connect_drone(self, drone_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_drones[drone_id] = websocket

    def disconnect_drone(self, drone_id: str):
        if drone_id in self.active_drones:
            del self.active_drones[drone_id]

    async def broadcast_drone_telemetry(self, order_id: str, telemetry_data: dict):
        """บรอดแคสต์พิกัด GPS ของโดรนไปยังลูกค้าและร้านค้าที่กำลังดูออเดอร์นี้"""
        if order_id in self.order_rooms:
            disconnected_sockets = []
            for connection in self.order_rooms[order_id]:
                try:
                    await connection.send_json(telemetry_data)
                except Exception:
                    disconnected_sockets.append(connection)
            
            for ws in disconnected_sockets:
                self.disconnect_client(order_id, ws)

manager = ConnectionManager()
