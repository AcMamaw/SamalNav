# Task 31A — Transportation Vocabulary and Profile Contract Audit

**Project:** SAMAL NAV
**Inspection:** Read-only repository review, 24 November 2026 (Asia/Manila)
**Status:** Findings and recommendations only. No Dart files, tests, SQL, migrations, database objects, or Supabase projects were changed or accessed.

## 1. Executive summary

The app has two distinct transportation concepts, but their boundaries and stored representations are not fully consistent:

1. **Profile travel preference:** `PlanningPreferencesPage` presents five string values: `walking`, `bicycle`, `motorcycle`, `car`, and `public transportation`. The profile model stores a non-null string `travelMode` in `travel_mode`; this conflicts with Task 30/D29-11, which selects a nullable profile preference.
2. **Trip-level choice:** itinerary planning has a nullable `PreferredTravelMode` enum with the same five concepts, plus a “Not specified” UI choice. This is a trip preference/input, but it is not per-leg transportation selection and current MO-GA does not route using that mode.
3. **Required water transfer:** `RequiredTransferKind` has `ferry` and `boat`, each tied to a directed pair of destination IDs. It is not an option in either travel-mode dropdown. The travel assessment recognizes a required ferry/boat leg and returns unavailable when schedule/duration evidence is absent, explicitly avoiding a substituted land route.

The main contract conflict is the duplicated representation of public transportation: profile/database-facing text uses `public transportation`, the Dart enum is `publicTransportation`, and Hive stores the enum `.name` (`publicTransportation`) while the adapter maps only the profile text form. This is currently bridged in code but leaves multiple persisted spellings. The profile UI has no “Not specified” option, although the selection field is nullable; the itinerary UI does.

**MO-GA limitation:** required transfer records are retained on `TripConfiguration` and Hive serialization, but `ManualSelectionMogaAdapter` does not pass them to `MogaEngine`. MO-GA optimizes geometric distance/time using an average speed and does not constrain a required ferry/boat edge to remain adjacent or schedule-feasible. Therefore the code preserves transfer metadata in the draft; it does **not** prove that an optimized route preserves the transfer as a fixed routing constraint. This is an implementation gap, not a resolved behavior.

The existing Tourist Planning Profile service deliberately reports profiles as unconfirmed because it has no persisted confirmation field in its current contract. The CARS assessment preparer blocks interest/activity scoring when preferences are unconfirmed. D29-09’s requested durable confirmation/reset contract is not yet implemented.

## 2. Transportation choices presented in the UI

### 2.1 Planning preferences screen

Source: `lib/screens/tourist_screens/planning_preferences_page.dart`

The static `_travelModes` list and “Preferred travel mode” dropdown present these exact values as both stored strings and visible labels:

| Current label | Current profile/API string | Nullable in the UI? | Meaning supported by source |
|---|---|---:|---|
| `walking` | `walking` | No explicit unset option | Profile preference only; this screen does not create a walking route leg. |
| `bicycle` | `bicycle` | No explicit unset option | Profile preference only. |
| `motorcycle` | `motorcycle` | No explicit unset option | Profile preference only. |
| `car` | `car` | No explicit unset option | Profile preference only. |
| `public transportation` | `public transportation` | No explicit unset option | Profile preference only; not a specific bus/van/ferry service. |

The state field `_selectedTravelMode` is nullable, but the dropdown’s listed choices do not include a null/“Not specified” item. During save, the screen uses `_selectedTravelMode ?? current.travelMode`; because the model currently requires a travel mode, the screen cannot clear a prior value through this control. Unsupported saved strings are shown as a separate “Saved value: … (unsupported)” dropdown item rather than silently mapped to a supported mode.

The “Review and save preferences” dialog is an explicit user confirmation step in the screen flow, but the service reports the saved profile as unconfirmed. This is intentional given the current persistence contract; it is not durable D29-09 confirmation.

### 2.2 Itinerary planning screen

Source: `lib/screens/tourist_screens/plan_page.dart`, `_travelMode` dropdown near the trip configuration controls.

This dropdown presents “Preferred travel mode (optional)” and includes “Not specified” (`null`) plus every `PreferredTravelMode` enum value. Visible enum labels are currently the same lower-case strings listed above. The trip’s mode is nullable, serialized into local Hive draft state, and remains distinct from the profile field in the data model.

`plan_page.dart` also states that MO-GA retains trip origin and mode but uses its existing coordinate-based distance estimate and average speed for route calculation. Therefore selecting car, walking, or public transportation does not currently select a corresponding route calculation in MO-GA.

### 2.3 Other transport-related UI

- `lib/screens/auth_screens/mainlanding.dart` has a “Ferry Schedules” feature/marketing card and mentions barges and boats. This is not a selectable planner mode and does not establish a live schedule source or routing contract.
- `lib/screens/tourist_screens/map_page.dart` references a map tile layer named `World_Transportation`; this is map presentation, not a trip-mode option or routing provider.
- Repository search found no other transportation-mode dropdown labels in `lib/`. It found transport references in CARS travel assessment and budget component definitions, which are data concepts rather than user-selectable transport modes.

## 3. Enums, constants, mappings, and validation

### 3.1 Current canonical-looking trip enum

`lib/models/itinerary_draft.dart` declares:

```text
PreferredTravelMode: walking, bicycle, motorcycle, car, publicTransportation
```

Its `PreferredTravelModeValue.value` mapping returns the strings:

```text
walking, bicycle, motorcycle, car, public transportation
```

`BudgetBasis` and `PlanningMethod` are also declared in that file but are not transport modes.

### 3.2 Transfer enum

The same file declares:

```text
RequiredTransferKind: ferry, boat
```

`RequiredTransfer` contains `fromDestinationId`, `toDestinationId`, and a required kind. It models a directed required transfer between a pair of destination IDs. It does not model a schedule, operator, departure time, duration, ticket, price, or verification/source record.

### 3.3 Profile travel mode and validation

`lib/models/tourist_planning_profile.dart` stores `travelMode` as a required `String`, parses `travel_mode` with `_requiredString`, and serializes that exact string. Its validation policy requires the caller to supply a non-empty `supportedTravelModes` set; it does not define an approved global vocabulary itself. Validation rejects a value not in the supplied set. Other relevant checks include:

