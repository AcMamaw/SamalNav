# Task 38B — Complete Manuscript System Feature Analysis

**Project:** SAMAL NAV
**Task:** Read-only manuscript analysis
**Implementation authorization:** Not granted
**Source of truth for this report:** the repository manuscript identified below. Repository summaries are secondary evidence only.

## 1. Manuscript identity, completeness, and inspection method

The only SAMAL NAV academic manuscript DOCX found by repository-wide filename search is [`SAMAL NAV  (1).docx`](../manuscript/SAMAL%20NAV%20%20%281%29.docx). It is a Microsoft Word Open XML document. Its core properties show revision `2`, created `2026-11-17T20:54:00Z`, modified `2026-11-17T20:56:00Z`; they do not provide a manuscript version number, author/title metadata, or a version history. The filename and metadata therefore identify the available copy, but do not prove it is the latest externally approved revision. No competing manuscript DOCX/PDF was found in the repository. Several later Task 38/39 technical documents are not manuscript versions and were not merged into the extraction.

The complete document body was extracted and reviewed, including tables, captions, equations/Office Math, references, data dictionary, appendices, and embedded media. There are 31 embedded media files, 34 drawing references, and 138 Office Math nodes. Embedded diagrams were viewed as images, including the CARS pipeline, circuit integration, MO-GA decision/operation figures, self-healing flows, conceptual model, ERD, architecture, and prototype screens. The document has seven section properties; Word's layout pagination is not preserved by text extraction, so this report cites section, table, equation, and figure numbers rather than asserting page numbers. The body contains sections titled `INTRODUCTION`, `METHODS`, and `3. REFERENCES`; it does not label itself as a standard three-chapter thesis. It also contains Appendices A–D.

The manuscript's objective numbering is 1.3.2.1–1.3.2.9. The design material is chiefly under 2.3.2.1. The numbered tables run from Table 1 through Table 51; figures and appendices contain reused/inconsistent figure numbering. A figure image says “Figure X” even though the surrounding caption is Figure 5. These numbering anomalies are preserved below, not silently corrected.

## 2. System purpose, users, objectives, and scope

### 2.1 Purpose and users

Section 1.2 describes a Flutter Progressive Web Application for Samal Island that combines destination/activity recommendation, itinerary creation and optimization, route guidance, recorded availability checking, tourism information, feedback, and role-specific administration. The four named user roles are tourists, private establishment owners, Tourism Office administrators, and Super Administrators. Establishments submit documents, undergo Tourism Office accreditation, and have accounts provisioned by a Super Administrator before they can manage/publish establishment information. Section 1.2 says tourists can browse, receive recommendations, customize plans, view recorded availability, and post reviews after a trip.

Sections 1.3.1 and 1.3.2.1–1.3.2.9 state the general objective and nine specific objectives:

| Objective | Explicit objective |
|---|---|
| 1.3.2.1 | CARS recommends destinations/activities on six weighted criteria: interest/activity match, public destination rating, weather suitability, budget compatibility, travel distance suitability, available travel time compatibility. |
| 1.3.2.2 | Present Tourism Office circuits and allow tourists to select/combine destinations from different circuits. |
| 1.3.2.3 | MO-GA optimizes one-day and multi-day plans from Manual Selection, Circuit-Based, and System-Generated destination sets using applicable recommendation scores, distance, estimated time, budget, and available itinerary time. |
| 1.3.2.4 | Integrate OpenStreetMap road-network data and OSRM for routes, road distances, and estimated travel times. |
| 1.3.2.5 | Integrate OpenWeatherMap and a dynamic self-healing re-optimization module for supported weather, unavailability, and tourist-reported delay disruptions; show proposed adjusted itineraries for tourist review/confirmation. |
| 1.3.2.6 | Check accommodation/activity availability and recommend alternatives using recorded/updated availability, price, similarity, distance, accessibility, and itinerary compatibility. |
| 1.3.2.7 | Provide a Tourism Management Module for authorized destination, circuit, establishment, price, availability, feedback, and content administration. |
| 1.3.2.8 | Provide limited Hive offline access to previously synchronized destination information and itineraries. |
| 1.3.2.9 | Use device geolocation, subject to permission and device capability, for location-related features. |

### 2.2 Scope and explicit limitations

Section 1.4 describes a Flutter PWA and management portal with CARS, MO-GA, OSM/OSRM route guidance, geolocation, dynamic re-optimization, and Hive/Supabase offline/cloud functions. Its limitations include: no reservations, online payments, airline/ferry bookings, vehicle hire, or external accommodation-system integration; establishment-entered availability may be stale; only database destinations/partners can be recommended; recommendation quality depends on recorded/verified data, ratings, weather, and routing; six CARS criteria do not cover all medical/travel restrictions; group suitability relies on entered preferences/accessibility data; geolocation requires permission and does not provide arrival detection/geofencing; weather, routing, availability updates, and cloud sync require internet; offline access is limited to previously synchronized information.

This limitation section conflicts with several other manuscript passages: the data dictionary includes reservations, payments, bookings, and reservation status; requirements list reservation management as a user need; Figure 4 depicts location monitoring/arrival detection and automatic re-optimization; the prototype captions mention arrival notifications, bookings, and payments. These are manuscript conflicts, not permission to add those capabilities.

