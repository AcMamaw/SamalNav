# Task 31A Final — SamalNav Transportation and MO-GA Technical Readiness Review

**Project:** SAMAL NAV
**Review date:** 24 November 2026 (Asia/Manila)
**Evidence basis:** Owner decisions D31A-01–D31A-22 supplied in this conversation; read-only repository findings consolidated in `TASK_31A_TRANSPORTATION_AND_PROFILE_CONTRACT_AUDIT.md`; inspected Flutter models, services, UI, optimizer, Hive store, and tests.
**Restrictions:** Documentation only. No source/test/configuration changes, SQL, migrations, Hive data changes, Supabase access, initialization, or deployment.

## 1. Final verdict

**Not ready for coding.**

The owner has selected a broad set of architecture and behavior directions, including flexible modes, per-leg transportation, protected fixed commitments, three commitment classes, three feasibility states, optional destination selection, indeterminate draft generation, and versioned Hive recovery. The existing implementation lacks core data types and algorithm support for these requirements. More critically, several design contracts remain undefined: feasibility-state predicates, catalog schema scope, timing/availability evidence, fixed-vs-planned conflict handling, legacy Hive classification, backup/recovery mechanics, and independent security or local migration acceptance gates.

Owner selections explicitly state that implementation authorization is **not granted**. This review does not authorize implementation, schema work, migration, or deployment. No code work should begin until the critical contract and authorization gates in Section 10 close.

## 2. Evidence categories

### 2.1 Verified repository findings (source inspection only)

- `TripConfiguration` contains one nullable trip-wide `PreferredTravelMode`; it has no per-leg mode list.
- `RequiredTransfer` contains only from/to destination IDs and `ferry`/`boat` kind; it has no schedule, operator, duration, fare, evidence source, or availability state.
- `DraftStop` has destination snapshot, selection order, day, provenance, selected activities, and `isIncluded`; it has no fixed/planned/optional commitment class. `StopProvenance` records source method, not commitment priority.
- `ManualSelectionMogaAdapter` passes included stops to `MogaEngine`. `MogaEngine` uses geometry, visit duration, starting point, and average speed. It receives no mode, transfer, commitment, or evidence-state inputs.
- `ManualMogaConfiguration.averageSpeedKmh` defaults to 30. This is a modeled estimate, not source-verified route-time evidence.
- `SystemGeneratedDraftBuilder` receives destination IDs already selected by the tourist and turns them into draft stops; it does not ask MO-GA to choose optional destinations from a broader candidate pool.
- `ManualSelectionMogaAdapter` explicitly rejects circuit-based drafts. Manual and circuit behaviors therefore need separate compatibility work; this adapter cannot be assumed to provide both.
- `LocalItineraryDraftStore` uses `formatVersion = 1`, serializes local manual drafts, and rejects unsupported versions while leaving their stored records unchanged. No automatic version migration, backup/rollback, recovery state, or feature isolation mechanism was found in the inspected store.
- Existing tests cover local Hive round trips, transfer metadata, manual workflow, MO-GA behavior, CARS travel assessment, and preference confirmation gates. They do not establish fixed commitment or optional-selection behavior in MO-GA, tri-state feasibility propagation, or Hive migration recovery.
- Current profile service reports preferences unconfirmed. CARS input preparation withholds interest/activity scoring when preferences are unconfirmed. The fail-closed CARS boundary must remain.

These findings establish current source behavior only. They do not establish deployed schema, live provider coverage, or production operations.

### 2.2 Owner-selected directions

The latest owner messages select D31A-01–D31A-22. The consolidated matrix in the Task 31A audit records every ID exactly once. Key decisions are:

- Flexible transport catalog and per-leg mode selection, including land, public, and water modes.
- Fixed, directionally ordered, adjacent ferry/boat commitments with tourist-entered schedules preserved locally.
- Three itinerary commitment classes: fixed pre-booked, tourist-planned, and optimizer-selectable optional.
- All planned activities retained where feasible; only optional items may be omitted under approved selection rules.
- Unknown or stale travel-time data is Indeterminate, not zero and not confirmed feasible.
- MO-GA feasibility has Feasible, Infeasible, and Indeterminate states.
- Optional destinations whose feasibility cannot be established are excluded from the verified core.
- D31A-22 permits a clearly labeled Indeterminate draft artifact.
- Fixed commitments may be deliberately edited only through explicit confirmation; Hive migration must be versioned and recoverable.

