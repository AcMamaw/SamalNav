--
-- PostgreSQL database dump
--

\restrict iXOJ5geySee9ySRbTJpfdW6g9okOyXu0R2SBMLEr8n8QTpC3g2mY7KwucEFhAFw

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
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categories (id, name, icon, created_at) FROM stdin;
0cc06ba0-46b3-459f-8959-7f813e00992a	Island	island	2026-07-07 01:58:55.008878+00
20452116-6f12-4e1b-8b3b-85e8adaeba20	Beach	beach	2026-07-07 01:58:55.008878+00
f035e5ec-9311-4339-9985-420c78a36bbc	Hotel	hotel	2026-07-07 01:58:55.008878+00
dffaa1ab-09f1-4824-8e8a-2fd5ac6e44ce	Mountain	mountain	2026-07-07 01:58:55.008878+00
f70c3774-d1a6-48b8-a73d-901f5e6094d0	Forest	forest	2026-07-07 01:58:55.008878+00
3c67c5d6-f7c2-42b4-83a1-3e99e63cbea9	Waterfall	waterfall	2026-07-07 01:58:55.008878+00
37d3728c-c000-4a4e-9b65-51c5a2150ae9	Resort	resort	2026-07-07 01:58:55.008878+00
723e79d2-4a38-4939-9f89-ac29c1c3d358	Nature Park	park_rounded	2026-07-07 09:34:03.544193+00
f61e8714-4715-4797-ab47-faaa2d0de12c	Other	place_rounded	2026-07-07 09:34:03.544193+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id, name, description, created_at) FROM stdin;
8a483ddb-509a-45c2-aacd-7e3a6882d714	tourist	Default visitor role, can browse and book destinations	2026-07-05 12:38:31.381275+00
7821d062-4b4f-40c8-b5ec-47bd32687551	administrator	Manages destinations, events, and verifications	2026-07-05 12:38:31.381275+00
5b127512-cf37-422f-a263-e99fdd2cf748	super_admin	Full system access, including role management	2026-07-05 12:38:31.381275+00
816bb203-5df9-4054-977f-cc0a044b3143	tour_guide	Licensed guide who can create itineraries for tourists	2026-07-05 12:39:58.577317+00
494b3fee-959d-4c77-a88a-d11cd95c4ac9	owner	Resort and business owners who manage their listings, respond to reviews, and view analytics.	2026-07-05 12:38:31.381275+00
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.profiles (id, display_name, avatar_url, updated_at, email, username, phone, role, profile_image_url, preferences, budget, fcm_token, created_at) FROM stdin;
1302c0c5-9ea3-4435-8a27-755d9f1abb72	Arljhun Cadiente	\N	2026-07-03 06:12:36.001549+00	arljhun@gmail.com	arljhunaj	+639979438884	tourist	\N	{}	\N	\N	2026-07-05 12:32:16.929114+00
3fecfeb4-1890-4640-b68b-8742bfbbba92	Tourism Admin	\N	2026-07-06 05:06:04.057198+00	admin@samalnav.ph	\N	\N	administrator	\N	{}	\N	\N	2026-07-06 05:06:04.057198+00
d0670a7d-5fed-4094-a958-a417669b1995	System Super Admin	\N	2026-07-06 05:06:33.997074+00	superadmin@samalnav.ph	\N	\N	super_admin	\N	{}	\N	\N	2026-07-06 05:06:33.997074+00
451e16ae-adc0-4737-a763-799764db82f9	Manuel Rodriguez Jr.	\N	2026-07-06 05:02:31.805137+00	owner@resort.com	\N	\N	owner	\N	{}	\N	\N	2026-07-06 05:02:31.805137+00
8d1ab4fd-65a7-43de-8454-9bab690eb3ac	Sean Kingston	\N	2026-07-06 15:45:11.35961+00	sean@gmail.com	\N	\N	owner	\N	{}	\N	\N	2026-07-06 15:45:11.35961+00
2c0f3ba7-6f1e-4773-873f-ee62a73d03c0	Jose Santos	\N	2026-07-07 03:15:43.377607+00	jose.admin@samalnav.ph	\N	\N	administrator	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
d9dc21e2-0bb2-41b3-aaeb-554802cdbb13	Maria Teresa	\N	2026-07-07 03:15:43.377607+00	maria.super@samalnav.ph	\N	\N	super_admin	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
8c38e7d2-8eea-4381-b367-00522c66c869	Juan Dela Cruz	\N	2026-07-07 03:15:43.377607+00	juan.delacruz@traveler.ph	\N	\N	tourist	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
eff4f458-767c-413d-8bbd-5056b51a82be	Pedro Penduko	\N	2026-07-07 03:15:43.377607+00	pedro.penduko@journey.ph	\N	\N	tourist	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
eca9f8ee-660c-47de-95d2-4c6244d8e48b	Maria Clara	\N	2026-07-07 03:15:43.377607+00	maria.clara@explorer.ph	\N	\N	tourist	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
ba431694-9708-4bff-bd57-351067958290	Crisostomo Ibarra	\N	2026-07-07 03:15:43.377607+00	ibarra.cris@roam.ph	\N	\N	tourist	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
60dc06ee-c954-4fea-9058-bd595e4b2d84	Sarah Geronimo	\N	2026-07-07 03:15:43.377607+00	sarah.geronimo@vocal.ph	\N	\N	tourist	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
33c14c05-97d9-475b-b23d-25951125f072	Gary Valenciano	\N	2026-07-07 03:15:43.377607+00	gary.valenciano@energy.ph	\N	\N	tourist	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
fcc94890-59b1-405f-bd41-26ea5dcea322	Manuel Secdea	\N	2026-07-07 03:15:43.377607+00	manuel.secdea@samalnav.ph	\N	09171234567	owner	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
35200539-cf55-4e9d-96ef-db437de3c93c	Alicia Pearl	\N	2026-07-07 03:15:43.377607+00	alicia.pearl@samalnav.ph	\N	09171234567	owner	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
87105a9d-e58a-410d-adb3-de7b17f47f5f	Roberto Maxima	\N	2026-07-07 03:15:43.377607+00	roberto.maxima@samalnav.ph	\N	09171234567	owner	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
9922b42a-62ed-4881-85f7-fb59c91ed68e	Clarissa Reta	\N	2026-07-07 03:15:43.377607+00	clarissa.reta@samalnav.ph	\N	09171234567	owner	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
4bad6697-3cfc-4dcf-acb6-72d60bd4953b	David Monfort	\N	2026-07-07 03:15:43.377607+00	david.monfort@samalnav.ph	\N	09171234567	owner	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
1adcb205-7b62-4673-ae7a-2348466458c7	Elena Hagimit	\N	2026-07-07 03:15:43.377607+00	elena.hagimit@samalnav.ph	\N	09171234567	owner	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
8087214e-2634-4bd9-b45f-9c36402b9050	Juan Kaputian	\N	2026-07-07 03:15:43.377607+00	juan.kaputian@samalnav.ph	\N	09171234567	owner	\N	{}	\N	\N	2026-07-07 03:15:43.377607+00
\.


--
-- Data for Name: establishments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.establishments (id, owner_id, name, description, address, lat, lng, contact_phone, is_verified, created_at, category_id, category) FROM stdin;
2419fd6d-6735-490e-93ca-c7e187baf89a	4bad6697-3cfc-4dcf-acb6-72d60bd4953b	Monfort Bat Sanctuary	The world record holder for the largest single colony of Rousette fruit bats.	Babak, Samal	7.155	125.705	09170000005	t	2026-07-07 03:15:43.377607+00	f61e8714-4715-4797-ab47-faaa2d0de12c	Resort
c15f0522-f79f-4640-8375-c9ae439229c4	35200539-cf55-4e9d-96ef-db437de3c93c	Pearl Farm Beach Resort	An iconic luxury resort showcasing traditional Southern Filipino culture and stunning coral reef structures.	Kaputian, Samal	7.00496	125.72708	09170000002	t	2026-07-07 03:15:43.377607+00	37d3728c-c000-4a4e-9b65-51c5a2150ae9	Resort
b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	9922b42a-62ed-4881-85f7-fb59c91ed68e	Isla Reta Beach Resort	Known for the absolute fine white sands, crystal waters, and lush green talisay trees.	Talikud Island, Samal	6.9038	125.6836	09170000004	t	2026-07-07 03:15:43.377607+00	20452116-6f12-4e1b-8b3b-85e8adaeba20	Resort
6f0faeca-1554-4cd8-9512-8ee452675f94	fcc94890-59b1-405f-bd41-26ea5dcea322	Secdea Beach Resort	A premier destination resort in Samal Island with luxury pools and white sand beach.	Babak, Samal	7.1772	125.68	09170000001	t	2026-07-07 03:15:43.377607+00	37d3728c-c000-4a4e-9b65-51c5a2150ae9	Resort
c2dd097f-cd94-4085-a638-41a9c9605df8	87105a9d-e58a-410d-adb3-de7b17f47f5f	Maxima Aquafun	Best known for its giant water slides directly into the pristine sea waters.	Penaplata, Samal	7.0425	125.7275	09170000003	t	2026-07-07 03:15:43.377607+00	37d3728c-c000-4a4e-9b65-51c5a2150ae9	Resort
ca489969-3b12-49d9-b21d-00ab5f0b76c1	1adcb205-7b62-4673-ae7a-2348466458c7	Hagimit Falls Eco-Park	Beautiful natural cascading waterfalls surrounded by lush greenery and cool swimming spots.	Penaplata, Samal	7.06664	125.72301	09170000006	t	2026-07-07 03:15:43.377607+00	723e79d2-4a38-4939-9f89-ac29c1c3d358	Resort
17f649a7-88f9-402d-a8e4-9aec049d5cb0	8087214e-2634-4bd9-b45f-9c36402b9050	Kaputian Beach Club	Public resort area boasting a wide stretch of fine white sand beach and beach bungalows.	South Samal	6.9647	125.7231	09170000007	t	2026-07-07 03:15:43.377607+00	20452116-6f12-4e1b-8b3b-85e8adaeba20	Resort
5a5c83d3-3a56-4997-957e-bb04b992ccbc	451e16ae-adc0-4737-a763-799764db82f9	Pearl Farm Resort	A tourist spot hotel in samal island/	Samal Island	\N	\N	09239319231	t	2026-07-07 16:22:18.424956+00	f035e5ec-9311-4339-9985-420c78a36bbc	Resort
\.


