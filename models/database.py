# ============================================================
#  models/database.py  —  Supabase Client
#  Single source of truth for the DB connection.
#  All services import `supabase` from here.
# ============================================================

import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()  # reads .env file automatically

SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "")
SUPABASE_KEY: str = os.environ.get("SUPABASE_ANON_KEY", "")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise RuntimeError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in your .env file")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
