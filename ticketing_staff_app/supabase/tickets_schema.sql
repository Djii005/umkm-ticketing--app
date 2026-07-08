-- Create custom enums for Tickets
CREATE TYPE ticket_priority AS ENUM ('low', 'medium', 'high', 'urgent');
CREATE TYPE ticket_status AS ENUM ('open', 'assigned', 'in_progress', 'pending_parts', 'resolved', 'closed');
CREATE TYPE service_type AS ENUM ('repair', 'maintenance', 'calibration', 'installation');
CREATE TYPE photo_type AS ENUM ('before', 'after', 'part');

-- Create Hospitals Table
CREATE TABLE public.hospitals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Link users.hospital_id to hospitals.id
ALTER TABLE public.users 
ADD CONSTRAINT fk_users_hospital 
FOREIGN KEY (hospital_id) REFERENCES public.hospitals(id) ON DELETE SET NULL;

-- Create Equipment Table
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

-- Create Sequence for Ticket Number Auto Generation
CREATE SEQUENCE public.ticket_number_seq START 1;

-- Create Tickets Table
CREATE TABLE public.tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_number TEXT UNIQUE,
    customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    hospital_id UUID NOT NULL REFERENCES public.hospitals(id) ON DELETE CASCADE,
    equipment_id UUID NOT NULL REFERENCES public.equipment(id) ON DELETE CASCADE,
    technician_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    priority ticket_priority NOT NULL DEFAULT 'medium',
    status ticket_status NOT NULL DEFAULT 'open',
    service_type service_type NOT NULL DEFAULT 'repair',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Function and Trigger to auto-generate ticket_number like TKT-20260001
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

-- Create Ticket Logs Table for lifecycle history
CREATE TABLE public.ticket_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Ticket Photos Table
CREATE TABLE public.ticket_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    caption TEXT,
    type photo_type NOT NULL DEFAULT 'before',
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for all new tables
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

-- ─── RLS POLICIES ──────────────────────────────────────────

-- Hospitals: Everyone authenticated can view, Admins can do everything
CREATE POLICY "Allow view hospitals to all authenticated" ON public.hospitals
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow write hospitals to admin only" ON public.hospitals
    FOR ALL TO authenticated USING (public.is_admin(auth.uid()));

-- Equipment: Everyone authenticated can view, Admins can do everything
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

