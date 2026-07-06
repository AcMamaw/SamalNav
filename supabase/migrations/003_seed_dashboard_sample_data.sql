-- Sample data for dashboards (run AFTER you created users + assigned roles)
-- Replace the emails below with your actual Supabase Auth emails.

DO $$
DECLARE
  v_establishment_owner UUID;
  v_tourist1 UUID;
  v_tourist2 UUID;
  v_establishment_id UUID;
  v_booking1 UUID;
  v_booking2 UUID;
BEGIN
  SELECT id INTO v_establishment_owner FROM profiles WHERE email = 'owner@resort.com' LIMIT 1;
  SELECT id INTO v_tourist1 FROM profiles WHERE email = 'maria@email.com' LIMIT 1;
  SELECT id INTO v_tourist2 FROM profiles WHERE email = 'james@email.com' LIMIT 1;

  IF v_establishment_owner IS NULL THEN
    RAISE NOTICE 'Skip seed: create owner@resort.com user first';
    RETURN;
  END IF;

  INSERT INTO establishments (owner_id, name, address, lat, lng, category, contact_phone, is_verified)
  VALUES (v_establishment_owner, 'Pearl Farm Resort', 'Kaputian, Samal', 7.0050, 125.7271, 'Resort', '+639171234567', true)
  ON CONFLICT (owner_id) DO UPDATE SET name = EXCLUDED.name
  RETURNING id INTO v_establishment_id;

  IF v_tourist1 IS NOT NULL THEN
    INSERT INTO bookings (establishment_id, tourist_id, service_name, guest_count, status, scheduled_date, eta_minutes)
    VALUES (v_establishment_id, v_tourist1, 'Day Tour — 3 guests', 3, 'confirmed', CURRENT_DATE, 12)
    RETURNING id INTO v_booking1;

    INSERT INTO transactions (establishment_id, booking_id, tourist_id, amount, status, payment_method)
    VALUES (v_establishment_id, v_booking1, v_tourist1, 4500.00, 'paid', 'gcash');

    INSERT INTO establishment_reviews (establishment_id, tourist_id, rating, comment)
    VALUES (v_establishment_id, v_tourist1, 5.0, 'Ang ganda ng lugar! Sobrang linis at friendly ang staff.');
  END IF;

  IF v_tourist2 IS NOT NULL THEN
    INSERT INTO bookings (establishment_id, tourist_id, service_name, guest_count, status, scheduled_date, eta_minutes)
    VALUES (v_establishment_id, v_tourist2, 'Resort Cottage — 2 nights', 2, 'pending', CURRENT_DATE + 1, 28)
    RETURNING id INTO v_booking2;

    INSERT INTO transactions (establishment_id, booking_id, tourist_id, amount, status, payment_method)
    VALUES (v_establishment_id, v_booking2, v_tourist2, 2800.00, 'pending', 'cash');

    INSERT INTO establishment_reviews (establishment_id, tourist_id, rating, comment)
    VALUES (v_establishment_id, v_tourist2, 4.0, 'Great experience overall. Food could be better.');
  END IF;

  INSERT INTO audit_logs (user_id, action_type, description)
  SELECT id, 'LOGIN', 'User signed in to SamalNav'
  FROM profiles WHERE role IN ('administrator', 'super_admin', 'establishment')
  LIMIT 5;

END $$;