### 2.3 Research, development method, and resource context

Section 2.1 describes an interview with the IGaCOS Tourism Office on 10 March 2026 and online survey data from prospective/current visitors and other demographic groups. Section 2.2.1 cites survey findings (53 respondents), including difficulties comparing destinations (42%), deciding where to start (30%), calculating expenses (42%), travel time (20%), reported transport/navigation issues (22%), bad-weather problems (34%), reservation issues (14%), and itinerary assembly (12%). Section 2.1 also proposes permitted public-web collection of destination rating/review counts using Python Requests and Beautiful Soup; it does not establish a production rating feed or refresh SLA.

Section 2.2.4.3 assesses operational, technical, economic, and schedule feasibility. Table 4 estimates a total project cost of ₱12,880: ₱3,000 internet/data, ₱2,000 documentation/printing, ₱650 dataset acquisition, ₱4,230 land transport/ferry/environmental fees for data gathering, and ₱3,000 domain/hosting allowance. Table 2 lists development computer, Android/iOS devices, GPS-enabled phone, and minimum 10 Mbps internet. Table 3 lists Flutter/Dart, Supabase, Hive, OSRM, OSM, OpenWeatherMap, Device Geolocation API, Git, Python, Requests, Beautiful Soup. Figure 1 and Section 2.2.4 describe six Agile stages: requirements analysis, system design, development, testing, deployment, review/iteration. The proposed 2026 schedule is Figure 2 with three development/testing sprints. These are proposed study requirements/resources, not evidence that deployment or all integrations have occurred.

## 3. Complete feature inventory and traceability

The following matrix maps manuscript features to objective and requirement/design references. Where no objective number exists, the relevant functional-requirement number is listed. “Inputs” and “logic” describe what the manuscript actually says; a blank/unspecified algorithm is called out rather than supplied by this report.