--
-- Data for Name: destinations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.destinations (id, establishment_id, name, location, lat, lng, description, image_url, rating, is_active, is_verified, created_at, updated_at, geohash, entrance_fee, average_stay_minutes, operating_hours, status, rating_average, owner_id, image_urls, category_id, gallery_urls, category) FROM stdin;
da619b6e-26d0-4454-b206-da9cb395305b	17f649a7-88f9-402d-a8e4-9aec049d5cb0	Kaputian Beach	South Samal	6.9647	125.7231	\N	https://upload.wikimedia.org/wikipedia/commons/9/91/Kaputian_Beach_001.jpg	0.0	t	t	2026-07-07 03:15:43.377607+00	2026-10-01 12:21:20.972736+00	\N	100.00	60	{"open": "08:00", "close": "17:00"}	active	0.00	8087214e-2634-4bd9-b45f-9c36402b9050	{}	20452116-6f12-4e1b-8b3b-85e8adaeba20	\N	Beach
19b551fc-5bfd-409f-b686-9f0a8d812905	ca489969-3b12-49d9-b21d-00ab5f0b76c1	Hagimit Eco-Camping Ground	Penaplata, Samal	7.0669	125.7228	\N	\N	0.0	t	t	2026-07-07 03:15:43.377607+00	2026-10-01 12:21:20.972736+00	\N	250.00	60	{"open": "08:00", "close": "17:00"}	active	0.00	1adcb205-7b62-4673-ae7a-2348466458c7	{}	723e79d2-4a38-4939-9f89-ac29c1c3d358	\N	Nature Park
2ca37f5c-88d9-4d08-b3ee-1fb227573f93	ca489969-3b12-49d9-b21d-00ab5f0b76c1	Hagimit Falls	Penaplata, Samal	7.06664	125.72301	\N	https://upload.wikimedia.org/wikipedia/commons/a/a2/Hagimit_Falls_001.jpg	0.0	t	t	2026-07-07 03:15:43.377607+00	2026-10-01 12:21:20.972736+00	\N	75.00	60	{"open": "08:00", "close": "17:00"}	active	0.00	1adcb205-7b62-4673-ae7a-2348466458c7	{}	3c67c5d6-f7c2-42b4-83a1-3e99e63cbea9	\N	Waterfall
30890134-4cc3-467e-a0f2-215cf1e78bb7	\N	Bali-Bali View Deck	Peñaplata, Samal	7.0125	125.713	Serene seaside resort with Asian-inspired architecture and an elevated ocean view deck.	https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=600&q=80	4.5	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	30.00	90	{"open": "08:00", "close": "17:00"}	active	4.50	\N	{}	\N	\N	Resort
400819fd-4bc1-4c23-87e3-ca8a9b702cf6	\N	Club Samal Resort	Peñaplata, Samal	7.0985	125.672	Modern resort featuring a lagoon pool, ballroom facilities, and beachfront lounge.	https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80	4.3	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	150.00	120	{"open": "08:00", "close": "17:00"}	active	4.30	\N	{}	\N	\N	Resort
3f8c39a8-a63e-4fec-8e64-42a986ac29fe	\N	Chema's by the Sea	Peñaplata, Samal	7.0875	125.679	Boutique cottage resort nestled in nature with lush gardens and Mediterranean-style dining.	https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80	4.4	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	100.00	120	{"open": "08:00", "close": "17:00"}	active	4.40	\N	{}	\N	\N	Resort
e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	c2dd097f-cd94-4085-a638-41a9c9605df8	Maxima Aquafun	Penaplata, Samal	7.0425	125.7275	\N	\N	0.0	t	t	2026-07-07 03:15:43.377607+00	2026-10-01 12:21:20.972736+00	\N	300.00	60	{"open": "08:00", "close": "17:00"}	active	0.00	87105a9d-e58a-410d-adb3-de7b17f47f5f	{}	723e79d2-4a38-4939-9f89-ac29c1c3d358	\N	Nature Park
2e21694b-dc9a-4dbd-b6ad-094d62397265	\N	Malipano Island	Kaputian, Samal	7.002	125.715	Exclusive private island featuring pristine shores, tropical gardens, and luxury villas.	https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=600&q=80	4.6	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	0.00	180	{"open": "08:00", "close": "17:00"}	active	4.60	\N	{}	\N	\N	Island
6decddba-dd37-4dc6-93c6-5a2efe2542dd	\N	Ligid Island Cave	Peñaplata, Samal	7.185	125.755	Mysterious coastal cave and dive site featuring deep caverns and underwater rock formations.	https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?auto=format&fit=crop&w=600&q=80	4.4	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	100.00	60	{"open": "08:00", "close": "17:00"}	active	4.40	\N	{}	\N	\N	Historical
aaf3ba6f-5591-4a82-85d9-02822bf5a541	\N	Samal Island Huts	Peñaplata, Samal	7.085	125.689	Eco-friendly bamboo huts near the coast with serene ambiance and hospitable island service.	https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80	4.2	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	0.00	60	{"open": "08:00", "close": "17:00"}	active	4.20	\N	{}	\N	\N	Hotel
08b882c0-7304-42bc-bfef-7fa00c0fa784	\N	Cavanico Bella Beach Resort	Babak, Samal	7.129	125.783	Modern resort destination with wide sandy beach, sunset view dining, and pool facilities.	https://www.philippinetraveler.com/wp-content/uploads/cavanico-shoreline.jpg	4.5	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	200.00	150	{"open": "08:00", "close": "17:00"}	active	4.50	\N	{}	\N	\N	Resort
0ff6b5a2-a8bf-4617-9324-b06c536bdd2b	\N	Paradise Island	Peñaplata, Samal	7.1147	125.6585	Popular resort beach with water sports, swimming pools, beachfront cottages, and aviaries.	https://upload.wikimedia.org/wikipedia/commons/5/52/Paradise_Island_Beach.jpg	4.7	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	250.00	120	{"open": "08:00", "close": "17:00"}	active	4.70	\N	{}	\N	\N	Beach
68dae3d8-d387-44aa-885f-67c9dfad54bd	\N	Babu Santa Beach	Babak District, Samal	7.105	125.778	A quiet and scenic stretch of sand with calm waves, ideal for day picnics and relaxation.	https://upload.wikimedia.org/wikipedia/commons/2/2e/Samal_beach_1.jpg	4.4	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	50.00	90	{"open": "08:00", "close": "17:00"}	active	4.40	\N	{}	\N	\N	Beach
9dba7573-a0e2-42e9-9797-1696a86a77f6	\N	Tagbaobo Falls	Tagbaobo, Samal	7.0054	125.775	Scenic waterfall tucked inside lush rainforest, surrounded by native flora and hiking paths.	https://jedblinque15.wordpress.com/wp-content/uploads/2015/09/img_3743.jpg	4.5	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	30.00	90	{"open": "08:00", "close": "17:00"}	active	4.50	\N	{}	\N	\N	Falls
0c1d4136-b2cf-46e1-ad60-32fa15f3397a	6f0faeca-1554-4cd8-9512-8ee452675f94	Secdea Beach Resort	Babak, Samal	7.1772	125.68	\N	https://dynamic-media-cdn.tripadvisor.com/media/photo-o/21/d6/c1/be/caption.jpg?w=600&h=600&s=1	0.0	t	t	2026-07-07 03:15:43.377607+00	2026-10-01 14:36:05.858047+00	\N	500.00	60	{"open": "08:00", "close": "17:00"}	active	0.00	fcc94890-59b1-405f-bd41-26ea5dcea322	{}	37d3728c-c000-4a4e-9b65-51c5a2150ae9	\N	Resort
1a3c35c1-7a60-4309-9cff-6984088ef8ed	\N	Costa Marina Beach Resort	Babak, Samal	7.116	125.659	Sister resort of Paradise Island offering breezy shorelines and delicious local dishes.	https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80	4.4	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	200.00	120	{"open": "08:00", "close": "17:00"}	active	4.40	\N	{}	\N	\N	Resort
22ff7b5f-a599-4f10-aaef-903d0220bbf7	\N	Blue Waters Samal Resort	Peñaplata, Samal	7.078	125.683	Charming seaside resort with quiet ambiance, blue waters, and affordable day tour packages.	https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80	4.3	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	100.00	90	{"open": "08:00", "close": "17:00"}	active	4.30	\N	{}	\N	\N	Resort
075a1c56-c4bf-4c05-a38d-2f9d275efd5e	\N	Monfort Bat Sanctuary	Babak, Samal	7.165	125.688	Guinness World Record holder for the largest colony of Geoffroy's Rousette fruit bats.	https://dynamic-media-cdn.tripadvisor.com/media/photo-o/26/ce/16/f0/i-captured-this-during.jpg?w=1200&h=1200&s=1	4.5	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	100.00	60	{"open": "08:00", "close": "17:00"}	active	4.50	\N	{}	\N	\N	Historical
71a34e03-3294-4b25-87a2-ace66457a72f	\N	Precious Garden of Samal	Peñaplata, Samal	7.135	125.678	Cozy European-inspired garden resort featuring authentic international cuisine.	https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=600&q=80	4.1	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	120.00	90	{"open": "08:00", "close": "17:00"}	active	4.10	\N	{}	\N	\N	Resort
6322f4c9-9a5f-4cbf-955f-0c3fa4041e1e	\N	Samal Zipline	Peñaplata, Samal	7.045	125.705	Thrilling adventure zipline soaring through dense tropical forest canopies.	https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=600&q=80	4.4	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	300.00	60	{"open": "08:00", "close": "17:00"}	active	4.40	\N	{}	\N	\N	Forest
9584d2b7-d33a-44dd-b2bb-bf50256970f4	\N	Talikud Island	Kaputian District, Samal	6.925	125.695	Picturesque sister island south of Samal famous for untouched reefs, caves, and dive spots.	https://ik.imagekit.io/tvlk/xpe-asset/AyJ40ZAo1DOyPyKLZ9c3RGQHTP2oT4ZXW+QmPVVkFQiXFSv42UaHGzSmaSzQ8DO5QIbWPZuF+VkYVRk6gh-Vg4ECbfuQRQ4pHjWJ5Rmbtkk=/2000297407829/Talicud-Island-Hopping---1-Day-Tour-c36915d0-9bbf-4f74-8810-a97e53ed0b93.jpeg?tr=q-60,c-at_max,w-740,h-500&_src=imagekit	4.8	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	200.00	180	{"open": "08:00", "close": "17:00"}	active	4.80	\N	{}	\N	\N	Island
fa481212-c868-4f19-a4e5-76150a8012ea	\N	Punta del Sol Beach Resort	Babak, Samal	7.081	125.675	Budget-friendly coastal resort perfect for company outings and family gatherings.	https://upload.wikimedia.org/wikipedia/commons/8/82/Punta_Del_Sol_Beach_Resort_Cottage_-_panoramio.jpg	4.3	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	150.00	120	{"open": "08:00", "close": "17:00"}	active	4.30	\N	{}	\N	\N	Resort
b424ff62-2612-4930-8962-70e686a04acc	\N	Leticia by the Sea	Babak, Samal	6.941	125.718	Tranquil coastal retreat with beachfront villas, seaside infinity pool, and sea view patio.	https://davaoportal.com/wp-content/uploads/2013/11/Leticia-by-the-sea-318x500.jpg	4.3	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	0.00	60	{"open": "08:00", "close": "17:00"}	active	4.30	\N	{}	\N	\N	Hotel
336ca252-6231-4da9-b5ae-7de3789aefe4	\N	Vanishing Island	Babak District, Samal	7.129	125.648	A sandbar that appears only during low tide in the middle of the Samal Strait.	https://i0.wp.com/realbreezedavaotours.com/wp-content/uploads/2024/11/Vanishing-Island.jpg?fit=541%2C448&ssl=1	4.7	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	300.00	120	{"open": "08:00", "close": "17:00"}	active	4.70	\N	{}	\N	\N	Beach
7066f04e-be9f-4deb-8a52-0531357f865b	\N	Canibad Beach	Babak District, Samal	7.1353	125.7925	Hidden cove with turquoise water, great for cliff diving, snorkeling, and camping.	https://upload.wikimedia.org/wikipedia/commons/f/fe/Travel_to_Samal_Island_Philippines.jpg	4.6	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	80.00	90	{"open": "08:00", "close": "17:00"}	active	4.60	\N	{}	\N	\N	Beach
a174157c-cecc-4890-83a7-071fbafdf7b0	\N	Mt. Puting Bato	Bali-Bali, Samal	7.0656	125.758	Highest peak in Samal Island (1,755 ft) offering 360-degree panoramic views of Davao Gulf.	https://upload.wikimedia.org/wikipedia/commons/b/b9/Puting_Bato.jpg	4.6	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	0.00	150	{"open": "08:00", "close": "17:00"}	active	4.60	\N	{}	\N	\N	Mountain
d1b558c3-45a6-426a-a2fe-3441e99335b3	\N	Hof Gorei Beach Resort	Babak, Samal	7.152	125.668	Exclusive boutique resort offering personalized Butler service and hilltop bungalows.	https://samalguide.com/wp-content/uploads/2021/03/Hof-Gorei4-1.jpeg	4.6	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	250.00	150	{"open": "08:00", "close": "17:00"}	active	4.60	\N	{}	\N	\N	Resort
fa0643b6-1e98-4b6a-859b-ae1f7c98e8eb	\N	Camp Holiday Resort	Babak, Samal	7.1275	125.6655	Convenient resort located right beside the Babak ferry terminal with camping grounds and pools.	https://davaoportal.com/wp-content/uploads/2021/03/759803-500x399.jpg	4.2	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	200.00	120	{"open": "08:00", "close": "17:00"}	active	4.20	\N	{}	\N	\N	Resort
96f999df-3e89-41b9-aab3-4bbaeecb3d39	\N	Coral Garden	Talikud Island, Samal	6.915	125.685	Protected marine sanctuary teeming with colorful corals, giant clams, and tropical fish.	https://images.unsplash.com/photo-1546026423-cc4642628d2b?auto=format&fit=crop&w=600&q=80	4.7	t	t	2026-09-22 07:16:21.959715+00	2026-10-01 12:21:20.972736+00	\N	500.00	120	{"open": "08:00", "close": "17:00"}	active	4.70	\N	{}	\N	\N	Island
5be07ec5-acaa-4992-978f-2a46fba50dd1	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	Isla Reta Beach	Talikud Island, Samal	6.9038	125.6836	\N	https://upload.wikimedia.org/wikipedia/commons/8/8d/Samal_Island.JPG	0.0	t	t	2026-07-07 03:15:43.377607+00	2026-10-01 12:21:20.972736+00	\N	150.00	60	{"open": "08:00", "close": "17:00"}	active	0.00	9922b42a-62ed-4881-85f7-fb59c91ed68e	{}	20452116-6f12-4e1b-8b3b-85e8adaeba20	\N	Beach
0e5a6c48-fb64-44dc-9792-d05391f61a1d	c15f0522-f79f-4640-8375-c9ae439229c4	Pearl Farm Resort	Kaputian, Samal	7.00496	125.72708	\N	https://upload.wikimedia.org/wikipedia/commons/f/f6/Pearl_Farm_at_Samal_Island%2C_Davao.jpg	0.0	t	t	2026-07-07 03:15:43.377607+00	2026-10-01 12:21:20.972736+00	\N	1500.00	60	{"open": "08:00", "close": "17:00"}	active	0.00	35200539-cf55-4e9d-96ef-db437de3c93c	{}	37d3728c-c000-4a4e-9b65-51c5a2150ae9	\N	Resort
\.


