# Task 17 — CARS Database Relationship and Evidence Source Discovery

**Project:** SamalNav  
**Branch:** `secondtemppush`  
**Inspection date:** 2026-11-18 (Asia/Manila)  
**Status:** Repository and checked-in database-artifact inspection completed. Deployed Supabase schema was **not** inspected in this session.

## 1. Executive summary

The repository contains enough local evidence to identify useful model shapes and several important schema gaps, but not enough to claim that any table, relationship, row population, or RLS rule matches the currently deployed project. The repository-configured app client points at a production Supabase project; no dashboard/browser session or Supabase/PostgreSQL read-only connector is available in this tool session. I did not use that configuration to connect. This avoids confusing the configured production project with the separate non-production project and avoids treating local artifacts as live evidence.

The most important findings are:

1. `activities.destination_id` and `destination_availability.destination_id` have destination foreign keys in the checked-in schema backup. Activities use free-text `category`, while a separate `categories` table is linked to `destinations.category_id`; no authoritative preference-to-activity ID relationship is represented or loaded by the Flutter application.
2. Tourist preferences are read from `tourist_details.preferred_categories`. A parallel `tourist_profiles` table with similar columns exists in the backup and migration 004, but the application service uses `tourist_details`. Neither schema artifact supplies an explicit preference-confirmation field; the current service correctly returns preferences as unconfirmed.
3. The backup stores destination ratings and prices with zero defaults. Those values cannot by themselves distinguish real zero from defaults. Rating provenance/freshness columns and price currency/unit/source metadata are absent from that backup. Task 16's app-side validators preserve this uncertainty.
4. `reviews` in the backup references both a destination and optionally an establishment. The application review service filters `reviews` by `establishment_id`; it does not calculate a public destination rating. Static sample reviews are not a verified data source.
5. A `weather_cache` relation exists only in local schema evidence with condition, multiplier, temperature, humidity and `updated_at`; the application does not query it. It does not document forecast coverage or a provider/source contract. The app has a separate injectable OpenWeatherMap raw forecast service.
6. There is no activity model/service or production CARS assessment source adapter in the inspected Flutter code. `PreparedCarsRecommendationProvider` remains injectable, and the default provider is deliberately unavailable.

No code, SQL, migration, database, policy, credential, or production change was made. No SQL was executed and no Supabase project was accessed.

## 2. Evidence classes and live-inspection boundary

| Evidence class | Sources inspected | What it establishes | What it does not establish |
|---|---|---|---|
| Repository implementation | Dart services/models/screens/tests under `lib/` and `test/` | Current client queries, parser contracts, provider interfaces, fallback and no-score behavior | Deployed table definitions, records, successful PostgREST access, RLS outcomes, or provider operation |
| Local schema/migration evidence | `supabase/backup/schema.sql`, `supabase/migrations/*.sql` | What the checked-in backup and migration text declare | Which migration ran, current deployed schema, migration history, current row population, or live policies |
| Prior owner-supplied evidence | H-series reconciliation records and Task 16 report | Findings previously summarized from owner-provided outputs, where explicitly labeled | Independent current verification; raw outputs not present in those summaries; completeness of unrelated CARS source tables |
| Deployed schema/data evidence | None obtained in Task 17 | Nothing | All actual production and non-production schema, relationship, population, and RLS questions remain open |

The repository contains `supabase/remote_schema_baseline.sql`, but it is **0 bytes** and provides no baseline. The app's checked-in Supabase URL is configured for the production project; this was not used to connect. The current task does not give a live project reference distinct from the application configuration, and the available tools do not provide Supabase Dashboard or SQL Editor access. The owner has dashboard access, but that dashboard session is not available to this agent. I therefore did not run queries or inspect representative records. No permissions were bypassed.

## 3. Repository data-access architecture

- `lib/main.dart` initializes `Supabase` with the repository configuration and the client anon key. No service-role client was found in the application path reviewed.
- `DestinationService.getAll()` performs `.from('destinations').select().order('name')`, maps each row with `DestinationRecord.fromJson(... source: database)`, filters active destinations, and falls back to bundled records when no rows are returned or the query throws. A fallback record is not evidence of a live destination or verified public rating.
- `TouristPlanningProfileService` reads and writes the current authenticated user's `tourist_details` row. It explicitly keeps `preferencesConfirmed: false`; no confirmation field is represented in its current model/service.
- `EstablishmentService.getReviews(establishmentId)` queries `reviews` joined to `profiles` and filters by `establishment_id`. Its average-rating helper reads `stars` for that establishment and returns `0` for an empty list. This is not a destination-rating adapter and its empty-list zero must not be used as destination evidence.
- No direct Flutter queries to `activities`, `categories`, `destination_availability`, or `weather_cache` were found. There is no `Activity` model in `lib/models/` and no activity repository/service.
- `CarsRecommendationAssessmentSource` is an injection boundary, not a database adapter. The default `UnavailableCarsRecommendationProvider` does not produce recommendations. The assessment preparer retains evidence with null scores when no approved scoring policy is provided.
- `OpenWeatherMapService` is a separate injectable raw-data HTTP boundary. It accepts supplied coordinates/dates and does not use `weather_cache` or produce a CARS weather score.

