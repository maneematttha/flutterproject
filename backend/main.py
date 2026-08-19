import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import menus, orders, drone, payments

app = FastAPI(
    title="SkyFLASH Drone Delivery API",
    description="ระบบเซิร์ฟเวอร์กลางประสานงาน 3 ทาง: ลูกค้า ➔ ร้านอาหาร ➔ โดรน (FastAPI + WebSockets + Supabase)",
    version="1.0.0"
)

# ตั้งค่า CORS เพื่อให้ Flutter App และ Web Admin เรียกใช้งานได้
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# เชื่อมต่อเราเตอร์ทั้งหมด
app.include_router(menus.router)
app.include_router(orders.router)
app.include_router(drone.router)
app.include_router(payments.router)

@app.get("/")
def root():
    return {
        "service": "SkyFLASH Drone Delivery Backend API",
        "status": "online",
        "version": "1.0.0",
        "docs_url": "/docs"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
