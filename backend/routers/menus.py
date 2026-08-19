from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from services.supabase_service import get_supabase

router = APIRouter(prefix="/api/menus", tags=["Menus"])

class MenuItemCreate(BaseModel):
    name: str
    price: float
    category: str = "อาหารจานเดียว"
    description: Optional[str] = None
    image_url: Optional[str] = None
    restaurant_id: Optional[str] = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    is_available: bool = True

@router.get("/")
def get_all_menus(category: Optional[str] = None):
    """ดึงรายการเมนูอาหารทั้งหมด"""
    supabase = get_supabase()
    query = supabase.from_("menus").select("*").eq("is_available", True)
    if category and category != "ทั้งหมด":
        query = query.eq("category", category)
    res = query.execute()
    return {"status": "success", "count": len(res.data), "data": res.data}

@router.post("/")
def create_menu_item(item: MenuItemCreate):
    """เพิ่มรายการเมนูอาหารใหม่ (สำหรับร้านค้า)"""
    supabase = get_supabase()
    res = supabase.from_("menus").insert(item.dict()).execute()
    if not res.data:
        raise HTTPException(status_code=400, detail="Failed to create menu item")
    return {"status": "success", "data": res.data[0]}

@router.delete("/{menu_id}")
def delete_menu_item(menu_id: str):
    """ลบรายการอาหาร"""
    supabase = get_supabase()
    res = supabase.from_("menus").delete().eq("id", menu_id).execute()
    return {"status": "success", "message": "Menu item deleted"}
