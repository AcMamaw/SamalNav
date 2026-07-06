-- Sample reservations + payments for establishment dashboard
-- Replace emails with your real Supabase Auth emails before running

DO $$
DECLARE
  v_establishment_id UUID;
  v_establishment_owner UUID;
  v_tourist1 UUID;
  v_tourist2 UUID;
  v_dest_id UUID;
  v_res1 UUID;
  v_res2 UUID;
BEGIN
  SELECT id INTO v_establishment_owner FROM profiles WHERE email = 'owner@resort.com' LIMIT 1;
  SELECT id INTO v_tourist1 FROM profiles WHERE email = 'maria@email.com' LIMIT 1;
  SELECT id INTO v_tourist2 FROM profiles WHERE email = 'james@email.com' LIMIT 1;

  IF v_establishment_owner IS NULL THEN
    RAISE NOTICE 'Skip: create owner@resort.com user first';
    RETURN;
  END IF;

  INSERT INTO establishments (owner_id, name, address, lat, lng, category, is_verified)
  VALUES (v_establishment_owner, 'Pearl Farm Resort', 'Kaputian, Samal', 7.0050, 125.7271, 'Resort', true)
  ON CONFLICT (owner_id) DO UPDATE SET name = EXCLUDED.name
  RETURNING id INTO v_establishment_id;

  SELECT id INTO v_dest_id FROM destinations WHERE name = 'Pearl Farm Resort' LIMIT 1;

  IF v_tourist1 IS NOT NULL THEN
    INSERT INTO reservations (tourist_id, establishment_id, destination_id, eta, pax_count, reservation_status, service_name)
    VALUES (v_tourist1, v_establishment_id, v_dest_id, now() + interval '12 minutes', 3, 'confirmed', 'Day Tour — 3 guests')
    RETURNING id INTO v_res1;

    INSERT INTO payments (reservation_id, tourist_id, establishment_id, amount, payment_method, status, paid_at)
    VALUES (v_res1, v_tourist1, v_establishment_id, 4500.00, 'gcash', 'paid', now());

    INSERT INTO reviews (tourist_id, destination_id, establishment_id, stars, review_text)
    VALUES (v_tourist1, v_dest_id, v_establishment_id, 5, 'Ang ganda ng lugar! Sobrang linis at friendly ang staff.');
  END IF;

  IF v_tourist2 IS NOT NULL THEN
    INSERT INTO reservations (tourist_id, establishment_id, destination_id, eta, pax_count, reservation_status, service_name)
    VALUES (v_tourist2, v_establishment_id, v_dest_id, now() + interval '28 minutes', 2, 'pending', 'Resort Cottage — 2 nights')
    RETURNING id INTO v_res2;

    INSERT INTO payments (reservation_id, tourist_id, establishment_id, amount, payment_method, status)
    VALUES (v_res2, v_tourist2, v_establishment_id, 2800.00, 'gcash', 'pending');

    INSERT INTO reviews (tourist_id, destination_id, establishment_id, stars, review_text)
    VALUES (v_tourist2, v_dest_id, v_establishment_id, 4, 'Great experience overall. Food could be better.');
  END IF;

  INSERT INTO audit_logs (actor_id, role, action, description)
  SELECT id, role, 'LOGIN', role || ' signed in to SamalNav'
  FROM profiles WHERE role IN ('establishment','administrator','super_admin') LIMIT 5;

END $$;
