# Task 32 — SamalNav Final Architecture Contract Closure and Pre-Implementation Specification

**Project:** SAMAL NAV
**Review date:** 24 November 2026 (Asia/Manila)
**Status:** Architecture specification and read-only repository audit.
**Authorization:** Documentation only. No code, tests, configuration, SQL, migrations, Hive data, database, Supabase project, initialization, or deployment was changed or accessed.

## 1. Executive summary

This specification translates the owner-selected D31A-01–D31A-22 directions into proposed technical contracts for transportation, itinerary data, feasibility, MO-GA, and Hive recovery. It inspects the current implementation and identifies the decisions that still need closure before implementation.

The current app cannot enforce the selected behavior. The itinerary model has one nullable trip-wide mode and a ferry/boat transfer tuple, but no per-leg mode, schedule-bearing commitment, commitment class, travel-time provenance, or tri-state feasibility. The NSGA-II-style optimizer shuffles and permutes every supplied stop and evaluates geometry-derived travel time using an average speed. The local draft store only reads/writes format version 1 and rejects other versions. It does not migrate or recover records.

The recommended initial catalog is a versioned bundled catalog of stable IDs, labels, categories, and active status. This avoids silently extending A-13’s ten-relation server scope and avoids implying operational service availability. Catalog expansion can be delivered as an approved application catalog update. A remote/hybrid catalog would require explicit A-13 scope treatment, A-14 access review, and a trusted update contract.

The proposed feasibility contract is fail-closed: **Feasible** only when every required core constraint is satisfied using acceptable evidence; **Infeasible** only when a known contradiction is demonstrated; otherwise **Indeterminate**. D31A-22 permits an Indeterminate draft artifact that retains fixed commitments and planned activities, but it must not be called verified feasible. Optional destinations with unknown feasibility are excluded, consistent with D31A-16.

**Final verdict: C. Not ready for coding.** Important semantics remain open, including whether explicit ordinary leg modes are immutable during optimization, how legacy drafts without commitment classifications are handled, how unknown travel-time evidence interacts with schedule constraints, and whether a transportation catalog may expand Scope A. Owner-selected architecture is not implementation authorization.

## 2. Evidence and decision hierarchy

### 2.1 Evidence classes

- **Source-verified finding:** behavior visible in the inspected repository at this review. It does not establish the deployed database or a live external service.
- **Owner-selected direction:** requirements supplied in D29/D31A messages and preserved in Tasks 29–31A. The selected architectural direction does not imply implementation approval.
- **Engineering proposal:** a suggested technical contract in this document. It is not an owner decision until accepted.
- **Unresolved approval:** a product, policy, data, security, or scope question that must be decided by the relevant authority.

Tasks 26–30 remain controlling for Scope A and the A-01–A-16 status. Task 31 and the two Task 31A documents provide application compatibility evidence. Where historical recommendations conflict with later owner selections, the later explicit selection controls; earlier text remains evidence of the prior code state or recommendation only.

### 2.2 Read-only evidence inspected

Inspected sources include:

- `lib/models/itinerary_draft.dart`, `lib/models/tourist_planning_profile.dart`
- `lib/algorithms/moga_engine.dart`, `lib/algorithms/manual_selection_moga_adapter.dart`, `lib/algorithms/manual_selection_workflow.dart`
- `lib/services/local_itinerary_draft_store.dart`, `lib/services/tourist_planning_profile_service.dart`, `lib/services/tourist_planning_profile_trip_adapter.dart`
- `lib/algorithms/cars_assessment_input_preparer.dart`
- Task 30, Task 31, Task 31A audit and Task 31A Final readiness review

Tests and test inventories referenced below were inspected as repository evidence only. No tests, analyzer, or build were executed for this task. No Supabase project was accessed.

## 3. Contract A — Transportation catalog

### 3.1 Current repository contract

`PreferredTravelMode` in `itinerary_draft.dart` contains five enum identifiers: `walking`, `bicycle`, `motorcycle`, `car`, and `publicTransportation`. Its wire mapping uses the values `walking`, `bicycle`, `motorcycle`, `car`, and `public transportation`. Hive currently serializes the enum name, so the last value is `publicTransportation`. Profile code uses a required arbitrary string, and the profile UI has its own five-value string list. These duplicate sources can drift.

`RequiredTransferKind` has `ferry` and `boat`, separate from `PreferredTravelMode`. The current travel-transfer type has only directed origin and destination IDs plus kind. Neither catalog presence nor the enum establishes an available route, operator, schedule, fare, or duration.

### 3.2 Proposed catalog placement and ownership

**Recommendation:** start with a bundled, versioned application catalog, with stable identifiers and an explicit update/version process. Do not add a relation to Scope A in this task. The bundled source can be updated only through an approved, reviewed app catalog release; it is read-only to ordinary users. This resolves the first implementation boundary without implying that A-13 already approved an eleventh relation.

A later hybrid/remote catalog is possible only after an explicit A-13 scope decision and A-14 review of read/write access, governance, cache freshness, and trusted administration. A catalog update does not establish route/service availability.

