--
-- PostgreSQL database dump
--

\restrict pAFKyEeexRHnM3Mi3uWBPr4bwcEUp3ewIOB5DeSSZEBhzOqSpHfmB9YZBgddLY6

-- Dumped from database version 17.11
-- Dumped by pg_dump version 18.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: admin_toggle_owner_verification(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_toggle_owner_verification(p_owner_id uuid, p_verified boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  caller_role TEXT;
  est_exists BOOLEAN;
  owner_name TEXT;
BEGIN
  SELECT role INTO caller_role FROM profiles WHERE id = auth.uid();
  IF caller_role NOT IN ('administrator', 'super_admin') THEN
    RAISE EXCEPTION 'Permission denied: only administrators can toggle verification';
  END IF;

  SELECT display_name INTO owner_name FROM profiles WHERE id = p_owner_id;
  IF owner_name IS NULL THEN
    RAISE EXCEPTION 'Owner not found';
  END IF;

  SELECT EXISTS(SELECT 1 FROM establishments WHERE owner_id = p_owner_id) INTO est_exists;

  IF est_exists THEN
    UPDATE establishments SET is_verified = p_verified WHERE owner_id = p_owner_id;
  ELSE
    INSERT INTO establishments (owner_id, name, category, is_verified)
    VALUES (p_owner_id, owner_name || '''s Establishment', 'Resort', p_verified);
  END IF;
END;
$$;


--
-- Name: current_user_role(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_user_role() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT COALESCE(
    (SELECT role FROM public.profiles WHERE id = auth.uid()),
    'tourist'
  );
$$;


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, role)
  VALUES (
    NEW.id, NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'tourist')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(profiles.display_name, EXCLUDED.display_name);
  RETURN NEW;
END;
$$;


--
-- Name: increment_review_helpful(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.increment_review_helpful(review_id uuid, is_yes boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF is_yes THEN
    UPDATE public.reviews SET helpful_yes = helpful_yes + 1 WHERE id = review_id;
  ELSE
    UPDATE public.reviews SET helpful_no = helpful_no + 1 WHERE id = review_id;
  END IF;
END;
$$;


--
-- Name: log_audit(text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_audit(p_action_type text, p_description text, p_metadata jsonb DEFAULT '{}'::jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  INSERT INTO public.audit_logs (user_id, action_type, description, metadata)
  VALUES (auth.uid(), p_action_type, p_description, p_metadata);
END;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activities (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    destination_id uuid NOT NULL,
    establishment_id uuid,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    category text DEFAULT 'general'::text NOT NULL,
    price numeric(10,2) DEFAULT 0 NOT NULL,
    duration_minutes integer DEFAULT 60 NOT NULL,
    difficulty_level text DEFAULT 'easy'::text NOT NULL,
    is_elder_friendly boolean DEFAULT true NOT NULL,
    is_child_friendly boolean DEFAULT true NOT NULL,
    min_age integer DEFAULT 0,
    max_pax integer DEFAULT 50,
    image_url text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT activities_category_check CHECK ((category = ANY (ARRAY['water_sport'::text, 'land_adventure'::text, 'relaxation'::text, 'cultural'::text, 'dining'::text, 'entertainment'::text, 'nature'::text, 'general'::text]))),
    CONSTRAINT activities_difficulty_level_check CHECK ((difficulty_level = ANY (ARRAY['easy'::text, 'moderate'::text, 'hard'::text, 'extreme'::text]))),
    CONSTRAINT activities_duration_minutes_check CHECK ((duration_minutes > 0)),
    CONSTRAINT activities_price_check CHECK ((price >= (0)::numeric))
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    action_type text NOT NULL,
    description text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    actor_id uuid,
    role text,
    action text,
    target_id uuid,
    device_info text,
    ip_address text
);


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    icon text DEFAULT 'default'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: destination_availability; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.destination_availability (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    destination_id uuid NOT NULL,
    date date NOT NULL,
    open_time time without time zone DEFAULT '08:00:00'::time without time zone NOT NULL,
    close_time time without time zone DEFAULT '17:00:00'::time without time zone NOT NULL,
    is_available boolean DEFAULT true NOT NULL
);


--
-- Name: destination_gallery; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.destination_gallery (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    destination_id uuid NOT NULL,
    image_url text NOT NULL,
    caption text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: destinations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.destinations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid,
    name text NOT NULL,
    location text NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    description text,
    image_url text,
    rating numeric(3,1) DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    geohash text,
    entrance_fee numeric(10,2) DEFAULT 0 NOT NULL,
    average_stay_minutes integer DEFAULT 60 NOT NULL,
    operating_hours jsonb DEFAULT '{"open": "08:00", "close": "17:00"}'::jsonb NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    rating_average numeric(3,2) DEFAULT 0 NOT NULL,
    owner_id uuid,
    image_urls text[] DEFAULT '{}'::text[],
    category_id uuid,
    gallery_urls text[] DEFAULT '{}'::text[],
    category text DEFAULT 'Other'::text NOT NULL
);


--
-- Name: establishments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.establishments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    owner_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    address text,
    lat double precision,
    lng double precision,
    contact_phone text,
    is_verified boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    category_id uuid,
    category text DEFAULT 'Resort'::text NOT NULL
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title text NOT NULL,
    description text NOT NULL,
    event_date timestamp with time zone NOT NULL,
    category text NOT NULL,
    posted_by uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT events_category_check CHECK ((category = ANY (ARRAY['festival'::text, 'advisory'::text, 'announcement'::text])))
);


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    place_name text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    destination_id uuid,
    location text,
    rating numeric(3,2) DEFAULT 0,
    category text
);


--
-- Name: itineraries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.itineraries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tourist_id uuid NOT NULL,
    itinerary_category text NOT NULL,
    type text NOT NULL,
    current_stop_index integer DEFAULT 0 NOT NULL,
    total_cost numeric(10,2) DEFAULT 0 NOT NULL,
    total_distance numeric(10,2) DEFAULT 0 NOT NULL,
    total_travel_time integer DEFAULT 0 NOT NULL,
    fitness_score numeric(10,4) DEFAULT 0 NOT NULL,
    generated_at timestamp with time zone DEFAULT now() NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    CONSTRAINT itineraries_itinerary_category_check CHECK ((itinerary_category = ANY (ARRAY['single_destination'::text, 'multi_destination'::text]))),
    CONSTRAINT itineraries_status_check CHECK ((status = ANY (ARRAY['active'::text, 'completed'::text, 'cancelled'::text]))),
    CONSTRAINT itineraries_type_check CHECK ((type = ANY (ARRAY['single_day'::text, 'multi_day'::text])))
);


--
-- Name: itinerary_stops; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.itinerary_stops (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    itinerary_id uuid NOT NULL,
    destination_id uuid NOT NULL,
    day_number integer DEFAULT 1 NOT NULL,
    sequence integer DEFAULT 1 NOT NULL,
    arrival_time timestamp with time zone NOT NULL,
    departure_time timestamp with time zone NOT NULL,
    estimated_travel_minutes integer DEFAULT 0 NOT NULL,
    contribution_score numeric(10,4) DEFAULT 0 NOT NULL,
    is_completed boolean DEFAULT false NOT NULL,
    CONSTRAINT itinerary_stops_day_number_check CHECK ((day_number >= 1)),
    CONSTRAINT itinerary_stops_sequence_check CHECK ((sequence >= 1))
);


--
-- Name: location_verifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location_verifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    establishment_id uuid,
    destination_id uuid,
    name text NOT NULL,
    address text NOT NULL,
    lat double precision NOT NULL,
    lng double precision NOT NULL,
    category text NOT NULL,
    submitted_by uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT location_verifications_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text])))
);


--
-- Name: moga_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moga_results (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    itinerary_id uuid NOT NULL,
    fitness_score numeric(10,4) DEFAULT 0 NOT NULL,
    preference_score numeric(10,4) DEFAULT 0 NOT NULL,
    weather_score numeric(10,4) DEFAULT 0 NOT NULL,
    budget_penalty numeric(10,4) DEFAULT 0 NOT NULL,
    time_penalty numeric(10,4) DEFAULT 0 NOT NULL,
    generation_count integer DEFAULT 0 NOT NULL,
    execution_time numeric(10,4) DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recipient_id uuid NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    type text NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    reservation_id uuid,
    tourist_id uuid NOT NULL,
    establishment_id uuid NOT NULL,
    amount numeric(10,2) NOT NULL,
    payment_method text DEFAULT 'gcash'::text NOT NULL,
    paymongo_reference text,
    status text DEFAULT 'pending'::text NOT NULL,
    paid_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT payments_amount_check CHECK ((amount > (0)::numeric)),
    CONSTRAINT payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'paid'::text, 'failed'::text, 'refunded'::text])))
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    display_name text,
    avatar_url text,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    email text,
    username text,
    phone text,
    role text DEFAULT 'tourist'::text NOT NULL,
    profile_image_url text,
    preferences text[] DEFAULT '{}'::text[],
    budget numeric(10,2),
    fcm_token text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['tourist'::text, 'owner'::text, 'administrator'::text, 'super_admin'::text])))
);


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    itinerary_id uuid,
    tourist_id uuid NOT NULL,
    establishment_id uuid NOT NULL,
    destination_id uuid,
    eta timestamp with time zone NOT NULL,
    pax_count integer DEFAULT 1 NOT NULL,
    reservation_status text DEFAULT 'pending'::text NOT NULL,
    service_name text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reservations_pax_count_check CHECK ((pax_count > 0)),
    CONSTRAINT reservations_reservation_status_check CHECK ((reservation_status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'cancelled'::text, 'completed'::text])))
);


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tourist_id uuid NOT NULL,
    destination_id uuid NOT NULL,
    establishment_id uuid,
    stars integer NOT NULL,
    review_text text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    helpful_yes integer DEFAULT 0 NOT NULL,
    helpful_no integer DEFAULT 0 NOT NULL,
    CONSTRAINT reviews_stars_check CHECK (((stars >= 1) AND (stars <= 5)))
);


--
-- Name: reviews_legacy; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reviews_legacy (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    place_name text NOT NULL,
    author_name text NOT NULL,
    rating double precision NOT NULL,
    comment text NOT NULL,
    helpful_yes integer DEFAULT 0 NOT NULL,
    helpful_no integer DEFAULT 0 NOT NULL,
    date_string text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: role_descriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_descriptions (
    role_key text NOT NULL,
    display_name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: self_healing_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.self_healing_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    itinerary_id uuid NOT NULL,
    trigger_type text NOT NULL,
    adjusted_minutes integer NOT NULL,
    delay_severity_score numeric(10,4) DEFAULT 0 NOT NULL,
    weather_risk_score numeric(10,4) DEFAULT 0 NOT NULL,
    contribution_score numeric(10,4) DEFAULT 0 NOT NULL,
    replacement_destination_id uuid,
    old_destination_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT self_healing_logs_trigger_type_check CHECK ((trigger_type = ANY (ARRAY['delay'::text, 'weather'::text])))
);


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_settings (
    key text NOT NULL,
    value jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_by uuid,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: tourist_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tourist_details (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    budget_min numeric(10,2) DEFAULT 0 NOT NULL,
    budget_max numeric(10,2) DEFAULT 5000 NOT NULL,
    available_hours_per_day integer DEFAULT 9 NOT NULL,
    trip_duration_days integer DEFAULT 1 NOT NULL,
    preferred_categories text[] DEFAULT '{}'::text[],
    current_lat double precision,
    current_lng double precision,
    travel_mode text DEFAULT 'walking'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    number_of_tourists integer DEFAULT 1,
    children_count integer DEFAULT 0,
    elders_count integer DEFAULT 0,
    CONSTRAINT tourist_profiles_available_hours_per_day_check CHECK ((available_hours_per_day > 0))
);


--
-- Name: tourist_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tourist_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    budget_min numeric(10,2) DEFAULT 0 NOT NULL,
    budget_max numeric(10,2) DEFAULT 5000 NOT NULL,
    available_hours_per_day integer DEFAULT 9 NOT NULL,
    trip_duration_days integer DEFAULT 1 NOT NULL,
    preferred_categories text[] DEFAULT '{}'::text[],
    current_lat double precision,
    current_lng double precision,
    travel_mode text DEFAULT 'walking'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT tourist_profiles_available_hours_per_day_check1 CHECK ((available_hours_per_day > 0))
);


--
-- Name: weather_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weather_cache (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    destination_id uuid NOT NULL,
    condition text NOT NULL,
    multiplier numeric(3,2) DEFAULT 1.00 NOT NULL,
    temperature numeric(5,2),
    humidity numeric(5,2),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT weather_cache_multiplier_check CHECK (((multiplier >= (0)::numeric) AND (multiplier <= (1)::numeric)))
);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: destination_availability destination_availability_destination_id_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destination_availability
    ADD CONSTRAINT destination_availability_destination_id_date_key UNIQUE (destination_id, date);


--
-- Name: destination_availability destination_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destination_availability
    ADD CONSTRAINT destination_availability_pkey PRIMARY KEY (id);


--
-- Name: destination_gallery destination_gallery_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destination_gallery
    ADD CONSTRAINT destination_gallery_pkey PRIMARY KEY (id);


--
-- Name: destinations destinations_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destinations
    ADD CONSTRAINT destinations_name_key UNIQUE (name);


--
-- Name: destinations destinations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destinations
    ADD CONSTRAINT destinations_pkey PRIMARY KEY (id);


--
-- Name: establishments establishments_owner_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establishments
    ADD CONSTRAINT establishments_owner_id_key UNIQUE (owner_id);


--
-- Name: establishments establishments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establishments
    ADD CONSTRAINT establishments_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (id);


--
-- Name: favorites favorites_user_destination_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_destination_unique UNIQUE (user_id, destination_id);


--
-- Name: favorites favorites_user_id_place_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_place_name_key UNIQUE (user_id, place_name);


--
-- Name: itineraries itineraries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itineraries
    ADD CONSTRAINT itineraries_pkey PRIMARY KEY (id);


--
-- Name: itinerary_stops itinerary_stops_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itinerary_stops
    ADD CONSTRAINT itinerary_stops_pkey PRIMARY KEY (id);


--
-- Name: location_verifications location_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_verifications
    ADD CONSTRAINT location_verifications_pkey PRIMARY KEY (id);


--
-- Name: moga_results moga_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moga_results
    ADD CONSTRAINT moga_results_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: payments payments_paymongo_reference_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_paymongo_reference_key UNIQUE (paymongo_reference);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: reviews_legacy reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews_legacy
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey1 PRIMARY KEY (id);


--
-- Name: role_descriptions role_descriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_descriptions
    ADD CONSTRAINT role_descriptions_pkey PRIMARY KEY (role_key);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: self_healing_logs self_healing_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_healing_logs
    ADD CONSTRAINT self_healing_logs_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (key);


--
-- Name: tourist_details tourist_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tourist_details
    ADD CONSTRAINT tourist_profiles_pkey PRIMARY KEY (id);


--
-- Name: tourist_profiles tourist_profiles_pkey1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tourist_profiles
    ADD CONSTRAINT tourist_profiles_pkey1 PRIMARY KEY (id);


--
-- Name: tourist_details tourist_profiles_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tourist_details
    ADD CONSTRAINT tourist_profiles_user_id_key UNIQUE (user_id);


--
-- Name: tourist_profiles tourist_profiles_user_id_key1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tourist_profiles
    ADD CONSTRAINT tourist_profiles_user_id_key1 UNIQUE (user_id);


--
-- Name: weather_cache weather_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_cache
    ADD CONSTRAINT weather_cache_pkey PRIMARY KEY (id);


--
-- Name: idx_activities_destination; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activities_destination ON public.activities USING btree (destination_id);


--
-- Name: idx_activities_establishment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activities_establishment ON public.activities USING btree (establishment_id);


--
-- Name: idx_destination_gallery_destination_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_destination_gallery_destination_id ON public.destination_gallery USING btree (destination_id);


--
-- Name: destinations destinations_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER destinations_updated_at BEFORE UPDATE ON public.destinations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: activities set_activities_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_activities_updated_at BEFORE UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: activities activities_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE CASCADE;


--
-- Name: activities activities_establishment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES public.establishments(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: destination_availability destination_availability_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destination_availability
    ADD CONSTRAINT destination_availability_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE CASCADE;


--
-- Name: destination_gallery destination_gallery_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destination_gallery
    ADD CONSTRAINT destination_gallery_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE CASCADE;


--
-- Name: destinations destinations_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destinations
    ADD CONSTRAINT destinations_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: destinations destinations_establishment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destinations
    ADD CONSTRAINT destinations_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES public.establishments(id) ON DELETE SET NULL;


--
-- Name: destinations destinations_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.destinations
    ADD CONSTRAINT destinations_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: establishments establishments_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establishments
    ADD CONSTRAINT establishments_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: establishments establishments_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establishments
    ADD CONSTRAINT establishments_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: events events_posted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_posted_by_fkey FOREIGN KEY (posted_by) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: itineraries itineraries_tourist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itineraries
    ADD CONSTRAINT itineraries_tourist_id_fkey FOREIGN KEY (tourist_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: itinerary_stops itinerary_stops_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itinerary_stops
    ADD CONSTRAINT itinerary_stops_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE CASCADE;


--
-- Name: itinerary_stops itinerary_stops_itinerary_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itinerary_stops
    ADD CONSTRAINT itinerary_stops_itinerary_id_fkey FOREIGN KEY (itinerary_id) REFERENCES public.itineraries(id) ON DELETE CASCADE;


--
-- Name: location_verifications location_verifications_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_verifications
    ADD CONSTRAINT location_verifications_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE SET NULL;


--
-- Name: location_verifications location_verifications_establishment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_verifications
    ADD CONSTRAINT location_verifications_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES public.establishments(id) ON DELETE SET NULL;


--
-- Name: location_verifications location_verifications_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_verifications
    ADD CONSTRAINT location_verifications_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: location_verifications location_verifications_submitted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location_verifications
    ADD CONSTRAINT location_verifications_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: moga_results moga_results_itinerary_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moga_results
    ADD CONSTRAINT moga_results_itinerary_id_fkey FOREIGN KEY (itinerary_id) REFERENCES public.itineraries(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_recipient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: payments payments_establishment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES public.establishments(id) ON DELETE CASCADE;


--
-- Name: payments payments_reservation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_reservation_id_fkey FOREIGN KEY (reservation_id) REFERENCES public.reservations(id) ON DELETE SET NULL;


--
-- Name: payments payments_tourist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_tourist_id_fkey FOREIGN KEY (tourist_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_role_fkey FOREIGN KEY (role) REFERENCES public.roles(name);


--
-- Name: reservations reservations_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_establishment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES public.establishments(id) ON DELETE CASCADE;


--
-- Name: reservations reservations_itinerary_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_itinerary_fk FOREIGN KEY (itinerary_id) REFERENCES public.itineraries(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_itinerary_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_itinerary_id_fkey FOREIGN KEY (itinerary_id) REFERENCES public.itineraries(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_tourist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_tourist_id_fkey FOREIGN KEY (tourist_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_establishment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_establishment_id_fkey FOREIGN KEY (establishment_id) REFERENCES public.establishments(id) ON DELETE SET NULL;


--
-- Name: reviews reviews_tourist_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_tourist_id_fkey FOREIGN KEY (tourist_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: self_healing_logs self_healing_logs_itinerary_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_healing_logs
    ADD CONSTRAINT self_healing_logs_itinerary_id_fkey FOREIGN KEY (itinerary_id) REFERENCES public.itineraries(id) ON DELETE CASCADE;


--
-- Name: self_healing_logs self_healing_logs_old_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_healing_logs
    ADD CONSTRAINT self_healing_logs_old_destination_id_fkey FOREIGN KEY (old_destination_id) REFERENCES public.destinations(id) ON DELETE SET NULL;


--
-- Name: self_healing_logs self_healing_logs_replacement_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_healing_logs
    ADD CONSTRAINT self_healing_logs_replacement_destination_id_fkey FOREIGN KEY (replacement_destination_id) REFERENCES public.destinations(id) ON DELETE SET NULL;


--
-- Name: system_settings system_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: tourist_details tourist_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tourist_details
    ADD CONSTRAINT tourist_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: tourist_profiles tourist_profiles_user_id_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tourist_profiles
    ADD CONSTRAINT tourist_profiles_user_id_fkey1 FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: weather_cache weather_cache_destination_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather_cache
    ADD CONSTRAINT weather_cache_destination_id_fkey FOREIGN KEY (destination_id) REFERENCES public.destinations(id) ON DELETE CASCADE;


--
-- Name: reviews_legacy Allow authenticated insert to reviews; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow authenticated insert to reviews" ON public.reviews_legacy FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: profiles Allow public read access to profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public read access to profiles" ON public.profiles FOR SELECT USING (true);


--
-- Name: reviews_legacy Allow public read access to reviews; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public read access to reviews" ON public.reviews_legacy FOR SELECT USING (true);


--
-- Name: reviews_legacy Allow public update to helpful count; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow public update to helpful count" ON public.reviews_legacy FOR UPDATE USING (true);


--
-- Name: favorites Allow users to delete their own favorites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow users to delete their own favorites" ON public.favorites FOR DELETE TO authenticated USING ((auth.uid() = user_id));


--
-- Name: favorites Allow users to insert their own favorites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow users to insert their own favorites" ON public.favorites FOR INSERT TO authenticated WITH CHECK ((auth.uid() = user_id));


--
-- Name: favorites Allow users to read their own favorites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow users to read their own favorites" ON public.favorites FOR SELECT USING ((auth.uid() = user_id));


--
-- Name: profiles Allow users to update their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Allow users to update their own profile" ON public.profiles FOR UPDATE USING ((auth.uid() = id));


--
-- Name: destinations Anyone can view destinations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Anyone can view destinations" ON public.destinations FOR SELECT USING (true);


--
-- Name: destination_gallery Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.destination_gallery FOR SELECT USING (true);


--
-- Name: moga_results Users can manage moga results of their own itineraries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage moga results of their own itineraries" ON public.moga_results TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.itineraries i
  WHERE ((i.id = moga_results.itinerary_id) AND (i.tourist_id = auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.itineraries i
  WHERE ((i.id = moga_results.itinerary_id) AND (i.tourist_id = auth.uid())))));


--
-- Name: self_healing_logs Users can manage self healing logs of their own itineraries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage self healing logs of their own itineraries" ON public.self_healing_logs TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.itineraries i
  WHERE ((i.id = self_healing_logs.itinerary_id) AND (i.tourist_id = auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.itineraries i
  WHERE ((i.id = self_healing_logs.itinerary_id) AND (i.tourist_id = auth.uid())))));


--
-- Name: itinerary_stops Users can manage stops of their own itineraries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage stops of their own itineraries" ON public.itinerary_stops TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.itineraries i
  WHERE ((i.id = itinerary_stops.itinerary_id) AND (i.tourist_id = auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.itineraries i
  WHERE ((i.id = itinerary_stops.itinerary_id) AND (i.tourist_id = auth.uid())))));


--
-- Name: itineraries Users can manage their own itineraries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own itineraries" ON public.itineraries TO authenticated USING ((tourist_id = auth.uid())) WITH CHECK ((tourist_id = auth.uid()));


--
-- Name: tourist_details Users can manage their own tourist details; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can manage their own tourist details" ON public.tourist_details TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: profiles Users can upsert their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can upsert their own profile" ON public.profiles USING ((auth.uid() = id)) WITH CHECK ((auth.uid() = id));


--
-- Name: favorites Users manage own favorites; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users manage own favorites" ON public.favorites USING ((auth.uid() = user_id));


--
-- Name: profiles Users manage own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users manage own profile" ON public.profiles USING ((auth.uid() = id));


--
-- Name: activities; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

--
-- Name: activities activities_delete_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY activities_delete_policy ON public.activities FOR DELETE USING ((establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid()))));


--
-- Name: activities activities_insert_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY activities_insert_policy ON public.activities FOR INSERT WITH CHECK ((establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid()))));


--
-- Name: activities activities_select_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY activities_select_policy ON public.activities FOR SELECT USING (true);


--
-- Name: activities activities_update_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY activities_update_policy ON public.activities FOR UPDATE USING ((establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid()))));


--
-- Name: audit_logs audit_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audit_insert ON public.audit_logs FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: audit_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs audit_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY audit_select ON public.audit_logs FOR SELECT TO authenticated USING ((public.current_user_role() = 'super_admin'::text));


--
-- Name: destination_availability availability_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY availability_admin ON public.destination_availability TO authenticated USING ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text, 'establishment'::text])));


--
-- Name: destination_availability availability_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY availability_select ON public.destination_availability FOR SELECT TO authenticated USING (true);


--
-- Name: categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

--
-- Name: categories categories_admin_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categories_admin_delete ON public.categories FOR DELETE TO authenticated USING ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])));


--
-- Name: categories categories_admin_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categories_admin_insert ON public.categories FOR INSERT TO authenticated WITH CHECK ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])));


--
-- Name: categories categories_admin_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categories_admin_update ON public.categories FOR UPDATE TO authenticated USING ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])));


--
-- Name: categories categories_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categories_public_read ON public.categories FOR SELECT TO authenticated, anon USING (true);


--
-- Name: categories categories_select_policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY categories_select_policy ON public.categories FOR SELECT TO authenticated USING (true);


--
-- Name: destination_availability; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.destination_availability ENABLE ROW LEVEL SECURITY;

--
-- Name: destination_gallery; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.destination_gallery ENABLE ROW LEVEL SECURITY;

--
-- Name: destinations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.destinations ENABLE ROW LEVEL SECURITY;

--
-- Name: destinations destinations_admin_all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY destinations_admin_all ON public.destinations TO authenticated USING ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))) WITH CHECK ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])));


--
-- Name: destinations destinations_owner_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY destinations_owner_write ON public.destinations TO authenticated USING ((owner_id = auth.uid())) WITH CHECK ((owner_id = auth.uid()));


--
-- Name: destinations destinations_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY destinations_public_read ON public.destinations FOR SELECT TO authenticated, anon USING (((is_active = true) AND (is_verified = true)));


--
-- Name: destinations destinations_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY destinations_select ON public.destinations FOR SELECT TO authenticated USING (((status = 'active'::text) OR (is_active = true) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])) OR (owner_id = auth.uid()) OR (establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid())))));


--
-- Name: establishments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.establishments ENABLE ROW LEVEL SECURITY;

--
-- Name: establishments establishments_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY establishments_insert ON public.establishments FOR INSERT TO authenticated WITH CHECK (((owner_id = auth.uid()) OR (public.current_user_role() = 'super_admin'::text)));


--
-- Name: establishments establishments_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY establishments_public_read ON public.establishments FOR SELECT TO authenticated, anon USING ((is_verified = true));


--
-- Name: establishments establishments_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY establishments_select ON public.establishments FOR SELECT TO authenticated USING (((owner_id = auth.uid()) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: establishments establishments_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY establishments_update ON public.establishments FOR UPDATE TO authenticated USING (((owner_id = auth.uid()) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

--
-- Name: events events_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY events_admin ON public.events TO authenticated USING ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))) WITH CHECK ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])));


--
-- Name: events events_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY events_select ON public.events FOR SELECT TO authenticated USING (true);


--
-- Name: favorites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

--
-- Name: favorites favorites_delete_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY favorites_delete_own ON public.favorites FOR DELETE TO authenticated USING ((user_id = auth.uid()));


--
-- Name: favorites favorites_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY favorites_insert_own ON public.favorites FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: favorites favorites_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY favorites_own ON public.favorites TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: favorites favorites_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY favorites_select_own ON public.favorites FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: self_healing_logs healing_via_itinerary; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY healing_via_itinerary ON public.self_healing_logs FOR SELECT TO authenticated USING (((itinerary_id IN ( SELECT itineraries.id
   FROM public.itineraries
  WHERE (itineraries.tourist_id = auth.uid()))) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: itineraries; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.itineraries ENABLE ROW LEVEL SECURITY;

--
-- Name: itineraries itineraries_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY itineraries_own ON public.itineraries TO authenticated USING (((tourist_id = auth.uid()) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])))) WITH CHECK ((tourist_id = auth.uid()));


--
-- Name: itinerary_stops; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.itinerary_stops ENABLE ROW LEVEL SECURITY;

--
-- Name: location_verifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.location_verifications ENABLE ROW LEVEL SECURITY;

--
-- Name: moga_results; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.moga_results ENABLE ROW LEVEL SECURITY;

--
-- Name: moga_results moga_via_itinerary; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY moga_via_itinerary ON public.moga_results FOR SELECT TO authenticated USING (((itinerary_id IN ( SELECT itineraries.id
   FROM public.itineraries
  WHERE (itineraries.tourist_id = auth.uid()))) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications notifications_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notifications_own ON public.notifications TO authenticated USING ((recipient_id = auth.uid())) WITH CHECK ((recipient_id = auth.uid()));


--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: payments payments_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY payments_insert ON public.payments FOR INSERT TO authenticated WITH CHECK (((establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid()))) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: payments payments_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY payments_select ON public.payments FOR SELECT TO authenticated USING (((tourist_id = auth.uid()) OR (establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid()))) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: payments payments_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY payments_update ON public.payments FOR UPDATE TO authenticated USING (((establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid()))) OR (public.current_user_role() = 'super_admin'::text)));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_insert ON public.profiles FOR INSERT TO authenticated WITH CHECK (((id = auth.uid()) OR (public.current_user_role() = 'super_admin'::text)));


--
-- Name: profiles profiles_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_select ON public.profiles FOR SELECT TO authenticated USING (true);


--
-- Name: profiles profiles_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_update ON public.profiles FOR UPDATE TO authenticated USING (((id = auth.uid()) OR (public.current_user_role() = 'super_admin'::text)));


--
-- Name: reservations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: reservations reservations_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_insert ON public.reservations FOR INSERT TO authenticated WITH CHECK (((tourist_id = auth.uid()) OR (public.current_user_role() = ANY (ARRAY['establishment'::text, 'administrator'::text, 'super_admin'::text]))));


--
-- Name: reservations reservations_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_select ON public.reservations FOR SELECT TO authenticated USING (((tourist_id = auth.uid()) OR (establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid()))) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: reservations reservations_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_update ON public.reservations FOR UPDATE TO authenticated USING (((establishment_id IN ( SELECT establishments.id
   FROM public.establishments
  WHERE (establishments.owner_id = auth.uid()))) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: reviews; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

--
-- Name: reviews reviews_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reviews_insert ON public.reviews FOR INSERT TO authenticated WITH CHECK ((tourist_id = auth.uid()));


--
-- Name: reviews reviews_insert_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reviews_insert_own ON public.reviews FOR INSERT TO authenticated WITH CHECK ((tourist_id = auth.uid()));


--
-- Name: reviews_legacy; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reviews_legacy ENABLE ROW LEVEL SECURITY;

--
-- Name: reviews reviews_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reviews_public_read ON public.reviews FOR SELECT TO authenticated, anon USING (true);


--
-- Name: reviews reviews_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reviews_select ON public.reviews FOR SELECT TO authenticated USING (true);


--
-- Name: role_descriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.role_descriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: role_descriptions role_descriptions_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY role_descriptions_select ON public.role_descriptions FOR SELECT TO authenticated USING (true);


--
-- Name: role_descriptions role_descriptions_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY role_descriptions_update ON public.role_descriptions FOR UPDATE TO authenticated USING ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'super_admin'::text));


--
-- Name: roles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

--
-- Name: roles roles_manage; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY roles_manage ON public.roles TO authenticated USING ((public.current_user_role() = 'super_admin'::text)) WITH CHECK ((public.current_user_role() = 'super_admin'::text));


--
-- Name: roles roles_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY roles_select ON public.roles FOR SELECT TO authenticated USING (true);


--
-- Name: self_healing_logs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.self_healing_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: system_settings settings_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY settings_select ON public.system_settings FOR SELECT TO authenticated USING ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])));


--
-- Name: system_settings settings_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY settings_update ON public.system_settings FOR UPDATE TO authenticated USING ((public.current_user_role() = 'super_admin'::text));


--
-- Name: itinerary_stops stops_via_itinerary; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY stops_via_itinerary ON public.itinerary_stops TO authenticated USING (((itinerary_id IN ( SELECT itineraries.id
   FROM public.itineraries
  WHERE (itineraries.tourist_id = auth.uid()))) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: system_settings; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: tourist_details; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tourist_details ENABLE ROW LEVEL SECURITY;

--
-- Name: tourist_details tourist_details_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tourist_details_own ON public.tourist_details TO authenticated USING (((user_id = auth.uid()) OR (( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = ANY (ARRAY['administrator'::text, 'super_admin'::text])))) WITH CHECK ((user_id = auth.uid()));


--
-- Name: tourist_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tourist_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: tourist_profiles tourist_profiles_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tourist_profiles_own ON public.tourist_profiles TO authenticated USING (((user_id = auth.uid()) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])))) WITH CHECK ((user_id = auth.uid()));


--
-- Name: location_verifications verifications_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY verifications_insert ON public.location_verifications FOR INSERT TO authenticated WITH CHECK ((submitted_by = auth.uid()));


--
-- Name: location_verifications verifications_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY verifications_select ON public.location_verifications FOR SELECT TO authenticated USING (((submitted_by = auth.uid()) OR (public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text]))));


--
-- Name: location_verifications verifications_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY verifications_update ON public.location_verifications FOR UPDATE TO authenticated USING ((public.current_user_role() = ANY (ARRAY['administrator'::text, 'super_admin'::text])));


--
-- Name: weather_cache; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.weather_cache ENABLE ROW LEVEL SECURITY;

--
-- Name: weather_cache weather_select; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY weather_select ON public.weather_cache FOR SELECT TO authenticated USING (true);


--
-- PostgreSQL database dump complete
--

\unrestrict pAFKyEeexRHnM3Mi3uWBPr4bwcEUp3ewIOB5DeSSZEBhzOqSpHfmB9YZBgddLY6