- budget minimum/maximum must be finite and nonnegative, with maximum not below minimum;
- available hours/day and trip duration must satisfy caller-supplied maxima;
- latitude/longitude must be both present or both absent and within coordinate bounds;
- `numberOfTourists`, if supplied, must be positive; child and elder counts must be nonnegative;
- child/elder counts require a total; their sum may not exceed total.

This profile model is stricter than the selected D29-11 nullable mode direction and the nullable profile facts direction in D29-10. It has no explicit adults field, preference-confirmation boolean, or confirmation timestamp.

### 3.4 Trip group validation

`TripConfiguration` in `lib/models/itinerary_draft.dart` stores nullable total, child, and elder counts. `adultsCount` returns `total - children - elders` only when all three values exist and are nonnegative with subgroup sum no greater than total. The trip validator allows a zero total (it rejects only negative totals), requires a total if child/elder counts are present, and checks child+elder sum does not exceed total. It does not store an independent adult count.

`planning_preferences_page.dart` collects total group size, children, and elders; it does not collect adult count. Its displayed validation message is derived from total less child and elder counts when those fields are valid.

The profile validator requires total to be positive when supplied, while the trip validator permits zero. This is a concrete validation inconsistency. Neither code path defines age cutoffs or pricing classes, and none should be inferred from these labels.

### 3.5 Persistence and conversion

- Profile database field: `tourist_details.travel_mode` string.
- Profile model/service adapter: recognizes the profile string `public transportation` and maps it to enum `PreferredTravelMode.publicTransportation`.
- Local Hive serialization: `lib/services/local_itinerary_draft_store.dart` stores `trip.travelMode?.name`; the public-transport enum therefore serializes as `publicTransportation` (camel case, no space). It serializes transfer kind using enum values (`ferry`, `boat`).
- Hive decoding parses enum names. The profile adapter separately maps wire strings. Both currently work in their respective paths but represent the same mode in different ways.
- Unknown profile mode strings map to `null` in `TouristPlanningProfileTripAdapter`; the adapter applies confirmed profile defaults only where the current trip field is absent, and it preserves existing required transfers.

## 4. Trip choice, routing, and water-transfer behavior

### 4.1 Profile preference is not trip instruction

The profile screen’s field describes a preferred mode. `TouristPlanningProfileTripAdapter.applyConfirmedDefaults` copies it to `TripConfiguration.travelMode` only if the profile snapshot is confirmed, the current trip has no mode, and the profile string is recognized. It preserves the current trip’s explicit mode and transfer list. This precedence is appropriate for keeping an explicitly configured trip choice over a profile default.

However, once copied, the same `TripConfiguration.travelMode` field is used as one trip-wide mode for all assessed legs. There is no per-leg mode representation in `TripConfiguration`, `RequiredTransfer`, or the route adapter. D29-11 also says a profile preference should be distinct from actual trip choices; code currently has separate fields, but the adapter intentionally uses a confirmed preference as a default. Owner confirmation is needed on whether that behavior remains acceptable or whether the tourist must select the trip mode explicitly every time.

### 4.2 Routing support

`lib/algorithms/cars_travel_assessment.dart` defines `TravelRoutingProvider.supports(PreferredTravelMode)` and passes the selected trip mode to a provider for ordinary route legs. A mode-specific route is unavailable if:

- trip mode is null;
- no configured provider exists or it does not support the mode;
- origin/date/coordinates are unavailable or invalid.

There is no concrete routing implementation established by this audit; an interface or test fake does not prove operational road, transit, or water routing.

`MogaEngine` in `lib/algorithms/moga_engine.dart` accepts destinations, visit durations, available tour hours, an average speed, and optional starting point. It calculates coordinate-based distance and time using that average speed. It has no mode, transfer, schedule, or per-leg transport inputs. `ManualSelectionMogaAdapter` constructs this engine without passing trip mode or required transfers.

### 4.3 Required water transfers and MO-GA

Current behavior, separated by layer:

1. `TripConfiguration.requiredTransfers` is immutable as a list and stores the requested ferry/boat pair.
2. `LocalItineraryDraftStore` serializes and restores transfer endpoint IDs and enum kind. Existing tests inspect persistence/transfer round-tripping.
3. CARS travel assessment compares adjacent itinerary stop IDs with required transfer endpoint IDs. For a required ferry/boat leg, it returns an unavailable estimate with a message that the schedule and duration are unavailable and that no land route was substituted.
4. MO-GA does not consume `requiredTransfers`. It may reorder the stops without enforcing water-edge adjacency or route feasibility. The adapter returns route order separately; the draft’s transfer list remains present, but no result-level invariant is shown that the transfer endpoints remain consecutive in the optimized route.

Accordingly, the current evidence supports **metadata preservation and safe non-substitution in the CARS travel assessor**, not **MO-GA fixed-transfer preservation**. This is a blocker against claiming the required water transfer is an optimizer constraint. It needs a separately authorized design and implementation with invariant tests. No water transfer can be scored or treated as operationally routable without a verified schedule/provider contract.

## 5. Compatibility conflicts and unsupported/duplicated representations

| Conflict/gap | Evidence | Compatibility effect |
|---|---|---|
| Profile mode required vs owner-selected nullable preference | `TouristPlanningProfile.travelMode` is `String` and required in JSON/constructor; UI has no null choice. | Cannot represent “no preference” in profile editing or round-trip it. This conflicts with D29-11 and nullable-profile direction. |
| Three public-transit representations | UI/API value `public transportation`; enum identifier `publicTransportation`; Hive enum-name serialization `publicTransportation`. | Database and Hive contracts differ; normalization is implicit in adapter code. Future stored values need an explicit canonical wire mapping and legacy decode. |
| Same five modes duplicated in separate sources | Preference page owns a string list; trip enum owns another set; adapter owns a third mapping. | Changes can drift. A single typed vocabulary/wire codec should drive both UI lists and mapping. |
| Profile preference may become trip mode by default | Adapter applies confirmed profile value to an unset trip. | This is a defaulting behavior rather than explicit per-trip selection. Confirm with owner under D29-11. Explicit trip input currently wins. |
| One selected trip mode for all ordinary legs | `TripConfiguration.travelMode` is one nullable value; no per-leg mode object. | Mixed land modes across legs cannot be represented. D29-11’s “preserve explicit land/water constraints” requires separate transfer records but does not define general per-leg modes in this local trip model. |
| Ferry/boat are transfer kinds, not modes | `RequiredTransferKind` models endpoint pair; no schedule/operator/duration. | Do not place ferry/boat in the five-value travel-mode enum as if they were provider-supported routable modes. |
| MO-GA uses generic speed geometry | `MogaEngine` has no transport/transfer input; adapter does not forward them. | Distance/time outputs are not mode-specific and cannot enforce ferry/water constraints. |
| Group zero acceptance differs | Profile validation rejects supplied total `<= 0`; trip validation rejects `< 0`, allowing 0. | Same group facts can pass one boundary and fail another. Owner-selected detailed count contract needs one consistent rule. |
| Group adults are derived, not stored | `TripConfiguration.adultsCount` requires all three counts; profile stores only total/children/elders. | Cannot distinguish “adult count not supplied” from a derived residual when partial subgroup data exists; owner must settle completeness/derivation. |
| Confirmation is UI-only for persistence | Service always returns `preferencesConfirmed: false`; profile JSON has no confirmation fields. | D29-09 persistence/reset behavior is not implementable against the current client contract; CARS remains blocked from using these profile interests. |

