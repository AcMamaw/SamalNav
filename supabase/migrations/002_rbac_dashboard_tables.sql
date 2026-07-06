-- ═══════════════════════════════════════════════════════════════════
-- SamalNav RBAC + Dashboard Schema
-- Run in Supabase SQL Editor (after profiles + favorites exist)
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. Profiles role column ─────────────────────────────────────────
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'tourist';

-- Add check constraint only if it doesn't exist yet
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_role_check'
  ) THEN
    ALTER TABLE profiles
    ADD CONSTRAINT profiles_role_check
    CHECK (role IN ('tourist', 'establishment', 'administrator', 'super_admin'));
  END IF;
END $$;

-- ── 2. Establishments ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS establishments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  description   TEXT,
  address       TEXT,
  lat           DOUBLE PRECISION,
  lng           DOUBLE PRECISION,
  category      TEXT NOT NULL DEFAULT 'Resort',
  contact_phone TEXT,
  is_verified   BOOLEAN NOT NULL DEFAULT false,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (owner_id)
);

-- ── 3. Destinations ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS destinations (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id  UUID REFERENCES establishments(id) ON DELETE SET NULL,
  name              TEXT NOT NULL,
  location          TEXT NOT NULL,
  lat               DOUBLE PRECISION NOT NULL,
  lng               DOUBLE PRECISION NOT NULL,
  category          TEXT NOT NULL,
  description       TEXT,
  image_url         TEXT,
  rating            NUMERIC(3,1) NOT NULL DEFAULT 0,
  is_active         BOOLEAN NOT NULL DEFAULT true,
  is_verified       BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 4. Bookings ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bookings (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id UUID NOT NULL REFERENCES establishments(id) ON DELETE CASCADE,
  tourist_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  destination_id   UUID REFERENCES destinations(id) ON DELETE SET NULL,
  service_name     TEXT NOT NULL,
  guest_count      INT NOT NULL DEFAULT 1,
  status           TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','confirmed','cancelled','completed')),
  scheduled_date   DATE NOT NULL DEFAULT CURRENT_DATE,
  eta_minutes      INT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 5. Transactions ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id UUID NOT NULL REFERENCES establishments(id) ON DELETE CASCADE,
  booking_id       UUID REFERENCES bookings(id) ON DELETE SET NULL,
  tourist_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount           NUMERIC(12,2) NOT NULL,
  status           TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','paid','refunded')),
  payment_method   TEXT DEFAULT 'cash',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 6. Establishment reviews ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS establishment_reviews (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id UUID NOT NULL REFERENCES establishments(id) ON DELETE CASCADE,
  destination_id   UUID REFERENCES destinations(id) ON DELETE SET NULL,
  tourist_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating           NUMERIC(2,1) NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment          TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 7. Location verifications ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS location_verifications (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id UUID REFERENCES establishments(id) ON DELETE SET NULL,
  destination_id   UUID REFERENCES destinations(id) ON DELETE SET NULL,
  name             TEXT NOT NULL,
  address          TEXT NOT NULL,
  lat              DOUBLE PRECISION NOT NULL,
  lng              DOUBLE PRECISION NOT NULL,
  category         TEXT NOT NULL,
  submitted_by     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status           TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending','approved','rejected')),
  reviewed_by      UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 8. Audit logs ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action_type TEXT NOT NULL,
  description TEXT NOT NULL,
  metadata    JSONB DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── 9. System settings ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS system_settings (
  key         TEXT PRIMARY KEY,
  value       JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_by  UUID REFERENCES profiles(id) ON DELETE SET NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO system_settings (key, value)
VALUES ('maintenance_mode', '{"enabled": false}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ═══════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS  (must exist BEFORE any RLS policies use them)
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role FROM public.profiles WHERE id = auth.uid()),
    'tourist'
  );
$$;

CREATE OR REPLACE FUNCTION public.log_audit(
  p_action_type TEXT,
  p_description TEXT,
  p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.audit_logs (user_id, action_type, description, metadata)
  VALUES (auth.uid(), p_action_type, p_description, p_metadata);
END;
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'tourist')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(profiles.display_name, EXCLUDED.display_name);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS destinations_updated_at ON destinations;
CREATE TRIGGER destinations_updated_at
  BEFORE UPDATE ON destinations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ═══════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE establishments ENABLE ROW LEVEL SECURITY;
ALTER TABLE destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE establishment_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- profiles
DROP POLICY IF EXISTS "profiles_select" ON profiles;
CREATE POLICY "profiles_select" ON profiles FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "profiles_update" ON profiles;
CREATE POLICY "profiles_update" ON profiles FOR UPDATE TO authenticated
  USING (id = auth.uid() OR public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "profiles_insert" ON profiles;
CREATE POLICY "profiles_insert" ON profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() OR public.current_user_role() = 'super_admin');

-- establishments
DROP POLICY IF EXISTS "establishments_select" ON establishments;
CREATE POLICY "establishments_select" ON establishments FOR SELECT TO authenticated
  USING (
    owner_id = auth.uid()
    OR public.current_user_role() IN ('administrator', 'super_admin')
  );

DROP POLICY IF EXISTS "establishments_insert" ON establishments;
CREATE POLICY "establishments_insert" ON establishments FOR INSERT TO authenticated
  WITH CHECK (owner_id = auth.uid() OR public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "establishments_update" ON establishments;
CREATE POLICY "establishments_update" ON establishments FOR UPDATE TO authenticated
  USING (owner_id = auth.uid() OR public.current_user_role() IN ('administrator', 'super_admin'));

-- destinations
DROP POLICY IF EXISTS "destinations_select" ON destinations;
CREATE POLICY "destinations_select" ON destinations FOR SELECT TO authenticated
  USING (
    is_active = true
    OR public.current_user_role() IN ('administrator', 'super_admin')
    OR establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "destinations_admin_all" ON destinations;
CREATE POLICY "destinations_admin_all" ON destinations FOR ALL TO authenticated
  USING (public.current_user_role() IN ('administrator', 'super_admin'))
  WITH CHECK (public.current_user_role() IN ('administrator', 'super_admin'));

-- bookings
DROP POLICY IF EXISTS "bookings_select" ON bookings;
CREATE POLICY "bookings_select" ON bookings FOR SELECT TO authenticated
  USING (
    tourist_id = auth.uid()
    OR establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator', 'super_admin')
  );

DROP POLICY IF EXISTS "bookings_insert" ON bookings;
CREATE POLICY "bookings_insert" ON bookings FOR INSERT TO authenticated
  WITH CHECK (
    tourist_id = auth.uid()
    OR public.current_user_role() IN ('establishment', 'administrator', 'super_admin')
  );

DROP POLICY IF EXISTS "bookings_update" ON bookings;
CREATE POLICY "bookings_update" ON bookings FOR UPDATE TO authenticated
  USING (
    establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator', 'super_admin')
  );

-- transactions
DROP POLICY IF EXISTS "transactions_select" ON transactions;
CREATE POLICY "transactions_select" ON transactions FOR SELECT TO authenticated
  USING (
    tourist_id = auth.uid()
    OR establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator', 'super_admin')
  );

DROP POLICY IF EXISTS "transactions_insert" ON transactions;
CREATE POLICY "transactions_insert" ON transactions FOR INSERT TO authenticated
  WITH CHECK (
    establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator', 'super_admin')
  );

DROP POLICY IF EXISTS "transactions_update" ON transactions;
CREATE POLICY "transactions_update" ON transactions FOR UPDATE TO authenticated
  USING (
    establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() = 'super_admin'
  );

-- establishment_reviews
DROP POLICY IF EXISTS "reviews_select" ON establishment_reviews;
CREATE POLICY "reviews_select" ON establishment_reviews FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "reviews_insert" ON establishment_reviews;
CREATE POLICY "reviews_insert" ON establishment_reviews FOR INSERT TO authenticated
  WITH CHECK (tourist_id = auth.uid());

-- location_verifications
DROP POLICY IF EXISTS "verifications_select" ON location_verifications;
CREATE POLICY "verifications_select" ON location_verifications FOR SELECT TO authenticated
  USING (
    submitted_by = auth.uid()
    OR public.current_user_role() IN ('administrator', 'super_admin')
  );

DROP POLICY IF EXISTS "verifications_insert" ON location_verifications;
CREATE POLICY "verifications_insert" ON location_verifications FOR INSERT TO authenticated
  WITH CHECK (submitted_by = auth.uid());

DROP POLICY IF EXISTS "verifications_update" ON location_verifications;
CREATE POLICY "verifications_update" ON location_verifications FOR UPDATE TO authenticated
  USING (public.current_user_role() IN ('administrator', 'super_admin'));

-- audit_logs
DROP POLICY IF EXISTS "audit_select" ON audit_logs;
CREATE POLICY "audit_select" ON audit_logs FOR SELECT TO authenticated
  USING (public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "audit_insert" ON audit_logs;
CREATE POLICY "audit_insert" ON audit_logs FOR INSERT TO authenticated
  WITH CHECK (true);

-- system_settings
DROP POLICY IF EXISTS "settings_select" ON system_settings;
CREATE POLICY "settings_select" ON system_settings FOR SELECT TO authenticated
  USING (public.current_user_role() IN ('administrator', 'super_admin'));

DROP POLICY IF EXISTS "settings_update" ON system_settings;
CREATE POLICY "settings_update" ON system_settings FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'super_admin');

-- ═══════════════════════════════════════════════════════════════════
-- SEED: Samal Island destinations
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO destinations (name, location, lat, lng, category, description, rating, is_active, is_verified)
SELECT v.name, v.location, v.lat, v.lng, v.category, v.description, v.rating, v.is_active, v.is_verified
FROM (VALUES
  ('Kaputian Beach', 'South Samal', 6.9644, 125.7235, 'Beach', 'Fine white sand with calm waters.', 4.9, true, true),
  ('Pearl Farm Resort', 'Kaputian, Samal', 7.0050, 125.7271, 'Resort', 'Resort built over clear water.', 4.9, true, true),
  ('Hagimit Falls', 'Penaplata, Samal', 7.0666, 125.7230, 'Falls', 'Multi-tiered waterfall with rock pools.', 4.7, true, true),
  ('Maxima Aquafun', 'Penaplata, Samal', 7.0425, 125.7275, 'Resort', 'Water park with slides and pools.', 4.6, true, true),
  ('Monfort Bat Cave', 'Babak, Samal', 7.1260, 125.7140, 'Historical', 'World-famous fruit bat colony.', 4.5, false, true),
  ('Vanishing Island', 'Babak District', 7.0700, 125.7100, 'Beach', 'Sandbar visible at low tide.', 4.7, true, true),
  ('Mt. Puting Bato', 'Bali-Bali, Samal', 7.0656, 125.7681, 'Mountain', 'Peak with Davao Gulf views.', 4.6, false, true),
  ('Talikud Island', 'Kaputian District', 6.9322, 125.6987, 'Island', 'Quiet island with snorkeling reefs.', 4.8, true, true),
  ('Secdea Beach Resort', 'Babak, Samal', 7.1772, 125.7264, 'Resort', 'Beach resort with cottages.', 4.8, true, false),
  ('Isla Reta Beach', 'Talikud Island, Samal', 6.9360, 125.7597, 'Beach', 'Crystal-clear waters and white sand.', 4.8, true, true)
) AS v(name, location, lat, lng, category, description, rating, is_active, is_verified)
WHERE NOT EXISTS (SELECT 1 FROM destinations d WHERE d.name = v.name);

-- Pending verification (only if an establishment user exists)
INSERT INTO location_verifications (name, address, lat, lng, category, submitted_by, status)
SELECT
  'Secdea Beach Resort', 'Babak, Samal', 7.1772, 125.7264, 'Resort', p.id, 'pending'
FROM profiles p
WHERE p.role = 'establishment'
  AND NOT EXISTS (
    SELECT 1 FROM location_verifications lv
    WHERE lv.name = 'Secdea Beach Resort' AND lv.status = 'pending'
  )
LIMIT 1;