--
-- Data for Name: activities; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.activities (id, destination_id, establishment_id, name, description, category, price, duration_minutes, difficulty_level, is_elder_friendly, is_child_friendly, min_age, max_pax, image_url, is_active, created_at, updated_at) FROM stdin;
b45f18bf-727b-4723-be03-24ca823d0602	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	6f0faeca-1554-4cd8-9512-8ee452675f94	Beach Volleyball	Play on the white sand volleyball court with stunning ocean views.	land_adventure	0.00	60	easy	t	t	5	12	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
7bc882c9-3cb6-4608-826e-f2d5c976504e	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	6f0faeca-1554-4cd8-9512-8ee452675f94	Jet Ski Rental	Ride a jet ski across the crystal-clear waters of the Davao Gulf.	water_sport	1500.00	30	moderate	f	f	16	2	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
a56366af-48d5-4749-999e-2b762976a9ce	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	6f0faeca-1554-4cd8-9512-8ee452675f94	Sunset Kayaking	Paddle along the coast during golden hour for breathtaking sunset views.	water_sport	350.00	45	easy	t	t	8	4	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
6f5fcc90-163a-4831-a221-59c0107685d1	0e5a6c48-fb64-44dc-9792-d05391f61a1d	c15f0522-f79f-4640-8375-c9ae439229c4	Snorkeling Tour	Guided snorkeling to see coral gardens and tropical fish around the resort.	water_sport	500.00	90	moderate	t	t	8	10	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
1519dcc5-5b51-4e59-b4b0-aa5a431c0ef2	0e5a6c48-fb64-44dc-9792-d05391f61a1d	c15f0522-f79f-4640-8375-c9ae439229c4	Mandaya Cultural Show	Watch traditional Mandaya tribal dances and music performances.	cultural	250.00	45	easy	t	t	0	50	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
cbc9f9f4-a6bf-4e77-987a-8a773b58ec67	0e5a6c48-fb64-44dc-9792-d05391f61a1d	c15f0522-f79f-4640-8375-c9ae439229c4	Island Hopping Tour	Visit hidden coves and snorkeling spots around Samal by boat.	water_sport	2000.00	240	moderate	t	t	5	15	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
dc798c6a-2d36-473a-8805-14d033f74343	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	c2dd097f-cd94-4085-a638-41a9c9605df8	Giant Water Slide	Slide down the famous 60-meter water slide straight into the sea!	water_sport	150.00	15	moderate	f	t	8	1	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
0e036fd1-fe74-4139-acbd-4d5ffc27f4c5	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	c2dd097f-cd94-4085-a638-41a9c9605df8	Aqua Obstacle Course	Floating inflatable obstacle course on the ocean for all ages.	water_sport	200.00	30	moderate	f	t	10	20	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
00ef87ab-e135-411a-928b-9d21c7f5dcec	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	c2dd097f-cd94-4085-a638-41a9c9605df8	Swimming Pool Access	All-day access to the freshwater swimming pools with lifeguard.	water_sport	100.00	480	easy	t	t	0	50	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
4cb3f293-9f93-4a6b-97bf-a6936058e096	5be07ec5-acaa-4992-978f-2a46fba50dd1	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	Snorkeling and Reef Walk	Explore vibrant coral reefs just off the white sand shore.	water_sport	200.00	60	easy	t	t	6	8	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
cfc33233-c94b-4a06-b9a4-72e97d2b409c	5be07ec5-acaa-4992-978f-2a46fba50dd1	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	Beach Bonfire Night	Evening bonfire with grilled seafood, acoustic music, and stargazing.	entertainment	300.00	120	easy	t	t	0	30	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
7c964e19-2504-4097-b4bb-be54cb3db732	5be07ec5-acaa-4992-978f-2a46fba50dd1	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	Banana Boat Ride	Thrilling banana boat ride across the turquoise waters.	water_sport	150.00	15	moderate	t	t	5	6	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
dee1c687-56e8-45e3-aad3-f3203834727c	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	ca489969-3b12-49d9-b21d-00ab5f0b76c1	Waterfall Swimming	Swim in the natural rock pools beneath the multi-tiered waterfall.	water_sport	75.00	120	easy	t	t	5	30	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
cfbc1476-23be-4221-a7b1-229929d8342e	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	ca489969-3b12-49d9-b21d-00ab5f0b76c1	Cliff Jumping	Jump from natural rock formations into the deep pool below.	land_adventure	0.00	30	extreme	f	f	16	5	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
2a1c24f7-382d-475a-9271-b9f153b7dbab	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	ca489969-3b12-49d9-b21d-00ab5f0b76c1	Forest Trekking	Guided trek through the rainforest canopy trail to the upper falls.	nature	100.00	90	moderate	f	t	10	12	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
bce77cb7-06c0-4dbd-85ba-4bdb20a202f0	19b551fc-5bfd-409f-b686-9f0a8d812905	ca489969-3b12-49d9-b21d-00ab5f0b76c1	Eco-Camping Overnight	Camp under the stars near the waterfalls with tent and equipment included.	nature	250.00	720	moderate	f	t	10	8	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
dee9d3d5-7445-4777-9bd3-a99659cbb3e5	19b551fc-5bfd-409f-b686-9f0a8d812905	ca489969-3b12-49d9-b21d-00ab5f0b76c1	BBQ Cookout Package	Group barbecue setup with fresh seafood and local meats beside the falls.	dining	500.00	120	easy	t	t	0	20	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
d06b9f85-e10f-4f06-bdb8-3407864b0856	da619b6e-26d0-4454-b206-da9cb395305b	17f649a7-88f9-402d-a8e4-9aec049d5cb0	Beach Frisbee and Games	Free beach games on the wide white sand: frisbee, football, and sandcastle kits.	entertainment	0.00	60	easy	t	t	3	20	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
63fe6fdf-2917-4f00-ab9c-b2dc73ec7d37	da619b6e-26d0-4454-b206-da9cb395305b	17f649a7-88f9-402d-a8e4-9aec049d5cb0	Stand-Up Paddleboarding	Rent a paddleboard and explore the calm bay waters.	water_sport	300.00	60	moderate	t	f	12	1	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
58a69809-d2de-4633-82ab-ec477306be3b	da619b6e-26d0-4454-b206-da9cb395305b	17f649a7-88f9-402d-a8e4-9aec049d5cb0	Boodle Fight Lunch	Filipino communal feast served on banana leaves at the beach.	dining	350.00	60	easy	t	t	0	15	\N	t	2026-07-26 04:07:39.558793+00	2026-07-26 04:07:39.558793+00
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.audit_logs (id, user_id, action_type, description, metadata, created_at, actor_id, role, action, target_id, device_info, ip_address) FROM stdin;
43315420-139e-482e-99f0-4c1042c4386e	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-06 05:13:58.008232+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
b7914260-9091-4a8a-9606-d310b086a84a	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Tourism Establishment signed in (management portal)	{}	2026-07-06 05:15:01.104049+00	451e16ae-adc0-4737-a763-799764db82f9	establishment	LOGIN	\N	\N	\N
da2e02c2-428a-4756-8fb4-488dabd7d22c	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-06 07:35:37.396391+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
69abf0c8-8a88-4711-8c42-36c40e84bfea	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 14:08:01.28068+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
6b8368c2-4f6e-46f2-adf2-ebe778936e21	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 14:12:34.0711+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
1cfddc51-123d-437a-9999-660fdb6e0949	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 14:31:23.12648+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
9bd7262f-0a52-4846-bac4-85ea2818cf18	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 14:33:00.337779+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
c7b2aa7e-c455-45a9-a973-798171007184	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 14:40:57.82602+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
0140eda8-9667-4e89-8769-659123ef86ea	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 15:03:11.409085+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
eeb3efbc-ab22-4b6c-8251-c9ee1fcab833	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-06 15:34:32.850824+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
7e9ef6c9-75fb-4c92-a569-0abca49e6082	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-06 15:36:07.197365+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
2bb4dc16-0f6e-4245-915e-ae8ac80556af	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 15:36:51.267856+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
7b5e2e05-802b-4989-b5f2-5932a452308f	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-06 15:44:03.351158+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
a2eb8e5c-8743-48be-ad3c-1bad39856649	8d1ab4fd-65a7-43de-8454-9bab690eb3ac	USER_CREATE	Created owner account: sean@gmail.com	{}	2026-07-06 15:45:12.178141+00	8d1ab4fd-65a7-43de-8454-9bab690eb3ac	establishment	USER_CREATE	\N	\N	\N
a5363655-cc16-4f01-905e-ef822f345ad8	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 15:45:45.184048+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
217eb296-d192-4990-b016-c046323a7f68	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-06 15:46:59.768791+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
4a0a786c-18a4-4c6a-a6ed-053227a15266	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Tourism Establishment signed in (management portal)	{}	2026-07-06 16:15:43.327265+00	451e16ae-adc0-4737-a763-799764db82f9	establishment	LOGIN	\N	\N	\N
7bd2b1c0-d34f-4518-a7ea-d80b19509b79	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-06 16:17:15.196638+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
60c5e813-ec55-4863-bd95-5fed9d8540eb	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Tourism Establishment signed in (management portal)	{}	2026-07-06 16:17:59.027855+00	451e16ae-adc0-4737-a763-799764db82f9	establishment	LOGIN	\N	\N	\N
f5dd0fa6-f820-4ec3-bb69-0d3661e1dfe0	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-06 16:19:21.377048+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
8d536540-67d7-4e14-a129-bb86b8c525b1	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Tourism Establishment signed in (management portal)	{}	2026-07-07 01:15:11.396125+00	451e16ae-adc0-4737-a763-799764db82f9	establishment	LOGIN	\N	\N	\N
5212a582-a808-481d-9850-f88a2bf228ce	8d1ab4fd-65a7-43de-8454-9bab690eb3ac	LOGIN	Tourism Establishment signed in (management portal)	{}	2026-07-07 01:23:05.446887+00	8d1ab4fd-65a7-43de-8454-9bab690eb3ac	establishment	LOGIN	\N	\N	\N
f9a585f3-4617-48c1-89b2-5ce3e81696b3	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-07 01:52:39.424829+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
c46a680d-9c7c-4697-a928-d03a4d6e3005	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 01:54:11.157466+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
586e745d-b9cc-4b79-a8f0-9c92c1183455	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-07 13:20:30.468287+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
4d5a6e6c-e19c-40bc-92e2-a15af8dc4971	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 14:31:48.153243+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
94e08dee-3a08-4b50-92a4-3d74fb96eb94	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 14:46:35.260469+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
2be31f60-5fa0-4a16-9a31-d28ab93b5419	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-07 14:47:20.45012+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
3a5f3f9a-5e43-4eea-88d9-76fdd808652d	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 14:47:36.136243+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
f57a980b-df73-43ce-88fd-cbee523dc1d0	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 14:47:42.847254+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
4d1cc8e5-03d8-4e73-9ee3-5df9413f6b93	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 14:48:22.213333+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
4e2dec25-9b9d-4bdf-8d44-780b0188febc	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 14:52:44.232196+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
78dbf5d5-c6b7-4b24-8a3a-be9f72cad76f	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-07 15:12:10.370746+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
d3968fd6-01dc-426b-9100-4acd0b736b27	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-07 15:14:09.97729+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
ca68268c-066c-493d-90b2-498936644f92	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 15:41:33.699305+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
35995d61-2665-4516-9184-f257e13242d5	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: fcc94890-59b1-405f-bd41-26ea5dcea322	{}	2026-07-07 15:41:40.164365+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
935aa204-6efd-4739-b5a4-adbdb1e16970	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 4bad6697-3cfc-4dcf-acb6-72d60bd4953b	{}	2026-07-07 15:41:43.918557+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
00049086-822c-402e-8a29-67d88ea8e1e8	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 15:42:24.476849+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
095c436b-6ae2-4a7a-980d-7245b76bcaaa	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 15:53:08.513346+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
5493edee-7855-4e06-838d-f65b83aed936	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 16:24:54.560018+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
53cb4acd-e88b-440b-b06d-ec4278c505be	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-07 16:25:25.943239+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
39a64d4c-e5a1-4fa4-b5c6-8c1ac250fa52	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 16:36:44.037616+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
857e4222-8e0b-4258-a7c2-1c177c8b3ae0	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 16:36:48.520436+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
2b833c06-a1bb-4fcf-89a3-a310b3ea56e2	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 4bad6697-3cfc-4dcf-acb6-72d60bd4953b	{}	2026-07-07 16:36:52.843672+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
1778c887-618b-4827-adaa-67cabb67a6b4	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 16:45:54.875853+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
826df744-55b6-46e4-9348-87b07c1f2935	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 16:46:03.757346+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
a7c6a545-1c92-44b3-9315-3fbb3905acdb	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 16:48:21.644853+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
ce18c674-e247-40f7-bff4-2d063523055d	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: fcc94890-59b1-405f-bd41-26ea5dcea322	{}	2026-07-07 17:00:46.015144+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
b04ecdba-c93f-46fe-88cc-dd4a65b0e8e7	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 17:01:00.692602+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
a0194e0d-953f-4350-8ed2-044cb44e4507	3fecfeb4-1890-4640-b68b-8742bfbbba92	VERIFY	Verified owner: 451e16ae-adc0-4737-a763-799764db82f9	{}	2026-07-07 17:01:58.12868+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	VERIFY	\N	\N	\N
4d49ec80-5c12-4e7b-b2d2-025c6771e613	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 17:12:26.409411+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
d6313d12-9997-406c-aeee-4a8b200d1955	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in	{}	2026-07-07 17:33:35.642501+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
0afe2198-ec6d-4ad4-99d5-71301ffb68aa	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in	{}	2026-07-07 17:34:01.287501+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
14617d2a-7307-491e-ae96-8e06054e586d	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-07 17:35:13.829159+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
4cdff4a4-9cb1-497a-b480-34b9706c7c2d	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-07 17:35:40.922677+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
82ab33ee-c296-4742-8987-6f2bb9ae15c6	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-07 17:37:35.743212+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
9787f12b-ec30-4618-a487-5a8473594dc2	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-07 20:13:25.214704+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
e7a947c8-857b-4ceb-952d-89c6f6325140	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-08 02:55:18.268115+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
c7899933-1487-4e7c-b77e-4402e620a229	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in	{}	2026-07-08 03:41:11.047434+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
4213b05c-4249-4768-8ddb-035d8d0ccd45	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-08 03:42:35.743978+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
47e60794-a0fc-492c-8ba4-7cc3c32f9258	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-08 03:43:39.484372+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
d4f35c3c-cd6d-483c-b751-c6dca82747fb	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-08 03:57:42.579652+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
4d54238c-58cb-45e7-acb2-74ce1d7d8270	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-08 04:05:55.960151+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
c71f7226-3562-47da-85d1-f39172f6faee	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-08 04:06:48.043076+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
83b5c9e2-afd5-466a-8e84-30c6f44da80c	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-08 04:08:22.578691+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
1b39958f-b858-4d92-9657-b558e7e89c54	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-08 04:12:06.501926+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
ee67c8fd-f23a-4c96-8733-ff5cfb0c290d	3fecfeb4-1890-4640-b68b-8742bfbbba92	LOGIN	Administrator signed in (management portal)	{}	2026-07-08 04:17:48.995791+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
956990f5-3a7f-4965-bb77-8d5eddbb0557	d0670a7d-5fed-4094-a958-a417669b1995	LOGIN	Super Admin signed in (management portal)	{}	2026-07-08 04:18:17.254557+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
5d0d0405-7d34-4305-976d-88c7f4cd9fd1	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-08 04:18:41.887343+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
5c49f585-2e1d-471e-ad1c-763e9ec59489	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-08 05:31:22.500893+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
b2c752dd-6fff-4f2d-a5f3-1d7db5962bc5	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-26 02:53:38.049876+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
66f2a304-6033-4a9c-8311-4fc82277cdff	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-26 03:10:43.316645+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
0017d252-81f8-4af3-8870-d9be01b75a5f	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-27 08:25:03.541949+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
87fa8da0-3e9c-4ab4-9ee3-4fdd145065a6	451e16ae-adc0-4737-a763-799764db82f9	LOGIN	Owner signed in (management portal)	{}	2026-07-27 08:38:30.130169+00	451e16ae-adc0-4737-a763-799764db82f9	owner	LOGIN	\N	\N	\N
e595dcbd-0542-4582-a924-ad08facd28a8	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-27 08:39:38.375237+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
67619fec-0ab7-4f9e-955f-bc1ae3f1db7c	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-28 03:30:49.896445+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
dd543dbb-8627-4ad3-b5ed-6ec0931512f7	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-07-29 04:40:16.383007+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
41df05fa-e6f9-41d8-882d-cc6058460ccf	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-08-12 11:34:56.078954+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
8a7a3f2f-3c25-4f4c-bec9-51f5d3e952a5	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-08-12 13:36:08.146642+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
fbbfecaf-e6c3-4bf7-9442-c8cc9e92e523	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-08-12 15:57:19.4448+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
d31b5557-4811-40d6-bbd8-484d73023bbd	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-09-15 05:57:19.652229+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
4f679961-f94b-4c14-a56b-730cce7bcaa2	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-09-15 06:28:39.163066+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
65e90c93-3325-4a26-9875-eaa7cf170ad8	\N	LOGIN	administrator signed in to SamalNav	{}	2026-09-22 07:17:35.672935+00	3fecfeb4-1890-4640-b68b-8742bfbbba92	administrator	LOGIN	\N	\N	\N
0825be43-f2ea-4d2e-9f63-89c1e6f71ef6	\N	LOGIN	super_admin signed in to SamalNav	{}	2026-09-22 07:17:35.672935+00	d0670a7d-5fed-4094-a958-a417669b1995	super_admin	LOGIN	\N	\N	\N
abb418e2-dd46-4c40-a9c4-8e89a9d456c3	\N	LOGIN	administrator signed in to SamalNav	{}	2026-09-22 07:17:35.672935+00	2c0f3ba7-6f1e-4773-873f-ee62a73d03c0	administrator	LOGIN	\N	\N	\N
7351ec59-ea09-4439-a5cf-9a858a650d9a	\N	LOGIN	super_admin signed in to SamalNav	{}	2026-09-22 07:17:35.672935+00	d9dc21e2-0bb2-41b3-aaeb-554802cdbb13	super_admin	LOGIN	\N	\N	\N
2d2f1d4e-c4d8-4eec-9663-a140ad968791	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-10-01 07:52:49.191282+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
834eb9a2-05f4-4d41-a5b0-facf729a4a75	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-11-10 15:18:04.140066+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
112b54d1-7c93-4b3d-9a59-0abd15a27cda	1302c0c5-9ea3-4435-8a27-755d9f1abb72	LOGIN	Tourist signed in	{}	2026-11-15 09:24:49.345932+00	1302c0c5-9ea3-4435-8a27-755d9f1abb72	tourist	LOGIN	\N	\N	\N
\.