## 4. Local table and relationship inventory

The following describes checked-in SQL only. It is not a deployed-schema assertion.

| Relation | Local backup fields relevant to CARS | Local relationship evidence | Flutter use found |
|---|---|---|---|
| `destinations` | `id`, `name`, `lat`, `lng`, `category`, `category_id`, `rating`, `rating_average`, `entrance_fee`, `average_stay_minutes`, `is_active`, `is_verified`, `status`, `establishment_id`, `owner_id` | `category_id → categories.id`; `establishment_id → establishments.id`; `owner_id → profiles.id` | `DestinationService` selects rows. `DestinationRecord` parses rating, category, location, entrance-fee amount and visit duration. |
| `activities` | `id`, `destination_id`, optional `establishment_id`, `name`, free-text `category`, `price`, `duration_minutes`, age/friendliness/capacity fields, `is_active` | `destination_id → destinations.id` (`ON DELETE CASCADE`); optional establishment FK (`SET NULL`). No `category_id` FK appears in backup. | No activity read service/model found. |
| `categories` | `id`, unique `name`, `icon`, `created_at` | Destination FK exists; no activity or preference FK appears in backup. | No category catalog service found. |
| `tourist_details` | `user_id`, budget bounds, daily hours, trip days, `preferred_categories text[]`, optional current coordinates, `travel_mode`, group counts | Unique `user_id → profiles.id` (`ON DELETE CASCADE`) in backup | Read/write target of `TouristPlanningProfileService`; no preference confirmation field in model. |
| `tourist_profiles` | Similar budget, time, preference, coordinate and mode fields | Separate unique `user_id → profiles.id` in backup | No Flutter query found. Migration 004 creates this table; it does not establish that the app's `tourist_details` contract is deployed. |
| `destination_availability` | `destination_id`, `date`, `open_time`, `close_time`, `is_available` | `destination_id → destinations.id`; backup unique key on `(destination_id, date)` | No Flutter query found. No capacity, seasonal source, or availability freshness/provider contract is represented. |
| `reviews` | `destination_id`, `tourist_id`, optional `establishment_id`, `stars`, text, creation/helpful counts | Destination and tourist FKs; optional establishment FK | Establishment service filters by establishment ID. No destination aggregate query/service found. |
| `weather_cache` | `destination_id`, `condition`, `multiplier`, `temperature`, `humidity`, `updated_at` | `destination_id → destinations.id`; multiplier check [0,1] in backup | No Flutter query found. App has separate OpenWeatherMap raw forecast service. |
| `establishment_reviews` | Defined in migration 002 as an establishment-specific review relation | Migration text links reviews to establishments/tourists | Application `EstablishmentService` instead queries `reviews`; exact deployed relation choice is unresolved. |

### Local artifact differences to resolve against live catalog

- `supabase/backup/schema.sql` contains both `tourist_details` and `tourist_profiles`; migration 004 creates `tourist_profiles`, while the current app service uses `tourist_details`.
- Migration 002 declares `establishment_reviews`; the application reads `reviews`, and the backup contains `reviews` plus `reviews_legacy`.
- The destination backup has both `rating` and `rating_average`, each defaulting to zero. `DestinationRecord` prefers `rating_average` when that key exists and reads optional verification/source/retrieval/freshness keys if present; those metadata fields are absent from the checked-in backup definition.
- `categories.name`, `destinations.category`, `destinations.category_id`, `activities.category`, and `tourist_details.preferred_categories` are different representations. No checked-in FK or approved taxonomy contract proves they share IDs or meanings.
- `activities.price` and `destinations.entrance_fee` are non-null with zero defaults in the backup. Neither has currency, pricing unit, source, verification, or freshness metadata there.

## 5. Six-criterion evidence source matrix

