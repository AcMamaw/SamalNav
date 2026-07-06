-- ═══════════════════════════════════════════════════════════════════
-- QUICK FIX: run this if you already got the current_user_role() error
-- Safe to run even if the full migration partially succeeded
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

-- Recreate policies that depend on current_user_role()
DROP POLICY IF EXISTS "profiles_update" ON profiles;
CREATE POLICY "profiles_update" ON profiles FOR UPDATE TO authenticated
  USING (id = auth.uid() OR public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "profiles_insert" ON profiles;
CREATE POLICY "profiles_insert" ON profiles FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() OR public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "establishments_select" ON establishments;
CREATE POLICY "establishments_select" ON establishments FOR SELECT TO authenticated
  USING (owner_id = auth.uid() OR public.current_user_role() IN ('administrator', 'super_admin'));

DROP POLICY IF EXISTS "establishments_insert" ON establishments;
CREATE POLICY "establishments_insert" ON establishments FOR INSERT TO authenticated
  WITH CHECK (owner_id = auth.uid() OR public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "establishments_update" ON establishments;
CREATE POLICY "establishments_update" ON establishments FOR UPDATE TO authenticated
  USING (owner_id = auth.uid() OR public.current_user_role() IN ('administrator', 'super_admin'));

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

DROP POLICY IF EXISTS "bookings_select" ON bookings;
CREATE POLICY "bookings_select" ON bookings FOR SELECT TO authenticated
  USING (
    tourist_id = auth.uid()
    OR establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator', 'super_admin')
  );

DROP POLICY IF EXISTS "bookings_insert" ON bookings;
CREATE POLICY "bookings_insert" ON bookings FOR INSERT TO authenticated
  WITH CHECK (tourist_id = auth.uid() OR public.current_user_role() IN ('establishment', 'administrator', 'super_admin'));

DROP POLICY IF EXISTS "bookings_update" ON bookings;
CREATE POLICY "bookings_update" ON bookings FOR UPDATE TO authenticated
  USING (
    establishment_id IN (SELECT id FROM establishments WHERE owner_id = auth.uid())
    OR public.current_user_role() IN ('administrator', 'super_admin')
  );

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

DROP POLICY IF EXISTS "verifications_select" ON location_verifications;
CREATE POLICY "verifications_select" ON location_verifications FOR SELECT TO authenticated
  USING (submitted_by = auth.uid() OR public.current_user_role() IN ('administrator', 'super_admin'));

DROP POLICY IF EXISTS "verifications_update" ON location_verifications;
CREATE POLICY "verifications_update" ON location_verifications FOR UPDATE TO authenticated
  USING (public.current_user_role() IN ('administrator', 'super_admin'));

DROP POLICY IF EXISTS "audit_select" ON audit_logs;
CREATE POLICY "audit_select" ON audit_logs FOR SELECT TO authenticated
  USING (public.current_user_role() = 'super_admin');

DROP POLICY IF EXISTS "settings_select" ON system_settings;
CREATE POLICY "settings_select" ON system_settings FOR SELECT TO authenticated
  USING (public.current_user_role() IN ('administrator', 'super_admin'));

DROP POLICY IF EXISTS "settings_update" ON system_settings;
CREATE POLICY "settings_update" ON system_settings FOR UPDATE TO authenticated
  USING (public.current_user_role() = 'super_admin');