--
-- Data for Name: destination_availability; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.destination_availability (id, destination_id, date, open_time, close_time, is_available) FROM stdin;
e53d84fa-3088-4c81-9b85-e123fb9f7cac	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	2026-07-07	08:00:00	18:00:00	t
20bd7dda-9143-410b-aef9-7685111c0559	0e5a6c48-fb64-44dc-9792-d05391f61a1d	2026-07-07	07:00:00	21:00:00	t
6ab7da48-e703-49b0-99f3-e4fce95882fa	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	2026-07-07	08:00:00	17:00:00	t
21156eb2-a67b-4b9e-9916-bd4b41d56d67	5be07ec5-acaa-4992-978f-2a46fba50dd1	2026-07-07	06:00:00	18:00:00	t
f0aff171-1855-4800-a907-20839874ea11	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	2026-07-07	06:00:00	18:00:00	t
435eac1a-c7ad-48a7-a425-dfafce09e973	da619b6e-26d0-4454-b206-da9cb395305b	2026-07-07	06:00:00	20:00:00	t
17b27987-2169-47a0-9102-260ab0ce0ea4	19b551fc-5bfd-409f-b686-9f0a8d812905	2026-07-07	00:00:00	23:59:59	t
\.


--
-- Data for Name: destination_gallery; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.destination_gallery (id, destination_id, image_url, caption, created_at) FROM stdin;
a55d767f-7a80-450c-82a5-e76691e45029	336ca252-6231-4da9-b5ae-7de3789aefe4	https://i0.wp.com/realbreezedavaotours.com/wp-content/uploads/2024/11/Vanishing-Island.jpg?fit=541%2C448&ssl=1	\N	2026-10-01 09:46:49.68449+00
48f70c77-6db7-48f0-a59c-4d5dc1591b26	336ca252-6231-4da9-b5ae-7de3789aefe4	https://i0.wp.com/realbreezedavaotours.com/wp-content/uploads/2015/07/VanishingIsland.jpg?resize=800%2C560&ssl=1	\N	2026-10-01 09:46:49.68449+00
5c45e8c9-4f3c-4ec7-a4c3-18ed1f05f4a0	075a1c56-c4bf-4c05-a38d-2f9d275efd5e	https://i0.wp.com/wayph.com/wp-content/uploads/2016/09/Monfort-Bat-Cave-2-2.jpg?resize=800%2C530	\N	2026-10-01 12:21:20.972736+00
5e85cf84-f8dc-43d9-91bd-f5cd45121af2	075a1c56-c4bf-4c05-a38d-2f9d275efd5e	https://d3fphkxyf5o5bm.cloudfront.net/image-resize/format=webp,w=720/QwRY54Li1HMwD7oNfoY2VXJsthPmARE2lBWsvSGq9F	\N	2026-10-01 12:21:20.972736+00
35e82ecb-51cf-40f4-a808-cb5b991f0eae	08b882c0-7304-42bc-bfef-7fa00c0fa784	https://popdavao.com/wp-content/uploads/2023/01/swimming-pool.jpg?w=616	\N	2026-10-01 12:21:20.972736+00
30bab423-e424-4342-960b-1c373c4f8773	08b882c0-7304-42bc-bfef-7fa00c0fa784	https://lookaside.fbsbx.com/lookaside/crawler/media/?media_id=1195671762601076	\N	2026-10-01 12:21:20.972736+00
96745755-1893-401e-a9db-8915220139ac	08b882c0-7304-42bc-bfef-7fa00c0fa784	https://dynamic-media-cdn.tripadvisor.com/media/photo-o/17/29/db/be/img-20190414-224919-largejpg.jpg?w=500&h=-1&s=1	\N	2026-10-01 12:21:20.972736+00
ee353a34-3cde-481e-bd28-5380da635e3d	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	https://i0.wp.com/samalguide.com/wp-content/uploads/2014/09/Secdea-Beach-Resort-18.jpg?ssl=1	\N	2026-10-01 12:21:20.972736+00
a2853300-724d-4ccc-bd38-67e68fd5b49d	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	https://i0.wp.com/samalguide.com/wp-content/uploads/2024/01/Secdea-2.jpg?fit=900%2C600&ssl=1	\N	2026-10-01 12:21:20.972736+00
b06a77ac-3b15-4ac5-9fdb-543eacb2d168	075a1c56-c4bf-4c05-a38d-2f9d275efd5e	https://i.redd.it/nlsivc8w2wp31.jpg	\N	2026-10-01 12:56:34.417321+00
15256528-df5c-4075-b9f2-803b753ce757	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	https://dynamic-media-cdn.tripadvisor.com/media/photo-o/11/84/7b/82/secdea-beach-resort.jpg?w=900&h=500&s=1	\N	2026-10-01 12:21:20.972736+00
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.events (id, title, description, event_date, category, posted_by, created_at) FROM stdin;
e95d0d18-e702-421e-8f5c-77212dd51850	Samal Island Tourism Week	Join us for a week-long celebration of Samal Island culture, food, and adventure!	2026-10-06 07:17:35.672935+00	festival	3fecfeb4-1890-4640-b68b-8742bfbbba92	2026-09-22 07:17:35.672935+00
\.


