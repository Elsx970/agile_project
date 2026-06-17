-- SQL Schema for AspiraNila Supabase Database Setup (S-CORE Style)
-- You can copy and run these commands directly in the Supabase SQL Editor

-- Clean up existing tables, functions, and triggers to start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.approve_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.reject_user(UUID) CASCADE;
DROP TABLE IF EXISTS public.comments CASCADE;
DROP TABLE IF EXISTS public.aspirations CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.registrations CASCADE;

-- 1. Create Profiles Table (extends auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    employee_id TEXT UNIQUE NOT NULL, -- NPM (Mahasiswa) or NIP (Dosen/Tendik)
    role TEXT NOT NULL CHECK (role IN ('mahasiswa', 'dosen', 'tendik', 'admin')),
    is_active BOOLEAN NOT NULL DEFAULT FALSE, -- FALSE = Pending approval
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read for all profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow users to update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Allow admin manage all profiles" ON public.profiles FOR ALL USING (
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 2. Create Trigger Function to automatically handle new Auth signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_role TEXT;
  v_full_name TEXT;
  v_employee_id TEXT;
  v_is_first_user BOOLEAN;
BEGIN
  -- Safe extraction from raw_user_meta_data to prevent null pointer exceptions
  BEGIN
    v_role := new.raw_user_meta_data->>'role';
    v_full_name := new.raw_user_meta_data->>'full_name';
    v_employee_id := new.raw_user_meta_data->>'employee_id';
  EXCEPTION WHEN OTHERS THEN
    v_role := NULL;
    v_full_name := NULL;
    v_employee_id := NULL;
  END;

  -- Apply fallbacks if data is missing
  v_role := COALESCE(v_role, 'mahasiswa');
  v_full_name := COALESCE(v_full_name, new.email, 'User Baru');
  v_employee_id := COALESCE(v_employee_id, new.email);
  
  -- Check if this is the very first user in the database (bootstrap as active admin)
  SELECT NOT EXISTS (SELECT 1 FROM public.profiles) INTO v_is_first_user;
  
  IF v_is_first_user THEN
    v_role := 'admin';
  END IF;

  -- Safe insert block to handle potential unique constraint violations on employee_id
  BEGIN
    INSERT INTO public.profiles (id, full_name, employee_id, role, is_active, email)
    VALUES (
      new.id,
      v_full_name,
      v_employee_id,
      v_role,
      v_is_first_user
    );
  EXCEPTION WHEN OTHERS THEN
    -- Fallback: If employee_id is duplicate or causes issue, use new.id to guarantee uniqueness and prevent signup crash
    INSERT INTO public.profiles (id, full_name, employee_id, role, is_active, email)
    VALUES (
      new.id,
      v_full_name,
      new.id::text,
      v_role,
      v_is_first_user
    );
  END;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create the trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. Create Admin Action RPC: Approve User
CREATE OR REPLACE FUNCTION public.approve_user(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Check if caller is active Admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin' AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Hanya Admin aktif yang dapat menyetujui akun.';
  END IF;

  -- Set active in profiles
  UPDATE public.profiles
  SET is_active = TRUE, updated_at = NOW()
  WHERE id = target_user_id;

  -- Confirm email in auth.users so they can log in immediately without verification email
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
  WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- 4. Create Admin Action RPC: Reject/Delete User
CREATE OR REPLACE FUNCTION public.reject_user(target_user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Check if caller is active Admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin' AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Hanya Admin aktif yang dapat menolak akun.';
  END IF;

  -- Delete from auth.users (which cascades to profiles)
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;


-- 5. Table for Aspirations
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.aspirations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow read for all aspirations" ON public.aspirations FOR SELECT USING (true);
CREATE POLICY "Allow create for authenticated users" ON public.aspirations FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update for authenticated users" ON public.aspirations FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Allow delete for admin or owner" ON public.aspirations FOR DELETE USING (
  auth.uid() = user_id OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- 6. Table for Comments / Discussion Thread
CREATE TABLE public.comments (
    id TEXT PRIMARY KEY,
    aspiration_id TEXT REFERENCES public.aspirations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_role TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow read for all comments" ON public.comments FOR SELECT USING (true);
CREATE POLICY "Allow create for authenticated users" ON public.comments FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Allow update/delete for owner or admin" ON public.comments FOR ALL USING (
  auth.uid() = user_id OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
