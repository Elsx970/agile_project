-- SQL Schema for AspiraNila Supabase Database Setup
-- You can run these commands directly in the Supabase SQL Editor

-- 1. Table for Registrations and Approved Accounts
CREATE TABLE IF NOT EXISTS public.registrations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    id_number TEXT UNIQUE NOT NULL, -- NPM for students, NIP for lecturers
    password TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('mahasiswa', 'dosen', 'tendik', 'admin')),
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) or disable as needed for direct testing
ALTER TABLE public.registrations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read-write for demo" ON public.registrations FOR ALL USING (true) WITH CHECK (true);

-- 2. Table for Aspirations
CREATE TABLE IF NOT EXISTS public.aspirations (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_role TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    upvote_count INTEGER DEFAULT 0,
    upvoted_by_user_ids TEXT[] DEFAULT '{}',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'diperiksa', 'selesai')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.aspirations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read-write for demo" ON public.aspirations FOR ALL USING (true) WITH CHECK (true);

-- 3. Table for Comments / Discussion Thread
CREATE TABLE IF NOT EXISTS public.comments (
    id TEXT PRIMARY KEY,
    aspiration_id TEXT REFERENCES public.aspirations(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL,
    user_name TEXT NOT NULL,
    user_role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read-write for demo" ON public.comments FOR ALL USING (true) WITH CHECK (true);

-- --- Mock Data for Testing Setup ---
INSERT INTO public.registrations (id, name, id_number, password, role, is_approved) VALUES
('req_1', 'Dr. Budi Utomo, M.T.', '19880415', 'dosenbudi', 'dosen', FALSE),
('req_2', 'Andi Pratama', '2217051088', 'mhsandi', 'mahasiswa', FALSE)
ON CONFLICT (id_number) DO NOTHING;

INSERT INTO public.aspirations (id, title, description, category, user_id, user_name, user_role, is_anonymous, upvote_count, upvoted_by_user_ids, status) VALUES
('asp_1', 'Fasilitas Lab Komputer Rusak', 'AC di Lab Komputer 3 Gedung H Jurusan Teknik Elektro mati sejak 2 minggu lalu. Mahasiswa merasa sangat gerah saat praktikum, dan beberapa komputer mengalami overheat.', 'Fasilitas', '1', 'M. Anazky Putra Irwansya', 'Mahasiswa', FALSE, 42, ARRAY['2', '3'], 'diperiksa'),
('asp_2', 'Keterlambatan Input Nilai KHS', 'Mohon untuk para dosen agar segera menginput nilai semester ganjil. Batas waktu KRS semester berikutnya sudah dekat, tapi nilai mata kuliah Pemrograman Mobile belum keluar.', 'Akademik', '1', 'M. Anazky Putra Irwansya', 'Mahasiswa', TRUE, 15, ARRAY['3'], 'pending')
ON CONFLICT (id) DO NOTHING;