--
-- Data for Name: favorites; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.favorites (id, user_id, place_name, created_at, destination_id, location, rating, category) FROM stdin;
aa01353d-df28-477c-a6c9-9eceaa496912	1302c0c5-9ea3-4435-8a27-755d9f1abb72	Isla Reta Beach	2026-07-07 14:05:21.392258+00	5be07ec5-acaa-4992-978f-2a46fba50dd1	Talikud Island, Samal	4.33	Beach
a676043c-d9b9-4e18-8f22-f673bb04d5d9	1302c0c5-9ea3-4435-8a27-755d9f1abb72	Hagimit Falls	2026-07-07 17:55:23.690856+00	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	Penaplata, Samal	4.00	Nature Park
\.


--
-- Data for Name: itineraries; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.itineraries (id, tourist_id, itinerary_category, type, current_stop_index, total_cost, total_distance, total_travel_time, fitness_score, generated_at, status) FROM stdin;
b9a08070-be86-4cbd-9007-065222d11296	8c38e7d2-8eea-4381-b367-00522c66c869	single_destination	single_day	1	500.00	15.20	45	95.5000	2026-07-07 03:15:43.377607+00	active
1de844e8-dd09-46a8-8753-a140a2e7eb16	eff4f458-767c-413d-8bbd-5056b51a82be	multi_destination	single_day	2	2300.00	32.50	90	88.0000	2026-07-07 03:15:43.377607+00	active
13ef266c-f3a9-49c6-8728-0b2c69199ad8	eca9f8ee-660c-47de-95d2-4c6244d8e48b	single_destination	single_day	1	300.00	12.80	30	92.5000	2026-07-07 03:15:43.377607+00	active
33379cd3-872d-4903-b427-79faa1669c2a	ba431694-9708-4bff-bd57-351067958290	multi_destination	multi_day	2	1350.00	45.00	120	85.0000	2026-07-07 03:15:43.377607+00	active
f0e29d62-7a68-4cb8-9b3d-31682a6542f9	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	4875.00	38.37	1500	10.0000	2026-07-07 20:14:08.885502+00	active
8b26d3d0-6c49-41dd-a37f-673d38b4ef20	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	8925.00	37.49	1440	10.0000	2026-07-07 20:14:45.059511+00	active
5ef264a2-ac52-46cc-9cf3-347b87391305	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	9225.00	39.75	1320	35.0000	2026-07-07 20:17:07.295803+00	active
4516deb4-27f9-4693-b226-0b3e22bd66ad	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	single_day	0	7375.00	44.29	1620	30.0000	2026-07-07 20:20:10.530746+00	active
a5b5458d-8ccd-4394-92a1-ae460ea35f73	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	8925.00	37.45	1440	0.0000	2026-07-07 20:35:05.090192+00	active
28c022ea-6aef-4453-9627-730ed84c3df6	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	8925.00	37.45	1440	10.0000	2026-07-08 03:58:42.331964+00	active
41c46bb3-1728-4a7c-babe-1165b7531198	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	8925.00	37.49	1440	0.0000	2026-07-08 05:36:40.306524+00	active
28e3f43f-b110-4405-91bf-eefd25cfc6cc	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	9975.00	42.49	1620	55.0000	2026-07-08 05:48:03.08659+00	active
6f6714dd-4ede-411e-a568-9d6d9f12a421	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	single_day	0	1825.00	3.54	300	100.0000	2026-07-26 03:15:40.702972+00	active
a8552ce6-e8b3-446a-b86e-0db9a563adc1	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	single_day	0	1825.00	3.54	300	100.0000	2026-07-26 03:15:43.545068+00	active
d2757c79-c87d-4627-b284-0856abc3dd0b	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	single_day	0	1825.00	3.54	300	100.0000	2026-07-26 03:16:00.226678+00	active
7b7f7e7a-897e-4db2-ab32-fb58328eda4a	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	single_day	0	12300.00	1.08	300	100.0000	2026-07-27 08:34:33.871942+00	active
96ed21ee-3585-483a-a444-e94e97c324a2	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	8925.00	40.78	1440	0.0000	2026-07-28 03:31:21.10887+00	active
0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	multi_day	0	7375.00	38.31	1620	30.0000	2026-07-29 05:22:37.220299+00	active
68c06ab9-e4bf-4057-82f8-a14dd3c9df87	1302c0c5-9ea3-4435-8a27-755d9f1abb72	multi_destination	single_day	0	3675.00	43.28	1440	27.2727	2026-08-12 13:37:17.237117+00	active
\.