Proposed catalog item shape (conceptual, not a database schema):

| Attribute | Contract proposal |
|---|---|
| `id` | Immutable stable identifier, independent of label and UI locale. Exact spelling registry remains owner/architect approval. |
| `displayName` | Localized or user-facing label; may change without changing identity. |
| `category` | Controlled category such as `non_motorized_land`, `motorized_land`, `public_transport`, `water_transfer`. Exact values need approval. |
| `isActive` | Whether new selection is currently offered. Inactive entries remain decodable/displayable in saved drafts and are never silently replaced. |
| `catalogVersion` | Version of the bundled catalog/identifier mapping used for validation and migration. |

Initial concepts are exactly the twelve owner-supplied entries: Walking, Bicycle, Motorcycle, Car, Public transportation, Jeepney, Tricycle, Multicab, Van, Bus, Ferry, and Boat. D29-11A says the list is not necessarily exhaustive. Ferry and Boat must be categorized as water-transfer modes; their route-edge endpoints remain separately represented.

No final stable IDs are selected here. A plausible engineering convention is lowercase snake case (`public_transportation`, `jeepney`, etc.), but the registry requires approval before persistence. The decoder should accept legacy spellings including `public transportation` and `publicTransportation`, map only known aliases, and preserve an unknown raw identifier as unsupported. It must never substitute an unknown/inactive mode with another mode.

### 3.3 Profile preference versus itinerary selection

The profile preference is nullable and advisory. A trip/leg explicit user selection has precedence over any profile suggestion. The existing adapter only applies a confirmed profile default to a missing trip-wide mode, but it cannot model per-leg choices. Under the selected D31A-02 direction, future UI may offer a profile suggestion when a new leg is unset; it must not overwrite an explicitly chosen trip or leg value.

**Owner closure still required:** whether a profile suggestion may initialize a newly created leg, whether an explicit ordinary leg mode is a hard constraint during optimization, and how mode selection behaves when an optimizer creates a new adjacency. Recommended safe default: explicit leg choices are retained; an optimizer must not silently change them. If reordering breaks an explicitly selected endpoint pair, retain the protected edge as a block or report a conflict/Indeterminate result for owner review.

### 3.4 Availability is a separate contract

Availability is route-, date-, and condition-specific. The catalog only identifies a mode. A separate evidence object should represent `verified`, `estimated`, `unverified`, `stale`, or `unknown` inputs; only owner-approved source/status combinations can establish confirmed numerical travel time. D31A-04 selects no automated water verification until an authoritative maintained source is approved. Tourist-entered ferry/boat details remain unverified by SAMAL NAV.

Do not persist speculative service operators, times, fare, or duration. No current source inspection verifies an operational routing provider for the twelve catalog modes.

## 4. Contract B — Itinerary and commitment data model

### 4.1 Conceptual local data shape

The following model is a technical proposal for local Hive data, not server persistence or finalized Dart field names.

| Concept | Proposed responsibility / fields |
|---|---|
| Itinerary artifact | `draftId`, artifact lifecycle (`draft`, `review`, `saved` or equivalent), update/version metadata, ordered entries, feasibility assessment and assessment timestamp. Artifact lifecycle is not feasibility. |
| Itinerary entry | Stable local entry ID, kind (`stop`, `transfer` or activity as clarified), ordering/day placement, commitment class, provenance, user-entered notes and source reference. |
| Stop | Destination identity/snapshot, selected activity IDs, planned duration only when supplied/approved, day/order, inclusion state and commitment class. |
| Transportation leg | Directed `fromEntryId` / `toEntryId` for consecutive endpoints, catalog mode ID, selection source (explicit/profile suggestion/optimizer), availability evidence reference/status, and optional user-visible notes. |
| Fixed pre-booked commitment | Local-only commitment ID; directed endpoint references; catalog mode ID; user-entered schedule fields and explicit timezone when supplied; manual-confirmation/unverified label; edit history/version. No provider confirmation or booking ID is implied. |
| Planned activity | Tourist-selected item that remains included whenever a feasible solution exists; may be reordered/timed but not silently removed or reclassified optional. |
| Optional destination | Candidate that MO-GA may include only when required constraints and feasibility evidence permit; optimizer-selected status is distinct from tourist selection/provenance. |
| Travel-time evidence | Origin, destination, mode/catalog ID, duration if actually sourced, source identifier, recorded/retrieved/updated timestamps where available, verification/freshness status and evidence reference. Unknown has no numeric duration. |
| Assessment | Feasibility state plus structured reasons, relevant leg/commitment IDs, evidence references, and excluded optional candidate explanations. Recomputed after meaningful edits. |

Schedule semantics must distinguish a calendar date from an instant and carry an IANA timezone when a timed local commitment is entered. Exact required/optional schedule components and handling of partial tourist-entered data remain open; no missing time is inferred.

### 4.2 Three commitment classes

Represent exactly the selected classes independently of provenance and transport mode:

1. **Fixed pre-booked commitment:** immutable during ordinary reorder/optimization; explicitly editable by the tourist only through confirmation and validation under D31A-17. Transfer endpoint order, adjacency, mode, and user-entered schedule remain fixed during optimization.
2. **Tourist-planned activity:** must remain included if a feasible solution exists. If it cannot fit or a required route is unknown, report the relevant Infeasible or Indeterminate outcome; do not silently drop or demote it.
3. **Optimizer-selectable optional destination:** may be omitted. Do not add it to the verified core unless its feasibility is established with approved evidence and it satisfies approved objectives.

Classification must exist at the correct granularity. A stop and a transfer edge are not necessarily the same entry; the contract must prevent inconsistent duplicate class values. Provenance (`manualSelection`, `circuit`, `carsRecommendation`) describes origin, not commitment class.

### 4.3 Legacy drafts without classification

Current format-1 drafts do not contain commitment class, per-leg transport, or schedules for transfers. A migration must not assume that `isIncluded == true` means planned or fixed, nor that CARS provenance means optional. Proposed safe representation is a `legacyUnclassified`/needs-review state that is not eligible for optimization under new rules until the tourist classifies it. This state is a recommendation requiring owner approval because the three selected classes are exhaustive for new entries but do not specify legacy behavior.

Keep the original format-1 bytes recoverable. Do not drop a draft, set invented defaults, or treat a legacy required transfer as having schedule details it does not contain.

## 5. Contract C — Feasibility and evidence model

### 5.1 Separate artifact and feasibility states

Artifact lifecycle answers “what is the user doing with this saved planning object?” Feasibility answers “what do current evidence and constraints establish?” A Draft/Review/Saved artifact can independently be Feasible, Infeasible, or Indeterminate. D31A-22 allows creating a labeled Indeterminate draft; it does not upgrade unknown evidence.

### 5.2 Proposed predicates

These predicates are engineering proposals and need approval as acceptance semantics:

| State | Proposed predicate |
|---|---|
| **Feasible** | Every fixed and planned entry is present and all hard ordering/adjacency/schedule/resource constraints pass; every travel-time or availability fact needed to establish time/route feasibility has current approved evidence; no unknown or stale required input remains. Optional candidates included in the result also meet this threshold. |
| **Infeasible** | At least one known, validated contradiction proves the required core cannot satisfy a hard constraint (for example, reversed fixed edge, impossible endpoint order, or verified time window conflict). Unknown evidence alone never establishes Infeasible. |
| **Indeterminate** | Neither proven feasible nor proven infeasible: a required core edge/time/availability is missing, stale, unverified, unsupported, or otherwise cannot be evaluated. Unknown is never zero. |

Suggested aggregation: a proven hard contradiction => Infeasible; else any unevaluated required core constraint => Indeterminate; else Feasible. Optional unknown candidates are excluded and recorded separately; their exclusion does not make the retained core Indeterminate. If a required/planned core leg remains unknown, the overall artifact is Indeterminate even when a draft can be generated.

Under D31A-16, “verified core” means the subset whose required constraints have approved evidence. If fixed commitments/planned activities themselves contain unknown required transport, the artifact may still be generated under D31A-22, but must be labeled **Indeterminate draft — feasibility not verified**, not “verified core itinerary.” The exact wording and whether to display verified subsegments require product review.

### 5.3 Evidence handling

- Missing duration is null/unknown, not 0.
- Stale records remain available for history with original source and timestamps but are not verified inputs. No universal freshness duration is assumed.
- Tourist-entered schedule is evidence of the tourist’s stated commitment, not evidence that the operator/service has confirmed it.
- A valid fixed commitment can be preserved even when its operational feasibility is unknown. The optimizer does not remove or replace it.
- A known schedule contradiction can be Infeasible; missing external service data is Indeterminate.
- Optional destinations whose feasibility is unknown are excluded under D31A-16, with a reason shown. They are not assigned synthetic duration or favorable fitness.
- Geometry and average-speed values may remain only as visibly non-verified estimates in a separate display channel. They cannot establish Feasible, enforce time limits, or be used as confirmed MO-GA inputs. If used for exploratory ordering, output remains Indeterminate and must not imply verified feasibility. Owner approval is needed for even this limited estimate behavior.

### 5.4 Invalidation after edits

Any edit to order, leg mode, fixed commitment, schedule, stop/activity inclusion, evidence, or duration invalidates the prior assessment. Re-run the assessment against the changed version. A failure to assess yields Indeterminate; it must not preserve a cached Feasible state. Manual edits to a fixed commitment require explicit confirmation, validation, clear display of changed details/conflicts, and a disclaimer that no outside booking is changed.

## 6. Contract D — MO-GA technical design

### 6.1 Existing optimizer inspection

`RouteChromosome` stores only `List<int> order`, fitness, rank, and crowding distance. `MogaEngine` validates unique indices; builds a symmetric haversine matrix multiplied by 1.3; estimates travel time as distance divided by `avgSpeedKmh` (default 30); and scores distance, negative count of stops fitting within `tourHours`, and stop-time variance. Initial population shuffles all assigned indices. Tournament selection uses rank/crowding distance. Order crossover copies a parent slice and fills unused genes from the other parent. Mutation swaps two indices. There is no repair or hard-constraint validation after mutation/crossover, no candidate subset gene, and no unknown/evidence input.