## 6. Profile confirmation and CARS dependency

### 6.1 Current confirmation behavior

`lib/services/tourist_planning_profile_service.dart`:

- `fetchCurrent()` constructs every snapshot with `preferencesConfirmed: false`.
- `createIfMissing()` likewise reports false.
- `updateCurrent()` reports false after writing; comments state the current deployed contract has no confirmation field.

`PlanningPreferencesPage` displays an “Preferences are unconfirmed” notice and explains that saved values/database defaults are not confirmation. The review-and-save dialog is an acknowledgement before save, but the success message says the profile remains unconfirmed. It has no distinct persisted “confirm this version” action.

`TouristPlanningProfileTripAdapter` returns the current trip unchanged if the snapshot is unconfirmed. If confirmed, it fills only missing supported values and preserves explicit trip values, origin, and transfers.

### 6.2 CARS gate

`lib/algorithms/cars_assessment_input_preparer.dart` checks `preferencesConfirmed`. When matched/no-match interest evidence is otherwise assessable but the flag is false, it returns `insufficientData` with an explanation that the preferences are not confirmed. It does not convert unconfirmed preferences into a zero score. The system-generated planning page tests also assert unconfirmed saved categories do not reach the CARS provider.

Current production profile service never supplies true, so this is a fail-closed boundary: it preserves CARS safety, but confirmed profile preference scoring is not currently reachable through this service. Any future D29-09 implementation must define a clear edit-reset rule and persist the flag/timestamp under an authorized schema contract; the UI alone cannot establish confirmation.

## 7. Recommended canonical vocabulary

### 7.1 Recommendation for owner review (not approval)

Use one stable typed enum/codec for the five land/general trip modes, and keep water transfers as a separate route-edge constraint:

| Canonical concept | Proposed stable identifier | User-facing label | Scope |
|---|---|---|---|
| Walking | `walking` | Walking | Nullable profile preference; optional trip-wide choice. |
| Bicycle | `bicycle` | Bicycle | Nullable profile preference; optional trip-wide choice. |
| Motorcycle | `motorcycle` | Motorcycle | Nullable profile preference; optional trip-wide choice. |
| Car | `car` | Car | Nullable profile preference; optional trip-wide choice. |
| Public transportation | `public_transportation` | Public transportation | Nullable profile preference; optional trip-wide choice. |
| Required ferry crossing | `ferry` | Ferry transfer | Separate `RequiredTransferKind`, directed from/to destination IDs; not an ordinary mode. |
| Required boat crossing | `boat` | Boat transfer | Separate `RequiredTransferKind`, directed from/to destination IDs; not an ordinary mode. |

Recommended rules:

1. Profile preference remains nullable and never constitutes a confirmed trip-mode selection by itself.
2. Trip configuration may remain mode-null (“Not specified”) and should retain an explicit user-selected mode when supplied.
3. A trip-wide mode must not be represented as per-leg selection. If mixed land modes are later required, add a distinct explicit per-leg structure after owner decision; do not overload `RequiredTransfer`.
4. Ferry/boat remain explicit transfer edges with separate provider evidence, schedule, date validity and duration. An unavailable edge stays unavailable; do not convert it to road distance.
5. Use a single wire identifier mapping across profile storage, trip serialization, and APIs. The proposed `public_transportation` avoids the current space/camel-case split, but changing existing values requires owner approval, migration/decoder compatibility, and a confirmed supported vocabulary.
6. Treat the five values as vocabulary only. It does not assert that a routing provider supports every mode, that a mode is safe, or that MO-GA calculates mode-specific routes.

### 7.2 Owner decisions still required

- Confirm the canonical persisted identifier for public transportation and whether all existing profile rows/legacy Hive drafts must be dual-read during transition.
- Confirm whether a profile preference can prefill an otherwise unset trip mode or whether the tourist must choose per trip. The current adapter does prefill only when confirmed and only when the trip is unset.
- Confirm whether mixed modes across ordinary legs are in scope. Current `TripConfiguration` is one mode for the trip; ferry/boat is separate.
- Confirm whether `walking` is a desired profile preference even though the current MO-GA model does not use it for route calculation.
- Confirm owner-approved supported mode list/version; do not add transit subtypes (bus, taxi, van) or water categories without evidence.
- Define the adult/child/elder count completeness and equality rule, including whether adults are explicitly stored or derived. Do not supply age cutoffs.
- Define how D29-09 confirmation is recorded, when edits clear it, and whether it confirms the entire preference set or versioned fields.

## 8. Test and evidence inventory (inspected, not run)

Relevant existing tests found:

- `test/itinerary_draft_test.dart`: trip mode nullability and derived adult count cases.
- `test/local_itinerary_draft_store_test.dart`: local enum and `RequiredTransfer` serialization/round-trip.
- `test/manual_selection_workflow_test.dart`: explicit mode, boat transfer data, and transfer retention during workflow reordering.
- `test/cars_travel_assessment_test.dart`: all enum modes and a ferry leg that does not use land routing.
- `test/planning_preferences_page_test.dart`: current five preference choices and save behavior; confirms persisted service snapshot remains false.
- `test/tourist_planning_profile_service_test.dart`: required stored profile mode/defaulted current fixture and unconfirmed state.
- `test/system_generated_planning_page_test.dart`: unconfirmed preferences do not reach CARS; confirmed supported fields fill only absent trip fields and preserve transfers/explicit choices.
- `test/cars_assessment_input_preparer_test.dart`: unconfirmed preference state prevents the interest/activity criterion from being scored.