--
-- Data for Name: itinerary_stops; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.itinerary_stops (id, itinerary_id, destination_id, day_number, sequence, arrival_time, departure_time, estimated_travel_minutes, contribution_score, is_completed) FROM stdin;
f953d1ed-e72b-48e9-a3cf-439c26afe9e7	b9a08070-be86-4cbd-9007-065222d11296	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	1	1	2026-07-06 03:15:43.377607+00	2026-07-06 05:15:43.377607+00	0	0.0000	t
28c95eca-aef3-49b0-810e-c75ed4bb74c0	1de844e8-dd09-46a8-8753-a140a2e7eb16	0e5a6c48-fb64-44dc-9792-d05391f61a1d	1	1	2026-07-05 03:15:43.377607+00	2026-07-05 07:15:43.377607+00	0	0.0000	t
3a4ccaf8-3d9e-4f5c-8f0f-d3da659f3889	13ef266c-f3a9-49c6-8728-0b2c69199ad8	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	1	1	2026-07-04 03:15:43.377607+00	2026-07-04 05:15:43.377607+00	0	0.0000	t
786aa962-55d9-4cc0-9fa5-a8ce442e05b7	33379cd3-872d-4903-b427-79faa1669c2a	5be07ec5-acaa-4992-978f-2a46fba50dd1	1	1	2026-07-03 03:15:43.377607+00	2026-07-03 09:15:43.377607+00	0	0.0000	t
a830ba08-bfed-46d4-9418-b707de962f88	33379cd3-872d-4903-b427-79faa1669c2a	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	2	2	2026-07-04 03:15:43.377607+00	2026-07-04 09:15:43.377607+00	0	0.0000	t
65f0338f-e8fa-4e16-9110-21629f77b683	f0e29d62-7a68-4cb8-9b3d-31682a6542f9	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	1	1	2026-07-08 08:00:00+00	2026-07-08 11:00:00+00	0	0.0000	f
ad895c10-a47a-4ac4-afc8-7921a67cfac6	f0e29d62-7a68-4cb8-9b3d-31682a6542f9	19b551fc-5bfd-409f-b686-9f0a8d812905	2	3	2026-07-09 11:26:00+00	2026-07-09 12:56:00+00	26	0.0000	f
2bf51004-ccbc-4eb0-9209-e86f54a88d82	f0e29d62-7a68-4cb8-9b3d-31682a6542f9	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	3	1	2026-07-10 08:00:00+00	2026-07-10 09:30:00+00	0	0.0000	f
496a37d0-8d91-4204-ba4d-e5506c5d24d0	f0e29d62-7a68-4cb8-9b3d-31682a6542f9	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	4	1	2026-07-11 08:00:00+00	2026-07-11 11:00:00+00	0	0.0000	f
aaf07eaa-14ce-49f2-9d7a-f512400afd6c	f0e29d62-7a68-4cb8-9b3d-31682a6542f9	da619b6e-26d0-4454-b206-da9cb395305b	4	3	2026-07-11 12:52:00+00	2026-07-11 14:52:00+00	0	0.0000	f
01346a94-04c0-4865-aa07-c6b9031d549e	f0e29d62-7a68-4cb8-9b3d-31682a6542f9	5be07ec5-acaa-4992-978f-2a46fba50dd1	4	5	2026-07-11 16:43:00+00	2026-07-11 18:43:00+00	0	0.0000	f
47ae1cb5-0c91-4c10-8c0d-0082f6622ce9	8b26d3d0-6c49-41dd-a37f-673d38b4ef20	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	1	1	2026-07-08 08:00:00+00	2026-07-08 11:00:00+00	0	0.0000	f
ec7347a5-09f8-47e6-b22d-e4589ed37fce	8b26d3d0-6c49-41dd-a37f-673d38b4ef20	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	1	4	2026-07-08 14:36:00+00	2026-07-08 16:06:00+00	26	0.0000	f
de3cdcc1-ae05-48db-9d2a-6f3942a87f3e	8b26d3d0-6c49-41dd-a37f-673d38b4ef20	19b551fc-5bfd-409f-b686-9f0a8d812905	2	1	2026-07-09 08:00:00+00	2026-07-09 09:30:00+00	0	0.0000	f
2da6ff94-82a4-4576-864b-2aca594bfedd	8b26d3d0-6c49-41dd-a37f-673d38b4ef20	0e5a6c48-fb64-44dc-9792-d05391f61a1d	2	4	2026-07-09 12:48:00+00	2026-07-09 15:48:00+00	0	0.0000	f
25a1e22e-0323-40e3-b5a8-e94db12944ce	8b26d3d0-6c49-41dd-a37f-673d38b4ef20	da619b6e-26d0-4454-b206-da9cb395305b	3	2	2026-07-10 09:30:00+00	2026-07-10 11:30:00+00	0	0.0000	f
1315ae7a-00cf-4a96-9da4-4469463f3ff8	8b26d3d0-6c49-41dd-a37f-673d38b4ef20	5be07ec5-acaa-4992-978f-2a46fba50dd1	3	4	2026-07-10 13:21:00+00	2026-07-10 15:21:00+00	0	0.0000	f
b27fc542-9a8f-4311-a7be-c6d0120c5e4e	5ef264a2-ac52-46cc-9cf3-347b87391305	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	1	4	2026-07-08 13:06:00+00	2026-07-08 14:36:00+00	26	0.0000	f
55e279b0-a271-4376-964b-5c5071f6a8b0	5ef264a2-ac52-46cc-9cf3-347b87391305	19b551fc-5bfd-409f-b686-9f0a8d812905	1	5	2026-07-08 14:36:00+00	2026-07-08 16:06:00+00	0	0.0000	f
8d0778b7-079f-4209-b681-f9e96fc774f3	5ef264a2-ac52-46cc-9cf3-347b87391305	0e5a6c48-fb64-44dc-9792-d05391f61a1d	2	3	2026-07-09 11:11:00+00	2026-07-09 14:11:00+00	0	0.0000	f
0e98af8d-f6a4-43f0-8665-958cd7011e0f	5ef264a2-ac52-46cc-9cf3-347b87391305	da619b6e-26d0-4454-b206-da9cb395305b	3	1	2026-07-10 08:00:00+00	2026-07-10 10:00:00+00	0	0.0000	f
550f5655-371d-4baf-8038-202a310507d7	5ef264a2-ac52-46cc-9cf3-347b87391305	5be07ec5-acaa-4992-978f-2a46fba50dd1	3	3	2026-07-10 11:51:00+00	2026-07-10 13:51:00+00	0	0.0000	f
d03109e6-481d-45bf-b851-5fa91cbb2ccb	4516deb4-27f9-4693-b226-0b3e22bd66ad	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	1	1	2026-07-08 08:00:00+00	2026-07-08 11:00:00+00	0	0.0000	f
1b6a1e5f-279c-4491-a900-4f00db46af22	4516deb4-27f9-4693-b226-0b3e22bd66ad	19b551fc-5bfd-409f-b686-9f0a8d812905	1	4	2026-07-08 14:36:00+00	2026-07-08 16:06:00+00	26	0.0000	f
eb001a3a-a7ee-4858-bc0d-20cb57500684	4516deb4-27f9-4693-b226-0b3e22bd66ad	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	1	5	2026-07-08 16:06:00+00	2026-07-08 17:36:00+00	0	0.0000	f
61516ec5-77d6-4916-a7ac-52f0deb05e93	4516deb4-27f9-4693-b226-0b3e22bd66ad	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	1	7	2026-07-08 19:15:00+00	2026-07-08 22:15:00+00	2	0.0000	f
c14de7cb-469a-411c-9442-1331fec7f739	4516deb4-27f9-4693-b226-0b3e22bd66ad	0e5a6c48-fb64-44dc-9792-d05391f61a1d	1	10	2026-07-09 02:56:00+00	2026-07-09 05:56:00+00	0	0.0000	f
bc1ce18f-8f85-4ab4-a335-82687c811915	4516deb4-27f9-4693-b226-0b3e22bd66ad	da619b6e-26d0-4454-b206-da9cb395305b	1	11	2026-07-09 06:08:00+00	2026-07-09 08:08:00+00	12	0.0000	f
f9ad8ebf-891c-47c8-8ea0-6a38409dafe9	4516deb4-27f9-4693-b226-0b3e22bd66ad	5be07ec5-acaa-4992-978f-2a46fba50dd1	1	12	2026-07-09 08:29:00+00	2026-07-09 10:29:00+00	21	0.0000	f
ccb7da72-9594-4e7a-b32a-b56029d81c85	a5b5458d-8ccd-4394-92a1-ae460ea35f73	5be07ec5-acaa-4992-978f-2a46fba50dd1	1	1	2026-07-08 08:00:00+00	2026-07-08 10:00:00+00	0	0.0000	f
ba429975-5c8d-4f86-a294-2eaa34136771	a5b5458d-8ccd-4394-92a1-ae460ea35f73	da619b6e-26d0-4454-b206-da9cb395305b	1	3	2026-07-08 11:51:00+00	2026-07-08 13:51:00+00	21	0.0000	f
cdb34f36-202e-428a-ba40-3caaed4766a6	a5b5458d-8ccd-4394-92a1-ae460ea35f73	0e5a6c48-fb64-44dc-9792-d05391f61a1d	2	2	2026-07-09 09:30:00+00	2026-07-09 12:30:00+00	0	0.0000	f
1a2b6535-2fb7-4477-af53-97900764538d	a5b5458d-8ccd-4394-92a1-ae460ea35f73	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	2	4	2026-07-09 14:18:00+00	2026-07-09 15:48:00+00	7	0.0000	f
cdfd4a68-30cc-496d-ac3d-d779454375d7	a5b5458d-8ccd-4394-92a1-ae460ea35f73	19b551fc-5bfd-409f-b686-9f0a8d812905	3	1	2026-07-10 08:00:00+00	2026-07-10 09:30:00+00	0	0.0000	f
6ffad5cc-0369-4e11-be32-fd9857767267	a5b5458d-8ccd-4394-92a1-ae460ea35f73	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	3	4	2026-07-10 13:06:00+00	2026-07-10 16:06:00+00	10	0.0000	f
27952f77-befc-45b3-88d5-b66f96a4c9d8	28c022ea-6aef-4453-9627-730ed84c3df6	5be07ec5-acaa-4992-978f-2a46fba50dd1	1	1	2026-07-08 08:00:00+00	2026-07-08 10:00:00+00	0	0.0000	f
8c232d45-4d60-423e-bc63-63a5394bf5af	28c022ea-6aef-4453-9627-730ed84c3df6	da619b6e-26d0-4454-b206-da9cb395305b	1	3	2026-07-08 11:51:00+00	2026-07-08 13:51:00+00	21	0.0000	f
82e09d93-9f5d-4c66-89a7-4529171b38c9	28c022ea-6aef-4453-9627-730ed84c3df6	0e5a6c48-fb64-44dc-9792-d05391f61a1d	2	2	2026-07-09 09:30:00+00	2026-07-09 12:30:00+00	0	0.0000	f
b3fc5d3c-40c3-407e-afed-c742be37e81d	28c022ea-6aef-4453-9627-730ed84c3df6	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	2	4	2026-07-09 14:18:00+00	2026-07-09 15:48:00+00	7	0.0000	f
3c2132e2-f1d8-498d-9915-ba9b84941cb5	28c022ea-6aef-4453-9627-730ed84c3df6	19b551fc-5bfd-409f-b686-9f0a8d812905	3	1	2026-07-10 08:00:00+00	2026-07-10 09:30:00+00	0	0.0000	f
563d576d-68c0-4676-af9a-01a576322152	28c022ea-6aef-4453-9627-730ed84c3df6	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	3	4	2026-07-10 13:06:00+00	2026-07-10 16:06:00+00	10	0.0000	f
fccee10e-79e1-41f1-999e-86486cd63054	41c46bb3-1728-4a7c-babe-1165b7531198	5be07ec5-acaa-4992-978f-2a46fba50dd1	1	1	2026-07-08 08:00:00+00	2026-07-08 10:00:00+00	0	0.0000	f
e85e5771-3d0e-4e00-a6ce-670d363aed52	41c46bb3-1728-4a7c-babe-1165b7531198	da619b6e-26d0-4454-b206-da9cb395305b	1	4	2026-07-08 13:21:00+00	2026-07-08 15:21:00+00	0	0.0000	f
d1ef7d4b-ffc4-42a6-8e37-bd17537899b2	41c46bb3-1728-4a7c-babe-1165b7531198	0e5a6c48-fb64-44dc-9792-d05391f61a1d	2	2	2026-07-09 09:30:00+00	2026-07-09 12:30:00+00	0	0.0000	f
ebbf0d30-000a-4215-9a77-f01fe19e9002	41c46bb3-1728-4a7c-babe-1165b7531198	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	2	4	2026-07-09 14:18:00+00	2026-07-09 15:48:00+00	7	0.0000	f
c09100d3-d085-4b03-beb6-f094b5cf18a3	41c46bb3-1728-4a7c-babe-1165b7531198	19b551fc-5bfd-409f-b686-9f0a8d812905	3	1	2026-07-10 08:00:00+00	2026-07-10 09:30:00+00	0	0.0000	f
c00c5d60-b0b1-4b2e-8cb9-655404498d25	41c46bb3-1728-4a7c-babe-1165b7531198	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	3	4	2026-07-10 13:06:00+00	2026-07-10 16:06:00+00	10	0.0000	f
4ef7a658-0910-4123-a4e6-65ae61b3926a	28e3f43f-b110-4405-91bf-eefd25cfc6cc	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	1	2	2026-07-08 09:30:00+00	2026-07-08 12:30:00+00	0	0.0000	f
338336eb-a047-475c-94df-9d8526a8299f	28e3f43f-b110-4405-91bf-eefd25cfc6cc	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	1	3	2026-07-08 13:04:00+00	2026-07-08 14:34:00+00	34	0.0000	f
2e89a0e3-99e4-44f2-98be-881aed3097b1	28e3f43f-b110-4405-91bf-eefd25cfc6cc	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	2	1	2026-07-09 08:00:00+00	2026-07-09 11:00:00+00	0	0.0000	f
4c40f97e-c88c-4098-862f-3692a63f07ab	28e3f43f-b110-4405-91bf-eefd25cfc6cc	0e5a6c48-fb64-44dc-9792-d05391f61a1d	3	1	2026-07-10 08:00:00+00	2026-07-10 11:00:00+00	0	0.0000	f
370bfe0d-e04d-4803-92a8-807015f104e8	28e3f43f-b110-4405-91bf-eefd25cfc6cc	da619b6e-26d0-4454-b206-da9cb395305b	3	3	2026-07-10 12:42:00+00	2026-07-10 14:42:00+00	0	0.0000	f
0a4319b2-5a2d-43f4-a6b5-412dc976eb2f	28e3f43f-b110-4405-91bf-eefd25cfc6cc	5be07ec5-acaa-4992-978f-2a46fba50dd1	4	1	2026-07-11 08:00:00+00	2026-07-11 10:00:00+00	0	0.0000	f
d2efdd2b-b795-4cfa-9a2c-6f108a59d48c	7b7f7e7a-897e-4db2-ab32-fb58328eda4a	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	1	1	2026-07-27 08:00:00+00	2026-07-27 11:00:00+00	2	0.0000	f
fde7806a-717a-48f2-91da-c9e8290e86a3	96ed21ee-3585-483a-a444-e94e97c324a2	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	1	1	2026-07-28 08:00:00+00	2026-07-28 11:00:00+00	0	0.0000	f
4b48899a-79c5-4f9a-b9c5-afba3a36dc32	96ed21ee-3585-483a-a444-e94e97c324a2	19b551fc-5bfd-409f-b686-9f0a8d812905	2	1	2026-07-29 08:00:00+00	2026-07-29 09:30:00+00	0	0.0000	f
8223919e-fd09-43b5-93ea-acfb1d6d7ad1	96ed21ee-3585-483a-a444-e94e97c324a2	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	2	2	2026-07-29 09:30:00+00	2026-07-29 11:00:00+00	0	0.0000	f
7e9df6ca-bb33-4016-a7f6-e8b1ff407e41	96ed21ee-3585-483a-a444-e94e97c324a2	0e5a6c48-fb64-44dc-9792-d05391f61a1d	2	4	2026-07-29 12:48:00+00	2026-07-29 15:48:00+00	0	0.0000	f
a20f2632-9cff-43d1-81ef-fc4dcc6d8a17	96ed21ee-3585-483a-a444-e94e97c324a2	da619b6e-26d0-4454-b206-da9cb395305b	3	2	2026-07-30 09:30:00+00	2026-07-30 11:30:00+00	0	0.0000	f
f4ea74a6-338f-4a0c-8bec-82c07f3b049e	96ed21ee-3585-483a-a444-e94e97c324a2	5be07ec5-acaa-4992-978f-2a46fba50dd1	3	4	2026-07-30 13:21:00+00	2026-07-30 15:21:00+00	0	0.0000	f
5945b9c9-faa1-4ad4-9bf7-e65e11d54668	0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	1	1	2026-07-29 08:00:00+00	2026-07-29 11:00:00+00	0	0.0000	f
94c3abb9-b246-41b2-a35e-7a48e4ea8503	0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	19b551fc-5bfd-409f-b686-9f0a8d812905	1	4	2026-07-29 14:36:00+00	2026-07-29 16:06:00+00	26	0.0000	f
b8ea61cb-3327-44e2-82d5-945bad0e0fb5	0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	2	1	2026-07-30 08:00:00+00	2026-07-30 09:30:00+00	0	0.0000	f
aec7a6b5-a839-4a20-8b4b-61054005060a	0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	2	3	2026-07-30 11:09:00+00	2026-07-30 14:09:00+00	2	0.0000	f
ee3ee2f7-b062-45ce-b716-083890cbc4b3	0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	0e5a6c48-fb64-44dc-9792-d05391f61a1d	3	3	2026-07-31 12:41:00+00	2026-07-31 15:41:00+00	0	0.0000	f
2888ea36-4aba-44d4-94bf-9f8f9f9c3d59	0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	da619b6e-26d0-4454-b206-da9cb395305b	4	1	2026-08-01 08:00:00+00	2026-08-01 10:00:00+00	0	0.0000	f
5131875b-5890-4d41-8762-5db0632584d6	0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	5be07ec5-acaa-4992-978f-2a46fba50dd1	4	2	2026-08-01 10:21:00+00	2026-08-01 12:21:00+00	21	0.0000	f
d6532012-3f0f-4ad7-9d73-206aadad2a3b	68c06ab9-e4bf-4057-82f8-a14dd3c9df87	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	1	1	2026-08-12 08:00:00+00	2026-08-12 11:00:00+00	0	0.0000	f
38f477e8-0161-4ecd-9417-ede0b4d18211	68c06ab9-e4bf-4057-82f8-a14dd3c9df87	19b551fc-5bfd-409f-b686-9f0a8d812905	1	5	2026-08-12 16:12:00+00	2026-08-12 17:42:00+00	31	0.0000	f
a3e5cc58-4d02-46c3-b80b-af400f62c154	68c06ab9-e4bf-4057-82f8-a14dd3c9df87	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	1	6	2026-08-12 17:42:00+00	2026-08-12 19:12:00+00	0	0.0000	f
36bb30ad-db3c-458d-be94-8366f8e17cf1	68c06ab9-e4bf-4057-82f8-a14dd3c9df87	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	1	8	2026-08-12 22:20:00+00	2026-08-13 01:20:00+00	0	0.0000	f
60227770-566f-4874-a1cc-012ac15ef31b	68c06ab9-e4bf-4057-82f8-a14dd3c9df87	da619b6e-26d0-4454-b206-da9cb395305b	1	10	2026-08-13 03:17:00+00	2026-08-13 05:17:00+00	0	0.0000	f
eeca86cf-59fd-4a74-bdd7-4cc20486516a	68c06ab9-e4bf-4057-82f8-a14dd3c9df87	5be07ec5-acaa-4992-978f-2a46fba50dd1	1	11	2026-08-13 05:42:00+00	2026-08-13 07:42:00+00	25	0.0000	f
\.