`optimizeAssignedItinerary` preserves preassigned day membership and rejects duplicate assignment, but independently optimizes each day’s order. It reports day violations from estimated numerical totals. It does not report an evidence-aware tri-state. `ManualSelectionMogaAdapter` passes only included stops, visit durations, available hours, average speed and starting point; it rejects circuit drafts. It does not pass modes, transfers, commitments, provenance evidence, or optional candidates.

### 6.2 Redesign recommendation

The existing permutation chromosome cannot safely express optional inclusion plus protected ordered edges by adding a simple post-hoc check. A constrained representation is recommended:

- A **mandatory core** containing all fixed commitments and planned activities.
- Fixed directed transfer edges and other explicit locked leg choices represented as atomic blocks or precedence/adjacency constraints.
- A candidate bitset for optional destinations.
- A sequence of blocks/entries that obeys hard constraints.
- Each consecutive leg carries a selected catalog mode and evidence state; the mode cannot be synthesized or changed silently.
- Fitness is evaluated only over known, approved inputs. Unknown dimensions are carried as unknown and never converted into a numeric objective.

Because crossover and swap mutation currently operate on individual indices, fixed-edge support requires either (a) block-level chromosome genes with operators that preserve each block’s internal direction/adjacency, or (b) a new constrained path representation and constraint-aware operators. The first is a safer initial design for fixed transfer pairs. Neither approach should repair a violation by deleting/reversing a commitment. Optional inclusion must be a separate decision variable and only optional entries may be excluded.

### 6.3 Proposed optimization loop

```text
validate input identities, classes, schedules, endpoint links and evidence
if a known core contradiction exists: return Infeasible with conflicts
form mandatory blocks from fixed commitments and required directed edges
retain every planned activity as mandatory
classify optional candidates:
  include only candidates whose route/time feasibility is established
  exclude unknown candidates and record the reason
initialize candidate sequences from legal block permutations
for each generation:
  select parents by approved objectives over evidence-supported values
  crossover whole blocks, never splitting/reversing a fixed edge
  mutate block order or optional inclusion only when hard constraints remain valid
  reject invalid offspring; do not weaken constraints to repair them
if required core evidence is unknown: emit Indeterminate draft with all fixed/planned entries
else if a proven contradiction exists: emit Infeasible with conflict diagnostics
else emit Feasible only when every required constraint passes approved evidence rules
```

The actual optimization objectives, normalization, Pareto selection, and tie-breaking remain unresolved under D31A-09/11. Do not use unverified ratings/prices or unsupported travel information. CARS remains a separate assessment boundary.

### 6.4 Invariants for future acceptance

1. Fixed commitment values and schedules are bit/value stable across ordinary optimization.
2. Every fixed transfer has the same directed adjacent endpoints in every output; no unrelated entry is inserted between them.
3. Every planned activity remains included unless the result is explicitly Infeasible and no generated “successful” itinerary is presented; never silently demote it.
4. Only optional candidates may be omitted by selection. Unknown optional candidates are excluded and explained.
5. No unknown or stale duration is passed to arithmetic as zero or a fabricated number.
6. Any explicit mode/locked edge remains unchanged; a conflict is reported rather than silently switching modes.
7. An Indeterminate artifact is never labeled verified feasible.
8. A commitment edit occurs only through explicit user confirmation and invalidates the prior feasibility assessment.
9. Manual and circuit workflows use the same class, leg, and conflict invariants. Circuit-based input needs a supported adapter; current rejection remains a known gap.

## 7. Contract E — Hive migration and recovery

### 7.1 Current format

`LocalItineraryDraftStore` uses box `samal_nav_local_itinerary_drafts_v1`, record `formatVersion: 1`, and `storageState: localDraft`. It serializes trip-wide mode by enum `.name`, `requiredTransfers` as from/to IDs and kind, and stops with snapshot, order, day, provenance, activity IDs, and `isIncluded`. `_readRecord` throws on any format other than 1 and states the stored value remains unchanged. No startup migration, backup, rollback, quarantine, or retry state machine was found in this store.

### 7.2 Proposed versioned migration architecture

Do not assume Hive transactions. Treat migration as a recoverable copy/validate/commit process:

1. Open the existing box read-only for migration assessment; acquire a single-process migration lock.
2. Detect each record’s version and capture exact raw bytes/key to a durable recovery copy before conversion. Do not overwrite the source.
3. Decode supported version-1 records into a legacy representation that can preserve unknown fields/raw values. Rejecting an unsupported record must isolate it without blocking safe unrelated app features.
4. Convert to a new version in a separate staging box/key namespace. Add no inferred commitment class; mark ambiguous legacy data for review, subject to owner approval.
5. Validate structural invariants, ID uniqueness, endpoint references, time parsing, recognized/unknown transport IDs, and preservation checks against source values.
6. Re-open staged data and validate a second time. Only after all required records pass should a commit marker/version pointer be advanced.
7. Expose migrated itinerary reads only after commit. Keep the original recoverable copy through a defined retention window and until explicit recovery acceptance; do not delete it during conversion.
8. On failure, leave source and commit marker unchanged, hide staged new-format reads, display migration failure, and permit a safe retry after the failure is addressed.

