from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Any
from services.supabase_service import get_supabase

router = APIRouter(prefix="/api/orders", tags=["Orders"])

class OrderCreate(BaseModel):
    customer_id: Optional[str] = None
    restaurant_id: Optional[str] = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    items: List[dict]
    food_total: float
    delivery_fee: float = 20.0
    grand_total: float
    delivery_address: Optional[str] = "พิกัดจุดรับอาหารอัตโนมัติ"
    delivery_lat: Optional[float] = 13.7580
    delivery_lng: Optional[float] = 100.5030
    payment_method: str = "qr_code"

class OrderStatusUpdate(BaseModel):
    status: str  # pending, cooking, ready_for_pickup, drone_assigned, delivering, completed, cancelled
    drone_id: Optional[str] = None

@router.get("/")
def get_orders(status: Optional[str] = None, restaurant_id: Optional[str] = None):
    """ดึงรายการออเดอร์ทั้งหมด (สำหรับร้านค้าและแดชบอร์ด)"""
    supabase = get_supabase()
    query = supabase.from_("orders").select("*").order("created_at", desc=True)
    if status:
        query = query.eq("status", status)
    if restaurant_id:
        query = query.eq("restaurant_id", restaurant_id)
    res = query.execute()
    return {"status": "success", "count": len(res.data), "data": res.data}

@router.get("/{order_id}")
def get_order_by_id(order_id: str):
    """ดึงข้อมูลออเดอร์รายตัว"""
    supabase = get_supabase()
    res = supabase.from_("orders").select("*").eq("id", order_id).maybe_single().execute()
    if not res.data:
        raise HTTPException(status_code=404, detail="Order not found")
    return {"status": "success", "data": res.data}

@router.post("/")
def create_order(order: OrderCreate):
    """ลูกค้าสร้างคำสั่งซื้อใหม่"""
    supabase = get_supabase()
    data = order.dict()
    data["status"] = "pending"
    data["payment_status"] = "paid" if order.payment_method == "qr_code" else "pending"
    res = supabase.from_("orders").insert(data).execute()
    if not res.data:
        raise HTTPException(status_code=400, detail="Failed to create order")
    return {"status": "success", "message": "Order placed successfully", "data": res.data[0]}

@router.patch("/{order_id}/status")
def update_order_status(order_id: str, update_data: OrderStatusUpdate):
    """ร้านค้าหรือระบบอัปเดตสถานะออเดอร์ (เช่น กำลังปรุง, เรียกโดรน, จัดส่งสำเร็จ)"""
    supabase = get_supabase()
    payload = {"status": update_data.status}
    if update_data.drone_id:
        payload["drone_id"] = update_data.drone_id
    res = supabase.from_("orders").update(payload).eq("id", order_id).execute()
    return {"status": "success", "message": f"Order status updated to {update_data.status}", "data": res.data}

@router.post("/{order_id}/dispatch-drone")
def dispatch_drone_to_order(order_id: str, drone_id: str = "DRONE-01"):
    """ร้านอาหารกดปุ่ม 'เรียกโดรน SkyFLASH' มารับอาหารเพื่อบินส่งลูกค้า"""
    supabase = get_supabase()
    # 1. อัปเดตสถานะโดรนเป็น busy/delivering
    supabase.from_("drones").update({"status": "delivering"}).eq("id", drone_id).execute()
    # 2. อัปเดตออเดอร์เป็น drone_assigned / delivering
    res = supabase.from_("orders").update({
        "status": "delivering",
        "drone_id": drone_id
    }).eq("id", order_id).execute()
    return {
        "status": "success",
        "message": f"โดรน {drone_id} ได้รับคำสั่งบินส่งออเดอร์ {order_id} เรียบร้อยแล้ว",
        "data": res.data
    }
