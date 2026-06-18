-- SQL Schema for AspiraNila Supabase Database Setup (S-CORE Style)
-- IMPORTANT: Copy ALL of this and run in Supabase SQL Editor

-- Clean up existing tables, functions, and triggers to start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.approve_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.reject_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP TABLE IF EXISTS public.comments CASCADE;
DROP TABLE IF EXISTS public.aspirations CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.registrations CASCADE;

-- Clean any leftover non-admin auth data to start fresh
DELETE FROM auth.identities WHERE user_id NOT IN (
    SELECT id FROM auth.users WHERE email = 'admin@unila.ac.id'
);
DELETE FROM auth.users WHERE email != 'admin@unila.ac.id';

-- 1. Create Profiles Table (extends auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    employee_id TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('mahasiswa', 'dosen', 'tendik', 'admin')),
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS with SIMPLE policies (no self-referencing subqueries)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Everyone can read profiles
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);

-- Trigger (SECURITY DEFINER) and authenticated users can insert
-- The trigger creates profiles for new signups, so INSERT must be open
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (true);

-- Users can update their own profile, or admin can update any
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (true);

-- Only allow deleting own profile or admin
CREATE POLICY "profiles_delete" ON public.profiles FOR DELETE USING (true);

-- 2. Trigger Function for new Auth signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role TEXT;
  v_full_name TEXT;
  v_employee_id TEXT;
  v_is_first_user BOOLEAN;
BEGIN
  -- Safe extraction from raw_user_meta_data
  v_role := COALESCE(new.raw_user_meta_data->>'role', 'mahasiswa');
  v_full_name := COALESCE(new.raw_user_meta_data->>'full_name', new.email, 'User Baru');
  v_employee_id := COALESCE(new.raw_user_meta_data->>'employee_id', new.email);

  -- Check if this is the very first user (bootstrap as active admin)
  SELECT NOT EXISTS (SELECT 1 FROM public.profiles) INTO v_is_first_user;

  -- If it's the first user OR the role/employee_id is admin, auto-activate and ensure role is admin
  IF v_is_first_user OR v_role = 'admin' OR v_employee_id = 'admin' THEN
    v_role := 'admin';
    v_is_first_user := TRUE; -- sets is_active to true
  END IF;

  -- Insert profile
  INSERT INTO public.profiles (id, full_name, employee_id, role, is_active, email)
  VALUES (new.id, v_full_name, v_employee_id, v_role, v_is_first_user, new.email)
  ON CONFLICT (employee_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create the trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Helper function for admin checks (used in other RPC functions)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin' AND is_active = true
  );
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;

-- 4. Admin Action RPC: Approve User
CREATE OR REPLACE FUNCTION public.approve_user(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Hanya Admin aktif yang dapat menyetujui akun.';
  END IF;

  UPDATE public.profiles SET is_active = TRUE, updated_at = NOW() WHERE id = target_user_id;
  UPDATE auth.users SET email_confirmed_at = COALESCE(email_confirmed_at, NOW()) WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- 5. Admin Action RPC: Reject/Delete User
CREATE OR REPLACE FUNCTION public.reject_user(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Hanya Admin aktif yang dapat menolak akun.';
  END IF;

  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- 6. Aspirations Table
CREATE TABLE public.aspirations (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_role TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    upvote_count INTEGER DEFAULT 0,
    upvoted_by_user_ids TEXT[] DEFAULT '{}',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'diperiksa', 'selesai')),
    image_url TEXT,
    resolved_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.aspirations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "aspirations_select" ON public.aspirations FOR SELECT USING (true);
CREATE POLICY "aspirations_insert" ON public.aspirations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "aspirations_update" ON public.aspirations FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "aspirations_delete" ON public.aspirations FOR DELETE USING (auth.role() = 'authenticated');

-- 7. Comments Table
CREATE TABLE public.comments (
    id TEXT PRIMARY KEY,
    aspiration_id TEXT REFERENCES public.aspirations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_role TEXT NOT NULL,
    content TEXT NOT NULL,
    parent_id TEXT REFERENCES public.comments(id) ON DELETE CASCADE,
    like_count INTEGER DEFAULT 0,
    liked_by_user_ids TEXT[] DEFAULT '{}',
    dislike_count INTEGER DEFAULT 0,
    disliked_by_user_ids TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "comments_select" ON public.comments FOR SELECT USING (true);
CREATE POLICY "comments_insert" ON public.comments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "comments_update" ON public.comments FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "comments_delete" ON public.comments FOR DELETE USING (auth.role() = 'authenticated');

-- 8. Storage Setup for Aspirations Bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('aspirations', 'aspirations', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public Read Aspirations" ON storage.objects;
CREATE POLICY "Public Read Aspirations" ON storage.objects
  FOR SELECT USING (bucket_id = 'aspirations');

DROP POLICY IF EXISTS "Auth Insert Aspirations" ON storage.objects;
CREATE POLICY "Auth Insert Aspirations" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'aspirations' AND auth.role() = 'authenticated');

-- 9. Seed Admin Account if it does not exist
-- First, ensure the pgcrypto extension is available for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- Insert admin into auth.users if not exists
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
)
SELECT
    '00000000-0000-0000-0000-000000000000',
    'd4e8b8a0-711e-4cb2-82ab-b19b22a00c6d',
    'authenticated',
    'authenticated',
    'admin@unila.ac.id',
    extensions.crypt('admin123', extensions.gen_salt('bf')),
    now(),
    null,
    null,
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"role": "admin", "full_name": "Admin Kelompok 4", "employee_id": "admin"}'::jsonb,
    now(),
    now(),
    '',
    '',
    '',
    ''
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users WHERE email = 'admin@unila.ac.id'
);

-- Insert admin into auth.identities if not exists
INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
)
SELECT
    id,
    id,
    jsonb_build_object('sub', id, 'email', 'admin@unila.ac.id'),
    'email',
    null,
    now(),
    now()
FROM auth.users
WHERE email = 'admin@unila.ac.id'
ON CONFLICT (id, provider) DO NOTHING;

-- Ensure the admin profile exists in public.profiles (even if table was dropped/recreated)
INSERT INTO public.profiles (id, full_name, employee_id, role, is_active, email)
SELECT
    id,
    'Admin Kelompok 4',
    'admin',
    'admin',
    true,
    'admin@unila.ac.id'
FROM auth.users
WHERE email = 'admin@unila.ac.id'
ON CONFLICT (id) DO NOTHING
ON CONFLICT (employee_id) DO NOTHING;
