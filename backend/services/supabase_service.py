import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://igipojhbetjhgufxbvgs.supabase.co")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "sb_publishable_tEmbm32nMcjG0gVPFQtT8A_Cz64sK8T")

def get_supabase() -> Client:
    """สร้างและคืนค่า Supabase Client Instance สำหรับ Backend"""
    return create_client(SUPABASE_URL, SUPABASE_KEY)
