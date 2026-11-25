# Task 38B — Manuscript to Application Implementation Gap Analysis

**Project:** SAMAL NAV
**Review basis:** Actual repository manuscript `manuscript/SAMAL NAV  (1).docx`; current Flutter source and tests inspected read-only
**Status:** Analysis only. No implementation authorization is granted.
**Execution:** No tests, builds, Supabase access, database access, or Hive data access were performed.

## 1. Evidence and status meanings

The manuscript analysis is in [`TASK_38B_SAMALNAV_COMPLETE_MANUSCRIPT_SYSTEM_FEATURE_ANALYSIS.md`](TASK_38B_SAMALNAV_COMPLETE_MANUSCRIPT_SYSTEM_FEATURE_ANALYSIS.md). Source references below are the actual current worktree. That worktree already contains unrelated CARS edits and many untracked Task documents; those were preserved. The current Task 39 profile change exists, but it is unrelated to the larger CARS/MO-GA integration gaps.

- **IMPLEMENTED AND VERIFIED:** source behavior plus relevant automated evidence has been checked for the specific stated behavior. This review did not run tests, so it uses this sparingly.
- **IMPLEMENTED BUT NOT FULLY VERIFIED:** a concrete production path exists, but runtime/integration behavior is not established by this read-only review.
- **PARTIALLY IMPLEMENTED:** some components exist, but important manuscript steps or end-to-end paths are missing.
- **NOT IMPLEMENTED:** no corresponding production behavior was found in inspected source.
- **BLOCKED BY AN APPROVED CONTRACT:** owner-selected requirements or existing scope/security gates constrain implementation; this label does not mean a code change was authorized.
- **REQUIRES OWNER DECISION:** the manuscript or current decisions do not settle the behavior.
- **REQUIRES SEPARATE AUTHORIZATION:** future code/schema/test changes are outside the current read-only task and need explicit scoped authorization.

No feature is marked fully verified solely because a model, screen, interface, or test file exists.

## 2. Feature-by-feature comparison

