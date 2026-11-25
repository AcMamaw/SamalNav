# Task 07 — CARS Blocker Resolution and Final Technical Contract Audit

**Status:** Repository-only audit and implementation specification. No application source, tests, SQL, configuration, Supabase project, or database object was modified or accessed. Task 06 remains the policy baseline; unresolved matters below are not silently decided.

## 1. Executive summary

The repository implements useful CARS boundaries but not a production-ready recommendation pipeline. It has six criteria, an injectable assessment source and scoring-policy interface, typed evidence availability, separate eligibility evaluation, and an engine that refuses to rank an otherwise eligible candidate missing any required score. The default recommendation provider deliberately reports unavailable. These are safe foundations.

Critical contract gaps remain:

- The requested score scale is 0–1, while engine validation, injected-policy validation, explanation text, UI labels, and tests currently use 0–100.
- No production-approved scoring policy or survey-weight configuration was found. Test weights are explicitly synthetic.
- No verified source contract was found for all six criteria. A local backup schema and application query do not prove deployed schema or populated production data.
- The review screen receives ranking and destination records, but the system-generated page does not pass the provider package's `assessmentInputs`; source, freshness, evidence states, and rule references therefore do not reach that screen through the current constructor.
- Whole-trip mode and selected trip origin are represented, but per-leg mode, mode-unfixed optimizer recommendations, GPS-default origin provenance, and return-to-origin intent are not represented in `TripConfiguration`.
- Budget candidate allocation, candidate-level time allocation, distance normalization, weather classification, eligibility vocabulary, and not-applicable behavior remain unresolved.

**Readiness: BLOCKED.** The only implementation safe without these decisions is continued maintenance of typed evidence and unavailable/insufficient-data handling. Do not enable production ranking or describe system-generated CARS recommendations as live.

## 2. Scope, method, and evidence limits

Reviewed Task 06, the current CARS models/algorithms/provider, rating and destination models/services, weather service, trip/draft models, MO-GA adapter/engine, recommendation and planning screens, local schema backup, and relevant CARS/system-generated tests. No Task 02–05 files were located by repository search; their supplied conversation outputs were treated as design references through Task 06.

Evidence distinctions used here:

- **Repository implementation:** behavior directly visible in checked-in Dart and tests.
- **Local schema artifact:** a checked-in SQL backup definition; not proof of deployed structure or current contents.
- **Application query:** code requesting a relation/fields; not proof the request succeeds in production.
- **Deployed schema / populated production data:** **UNVERIFIED**. No Supabase access was made and no live evidence was supplied for this audit.

No line numbers are cited; symbols and file paths identify evidence without inventing locations.

## 3. Repository evidence inventory

