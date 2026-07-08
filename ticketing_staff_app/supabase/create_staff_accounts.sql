-- ==========================================
-- SQL SCRIPT: MEMBUAT AKUN ADMIN & TEKNISI
-- ==========================================
-- Jalankan query ini di SQL Editor Supabase Anda.

-- Aktifkan ekstensi pgcrypto untuk melakukan enkripsi kata sandi
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. BUAT AKUN ADMIN
-- Email: admin@gmail.com
-- Sandi: adminpassword123
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  aud,
  role,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'admin@gmail.com',
  crypt('adminpassword123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Administrator Arsya", "role": "admin"}',
  'authenticated',
  'authenticated',
  now(),
  now()
);

-- 2. BUAT AKUN TEKNISI
-- Email: teknisi@gmail.com
-- Sandi: teknisipassword123
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  aud,
  role,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'teknisi@gmail.com',
  crypt('teknisipassword123', gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Budi Teknisi", "role": "teknisi"}',
  'authenticated',
  'authenticated',
  now(),
  now()
);