These are architecture/behavior selections only, not authorization to implement. D31A-01/15/16/22 are included in the corrected audit matrix; D31A-01–22 were checked for completeness and uniqueness.

### 2.3 Engineering recommendations (not owner approval)

- Separate itinerary artifact lifecycle (draft/review/saved) from feasibility state (Feasible/Infeasible/Indeterminate).
- Model legs explicitly between adjacent itinerary endpoints, each with a catalog mode ID and evidence/availability state. Water transfers also carry the directed fixed edge and user-entered schedule.
- Keep commitment class separate from provenance and separate from transport mode.
- Recalculate feasibility after edits; never retain a prior Feasible result after changing a commitment or route.
- Generate an Indeterminate artifact when core evidence is unknown, preserving all fixed commitments and planned activities; exclude optional candidates with unknown feasibility and show why.
- Do not pass geometric-average-speed approximations into a result labeled verified Feasible. They may only remain as clearly labeled, non-verified estimates if the approved policy allows them.
- Preserve original Hive data until a migrated record has passed validation; quarantine/read-only isolate malformed records rather than discarding them.

## 3. D31A-22 reconciliation

### 3.1 Artifact status versus feasibility status

D31A-22 resolves the prior question of whether an itinerary artifact may be produced when feasibility is unknown: **yes, as a clearly labeled Indeterminate draft**. It does not turn the underlying feasibility into success.

| Artifact lifecycle | Feasibility | Permitted interpretation |
|---|---|---|
| Draft exists / awaiting review | Indeterminate | A planning artifact exists, but complete route feasibility is not established. Show an explicit warning; never call it verified feasible. |
| Draft exists / awaiting review | Feasible | Evidence and constraints meet approved feasibility rules; only then may it be described as feasible. |
| Draft exists / awaiting review | Infeasible | Evidence establishes a conflict. Show the conflict; do not silently weaken or drop protected entries. |

Exact artifact lifecycle labels remain an engineering/UI contract. They must not be overloaded with the three D31A-15 feasibility values.

### 3.2 Indeterminate core behavior

If a fixed commitment or planned activity has unknown/stale/unverified required transportation information:

1. Preserve the commitment/activity, endpoints, order, transportation type, and schedule as entered.
2. Generate a draft artifact under D31A-22 with feasibility **Indeterminate**.
3. Do not invent a duration, route, fare, operator, availability result, or verified status.
4. Exclude optional destinations whose feasibility cannot be established, consistent with D31A-16. Present their exclusion and reason separately.
5. Do not describe the result as a “verified core itinerary” until the protected core itself meets the approved Feasible criteria.
6. If evidence proves a conflict, classify Infeasible and report it; do not convert known infeasibility to Indeterminate.

This interpretation aligns D31A-08, -12, -15, -16, -17, and -22 while preserving the difference between an artifact and a validated plan. The final definitions of verified core and feasibility aggregation remain open.

## 4. Final technical readiness matrix