| ID / manuscript trace | Current application evidence | Status | Gap / verification note |
|---|---|---|---|
| F01 Authentication and role access (1.2; 2.2.4.1.1/1.16; 2.3.6) | `lib/screens/auth_screens/{login_page.dart,register_page.dart,management_login_page.dart}`, `lib/services/role_service.dart`, `lib/models/app_role.dart`, `lib/config/routes.dart`, role dashboards and guarded route helpers use Supabase Auth/role lookup. | IMPLEMENTED BUT NOT FULLY VERIFIED | Production paths exist, but role matrix, RLS, establishment verification sequence and complete workflow were not integration-tested here. The manuscript also differs on booking/payment features. |
| F02 Tourist profile/preferences (2.2.4.1.2; Task 39 current state) | `lib/models/tourist_planning_profile.dart`, `lib/services/tourist_planning_profile_service.dart`, `lib/screens/tourist_screens/planning_preferences_page.dart`; profile-to-trip adapter. Task 39 now makes local `travelMode` nullable, shows it read-only/unconfirmed, and removes `travel_mode` from remote update payloads. | IMPLEMENTED BUT NOT FULLY VERIFIED | Interests/preferences, budget, availability/group facts are present, but durable confirmation is absent and CARS remains fail-closed for unconfirmed preference evidence. No remote transport writes/clear are implemented (by design). Do not treat Task 39 as full catalog-based trip-leg selection. |
| F03 Destination information browsing (FR 2.2.4.1.3; Tables 39–42) | `lib/models/destination_record.dart`; `lib/services/destination_service.dart`; home, map, favorites, detail/planning screens; record decoding supports source/rating trust fields. | IMPLEMENTED BUT NOT FULLY VERIFIED | App can load/display records, but the manuscript’s complete accredited catalog/content/gallery/accessibility and freshness behavior is not proven end to end. Destination loading includes fallback/OSM discovery paths that need trust separation. |
| F04 CARS six-criterion scoring/ranking (Objective 1; 2.3.2.1.1; Tables 5–13; Eqs 1–2) | `lib/models/cars_models.dart` declares six criteria and currently uses a 0–100 score contract. `lib/algorithms/cars_engine.dart` accepts caller-supplied score maps and weights, validates weights sum to 1 and ranks complete candidates; it does not calculate the six raw criterion formulas. `lib/algorithms/cars_interest_activity_matcher.dart`, `cars_budget_assessment.dart`, `cars_travel_assessment.dart`, and `cars_assessment_input_preparer.dart` prepare evidence/eligibility. `lib/services/cars_recommendation_provider.dart` has an unavailable default and a source/policy-injected path. UI review is `cars_recommendation_review_page.dart`. | PARTIALLY IMPLEMENTED | Current fail-closed boundary prevents unsupported rankings. The manuscript criterion formulas are absent for five criteria; runtime policy is injected and no default full six-score source/policy is wired. Runtime 0–100 differs from manuscript example 0–1. The manuscript survey weights are fixed; current engine permits configured weights. Need approved alignment before claims of manuscript-faithful CARS. |
| F05 Tourism circuit browsing/combination (Objective 2; 2.3.2.1.2; Figure 6) | `lib/models/itinerary_draft.dart` has `PlanningMethod.circuitBased`, `CircuitReference`, and circuit provenance; `plan_page.dart` exposes planning flows. `ManualSelectionMogaAdapter` explicitly rejects circuit-based drafts. Repository contains no dedicated circuit selection/administration screen found in `lib/screens/`. | PARTIALLY IMPLEMENTED | Data concepts/provenance exist, but Office circuit browsing, cross-circuit selection and route to circuit-capable MO-GA are not established. Do not equate a `CircuitReference` model with the feature. |
| F06 Manual destination selection/customization (FR 2.2.4.1.6; 2.2.1.7–1.8) | `lib/screens/tourist_screens/plan_page.dart`; `lib/algorithms/manual_selection_workflow.dart`; `lib/models/itinerary_draft.dart`; manual UI/Hive tests. | IMPLEMENTED BUT NOT FULLY VERIFIED | Manual stop add/remove/reorder and reviewed drafts exist. The approved draft model has no commitment class, protected transfer schedule, or per-leg transport. Circuit mode has separate gaps. |
| F07 MO-GA itinerary optimization (Objective 3; 2.3.2.1.3; Eqs 3–9; Figures 7–12) | `lib/algorithms/moga_engine.dart` has permutation chromosomes, evolutionary operations, Pareto sorting/crowding, one-/multi-day methods; `manual_selection_moga_adapter.dart` adapts drafts; `system_generated_draft_builder.dart` creates CARS-generated drafts. Tests: `test/moga_engine_test.dart`, `test/manual_selection_moga_adapter_test.dart`, `test/system_generated_draft_builder_test.dart`. | PARTIALLY IMPLEMENTED | Engine objective is `[distance, -attractionsFit, variance]` with NSGA-II-style Pareto processing and minimum-distance front selection. Distance is Haversine × 1.3; time uses fixed average speed (commonly 30 km/h). It does not implement manuscript fitness equations/cost/CARS/weather, road-network route legs, or all manuscript constraints. Adapter rejects circuit drafts. Does not choose optional destinations from broader candidate pool or preserve D31A commitments. |
| F08 OSM/OSRM route guidance (Objective 4; 2.3.2.1.3.3; FR 2.2.4.1.8) | `lib/screens/tourist_screens/map_page.dart` uses `flutter_map`/`latlong2` and OSM tile presentation; `destination_service.dart` includes optional Overpass OSM discovery. `cars_travel_assessment.dart` exposes provider interface, not an OSRM production implementation. Search of `lib/` found no OSRM client/router endpoint. | PARTIALLY IMPLEMENTED | Map tiles/OSM discovery are not OSRM road routing. MO-GA uses geometric approximation. No verified route polyline, pairwise road distance/time provider, return leg, mode-aware route, or connected route-navigation service was found. |
| F09 Weather API and suitability (Objectives 1/5; 2.3.2.1.4.2; Tables 27–31) | `lib/services/open_weather_map_service.dart` implements an injectable HTTP forecast service with provenance/coverage, and has `test/open_weather_map_service_test.dart`. `cars_assessment_input_preparer.dart` attaches weather evidence and coverage to CARS inputs. | PARTIALLY IMPLEMENTED | Weather fetch/evidence exists, but no manuscript WRS/activity sensitivity scoring or weather-action rules are wired. `OpenWeatherMapService` comments say it is not wired into manual planning and does not calculate CARS scores. No self-healing workflow consumes it. |
| F10 Self-Healing Re-Optimization (Objective 5; 2.3.2.1.4; Eqs 10–13; Tables 24–34; Figures 13–14) | Search of production `lib/` found no Delay Severity Score, WRS decision engine, Alternative Score selection, disruption orchestration, accept/reject rollback workflow, or self-healing service. Itinerary models have stages but not self-healing. | NOT IMPLEMENTED | All three disruption types, formulas, restoration, proposal lifecycle and acceptance/rejection must be implemented and tested; formula contradictions must be resolved first. |
| F11 Accommodation/activity availability and alternatives (Objective 6; 2.2.4.1.11–1.12; Tables 38/41/42) | `lib/services/establishment_service.dart`, `establishment_dashboard.dart`, `destination_service.dart`, and models include establishment/reservation/activity-adjacent concepts; `DestinationRecord` exposes availability-related attributes but a complete date/time accommodation/activity alternative recommendation flow was not found. | PARTIALLY IMPLEMENTED | Owner dashboards and recorded data concepts exist; tourist “Find Similar” ranking with price/similarity/distance/accessibility/itinerary fit, data freshness, and no-booking boundary are not established. Source data is not proof of current provider confirmation. |
| F12 Ratings/reviews (FR 2.2.4.1.13; Table 51) | `lib/models/review.dart`, `review_record.dart`, `establishment_review_record.dart`; services and admin/establishment components reference review tables; destination records carry rating provenance; CARS review screen exposes evidence. | PARTIALLY IMPLEMENTED | Data and some display/manage paths exist. End-to-end tourist submission/moderation/public-rating collection/attribution and consistency with CARS evidence remain unverified. |
| F13 Tourism information/advisories/circuit management (Objective 7; FR 2.2.4.1.14) | `administrator_service.dart`, `destination_service.dart`, administrator dashboard and models cover parts of admin data access; destination/circuit functions are not shown as complete. | PARTIALLY IMPLEMENTED | Full official content/advisory/circuit lifecycle and synchronization to all tourist views not established. |
| F14 Establishment management/accreditation (Objective 7; FR 2.2.4.1.11) | `establishment_service.dart`, `establishment_dashboard.dart`, `establishment.dart`, `location_verification.dart`, role screens. | PARTIALLY IMPLEMENTED | Owner dashboard/records exist, but entire document submission → Office accreditation → Super Admin provisioning workflow and authorization controls are not verified. |
| F15 Admin/user management (FR 2.2.4.1.16; Figure 19) | `super_admin_dashboard.dart`, `administrator_dashboard.dart`, `role_service.dart`, `super_admin_service.dart`, audit service/models. | IMPLEMENTED BUT NOT FULLY VERIFIED | Role/settings/audit interfaces/services exist. RLS, least-privilege security and complete authorized function matrix require independent security review and environment-level evidence. |
| F16 Offline access and synchronization (Objective 8; FR 2.2.4.1.15) | `lib/services/offline_cache_service.dart` caches JSON snapshots previously synced; `local_itinerary_draft_store.dart` stores editable manual drafts in Hive v1. `main.dart` initializes Hive/cache. Tests: `local_itinerary_draft_store_test.dart`, `local_itinerary_draft_ui_test.dart`. | PARTIALLY IMPLEMENTED | The cache explicitly does not synchronize; local drafts explicitly are device-only and not account-synced. No Supabase sync queue, conflict strategy, or automatic data sync was found. Hive draft store accepts only format v1 and rejects other versions without migration. |
| F17 Device geolocation (Objective 9; FR 2.2.1.9; Figure 27) | `map_page.dart` uses `geolocator`; package dependency is in `pubspec.yaml`; planner accepts optional origin coordinates. | IMPLEMENTED BUT NOT FULLY VERIFIED | Current coordinate and origin flows exist. Manuscript says no arrival detection; prototype suggests it. Permission-denied/device fallback, precision/privacy and route integration need verification. |
| F18 Progressive web/cross-platform, security, quality (2.2.4.2; 2.3.6) | Flutter app structure, routes, platform folders, Supabase auth/config, manifests/platform project files. | IMPLEMENTED BUT NOT FULLY VERIFIED | PWA installability, browser compatibility, performance, security/password storage/RLS, and reliability targets are not established by source-file presence. No build/browser/security testing was run. |
| F19 Reservations/bookings/payments | Scope 1.4 says excluded, but tables/prototypes mention them. `booking_record.dart`, `reservation_record.dart`, `payment_record.dart`, `establishment_service.dart` include reservation/payment code. | REQUIRES OWNER DECISION | Application contains booking/payment-related behaviors that conflict with manuscript scope exclusions. Must not expand or claim functionality without reconciling scope and existing authorization/security contracts. |
| F20 Transportation / fixed water constraints | The manuscript broadly lists transportation as a travel requirement and illustrates land/ferry cost in Table 4; it does not establish the later D31A detailed catalog/leg/commitment contract. Current `TransportCatalog` is a local model; `TripConfiguration` has one trip-wide legacy mode and `RequiredTransfer` kind/endpoints only. | BLOCKED BY AN APPROVED CONTRACT | D31A decisions establish per-leg modes and fixed water commitments, but current data, source, availability and optimizer handling are absent and separate implementation authorization remains necessary. Catalog presence never proves service availability. |

