-- ═══════════════════════════════════════════════════════════════════
-- SamalNav FULL SCHEMA — from Tables 14–29 (excluding Vouchers)
-- Run AFTER 002_rbac_dashboard_tables.sql (or standalone if fresh DB)
-- Safe to re-run: uses IF NOT EXISTS / ADD COLUMN IF NOT EXISTS
-- ═══════════════════════════════════════════════════════════════════

-- ── Helper functions (create first) ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE((SELECT role FROM public.profiles WHERE id = auth.uid()), 'tourist');
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 14 — Users (profiles)
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'tourist';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferences TEXT[] DEFAULT '{}';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS budget NUMERIC(10,2);
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_role_check') THEN
    ALTER TABLE profiles ADD CONSTRAINT profiles_role_check
      CHECK (role IN ('tourist','establishment','administrator','super_admin'));
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 15 — Tourist Profiles
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS tourist_profiles (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  budget_min              NUMERIC(10,2) NOT NULL DEFAULT 0,
  budget_max              NUMERIC(10,2) NOT NULL DEFAULT 5000,
  available_hours_per_day INT NOT NULL DEFAULT 9 CHECK (available_hours_per_day > 0),
  trip_duration_days      INT NOT NULL DEFAULT 1,
  preferred_categories    TEXT[] DEFAULT '{}',
  current_lat             DOUBLE PRECISION,
  current_lng             DOUBLE PRECISION,
  travel_mode             TEXT NOT NULL DEFAULT 'walking',
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 16 — Destinations (extend existing or create)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS destinations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,
  description           TEXT NOT NULL DEFAULT '',
  category              TEXT NOT NULL,
  lat                   DOUBLE PRECISION NOT NULL,
  lng                   DOUBLE PRECISION NOT NULL,
  location              TEXT NOT NULL DEFAULT '',
  geohash               TEXT,
  entrance_fee          NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (entrance_fee >= 0),
  average_stay_minutes  INT NOT NULL DEFAULT 60 CHECK (average_stay_minutes > 0),
  operating_hours       JSONB NOT NULL DEFAULT '{"open":"08:00","close":"17:00"}'::jsonb,
  status                TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active','inactive','maintenance')),
  rating_average        NUMERIC(3,2) NOT NULL DEFAULT 0,
  owner_id              UUID REFERENCES profiles(id) ON DELETE SET NULL,
  establishment_id      UUID REFERENCES establishments(id) ON DELETE SET NULL,
  image_urls            TEXT[] DEFAULT '{}',
  image_url             TEXT,
  is_active             BOOLEAN NOT NULL DEFAULT true,
  is_verified           BOOLEAN NOT NULL DEFAULT false,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE destinations ADD COLUMN IF NOT EXISTS description TEXT NOT NULL DEFAULT '';
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS geohash TEXT;
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS entrance_fee NUMERIC(10,2) NOT NULL DEFAULT 0;
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS average_stay_minutes INT NOT NULL DEFAULT 60;
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS operating_hours JSONB NOT NULL DEFAULT '{"open":"08:00","close":"17:00"}'::jsonb;
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS rating_average NUMERIC(3,2) NOT NULL DEFAULT 0;
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE destinations ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';

-- Sync legacy is_active ↔ status
UPDATE destinations SET status = CASE WHEN is_active THEN 'active' ELSE 'inactive' END
WHERE status IS NULL OR status = 'active' AND is_active = false;

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 17 — Destination Availability
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS destination_availability (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  destination_id  UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  date            DATE NOT NULL,
  open_time       TIME NOT NULL DEFAULT '08:00',
  close_time      TIME NOT NULL DEFAULT '17:00',
  is_available    BOOLEAN NOT NULL DEFAULT true,
  UNIQUE (destination_id, date)
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 18 — Itineraries
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS itineraries (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tourist_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  itinerary_category  TEXT NOT NULL CHECK (itinerary_category IN ('single_destination','multi_destination')),
  type                TEXT NOT NULL CHECK (type IN ('single_day','multi_day')),
  current_stop_index  INT NOT NULL DEFAULT 0,
  total_cost          NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_distance      NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_travel_time   INT NOT NULL DEFAULT 0,
  fitness_score       NUMERIC(10,4) NOT NULL DEFAULT 0,
  generated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  status              TEXT NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active','completed','cancelled'))
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 19 — Itinerary Stops
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS itinerary_stops (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  itinerary_id              UUID NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
  destination_id            UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  day_number                INT NOT NULL DEFAULT 1 CHECK (day_number >= 1),
  sequence                  INT NOT NULL DEFAULT 1 CHECK (sequence >= 1),
  arrival_time              TIMESTAMPTZ NOT NULL,
  departure_time            TIMESTAMPTZ NOT NULL,
  estimated_travel_minutes  INT NOT NULL DEFAULT 0,
  contribution_score        NUMERIC(10,4) NOT NULL DEFAULT 0,
  is_completed              BOOLEAN NOT NULL DEFAULT false
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 20 — MO-GA Results
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS moga_results (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  itinerary_id      UUID NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
  fitness_score     NUMERIC(10,4) NOT NULL DEFAULT 0,
  preference_score  NUMERIC(10,4) NOT NULL DEFAULT 0,
  weather_score     NUMERIC(10,4) NOT NULL DEFAULT 0,
  budget_penalty    NUMERIC(10,4) NOT NULL DEFAULT 0,
  time_penalty      NUMERIC(10,4) NOT NULL DEFAULT 0,
  generation_count  INT NOT NULL DEFAULT 0,
  execution_time    NUMERIC(10,4) NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 21 — Self-Healing Logs
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS self_healing_logs (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  itinerary_id                UUID NOT NULL REFERENCES itineraries(id) ON DELETE CASCADE,
  trigger_type                TEXT NOT NULL CHECK (trigger_type IN ('delay','weather')),
  adjusted_minutes            INT NOT NULL,
  delay_severity_score        NUMERIC(10,4) NOT NULL DEFAULT 0,
  weather_risk_score          NUMERIC(10,4) NOT NULL DEFAULT 0,
  contribution_score          NUMERIC(10,4) NOT NULL DEFAULT 0,
  replacement_destination_id  UUID REFERENCES destinations(id) ON DELETE SET NULL,
  old_destination_id          UUID REFERENCES destinations(id) ON DELETE SET NULL,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 22 — Weather Cache
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS weather_cache (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  destination_id  UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  condition       TEXT NOT NULL,
  multiplier      NUMERIC(3,2) NOT NULL DEFAULT 1.00 CHECK (multiplier >= 0 AND multiplier <= 1),
  temperature     NUMERIC(5,2),
  humidity        NUMERIC(5,2),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 23 — Reservations
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS reservations (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  itinerary_id        UUID REFERENCES itineraries(id) ON DELETE SET NULL,
  tourist_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  establishment_id    UUID NOT NULL REFERENCES establishments(id) ON DELETE CASCADE,
  destination_id      UUID REFERENCES destinations(id) ON DELETE SET NULL,
  eta                 TIMESTAMPTZ NOT NULL,
  pax_count           INT NOT NULL DEFAULT 1 CHECK (pax_count > 0),
  reservation_status  TEXT NOT NULL DEFAULT 'pending'
                      CHECK (reservation_status IN ('pending','confirmed','cancelled','completed')),
  service_name        TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 24 — Payments
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS payments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id      UUID REFERENCES reservations(id) ON DELETE SET NULL,
  tourist_id          UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  establishment_id    UUID NOT NULL REFERENCES establishments(id) ON DELETE CASCADE,
  amount              NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  payment_method      TEXT NOT NULL DEFAULT 'gcash',
  paymongo_reference  TEXT UNIQUE,
  status              TEXT NOT NULL DEFAULT 'pending'
                      CHECK (status IN ('pending','paid','failed','refunded')),
  paid_at             TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 26 — Notifications
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS notifications (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  message       TEXT NOT NULL,
  type          TEXT NOT NULL,
  is_read       BOOLEAN NOT NULL DEFAULT false,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 27 — Events
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT NOT NULL,
  description   TEXT NOT NULL,
  event_date    TIMESTAMPTZ NOT NULL,
  category      TEXT NOT NULL CHECK (category IN ('festival','advisory','announcement')),
  posted_by     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 28 — Reviews (tourist destination reviews)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS reviews (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tourist_id      UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  destination_id  UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  establishment_id UUID REFERENCES establishments(id) ON DELETE SET NULL,
  stars           INT NOT NULL CHECK (stars >= 1 AND stars <= 5),
  review_text     TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ═══════════════════════════════════════════════════════════════════
-- TABLE 29 — Audit Logs (extend)
-- ═══════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  actor_id    UUID REFERENCES profiles(id) ON DELETE SET NULL,
  role        TEXT,
  action_type TEXT,
  action      TEXT,
  description TEXT,
  target_id   UUID,
  metadata    JSONB DEFAULT '{}'::jsonb,
  device_info TEXT,
  ip_address  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS role TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS action TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS target_id UUID;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS device_info TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS ip_address TEXT;

-- ═══════════════════════════════════════════════════════════════════
-- RLS — enable on all new tables
-- ═══════════════════════════════════════════════════════════════════
ALTER TABLE tourist_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE destination_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE itineraries ENABLE ROW LEVEL SECURITY;
ALTER TABLE itinerary_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE moga_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE self_healing_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- tourist_profiles
DROP POLICY IF EXISTS "tourist_profiles_own" ON tourist_profiles;
CREATE POLICY "tourist_profiles_own" ON tourist_profiles FOR ALL TO authenticated
  USING (user_id = auth.uid() OR public.current_user_role() IN ('administrator','super_admin'))
  WITH CHECK (user_id = auth.uid());

-- destinations (update admin policy to use status)
DROP POLICY IF EXISTS "destinations_select" ON destinations;
CREATE POLICY "destinations_select" ON destinations FOR SELECT TO authenticated
  USING (
    status = 'active' OR is_active = true
    OR public.current_user_role() IN ('administrator','super_admin')
    OR owner_id = auth.uid()
    OR establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
  );

-- destination_availability
DROP POLICY IF EXISTS "availability_select" ON destination_availability;
CREATE POLICY "availability_select" ON destination_availability FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "availability_admin" ON destination_availability;
CREATE POLICY "availability_admin" ON destination_availability FOR ALL TO authenticated
  USING (public.current_user_role() IN ('administrator','super_admin','establishment'));

-- itineraries
DROP POLICY IF EXISTS "itineraries_own" ON itineraries;
CREATE POLICY "itineraries_own" ON itineraries FOR ALL TO authenticated
  USING (tourist_id = auth.uid() OR public.current_user_role() IN ('administrator','super_admin'))
  WITH CHECK (tourist_id = auth.uid());

-- itinerary_stops
DROP POLICY IF EXISTS "stops_via_itinerary" ON itinerary_stops;
CREATE POLICY "stops_via_itinerary" ON itinerary_stops FOR ALL TO authenticated
  USING (itinerary_id IN (SELECT id FROM itineraries WHERE tourist_id = auth.uid())
         OR public.current_user_role() IN ('administrator','super_admin'));

-- moga_results
DROP POLICY IF EXISTS "moga_via_itinerary" ON moga_results;
CREATE POLICY "moga_via_itinerary" ON moga_results FOR SELECT TO authenticated
  USING (itinerary_id IN (SELECT id FROM itineraries WHERE tourist_id = auth.uid())
         OR public.current_user_role() IN ('administrator','super_admin'));

-- self_healing_logs
DROP POLICY IF EXISTS "healing_via_itinerary" ON self_healing_logs;
CREATE POLICY "healing_via_itinerary" ON self_healing_logs FOR SELECT TO authenticated
  USING (itinerary_id IN (SELECT id FROM itineraries WHERE tourist_id = auth.uid())
         OR public.current_user_role() IN ('administrator','super_admin'));

-- weather_cache
DROP POLICY IF EXISTS "weather_select" ON weather_cache;
CREATE POLICY "weather_select" ON weather_cache FOR SELECT TO authenticated USING (true);

-- reservations
DROP POLICY IF EXISTS "reservations_select" ON reservations;
CREATE POLICY "reservations_select" ON reservations FOR SELECT TO authenticated
  USING (
    tourist_id = auth.uid()
    OR establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator','super_admin')
  );
DROP POLICY IF EXISTS "reservations_insert" ON reservations;
CREATE POLICY "reservations_insert" ON reservations FOR INSERT TO authenticated
  WITH CHECK (tourist_id = auth.uid() OR public.current_user_role() IN ('establishment','administrator','super_admin'));
DROP POLICY IF EXISTS "reservations_update" ON reservations;
CREATE POLICY "reservations_update" ON reservations FOR UPDATE TO authenticated
  USING (
    establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator','super_admin')
  );

-- payments
DROP POLICY IF EXISTS "payments_select" ON payments;
CREATE POLICY "payments_select" ON payments FOR SELECT TO authenticated
  USING (
    tourist_id = auth.uid()
    OR establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator','super_admin')
  );
DROP POLICY IF EXISTS "payments_insert" ON payments;
CREATE POLICY "payments_insert" ON payments FOR INSERT TO authenticated
  WITH CHECK (
    establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator','super_admin')
  );
DROP POLICY IF EXISTS "payments_update" ON payments;
CREATE POLICY "payments_update" ON payments FOR UPDATE TO authenticated
  USING (
    establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() = 'super_admin'
  );

-- notifications
DROP POLICY IF EXISTS "notifications_own" ON notifications;
CREATE POLICY "notifications_own" ON notifications FOR ALL TO authenticated
  USING (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

-- events
DROP POLICY IF EXISTS "events_select" ON events;
CREATE POLICY "events_select" ON events FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "events_admin" ON events;
CREATE POLICY "events_admin" ON events FOR ALL TO authenticated
  USING (public.current_user_role() IN ('administrator','super_admin'))
  WITH CHECK (public.current_user_role() IN ('administrator','super_admin'));

-- reviews
DROP POLICY IF EXISTS "reviews_select" ON reviews;
CREATE POLICY "reviews_select" ON reviews FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "reviews_insert" ON reviews;
CREATE POLICY "reviews_insert" ON reviews FOR INSERT TO authenticated
  WITH CHECK (tourist_id = auth.uid());

-- audit_logs (extend policy)
DROP POLICY IF EXISTS "audit_insert" ON audit_logs;
CREATE POLICY "audit_insert" ON audit_logs FOR INSERT TO authenticated WITH CHECK (true);

-- ═══════════════════════════════════════════════════════════════════
-- SEED: Update destinations with spec fields
-- ═══════════════════════════════════════════════════════════════════
UPDATE destinations SET
  description = COALESCE(NULLIF(description,''), 'A beautiful destination in Samal Island.'),
  entrance_fee = CASE name
    WHEN 'Kaputian Beach' THEN 100 WHEN 'Pearl Farm Resort' THEN 250
    WHEN 'Hagimit Falls' THEN 50 WHEN 'Maxima Aquafun' THEN 350
    ELSE 100 END,
  average_stay_minutes = CASE category
    WHEN 'Resort' THEN 180 WHEN 'Beach' THEN 120 WHEN 'Falls' THEN 90
    WHEN 'Mountain' THEN 150 ELSE 60 END,
  rating_average = COALESCE(rating_average, 4.5),
  status = CASE WHEN is_active THEN 'active' ELSE 'inactive' END
WHERE description = '' OR description IS NULL;

-- Sample events (admin announcements)
INSERT INTO events (title, description, event_date, category, posted_by)
SELECT
  'Samal Island Tourism Week',
  'Join us for a week-long celebration of Samal Island culture, food, and adventure!',
  now() + interval '14 days',
  'festival',
  p.id
FROM profiles p
WHERE p.role IN ('administrator','super_admin')
  AND NOT EXISTS (SELECT 1 FROM events WHERE title = 'Samal Island Tourism Week')
LIMIT 1;