| Area | Current source status | Owner direction | Readiness and required work |
|---|---|---|---|
| Transportation catalog completeness | Current preference/trip UI and enum expose five modes; no catalog data model was found. | D31A-01 Option C and D29-11A select a flexible catalog with twelve initial concepts. | **Not ready.** Define stable IDs, categories, active/inactive semantics, governance and legacy mapping. Decide whether catalog storage adds a relation beyond A-13’s ten-relation Scope A. |
| Per-leg transportation representation | One trip-wide mode; no generic itinerary-leg type/mode assignment. | D31A-02 Option A requires independent mode per leg. | **Not ready.** Define leg identity/order, mode reference, transfer edge binding, mixed-mode editing and generated-draft contract. |
| Local pre-booked commitment storage | Hive trip stores required transfer endpoints and kind only. No schedule-bearing commitment object or commitment class. | D31A-03/07/17 require fixed, editable-with-confirmation local commitments. | **Not ready.** Define commitment fields/timezone, endpoint linkage, user-entered/unverified labeling, edit confirmation, conflicts, and backward compatibility. Keep local Hive; no server reservation or booking claims. |
| MO-GA fixed constraints | Optimizer does not receive fixed transfers or commitment classes and may reorder stops. | D31A-03/05/06 require exact preservation, adjacency, direction and infeasibility reporting. | **Not ready.** Add constraint-aware route representation/algorithm and prove no delete, reversal, separation, or rescheduling. Surface impossible constraints without relaxation. |
| Three-level commitment classification | `DraftStop.isIncluded` and provenance do not express fixed/planned/optional. | D31A-07 selects three classes. | **Not ready.** Define classification for stops, activities, and transfer edges; legacy drafts must not be assigned a class without evidence. |
| Three-state feasibility | MO-GA has route feasibility calculations based on geometric estimates; no evidence-aware tri-state classification. | D31A-15 Option A. | **Not ready.** Define Feasible/Infeasible/Indeterminate predicates and aggregate rules across route legs, schedules, time limits, and constraints. Unknown is not infeasible or zero. |
| Indeterminate draft generation | No separate artifact and feasibility state found. | D31A-22 Option A; D31A-16 excludes optional unknowns from verified core. | **Not ready.** Implement distinct states and UI labels. Preserve fixed/planned core in an Indeterminate draft; exclude uncertain optional candidates; prevent “verified/feasible” claims. |
| Manual editing protection | Current draft editing/reordering has no fixed commitment edit confirmation contract. | D31A-17 Option A. | **Not ready.** Add explicit edit action, confirmation, validation, conflict display, local-only disclaimer, and feasibility invalidation/reassessment. |
| Hive migration, backup, recovery, retry | Format version 1, strict version equality; unsupported record stays unchanged. No migration/rollback/isolation workflow found. | D31A-18–21 require backward-compatible automatic startup migration, preserved originals, recoverability and feature isolation. | **Not ready.** Design atomic/versioned conversion, backup retention, validation, restart/idempotency, malformed-record handling, retry and safe feature gating; use representative legacy fixtures. |
| Manual and circuit planning regression | Manual workflow and tests exist; current adapter rejects circuit drafts. | Decisions require same commitment distinctions across manual and circuit workflows. | **Not ready.** Trace both planner implementations and add route/commitment invariants. Keep manual selection and circuit planning available even if one optimization path is isolated. |
| CARS evidence boundaries | Preparer checks preference confirmation; travel assessor does not substitute land route for an unavailable required ferry/boat schedule. | D31A-11/12/13/14 and prior CARS decisions prohibit unverified numerical evidence. | **Partially aligned, not ready.** Preserve fail-closed CARS behavior. Never treat catalog membership, user-entered schedule, stale data, fallback rating, or unverified price as numeric evidence. CARS cannot establish route availability absent approved source. |
| Existing application compatibility | Profile mode required; enum stores five modes; string/enum/Hive spellings differ; current profile confirmation is always false. | Nullable preferences, stable catalog, per-leg choices and legacy-readable Hive are selected. | **Not ready.** Update model, adapter, service, UI, serialization, generated/manual/circuit paths together after contract closure; retain old values during migration. |

## 5. Future implementation change inventory

No changes are made by this review. The following are the expected implementation surfaces after separate authorization and contract closure.

### 5.1 Models and adapters

- `lib/models/itinerary_draft.dart`: transport catalog reference/codec; explicit leg representation; commitment class distinct from provenance; fixed commitment/schedule and route evidence states; separate artifact lifecycle and feasibility status; validation for adjacency/direction, included planned activities, and unknown evidence.
- `lib/models/tourist_planning_profile.dart`: nullable profile mode preference and migration-compatible values; preserve no-preference state.
- `lib/services/tourist_planning_profile_trip_adapter.dart`: profile preference may suggest only where no explicit trip/leg choice exists; never overrides explicit choice; legacy identifier decoding.
- `lib/algorithms/manual_selection_moga_adapter.dart`: convert protected/planned/optional entries and per-leg constraints to optimizer input; reject or report unsupported/indeterminate cases safely.
- `lib/algorithms/system_generated_draft_builder.dart`: keep CARS-selected destinations distinct from MO-GA optional candidates; preserve provenance and apply only owner-approved evidence policy.
- New route-time evidence value types/provider contract: source, endpoints, mode/catalog ID, recorded/retrieved/updated time, verification/freshness state, and unknown/stale representation. Do not fabricate values.

### 5.2 Services and Hive

- `lib/services/local_itinerary_draft_store.dart`: versioned startup migration, dual-read legacy identifiers, safe defaults only where semantically valid, original-data backup/recovery, atomic or recoverable conversion, validated version commit, retry and quarantine/isolation behavior.
- Startup initialization/service boundary: prevent new-format readers from opening data until migration validation succeeds; isolate itinerary features on migration failure while unrelated safe app features continue.
- Local repository/service API: explicit edit-confirmation path for fixed commitments, validation, feasibility invalidation, and re-assessment. Do not create server-side reservations or itinerary persistence.