| Area | Repository evidence | What it establishes | What it does not establish |
|---|---|---|---|
| CARS criteria and engine | `CarsCriterion`, `CarsCandidate`, `CarsCandidateResult`; `CarsRecommendationEngine` in `lib/models/cars_models.dart`, `lib/algorithms/cars_engine.dart` | Six enum criteria; exact six weights required and must sum to 1; eligibility separate; missing scores produce `insufficientData`; deterministic ordering | Production weights, approved criterion formulas, production source completeness, deployed authorization |
| Score contract | Engine and preparer validate [0,100]; UI says `/100`; `test/cars_engine_test.dart` uses synthetic 0–100 values and test-only weights | Current implementation contract is 0–100 | Task 06 target 0–1 is not implemented |
| Evidence preparation | `CarsAssessmentInputPreparer`, `CarsCriterionScoringPolicyApplier` in `lib/algorithms/cars_assessment_input_preparer.dart` | States include available, insufficient, unavailable, invalid, stale, unsupported, notApplicable; no score without injected rule reference; non-available evidence cannot be scored | Complete provenance preservation through UI; approved policy; no universal distinction between absent source and missing field in every upstream type |
| Provider | `CarsRecommendationProvider`, `UnavailableCarsRecommendationProvider`, `PreparedCarsRecommendationProvider` in `lib/services/cars_recommendation_provider.dart` | Injectable source → preparer → optional policy → engine; duplicate/empty destination IDs rejected; no-policy means no numeric scores | Production source adapter and verified production policy; absence of external callers/data |
| System-generated screen flow | `SystemGeneratedPlanningPage._loadRecommendations` passes `ranking`, `destinations`, `trip`, and run reference into `CarsRecommendationReviewPage` | Tourist review follows provider completion; loading/error/empty handling exists | Provider package `assessmentInputs` is not passed to review page; criterion evidence details are not rendered there |
| Review and draft | `CarsRecommendationReviewPage`; `SystemGeneratedDraftBuilder` | Tourist selects ranked destinations; multi-day assignments required; builder validates active verified database destination and preserves CARS run provenance | Prepared per-criterion evidence/source snapshot is not carried into draft; scores are not used to establish verified evidence by themselves |
| Preference matching | `CarsInterestActivityMatcher` and tests | Exact identifier mapping boundary; no mapping bundled; empty preference, unsupported IDs, unavailable activity categories, matched/no-match are distinguishable | Authoritative complete mapping catalog or mapping version |
| Rating | `DestinationRecord` parser/availableRating and preparer; rating tests | Missing/null and invalid values can be retained as unavailable/invalid; verified/source/freshness checks are required by preparer; fallback records rejected | Authoritative rating source, public-vs-internal meaning, deployed scale/default semantics, reliable source/freshness data |
| Weather | `OpenWeatherMapService`, `WeatherForecastResult`, tests | Injectable HTTP service retrieves raw OpenWeatherMap 5-day/3-hour forecast; records requested/provider location, units, date coverage, retrieval time; no CARS score | Activity-specific requirements/classifier, suitable temporal granularity for every trip date, provider data completeness for arbitrary itinerary duration |
| Budget | `CarsBudgetAssessmentService`, `BudgetCostItem`, `PriceInfo`, tests | Typed component/unit/currency/verification/source/freshness and group-count inputs; incomplete evidence is surfaced; no CARS score formula | Verified source costs, candidate budget allocation, age-dependent rates, general availability of all cost components |
| Distance/time | `CarsTravelAssessmentService`, `TravelRoutingProvider`, tests | Coordinate validation, Haversine straight-line geometry, injected route estimates with source/freshness/mode/date; selected origin and one trip-wide nullable mode; water transfer is not replaced with land route | Configured production routing provider, per-leg modes, candidate-level distance normalization, visit/transfer-inclusive candidate time |
| Origin and modes | `TripOrigin`, `TripConfiguration` in `lib/models/itinerary_draft.dart` | Explicit origin coordinates/label; optional `travelMode`; no live GPS provenance; no per-leg mode or return-to-origin flag | GPS-first permission and fallback workflow; mode-recommendation contract; return leg intent |
| MO-GA | `MogaEngine`, `ManualSelectionMogaAdapter`, tests | Existing optimizer has destination sequence and origin-aware initial-leg evaluation; objectives remain distance, stops fitting time, visit/travel time variation; mode is not an optimizer dimension in the inspected adapter | Approved mode recommendation provider, verified road/water route semantics, return-to-origin option in trip contract |
| Local SQL backup | `supabase/backup/schema.sql` and `data.sql` | A local historical schema artifact contains `destinations.rating`, `rating_average`, `entrance_fee`, categories, activities, reviews, `destination_availability`, `weather_cache`, and tourist preference tables | Deployed schema, live rows, rating defaults' actual effects, authoritative category mapping, current provenance or freshness |
| Destination service | `lib/services/destination_service.dart` queries `destinations`; also contains bundled fallback destination literals with ratings and fees | Application attempts a destination query and has local bundled fallback records | Query success, current values, verified ratings/costs; fallback literals are not verified recommendations |
| Review services | `lib/services/establishment_service.dart` queries establishment reviews; plan UI separately notes review entries do not provide a verified public average | Review records are used in existing establishment/destination UI flows | An authoritative destination-wide public rating aggregate suitable for CARS |

## 4. D-03 through D-16 resolution matrix

Statuses are limited to the Task 07 vocabulary. Multiple statuses may apply.

