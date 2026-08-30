-- ============================================================================
-- AL-GHOZALI MESSENGER - SUPABASE DATABASE SCHEMA (LENGKAP DENGAN GRANT PERMISSION)
-- Jalankan skrip ini di: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ============================================================================

-- 1. Buat Tabel Users / Guru
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    nama TEXT NOT NULL,
    mata_pelajaran TEXT DEFAULT 'Belum diatur',
    avatar TEXT DEFAULT '',
    status TEXT DEFAULT 'Offline',
    last_seen TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 2. Buat Tabel Messages (Pesan Chat)
CREATE TABLE IF NOT EXISTS public.messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    message_text TEXT DEFAULT '',
    message_type TEXT DEFAULT 'TEXT', -- 'TEXT' atau 'IMAGE'
    attachment_url TEXT DEFAULT '',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 3. Indeks untuk Query Cepat Pesan
CREATE INDEX IF NOT EXISTS idx_messages_sender_receiver ON public.messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at ASC);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- 4. Berikan Hak Akses (GRANT) Penuh ke Role anon & authenticated
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON TABLE public.users TO anon, authenticated;
GRANT ALL ON TABLE public.messages TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- 5. Aktifkan Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 6. Kebijakan Keamanan (Policies) untuk Akses Anonim / Publik (Akses Frontend)
-- Kebijakan Users
DROP POLICY IF EXISTS "Allow public read users" ON public.users;
CREATE POLICY "Allow public read users" ON public.users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert users" ON public.users;
CREATE POLICY "Allow public insert users" ON public.users FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update users" ON public.users;
CREATE POLICY "Allow public update users" ON public.users FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Allow public delete users" ON public.users;
CREATE POLICY "Allow public delete users" ON public.users FOR DELETE USING (true);

-- Kebijakan Messages
DROP POLICY IF EXISTS "Allow public read messages" ON public.messages;
CREATE POLICY "Allow public read messages" ON public.messages FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow public insert messages" ON public.messages;
CREATE POLICY "Allow public insert messages" ON public.messages FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update messages" ON public.messages;
CREATE POLICY "Allow public update messages" ON public.messages FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Allow public delete messages" ON public.messages;
CREATE POLICY "Allow public delete messages" ON public.messages FOR DELETE USING (true);

-- 7. Tambahkan ke Realtime Publication Secara Aman (Tidak akan error jika sudah ada)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' 
    AND schemaname = 'public' 
    AND tablename = 'users'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
  END IF;
END $$;

-- ============================================================================
-- SELESAI! Database siap digunakan oleh Al-Ghozali Messenger.
-- ============================================================================
