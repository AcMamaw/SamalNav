# Task 36 â€” SamalNav Transportation Catalog Integration Compatibility Review

**Project:** SAMAL NAV
**Review type:** Documentation and read-only repository inspection
**Status:** Integration analysis only; implementation authorization is **not granted**.
**Evidence date:** 24 November 2026 (Asia/Manila)

## 1. Executive summary

Task 35 introduced an immutable local transportation catalog and a focused codec test suite in `lib/models/transport_catalog.dart` and `test/transport_catalog_test.dart`. The catalog is not currently imported or consumed by application code. The prior Task 35 verification reported 20 focused tests passed; no integration tests were run for this review.

The application still has three separate, older representations:

1. A profile-level `String travelMode`, stored as `tourist_details.travel_mode`, with a five-value preference list.
2. A trip-wide nullable `PreferredTravelMode` enum, also containing five modes.
3. `RequiredTransferKind { ferry, boat }` with directed destination endpoints but no per-leg catalog identifier, schedule, or availability evidence.

The Task 35 catalog can serve as the canonical vocabulary for future integration, but it does not yet make the current screens or services catalog-backed. Its capability flags are metadata, not application enforcement: `selectableMode` checks `isActive` only and does not check which workflow capability is requested. Current UI and the CARS route assessor still use the old enum. Hive stores that enumâ€™s `.name`, so existing saved drafts use values such as `publicTransportation`, whereas the profile/database-facing legacy value is `public transportation`.

**Recommendation:** Do not wire all workflows at once. The smallest reasonable first integration is a separately authorized profile-preference compatibility slice, after confirming nullable profile storage compatibility. It should display active catalog modes with `profilePreference == true`, retain unknown or inactive saved values visibly without substitution, and write stable catalog IDs. It must not claim that a preference selects a trip leg or proves service availability. A later itinerary-leg slice is required before the remaining seven modes can be selected on individual legs.

## 2. Evidence and scope

Authoritative specifications inspected:

- `docs/TASK_33A_SAMALNAV_FINAL_TECHNICAL_CONTRACT_CLOSURE.md`
- `docs/TASK_34_SAMALNAV_BOUNDED_TRANSPORTATION_CATALOG_IMPLEMENTATION_AUTHORIZATION_REVIEW.md`
- `lib/models/transport_catalog.dart`
- `test/transport_catalog_test.dart`

The relevant current application models, services, screens, algorithms and tests were inspected read-only. No tests, analyzer, or build were run for Task 36. No Hive records, Supabase project, database, or network service was accessed. No source, test, or manuscript file was modified by this review.

The worktree already contained unrelated CARS edits, Task 06â€“35 documents, and an untracked manuscript directory. Those changes were preserved.

## 3. Existing transportation architecture

### 3.1 Catalog (Task 35)

`TransportCatalog.initial` defines the twelve stable IDs `walking`, `bicycle`, `motorcycle`, `car`, `public_transportation`, `jeepney`, `tricycle`, `multicab`, `van`, `bus`, `ferry`, and `boat`; seven categories; version fields; alias decoding; unknown mode preservation; historical label snapshots; and workflow capability values. The only production implementation is the model itself. A repository search found no other imports or references to `TransportCatalog`, `TransportModeReference`, or its APIs.

The catalog has no route, operator, schedule, fare, travel-time, or availability state. This is correct for the approved boundary: catalog recognition does not establish service availability. The codec recognizes the two approved public transportation aliases exactly and canonical IDs; it does not trim or case-fold.

`TransportModeReference.canSelectForNewUse` and `TransportCatalog.selectableMode` only test active status. A later workflow must additionally check the relevant `WorkflowCapabilities` field; otherwise, an active mode whose capability is false could be surfaced incorrectly. The initial policy sets `circuitPlanning` and `mogaRouteEvaluation` false for all entries while allowing profile preference, manual leg recording, and fixed commitment capture.

### 3.2 Profile preference

`lib/models/tourist_planning_profile.dart` defines `TouristPlanningProfile.travelMode` as a required `String`. JSON reads/writes `travel_mode`; validation compares the value against a caller-supplied `supportedTravelModes` set. This keeps the value open-ended at the model level but does not itself use or validate against the new catalog.