Task 31A did not run these tests. The inspected tests do not establish that MO-GA enforces ferry/boat adjacency as a hard constraint. The manual workflow’s retained transfer object is not a test of optimizer feasibility or transfer-schedule execution.

## 9. Evidence limitations and next closure steps

- No Supabase project or deployed schema was accessed. Profile `travel_mode` nullability, defaults, existing values, and confirmation fields are not live-verified here.
- No provider was contacted. Road/transit mode coverage, ferry/boat routes, schedules, freshness, and operations remain unverified.
- No tests, analyzer, or build were run. This is a source inspection only.
- The UI search covered Dart source under `lib/` for travel-mode and transfer values. It does not establish unsearched platform-specific or remotely configured UI options.
- At the original audit date, Task 30 D29-11 selected a nullable profile preference and left vocabulary open. The later D29-11A addendum records the owner-selected flexible catalog direction; exact IDs/categories and implementation remain open.

Recommended next sequence:

1. Owner closes D29-11’s vocabulary and profile-to-trip defaulting behavior, and D29-10’s group completeness/adult representation.
2. Close D29-09 persistence and edit-reset semantics as part of the profile contract; continue treating current preferences as unconfirmed for CARS until this is implemented and validated.
3. In a separately authorized code task, unify the typed mode codec and nullable profile field while preserving old Hive draft decoding.
4. Separately design and authorize MO-GA handling for required transfer edges; add tests that assert endpoints remain consecutive or that infeasible fixed transfers are explicitly surfaced. Verify schedule source before treating transfers as routable.
5. Keep CARS scoring blocked for unconfirmed preferences and unverified mode-specific evidence; preserve manual selection and circuit planning behavior.

## 10. Validation and closeout

- Transportation UI strings, model values, serialization mappings, profile validation, adapter precedence, CARS confirmation gate, and routing/MO-GA transfer paths were inspected read-only.
- `git diff --check`: **passed**.
- No Dart/test/configuration/SQL/migration edits; no SQL executed; no Supabase access.
- **Created:** `docs/TASK_31A_TRANSPORTATION_AND_PROFILE_CONTRACT_AUDIT.md`.

## 11. Owner decision addendum — D29-11A flexible transportation catalog

**Source:** Owner-supplied D29-11A decision in this conversation, received after the source audit above.
**Selected option:** C — flexible transportation catalog.
**Approval state:** Owner-selected architectural direction; catalog governance, exact entries/identifiers, service sources, compatibility, and schema scope still require technical validation. **Implementation authorization is not granted.** No owner name, role, date, or policy version is inferred.

This later owner decision supplements and supersedes the earlier five-mode-only recommendation in Section 7. It preserves the earlier observed code facts: the current UI and enum expose five general modes, while ferry/boat are currently separate required-transfer kinds. The owner-selected initial catalog now additionally names `Jeepney`, `Tricycle`, `Multicab`, `Van`, `Bus`, `Ferry`, and `Boat`, alongside Walking, Bicycle, Motorcycle, Car, and Public transportation.

### 11.1 Decision requirements to carry forward

- Each transportation catalog entry must have a stable identifier, display name, category, and active/inactive status.
- The profile preference remains nullable and is distinct from actual itinerary selection.
- Existing Hive enum-name values and legacy identifiers must remain readable during any future transition; unsupported/inactive entries must not be silently substituted.
- Catalog membership is not service availability. Availability is route- and condition-specific. Unknown remains distinct from confirmed available.
- Operator, schedule, fare, and duration evidence must be verified; none is fabricated.
- Ferry and boat catalog items must remain identifiable as water-transfer modes and as explicit itinerary constraints. A water mode selection must not erase its route-edge identity or allow a silent road-route substitution.

### 11.2 Reconciliation with the inspected implementation

The current `PreferredTravelMode` enum and both dropdowns still contain only `walking`, `bicycle`, `motorcycle`, `car`, and `public transportation`. The current `RequiredTransferKind` contains `ferry` and `boat` with from/to destination IDs. Therefore the owner’s catalog selection expands the intended vocabulary but does not mean the current UI, profile model, routing provider, Hive codec, or MO-GA supports the new entries.

The safest compatible concept model is two linked layers:

1. **Transportation catalog item** — stable identifier, display name, owner-approved category and active state. It represents a mode that may be preferred or selected; it makes no claim that a service exists for a route/date.
2. **Itinerary transportation constraint/leg** — identifies the chosen catalog item and relevant route edge or leg. Ferry/boat must retain explicit from/to endpoints. Service availability/evidence is a separate state attached to route/date/provider evidence, not inferred from the catalog item.

This is a technical recommendation, not a finalized field design. The existing `RequiredTransfer` does not carry a catalog identifier, availability state, operator, schedule, fare, or duration. MO-GA does not consume either catalog entries or transfer records and therefore still does not enforce required water legs. D29-11A does not itself close that optimizer compatibility gap.

### 11.3 Scope and owner decisions still open

Task 27/30 records A-13 approval for a ten-relation Scope A manifest. That manifest does not include a transportation catalog relation. D29-11A’s requirement for catalog records could require an eleventh relation, an explicitly approved extension to an existing relation, or a separately governed configuration catalog. Do not silently add a table or imply that A-13’s ten-relation approval already covers it. The owner/architect must document whether D29-11A amends A-13 scope before final schema design.

Technical closure is still needed for:

- stable IDs and exact canonical spellings for all twelve initial entries, including the migration mapping from `publicTransportation`, `public transportation`, enum names, and any prior persisted values;
- category vocabulary and which catalog entries are classified as water-transfer modes;
- whether inactive catalog entries remain readable for old drafts and how they appear/edit in the UI;
- how the profile preference can be null and whether it may prefill a trip selection;
- whether a selected catalog item is trip-wide or may vary by leg;
- how a ferry/boat catalog selection maps to the existing directed `RequiredTransfer` endpoints;
- route/date availability states, evidence authority, freshness, and behavior when unknown or stale;
- which source can verify routes, operators, schedules, fares, and durations for each supported mode;
- how a disabled/unsupported selection is handled without substituting another mode;
- schema-scope amendment and A-14 review for catalog reads/writes and any administrative catalog update path.

### 11.4 Updated recommendation (not approval)