## 3. Concrete source/test inventory

### 3.1 Models and persistence

- CARS: `lib/models/cars_models.dart`, `destination_record.dart`, `price_info.dart`, `itinerary_draft.dart`.
- Profile: `tourist_planning_profile.dart`; service and page are Task 39 modified, with transport read-only/unconfirmed and no remote `travel_mode` write.
- Itinerary: `itinerary_draft.dart` contains trip-wide `PreferredTravelMode`, `RequiredTransferKind`, `DraftStop`, `CircuitReference`, provenance, stage and optimization result. It does not contain a general ordered leg object or fixed/planned/optional commitment class.
- Local: `local_itinerary_draft_store.dart` uses `samal_nav_local_itinerary_drafts_v1`, format version 1; it writes only manual-selection drafts in review and rejects unsupported versions. `offline_cache_service.dart` is a separate synced-snapshot cache and does not sync.
- Catalog: `lib/models/transport_catalog.dart` defines a local catalog/codec and `test/transport_catalog_test.dart`; integration is not global.

### 3.2 Algorithms, services and screens

- Algorithms: `cars_engine.dart`, `cars_interest_activity_matcher.dart`, `cars_budget_assessment.dart`, `cars_travel_assessment.dart`, `cars_assessment_input_preparer.dart`, `manual_selection_workflow.dart`, `manual_selection_moga_adapter.dart`, `moga_engine.dart`, `system_generated_draft_builder.dart`.
- Services: `cars_recommendation_provider.dart`, `open_weather_map_service.dart`, `destination_service.dart`, `establishment_service.dart`, `administrator_service.dart`, `role_service.dart`, `offline_cache_service.dart`, `local_itinerary_draft_store.dart`.
- Tourist screens: `home_page.dart`, `map_page.dart`, `plan_page.dart`, `plan_results_page.dart`, `cars_recommendation_review_page.dart`, `system_generated_planning_page.dart`, `system_generated_draft_review_page.dart`, `planning_preferences_page.dart`, `favorite_page.dart`, `history_page.dart`.
- Management screens: `administrator_dashboard.dart`, `super_admin_dashboard.dart`, `establishment_dashboard.dart` plus role shell/auth screens.
- No production OSRM routing client or self-healing algorithm/service was found in `lib/` search.