This is a proposal requiring platform-specific design: Hive box flush/rename semantics, crash behavior, backup location, storage quotas, encryption/device backup interaction, and atomic marker update must be validated. Copying local app files may not be atomic across operating systems. Recovery cannot be claimed until failure injection proves the actual strategy.

### 7.3 Startup and failure pseudocode

```text
startup:
  gate itinerary repository as unavailable
  acquire migration lock
  inspect metadata and source records
  if new install: initialize current format and validate
  else if version current: validate before enabling repository
  else:
    preserve raw source snapshot
    stage conversion record-by-record without deleting source
    validate complete staged dataset
    atomically/recoverably commit version pointer only after validation
  on success: enable itinerary feature
  on failure: retain source; isolate itinerary readers/writers; show recovery UI
              leave unrelated safe app features available; permit explicit retry
```

Malformed records are preserved verbatim and quarantined from the new decoder with a visible recovery status; they are not silently skipped or deleted. Whether one malformed record blocks all itinerary functionality or only that record must be decided. D31A-21 favors isolating itinerary functionality, but record-level isolation and user recovery must not expose mixed formats.

### 7.4 Required fixture and failure tests

Fixtures should cover format-1 examples, both legacy public-transport spellings, ferry/boat metadata, null/absent new fields, unknown mode values, unsupported versions, malformed JSON, duplicate IDs, missing endpoints, interrupted staging, partial backup, commit-marker failure, restart, retry, and new installation. Compare original values to migrated values. Test all-or-nothing visibility, idempotency and recoverability on each supported platform. No fixtures were added or run here.

## 8. Contract F — Security and persistence boundaries

- Itinerary drafts, transfer commitments, schedules, and itinerary legs remain local Hive data under the selected Task 26–31A boundary. Do not create server itinerary, reservation, or payment persistence.
- Tourist-entered pre-booked information is not an SAMAL NAV reservation, provider confirmation, or payment record.
- Do not add CARS evidence tables or use unverified ratings, prices, user-entered schedules, stale route times, catalog presence, or unsupported modes as numerical CARS evidence.
- CARS interest/activity scoring remains fail-closed while preferences are unconfirmed. The inspected profile service currently always returns `preferencesConfirmed: false`.
- A-13 approved a ten-relation Scope A target conditionally; a remotely managed catalog could exceed it. Obtain explicit scope closure before any server relation or migration.
- A-14 independent RLS/grant/trusted-operation review remains a separate security gate. Any remote catalog or privileged catalog update path must define caller authority, allowlisted operations, audit, and read exposure before coding/deployment.
- A-09 audit/settings taxonomy and access policies remain open; A-11 retention/deletion details remain open; A-15 non-production initialization and A-16 production deployment remain deferred/unauthorized in the controlling task records.
- Auth/profile role trust remains governed by A-01/A-02 and the trigger/trusted-operation contract. Catalog data must never be used as an authorization signal.
- No Supabase access, SQL execution, initialization, or deployment is authorized by this specification.

## 9. Cross-contract consistency matrix

| Concern | Required separation / consistency rule | Current conflict or open item |
|---|---|---|
| Catalog vs availability | Catalog item identifies a mode; evidence determines route/service availability. | No catalog model or operational provider established. |
| Profile vs leg choice | Nullable profile value may suggest; explicit leg choice wins. | Current trip-wide mode; profile model requires string. |
| Mode vs commitment class | Mode describes transport; class describes user/optimizer obligation. | Current `DraftStop` lacks class. |
| Provenance vs class | Manual/CARS/circuit origin is not fixed/planned/optional. | Existing model only has provenance and `isIncluded`. |
| Transfer vs stop | Fixed transfer is directed edge with endpoints and schedule; not merely an enum on a trip. | `RequiredTransfer` holds only endpoint IDs and kind. |
| Artifact vs feasibility | Draft/review/saved lifecycle does not equal Feasible. | Current result exposes bool feasibility from numeric estimates. |
| Unknown vs infeasible | Missing evidence => Indeterminate; known contradiction => Infeasible. | Existing optimizer calculates numerical estimates without evidence status. |
| Core vs optional | Fixed/planned retained; optional unknown excluded. | Current adapter only optimizes included input list. |
| Estimate vs evidence | Geometric/average-speed estimate is not verified travel time. | Default speed 30 informs numerical feasibility today. |
| Hive migration vs legacy | Preserve source; ambiguous legacy remains unclassified until reviewed. | Current version 1 strict reader, no conversion/recovery. |
| Local commitments vs reservations | Hive-only user-entered detail, no external booking claim. | Existing excluded server booking/payment code elsewhere requires separate redesign under Task 31. |
| CARS vs MO-GA | CARS evidence/ranking and MO-GA route optimization remain separate. | No approved route evidence source or CARS scoring extension. |
| Security vs catalog governance | Local bundled catalog avoids remote permissions; remote catalog requires A-13/A-14 closure. | A-13 scope and A-14 review are not closed for a new relation. |