Replace the earlier five-entry-only catalog proposal with a single stable-ID catalog containing the twelve owner-supplied initial concepts. Keep user-facing display names separate from identifiers. Preserve distinct typed categories for general land/non-motorized/public transportation and water-transfer semantics, with exact category values pending owner/architect review. Keep availability and verified route evidence separate from the catalog. Preserve the existing `RequiredTransfer` edge concept, but future implementation must bind water catalog items to explicit edges and teach the optimizer/route contract to preserve or reject infeasible required edges. A catalog entry alone must never imply routing support.

Do not yet approve `public_transportation` or any other proposed canonical identifier: owner selection establishes the flexible catalog and initial display concepts, while exact IDs, category strings, schema placement, and legacy mapping remain open. The prior recommendation table is a proposal and is not an owner-approved identifier registry.

### 11.5 Updated status

- D29-11A Option C is **owner-selected**; implementation is **not authorized**.
- The original five current UI/API choices remain accurate as source inspection findings, not the complete owner-approved future catalog.
- Profile nullability and profile-vs-itinerary separation remain requirements; current profile implementation still conflicts with nullability.
- Water service availability and MO-GA hard-constraint support remain unverified/unimplemented.
- A-13 scope impact, A-14 security review, A-15 non-production initialization, and A-16 production authorization remain separate gates; none is granted by D29-11A.

## 12. Owner decision addendum — itinerary legs, commitments, feasibility, and Hive

**Source:** Owner-supplied D31A decisions in this conversation.
**Selections recorded:** D31A-01–D31A-22 are explicitly supplied across the owner messages in this conversation. D31A-01, D31A-15, D31A-16, and D31A-22 are recorded in correction addenda below.
**Approval state:** Owner-selected architectural/behavioral directions. Route representation, feasibility semantics, Hive migration/recovery implementation, and acceptance evidence remain pending. **Implementation authorization is not granted.**

This addendum supersedes prior open questions in this report where the owner has now explicitly decided them. In particular, mixed transportation modes per leg are selected (D31A-02), and strict water-transfer adjacency/order and infeasibility handling are selected (D31A-05/06). Earlier recommendations against per-leg modes or statements that the owner had not selected them remain historical audit context only.

### 12.1 Decisions received

| Decision | Owner-selected direction | Still requires technical closure |
|---|---|---|
| D31A-01 | Option C: flexible transportation vocabulary scope that supports additional modes. | Aligns with D29-11A’s flexible catalog direction. Exact catalog scope, IDs, categories, relation/configuration placement, governance and legacy mappings remain open. |
| D31A-02 | Each itinerary leg can select a mode from the flexible catalog; mixed transport supported; profile values are suggestions and cannot override explicit trip/leg choice. | Exact leg identity/representation, catalog ID binding, manual/circuit UI behavior, compatibility with generated drafts. |
| D31A-03 | Tourist-entered pre-booked ferry/boat details are strict fixed constraints; never altered by optimization. | Commitment value fields, time semantics, endpoint reference rules, and invariant enforcement. |
| D31A-04 | No automated water-route verification until authoritative maintained source is approved; manual tourist confirmation only; unverified routes are not automatically feasible. | How manual confirmation is represented and disclosed; route unknown/infeasible state model. |
| D31A-05 | Fixed transfer endpoints remain consecutive and in the recorded direction; no inserted stop or endpoint replacement. | Route graph/edge model and enforcement in every planner/optimizer/manual edit. |
| D31A-06 | Preserve all commitments and report conflicts/infeasibility; no silent relaxation. | Feasibility diagnostics and conflicting commitment identification. |
| D31A-07 | Every itinerary entry has one of three classes: fixed pre-booked commitment, tourist-planned activity, optimizer-selectable optional destination. | Classification ownership and representation for stop versus transfer; default for legacy entries must not be invented. |
| D31A-08 | Preserve all planned activities when feasible; otherwise report infeasibility; optional destinations yield before planned activities. | Define feasibility dimensions and reporting while travel-time data may be unknown. |
| D31A-09 | MO-GA may select feasible optional destinations, while preserving commitments and planned activities. | Candidate pool, approved optimization criteria, selection limit (subject to D31A-10), and data readiness. |
| D31A-10 | Destination count is feasibility-based; no forced extras; preserve fixed and planned entries. | Feasibility contract and stopping behavior. |
| D31A-11 | Optional destinations may use preferences and approved criteria; never use unverified rating, price, or unsupported transport information numerically. | Exact approved criteria/objectives/weights and preference confirmation availability. |
| D31A-12 | Missing/incomplete/unverified travel time is unknown, not zero; it cannot establish numerical feasibility. | Typed unknown/unverified/stale states must flow through planning and optimizer APIs. |
| D31A-13 | Travel-time records carry source, endpoints, mode, recorded/updated times and verification status. | Approved source categories and freshness policy. |
| D31A-14 | Retain stale travel-time records for history but classify as unverified; no universal expiry threshold. | Source-specific threshold policy; stale data cannot be used as confirmed feasibility evidence. |
| D31A-15 | Option A: MO-GA reports one of three feasibility states: **Feasible**, **Infeasible**, or **Indeterminate**. | Define state predicates, propagation/aggregation from legs and constraints, and distinguish unknown evidence from proven conflict. No thresholds or fallback values are implied. |
| D31A-16 | Option A: generate the verified core itinerary and exclude optional destinations whose feasibility cannot be established. | Define “verified core,” handling when a required/planned core leg is Indeterminate, and whether the resulting itinerary can be labeled verified when optional candidates are excluded. Must align with D31A-07/08/12/15. |
| D31A-17 | Protect commitments from ordinary edits; deliberate owner edit requires explicit confirmation, validation and conflict display. | UI edit/confirmation contract and audit/history expectations, if any. |
| D31A-18 | Backward-compatible versioned Hive migration; legacy modes remain readable; do not infer classifications without evidence. | Format/version plan, exact legacy mappings and safe treatment of ambiguous old records. |
| D31A-19 | Preserve original data, recover/rollback on failure, do not discard malformed records, support retry. | Concrete atomicity/backup strategy supported by Hive/platform, per-record failure handling. |
| D31A-20 | Run versioned migration automatically during startup; expose new-format data only after validation; update version only after success. | Startup ordering, locking, idempotency, backup lifecycle and recovery state design. |
| D31A-21 | On migration failure, isolate itinerary features while safe unrelated app features continue; preserve source data and show recovery guidance. | App boot/service gating and retry/recovery UX. |
| D31A-22 | Option A: Generate a clearly labeled **Indeterminate** itinerary draft when feasibility cannot be established. | Separate draft artifact lifecycle from Feasible/Infeasible/Indeterminate assessment; define labels, save/edit/reassessment behavior, and core-vs-optional handling. Never label an Indeterminate draft verified feasible. |