| Decision | Status | Finding and exact blocker |
|---|---|---|
| D-03 Interest/activity matching | **RESOLVED BY EXISTING IMPLEMENTATION; REQUIRES EXTERNAL DATA; BLOCKED BY MISSING INFORMATION** | Matcher safely distinguishes no preference, missing mapping, unsupported preference IDs, missing activity categories, match, and genuine no-match once an authoritative mapping is injected. No authoritative mapping/catalog/version or complete activity coverage was found. Empty preference is not incomplete, but ranking behavior is unresolved under D-14. Need approved mapping source/version and coverage contract. |
| D-04 Public rating | **RESOLVED BY EXISTING IMPLEMENTATION; REQUIRES EXTERNAL DATA; BLOCKED BY MISSING INFORMATION** | Parser preserves null/invalid ratings and preparer requires verified rating, source, retrieval time, freshness, and rejects fallback. Local backup has `rating numeric(3,1) DEFAULT 0 NOT NULL` and `rating_average numeric(3,2) DEFAULT 0 NOT NULL`; this raises a zero/default provenance ambiguity. Reviews table and review UI do not prove a trusted public aggregate. Need authoritative source/meaning, scale, whether zero is an actual observation versus default, freshness contract, and populated data evidence. |
| D-05 Weather | **RESOLVED BY EXISTING IMPLEMENTATION; REQUIRES EXTERNAL DATA; BLOCKED BY MISSING INFORMATION** | Service returns provenance-bearing raw 5-day/3-hour forecast and coverage states; no score classifier exists. Trip duration allows up to 30 days, so provider horizon may not cover requested dates. No destination-activity weather requirements or approved threshold/aggregation/normalization found. Need classifier policy and date/activity evidence; otherwise unscored. |
| D-06 Budget | **RESOLVED BY EXISTING IMPLEMENTATION; REQUIRES EXTERNAL DATA; BLOCKED BY MISSING INFORMATION** | Cost assessment validates units, currencies, group counts, source/freshness and package coverage; no reciprocal CARS formula or destination allocation exists. `TripConfiguration` has min/max, optional basis/currency/group counts. Existing destination entrance fee is adapted as unverified without currency/unit/source/freshness. Need owner-approved candidate allocation, zero-budget rule, cost applicability and verified cost records. |
| D-07 Distance | **RESOLVED BY EXISTING IMPLEMENTATION; REQUIRES EXTERNAL DATA; BLOCKED BY MISSING INFORMATION** | Straight-line Haversine geometry is explicitly not a route. Injected `TravelRoutingProvider` can return mode/date-specific route distance and duration with source/freshness; no production provider or distance score normalization/limit found. Need approved score policy and verified provider coverage, including mode and water distinction. |
| D-08 Available time | **RESOLVED BY EXISTING IMPLEMENTATION; REQUIRES EXTERNAL DATA; BLOCKED BY MISSING INFORMATION** | Available hours/day and destination average visit minutes exist; route provider can supply travel duration. The travel assessment compares route travel only and expressly excludes visit/wait/meal/transfer durations. No candidate time allocation or reciprocal score exists. Need candidate allowance allocation, duration scope and sources, transfer policy, and over-limit treatment. |
| D-09 GPS default/manual fallback | **NOT IMPLEMENTED; BLOCKED BY MISSING INFORMATION** | `TripOrigin` is manually supplied coordinate/label and comments say live GPS is not modeled. Travel assessment uses this origin; no origin provenance. Map page uses Geolocator for map location, but planner integration into trip origin was not found. Need product consent/default, permission denied/forever, disabled service, timeout/error, manual fallback, and provenance behavior approved. |
| D-10 Whole-trip/per-leg mode | **NOT IMPLEMENTED; BLOCKED BY MISSING INFORMATION** | `TripConfiguration.travelMode` represents one nullable whole-trip mode. `CarsTravelAssessmentService` passes it to each leg. No per-leg mode map or MO-GA mode recommendation interface found. Need smallest typed mode contract and define how unspecified mode yields candidate evidence; CARS must remain non-selector. |
| D-11 Verified water transport | **RESOLVED BY EXISTING IMPLEMENTATION; REQUIRES EXTERNAL DATA** | `RequiredTransfer` identifies ferry/boat intent; travel assessment marks such legs unavailable and explicitly avoids land substitution. No connection directory, schedule, route identity, provider, duration, source, or freshness evidence found. Need authoritative date-specific water-transfer source contract. |
| D-12 Eligibility/suitability | **RESOLVED BY EXISTING IMPLEMENTATION; BLOCKED BY MISSING INFORMATION** | Evaluator gates dataset presence, accepted approval status, required accreditation, and declared supported/required suitability-code sets. Accepted status sets are injected, not canonical; traveler-specific restriction definitions and authoritative fields are not established. Need approved vocabulary, source, missing-status semantics, and suitability requirements. |
| D-13 Mixed-group requirements | **RESOLVED BY EXISTING IMPLEMENTATION; REQUIRES EXTERNAL DATA; BLOCKED BY MISSING INFORMATION** | Trip model stores total, children, elders and derives adults; budget assessor can apply explicit pricing units where group data and item rates permit. No verified age definitions/rates or complete price source. Group/vehicle/room/activity quantities are not invented. Need price source per unit and policy for counts and age classes. |
| D-14 Not-applicable criteria | **BLOCKED BY MISSING INFORMATION** | No option selected. A: block ranking preserves six-term consistency and no redistribution, but can prevent ranking when preference is absent. B: fixed treatment preserves denominator only if an owner-defined value/semantics is approved; 0/1 cannot be assumed. C: explicit applicability domain is coherent if objective entry conditions are defined, but narrows recommendation coverage and may exclude otherwise eligible trips. Owner must approve exactly one rule (or a fully specified alternative) and examples. |
| D-15 Evidence states | **RESOLVED BY EXISTING IMPLEMENTATION; BLOCKED BY MISSING INFORMATION** | Preparer has available, insufficientData, unavailable, invalid, stale, unsupported, notApplicable. Verified zero is a value, not a status, and rating/cost types can retain zero distinctly when provenance allows. Upstream models do not uniformly distinguish “missing field” from “source unavailable”; add explicit source/field reason only if approved contract requires it. Need define missing-vs-unavailable granularity and not-applicable ranking consequence. |
| D-16 Return-to-origin | **NOT IMPLEMENTED; BLOCKED BY MISSING INFORMATION** | `TripConfiguration` has no return flag; inspected MOGA constructor accepts starting point, but adapter invokes optimizer over destination sequences and no return choice is passed. Need tourist choice default/requiredness and typed trip/draft persistence contract; add the return leg to route evaluation only after policy definition. Does not change objectives. |