### 3.3 Existing relevant tests (inspected only)

`test/cars_engine_test.dart`, `cars_interest_activity_matcher_test.dart`, `cars_budget_assessment_test.dart`, `cars_travel_assessment_test.dart`, `cars_assessment_input_preparer_test.dart`, `cars_recommendation_provider_test.dart`, `cars_recommendation_review_page_test.dart`, `moga_engine_test.dart`, `manual_selection_moga_adapter_test.dart`, `manual_selection_workflow_test.dart`, `system_generated_draft_builder_test.dart`, `system_generated_planning_page_test.dart`, `local_itinerary_draft_store_test.dart`, `local_itinerary_draft_ui_test.dart`, `open_weather_map_service_test.dart`, `planning_preferences_page_test.dart`, and `tourist_planning_profile_service_test.dart` exist. Their existence does not establish complete manuscript implementation. No tests were run for Task 38B.

## 4. Manuscript-to-code discrepancies

| Discrepancy | Manuscript evidence | Current code evidence | Consequence |
|---|---|---|---|
| Criterion scores scale | Example scores and RS are 0–1, Table 12 weights .1548–.1785 | `CarsScoreContract` is 0–100 and accepts only caller-supplied scores | Any future score adapter needs explicit scale conversion/approval; never silently scale or claim same contract. |
| CARS formulas | Only weighted sum/distance function specified; other five criterion formulas absent | Engine is generic score aggregator; preparer produces evidence; score policy injection required; default provider unavailable | Full ranking should remain blocked without approved score definitions/evidence. |
| CARS weights | Manuscript provides one survey weight vector | Engine takes a configurable map and provider accepts policy | Need decide if manuscript fixed vector governs production or another version is authorized. |
| MO-GA objective | Scalar fitness formula and highest-fitness candidate; some operators unspecified | NSGA-II Pareto objectives and distance-first front member; Haversine × 1.3, average speed | Current engine is not the manuscript formula; source code labels approximation, not OSRM. |
| CARS-to-MO-GA | CARS scores feed System-Generated MO-GA; manual/circuit must not receive invented scores | Builder currently passes selected destinations; engine's objectives do not use score/budget/weather | Ranking can create draft, but optimization does not apply manuscript score/cost constraints. |
| Circuit workflow | Tourist can combine Tourism Office circuits | Only model/reference/provenance; optimizer explicitly rejects circuit drafts | End-to-end objective 1.3.2.2/1.3.2.3 is absent. |
| Road network | OSM + OSRM for road distances, times and route directions | OSM map/Overpass paths; no OSRM route client found; MOGA geometric estimate | Route and travel-time output is not the specified road route. |
| Weather | OpenWeatherMap, WRS, thresholds, restoration/self-heal | Forecast service and evidence pipeline; no WRS/self-healing consumer | Forecast availability does not equal weather suitability/action. |
| Availability alternatives | Alternative ranking and “Find Similar” | Management data/services exist; complete tourist alternative decision flow absent | Recorded availability may be displayed but complete requirement is not satisfied by data model alone. |
| Offline sync | Previously synced records and itinerary information synchronize when online | cache only stores snapshots that already synced; draft store local-only; no sync orchestration found | Current offline functionality is narrower; no conflict resolution. |
| Geofence/arrival | Scope explicitly says none | Figure 4 / Figure 27 imply detection/notification; current map provides device location | Product/spec ambiguity must be resolved; don't claim arrival monitoring. |
| Bookings/payments | Scope excludes them | DB models/services contain booking/reservation/payment actions | Scope, security, RLS, audit and manuscript need reconciliation before expanding. |
| Fixed/per-leg transport | Later D31A contract requires mixed per-leg and strict fixed water constraints | One trip-wide legacy enum; separate unscheduled RequiredTransfer; MO-GA adapter ignores transfer list | Current MO-GA must not be said to honor tourist transfer bookings. |
| Hive versioning | Manuscript says Hive/local previously synchronized information; no explicit staged migration requirements | Draft version 1, unsupported formats fail read; synced cache separate | D31A-18–21 were later selected; migration/recovery remains unimplemented. |