`lib/screens/tourist_screens/planning_preferences_page.dart` has a local `_travelModes` list with five values: `walking`, `bicycle`, `motorcycle`, `car`, and `public transportation`. It preserves a saved unsupported value in the form as an explicit â€œSaved value: â€¦ (unsupported)â€ option and allow-lists that current value during validation. It has no UI choices for the other seven catalog entries.

`lib/services/tourist_planning_profile_service.dart` fetches and updates the profile as a string-valued record. Its current implementation marks profiles unconfirmed because the deployed contract has no confirmation field. The selection/persistence path does not prove a new catalog value is accepted by the deployed schema or any remote policy; no live schema was checked.

`lib/services/tourist_planning_profile_trip_adapter.dart` maps only the five legacy profile values into `PreferredTravelMode`. For any of the seven other catalog modes or any unknown ID, `_travelMode` returns null. The adapter only applies confirmed preferences to an unset trip mode, so an existing explicit trip mode wins; an unmapped preference is not substituted with another mode.

### 3.3 Itinerary and transfer representation

`lib/models/itinerary_draft.dart` defines `PreferredTravelMode` with the same five Dart enum values. `TripConfiguration.travelMode` is nullable but applies to the trip as a whole. There is no general `ItineraryLeg` type or per-leg mode assignment. `RequiredTransferKind { ferry, boat }` and `RequiredTransfer` separately hold a directed from/to destination pair and kind.

The transfer representation is narrower than the catalogâ€™s ferry/boat modes. It has no catalog ID, departure/arrival schedule, timezone, operator, user-confirmation label, or availability state. It cannot represent fixed ferry/boat booking details required by D31A commitments.

`lib/screens/tourist_screens/plan_page.dart` presents an optional trip-wide dropdown for the existing enum. It does not provide per-leg choices. `lib/algorithms/manual_selection_workflow.dart` builds/reorders destination stops grouped by day, not transportation legs.

### 3.4 Serialization and compatibility

`lib/services/local_itinerary_draft_store.dart` writes `TripConfiguration.travelMode?.name` into the v1 Hive JSON record and reads it with `_enumByName(PreferredTravelMode.values, ...)`. Therefore, the public transport enum is stored locally as `publicTransportation`, while the profile value is `public transportation`. The Task 35 catalog explicitly decodes both strings to `public_transportation`, but the existing Hive store does not call it.

The v1 store uses the box `samal_nav_local_itinerary_drafts_v1`, `formatVersion = 1`, and rejects a different record format without rewriting the record. Unknown trip mode strings are not supported by the enum parser and would produce a format error; no catalog-backed unknown value or historical label snapshot is persisted in the current trip model.

No Hive records were opened or inspected. These are conclusions from serializer source only.

## 4. Catalog compatibility findings

| Existing concept | Current representation | Catalog relationship | Compatibility issue |
|---|---|---|---|
| Profile preference | Required `String`; five UI options | Catalog contains twelve mode IDs, two legacy aliases | Current selector omits seven entries; nullable profile decision is not reflected in the Dart model. |
| Trip transportation | Nullable five-value enum | First four IDs map directly; `publicTransportation` needs explicit value mapping; seven modes have no enum member | Cannot preserve or select all catalog modes in trip configuration. |
| Water transfer | Separate `RequiredTransferKind` plus from/to IDs | `ferry`/`boat` IDs are catalog items with directed endpoints required | Similar names do not make the model interchangeable; transfer includes endpoints, catalog mode is only vocabulary. |
| Historic Hive mode | Enum `.name` string | Catalog can decode `publicTransportation` and canonical IDs | Store does not use catalog codec; any field-shape change needs a versioned migration plan. |
| Unknown mode | Profile can display/preserve a current raw string; Hive enum parser rejects unknown names | `TransportModeReference` preserves unknown raw ID and optional label | Compatibility exists in the new codec only; old app workflows do not round-trip unknown Hive modes. |
| Inactive mode | No catalog or inactive state in existing profile/trip model | Catalog can decode inactive entry and `selectableMode` returns null | Integrations must preserve historical references while blocking new selection. |
| Availability | Route-provider assessment state, separate from mode values | Catalog intentionally has no availability field | Must remain a separate provider/evidence concern. |

Legacy identifier interpretation:

- Profile/database-facing known values: the five lower-case strings above, including `public transportation`.
- Current Hive encoding: Dart enum names, including `publicTransportation`; transfer kinds are `ferry` and `boat`.
- Catalog canonical IDs: snake_case, including `public_transportation`.
- Catalog approved aliases: `public transportation` and `publicTransportation`. It must not grow aliases by inferred case folding or trimming.