### 5.3 UI

- `planning_preferences_page.dart`: nullable catalog preference and active/inactive legacy display without silent substitution.
- `plan_page.dart`: per-leg mode selection, three commitment classifications, fixed commitment editing with confirmation, explicit unknown/Indeterminate labels, and manual route changes that preserve constraints.
- Generated draft/review screens: distinguish artifact status from feasibility status; show excluded optional candidate reasons and core conflicts; never call Indeterminate “verified feasible.”
- Circuit workflow screens: apply the same fixed/planned/optional and mixed-mode semantics without forcing circuit drafts through an adapter that currently rejects them.
- Hive migration failure UI: clear warning, preserved-data statement, safe recovery/retry guidance, no reset/discard action.

### 5.4 MO-GA

- Accept explicit leg mode and verified/unknown route-duration evidence rather than assume one mode for all legs.
- Treat fixed commitment transfer edges as ordered adjacent blocks with fixed endpoints/schedule; prevent mutation, deletion, reversal, insertion between endpoints, or mode substitution.
- Retain all planned activities; optional candidates may be included only if feasibility is established under the approved objective/constraints.
- Return Feasible, Infeasible, or Indeterminate, plus conflict/unknown reasons. Unknown travel time cannot become zero or a fabricated numerical optimizer input.
- Produce a clearly labeled Indeterminate draft when allowed; never label it feasible/verified. Report infeasibility rather than relax protected constraints.

## 6. D31A-22 and related acceptance test matrix

All are future acceptance tests; none was run for this documentation task.

| Test | Acceptance criteria |
|---|---|
| Artifact/feasibility independence | Draft lifecycle can be Draft/Review/Saved while feasibility independently reports Indeterminate; no status conflation in model or UI. |
| Unknown fixed water commitment | Generate a draft with fixed endpoints, direction, schedule and mode preserved; feasibility is Indeterminate; UI clearly says not verified feasible. |
| Unknown planned activity route | Keep planned activity in draft; classify Indeterminate; do not drop or downgrade it. |
| Unknown optional route | Exclude optional destination from verified optional selection; show reason; do not add placeholder duration, rating, price, or score. |
| Verified feasible optional candidate | Candidate may be added only if approved evidence establishes feasibility and approved objective ranks it. |
| Proven conflict | Mark Infeasible and report conflicting commitment/activity/leg; preserve source draft and all protected entries. |
| Missing/stale route time | Mark Indeterminate; no zero or default average-speed value may establish Feasible. Stale source/timestamps remain intact. |
| Explicit fixed commitment edit | Require deliberate edit and confirmation; local record changes only; validate; invalidate prior feasibility and reassess. No external reservation modification is implied. |
| Save/load and migration | Round-trip artifact status, feasibility, per-leg modes, classes, schedules, endpoints, evidence provenance, and edit state; preserve format-1 fixtures and ambiguous legacy data without invented classification. |
| Migration failure/retry | Original readable data remains recoverable; no partial new-format visibility; unrelated safe features work; retry is idempotent and produces no duplicates. |
| Manual planning | Manual ordering/editing preserves fixed transfer adjacency/direction and planned activities; optional unknown entries remain excluded from verified subset. |
| Circuit planning | Circuit grouping remains intact; same commitment rules apply; infeasible/indeterminate cases are surfaced without deleting commitments. |
| Generated planning | CARS selection remains distinct from optional MO-GA candidates; no unverified CARS rating/price or unconfirmed preference enters numeric evidence. |
| Regression / no server booking | Local pre-booked commitments never issue `reservations`/`payments` writes and do not claim provider confirmation. |

## 7. Remaining contradictions and unresolved technical details