## 5. Dependency graph and implementation order

The functional dependency is:

`approved source records + profile/group constraints → CARS evidence/scoring/eligibility → tourist review/approved candidates → per-leg route evidence + MO-GA feasibility/optimization → itinerary review/save → weather/delay/availability disruption assessment → alternatives/self-healing proposal → tourist confirmation`.

The separate management/data dependency is:

`role/security contract → tourism/establishment source-of-truth and verification → destination/activity/price/availability data → tourist browsing, CARS, alternative selection`.

Offline is cross-cutting: `stable local format + sync ownership/conflict contract → cached read and local edit behavior`, not a substitute for live routing/weather/availability.

Critical prerequisites and safe order:

1. **Reconcile source specification:** author resolves manuscript formula/threshold/scope contradictions (Section 1.4 vs tables/prototypes; Eq. 4; WRS; Figure numbers). Create a versioned approved requirements baseline; leave disputed behavior explicitly blocked.
2. **Evidence and security foundations:** identify approved source records, verification/freshness, A-09 audit/settings, A-11 retention, A-13 database scope, A-14 independent review; no live project access in this task.
3. **Data/evidence contracts:** destination/activity/group, costs, ratings, weather, availability, travel times; typed missing/unverified states and data provenance. Do not use placeholders as zero.
4. **CARS slice:** implement only approved scores/weights and eligibility; all six score evidence and missing-data behavior; acceptance tests against manuscript examples and score scale.
5. **Route provider slice:** OSM/OSRM route/time evidence and provenance; compare against geometric estimates without promoting estimates to road routes.
6. **Itinerary contract and Hive:** per-leg modes, trip-origin semantics, day assignment, commitment classes/fixed commitments and status; compatible migration/recovery design before persistence format change.
7. **MO-GA:** reconcile scalar-vs-Pareto, hard vs soft feasibility, single/multi-day, destination selection; then implement manual and circuit paths with invariants and deterministic tests.
8. **Availability/alternative workflow:** source-defined recorded status, price and attributes, alternative scoring and local confirmation boundaries.
9. **Self-healing:** only after delay/weather/availability evidence, formulas, schedule semantics, candidate alternatives and MO-GA constraints are integrated. Add acceptance/rejection rollback and restoration tests.
10. **Offline sync and release:** staged migration/recovery, conflict behavior, RLS/security, non-production verification before any authorized deployment.