## 5. Profile integration requirements

Future profile work should:

1. Generate new selectable choices from `TransportCatalog.initial.modes` where `isActive` and `workflowCapabilities.profilePreference` are both true.
2. Keep saved unknown or inactive identifiers visible as historical values and avoid silently replacing them. Do not offer them as new choices.
3. Decode legacy profile strings through the catalog codec and emit canonical IDs only when the user makes an explicit save under an approved transition rule.
4. Keep profile preference distinct from an actual trip or leg selection. It may be an initial suggestion only where a later owner-approved flow supports that behavior; explicit trip/leg choices take precedence.
5. Reconcile the selected nullable profile preference requirement with the current required `String` model and confirm local schema contract compatibility before any production service integration. No remote schema was accessed here.
6. Preserve the existing fail-closed preference confirmation rule. The current service reports preferences unconfirmed; do not use catalog selection alone as confirmation or as CARS evidence.

Required future profile files and methods are listed in Section 9. Do not modify them under this review.

## 6. Itinerary-leg integration requirements

The selected architecture requires independent transportation on each leg. A future local model needs explicit ordered leg identity and endpoint references, a catalog mode reference, and a label snapshot. For water modes it must retain directed endpoint constraints and locally tourist-entered commitment schedule details where supplied. Catalog IDs and label snapshots describe the selected/historical mode; neither proves an external operator or service is confirmed.

Requirements before changing itinerary or Hive structures:

- Define how leg endpoints refer to adjacent itinerary entries, including trip origin and final destination semantics.
- Bind `ferry` and `boat` catalog values to the existing directed transfer concept without duplicate contradictory source-of-truth fields.
- Preserve unknown and inactive historical IDs and label snapshots through serialization; block new unsupported selections.
- Keep pre-booked details local and label them tourist-entered/unverified by SAMAL NAV. They are not reservations, tickets, payment records, or provider confirmations.
- Preserve strict D31A direction, adjacency, timing and fixed-commitment constraints. Existing `RequiredTransfer` does not carry the schedule or prove the constraint.
- Version any local serialization change and maintain a recoverable path for v1 Hive records. Do not infer fixed/planned/optional classifications for old records without evidence.

The existing Task 35 `TransportModeReference` can represent a stable mode ID and optional label snapshot in memory, but it is not included in `TripConfiguration`, `DraftStop`, `RequiredTransfer`, or the Hive JSON contract.

## 7. Workflow capability compatibility

| Workflow | Catalog capability | Current application behavior | Compatibility conclusion |
|---|---:|---|---|
| Profile preference | Enabled for all twelve | Profile UI exposes five; service persists a string; model is required/non-null | Partial only. Selector and nullable contract are not catalog-backed. |
| Manual leg selection/recording | Enabled for all twelve | Manual workflow selects and orders destinations; no per-leg transport editor/model | Capability describes permitted future recording, not current implemented UI. |
| Circuit transport evaluation | Disabled for all twelve | Circuit-based planning references exist in `ItineraryDraft`/`CircuitReference`; no circuit-specific screen file was found by targeted search; MO-GA adapter rejects circuit drafts | Keep existing circuit destination selection intact. Do not claim transport feasibility evaluation or enable this catalog capability. |
| MO-GA route evaluation | Disabled for all twelve | `MogaEngine` uses coordinate distance and average-speed time; adapter does not pass modes or transfers | No catalog mode may be treated as routed by MO-GA. Keep capability false and prevent silent mode substitution. |
| Fixed commitment capture | Enabled for all twelve | Existing transfer metadata captures only endpoints and ferry/boat kind; no scheduled protected commitment record or edit confirmation | Catalog permission is not proof that the required capture workflow exists. Local commitment model and constraints remain future work. |

The capability booleans are not enforced by the catalogâ€™s selection helper. A future picker must check both active state and its specific workflow capability. The initial values do not change any current workflow behavior by themselves.

## 8. MO-GA and CARS boundaries

### MO-GA

`lib/algorithms/moga_engine.dart` optimizes destination order and computes distance/time using geographic distance and an average speed. `ManualSelectionMogaAdapter.optimize` prepares selected stops for the engine and rejects `PlanningMethod.circuitBased`. Neither component receives catalog modes, per-leg selections, commitment classes, or verified route evidence. Its current estimates must not be relabeled as verified mode-specific travel times.