## 10. Owner decision traceability matrix

All rows below are owner-selected directions only, not implementation authorization. The technical mapping is proposed; exact tests and unresolved detail remain for closure.

| Decision | Selected direction | Contract / future acceptance coverage | Remaining detail |
|---|---|---|---|
| D29-01 | Username login with case-insensitive uniqueness (Option A) | Profile/auth contract tests, normalization collision tests | Exact normalization/reserved names and legacy collision plan. |
| D29-02 | Omit unused establishment contacts (Option C) | Establishment field compatibility tests | Verify retained app fields and public visibility. |
| D29-03 | Nullable destination-establishment link (Option A, conditional) | Relationship/nullability and deletion tests | Confirm actual product relationship and FK action. |
| D29-04 | Nullable verification-result destination link, trusted approval (Option A, conditional) | Atomic approval/idempotency tests | New/correction workflows and duplicate semantics. |
| D29-05 | Unique linked favorite per user/destination; snapshot null IDs may repeat (Option A) | Duplicate add/undo and ownership tests | Confirm snapshot behavior and FK retention. |
| D29-06 | Omit rating/price until authority/stewardship approved (Option C) | CARS missing/unverified evidence tests | Future source/steward/freshness policy. |
| D29-07 | Separate publication lifecycle (Option A) | Transition/public visibility tests | Exact states, actors and predicates. |
| D29-08 | Separate verification lifecycle (Option A) | Verification transition tests | Exact states, transitions and actors. |
| D29-09 | Explicit preference confirmation and timestamp (Option A) | Edit-reset/reconfirm and CARS fail-closed tests | Confirmation scope/UI version semantics. |
| D29-10 | Store total only until category semantics are approved (Option B) | Nullable group input and validation tests | Group completeness and adult derivation. |
| D29-11 / D29-11A | Nullable preference; flexible catalog Option C, initial 12 concepts | Catalog codec/profile nullability/legacy Hive tests | Stable IDs, categories, scope, governance, suggestion rules. |
| D29-12 | Integer star scale Option A after UI verification; duplicate-review Option 2 | Scale and multiple dated review tests | Exact UI range and aggregation policy. |
| D29-13 | Moderation state machine Option A | Trusted transition/public filter tests | States, appeals, visibility and actors. |
| D29-14 | Events Option C: date, all-day flag, optional instants, timezone | Event parse/interval/timezone tests | Confirm application workflows and exact DB checks. |
| D29-15 | Structured trusted audit events Option A, conditional A-09 | Client denial/server writer/redaction tests | Taxonomy, retention and read access. |
| D29-16 | Allowlisted typed settings Option A, conditional A-09 | Key allowlist/type/access tests | Keys, emergency access, authorized writers. |
| D29-17 | Soft-close and controlled retention Option A | Closure/anonymization/FK/backup tests | Formal A-11 periods, actors and deletion process. |
| D31A-01 | Flexible vocabulary scope, Option C | Catalog completeness/legacy decoder tests | Scope, ID/category registry and governance. |
| D31A-02 | Independent mode per leg; mixed transport | Leg CRUD, precedence, manual/circuit tests | Leg identity and whether explicit ordinary modes are locked. |
| D31A-03 | Ferry/boat arrangements are fixed commitments | Value preservation tests | Schedule field/time semantics and endpoint model. |
| D31A-04 | No automated water verification; manual confirmation only | Unverified labeling/no route substitution tests | Representation of manual confirmation and wording. |
| D31A-05 | Fixed transfer adjacency/direction | Optimizer and manual edit invariants | Exact representation across days and itinerary edges. |
| D31A-06 | Preserve commitments and report infeasibility | Known conflict diagnostics | Conflict taxonomy and completeness. |
| D31A-07 | Fixed/planned/optional classes | Persistence/class validation tests | Legacy classification and entry granularity. |
| D31A-08 | Keep all planned activities or report infeasibility | Mandatory inclusion tests | “Feasible” semantics with unknown travel inputs. |
| D31A-09 | MO-GA may select optional destinations | Candidate-pool/objective tests | Approved objective and candidate source. |
| D31A-10 | Feasibility-based destination limit | Capacity and no-forced-extra tests | Numeric constraints and duration evidence. |
| D31A-11 | Preferences and approved criteria only | CARS boundary and ranking tests | Weights/normalization; preference confirmation. |
| D31A-12 | Missing/unverified travel time is unknown | Null/stale evidence propagation tests | Approved source/threshold rules. |
| D31A-13 | Provenance/source/freshness on travel-time records | Evidence schema/parse tests | Approved source categories and required timestamps. |
| D31A-14 | Retain stale records but treat unverified | Staleness transition tests | Source-specific freshness rules. |
| D31A-15 | Feasible/Infeasible/Indeterminate | Predicate/aggregation tests | Exact aggregation and proof rules. |
| D31A-16 | Verified core; exclude optional unknowns | Optional exclusion and core-state tests | “Verified core” wording when mandatory core unknown. |
| D31A-17 | Explicit confirmed manual edit for fixed commitment | Confirmation/validation/invalidation tests | History/audit expectations and conflict UX. |
| D31A-18 | Versioned backward-compatible Hive migration | Legacy format fixture tests | Target version and legacy unknown handling. |
| D31A-19 | Recoverable migration, preserve originals | Failure injection/recovery tests | Platform implementation and backup durability. |
| D31A-20 | Automatic startup migration | Startup gate/idempotency tests | Locking/commit marker semantics. |
| D31A-21 | Isolate itinerary on failure, keep safe features | Feature gating/retry tests | Record-level vs whole-feature isolation. |
| D31A-22 | Clearly labeled Indeterminate draft | Artifact/feasibility separation tests | Exact labels, save/review semantics. |

