-- ==============================================================================
-- 🚀 SkyFLASH Database Schema (Supabase PostgreSQL) - Safe Re-run Version
-- ระบบสั่งอาหารและจัดส่งด้วยโดรนแบบ 3 ทาง: ลูกค้า ➔ ร้านอาหาร ➔ โดรน
-- (สามารถกดรันซ้ำกี่รอบก็ได้ โดยไม่มี Error)
-- ==============================================================================

-- 1. สร้าง Extensions ที่จำเป็น
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- ตารางที่ 1: PROFILES (ข้อมูลผู้ใช้: ลูกค้า / ร้านค้า / แอดมิน / คนคุมโดรน)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT,
    full_name TEXT,
    email TEXT,
    phone TEXT,
    address TEXT,
    avatar_url TEXT,
    role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'restaurant', 'admin', 'drone_operator')),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- ตารางที่ 2: RESTAURANTS (ข้อมูลร้านอาหาร)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.restaurants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    address TEXT,
    lat DOUBLE PRECISION DEFAULT 13.7563,  -- พิกัดร้านค้า (Latitude)
    lng DOUBLE PRECISION DEFAULT 100.5018, -- พิกัดร้านค้า (Longitude)
    phone TEXT,
    is_open BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- ตารางที่ 3: MENUS (ข้อมูลเมนูอาหารและราคา)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    category TEXT DEFAULT 'อาหารจานเดียว',
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- ตารางที่ 4: DRONES (ข้อมูลและสถานะโดรน Raspberry Pi 5)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.drones (
    id TEXT PRIMARY KEY, -- เช่น 'DRONE-01', 'DRONE-02'
    name TEXT NOT NULL,
    model TEXT DEFAULT 'SkyFLASH Drone Pi5',
    status TEXT DEFAULT 'idle' CHECK (status IN ('idle', 'busy', 'delivering', 'returning', 'maintenance')),
    current_lat DOUBLE PRECISION DEFAULT 13.7563,
    current_lng DOUBLE PRECISION DEFAULT 100.5018,
    current_altitude DOUBLE PRECISION DEFAULT 0.0,
    battery_level INTEGER DEFAULT 100,
    speed DOUBLE PRECISION DEFAULT 0.0,
    last_heartbeat TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- ตารางที่ 5: ORDERS (ข้อมูลคำสั่งซื้อทั้งหมด)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE SET NULL,
    drone_id TEXT REFERENCES public.drones(id) ON DELETE SET NULL,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    food_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    delivery_fee NUMERIC(10, 2) NOT NULL DEFAULT 20.00,
    grand_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    delivery_lat DOUBLE PRECISION,
    delivery_lng DOUBLE PRECISION,
    delivery_address TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'cooking', 'ready_for_pickup', 'drone_assigned', 'delivering', 'completed', 'cancelled')),
    payment_method TEXT DEFAULT 'qr_code' CHECK (payment_method IN ('qr_code', 'cash')),
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed')),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- ตารางที่ 6: PAYMENTS (ข้อมูลการชำระเงินและตรวจสอบสลิป)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    payment_method TEXT DEFAULT 'promptpay_qr',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed')),
    slip_url TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- ตารางที่ 7: DRONE_TELEMETRY_LOGS (บันทึกเส้นทางบิน GPS Real-time)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.drone_telemetry_logs (
    id BIGSERIAL PRIMARY KEY,
    drone_id TEXT REFERENCES public.drones(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    altitude DOUBLE PRECISION,
    battery INTEGER,
    speed DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ==============================================================================
-- 🚀 เปิดใช้งาน Supabase Realtime อย่างปลอดภัย (เช็คก่อนเพิ่ม)
-- ==============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'orders'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'drones'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.drones;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'menus'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.menus;
    END IF;
END $$;

-- ==============================================================================
-- 🛡️ Row Level Security (RLS) - ลบ Policy เก่าก่อนสร้างใหม่ (ป้องกัน Error ซ้ำ)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- ลบ Policies เดิมหากมีอยู่
DROP POLICY IF EXISTS "Public can view restaurants" ON public.restaurants;
DROP POLICY IF EXISTS "Public can view menus" ON public.menus;
DROP POLICY IF EXISTS "Public can view drones" ON public.drones;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Allow update orders" ON public.orders;
DROP POLICY IF EXISTS "Allow select payments" ON public.payments;
DROP POLICY IF EXISTS "Allow insert payments" ON public.payments;

-- สร้าง Policies ใหม่
CREATE POLICY "Public can view restaurants" ON public.restaurants FOR SELECT USING (true);
CREATE POLICY "Public can view menus" ON public.menus FOR SELECT USING (true);
CREATE POLICY "Public can view drones" ON public.drones FOR SELECT USING (true);

CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (true);
CREATE POLICY "Users can create orders" ON public.orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update orders" ON public.orders FOR UPDATE USING (true);

CREATE POLICY "Allow select payments" ON public.payments FOR SELECT USING (true);
CREATE POLICY "Allow insert payments" ON public.payments FOR INSERT WITH CHECK (true);

-- ==============================================================================
-- 🍱 ข้อมูลเริ่มต้น (Sample Initial Seed Data)
-- ==============================================================================

-- 1. เพิ่มร้านอาหารต้นแบบ
INSERT INTO public.restaurants (id, name, description, image_url, address, lat, lng, phone, is_open)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'SkyFLASH Gourmet Kitchen (ครัวโดรนหลัก)',
    'ร้านอาหารพรีเมียม จัดส่งรวดเร็วด้วยโดรนอัตโนมัติภายใน 15 นาที',
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500&auto=format&fit=crop&q=60',
    'อาคารนวัตกรรมการบิน มหาวิทยาลัย',
    13.7563,
    100.5018,
    '081-234-5678',
    true
) ON CONFLICT (id) DO NOTHING;

-- 2. เพิ่มรายการเมนูอาหารไทย
INSERT INTO public.menus (restaurant_id, name, description, price, category, image_url, is_available) VALUES
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ข้าวกะเพราหมูกรอบ ไข่ดาว', 'หมูกรอบสูตรเด็ด ผัดกะเพรารสจัดจ้าน เสิร์ฟพร้อมไข่ดาวกรอบ', 65.00, 'อาหารจานเดียว', 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=500&auto=format&fit=crop&q=60', true),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ข้าวผัดต้มยำกุ้งแม่น้ำ', 'ข้าวผัดเครื่องต้มยำหอมกรุ่น กุ้งแม่น้ำตัวใหญ่สดฉ่ำ', 85.00, 'อาหารจานเดียว', 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=500&auto=format&fit=crop&q=60', true),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ผัดไทยกุ้งสด ห่อไข่', 'เส้นจันท์เหนียวนุ่ม ผัดซอสมะขามสูตรโบราณ กุ้งสดตัวโต', 75.00, 'อาหารจานเดียว', 'https://images.unsplash.com/photo-1559314809-0d155014e29e?w=500&auto=format&fit=crop&q=60', true),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ข้าวหมูกรอบ คั่วพริกเกลือ', 'หมูกรอบคั่วกระเทียมพริกเกลือ คลุกข้าวสวยร้อนๆ', 60.00, 'อาหารจานเดียว', 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500&auto=format&fit=crop&q=60', true),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ต้มยำกุ้งน้ำข้น หม้อไฟ', 'ต้มยำน้ำข้นครบรส เปรี้ยว เผ็ด มัน หอมสมุนไพรไทย', 120.00, 'ต้ม/แกง', 'https://images.unsplash.com/photo-1548946526-f69e2424cf45?w=500&auto=format&fit=crop&q=60', true),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ส้มตำไทยไข่เค็ม + ไก่ย่าง', 'ส้มตำรสแซ่บ เส้นกรอบ พร้อมไก่ย่างหมักสมุนไพร', 80.00, 'ยำ/ส้มตำ', 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=500&auto=format&fit=crop&q=60', true),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ข้าวหน้าเนื้อย่าง ซอสแจ่ว', 'เนื้อวัวคัดพิเศษย่างหอมๆ เสิร์ฟคู่น้ำจิ้มแจ่วรสเด็ด', 95.00, 'อาหารจานเดียว', 'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=60', true),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'ชาไทยเย็น หวานมัน', 'ชาตรามือพรีเมียม ชงสดหวานมันกลมกล่อม', 35.00, 'เครื่องดื่ม', 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=60', true),
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'น้ำมะพร้าวน้ำหอมปั่นนมสด', 'มะพร้าวน้ำหอมสดปั่นนมสด หอมหวานชื่นใจ', 45.00, 'เครื่องดื่ม', 'https://images.unsplash.com/photo-1556881286-fc6915169721?w=500&auto=format&fit=crop&q=60', true);

-- 3. เพิ่มโดรนเริ่มต้น 2 ลำ
INSERT INTO public.drones (id, name, model, status, current_lat, current_lng, current_altitude, battery_level, speed) VALUES
('DRONE-01', 'SkyFLASH Alpha-1', 'Raspberry Pi 5 Octacopter', 'idle', 13.7563, 100.5018, 0.0, 100, 0.0),
('DRONE-02', 'SkyFLASH Beta-2', 'Raspberry Pi 5 Hexacopter', 'idle', 13.7570, 100.5025, 0.0, 95, 0.0)
ON CONFLICT (id) DO NOTHING;