| ID | Manuscript feature | Objective reference | Chapter/section | Required inputs | Manuscript processing logic | Expected output | Dependencies |
|---|---|---|---|---|---|---|---|
| F01 | Accounts, authentication, role authorization | General objective; FR 2.2.4.1.1 | 1.2; 2.2.4.1.1; 2.2.4.1.16; 2.3.6 | Credentials, profile, assigned role, submitted establishment documents | Authenticate; enforce role-specific permissions; establishment document review/accreditation and Super Admin account provisioning | Tourist/owner/admin access within role; verified owners may manage approved establishment information | Supabase Auth/backend, profiles/roles, accreditation records, admin portal |
| F02 | Tourist profile and preference management | 1.3.2.1; FR 2.2.4.1.2 | 1.2; 2.2.1; 2.2.4.1.2; 2.3.2.1.1 | Interests/activities, budget, time, distance, trip dates, group facts/accessibility preferences | Store profile data and use it as recommendation inputs and suitability/eligibility filters | Personalized recommendation inputs/profile | Tourist profile store, destination/activity attributes |
| F03 | Destination information discovery | 1.3.2.1; FR 2.2.4.1.3 | 2.2.4.1.3; 2.3.2.1.1; 2.3.7; data dictionary Table 40 | Search/category, destination ID/name/location, activity, accessibility, rating, price | Browse/search/view recorded/accredited tourism records | Destination details and activities | Destination, category, gallery, activity and establishment records |
| F04 | CARS recommendation and ranking | 1.3.2.1; FR 2.2.4.1.4 | 2.3.2.1.1.1–1.1.6; Tables 5–13; Equations 1–2; Figure 5 | Tourist profile/interests, group, budget/time/distance/date/location; destination activities, public rating, weather, route distance/time, availability | Eligibility/suitability filtering, normalize six criterion scores, apply survey-derived weights, rank descending, tourist reviews/adds/removes | Ranked candidate destinations with activities for MO-GA | Verified destination data, rating source, weather, routing, prices, group suitability |
| F05 | Tourism circuits | 1.3.2.2; FR 2.2.4.1.5 | 2.3.2.1.2; Figure 6 | Tourism Office circuit records, associated destination records, tourist preferences/budget/time | Browse circuits; select/combine across circuits; no required sequence; CARS evaluates selected destinations; tourist can retain/add/remove | Approved combined destination set to MO-GA | Tourism Office data and administration, destination records, CARS, routing |
| F06 | Manual selection and itinerary customization | 1.3.2.3; FR 2.2.4.1.6 | 1.2; 2.2.1.7–1.8; 2.3.2.1.3 | Tourist-selected destinations/activities, trip length, budget/time, start point | Tourist adds/removes/arranges; reviews/approves destination set; MO-GA orders/schedules | Customized one-day or multi-day itinerary | Destination records, trip constraints, MO-GA, route data |
| F07 | MO-GA sequence/schedule optimization | 1.3.2.3; FR 2.2.4.1.7 | 2.3.2.1.3.1–1.3.3; 2.3.2.1.2.4–1.2.7; Tables 14–23; Equations 3–9; Figures 7–12 | Approved destination genes, activities/stay times, start point, per-day time, budget/costs, optional CARS scores, route segments | Permutation population; tournament selection; permutation-preserving crossover; swap mutation; fitness/constraint evaluation; stopping by max generations or stagnation | Highest-fitness feasible sequence for tourist review/edit | Candidate set, OSRM routes, costs, day assignment/time, suitability, CARS if generated |
| F08 | Route calculation/guidance | 1.3.2.4; FR 2.2.4.1.8 | 2.3.2.1.1.4; 2.3.2.1.2.1/3; 2.2.1.9; Figures 4, 16/17, 27 | Origin and destination coordinates, OSM road network, requested route | OSRM calculates road-network path/distance/estimated time; add successive segment values; device position only with permission | Directions, road distance, travel-time estimate, route map | OSM and OSRM service, valid coordinates, connectivity |
| F09 | Weather information and suitability | 1.3.2.1 and 1.3.2.5; FR 2.2.4.1.9 | 2.3.2.1.1.2; 2.3.2.1.4.2; Tables 27–31; Figure 5 | Current/forecast weather by trip/destination/time; destination exposure and activity sensitivity | Map conditions to severity weights; compute WRS/exposure and activity impact; apply thresholds; reassess/postpone/replace/re-optimize | Weather information, criterion score or proposed activity/itinerary changes | OpenWeatherMap current/hourly forecast, destination/activity classification, trip timing |
| F10 | Dynamic self-healing | 1.3.2.5; FR 2.2.4.1.10 | 2.3.2.1.4.1–1.4.5; Equations 10–13 and weather decision rule; Tables 24–34; Figures 13–14 | Delay report, weather forecast, unavailable destination/activity, remaining itinerary/progress, candidate alternatives | Calculate DS/WRS; assess weather-sensitive activities; compute alternative score; choose ETA-only, schedule compression, alternatives, or MO-GA; tourist accepts/declines | Proposed revised remainder; preserve visited destinations; accepted changes apply, decline retains old itinerary | Delay inputs, forecast, availability data, AS inputs, route/time data, MO-GA, review confirmation |
| F11 | Accommodation/activity availability and alternatives | 1.3.2.6; FR 2.2.4.1.11–1.12 | 1.2; 2.2.1.12; 2.2.4.1.11–1.12; data Tables 38, 41–42 | Travel date/time, party size, selected service, establishment-entered price and availability, attributes/location/accessibility | Display recorded/currently updated availability; if recorded unavailable, filter alternatives and compare price, similarity, distance, accessibility, itinerary compatibility; “Find Similar” replaces only unavailable room/activity | Alternative options, distance/time/directions; no reservation or payment in scope | Owner-maintained data, approval/accreditation, destination/activity, availability and price records, route data |
| F12 | Ratings/reviews/feedback | No distinct objective; FR 2.2.4.1.13 | 1.2; 2.2.1.13; 2.2.4.1.13; Tables 35/51 | Tourist rating/review; destination/establishment; feedback | Submit, display, and authorized personnel review/manage feedback; public destination ratings used by CARS | Feedback records and rating displays | Auth, destination/establishment, feedback moderation/role access, public rating collection |
| F13 | Tourism content/advisory management | 1.3.2.7; FR 2.2.4.1.14 | 2.2.4.1.14/1.16; 2.3.6.5 | Official destinations, circuits, advisories, content | Authorized Tourism Office updates content; make updates accessible after synchronization | Current tourism information/advisory/circuit records | Admin portal, roles, backend/data sync |
| F14 | Establishment management/accreditation | 1.3.2.7; FR 2.2.4.1.11 | 1.2; 2.2.4.1.11/1.16; 2.3.6.5 | Owner application/documents, profile, package/activity/prices, availability | Tourism Office accredits; Super Admin provisions account; authorized owner maintains establishment records | Verified establishment content/availability for tourist display | Accreditation workflow, identity/roles, establishment records, audit controls |
| F15 | System administration and operations | 1.3.2.7; FR 2.2.4.1.16 | 2.2.4.1.16; 2.3.6.5; prototype Figure 19 | Users, roles, settings, system records | Tourism Office manages official tourism records and submitted feedback; Super Admin manages users/roles/system settings | Admin operations and system-level configuration | RBAC, settings, audit logs, admin screens |
| F16 | Offline/synchronization | 1.3.2.8; FR 2.2.4.1.15 | 1.4; 2.2.4.1.15; 2.3.6.1/4 | Previously synchronized itinerary and destination snapshots; connection recovery | Read limited cached data offline; synchronize local information to Supabase when connectivity returns | Offline view and later synchronization | Hive, Supabase, sync/conflict policy, connectivity detection |
| F17 | Device geolocation | 1.3.2.9; FR 2.2.4.1.8 | 1.4; 2.2.1.9; 2.3.2.1.1.4/1.3.3; 2.3.6.1 | Device/browser location permission and GPS/network capability | Acquire current coordinates; use as route starting point/current position; do not assume arrival detection per scope | Current-location display/start point | Device Geolocation API, permission, valid coordinates, route service |
| F18 | PWA and cross-platform quality | Cross-cutting | 1.2; 2.2.4.2.1–2.2.4.2.6; Figure 1 | Browser/device, auth, network, cached data | Secure auth/password handling, RBAC, validation; performance/reliability/availability/usability/compatibility/maintainability requirements | Responsive installable PWA and admin portal | Flutter web/PWA support, security, performance, browser testing |