### D-14 alternative comparison

| Option | Mathematical consistency | Fairness and survey interpretation | Missing-data behavior | UX and testability |
|---|---|---|---|---|
| A. Not-applicable blocks ranking | Keeps fixed six-term weighted formula undefined until every term exists | Avoids inventing contribution, but may make no-preference trips unrankable; survey weight meaning stays intact | Safest and consistent with current engine's all-six requirement | Clear insufficient-data message; straightforward tests; can be restrictive |
| B. Fixed approved treatment | Preserves six weights only if the treatment is explicitly specified and its semantic contribution is accepted | Could bias rankings if treatment value encodes a preference; changes interpretation of criterion | Must remain distinct from missing/invalid and cannot be silent | Testable after value, scope, and rationale are approved; risk of hidden policy if poorly explained |
| C. Applicability domain | Formula applies only to a predefined set of trips/candidates for which all six criteria apply | Preserves formula inside domain but changes who can receive recommendations | Outside-domain candidates are explicitly not scoreable; no weight redistribution | Testable with explicit domain predicates; requires eligibility/product UX and may reduce coverage |

No option is selected in this audit.

## 5. Cross-architecture contract audit

| Transition | Current input → output | Validation / missing handling | Provenance and information-loss finding | Status |
|---|---|---|---|---|
| Tourist profile → trip configuration | `TouristPlanningProfileService` and `TouristPlanningProfileTripAdapter` → `TripConfiguration` | Adapter uses confirmed defaults and preserves current trip fields; it does not map unverified preferred category IDs to CARS interest IDs or replace selected origin with profile current coordinates | Preference snapshot/confirmation context is not attached to the later result contract; origin remains explicit/manual in trip model | Implemented bounded adapter; GPS/per-leg/return gaps remain |
| Trip → evidence source | `CarsRecommendationAssessmentSource.loadAssessments(trip)` → assessment records | Interface injectable; provider catches duplicate/empty destination IDs but source success/completeness is provider responsibility | No concrete verified all-six production source adapter established | Interface only; production source blocked |
| Evidence → preparation | `CarsAssessmentPreparationInput` → six `CarsPreparedCriterionInput`s | Validates rating state/provenance, preference confirmation/mapping, weather coverage, budget status, route availability/freshness | Prepared object preserves evidence objects in map; some evidence states are coarser than raw missing causes | Implemented, with policy/data gaps |
| Preparation → scoring policy | Prepared criterion → policy reference and nullable score | No policy leaves scores null; only available evidence is passed; malformed range output is marked invalid | Rule reference exists in prepared record; no built-in production policy. Current accepted range is 0–100 | Safe boundary; target scale mismatch |
| Candidate → eligibility | `CarsRecommendationEligibilityInput` → `CarsEligibilityResult` | Dataset, approval, accreditation and code requirements checked separately | Eligibility inputs currently not embedded in raw prepared evidence; reasons retained in result | Engine exists; canonical source/status values unresolved |
| Scores → engine | `CarsCandidate` → ranked/excluded results | All six scores required; missing goes insufficientData; invalid provided score throws; no redistribution | Raw evidence is not carried into engine result, only candidate scores and eligibility | Safe incomplete handling; 0–100 contract conflicts with Task 06 |
| Provider package → planning page → review | `CarsRecommendationPackage` has ranking, destinations, run reference, `assessmentInputs`; page forwards ranking, destinations, trip, reference | Empty package and thrown errors shown; review screen restricts selection to database, active, verified destination records | **Information loss:** `assessmentInputs` is not passed to review. The screen cannot show per-score evidence source/freshness/status/rule reference. `CarsCandidateResult` has score/contributions/explanation but no source metadata. Preference snapshot is explicitly not in the review result contract. | Requires contract/UI change before evidence-transparent scoring |
| Tourist review → draft | selected destination IDs/days → `ItineraryDraft` | Builder requires ranked, verified active database records and day assignments; no MO-GA runs here | Preserves destination identity, selected day, CARS run ID/provenance; does not snapshot prepared assessment evidence or per-criterion source metadata | Implemented review boundary; evidence snapshot gap |
| Explicit draft action → MO-GA | `ItineraryDraft` → adapter → `MogaEngine`/route result | Draft validation; selected stops mapped to indices; multi-day assignments preserved | Origin passed; global configured average speed and Haversine approximation in existing MO-GA; no per-leg chosen mode, route provider, return flag, or water schedule input at adapter boundary | Explicit optimizer boundary exists; requested mode/return additions not implemented |