## 11. Proposed implementation dependency roadmap

Each phase requires a separate explicit coding authorization. Database and remote security work must remain separate from local Flutter/Hive work.

| Phase | Objective and likely files | Dependencies | Tests / exit criteria | Risk / authorization |
|---|---|---|---|---|
| 0. Contract decisions | Decision record; no code | Owner/architect closes leg mode mutability, class granularity, legacy policy, feasibility aggregation, catalog registry/placement, evidence rules | Signed versioned contract with approvers, rationale, evidence | No implementation begins; separate code authorization still required. |
| 1. Local value types | `itinerary_draft.dart`, new transport/evidence model files | Phase 0 | Pure model tests: codecs, IDs, null/unknown, constraints | Local code only; no database. |
| 2. Hive v2 migration/recovery | `local_itinerary_draft_store.dart`, startup/bootstrap, local repository | Phase 1 plus platform recovery design | Version-1 fixtures, malformed input, backup/rollback/retry/platform failure injection | High data-loss risk; explicit code authorization and recovery review. |
| 3. Profile preference compatibility | `tourist_planning_profile.dart`, profile service/adapter, `planning_preferences_page.dart`, `plan_page.dart` | IDs and preference confirmation contract; D29-09 field contract for remote persistence | Nullable round-trip, legacy aliases, explicit selection precedence, CARS remains fail-closed | Remote profile write fields need approved schema/A-14; can isolate codec UI from persistence. |
| 4. Manual/circuit leg editing | manual workflow, planner screens, circuit flow, draft review screens | Phases 1–2; owner mode-lock rule | Mixed mode, preserved constraints, edit confirmation, source draft immutability | Must not claim route feasibility without evidence; separate authorization. |
| 5. Evidence and feasibility service | new local evidence/assessment types, CARS travel assessor integration | Approved source and freshness rules | State predicates, unknown/stale/proven-conflict tests | No external provider integration without approval. |
| 6. Constrained optimizer | `moga_engine.dart`, manual adapter, circuit adapter, generated draft builder | Phases 1, 4, 5; objective decisions | Property/invariant tests, deterministic seeds, infeasibility/indeterminate cases | Major algorithm redesign; dedicated approval and performance review. |
| 7. Indeterminate draft UX | plan/review/generated screens | Feasibility contract and optimizer results | No feasible-label leakage; excluded optional reason display | Product wording and accessibility review. |
| 8. CARS and security boundaries | CARS preparer/provider paths; only after approved evidence policy | D29-06/09/11, D31A-11–14; A-14 where remote data involved | Unverified values never scored; unconfirmed preference stays unavailable | No CARS evidence schema or remote catalog without explicit approvals. |
| 9. Separate canonical DB work | schema manifest, later migration task | D29 closure, A-09/A-11/A-13/A-14 | Local clean install, RLS adversarial tests, backups | SQL/migrations only under separate authorization; A-15/A-16 remain separate. |

**Smallest safe first coding task (after authorization):** implement the pure local transport identifier codec and catalog model with tests only, using an approved ID registry and legacy aliases. It must not change Hive persistence or remote schema until the migration and catalog-placement contracts are approved. As of this document, those prerequisites are not closed, so no coding task is ready to start.

## 12. Test acceptance matrix

Future acceptance criteria only; not executed here.