## 4. CARS: criteria, equations, weights, and decision boundaries

### 4.1 Six weighted criteria

Section 2.3.2.1.1.2 and Table 6 state the six weighted criteria. The table's observed survey means and weights are:

| Criterion | Basis stated in Table 6 | Mean Likert score | Weight |
|---|---|---:|---:|
| Interest and Activity Match | Match tourist interests/preferred activities to destination offerings | 3.1860 | 15.48% |
| Public Destination Rating | Publicly available destination ratings | 3.5349 | 17.18% |
| Weather Suitability | Current/forecast weather suitability | 3.4884 | 16.95% |
| Budget Compatibility | Estimated destination cost versus tourist budget | 3.6744 | 17.85% |
| Travel Distance Sustainability (other prose says suitability) | Calculated distance versus preferred maximum | 3.3488 | 16.27% |
| Preferred Travel Time (objective says Available Travel Time Compatibility) | Compatibility with preferred/available duration | 3.3488 | 16.27% |
| **Total** |  | **20.5814** | **100.00%** |

The criterion score is described as normalized, with each score on a 0–1 scale in the Hagimit example. Equation (1) is the weighted sum:

`RS(d) = Σ(i=1..n) w_i S_id`, with `Σ(i=1..n) w_i = 1`.

Equation (1) is expanded in Equation text at Section 2.3.2.1.1.3 as `RS(d)=w_pP(d)+w_rR(d)+w_wW(d)+w_bB(d)+w_dD(d)+w_tT(d)`. Here P is interest/activity, R public rating, W weather, B budget, D travel distance, T preferred time. Table 12 repeats weights: .1548, .1718, .1695, .1785, .1627, .1627. Table 13's illustrative scores are .90, .85, 1.00, .80, .75, .90. The text reports the weighted result as `0.8661` or `86.61%`.

Equation (2), shown as embedded image6, is the only explicit CARS criterion normalization formula:

`D(d) = 1 − d / D_max` when `d ≤ D_max`; otherwise `D(d) = 0`.

The prose says OSM provides road-network data and OSRM computes road distance/time from current location; distance near the preferred maximum gets a linearly lower score, and values above maximum score zero. The source does **not** specify exact formulas for public rating, weather suitability, budget compatibility, interest/activity matching, or preferred-time compatibility. It does not specify missing-score imputation. The group and accessibility suitability rules are stated as eligibility/suitability logic rather than an additional weighted criterion.

### 4.2 Group and activity suitability

Sections 2.3.2.1.1.5–1.1.5.8 and Tables 9–11 distinguish solo, couples, small groups (2–5), big groups (6+), families with children, seniors, PWDs, and mixed groups. Table 9 maps family-with-children, senior, and PWD profiles to examples of suitable activities. Table 10 labels swimming/picnic/sightseeing/beach relaxation suitable by default, snorkeling/kayaking optional at parent choice, cliff diving/strenuous hiking not recommended by default but selectable by parent. Table 11 says mixed groups prioritize accessibility/family/low-demand choices, rest, capacity, and optional vigorous activities. The text expressly says these are recorded suitability classifications, not clinical assessments, and parents remain responsible for deciding appropriateness. No age cutoffs, medical model, exact accessibility scoring, or numerical group weighting formula is supplied.

## 5. Tourism circuit feature

Section 2.3.2.1.2 and Figure 6 specify Tourism Office-provided circuits grouping destinations (interview examples: North, Central, South Samal). Tourists browse, choose, combine destinations across circuits, and are not required to follow a fixed circuit sequence. Selected destinations are evaluated with CARS; tourists review and retain/add/remove them; approved destinations go to MO-GA. Routes and estimated distances/time are assigned by OSM/OSRM, optionally starting from permitted geolocation. The resulting itinerary is described as containing destinations, activities, stay durations, routes, travel times, and estimated costs. Tourism Office administrators maintain circuits and associated destinations, with changes synchronized to the tourist app.

The manuscript does not fully specify circuit versioning, whether a circuit itself is a protected item, what manual selection/circuit mixing means in the UI, or how the input is encoded for multi-day MO-GA. Figure 6's embedded diagram depicts selection → CARS/MO-GA → itinerary generation/review/presentation, but does not fill these contract gaps.

## 6. MO-GA design as written

### 6.1 Problem and chromosome

Section 2.3.2.1.3 says candidate destinations come from Manual Selection, Circuit-Based Planning, or CARS/System-Generated planning. Tourists approve destinations and provide length/budget/time. Only System-Generated planning supplies CARS scores; manual/circuit destinations are not assigned invented scores. OSM supplies road data and OSRM routes between successive destinations. It says select the highest-fitness feasible candidate and let the tourist review/amend it.

A chromosome is a permutation/ordered sequence of destination genes; each gene contains destination ID, associated activities, and planned stay duration; start point is separate. Table 14 illustrates S plus four genes: Hagimit Falls (90m), Kaputian Beach (180m), Paradise Island (120m), Monfort Bat Sanctuary (60m). Initialization creates candidate visiting orders over the same approved gene set, preserving destination information/stay; Table 15 gives four permutations. Thus the detailed described initialization changes ordering, not destination membership. That sits uneasily beside objective 1.3.2.3 wording and system-generated selection expectations if MO-GA is expected to choose a subset.