A future MO-GA integration must use only explicitly supported/evidence-backed modes; unsupported mode legs must remain unknown/indeterminate or be rejected with an explicit reason. It must never silently convert ferry/boat to land travel. D31A fixed commitment and planned activity invariants remain separate from catalog recognition.

### CARS

`lib/algorithms/cars_travel_assessment.dart` accepts the existing enum in `TravelRoutingProvider` and marks a recorded required ferry/boat leg unavailable when schedule/duration evidence is absent; it explicitly does not substitute a land route. Catalog inclusion must not make a provider support a mode or create route evidence. Unverified ratings, prices, preference state, or service availability remain outside any numerical CARS input unless separately approved and evidence-backed.

No CARS or MO-GA file was changed, and no assessment or route provider was run in this review.

## 9. Future file-level integration proposal

This is a sequencing proposal only. Every source/test path below needs a distinct implementation authorization before edits.

### 9.1 Profile integration

| File path | Current behavior | Proposed change | Dependencies | Required tests |
|---|---|---|---|---|
| `lib/models/tourist_planning_profile.dart` | Required string `travelMode`; reads/writes `travel_mode`; caller-provided validation set | Represent nullable preference as required by prior decision; use catalog IDs for new selections; preserve legacy/unknown raw values on read | Local approved nullability and wire-value contract; avoid assuming live schema | `test/tourist_planning_profile_service_test.dart`, new model codec cases |
| `lib/services/tourist_planning_profile_service.dart` | Selects/updates string-valued profile; all snapshots unconfirmed | Preserve nullable/raw catalog values through JSON boundary; never infer confirmation | Approved schema compatibility and existing unconfirmed preference policy | service parse/update/round-trip tests with legacy, canonical, unknown, null |
| `lib/screens/tourist_screens/planning_preferences_page.dart` | Local five-string list; displays unsupported saved string | Build active choices from catalog with profile capability; preserve unsupported/inactive saved value without offering it as a new choice | Profile model/service change; catalog UI label presentation | `test/planning_preferences_page_test.dart`: all twelve, active filtering, unknown retention, null clearing, no availability claim |
| `lib/services/tourist_planning_profile_trip_adapter.dart` | Switch maps five legacy strings to old enum; ignores other modes | Keep old trip choice precedence; explicitly avoid lossy substitution for catalog modes absent from trip/leg contract; later map only after target type supports them | Per-leg/trip type decision and preference-default semantics | Existing `system_generated_planning_page_test.dart` adapter precedence plus unknown/new modes |

### 9.2 Itinerary and Hive integration

| File path | Current behavior | Proposed change | Dependencies | Required tests |
|---|---|---|---|---|
| `lib/models/itinerary_draft.dart` | One nullable trip enum; transfer separate; no general leg, label snapshot, commitment class | Add typed leg mode references, ordered endpoints and protected commitment references; preserve trip-level legacy field only during a deliberate transition | Final local leg/commitment contract, D31A constraints, migration design | `test/itinerary_draft_test.dart`: per-leg mode, water direction/adjacency, unknown/inactive preservation |
| `lib/services/local_itinerary_draft_store.dart` | Hive v1 serializes enum `.name`, rejects other formats | Add versioned backward-compatible encoding/migration for leg IDs, label snapshots, commitments and unknown values; preserve original data and recovery behavior | D31A-18â€“21; format, journal, backup and recovery acceptance design | `test/local_itinerary_draft_store_test.dart`: v1 fixtures, aliases, unknowns, migration failure/recovery |
| `lib/screens/tourist_screens/plan_page.dart` | Single trip-wide dropdown; manual day/stop selection | Provide per-leg mode selection and explicit display of unsupported/inactive/unknown values without fallback | Model/store, catalog UI labels, mode capability checks | New widget tests for per-leg edits, persistence, explicit null, no substitution |
| `lib/algorithms/manual_selection_workflow.dart` | Builds and reorders destinations per day, preserving stop data | Preserve leg assignments and protected endpoints during manual reorder/edit | Per-leg model and D31A-05/17 rules | `test/manual_selection_workflow_test.dart`: leg remap, protected edit confirmation, block integrity |
| `test/itinerary_draft_test.dart`, `test/local_itinerary_draft_store_test.dart` | Test trip enum and transfer metadata | Add compatibility fixtures and leg/label/commitment round trips | Model and migration contract | Keep v1 records readable, unknown IDs round-trip, no invented default class |