The review screen currently presents result values in `/100`, criterion numbers and an engine explanation. Assessment provenance can be inspected in the `CarsPreparedAssessmentInputs` map returned by the provider, but it is not reachable from the current review page arguments. This is a concrete data handoff gap, separate from policy approval.

## 6. Score-scale migration impact

Task 06 target is [0,1]; all inspected current consumers are [0,100]. Required coordinated migration map:

| Consumer | Current dependency | Required change after approval |
|---|---|---|
| `CarsRecommendationEngine` | Validates `0..100`; contributions and total on same scale; explanation prints `/100` | Validate `0..1`; contributions and total remain [0,1]; explain as normalized score without `/100` |
| `CarsCriterionScoringPolicyApplier` | Accepts policy output through 100 | Enforce finite [0,1] and preserve rule version/reference |
| `CarsCandidateResult` / `CarsPreparedCriterionInput` | Plain `double`; no type-level scale marker | Document/enforce normalized contract; consider policy version metadata (no serialization currently located) |
| `CarsRecommendationReviewPage` | Displays total `/100`; criterion one decimal and contribution | Display 0–1 semantics consistently, retain unavailable state and provenance/limitations |
| Sorting | Descending numeric sort | Ordering remains valid under scale change if all candidates use same normalized scale; mixed legacy/new results must not be compared |
| Tests | `cars_engine_test.dart`, `cars_assessment_input_preparer_test.dart`, `cars_recommendation_provider_test.dart` use 0–100 fixture scores | Convert fixtures/expected values and add exact formula, endpoints, finite/range and no-mixed-scale tests |
| Provider/configuration | Weight injection currently generic; no serialization found | Install only approved survey weights; reject unversioned or legacy scale policy outputs |
| Persistence/export | No CARS score persistence path found in inspected workflow; draft retains run reference, not scores | Re-audit any later persistence/analytics before scale migration; no claim of no external consumer |