### 12.2 Current source compatibility against new decisions

| Area | Current repository evidence | Gap against selected decisions |
|---|---|---|
| Per-leg transportation | `TripConfiguration` has one nullable `travelMode`; `RequiredTransfer` has only transfer kind and endpoints. | No general per-leg mode selection or catalog ID. Mixed land/public/water choices cannot be expressed as separate leg selections. |
| Catalog | Current UI and enum contain five general modes; D29-11A owner-selected twelve initial entries. | Added modes are not present in dropdown enum/codec. Catalog record structure and source are not implemented. |
| Commitment class | `DraftStop` has provenance, selected activity IDs, `isIncluded`, day, and order, but no commitment classification. `StopProvenance` describes origin (manual/circuit/CARS), not whether a stop is fixed/planned/optional. | D31A-07’s three classes cannot currently be represented, and old entries cannot safely be assigned a new class by assumption. |
| Water commitment schedule | `RequiredTransfer` stores only from ID, to ID, and `ferry`/`boat`. | No tourist-entered schedule, times, timezone, confirmation label, or editable protected commitment object. |
| MO-GA optimization | `ManualSelectionMogaAdapter` passes selected stops to `MogaEngine`; `MogaEngine` optimizes order from geometry, visit duration, average speed, and start point. It does not receive modes, transfer edges, commitment classes, or unknown route-time states. | Cannot enforce strict adjacency/direction, fixed times, planned activity inclusion or optional-vs-required priority. It may reorder stops without transfer constraints. |
| Optional candidate choice | `ManualSelectionMogaAdapter` optimizes the included stops it receives. `SystemGeneratedDraftBuilder` receives tourist-selected destination IDs and creates stops from them. | Current flow does not have MO-GA choose optional candidates from an eligible candidate pool; objective/selection policy is not implemented here. |
| Time feasibility | `ManualMogaConfiguration.averageSpeedKmh` defaults to 30; `MogaEngine` converts geometric distances into time using that speed. | This is a modeled estimate, not source-verified travel time. Under D31A-12, it cannot be presented as verified route feasibility; either label as non-evidence and avoid hard claims, or gate feasibility when authoritative durations are absent. |
| Water availability | CARS travel assessment marks required ferry/boat legs unavailable absent schedule/duration and does not substitute land routing. No authoritative source is established. | This aligns with D31A-04’s safe behavior, but D31A-04 now makes manual-confirmation-only the selected interim policy; the UI needs a clear unverified state and must not call the leg operationally verified. |
| Hive versioning | `LocalItineraryDraftStore` has `formatVersion = 1`, box name `samal_nav_local_itinerary_drafts_v1`, writes format 1, and `_readRecord` rejects any other version while leaving stored record unchanged. | No migration or backup/rollback path is present in the inspected store. It does not meet automatic startup migration, retry, isolation, or recovery requirements. |
| Hive data shape | Current store persists manual-selection drafts and trip/stops/transfers using JSON; enum mode uses `.name`. Existing tests cover round-trip and transfer metadata. | No commitment classes or per-leg modes; changing enums/fields risks legacy decode. Migration must preserve old payloads and cannot assign fixed/planned/optional classifications without evidence. |
| Manual/circuit planning | Manual workflow creates/reorders `DraftStop` values. `ManualSelectionMogaAdapter` explicitly rejects `PlanningMethod.circuitBased`. | New shared commitment rules must cover manual and circuit planners; current adapter is not a circuit optimizer path and no claim should be made that it supports circuit constraints. |

### 12.3 Revised transportation and itinerary contract recommendation

The new owner decisions resolve the earlier per-leg question. The recommended technical model for review is now:

1. A catalog item has a stable ID, display name, category and active state. Catalog membership does not assert a route, operator, availability, schedule or duration.
2. An itinerary has ordered entries classified as fixed commitment, planned activity, or optional destination. Preserve provenance separately; provenance is not commitment class.
3. Each travel leg connects two consecutive itinerary endpoints and references a catalog mode. A ferry/boat leg also has a fixed directed transfer constraint and tourist-entered schedule where provided. It remains unverified by SAMAL NAV under D31A-04.
4. Profile preference is nullable and may only suggest a mode where no explicit leg choice exists. It cannot overwrite a trip/leg selection.
5. Separate route-data status from user-entered commitment status. A tourist can record a pre-booked commitment without SAMAL NAV claiming provider verification. Unknown/stale travel time cannot be used as a confirmed numeric feasibility input.
6. If required route-time evidence is unknown, the system must say feasibility cannot be established; do not silently substitute another mode. The optimizer may still organize unaffected entries only if the result is clearly not represented as fully feasibility-validated under the owner-approved rule.
7. MO-GA must preserve all fixed commitments, fixed transfer direction/adjacency/schedules, and planned activities when feasible. If not feasible, return an explicit conflict result rather than an apparently valid relaxed itinerary. Only optional entries may be omitted.

These are engineering recommendations for the field/algorithm contract, not approved field names or a license to add a relation. A transportation catalog relation may expand the ten-relation A-13 scope; a leg/commitment model may be local Hive-only under A-10, but that storage scope must be explicit. No server itinerary, reservation, payment, or CARS evidence persistence is implied.

### 12.4 Hive migration acceptance requirements derived from decisions

Any future separately authorized implementation should demonstrate all of the following before opening migrated drafts to itinerary screens:

- Read fixtures containing current format version 1, each legacy transport encoding (`public transportation`, `publicTransportation`), `ferry`/`boat` transfer records, absent new fields, malformed records, and partially written/unknown versions.
- Preserve original box/record data until each converted record passes structural and semantic validation. Do not mark an unknown old draft as fixed, planned, or optional without an explicit safe rule; preserve an unresolved legacy classification or quarantine it without data loss.
- Make migration version update atomic at the supported storage boundary; rerun/restart after failure without duplicates or partial visibility.
- Keep unrelated application routes usable on migration failure while blocking new-format itinerary reads/writes; show a recovery message and retry only through the defined recovery path.
- Test local creation, saving, reopening, editing, and re-optimizing a commitment. Assert endpoint order, adjacency, transportation ID and tourist-entered schedule remain byte/value equivalent unless the tourist explicitly edits and confirms outside optimization.
- Test planned activities are never silently omitted; optional destinations may be selected/excluded only within approved objective and feasibility rules; report infeasibility/unknown travel-time states distinctly.
- Test manual planning, circuit planning, Hive round-trip, and generated planning with fixed and planned entries. Preserve no-network/no-server-booking behavior.

