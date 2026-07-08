-- ==========================================
-- PT. Arsya Anakta Medikal - Ticketing System
-- Consolidated Master Database Schema Setup
-- ==========================================

-- ─── CLEANUP (Drop existing objects if any to ensure clean setup) ─────────
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP TABLE IF EXISTS public.ticket_photos CASCADE;
DROP TABLE IF EXISTS public.ticket_logs CASCADE;
DROP TABLE IF EXISTS public.tickets CASCADE;
DROP TABLE IF EXISTS public.equipment CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.hospitals CASCADE;
DROP SEQUENCE IF EXISTS public.ticket_number_seq;

-- Drop existing types (Enums)
DROP TYPE IF EXISTS public.user_role;
DROP TYPE IF EXISTS public.ticket_priority;
DROP TYPE IF EXISTS public.ticket_status;
DROP TYPE IF EXISTS public.service_type;
DROP TYPE IF EXISTS public.photo_type;

-- ─── ENUMS SETUP ──────────────────────────────────────────────────────────
CREATE TYPE public.user_role AS ENUM ('admin', 'teknisi', 'customer');
CREATE TYPE public.ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE public.ticket_status AS ENUM ('open', 'assigned', 'in_progress', 'pending_parts', 'resolved', 'closed');
CREATE TYPE public.service_type AS ENUM ('repair', 'maintenance', 'calibration', 'installation');
CREATE TYPE public.photo_type AS ENUM ('before', 'after', 'part');

-- ─── HOSPITALS TABLE ──────────────────────────────────────────────────────
CREATE TABLE public.hospitals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─── USERS TABLE (Extends Supabase auth.users) ────────────────────────────
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    role public.user_role NOT NULL DEFAULT 'customer',
    hospital_id UUID REFERENCES public.hospitals(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─── EQUIPMENT TABLE ──────────────────────────────────────────────────────
CREATE TABLE public.equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hospital_id UUID NOT NULL REFERENCES public.hospitals(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    brand TEXT NOT NULL,
    model TEXT NOT NULL,
    serial_number TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    installation_date DATE,
    warranty_expiry DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─── TICKETS SEQUENCE & TABLE ─────────────────────────────────────────────
CREATE SEQUENCE public.ticket_number_seq START 1;

CREATE TABLE public.tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number TEXT UNIQUE,
    customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    hospital_id UUID NOT NULL REFERENCES public.hospitals(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES public.equipment(id) ON DELETE CASCADE,
    technician_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    priority public.ticket_priority NOT NULL DEFAULT 'medium',
    status public.ticket_status NOT NULL DEFAULT 'open',
    service_type public.service_type NOT NULL DEFAULT 'repair',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Function and Trigger to auto-generate ticket_number like TKT-YYYY0001
CREATE OR REPLACE FUNCTION public.generate_ticket_number()
RETURNS TRIGGER AS $$
DECLARE
    seq_val INT;
    year_str TEXT;
BEGIN
    seq_val := nextval('public.ticket_number_seq');
    year_str := to_char(CURRENT_DATE, 'YYYY');
    NEW.ticket_number := 'TKT-' || year_str || lpad(seq_val::text, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generate_ticket_number
BEFORE INSERT ON public.tickets
FOR EACH ROW
WHEN (NEW.ticket_number IS NULL)
EXECUTE FUNCTION public.generate_ticket_number();

-- ─── TICKET LOGS TABLE (Lifecycle History) ──────────────────────────────
CREATE TABLE public.ticket_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─── TICKET PHOTOS TABLE ──────────────────────────────────────────────────
CREATE TABLE public.ticket_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    caption TEXT,
    type public.photo_type NOT NULL DEFAULT 'before',
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─── AUTH REGISTRATION TRIGGER FUNCTION (Resilient Version) ───────────────
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
DECLARE
    default_role public.user_role := 'customer'::public.user_role;
    meta_role text;
BEGIN
    -- Extract role from metadata safely
    IF new.raw_user_meta_data IS NOT NULL THEN
        meta_role := new.raw_user_meta_data->>'role';
    ELSE
        meta_role := NULL;
    END IF;
    
    INSERT INTO public.users (id, email, full_name, role)
    VALUES (
        new.id, 
        new.email, 
        COALESCE(new.raw_user_meta_data->>'full_name', 'Unknown User'),
        CASE 
            WHEN meta_role = 'admin' THEN 'admin'::public.user_role
            WHEN meta_role = 'teknisi' THEN 'teknisi'::public.user_role
            ELSE default_role
        END
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function on new auth.users creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ─── ROW LEVEL SECURITY (RLS) ACTIVATION ──────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_photos ENABLE ROW LEVEL SECURITY;


-- Create helper function to check admin status safely bypassing RLS
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = user_id AND role = 'admin'::public.user_role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ─── RLS POLICIES ──────────────────────────────────────────────────────────

-- Users Policies
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT TO authenticated USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON public.users
    FOR SELECT TO authenticated USING (public.is_admin(auth.uid()));

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Hospitals Policies
CREATE POLICY "Allow view hospitals to all authenticated" ON public.hospitals
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow write hospitals to admin only" ON public.hospitals
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Equipment Policies
CREATE POLICY "Allow view equipment to all authenticated" ON public.equipment
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow write equipment to admin only" ON public.equipment
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Tickets Policies
CREATE POLICY "Customers can view their own tickets" ON public.tickets
    FOR SELECT TO authenticated USING (customer_id = auth.uid());

CREATE POLICY "Technicians can view tickets assigned to them" ON public.tickets
    FOR SELECT TO authenticated USING (technician_id = auth.uid());

CREATE POLICY "Admins can view all tickets" ON public.tickets
    FOR SELECT TO authenticated USING (public.is_admin(auth.uid()));

CREATE POLICY "Customers can create tickets" ON public.tickets
    FOR INSERT TO authenticated WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Admins can create/update all tickets" ON public.tickets
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

CREATE POLICY "Technicians can update tickets assigned to them" ON public.tickets
    FOR UPDATE TO authenticated USING (technician_id = auth.uid());

-- Ticket Logs Policies
CREATE POLICY "View logs for related tickets" ON public.ticket_logs
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.tickets t 
            WHERE t.id = ticket_id AND (
                t.customer_id = auth.uid() OR 
                t.technician_id = auth.uid() OR
                public.is_admin(auth.uid())
            )
        )
    );

CREATE POLICY "Create logs for related tickets" ON public.ticket_logs
    FOR INSERT TO authenticated WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.tickets t 
            WHERE t.id = ticket_id AND (
                t.customer_id = auth.uid() OR 
                t.technician_id = auth.uid() OR
                public.is_admin(auth.uid())
            )
        )
    );

-- Ticket Photos Policies
CREATE POLICY "View photos for related tickets" ON public.ticket_photos
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.tickets t 
            WHERE t.id = ticket_id AND (
                t.customer_id = auth.uid() OR 
                t.technician_id = auth.uid() OR
                public.is_admin(auth.uid())
            )
        )
    );

CREATE POLICY "Upload photos for related tickets" ON public.ticket_photos
    FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.tickets t 
            WHERE t.id = ticket_id AND (
                t.customer_id = auth.uid() OR 
                t.technician_id = auth.uid() OR
                public.is_admin(auth.uid())
            )
        )
    );