--
-- Data for Name: location_verifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.location_verifications (id, establishment_id, destination_id, name, address, lat, lng, category, submitted_by, status, reviewed_by, reviewed_at, created_at) FROM stdin;
e8a302bc-e63e-4079-9de0-0917a2e0b75e	6f0faeca-1554-4cd8-9512-8ee452675f94	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	Secdea Beach Resort	Babak, Samal	7.1772	125.68	Resort	8c38e7d2-8eea-4381-b367-00522c66c869	approved	2c0f3ba7-6f1e-4773-873f-ee62a73d03c0	2026-07-06 03:15:43.377607+00	2026-07-07 03:15:43.377607+00
7461f2f7-8c91-456b-a899-1bbe53eb8361	c15f0522-f79f-4640-8375-c9ae439229c4	0e5a6c48-fb64-44dc-9792-d05391f61a1d	Pearl Farm Resort	Kaputian, Samal	7.005	125.7	Resort	eff4f458-767c-413d-8bbd-5056b51a82be	approved	2c0f3ba7-6f1e-4773-873f-ee62a73d03c0	2026-07-05 03:15:43.377607+00	2026-07-07 03:15:43.377607+00
3df6c31e-ac56-448d-9f09-63e7eafc7c74	c2dd097f-cd94-4085-a638-41a9c9605df8	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	Maxima Aquafun	Penaplata, Samal	7.0425	125.72	Resort	eca9f8ee-660c-47de-95d2-4c6244d8e48b	approved	2c0f3ba7-6f1e-4773-873f-ee62a73d03c0	2026-07-04 03:15:43.377607+00	2026-07-07 03:15:43.377607+00
7fb63e76-3bf8-4b5a-904e-9455ce138733	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	5be07ec5-acaa-4992-978f-2a46fba50dd1	Isla Reta Beach	Talikud Island, Samal	6.936	125.65	Beach	ba431694-9708-4bff-bd57-351067958290	approved	2c0f3ba7-6f1e-4773-873f-ee62a73d03c0	2026-07-03 03:15:43.377607+00	2026-07-07 03:15:43.377607+00
\.


--
-- Data for Name: moga_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.moga_results (id, itinerary_id, fitness_score, preference_score, weather_score, budget_penalty, time_penalty, generation_count, execution_time, created_at) FROM stdin;
37de4ca1-a8eb-4375-a364-5330e4a9718a	5ef264a2-ac52-46cc-9cf3-347b87391305	35.0000	21.0000	1.0000	4225.0000	0.0000	120	0.8200	2026-07-07 20:17:07.638443+00
0e6f0962-f35a-4260-bd39-a4f1ea7f159a	4516deb4-27f9-4693-b226-0b3e22bd66ad	30.0000	18.0000	1.0000	2375.0000	1288.5808	120	0.8550	2026-07-07 20:20:11.058499+00
edc3bcb4-923b-469a-9479-0981fca57c9a	a5b5458d-8ccd-4394-92a1-ae460ea35f73	0.0000	0.0000	1.0000	3925.0000	0.0000	120	3.2720	2026-07-07 20:35:05.575407+00
eac44879-2aaf-4695-bff4-4b6541085fc1	28c022ea-6aef-4453-9627-730ed84c3df6	10.0000	6.0000	1.0000	3925.0000	0.0000	120	1.8530	2026-07-08 03:58:43.019934+00
66168bd6-b0f4-4f7b-ab57-87b18b727d13	41c46bb3-1728-4a7c-babe-1165b7531198	0.0000	0.0000	1.0000	3925.0000	0.0000	120	0.8260	2026-07-08 05:36:40.692345+00
d7607495-83fb-4b47-bb09-a8527ff413b8	28e3f43f-b110-4405-91bf-eefd25cfc6cc	55.0000	33.0000	1.0000	4975.0000	0.0000	120	0.9740	2026-07-08 05:48:03.446834+00
ad29f315-cce9-4b1d-834b-7d5c781852f2	7b7f7e7a-897e-4db2-ab32-fb58328eda4a	100.0000	1.0000	1.0000	7300.0000	0.0000	120	0.1000	2026-07-27 08:34:34.625478+00
26f2935f-0b31-4c5d-828b-a52a34c4fcc6	96ed21ee-3585-483a-a444-e94e97c324a2	0.0000	0.0000	1.0000	3925.0000	0.0000	120	1.6130	2026-07-28 03:31:21.712461+00
f068a1d4-f29f-4982-91cc-3f4ba65cbbcb	0d94ce66-9af3-4a53-ad06-2c61e62a1f4a	30.0000	18.0000	1.0000	2375.0000	0.0000	120	1.0180	2026-07-29 05:22:42.104579+00
b1da1e75-04fb-4136-bfa4-a9965f0c3d76	68c06ab9-e4bf-4057-82f8-a14dd3c9df87	27.2727	15.0000	1.0000	2675.0000	1003.8787	120	0.8820	2026-08-12 13:37:17.983994+00
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, recipient_id, title, message, type, is_read, sent_at) FROM stdin;
bfa9c18e-b571-4d9e-a4d4-3626848a6619	fcc94890-59b1-405f-bd41-26ea5dcea322	Incoming Reservation Completed	Juan Dela Cruz completed their reservation at Secdea Beach Resort.	reservation	t	2026-07-07 03:15:43.377607+00
99e3c91f-7d40-4747-901a-61eb483884a0	35200539-cf55-4e9d-96ef-db437de3c93c	Incoming Reservation Completed	Pedro Penduko completed their reservation at Pearl Farm Beach Resort.	reservation	t	2026-07-07 03:15:43.377607+00
5da91227-0e46-4324-a0e8-61ed59ed9702	87105a9d-e58a-410d-adb3-de7b17f47f5f	Incoming Reservation Completed	Maria Clara completed their reservation at Maxima Aquafun.	reservation	t	2026-07-07 03:15:43.377607+00
b1987491-fcf7-49e0-9643-955fceaef6cd	9922b42a-62ed-4881-85f7-fb59c91ed68e	Incoming Reservation Completed	Crisostomo Ibarra completed their reservation at Isla Reta Beach Resort.	reservation	t	2026-07-07 03:15:43.377607+00
5da91227-0e46-4324-a0e8-61ed59ed9703	451e16ae-adc0-4737-a763-799764db82f9	Incoming Reservation Pending	Pedro Penduko submitted a reservation request for Grand Horizon Pool & Spa.	reservation	f	2026-07-07 17:19:12.264226+00
5da91227-0e46-4324-a0e8-61ed59ed9704	451e16ae-adc0-4737-a763-799764db82f9	Pending GCash Payment	Pedro Penduko sent ₱3,000.00 payment via GCash. Verification required.	booking	f	2026-07-07 17:24:12.264226+00
5da91227-0e46-4324-a0e8-61ed59ed9705	451e16ae-adc0-4737-a763-799764db82f9	Verified by Tourism Admin	Grand Hotel Samal has been verified by the Tourism Administrator!	welcome	f	2026-07-07 17:09:12.264226+00
\.


