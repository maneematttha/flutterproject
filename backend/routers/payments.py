from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from services.supabase_service import get_supabase

router = APIRouter(prefix="/api/payments", tags=["Payments"])

class PaymentCreate(BaseModel):
    order_id: str
    amount: float
    payment_method: str = "promptpay_qr"
    slip_url: Optional[str] = None

@router.post("/verify")
def verify_payment(payment: PaymentCreate):
    """
    ตรวจสอบการชำระเงิน (Mock Slip Verification / PromptPay Webhook)
    - เมื่อตรวจสอบผ่าน ➔ ปรับสถานะ Order เป็น 'paid' และแจ้งร้านอาหารทันที
    """
    supabase = get_supabase()
    
    # 1. บันทึกข้อมูลการชำระเงิน
    pay_res = supabase.from_("payments").insert({
        "order_id": payment.order_id,
        "amount": payment.amount,
        "payment_method": payment.payment_method,
        "status": "paid",
        "slip_url": payment.slip_url
    }).execute()

    # 2. อัปเดตสถานะออเดอร์เป็น paid
    supabase.from_("orders").update({
        "payment_status": "paid"
    }).eq("id", payment.order_id).execute()

    return {
        "status": "success",
        "message": "การชำระเงินได้รับการตรวจสอบและยืนยันเรียบร้อยแล้ว",
        "data": pay_res.data
    }