| Criterion | Evidence available in repository | Missing relationship/data contract | Reusable implementation / status |
|---|---|---|---|
| Interest and Activity Match | Tourist preference text array in `tourist_details`; destination text/category ID; activity free-text category and destination ID in local backup. Current matcher accepts authoritative ID mappings and explicitly represents unsupported/incomplete activity evidence. | Canonical preference IDs, activity category IDs, authoritative crosswalk, active activity loader and complete per-destination relationships. Similar text labels are not sufficient. | Reuse `CarsInterestActivityMatcher` and `CarsRecommendationAssessmentSource`; implement no DB adapter until taxonomy/source is verified. **Blocked by live schema/source evidence.** |
| Public Destination Rating | Destination row has rating fields in local backup. Destination parser/preparer retains range, verification, source and freshness states. Review table has a destination FK in local backup. | Verified public source and aggregation policy, actual-vs-default-zero semantics, source/freshness metadata and deployed relation contract. No separate public rating provider exists. | Reuse `DestinationRecord`, preparer, provider and review evidence display. Task 16 tightened public display to current provenance. Do not treat establishment average or static review fixtures as a destination score. **Source unverified.** |
| Weather Suitability | Injectable OpenWeatherMap service retrieves raw forecast points for supplied location/date range, including provider/retrieval metadata. Backup `weather_cache` has a coarse condition/multiplier row. | No app cache adapter, forecast coverage semantics in cache, activity weather requirements, or approved classifier/aggregation/normalization. | Reuse `OpenWeatherMapService` and `CarsAssessmentInputPreparer`; leave raw evidence unscored. **Provider boundary exists; scoring/source approval missing.** |
| Budget Compatibility | `TripConfiguration` supports explicit budget basis/currency; typed assessor requires item price currency/unit/source/verification/freshness and cost-component coverage. Backup has zero-default entrance/activity prices and tourist budget bounds. | Deployed verified prices, currency, pricing units, age/group rates, required cost components, package inclusions and per-candidate budget allocation. | Reuse `CarsBudgetAssessmentService`; destination/activities raw prices cannot be treated as verified totals. Food, accommodation, transport and package evidence not connected. **Data contract absent.** |
| Travel Distance Suitability | Destination lat/lng and tourist-selected origin represented locally; Haversine geometry and injectable `TravelRoutingProvider` exist. | Current coordinate completeness/quality; configured route provider; mode-specific route contract; verified water connections and date-valid schedules. No per-leg route data source. | Reuse `CarsTravelAssessmentService`; label straight-line geometry separately. Never call MO-GA approximation road-route evidence. **Provider absent.** |
| Available Travel Time Compatibility | Trip model has daily available hours/dates; destination average stay and activity duration fields exist in local backup. Travel assessment can collect provider-backed travel duration. | Verified visit durations, activity applicability, complete travel and transfer time, source/freshness, and approved candidate-level time allocation. Existing route assessment does not include visit or transfer duration. | Reuse trip/travel assessments; keep result insufficient until all required components and policy are provided. **Incomplete.** |

## 6. Confirmed and unverified findings

### Confirmed in checked-in repository

- Current branch is `secondtemppush`; working tree contains the existing Tasks 06–16 untracked documents and modified CARS files/tests. They were preserved.
- `supabase/remote_schema_baseline.sql` is empty (0 bytes).
- Destination loading is a direct `destinations` select with cache/fallback behavior; no activity/category/availability/weather-cache query was found in the client service search.
- The current tourist preference service uses `tourist_details` and never infers confirmation from saved values.
- No deployed public destination rating aggregation/source adapter, activity repository, category mapping catalog, route provider implementation, or weather-cache adapter was found.
- The CARS production default remains unavailable; raw assessment evidence does not by itself produce scores.

### Confirmed only in local backup/migration artifacts

- Backup table columns, default declarations, FK/unique/check definitions summarized above.
- The migration text contains additional/alternate tourist profile and establishment review table declarations.
- The backup's public review table connects review rows to a destination and optionally an establishment; this does not establish current production use or which review subset should aggregate to a destination rating.

### Not verified in deployed database

- Correct current project target/reference for this manual inspection; table presence and exact column types; applied migration set; FK/index/constraint names and actions; RLS and grants; actual row population; category/ID consistency; default-vs-real rating/price zeros; duplicate/orphan records; preference/category/activity completeness; review publication/moderation; availability dates; weather cache freshness; and successful client access.
- No representative application rows were read. No personal data was copied or inspected.

## 7. Criterion-specific technical resolutions

