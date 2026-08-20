# ⚡ SkyFLASH

ระบบสั่งอาหารอัจฉริยะและการจัดส่งอาหารอัตโนมัติผ่านโดรน (Smart Restaurant & Drone Delivery System) แบบ Real-time

---

## 📌 Project Overview
**SkyFLASH** เป็นโปรเจกต์พัฒนาระบบสั่งอาหารของร้านอาหาร พร้อมเชื่อมต่อการจัดส่งผ่านโดรนอัตโนมัติ รองรับการสั่งอาหารผ่าน QR Code, ตรวจสอบสถานะการชำระเงินอัตโนมัติ และควบคุมการบินของโดรนแบบสองทาง (Customer & Drone Server)

---

## ✨ Key Features
* **ระบบลูกค้า (Customer App & Web):**
  * สแกน QR Code เพื่อเลือกดูเมนูและสั่งอาหาร
  * หน้า Landing Page / Form สำหรับเก็บข้อมูลและเชื่อมต่อฐานข้อมูล
  * ระบบตรวจสอบการโอนเงินเข้าบัญชีอัตโนมัติ (Payment Verification)
* **ระบบส่งอาหารด้วยโดรน (Drone Delivery & Server):**
  * ระบบเซิร์ฟเวอร์สื่อสาร 2 ทาง (Two-way Communication) ระหว่างลูกค้าและโดรน
  * ควบคุมและขับเคลื่อนการส่งอาหารด้วย Raspberry Pi 5

---

## 🛠️ Tech Stack & Architecture

* **Frontend App:** Flutter (Cross-platform)
* **Frontend Web:** HTML (สำหรับเก็บข้อมูลและเชื่อมต่อฐานข้อมูล)
* **UI/UX Design:** Figma
* **Backend API:** FastAPI (Python) — Deploy บน **Render**
* **Database:** Supabase
* **Drone Hardware & Server:** Raspberry Pi 5
* **Version Control:** GitHub (สำหรับการทำงานร่วมกันในทีม)