Do not implement a scale migration until approval and all consumers/tests can move atomically. No source serialization contract was found in the inspected CARS flow, but external consumers are outside repository evidence.

## 7. Supabase and source verification matrix

| Source | Local evidence | Application usage | Required fields for CARS | Missing provenance / readiness |
|---|---|---|---|---|
| Destinations | Local backup `destinations` has IDs, name/location, coordinates, categories, ratings, entrance fees, status/verification fields; `DestinationRecord` maps some of these | `DestinationService` queries `destinations`; fallback literals also exist | Stable ID, active/approval/verification state, valid coordinates, category/activity association, visit duration, rating/cost evidence | Local only; fallback cannot be recommendation evidence. Deployed schema/data **UNVERIFIED**. |
| Activities | Local backup has activity records/category/check fields; application provider has no established end-to-end CARS activity source | No direct activity catalog call was found in searched CARS/application flow | Stable activity/category IDs, destination association, availability, source and applicable weather/cost requirements | No complete coverage/version contract; deployed and populated data **UNVERIFIED**. |
| Categories | Local backup contains `categories` and `category_id` relationships; profile model stores `preferred_categories` text values | Preference/profile services load/save preferences; no authoritative category-to-activity adapter | Canonical ID namespace and versioned mapping between preference IDs and activity IDs | Names are not a mapping. Mapping catalog/source unavailable; production data **UNVERIFIED**. |
| Reviews/ratings | Local backup has `reviews`, `reviews_legacy`, destination `rating`/`rating_average`; review service queries review rows | Establishment review service and UI; destination parser supports verification/provenance keys | Public destination aggregate definition, scale, actual-observation/default distinction, source, timestamp, freshness | Internal review rows do not establish public aggregate. No authoritative source contract; deployed data **UNVERIFIED**. |
| Weather | No verified local cache contract relied on for CARS; typed OpenWeatherMap raw model/service | Injectable HTTP to OpenWeatherMap 5-day/3-hour forecast; no CARS classifier | Destination/visit coordinates and dates, complete forecast coverage, units, conditions, retrieval and forecast timestamps, activity requirements | Forecast horizon limited relative to 30-day trip input; requirements/classifier missing. External evidence needed. |
| Pricing | Local backup includes destination entrance fee and activity price fields; `PriceInfo` and cost item models preserve uncertainty | Destination parsing plus budget assessor; entrance fee adapter is explicitly unverified absent currency/unit/source/freshness | Amount, currency, unit, group applicability/quantity, source, verification, freshness, package inclusion, required component status | Verified source and complete units not established. Deployed schema/data **UNVERIFIED**. |
| Destination availability | Local backup includes `destination_availability`; reviewed app does not establish its use as CARS date-specific eligibility source | Destination records expose active/verified; separate availability integration not established | Date-specific opening/closure/eligibility source and freshness if used | No approved eligibility requirement/source. Deployed data **UNVERIFIED**. |
| Tourist preferences | Local backup includes tourist preference tables/`preferred_categories`; model/service tracks saved profile and confirmed state contract | Profile service and trip adapter; unverified category IDs withheld from CARS | Authenticated owner, explicit confirmed status, stable preference IDs, mapping version | No authoritative activity mapping or production completeness evidence. |
| Routing | Local destination coordinates and MO-GA geometry implementation; `TravelRoutingProvider` abstraction | CARS travel assessor accepts injected provider; no configured provider established | Mode-specific route distance/time, route type, date, origin, freshness/source, water segments | Interface is not an integration. No verified network distance or water timetable. |
| Water transport | `RequiredTransfer` captures a requested ferry/boat transfer; no route dataset found | Travel assessor marks required water leg unavailable and never substitutes land routing | Connection identity, endpoints, schedule/date validity, duration, source, retrieval/freshness | No verified connection or schedule source. |