### 9.3 Manual planning, circuit planning, MO-GA, and CARS integration

| File path | Current behavior | Proposed change | Dependencies | Required tests |
|---|---|---|---|---|
| `lib/algorithms/manual_selection_moga_adapter.dart` | Optimizes included destination stops; rejects circuit drafts; passes average speed, not mode/transfer evidence | Consume only supported per-leg route evidence; maintain protected blocks/commitments; leave unsupported modes Indeterminate; never substitute | MO-GA constraint design, evidence semantics, acceptance invariants | `test/manual_selection_moga_adapter_test.dart`: no mode loss, fixed transfer direction/adjacency, unsupported-mode behavior |
| `lib/algorithms/moga_engine.dart` | Permutation optimization over destination indexes; no catalog inputs | Add only after a separately approved algorithm design for leg modes, protected blocks and evidence states; retain deterministic constraint handling | D31A MO-GA decisions, verified input/evidence contract, performance/regression plan | `test/moga_engine_test.dart`: fixed/planned protection, optional exclusion, three-state feasibility |
| Circuit workflow files | `PlanningMethod.circuitBased` and circuit references exist; the adapter rejects circuit drafts; no dedicated circuit screen was found in targeted search | Identify actual circuit selection UI/data path before integration; preserve selection/grouping, but do not add transport feasibility while capability is false | Full circuit-path discovery; dedicated design and owner-approved workflow | Existing circuit tests plus new capability-disabled behavior; do not route through manual adapter |
| `lib/algorithms/cars_travel_assessment.dart` | Provider interface accepts old enum; required ferry/boat legs are unavailable without evidence | Only later adapt provider contract to catalog mode IDs when provider supports explicit modes and evidence provenance | Approved source/freshness policy; availability remains separate from catalog | `test/cars_travel_assessment_test.dart`: unsupported/unknown modes unavailable, water non-substitution |
| `lib/algorithms/cars_assessment_input_preparer.dart` and CARS models/providers | CARS gates preference evidence and evaluates separate recommendation criteria | No direct catalog scoring. Preserve verified evidence, confirmed-preference gates and missing-data behavior | Separate methodology/evidence approval if any change is proposed | Existing CARS tests remain regression gates; add proof catalog membership creates no score/evidence |

## 10. Migration and backward compatibility plan

This section describes requirements, not a migration execution plan or authorization.

1. Keep profile aliases separate from Hive enum-name values. Decode the exact supported values only; never trim or case-fold.
2. Read old profile values: map the known five directly through approved aliases/canonical IDs; preserve an unknown string rather than substituting.
3. Read old Hive values: explicitly bridge `walking`, `bicycle`, `motorcycle`, `car`, `publicTransportation` and null. Transfer `ferry`/`boat` remain separate directed transfer kinds until the new leg model deliberately unifies their representation.
4. For future generic legs, persist stable canonical `modeId` plus `labelSnapshot`. Unknown IDs and inactive known IDs must round-trip; do not offer them as new selections.
5. Do not infer itinerary commitment classes or schedules for old drafts that lack that data. Preserve legacy source values and mark unresolved classification only under the approved Hive migration contract.
6. Any change to the current v1 Hive payload requires the D31A-18â€“21 versioned, staged, recoverable migration behavior. Do not edit or open stored Hive data as part of this review.
7. New writes should emit canonical IDs after a deliberate versioned transition; historical alias/raw payloads must remain recoverable until conversion validation succeeds.

## 11. Acceptance-test plan for future integration

No integration tests were run for Task 36. A future implementation should add:

