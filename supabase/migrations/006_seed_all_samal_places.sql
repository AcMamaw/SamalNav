-- ═══════════════════════════════════════════════════════════════════
-- SamalNav Comprehensive Seed: All Samal Island Destinations
-- Covers Babak, Peñaplata, Kaputian, and Talikud Island
-- ═══════════════════════════════════════════════════════════════════

INSERT INTO destinations (
  name, location, lat, lng, category, description, rating_average,
  entrance_fee, average_stay_minutes, status, is_active, is_verified, image_url
)
VALUES
  -- ── BEACHES ──────────────────────────────────────────────────────
  (
    'Kaputian Beach', 'South Samal', 6.9736, 125.7265, 'Beach',
    'A long stretch of fine white sand with calm, shallow waters perfect for families and swimming.',
    4.9, 100, 90, 'active', true, true,
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Isla Reta Beach', 'Talikud Island, Samal', 6.9385, 125.7115, 'Beach',
    'Crystal-clear waters and powdery white sand surrounded by lush coconut trees and coral beds on Talikud Island.',
    4.8, 150, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Canibad Beach', 'Babak District, Samal', 7.1353, 125.7925, 'Beach',
    'Hidden cove with turquoise water, great for cliff diving, snorkeling, and camping.',
    4.6, 80, 90, 'active', true, true,
    'https://images.unsplash.com/photo-1439066615861-d1af74d74000?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Paradise Island', 'Peñaplata, Samal', 7.1147, 125.6585, 'Beach',
    'Popular resort beach with water sports, swimming pools, beachfront cottages, and aviaries.',
    4.7, 250, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Vanishing Island', 'Babak District, Samal', 7.1290, 125.6480, 'Beach',
    'A sandbar that appears only during low tide in the middle of the Samal Strait.',
    4.7, 300, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1473116763269-255448993f66?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Babu Santa Beach', 'Babak District, Samal', 7.1050, 125.7780, 'Beach',
    'A quiet and scenic stretch of sand with calm waves, ideal for day picnics and relaxation.',
    4.4, 50, 90, 'active', true, true,
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80'
  ),

  -- ── RESORTS ──────────────────────────────────────────────────────
  (
    'Pearl Farm Resort', 'Kaputian, Samal', 7.0080, 125.7170, 'Resort',
    'Luxury island resort built over clear waters with iconic Mandaya-inspired stilt houses.',
    4.9, 250, 180, 'active', true, true,
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Secdea Beach Resort', 'Babak, Samal', 7.1690, 125.7580, 'Resort',
    'Upscale beach resort featuring infinity pools, mangrove boardwalks, and cozy seaside villas.',
    4.8, 200, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Maxima Aquafun', 'Peñaplata, Samal', 7.0425, 125.7035, 'Resort',
    'Famous adventure resort with giant water slides that plunge directly into the deep sea.',
    4.6, 350, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Bali-Bali View Deck', 'Peñaplata, Samal', 7.0125, 125.7130, 'Resort',
    'Serene seaside resort with Asian-inspired architecture and an elevated ocean view deck.',
    4.5, 30, 90, 'active', true, true,
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Cavanico Bella Beach Resort', 'Babak, Samal', 7.1290, 125.7830, 'Resort',
    'Modern resort destination with wide sandy beach, sunset view dining, and pool facilities.',
    4.5, 200, 150, 'active', true, true,
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Club Samal Resort', 'Peñaplata, Samal', 7.0985, 125.6720, 'Resort',
    'Modern resort featuring a lagoon pool, ballroom facilities, and beachfront lounge.',
    4.3, 150, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Chema''s by the Sea', 'Peñaplata, Samal', 7.0875, 125.6790, 'Resort',
    'Boutique cottage resort nestled in nature with lush gardens and Mediterranean-style dining.',
    4.4, 100, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Hof Gorei Beach Resort', 'Babak, Samal', 7.1520, 125.6680, 'Resort',
    'Exclusive boutique resort offering personalized Butler service and hilltop bungalows.',
    4.6, 250, 150, 'active', true, true,
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Punta del Sol Beach Resort', 'Babak, Samal', 7.0810, 125.6750, 'Resort',
    'Budget-friendly coastal resort perfect for company outings and family gatherings.',
    4.3, 150, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Costa Marina Beach Resort', 'Babak, Samal', 7.1160, 125.6590, 'Resort',
    'Sister resort of Paradise Island offering breezy shorelines and delicious local dishes.',
    4.4, 200, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Camp Holiday Resort', 'Babak, Samal', 7.1275, 125.6655, 'Resort',
    'Convenient resort located right beside the Babak ferry terminal with camping grounds and pools.',
    4.2, 200, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Blue Waters Samal Resort', 'Peñaplata, Samal', 7.0780, 125.6830, 'Resort',
    'Charming seaside resort with quiet ambiance, blue waters, and affordable day tour packages.',
    4.3, 100, 90, 'active', true, true,
    'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Precious Garden of Samal', 'Peñaplata, Samal', 7.1350, 125.6780, 'Resort',
    'Cozy European-inspired garden resort featuring authentic international cuisine.',
    4.1, 120, 90, 'active', true, true,
    'https://images.unsplash.com/photo-1538964173425-93884d739596?auto=format&fit=crop&w=600&q=80'
  ),

  -- ── WATERFALLS ───────────────────────────────────────────────────
  (
    'Hagimit Falls', 'Peñaplata, Samal', 7.0620, 125.7085, 'Falls',
    'Cascading multi-tiered natural waterfall with crystal-clear turquoise pools shaded by trees.',
    4.7, 50, 90, 'active', true, true,
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Tagbaobo Falls', 'Tagbaobo, Samal', 7.0054, 125.7750, 'Falls',
    'Scenic waterfall tucked inside lush rainforest, surrounded by native flora and hiking paths.',
    4.5, 30, 90, 'active', true, true,
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=600&q=80'
  ),

  -- ── MOUNTAIN & NATURE ────────────────────────────────────────────
  (
    'Mt. Puting Bato', 'Bali-Bali, Samal', 7.0656, 125.7580, 'Mountain',
    'Highest peak in Samal Island (1,755 ft) offering 360-degree panoramic views of Davao Gulf.',
    4.6, 0, 150, 'active', true, true,
    'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Samal Zipline', 'Peñaplata, Samal', 7.0450, 125.7050, 'Forest',
    'Thrilling adventure zipline soaring through dense tropical forest canopies.',
    4.4, 300, 60, 'active', true, true,
    'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=600&q=80'
  ),

  -- ── ISLANDS & MARINE ─────────────────────────────────────────────
  (
    'Talikud Island', 'Kaputian District, Samal', 6.9250, 125.6950, 'Island',
    'Picturesque sister island south of Samal famous for untouched reefs, caves, and dive spots.',
    4.8, 200, 180, 'active', true, true,
    'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Coral Garden', 'Talikud Island, Samal', 6.9150, 125.6850, 'Island',
    'Protected marine sanctuary teeming with colorful corals, giant clams, and tropical fish.',
    4.7, 500, 120, 'active', true, true,
    'https://images.unsplash.com/photo-1546026423-cc4642628d2b?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Malipano Island', 'Kaputian, Samal', 7.0020, 125.7150, 'Island',
    'Exclusive private island featuring pristine shores, tropical gardens, and luxury villas.',
    4.6, 0, 180, 'active', true, true,
    'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=600&q=80'
  ),

  -- ── CAVES & HISTORICAL ───────────────────────────────────────────
  (
    'Monfort Bat Sanctuary', 'Babak, Samal', 7.1650, 125.6880, 'Historical',
    'Guinness World Record holder for the largest colony of Geoffroy''s Rousette fruit bats.',
    4.5, 100, 60, 'active', true, true,
    'https://images.unsplash.com/photo-1507163546605-a84d8ff1a3bb?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Ligid Island Cave', 'Peñaplata, Samal', 7.1850, 125.7550, 'Historical',
    'Mysterious coastal cave and dive site featuring deep caverns and underwater rock formations.',
    4.4, 100, 60, 'active', true, true,
    'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57?auto=format&fit=crop&w=600&q=80'
  ),

  -- ── HOTELS ───────────────────────────────────────────────────────
  (
    'Samal Island Huts', 'Peñaplata, Samal', 7.0850, 125.6890, 'Hotel',
    'Eco-friendly bamboo huts near the coast with serene ambiance and hospitable island service.',
    4.2, 0, 60, 'active', true, true,
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80'
  ),
  (
    'Leticia by the Sea', 'Babak, Samal', 6.9410, 125.7180, 'Hotel',
    'Tranquil coastal retreat with beachfront villas, seaside infinity pool, and sea view patio.',
    4.3, 0, 60, 'active', true, true,
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80'
  )
ON CONFLICT DO NOTHING;