1. **“Verified core” versus Indeterminate core artifact:** D31A-16 describes a verified core; D31A-22 now explicitly allows an Indeterminate draft. Reconcile by treating “verified core” as a feasibility-qualified subset, not the artifact’s existence. Exact UX wording needs review.
2. **Core unknown versus optional exclusion:** D31A-22 permits a draft with uncertain fixed/planned core; D31A-16 excludes optional destinations whose feasibility is unknown. The core remains present and Indeterminate; optional unknowns are excluded. This interpretation should be confirmed in product acceptance criteria.
3. **Unknown inputs versus optimizer arithmetic:** current MOGA uses average-speed geometry. It cannot produce a verified Feasible result under D31A-12/13 without approved source/freshness semantics. State rules and whether to retain non-verified estimates remain open.
4. **Catalog and schema scope:** D31A-01/D29-11A imply catalog records, while A-13 approved a ten-relation candidate scope that did not list a catalog relation. Resolve as an explicit scope amendment or approved non-schema catalog source before schema design.
5. **Per-leg choices and transfer constraints:** define whether ferry/boat are catalog modes, transfer-edge types, or both, and ensure one leg has stable mode identity plus explicit directed endpoints without duplicate/conflicting fields.
6. **Feasibility aggregation:** decide what overall itinerary state means when some optional items are excluded, when a required core leg is unknown, or when a constraint is known infeasible. D31A-15 names states but not aggregation precedence.
7. **Hive classification:** existing drafts have no commitment classes. Never silently label old included stops as fixed/planned/optional. Define a safe unknown legacy state or migration review path.
8. **Migration recoverability:** “atomic” migration, backup retention, interrupted write behavior, malformed-record isolation, and retry policy need a Hive/platform-specific design and failure-injection tests.
9. **Circuit support:** current MO-GA adapter rejects circuit drafts. Identify the actual circuit path and design shared constraints without degrading circuit planning.
10. **Security/persistence boundary:** keep itinerary/commitment data local under A-10; no remote persistence authorization is present. Any catalog write/read path still needs A-14 review and A-13 scope closure.

## 8. CARS, manual planning, and scope safeguards

- CARS remains a destination assessment/ranking boundary, not an itinerary optimizer. MO-GA’s new optional selection must not silently move CARS responsibility into route optimization.
- Unconfirmed preferences remain unavailable for CARS interest scoring; no new approval changes D29-09 implementation status.
- Unverified ratings/prices, fallback records, catalog presence, user-entered ferry details, stale travel-time values, and unsupported route modes must not become numeric CARS or verified-feasibility inputs.
- Manual selection and circuit planning remain first-class flows. They must preserve planned activities and fixed constraints and report Indeterminate/Infeasible rather than silently remove entries.
- Tourist-entered pre-booked ferry/boat information remains local Hive itinerary data. It is not a SAMAL NAV reservation, external confirmation, or payment record.
- Payments, server reservations, server itinerary persistence, and CARS evidence tables remain excluded unless separately approved.

## 9. Validation record

- Read-only source inventory cross-checked against the existing Task 31A audit and the owner-selected D31A decisions.
- D31A-01–D31A-22 appear exactly once in the Task 31A consolidated matrix after the update.
- Existing tests were inspected as evidence references only. No Flutter tests, analyzer, or build were run.
- `git diff --check` and whitespace validation: **passed**.
- No application code, tests, configuration, SQL, migrations, Hive data, or Supabase state changed or accessed.

## 10. Final readiness and blockers

Critical closure requirements before a coding task:

1. Owner/architect approves exact catalog identifiers, categories, data placement and A-13 scope treatment.
2. Define leg, transfer, schedule, commitment-class, and itinerary artifact models, including how legacy/unknown records are represented.
3. Define Feasible/Infeasible/Indeterminate predicates, aggregation, core semantics, optional filtering, and D31A-22 labels.
4. Approve route-time evidence sources/freshness and specify behavior when required core travel time is unknown; no current source proves service availability.
5. Design MO-GA constraints and candidate selection with testable invariants for fixed transfers and planned activity inclusion; preserve manual and circuit planning.
6. Design and failure-test the automatic Hive migration, backup, rollback/recovery, quarantine, startup gating, and retry behavior.
7. Complete the code-task authorization separately. Resolve A-14 security review for any remote catalog/read path; do not initialize or deploy a database under these decisions.

**Final classification: NOT READY FOR CODING.** Critical data contracts, feasibility rules, catalog scope, optimizer behavior, and Hive recovery are unresolved. Owner architectural selections do not grant implementation authorization.

### Closeout

- **Updated:** `docs/TASK_31A_TRANSPORTATION_AND_PROFILE_CONTRACT_AUDIT.md` with D31A-22 and its acceptance cases.
- **Created:** `docs/TASK_31A_FINAL_SAMALNAV_TRANSPORTATION_AND_MOGA_TECHNICAL_READINESS_REVIEW.md`.
- **No code/tests/database changes:** confirmed.