### 6.2 Route segments and fitness equations

Section 2.3.2.1.3.3 calculates road route distance/time for origin→first stop and each consecutive pair; totals sum segments. Table 16 is illustrative: 5, 10, 12, 8 km and 12, 22, 26, 20 minutes, totals 35 km and 80 minutes; the text says replace these with actual OSRM outputs. Stay duration is added separately to travel time for daily schedule.

Equation (3), as rendered in Figure 12 and used by the sample, is interpreted visually as:

`F = [Σ(i=1..n) RS_i] / [α D_norm + β T_norm] − P_budget − P_time`.

This is the figure's displayed expression; the extracted equation paragraph has lost fraction layout. It is a scalar maximization despite the name “Multi-Objective.” Equation (4), for Manual Selection/Circuit-Based Planning, is malformed in extracted text (`F=1α*DNorm +β*TNorm * Pbudget *Ptime`); the fraction/penalty operators cannot be unambiguously recovered from body text alone. Figure 12 only depicts the System-Generated variant. No alternate equation is invented here.

Equation (5): `α + β = 1`, where α weights distance and β travel time. Equation (6): `D_norm = D_total / D_max`. Equation (7): `T_norm = T_travel / T_max`. Equation (8), budget penalty, is `0` if `C_total ≤ B`, otherwise `(C_total − B) / B`. Equation (9), daily time penalty shown in image8:

`P_time = Σ(d=1..m) [0 if T_d ≤ T_available,d; (T_d − T_available,d) / T_available,d if T_d > T_available,d]`, where `T_d = T_travel,d + T_stay,d`.

The manuscript does not give zero-budget handling, normalization reference selection, all cost component inclusion details, or policy for absent estimates. Table 17 defines F, RS_i, n, normalized totals, α/β, route totals/maxima, cost, budget, and availability.

### 6.3 Constraints and operators

Section 2.3.2.1.2.7 lists: budget overrun is penalized; daily travel+stay over available time is penalized; traveler capability/accessibility is eligibility, not a fitness component; no destination revisit; System-Generated planning only considers the CARS candidate set. Other prose says the selected candidate must be feasible, so the boundary between soft penalties and feasible-candidate rejection is not fully reconciled.

Operators: tournament selection chooses best fitness among a small random tournament; one-point crossover is required to preserve a permutation with each selected destination exactly once, but its repair/algorithm is expressly “to be finalized”; swap mutation exchanges two destination genes without changing their attributes or set. Stopping occurs at max generation count or specified no-improvement generations; final highest-fitness feasible candidate is output. Neither population size, tournament size, mutation/crossover rates, max generations, nor stagnation count is set by the manuscript. No explicit elitism or non-dominated sort/crowding-distance rule appears. Figure 8 is tournament; Figure 9 one-point crossover; Figure 10 swap mutation; Figure 11 stopping.

### 6.4 Sample calculation and one-/multi-day gap

Tables 18–22 use a family of five, ₱5,000, three days, interests Nature/Beach/Recreation; four candidates with scores .92/.90/.95/.88 and sample costs/stays; four whole-sequence permutations; sample fitness scores A 5.34, C 4.89, B 4.45, D 3.93. The sample assumes zero penalties and states A wins with the shortest distance/time and same total CARS score. It does not explicitly show day allocation, per-day route decomposition, accommodation cost, or schedule feasibility for those three days, while Equation (9) is daily. One-day versus multi-day encoding, stop-day assignment, overnight bases, cross-day route starts, and itinerary end point are insufficiently specified.

## 7. Route calculation and device location

Sections 1.3.2.4, 2.2.1.9, 2.3.2.1.1.4, 2.3.2.1.3.3 and 2.3.6.3 specify OSM road network data and OSRM road routing/distance/estimated-time. OSRM values are intended as road-network outputs, not straight-line distance. The sample route values are expressly illustrative pending actual OSRM results. The starting coordinate can be the current permitted device location or tourist-selected designated point. The manuscript says destination network legs and return? It specifies origin→first and consecutive destination pairs; it does not state a final return-to-origin leg. No specific travel-mode profile or mode-specific OSRM profile is defined.

Geolocation is permission/device dependent and is used for current coordinates/proximity/start location. Section 1.4 explicitly excludes arrival detection/geofencing. Figure 4 and the Figure 27 prototype caption imply location monitoring/arrival notifications; this is contradictory and requires manuscript clarification.

## 8. Self-healing module: equations and chronological flow

### 8.1 Delay Severity Score

Section 2.3.2.1.4.1 defines actual delay `D = T_actual − T_planned` (Equation 11), then `DS = (T_actual − T_planned) / T_remaining` (Equation 10). Table 25 / Equation (12): `DS < .20` minor → update ETA only; `.20 ≤ DS < .40` moderate → propose activity-duration/schedule changes; `DS ≥ .40` severe → propose MO-GA re-optimization. The example 210−180=30; 30/120=.25 = moderate. Tourist confirmation applies to proposed changes.

Unspecified: whether times are elapsed or total on which clock; denominator zero/negative; actual delay under zero; missing/uncertain reports; time-zone/rounding; whether DS is clamped. The narrative says accumulated delay as fraction of remaining planned time.