No production or non-production Supabase project was accessed. Every deployed schema, current privilege/RLS effect, and populated production value remains outside this repository-only audit.

## 8. Final implementation dependency map

### A. Owner decisions

- Approve all six score policies and versioned rule references; especially D-05 weather, D-06 budget, D-07 distance, D-08 time.
- Decide D-14 not-applicable behavior and define whether no selected preference blocks ranking.
- Approve eligibility status vocabulary and traveler suitability requirements (D-12).
- Confirm weight provenance and target 0–1 scale migration.
- Define GPS/manual fallback, per-leg mode and unspecified mode semantics, return choice, and zero-budget/zero-time behavior.

### B. External data dependencies

- Authoritative preference/activity mapping and complete destination activity coverage.
- Rating authority, aggregate meaning, scale, freshness, and true-zero provenance.
- Weather forecast coverage and activity-specific requirements.
- Verified prices with currency/unit, group applicability, source/freshness, and package relationships.
- Mode-specific route provider and verified water transport schedule.
- Date-specific destination availability and canonical eligibility evidence if required.

### C. Model and architecture dependencies

- Carry assessment evidence/provenance/rule reference into the review surface, not just provider-internal map.
- Decide whether review-selected draft/history needs an immutable evidence snapshot (privacy/retention review required).
- Represent GPS/manual origin provenance, per-leg modes, return-to-origin, and unknown mode without accidental defaults.
- Preserve target score scale consistently in model, provider, engine, UI and any future serialization.

### D. Algorithm dependencies

- Approve formula/parameters for weather and distance; approve candidate budget/time allocation and reciprocal formula semantics.
- Resolve not-applicable handling without silent zero/one or reweighting.
- Clarify candidate time feasibility versus score and eligibility.

### E. UI and workflow dependencies

- Show evidence state, source/freshness, rule reference, and limitations on recommendation review.
- Explain insufficient, ineligible, and unavailable outcomes separately.
- Keep tourist review/selection before explicit MO-GA and preserve the unavailable state if data/policy is not ready.
- Request GPS permission and provide manual fallback only under approved behavior.

### F. Testing dependencies

- Approved formula examples and threshold/classifier boundary vectors.
- Synthetic source/provider fixtures proving provenance, stale, malformed, and incomplete cases.
- Whole-trip/per-leg/return and road/water routing fixtures.
- Review handoff tests proving evidence is not lost and no score is fabricated.
- Manual/circuit regressions; full app analysis and test suite after implementation.

Dependencies A and B precede D; C must be settled before adapter/UI work; E and F follow stable contracts. Source evidence can be gathered in parallel with owner policy decisions, but no scoring implementation should begin until both rule and input contract are testable.

## 9. Implementation readiness gates

Every gate below is currently **FAIL** for production scoring/activation unless noted. A Dart interface or local SQL backup alone cannot pass a gate.

| # | Gate | Result | Evidence required to pass |
|---:|---|---|---|
| 1 | Six criteria and weights verified | **PARTIAL** | Criteria and Task 06 weights are recorded; confirm survey source/owner provenance before release configuration. |
| 2 | 0–1 contract approved and migration impact identified | **FAIL** | Owner approval and coordinated engine/preparer/UI/test migration. Impact identified in Section 6. |
| 3 | All six scoring policies approved | **FAIL** | Versioned policy, evidence domains, examples, and boundaries for each criterion. |
| 4 | Not-applicable treatment approved | **FAIL** | Explicit D-14 choice and testable rule. |
| 5 | Eligibility rules and vocabulary approved | **FAIL** | Authoritative status sets, suitability semantics, source and missing-state behavior. |
| 6 | All source contracts verified | **FAIL** | Verified source definitions and populated-value evidence for every required criterion/eligibility input. |
| 7 | Provenance/freshness supported | **FAIL** | Source-specific timestamps, verification, units and freshness thresholds; demonstrated through adapters. |
| 8 | GPS/manual origin behavior finalized | **FAIL** | Consent, permission denial/unavailability, fallback and provenance contract. |
| 9 | Whole-trip/per-leg mode contract finalized | **FAIL** | Typed trip/leg mode representation and behavior when mode is unfixed. |
| 10 | Water transport evidence contract verified | **FAIL** | Authoritative connection, schedule, duration, route identity, freshness and supported endpoints. |
| 11 | Candidate budget/time allocation defined | **FAIL** | Approved allocation rules, units, group treatment, time duration scope, zero/over-limit behavior. |
| 12 | Return-to-origin input contract defined | **FAIL** | Explicit tourist choice representation and MO-GA route semantics. |
| 13 | Evidence preservation through review verified | **FAIL** | Pass `assessmentInputs` or equivalent reviewed evidence contract; tests show no metadata loss. |
| 14 | Automated acceptance tests specified | **PASS — specified only** | Task 06 tests plus this audit's source/handoff/mode requirements; execution still required after implementation. |
| 15 | Manual/circuit regression risks assessed | **PASS — assessed only** | Keep CARS optional; add regression tests proving manual/circuit independence. No execution yet. |
| 16 | Production activation/security approval separate | **PASS — gate defined** | Separate explicit production and security approval after implementation/testing; no activation authorized here. |