These are acceptance criteria only. No migration was designed or run and no tests were executed for this addendum.

### 12.5 Updated blockers and approval boundary

- **Decision submission coverage:** D31A-01–D31A-22 are present in the owner conversation and consolidated matrix. D31A-01, D31A-15, D31A-16, and D31A-22 were added by correction addenda. Their selections are owner-selected directions, not implementation authorization.
- **Per-leg transport/catalog schema:** exact catalog relation/scope, IDs/categories, active/inactive behavior and per-leg representation need a versioned technical contract. A-13 ten-relation scope impact requires explicit resolution.
- **Availability/provenance:** no approved authoritative transport source or freshness threshold is supplied; water routes remain manually entered and unverified. No numeric route feasibility may be fabricated.
- **Optimizer:** MO-GA has no required/planned/optional distinction, per-leg mode, fixed-schedule constraint, water-edge adjacency constraint, optional candidate selection, or unknown-duration semantics. Implementing these is a substantial algorithm and workflow change requiring dedicated design and tests.
- **Hive migration:** version 1 is read/written; unsupported versions are rejected and left in place. Backup, automatic migration, atomic recovery, quarantine/isolation, and retry policy are not implemented.
- **Profile and CARS:** profile transport preference remains required in the model; durable preference confirmation is absent and CARS interest scoring remains fail-closed when unconfirmed. The new directions do not authorize changing that boundary.
- **Authorization:** all supplied D31A decisions explicitly say implementation authorization is not granted. No code, tests, schema, migration, SQL, Supabase operation, or deployment is authorized here.

### 12.6 Recommended next task

Prepare a dedicated **D31A itinerary data contract and optimizer design** before coding. It should define the local entry/leg/commitment types, fixed transfer timing and adjacency constraints, planned-vs-optional selection semantics, unknown/stale travel-time behavior, infeasibility diagnostics, mode catalog scope, and versioned Hive migration/recovery state machine. Review the design against the existing manual, circuit, generated-planning and Hive flows, then obtain a separate explicit implementation authorization. Keep water availability unverified and all tourist commitments local until an authoritative source and separate persistence decision exist.

## 13. Focused correction — D31A-01, D31A-15, and D31A-16

**Verification source:** The owner explicitly supplied the three selections in the latest conversation message. The prior Section 12 matrix omitted them and incorrectly described them as not supplied. This correction supersedes that earlier coverage statement. The decisions are recorded as owner-selected architectural directions only; all state that implementation authorization is not granted.

### 13.1 Corrected decision entries

| Decision | Owner selection recorded | Compatibility implication | Remaining technical closure |
|---|---|---|---|
| D31A-01 | **Option C — Flexible transportation vocabulary scope supporting additional transportation modes.** | Confirms the flexible catalog direction already stated in D29-11A. The intended initial concepts are the twelve entries listed in Section 11. | Specify stable IDs, category vocabulary, active/inactive lifecycle, source of truth, legacy mapping and whether catalog data expands A-13’s ten-relation schema. No catalog relation or app change is authorized by the selection alone. |
| D31A-15 | **Option A — Three-state MO-GA feasibility classification: Feasible, Infeasible, Indeterminate.** | Requires feasibility state to be explicit rather than treating missing evidence as pass/fail or zero duration. Current MO-GA returns route/feasibility calculations based on geometry and average speed; it has no tri-state evidence status. | Define exact state predicates and aggregation across required constraints, planned activities, legs, schedules, stale evidence and unknown travel times. Proven constraint conflict is distinct from insufficient evidence. |
| D31A-16 | **Option A — Generate the verified core itinerary and exclude optional destinations whose feasibility cannot be established.** | Fixed commitments and planned activities form the protected core under D31A-07/08; optional candidates with indeterminate feasibility must not be included as verified feasible stops. | Define “verified core,” what output is allowed when a core leg is Indeterminate, and how excluded optional candidates/reasons are shown. Reconcile with D31A-04 manual/unverified water arrangements and D31A-12 unknown-duration behavior. |

### 13.2 Cross-decision consistency and remaining ambiguity

The three selections are compatible with one another if the implementation keeps *feasibility classification* separate from *commitment preservation* and *provider verification*:

- **Feasible:** evidence and constraints establish that the candidate/core arrangement satisfies the approved time, route, transfer, and itinerary rules.
- **Infeasible:** available evidence establishes a conflict or violated constraint.
- **Indeterminate:** missing, stale, unverified, or unsupported evidence prevents a reliable decision. It is not a numeric zero and is not equivalent to infeasible.
- For D31A-16, include an optional destination in a “verified core itinerary” only when its addition is Feasible; exclude an Indeterminate optional candidate and report why. An Infeasible optional candidate may also be excluded under D31A-09/10.
- Preserve all fixed commitments and planned activities even when feasibility is Indeterminate or Infeasible; report the status/conflict rather than deleting or weakening them. D31A-08 requires infeasibility reporting when planned activities cannot be accommodated, while D31A-15 requires unknown evidence to remain Indeterminate.

**Unresolved core case:** D31A-04 says SAMAL NAV will not automatically verify water service and tourist-entered arrangements remain unverified. D31A-03/05 require those arrangements to remain fixed and adjacent. If the itinerary’s required core includes such a transfer but no verified schedule/duration exists, D31A-12/15 imply **Indeterminate**, while D31A-16 calls for a “verified core itinerary.” The owner-selected decisions do not say whether the app may still generate a clearly labeled, non-verified draft preserving the commitments, or must withhold a generated core until the unknown is resolved. Do not label it “verified” by relying solely on the tourist-entered schedule; obtain an explicit interpretation before implementation.

**Current algorithm incompatibility:** `MogaEngine` uses geometric distance divided by `avgSpeedKmh` (default 30 in the adapter/engine configuration) to calculate travel time. That estimate cannot establish verified feasibility under D31A-12/13/14 without an approved, provenance-bearing source policy. A future implementation must either keep this as a visibly non-verified heuristic that cannot mark a result Feasible, or replace/gate it with approved route-time evidence. The current implementation provides neither the owner-selected tri-state result nor D31A-16 optional-candidate exclusion based on evidence status.