### 8.2 Weather Risk Score and activity impact

Equation (13) body extraction reads `WRS = Σ(X_i × X_i) / n`, but the variables Table 27 defines are `W_i` (weather severity) and `R_i` (destination exposure), and the worked example computes `Σ(W_i × R_i)/n`. Therefore the likely intended product conflicts with the literal extracted equation; the report records both without choosing. `0≤W_i,R_i≤1`, hence `0≤WRS≤1`. Table 28: Sunny 0, Cloudy .25, Light Rain .50, Heavy Rain .75, Storm 1.00. Table 29: indoor/protected `R=.00`, partially sheltered `.50`, fully outdoor `1.00`. Weather risk Table 30: low `<.50`, moderate `.50≤WRS<.75`, high `≥.75`.

The weather action rule (embedded image15 and Table 34) says low retains current plan; moderate reassesses/proposes temporary schedule adjustments or alternatives; high evaluates affected activities and may MO-GA-reoptimize. Image15 appears to put `.75` in the moderate branch (`≤.75`), while Table 30 and Figure 13 make `.75` high (`≥.75`). This boundary is inconsistent.

Activity sensitivity `S_a = h(activity classification)` (Table 31): indoor 0; outdoor weather-independent .25; outdoor weather-sensitive .75; high-risk during severe weather 1. Weather impact `IA_a = W_a × S_a`; reassess when `IA_a ≥ θ_a`, with `.50` offered as an example threshold. Candidate alternative set `C={a | available, suitable, not weather-affected}`. `A_alternative = arg max_{a∈C} AS(a)`. `AS(a)=w1P(a)+w2D(a)+w3T(a)+w4W(a)`; weights nonnegative and sum to one. The exact four weights and scoring functions for P/D/T/W are not supplied.

Temporal handling: forecast weather disruption duration `D_w = T_weather-end − T_weather-start`; `≤60` minutes is short, `>60` prolonged. For short adverse weather, temporarily postpone outdoor activity rather than immediately remove it; may suggest an indoor alternative, refresh weather, reassess. `ΔW = W_(t+1) − W_t`; positive worsening, negative improving, zero unchanged. After improvement, reassess restoration using updated WRS and available schedule. Paragraph at 2.3.2.1.4.2.6 prints `WRS 0.50` while its parenthetical says moderate/high `WRS ≥ 0.50`; likely intended inequality is `WRS ≥ .50`, but it is not silently normalized here.

### 8.3 End-to-end self-healing chronology

1. Identify unfavorable weather, destination/activity unavailability, or tourist-reported delay (Figure 13; Section 2.3.2.1.4.5).
2. Determine affected remaining itinerary entries. For delay compute DS; for weather compute WRS and activity sensitivity/impact; for unavailability/unsuitable weather form eligible alternatives and calculate AS.
3. Apply the relevant decision: minor delay updates ETA only; moderate delay proposes compressing remaining activity duration/schedule; severe delay sends remaining itinerary to MO-GA. Low weather risk retains subject to activity fit; moderate reassesses affected activities and proposes temporary adjustment/alternative; high evaluates affected activities and re-optimizes when necessary. Unavailable/affected item selects highest-scoring eligible alternative; when none exists, may postpone or re-optimize.
4. Keep already visited destinations and try to retain original plan as far as applicable; recalculate estimated times/schedule for remaining portion where necessary.
5. Show proposed changes to tourist for review and confirmation.
6. On acceptance, apply revised itinerary; on rejection, keep the existing itinerary. Weather-improved postponed activities may be reconsidered and restored only after schedule/updated risk reassessment and tourist acceptance.

The text says “when necessary” and “may” for several actions, so not every branch is deterministic. Section 1.2 says Find Similar replaces only the unavailable service, not the whole itinerary; self-healing can reoptimize the remainder. Their boundaries are not defined.

## 9. Availability, alternative recommendations, and tourism management

Sections 1.2, 1.3.2.6, 2.2.4.1.11–1.12 specify that availability and prices are operator-recorded/updated. Alternatives for unavailable rooms/activities consider price, similarity, distance, accessibility, and itinerary fit; for accommodations, other operators accepting outside guests may qualify. “Find Similar” changes only the unavailable room/activity, not the whole itinerary; tourist reviews/accepts. The system does not process reservations or online payment (scope). No exact similarity/distance/accessibility/fit scoring formula, data refresh schedule, evidence freshness limit, service/provider API, or tie-breaker appears. Recorded availability is not live external confirmation.

Authorized Tourism Office functions include destination/circuit/content/advisory and feedback management, accreditation-related records, and tourism information (Sections 1.2, 2.2.4.1.14/1.16, 2.3.6.5). Authorized establishment owners maintain their own establishment/profile, packages, activities, service details, prices and recorded availability after verification. Super Admin provisions accounts and administers users, roles, permissions, and system configuration. The manuscript includes role boundaries but does not specify a complete permission matrix or audit/retention policy.

## 10. Offline storage, synchronization, and data model