| Test group | Required acceptance behavior |
|---|---|
| Profile compatibility | All active modes with profile capability offered; profile null preserved; current explicit profile choice round-trips; unknown/inactive legacy value remains visible and is not substituted; confirmation remains independent. |
| Legacy identifiers | `public transportation` and `publicTransportation` decode exactly to `public_transportation`; canonical encoding emits only the canonical ID; near-miss capitalization/whitespace remains unknown. |
| Per-leg itinerary | Each adjacent endpoint pair owns its mode; label snapshot and catalog ID serialize; explicit trip/leg input wins over profile suggestion. |
| Unknown/inactive mode | Raw ID and historical label survive save/load; not selectable for new legs; feasibility is not marked available. |
| Water/fixed commitments | Ferry/boat retains direction, adjacency, entered schedule and local-only/unverified status; edit requires explicit action/confirmation; optimizer cannot delete, separate, reverse, reschedule, or replace it. |
| Capabilities | Pickers gate on active plus workflow-specific flag; false circuit/MO-GA flags prevent transport evaluation but do not disable existing circuit destination selection or manual destination selection. |
| Availability | Catalog membership does not instantiate a provider result; absent/stale/unverified route time remains unknown/indeterminate; no fabricated duration, fare or land substitute. |
| Hive backward compatibility | Representative v1 fixtures decode unchanged; v2 conversion preserves stops, trips and unknown values; interrupted migration retains recoverable originals; retry is idempotent. |
| Workflow regression | Manual day grouping, circuit selection/grouping, generated draft review and existing CARS behavior remain intact. No server reservation, payment or itinerary persistence is introduced. |

Existing inspected regression files include `test/planning_preferences_page_test.dart`, `test/tourist_planning_profile_service_test.dart`, `test/system_generated_planning_page_test.dart`, `test/itinerary_draft_test.dart`, `test/local_itinerary_draft_store_test.dart`, `test/manual_selection_workflow_test.dart`, `test/manual_selection_moga_adapter_test.dart`, `test/moga_engine_test.dart`, and `test/cars_travel_assessment_test.dart`. Their existence is not evidence that the future integration behavior is covered.

## 12. Remaining blockers and recommended next implementation task

### Blockers

- The profile model remains required/non-null despite the selected nullable preference direction; confirm approved storage compatibility before profile UI integration.
- Current five-value `PreferredTravelMode` cannot represent seven catalog modes or independently selected leg modes.
- No general per-leg mode, endpoint, or historical label snapshot exists in the itinerary model.
- `RequiredTransfer` is not a schedule-bearing fixed commitment and has no explicit binding to a catalog `TransportModeReference`.
- Existing Hive v1 serialization has no catalog codec, unknown enum support, or new leg records; migration/recovery must be designed and authorized separately.
- Catalog capability fields are not yet applied by workflow pickers; helpers check active state only.
- Manual selection has no per-leg transport UI; circuit transport evaluation and MO-GA route evaluation are disabled by the catalog capability policy.
- No approved authoritative source makes catalog values into route availability or verified duration evidence. CARS/MO-GA must remain fail-closed for unknown support.
- No app integration is authorized by Task 36.

### Smallest safe future task

Prepare a separately authorized **Task 37 â€” Profile Preference Catalog Compatibility Slice** with narrowly scoped model/service/screen and tests. Have it read choices from the bundled catalog, preserve exact unknown/inactive saved values, write canonical IDs only on explicit user save, and keep the profile preference distinct from trip/leg instructions. Resolve nullable-field compatibility and confirmation semantics first. Do not modify Hive, itinerary legs, circuit planning, MO-GA, CARS route providers, or server schema in that first slice.

Because the trip adapter accepts only the legacy five-value enum, that first slice must not imply that every profile mode can be evaluated or automatically applied to an itinerary. Add generic per-leg selection only in a later task after the local leg and Hive migration contracts are approved.

## 13. Manuscript consistency

The manuscript file `manuscript/SAMAL NAV  (1).docx` was inspected read-only for topic-level references. Its affected material includes the scope/limitations and objectives discussing transportation, itinerary planning, circuits and MO-GA, plus methodology/system-description passages describing route calculation, travel-time assumptions, candidate itinerary generation, and optimization inputs.

Before a later manuscript revision, distinguish:

- **Implemented now:** the local catalog model/codec exists and its focused tests passed in Task 35; existing application UI and services still use legacy representations.
- **Not yet integrated:** catalog-backed profile choices, per-leg modes, multi-modal manual/circuit UI, catalog-aware Hive persistence, and catalog-aware MO-GA/CARS routing.
- **Not established:** actual service availability, operators, schedules, fares, or verified travel durations merely from catalog membership.

Do not describe those planned integrations as completed features. No manuscript content was changed.

## 14. Authorization and closeout

- Task 35 catalog implementation is a standalone local model/codec; application integration is not present.
- Task 35 focused tests previously passed (20/20); no tests were run for this read-only review.
- No application or test file was modified; no Hive data was opened or changed; no SQL, database, network, or Supabase operation was performed.
- No integration authorization is granted by this report.

**Final status: Integration remains unimplemented and requires a separate scoped authorization.**
