# ⚡ SkyFLASH

ระบบสั่งอาหารและระบบจัดส่งทางอากาศอัจฉริยะ
แบบ Real-time

---

## 📌 Project Overview
**SkyFLASH** เป็นโปรเจกต์พัฒนาระบบสั่งอาหารของร้านตนเองผ่านแอปพลิเคชัน พร้อมรองรับการชำระเงินผ่าน QR Code และตรวจสอบการโอนเงินเข้าบัญชีอัตโนมัติ เชื่อมต่อกับระบบจัดส่งอาหารด้วยโดรนผ่านเซิร์ฟเวอร์สื่อสาร 2 ทาง (Customer & Drone Server)

---

## ✨ Key Features
* **ระบบลูกค้า (Customer App & Web):**
  * สั่งอาหารและเลือกเมนูผ่านแอปพลิเคชัน (Flutter)
  * ชำระเงินสะดวกผ่าน QR Code พร้อมระบบตรวจสอบสลิป/การโอนเงินอัตโนมัติ (Payment Verification)
  * หน้า Web (HTML) สำหรับบันทึกข้อมูลและเชื่อมต่อไปยังฐานข้อมูล
* **ระบบส่งอาหารด้วยโดรน (Drone Delivery & Server):**
  * ระบบเซิร์ฟเวอร์สื่อสาร 2 ทาง (Two-way Communication) ระหว่างฝั่งลูกค้าและฝั่งโดรน
  * ควบคุมและประมวลผลการส่งอาหารด้วย Raspberry Pi 5

---

## 🛠️ Tech Stack & Architecture

* **Frontend App:** Flutter (Cross-platform)
* **Frontend Web:** HTML (สำหรับเก็บข้อมูลและเชื่อมต่อฐานข้อมูล)
* **UI/UX Design:** Figma
* **Backend API:** FastAPI (Python) — Deploy บน **Render**
* **Database:** Supabase
* **Drone Hardware & Server:** Raspberry Pi 5
* **Version Control:** GitHub (สำหรับการทำงานร่วมกันในทีม)