Sections 1.3.2.8, 1.4, 2.2.4.1.15 and 2.3.6.1 describe limited offline viewing of previously synchronized itineraries/destination details through Hive and synchronization with Supabase when online. The scope says live weather, routing, availability updates, and cloud sync require internet. The manuscript does not define conflict resolution, whether local itinerary edits are queued, sync ordering/idempotency, data retention, partial sync, offline authentication, or migration recovery. Those must not be invented as manuscript requirements.

Data dictionary Tables 35–51 and Figure 16/Appendix C ERD cover profiles, categories, tourist_details, establishments, destination_gallery, destinations, activities, destination_availability, itineraries, itinerary_stops, notifications, moga_results, self_healing_logs, weather_cache, favorites, reservations, and reviews. The diagram also depicts tables beyond the numbered dictionary (e.g., audit_logs, bookings, transactions, payments, location_verifications, events, roles/system_settings). This is a scope discrepancy. Tables 43–44 contain itinerary/status/sequence/time/cost/distance/fitness fields; Table 46 stores optimization outputs; Table 47 stores self-healing trigger/adjustment and scores; Table 48 caches weather. Table 50 `reservations` conflicts with the explicit “no reservations” limit.

## 11. Tourism workflows (manuscript reconstruction)

The following summaries cover the seventeen requested workflow families. They are manuscript descriptions, not verified application capabilities.

| Workflow | User action and inputs | Processing/decision | Output and modules |
|---|---|---|---|
| Registration/profile | Register/log in, recover account, set preferences/group/budget/time | Auth and role permissions; store profile | Profile usable by CARS and planning; auth/profile modules |
| Preference input | Enter interests, budget, travel time/distance, group/accessibility, dates/location | Persist and apply suitability filters; no exact profile schema semantics given here | CARS-ready preferences |
| CARS recommendations | Request recommendations | retrieve candidates/context; eligibility then six weighted criteria; rank; tourist can edit | Ranked destinations/activities sent to MO-GA |
| Manual destinations | Browse/search and add/remove/reorder | Tourist-selected destinations; no CARS scores assigned solely for manual input | Approved list to MO-GA |
| Circuit selection/combination | Browse office circuits and choose destinations across circuits | No fixed sequence; CARS evaluation/review; admin maintains records | Approved mixed list to MO-GA |
| System-generated itinerary | Review CARS candidates, approve list, enter length/budget/time | MO-GA permutes/evaluates; only CARS candidates per candidate constraint | Proposed optimized itinerary |
| One-day planning | Choose trip entries/start/time and constraints | MO-GA route/schedule for one day; daily penalty/eligibility | One-day order/schedule |
| Multi-day planning | Enter number of days and availability per day | MO-GA handles daily duration; manuscript does not completely define assignment/overnights | Multi-day itinerary; encoding needs closure |
| Route calculation | Set/allow origin and selected stops | OSM road network + OSRM routes origin-to-first and pairwise subsequent legs | Road route, distance and estimated time; no mode-specific profile specified |
| Accommodation/activity alternative | View itinerary availability; choose Find Similar after unavailable record | Filter/rank alternatives using five named dimensions; replace only unavailable service | Tourist reviewable service alternative; no transaction |
| Weather disruption | Weather service identifies condition at remaining itinerary | WRS, activity impact, time duration; retain/adjust/alternative/reoptimize by thresholds | Proposed adjustment |
| Delay | Tourist reports travel delay and elapsed/planned/remaining time | DS thresholds select ETA, schedule compression, MO-GA | Proposed remaining itinerary/time adjustment |
| Unavailable destination/activity | Tourist or recorded information indicates unavailable | Search available/suitable alternatives, AS rank; if none postpone or reoptimize | Alternative proposal or postponed item |
| Self-healing review | Tourist accepts/rejects proposed changes | Accept applies; decline preserves old itinerary | Updated plan or unchanged active plan |
| Tourism management | Admin/owner edits assigned records | Role scope, accreditation and synchronization | Updated destinations/circuits/prices/availability/content |
| Ratings/reviews | Tourist submits/views feedback | Record and authorized review; public rating source may feed CARS | Feedback and rating displays |
| Offline itinerary | Tourist opens previously synced itinerary/destination offline | Read local Hive snapshot; later sync to Supabase online | Limited cached access; conflicts unspecified |
| Geolocation | Grant location permission | Obtain current coordinates for current location/start/proximity; no geofence per scope | Location display or route origin |

## 12. Figures, tables, equations, and appendices inspected

Main figure captions: Figures 1–17 cover Agile lifecycle, 2026 project duration, conceptual framework, overall system workflow, CARS pipeline, tourism circuit integration, MO-GA process, tournament selection, one-point crossover, swap mutation, stopping criterion, optimization problem representation, dynamic self-healing process, use-case diagram, ERD, and system architecture. Prototype captions continue Figures 18–28: admin dashboard, role management, establishment dashboard, tourist home, destination details, route planner (Figure 24), trip preferences (Figure 23), destination selection, generate itinerary, interactive map navigation, saved places. The manuscript text at architecture calls its diagram Figure 18 though caption labels Figure 17; route planner/trip preferences numbering is inverted. Appendices A–D reproduce conceptual/use-case/ERD diagrams and data-gathering materials; some figures reuse earlier Figure 3/14/15 labels.