The detailed batches, critical path, gates and parallelization are in [`TASK_38B_SAMALNAV_ACCELERATED_DEVELOPMENT_MASTER_ROADMAP.md`](TASK_38B_SAMALNAV_ACCELERATED_DEVELOPMENT_MASTER_ROADMAP.md).

## 6. Current barriers and authorization boundary

- The manuscript does not precisely specify five CARS criterion functions, score handling when evidence is missing, alternate weights, or travel-time/distance scoring edge cases.
- Current MO-GA differs materially from the manuscript fitness equations and lacks OSRM, CARS, price, weather, per-leg mode, commitment and required-transfer constraints.
- Circuit-based optimization is explicitly rejected by the current manual adapter; circuit discovery/admin route was not found.
- Weather provider exists, but self-healing rules are not wired. Alternative availability data remains operator-recorded, not confirmed live provider availability.
- Required D31A per-leg modes, fixed commitments, indeterminate feasibility and versioned Hive recovery need dedicated scoped implementation; this task grants none.
- RLS, table scope, audit/retention, security review, source freshness and sync conflict behavior are not established by read-only client source.
- Any code/test, schema, data, remote, deployment or manuscript action requires its own authorization. This analysis does not authorize Task 39 or any new coding task.

## 7. Closeout

The application comparison is based on source search/read, not test execution. No tests or builds were run. No SQL, database, Supabase or Hive application data was accessed. No source, test, manuscript, dependency, or configuration file was modified. The existing uncommitted worktree was preserved.