--
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reservations (id, itinerary_id, tourist_id, establishment_id, destination_id, eta, pax_count, reservation_status, service_name, created_at) FROM stdin;
a075c9f5-e3ae-4a4b-b5d0-7978d3d65752	b9a08070-be86-4cbd-9007-065222d11296	8c38e7d2-8eea-4381-b367-00522c66c869	6f0faeca-1554-4cd8-9512-8ee452675f94	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	2026-07-06 03:15:43.377607+00	2	completed	Daytour Entry	2026-07-07 03:15:43.377607+00
afede794-798c-4f55-abd0-99b308af52b3	1de844e8-dd09-46a8-8753-a140a2e7eb16	eff4f458-767c-413d-8bbd-5056b51a82be	c15f0522-f79f-4640-8375-c9ae439229c4	0e5a6c48-fb64-44dc-9792-d05391f61a1d	2026-07-05 03:15:43.377607+00	4	completed	Mandaya Spa package	2026-07-07 03:15:43.377607+00
3992bfc8-691a-4498-b21c-6f3ea3b395e8	13ef266c-f3a9-49c6-8728-0b2c69199ad8	eca9f8ee-660c-47de-95d2-4c6244d8e48b	c2dd097f-cd94-4085-a638-41a9c9605df8	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	2026-07-04 03:15:43.377607+00	1	completed	Giant slide and swimming	2026-07-07 03:15:43.377607+00
ceb6e50d-81c9-4a6d-aae5-3cfb9fec9545	33379cd3-872d-4903-b427-79faa1669c2a	ba431694-9708-4bff-bd57-351067958290	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	5be07ec5-acaa-4992-978f-2a46fba50dd1	2026-07-03 03:15:43.377607+00	3	completed	Cottage Overnight	2026-07-07 03:15:43.377607+00
e53d84fa-3088-4c81-9b85-e123fb9f7cad	\N	60dc06ee-c954-4fea-9058-bd595e4b2d84	5a5c83d3-3a56-4997-957e-bb04b992ccbc	\N	2026-07-07 12:00:00+00	3	confirmed	Grand Presidential Suite	2026-07-07 17:29:12.264226+00
f0aff171-1855-4800-a907-20839874ea12	\N	ba431694-9708-4bff-bd57-351067958290	5a5c83d3-3a56-4997-957e-bb04b992ccbc	\N	2026-07-12 00:00:00+00	5	confirmed	Grand Presidential Suite	2026-07-07 17:29:12.264226+00
f0aff171-1855-4800-a907-20839874ea11	\N	eff4f458-767c-413d-8bbd-5056b51a82be	5a5c83d3-3a56-4997-957e-bb04b992ccbc	\N	2026-07-08 12:00:00+00	2	pending	Grand Horizon Pool & Spa	2026-07-07 17:29:12.264226+00
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payments (id, reservation_id, tourist_id, establishment_id, amount, payment_method, paymongo_reference, status, paid_at, created_at) FROM stdin;
8fccb3db-99ef-4ec3-89eb-8f23f9730558	a075c9f5-e3ae-4a4b-b5d0-7978d3d65752	8c38e7d2-8eea-4381-b367-00522c66c869	6f0faeca-1554-4cd8-9512-8ee452675f94	1000.00	gcash	\N	paid	2026-07-06 02:15:43.377607+00	2026-07-07 03:15:43.377607+00
169fe64d-a5a5-4638-85f5-757fb2b9d684	afede794-798c-4f55-abd0-99b308af52b3	eff4f458-767c-413d-8bbd-5056b51a82be	c15f0522-f79f-4640-8375-c9ae439229c4	10000.00	gcash	\N	paid	2026-07-05 02:15:43.377607+00	2026-07-07 03:15:43.377607+00
7c430c4e-280e-49e4-9f5f-980465197c86	3992bfc8-691a-4498-b21c-6f3ea3b395e8	eca9f8ee-660c-47de-95d2-4c6244d8e48b	c2dd097f-cd94-4085-a638-41a9c9605df8	300.00	gcash	\N	paid	2026-07-04 02:15:43.377607+00	2026-07-07 03:15:43.377607+00
d5559ea9-6c8f-4048-b612-eb0a1c3646ad	ceb6e50d-81c9-4a6d-aae5-3cfb9fec9545	ba431694-9708-4bff-bd57-351067958290	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	3600.00	gcash	\N	paid	2026-07-03 02:15:43.377607+00	2026-07-07 03:15:43.377607+00
d1f9d877-ab0d-4e48-bff2-df8780a78a4d	f0aff171-1855-4800-a907-20839874ea11	eff4f458-767c-413d-8bbd-5056b51a82be	5a5c83d3-3a56-4997-957e-bb04b992ccbc	3000.00	gcash	\N	pending	\N	2026-07-07 17:29:12.264226+00
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reviews (id, tourist_id, destination_id, establishment_id, stars, review_text, created_at, helpful_yes, helpful_no) FROM stdin;
dd47e8c4-c115-4bb2-932b-78d17ddbced3	8c38e7d2-8eea-4381-b367-00522c66c869	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	6f0faeca-1554-4cd8-9512-8ee452675f94	5	Secdea is wonderful! Clean swimming pools and stunning seaside views.	2026-07-07 03:15:43.377607+00	0	0
e60522ca-081b-4815-8955-cd8b66c2931c	eff4f458-767c-413d-8bbd-5056b51a82be	0e5a6c48-fb64-44dc-9792-d05391f61a1d	c15f0522-f79f-4640-8375-c9ae439229c4	5	Stunning traditional huts and top-tier customer service! Mandaya Spa was exceptionally relaxing.	2026-07-07 03:15:43.377607+00	0	0
4fe029f8-2fab-4201-8d8f-797c0575e664	eca9f8ee-660c-47de-95d2-4c6244d8e48b	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	c2dd097f-cd94-4085-a638-41a9c9605df8	4	Terrific giant slide, kids loved the experience. Quite deep water though!	2026-07-07 03:15:43.377607+00	0	0
40f5dcda-412c-4d39-9516-8e6a9acaee3f	eca9f8ee-660c-47de-95d2-4c6244d8e48b	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	ca489969-3b12-49d9-b21d-00ab5f0b76c1	5	Cold, clear water straight from the mountain. Bring water shoes, the rocks are slippery.	2026-07-02 11:27:48.072042+00	19	1
a55ed8cd-e808-4e36-a6a6-38a48a8bcd36	ba431694-9708-4bff-bd57-351067958290	2ca37f5c-88d9-4d08-b3ee-1fb227573f93	ca489969-3b12-49d9-b21d-00ab5f0b76c1	3	Beautiful spot but the trail down is quite steep. Not ideal for elders.	2026-06-28 11:27:48.072042+00	6	3
fe842f96-7270-4d79-91fe-bb5b83f93513	eff4f458-767c-413d-8bbd-5056b51a82be	19b551fc-5bfd-409f-b686-9f0a8d812905	ca489969-3b12-49d9-b21d-00ab5f0b76c1	4	Peaceful campsite, good for a weekend getaway. Bring your own tent though.	2026-06-17 11:27:48.072042+00	8	0
0f32eebb-8a2e-47c3-9da0-c01ee0930691	1302c0c5-9ea3-4435-8a27-755d9f1abb72	da619b6e-26d0-4454-b206-da9cb395305b	17f649a7-88f9-402d-a8e4-9aec049d5cb0	5	Long stretch of white sand, barely crowded even on a Saturday. One of the best in Samal.	2026-07-01 11:27:48.072042+00	27	2
fe384093-0031-4063-8d4e-c7299caafd51	33c14c05-97d9-475b-b23d-25951125f072	da619b6e-26d0-4454-b206-da9cb395305b	17f649a7-88f9-402d-a8e4-9aec049d5cb0	4	Affordable entrance fee, clean restrooms. Bring your own umbrella since shade is limited.	2026-06-20 11:27:48.072042+00	9	1
1168955c-373b-4b01-bd5f-da6f3b909c5f	33c14c05-97d9-475b-b23d-25951125f072	0c1d4136-b2cf-46e1-ad60-32fa15f3397a	6f0faeca-1554-4cd8-9512-8ee452675f94	4	Good value for the entrance fee. Pools were well maintained during our visit.	2026-06-18 11:27:48.072042+00	7	1
caca2e87-9e8c-488c-a761-86e07a55c569	60dc06ee-c954-4fea-9058-bd595e4b2d84	0e5a6c48-fb64-44dc-9792-d05391f61a1d	c15f0522-f79f-4640-8375-c9ae439229c4	5	The traditional huts on stilts over the water are stunning. Great for photos.	2026-06-16 11:27:48.072042+00	16	0
2df84721-49fb-46ca-9f05-6c54848a2f63	eca9f8ee-660c-47de-95d2-4c6244d8e48b	e58ee445-65f0-4521-a4f9-24fc8f7cb4fe	c2dd097f-cd94-4085-a638-41a9c9605df8	4	Fun slides for the whole family, though the queue moves slowly on weekends.	2026-06-27 11:27:48.072042+00	12	1
bd9ae53b-7d40-4085-831f-8030d7ec2ff9	eff4f458-767c-413d-8bbd-5056b51a82be	5be07ec5-acaa-4992-978f-2a46fba50dd1	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	5	Talikud Island trip is worth the boat ride. Water is crystal clear here.	2026-06-30 11:27:48.072042+00	20	0
b42bc6cc-afb3-4bc8-9549-fceb24a9ef4f	ba431694-9708-4bff-bd57-351067958290	5be07ec5-acaa-4992-978f-2a46fba50dd1	b062ffca-7bc9-4d91-b5ef-4d54bb6590dc	5	Super fine white sand. Sleep under the talisay trees is pure peace.	2026-07-07 03:15:43.377607+00	8	0
3bb993b1-75c9-4754-9ee2-55fcb4712355	1302c0c5-9ea3-4435-8a27-755d9f1abb72	5be07ec5-acaa-4992-978f-2a46fba50dd1	\N	3	Nice but not clean inside.	2026-07-07 13:33:36.837076+00	3	2
\.


--
-- Data for Name: reviews_legacy; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reviews_legacy (id, place_name, author_name, rating, comment, helpful_yes, helpful_no, date_string, created_at) FROM stdin;
\.


--
-- Data for Name: role_descriptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role_descriptions (role_key, display_name, description, updated_at) FROM stdin;
tourist	Tourist	End-users who browse destinations, create itineraries, and leave reviews.	2026-07-06 14:29:50.677266+00
administrator	Administrator	LGU tourism officers who verify establishments, moderate content, and oversee platform operations.	2026-07-06 14:29:50.677266+00
super_admin	Super Admin	System-level administrators with full access to all settings, users, roles, and audit logs.	2026-07-06 14:29:50.677266+00
owner	Owner	Resort and business owners who manage their listings, respond to reviews, and view analytics.	2026-07-06 14:29:50.677266+00
\.


--
-- Data for Name: self_healing_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.self_healing_logs (id, itinerary_id, trigger_type, adjusted_minutes, delay_severity_score, weather_risk_score, contribution_score, replacement_destination_id, old_destination_id, created_at) FROM stdin;
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_settings (key, value, updated_by, updated_at) FROM stdin;
maintenance_mode	{"enabled": false}	\N	2026-07-05 04:52:40.782874+00
\.


--
-- Data for Name: tourist_details; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tourist_details (id, user_id, budget_min, budget_max, available_hours_per_day, trip_duration_days, preferred_categories, current_lat, current_lng, travel_mode, created_at, number_of_tourists, children_count, elders_count) FROM stdin;
2fd1b8f2-b319-4022-b105-dfbf1fd62be2	8c38e7d2-8eea-4381-b367-00522c66c869	500.00	2000.00	9	1	{}	\N	\N	driving	2026-07-07 03:15:43.377607+00	2	0	0
b8ef073f-3299-48e5-a671-3f5034f2b3c7	eff4f458-767c-413d-8bbd-5056b51a82be	2000.00	15000.00	9	1	{}	\N	\N	driving	2026-07-07 03:15:43.377607+00	6	1	1
945d6d69-0137-4a22-8045-38923566f70e	eca9f8ee-660c-47de-95d2-4c6244d8e48b	100.00	1000.00	9	1	{}	\N	\N	walking	2026-07-07 03:15:43.377607+00	1	0	0
f330bdfe-c18d-4593-95ee-c702cc3e7b43	ba431694-9708-4bff-bd57-351067958290	1000.00	5000.00	9	1	{}	\N	\N	transit	2026-07-07 03:15:43.377607+00	5	2	0
0e1f1999-3004-490e-98cf-89e6e3a2ea81	60dc06ee-c954-4fea-9058-bd595e4b2d84	1500.00	8000.00	9	1	{}	\N	\N	driving	2026-07-07 03:15:43.377607+00	3	1	0
4b86b99e-e51c-4f59-a419-48e82dff38f8	33c14c05-97d9-475b-b23d-25951125f072	3000.00	20000.00	9	1	{}	\N	\N	driving	2026-07-07 03:15:43.377607+00	7	0	2
4cbc8950-5192-4765-b0ce-f5746d7ee654	1302c0c5-9ea3-4435-8a27-755d9f1abb72	1000.00	1000.00	7	1	{Beach,Resort}	7.085	125.73	transit	2026-07-07 20:14:07.139866+00	4	4	0
\.


--
-- Data for Name: tourist_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tourist_profiles (id, user_id, budget_min, budget_max, available_hours_per_day, trip_duration_days, preferred_categories, current_lat, current_lng, travel_mode, created_at) FROM stdin;
\.


--
-- Data for Name: weather_cache; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.weather_cache (id, destination_id, condition, multiplier, temperature, humidity, updated_at) FROM stdin;
\.


--
-- PostgreSQL database dump complete
--

\unrestrict iXOJ5geySee9ySRbTJpfdW6g9okOyXu0R2SBMLEr8n8QTpC3g2mY7KwucEFhAFw