Figure 15's embedded use-case diagram further shows tourist actions (register/log in, manage profile, search/view information, browse/select/combine circuits, CARS, customize/generate itineraries, route directions, update progress, self-healing updates, recorded availability/alternatives, reviews, offline access); owner actions (submit documents/activities, manage profile, packages/activities, price/availability, view feedback); Tourism Office actions (accredit establishments, destinations/circuits/advisories/feedback, reports); and Super Admin actions (verified-owner provisioning, users/roles, settings/API configuration, database/backup, logs/reports). Some of these extend beyond the prose scope or have no matching current application end-to-end implementation. This diagram is additional source evidence, not a reconciliation of the conflicts.

Tables 1–4: market/feature comparison, hardware/software, project estimate. Tables 5–13: activities, CARS criteria/variables/examples. Tables 14–23: gene/population/route segment/fitness/sample/optimization problem. Tables 24–34: delay and weather/alternative rules. Tables 35–51: schema data dictionary. All tables and available row content were inspected; image/table text that is not legible or not extractable is not treated as additional requirement evidence.

Equations (1)–(13) cover weighted CARS score, distance suitability, two MO-GA fitness variants, α/β condition, normalized distance/time, budget and daily time penalties, DS and raw delay, delay action, WRS, and the activity/weather/alternative calculations described above. Other formula-like embedded images are explicitly cited above. Equations (3), (4), (13), weather action at `.75`, and the weather-restoration inequality contain extraction/rendering or internal consistency ambiguities.

## 13. Explicit requirements versus recommendations

**Explicit manuscript requirements:** six weighted CARS criteria and survey weights; profile/group and recorded suitability checks; cross-circuit selection; tourist approval and control; MO-GA one-/multi-day processing and named operators/constraints; OSM/OSRM road-network route outputs; weather and disruption rules/thresholds where specified; recorded availability alternatives; role-managed tourism data; limited offline cached access; user-permission geolocation; no bookings/payments/integrations in stated scope; security, performance, reliability, availability, usability, compatibility, maintainability.

**Not explicit / engineering recommendations only:** missing-score policy; precise scoring methods for five of six CARS criteria; missing/uncertain evidence states; exact remote schemas and RLS; immutable itinerary commitments; flexible per-leg transport; safe migration/backup; circuit-to-MO-GA record identity; fitness equation repair; Pareto policy; accepted alternative weight values; freshness standards; conflict resolution; security audit/retention implementation; arrival detection; any transportation provider coverage. This report does not promote these recommendations to owner or manuscript approval.

## 14. Manuscript ambiguities and contradictions requiring author clarification

1. **CARS names:** objectives/functional text says “Available Travel Time Compatibility”; design/weights say “Preferred Travel Time”; the six criteria otherwise appear aligned.
2. **Criteria formula coverage:** only the distance function is fully specified. Other criterion score normalization/formulas and missing evidence policy are absent.
3. **CARS Table 6 cross-reference:** paragraph after Table 6 says “Table 5 shows the six aspects,” despite Table 6 containing them.
4. **MO-GA naming and objective:** called multi-objective but presents a single scalar fitness and “highest fitness.” Equation (4) is not reconstructable unambiguously from extracted text; figure illustrates only the system-generated formula.
5. **Feasibility vs penalties:** budget/time are penalized, yet selection is said to choose among feasible candidates; exact hard/soft boundary is missing.
6. **Population scope:** initialization keeps the same approved destination genes and permutes order; candidate-set constraint covers system-generated destinations. No subset-selection operator is defined.
7. **Multi-day plans:** 3-day sample but no clear day allocation, overnight starts/return behavior, or proof that sample daily constraints are evaluated.
8. **Weather formula:** Equation (13) body says `X_i×X_i`; variable table and worked example use `W_i×R_i`.
9. **Weather threshold:** Table 30 says high at `WRS≥.75`; Figure 13 agrees; embedded weather action image puts `.75` in moderate with `≤.75`.
10. **Weather restoration:** the printed `WRS 0.50` omits a comparison sign; parenthetical says `WRS≥.50` while describing weather-improved restoration.
11. **Delay denominator:** no behavior for zero remaining time or negative measured delay; elapsed-time clock definition is incomplete.
12. **Self-healing vs “Find Similar”:** one section replaces only unavailable service, while broader self-healing can reoptimize itinerary; interaction is not defined.
13. **Geolocation:** scope excludes arrival detection/geofencing, but Figure 4 says location monitoring/detect arrival and Figure 27 says arrival notifications; Figure 4 also says automatic re-optimization though self-healing text requires review/acceptance.
14. **Reservations/payments:** scope says no reservations/payments, yet requirements/data dictionary/ERD/prototype captions include reservations, bookings, payments, and outstanding balances.
15. **Roles and management:** four roles are named, but full permission/approval/audit matrix and owner-vs-office field boundaries are not specified.
16. **Offline synchronization:** scope says sync cached/local records when online but omits conflict, merge, retry, failed sync and recovery behavior.
17. **Figures/versions:** labels and cross-references conflict (Figure 17/18 architecture; Figures 23/24 order; duplicate appendix figure numbers; Figure X placeholder). No explicit revision baseline is named.

These are source findings. They need manuscript-owner resolution before treating the affected items as precise acceptance criteria. No manuscript edit, code edit, test run, or implementation authorization was made for this task.