### 13.3 D31A-01–D31A-21 coverage check

The consolidated matrix in Section 12.1 now contains all 21 IDs exactly once: **D31A-01 through D31A-21**. Each is recorded as owner-selected based on the messages available in this conversation. D31A-01, -15, and -16 were added by this correction; no decision topic or answer is inferred for other work. Their selection does not approve final schemas, algorithm details, a migration, or deployment.

Remaining cross-cutting closures include catalog schema scope under A-13, verified-time data source and freshness thresholds, feasibility-state predicates, treatment of indeterminate fixed/planned core, optional-selection objective and reporting, legacy Hive classification/migration recovery, and independent A-14 review. A-15 and A-16 remain separately deferred/not authorized.

### 13.4 Correction validation

- Compared the corrected entries with the explicit owner wording in the latest conversation: D31A-01 Option C; D31A-15 Option A, three states; D31A-16 Option A, generate the verified core and exclude optional destinations of unknown feasibility.
- Confirmed the Section 12.1 matrix covers D31A-01–D31A-21 at the time of that correction; D31A-02–14 and D31A-17–21 remain unchanged.
- This is a documentation-only correction. No Dart, test, SQL, migration, Hive data, database, or Supabase changes were made.
- `git diff --check` and whitespace validation: **passed**.

## 14. Owner decision addendum — D31A-22 indeterminate itinerary draft

**Source:** Owner-supplied D31A-22 decision in the latest conversation message.
**Selected direction:** Option A — Generate a clearly labeled Indeterminate itinerary draft.
**Approval state:** Owner-approved architectural direction only. **Implementation authorization is not granted.**

### 14.1 Artifact state and feasibility state are separate

An itinerary draft is an artifact the tourist can inspect, save locally, or edit. Feasibility is an assessment of whether its contents can be supported by available route/time evidence and constraints. They must not share one overloaded status:

| Dimension | Meaning | Required treatment |
|---|---|---|
| Artifact lifecycle | Whether a draft exists and where it is in the tourist workflow (exact labels remain a technical contract). | A draft may be generated and saved even when complete route feasibility is unknown. |
| Feasibility assessment | D31A-15 state: Feasible, Infeasible, or Indeterminate. | Unknown/stale/unverified travel time yields Indeterminate, not zero duration or Feasible. |

An **Indeterminate** draft must be visibly labeled as not verified feasible. It must not display “verified route,” “feasible itinerary,” or equivalent success claims. Reassessment after evidence or tourist edits may change feasibility only under approved rules; an edit must not preserve a stale Feasible label.

### 14.2 Indeterminate draft contents and optional destinations

- Preserve every fixed pre-booked commitment, its user-entered transportation type, direction, endpoints, and schedule exactly as entered, subject only to a deliberate confirmed edit under D31A-17.
- Preserve every tourist-planned activity. If its feasibility cannot be established, keep it in the draft and mark the itinerary Indeterminate; do not silently remove or downgrade it to optional.
- Preserve unknown/stale/unverified transportation information as typed evidence state and source metadata when available. Do not create a numeric duration, fare, operator, route, or availability result to make a draft appear complete.
- Per D31A-16, exclude optional destinations whose feasibility cannot be established from the generated verified subset. Report the exclusion reason without treating missing evidence as a negative score.
- A draft containing a fixed commitment or planned activity with unknown travel-time or service evidence can still be generated under D31A-22, but its feasibility remains **Indeterminate**. It is not a “verified core itinerary” until the core itself has sufficient verified evidence under the approved rules.
- If evidence proves a constraint conflict, classify it Infeasible under D31A-15 and report the conflict. D31A-22 does not convert proven infeasibility to Indeterminate.

This reconciles D31A-08/12/15/16/17: preserve required/planned entries, distinguish unknown evidence from proven conflict, omit optional candidates when their feasibility is unknown, allow a clearly labeled draft artifact, and require explicit confirmation for a tourist’s intentional edit to a fixed commitment.

**Remaining interpretation point:** D31A-22 allows an Indeterminate draft even when required/planned core evidence is unknown. Such an artifact must not be represented as the “verified core” referenced in D31A-16. Owner approval establishes that the draft may be generated; exact user-facing wording and whether an additional “verification incomplete” banner is required remain product/UI details for technical review.

### 14.3 D31A-22 acceptance tests (future; not executed)

| Test case | Acceptance result |
|---|---|
| Fixed ferry/boat commitment lacks verified schedule/duration | Draft artifact is generated; feasibility is Indeterminate; commitment data, direction, endpoints and order remain unchanged; no verified/feasible claim is displayed. |
| Planned activity has unknown route duration | Activity remains included; draft is Indeterminate; no silent removal or downgrade occurs. |
| Optional candidate has unknown, stale or unsupported route-time evidence | Candidate is excluded from verified optional selections; reason is surfaced; no numeric duration or score is fabricated. |
| Optional candidate has a proven constraint violation | Candidate is excluded as Infeasible with a conflict reason; draft feasibility aggregation follows the approved state rules. |
| Required/planned core has a proven conflict | Result is Infeasible and conflict is surfaced; no relaxed or misleadingly valid draft is returned as feasible. |
| Required route-time evidence is missing | No zero-minute or estimate-as-verified value enters feasibility; state remains Indeterminate. |
| Tourist deliberately edits a fixed commitment | Explicit confirmation is required; local data changes only; prior feasibility is invalidated and recalculated. |
| Indeterminate draft is saved and reopened through Hive | Artifact and feasibility states survive round-trip; commitment, planned activity, mode, schedule and evidence-status data are preserved. |
| Hive migration fails for an Indeterminate draft | Original data remains recoverable; itinerary access is isolated; unrelated safe app features remain available; retry follows the approved recovery path. |
| Indeterminate state is rendered across manual and generated review | Both flows use an explicit non-verified label and preserve required/planned entries; optional unknown candidates remain excluded. |

These are acceptance criteria, not implemented behavior. Current source has no separate artifact/feasibility status model; Hive remains format version 1.

### 14.4 D31A-01–D31A-22 coverage check

The consolidated owner-decision matrix in Section 12.1 now contains **D31A-01 through D31A-22 exactly once**. D31A-22 is recorded as Option A, owner-selected architectural direction, not implementation authorization. This addendum changes documentation only; no code, test, SQL, migration, Hive data, or Supabase change is authorized.