1. **Activities and taxonomy:** after live catalog confirmation, provide an owner-approved, versioned preference/activity mapping and a read-only activity source adapter. If current deployed `activities.category` is text-only, do not join by similar labels. Minimal schema improvement, if approved, is a canonical category identifier relationship plus migration/coverage plan; exact table/FK choice requires live evidence and owner approval.
2. **Ratings:** first identify whether public destination ratings are stored in destination aggregates or derived from public destination-linked reviews. Approve publication/moderation inclusion, deduplication, scale and actual-zero semantics; require source and update/retrieval/freshness metadata. Do not use `EstablishmentService.getAverageRating()` or the empty-list `0` as CARS evidence.
3. **Weather:** either define a cache contract with location, forecast interval, provider, units, fetched time and coverage, or use the existing raw forecast service. Separately approve activity requirements and classifier. Do not interpret `weather_cache.multiplier` as an approved score.
4. **Prices:** supply source-verified cost items with currency, unit, applicability, amount, verification, source, freshness and explicit package inclusions. Current default-zero amount fields cannot safely feed totals. Add group-rate fields only after an approved pricing-unit contract.
5. **Availability:** confirm date and local timezone semantics, source/owner, freshness and status vocabulary. Adapt the existing date relation only if live catalog and product policy match; no query currently consumes it.
6. **Routing/time:** connect a selected/injected route provider supporting requested mode, endpoints and itinerary date with source/freshness. Keep water legs separate. Add verified visit and transfer durations for any complete time result. Do not use geometric estimates as actual network routes.
7. **Tourist profile:** inspect live `tourist_details` vs `tourist_profiles`, unique keys and RLS. Do not merge/remove either table until usage, row counts, external callers and owner decision are known. Add preference confirmation only through a separately reviewed schema/model contract; current service must stay unconfirmed without it.

All schema additions above are **proposals only**, not authorized changes.

## 8. Priority-based roadmap

### Priority 1 — Existing evidence that can already be reused

- Preserve the destination row/parser and strict rating evidence handling from Task 16.
- Reuse typed CARS assessment, no-score provider and review evidence transport.
- Reuse preference profile loading while keeping saved values unconfirmed.
- Reuse raw weather service and travel/budget assessment boundaries without assigning numeric CARS scores.

No existing local relation is sufficiently verified to serve as a production CARS evidence adapter today.

### Priority 2 — Confirm relationships and gaps

- Obtain sanitized live catalog output for target relations, columns/defaults, PK/unique/check/FK/index, policies and grants.
- Confirm whether destination activities/categories and profile relations exist and how they join.
- Review aggregate/duplicate/orphan data only through owner-authorized, bounded queries with no personal values.

### Priority 3 — External evidence contracts

- Identify authoritative public rating/aggregation source, operational weather source, mode-aware routing source, and maintained water-transfer source.
- Declare verified pricing, group rates, availability, source, unit and freshness contracts.

### Priority 4 — Research and scoring dependencies

- Resolve owner-approved formulas, parameters, missing/not-applicable behavior, budget/time allocation and thresholds before turning any raw evidence into scores.
- Preserve six weights and no-redistribution behavior; do not activate CARS while any required policy is unresolved.

### Priority 5 — Integration and readiness

- Implement separately injectable source adapters only after source contracts and deployed schema are confirmed.
- Add synthetic tests for identity, duplicates, null/defaults, stale/incomplete data and RLS-denial behavior.
- Keep the production provider unavailable until implementation acceptance, security/RLS review and separate activation approval.

## 9. Inspection performed

- Confirmed current branch and `git status --short` before work. Existing modified/untracked files were preserved.
- Inspected Supabase bootstrap/configuration architecture without using it to connect; destination, tourist preference and establishment review queries; CARS provider/preparer; weather, travel and budget boundaries; relevant destination/profile/review models; local backup and migrations 002/004; Tasks 15–16 records.
- Searched the Flutter source for reads of activities, categories, availability, reviews and weather cache.
- Checked `supabase/remote_schema_baseline.sql` file size: 0 bytes.
- No tests were run for this repository-only inventory. No SQL statement was executed and no Supabase project was accessed.

## 10. Remaining blockers and next task

The central blocker is the absence of sanitized, current, owner-run catalog evidence for the correct project. Without it, reported local schema relationships remain hypotheses about deployment. The repository app configuration points to production, while the approved non-production project is separate; neither target was contacted. The correct environment and exact project reference must be verified by the owner in the dashboard before catalog results are labeled.

Other blockers are the missing preference/activity taxonomy, unknown rating authority and aggregate policy, zero-default price semantics, undeclared group/cost units, missing configured routing and water schedules, incomplete visit/transfer duration inputs, no app availability/weather-cache adapters, and unresolved scoring policies/owner approvals.

**Recommended Task 18:** owner-run read-only catalog evidence intake for the explicitly selected SamalNav project: export sanitized definitions and relationship/constraint/policy results for the CARS target relations, accompanied by project label/reference and query timestamp. Keep row-level data out of the intake unless a separately approved, aggregate-only quality query is essential. Then reconcile only those catalog results with this repository inventory before proposing any adapter or schema change.

## 11. Closeout

- **Created:** `docs/TASK_17_CARS_DATABASE_RELATIONSHIP_AND_EVIDENCE_SOURCE_DISCOVERY.md`
- **Files modified:** this report only.
- **Live Supabase inspection:** not performed; available tools did not provide the authorized Dashboard/SQL Editor or a project-verifiable read-only database connector. No live schema/data claim is made.
- **Database changes / SQL execution:** none.
- **CARS activation:** not authorized and not performed.