| Feature | Required tests | Acceptance |
|---|---|---|
| Catalog IDs and aliases | Every initial concept, aliases `public transportation`/`publicTransportation`, unknown/inactive values, version upgrade | Stable ID round-trip; unknown preserved as unsupported; no silent substitution. |
| Profile vs leg choice | Null profile, suggestion, explicit trip/leg, profile edit | Profile is nullable; explicit choice always wins; no unintended per-leg overwrite. |
| Leg graph | Directed consecutive endpoints, duplicate/missing IDs, mixed land/public/water | Valid path only; mode tied to intended leg; invalid references rejected. |
| Fixed commitments | Schedule preservation, endpoint order/adjacency, mode identity, edit confirmation | Ordinary optimize cannot change; explicit edit validates and invalidates feasibility. |
| Commitment classes | Fixed/planned/optional behavior and provenance independence | Only optional omitted; planned retained; fixed never mutated. |
| Feasibility tri-state | verified input, proven contradiction, unknown/stale source, aggregate combinations | State follows approved predicates; unknown never equals zero or infeasible. |
| D31A-16/22 | Unknown core vs unknown optional | Draft can be Indeterminate with core retained; unknown optional excluded and explained; never called verified feasible. |
| MO-GA operators | Initial population, crossover, mutation, selection, block preservation, optional bitset | All generated chromosomes satisfy hard constraints or are rejected; no repair weakens commitments. |
| Unknown travel inputs | Missing duration, unavailable water evidence, stale source | No numerical feasibility claim; water edge remains fixed; no land substitution. |
| Pareto/objectives | Approved objective inputs only, unavailable criteria, deterministic tie behavior | No unverified rating/price/transport data used numerically; selected candidate satisfies constraints. |
| Manual planner | Reorder, remove, day assignment, mode edit | Fixed/planned protections apply; conflicts surfaced; draft remains local. |
| Circuit planner | Existing circuit grouping plus fixed/planned/optional constraints | Circuit semantics preserved; unsupported constraint returns explicit state, not silent flattening. |
| Hive migration | Format-1 legacy fixture, each alias, unknown field/mode, malformed and interrupted migration | Original preserved; staged conversion validated; idempotent retry; no partial new reads. |
| Startup recovery | backup failure, staging failure, commit failure, restart and retry | Itinerary feature isolated; unrelated safe features remain; originals readable/recoverable. |
| CARS boundary | unconfirmed preferences, unverified rating/price, unknown travel time | Such values do not create numeric criterion scores or verified route feasibility. |
| Scope and persistence | static repository/query scan and local test fakes | No server itinerary/reservation/payment writes; no unapproved CARS evidence relation. |

## 13. Remaining owner and reviewer approvals

1. **Catalog:** exact stable IDs, category values, active/inactive behavior, completeness/update governance, and approval of bundled-local placement; confirm no A-13 scope amendment is required for the selected initial implementation.
2. **Leg semantics:** whether explicit per-leg choices are locked during optimization, how modes are assigned to optimizer-created adjacency, and whether profile suggestions initialize only new empty legs.
3. **Commitments:** exact schedule fields, all-day/timed semantics, timezone requirements, transfer/stop granularity, and behavior for incomplete tourist-entered details.
4. **Legacy:** owner approval for a legacy-unclassified review state; classification cannot be inferred from inclusion/provenance.
5. **Feasibility:** predicates, aggregation precedence, what evidence counts as verified, treatment of estimates, “verified core” interpretation, conflict diagnostics, and whether a mandatory unknown makes entire artifact Indeterminate (recommended yes).
6. **Optimization:** approved objectives/weights/normalization, optional candidate source, tie-breaking, and feasibility limits. D31A-11 forbids unsupported numerical evidence.
7. **Transport source:** approved source categories and source-specific freshness. No automated water verification before authoritative maintained source approval.
8. **Hive recovery:** platform-specific backup durability, atomic/recoverable commit, malformed-record isolation scope, backup retention, and user recovery UX; demonstrate failure injection before claiming data safety.
9. **Security/policy:** A-09 audit/settings, A-11 retention, A-14 independent security review for any remote behavior; A-13 scope closure; separate A-15/A-16 approvals for remote initialization/deployment.
10. **Implementation:** explicit authorization for each coding phase. Owner decisions alone do not authorize code or tests.

No owner name, role, date, or policy version is inferred in this document.

## 14. Final coding-readiness assessment

| Readiness option | Assessment |
|---|---|
| A. Ready for coding | No. Core model, feasibility, optimizer, and migration semantics remain unresolved. |
| B. Ready for limited coding with restrictions | No. Even the smallest safe codec/catalog slice depends on an approved stable-ID registry and placement decision; explicit implementation authorization is absent. |
| C. Not ready for coding | **Selected.** Critical technical contracts, evidence rules, catalog scope, Hive recovery design, and coding authorization remain open. |

The smallest safe next action is decision closure for the ten approval areas above, followed by a separately authorized local-only transport codec/catalog-model task. Do not start database or optimizer implementation from this specification. A-14, A-15, and A-16 remain independent gates; no remote operation is authorized.

## 15. Validation and closeout

- Owner directions D31A-01–D31A-22 and Task 29/30 decisions are represented as selected directions, never recast as implementation authorization.
- Source inspection covered the current model, MO-GA loop/operators, adapter, local Hive format/read/write path, profile service/adapter, and CARS confirmation boundary.
- No tests, analyzer, or build were run. Tests in this document are proposed acceptance criteria.
- No source, test, configuration, SQL, migration, Hive data, database, or Supabase state was changed or accessed.
- Existing working-tree modifications and untracked files were preserved.
- `git diff --check` and the new document whitespace check: recorded after file creation below.