## 10. Required future files and tests

Likely code targets after blockers close:

- `lib/algorithms/cars_engine.dart` — coordinated 0–1 migration.
- `lib/models/cars_models.dart` — score/evidence/rule-reference output contract.
- `lib/algorithms/cars_assessment_input_preparer.dart` — approved policy application and provenance states.
- `lib/services/cars_recommendation_provider.dart` — verified adapters, approved weights/policies, preserve evidence output.
- `lib/algorithms/cars_interest_activity_matcher.dart` — inject authoritative versioned mapping.
- `lib/algorithms/cars_budget_assessment.dart` — candidate allocation evidence only after policy approval.
- `lib/algorithms/cars_travel_assessment.dart` — candidate route evidence and explicit per-leg mode support if approved.
- `lib/models/itinerary_draft.dart` — only if origin provenance, per-leg modes, or return choice are approved.
- `lib/screens/tourist_screens/system_generated_planning_page.dart` and `cars_recommendation_review_page.dart` — evidence handoff, limitations, score display, and workflow messaging.
- `lib/services/destination_service.dart` or a new verified source adapter — exact source contract to be selected after data verification.
- A new scoring-policy file may be created only after policy approval; no placeholder production formula.

Tests to extend include `test/cars_engine_test.dart`, `test/cars_assessment_input_preparer_test.dart`, `test/cars_recommendation_provider_test.dart`, `test/cars_interest_activity_matcher_test.dart`, `test/cars_budget_assessment_test.dart`, `test/cars_travel_assessment_test.dart`, `test/cars_recommendation_review_page_test.dart`, `test/system_generated_planning_page_test.dart`, plus MO-GA adapter and manual/circuit workflow regression tests as relevant. Tests should use synthetic fixtures, never claim live Supabase access.

## 11. Git and working-tree safety record

- **Branch:** `secondtemppush`.
- **Initial `git status --short`:** `?? docs/TASK_06_CARS_FINAL_POLICY_DECISIONS_AND_IMPLEMENTATION_AUTHORIZATION.md`.
- **Initial tracked and staged diff summaries:** no changes reported by `git diff --stat` or `git diff --cached --stat`.
- The existing untracked Task 06 document was read and preserved. This audit created only the requested Task 07 document; it did not clean, reset, restore, stash, stage, or commit any files.
- `git diff --check` applies to tracked diffs; the new untracked Markdown document was visually/source reviewed. No source or test files were edited.

## 12. Final determination

**CARS is not ready for controlled scoring implementation or production activation.** The score scale target is specified but not migrated; five criterion scoring areas and not-applicable behavior remain policy-blocked; authoritative source contracts and deployed/populated data remain unverified; and review currently drops prepared evidence metadata. GPS origin, per-leg mode, water routing, return-to-origin, candidate budget/time semantics, and eligibility vocabulary need explicit contracts.

The future implementation may proceed only after the failed gates have evidence and explicit decisions, followed by separately reviewed implementation authorization. Production activation and any Supabase/schema work require independent authorization. Until then, keep the safe unavailable behavior and do not represent fallback destinations, partial evidence, or test-policy scores as live recommendations.
