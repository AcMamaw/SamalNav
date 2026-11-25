# Task 33A — SamalNav Final Technical Contract Closure

**Project:** SAMAL NAV
**Review date:** 24 November 2026 (Asia/Manila)
**Status:** Technical specification closure; no implementation performed.
**Authorization:** Documentation and read-only repository inspection only. No code/test changes, SQL, migrations, Hive changes, database access, or Supabase access.

## 1. Executive determination

This document closes a proposed technical contract for the selected transportation, itinerary, feasibility, MO-GA, and Hive behaviors. It refines but does not alter owner selections recorded in Tasks 26–32B Rev 1. Exact D32A Option A selections are treated as confirmed by the conversation record in Task 32B Rev 1; their omitted original worksheet wording is not invented.

The contracts below are sufficiently specific to submit a **separate, narrowly scoped coding authorization review** for a pure local transportation catalog model and codec. They do not authorize coding. Full Hive migration/recovery and constrained MO-GA implementation require platform failure-injection and algorithm acceptance plans, and remain outside that first slice. A-09/A-11/A-13/A-14 conditions and A-15/A-16 execution gates remain independent.

**Readiness statement:** Technical contracts are sufficiently complete for review of the isolated first task described in Section 9, once the stable identifier/category/capability table below is accepted as the engineering contract. The full application is not yet ready for broad implementation or database/deployment work. This specification grants no implementation authorization.

## 2. Decision context and source evidence

Owner selections are preserved in Tasks 30, 31A, and 32B Rev 1. This task does not reopen those decisions. Task 32B Rev 1 records all D32A-01–D32A-22 as Option A, and records that original worksheet wording is incomplete. Technical field names and rules in this document are engineering specification, not additional owner approvals.

Read-only source checks confirm:

- `lib/models/itinerary_draft.dart`: five-value `PreferredTravelMode`, one nullable trip-wide mode, `RequiredTransferKind { ferry, boat }`, `RequiredTransfer` with directed destination IDs and kind, `DraftStop` without commitment class, and no generic leg model.
- `lib/services/local_itinerary_draft_store.dart`: `samal_nav_local_itinerary_drafts_v1`, `formatVersion = 1`, JSON string records, enum `.name` serialization, and strict rejection of unsupported versions while leaving original data unchanged.
- `lib/algorithms/moga_engine.dart`: `RouteChromosome.order` is a permutation of destination indexes; population initialization shuffles indexes; fitness uses a geometric distance matrix multiplied by 1.3 and average speed; tournament selection uses rank/crowding; crossover is order-preserving segment fill; mutation swaps indexes; generation count is the stopping rule. No protected-block repair or evidence-aware feasibility exists.
- `lib/algorithms/manual_selection_moga_adapter.dart`: passes included stops, available hours, average speed (default 30 km/h), and origin; does not pass modes, commitments, or travel-time evidence; rejects circuit drafts.
- `pubspec.lock`: resolves `hive` 2.2.3 and `hive_flutter` 1.1.0. This audit does not claim transaction/crash-atomicity guarantees from these versions; those require package-source/platform validation and failure-injection testing.
- `lib/services/tourist_planning_profile_service.dart` currently reports preferences unconfirmed. `lib/algorithms/cars_assessment_input_preparer.dart` blocks interest/activity scoring when preferences are unconfirmed.

No tests, analyzer, or build were run. No Supabase project was accessed. Existing working-tree changes are preserved.

## 3. Transportation catalog contract

### 3.1 Catalog structure and exact proposed fields

Catalog is a bundled, versioned, read-only application asset for the initial release. It has no database relation and is not remotely mutable. Catalog updates are app releases. A future remote catalog requires a distinct A-13 scope decision and A-14 security review. Catalog membership never asserts real-world route/service availability.

Proposed typed structures:

```text
TransportCatalog {
  schemaVersion: int,                 // positive, increments on shape changes
  catalogVersion: int,                // positive, increments on registry changes
  categories: List<TransportCategory>,
  modes: List<TransportMode>
}

TransportCategory {
  id: TransportCategoryId,            // immutable lowercase snake_case
  labelKey: String,                   // stable localization key
  parentId: TransportCategoryId?      // null for root; at most two levels
}

TransportMode {
  id: TransportModeId,                // immutable lowercase snake_case
  categoryId: TransportCategoryId,    // must reference a catalog category
  labelKey: String,
  isActive: bool,                      // offer for new selection
  legacyAliases: List<String>,        // decode-only; canonical encoder never emits aliases
  requiresDirectedEndpoints: bool,    // true for ferry/boat
  workflowCapabilities: WorkflowCapabilities
}

WorkflowCapabilities {
  profilePreference: bool,
  manualLegSelection: bool,
  circuitPlanning: bool,
  mogaRouteEvaluation: bool,
  fixedCommitmentCapture: bool
}
```

The catalog intentionally omits operator, route, fare, schedule, duration, verification, and availability fields. Those belong to route/service evidence and user-entered commitment records, not mode identity.

Validation rules:

- `schemaVersion` and `catalogVersion` are positive integers.
- Category and mode IDs match `^[a-z][a-z0-9_]*$`, are unique, and are immutable once published.
- Category parent references exist, contain no cycles, and have maximum depth two.
- Every mode references one category; labels/label keys are non-empty; flags are booleans.
- Each alias maps to exactly one canonical ID and cannot collide with another ID or alias.
- Ferry/boat entries are in `water_transfer` and set `requiresDirectedEndpoints=true`; non-water entries do not set the water category.
- An inactive entry remains decodable; unknown raw IDs are not rejected at decode time, but cannot be newly selected or evaluated as supported.

### 3.2 Registry, categories, and capabilities

Canonical IDs are lowercase snake_case and immutable. IDs are never reused, renamed, or derived from display labels. The initial registry maps the twelve already selected concepts as follows:

| ID | Label | Category ID | Directed endpoints required | Active in bundled catalog |
|---|---|---|---:|---:|
| `walking` | Walking | `land_non_motorized` | No | Yes |
| `bicycle` | Bicycle | `land_non_motorized` | No | Yes |
| `motorcycle` | Motorcycle | `land_motorized` | No | Yes |
| `car` | Car | `land_motorized` | No | Yes |
| `public_transportation` | Public transportation | `public_transport_local` | No | Yes |
| `jeepney` | Jeepney | `public_transport_local` | No | Yes |
| `tricycle` | Tricycle | `public_transport_local` | No | Yes |
| `multicab` | Multicab | `public_transport_local` | No | Yes |
| `van` | Van | `public_transport_local` | No | Yes |
| `bus` | Bus | `public_transport_local` | No | Yes |
| `ferry` | Ferry | `water_transfer` | Yes | Yes |
| `boat` | Boat | `water_transfer` | Yes | Yes |

Root categories are `land`, `public_transport`, and `water`; second-level categories are `land_non_motorized`, `land_motorized`, `public_transport_local`, and `water_transfer`. Their parent IDs are respectively `land`, `land`, `public_transport`, and `water`. Category topology must have no cycles and depth at most two. This compact hierarchy is a technical specification under the selected flexible-catalog direction.

Initial capability policy, independent of `isActive`:

| Mode group | Profile preference | Manual leg selection/recording | Circuit planning | MO-GA route evaluation | Fixed commitment capture |
|---|---:|---:|---:|---:|---:|
| All 12 catalog modes | Yes | Yes | No, until a circuit adapter supports the mode | No, until a verified route provider/evidence path is implemented | Yes |

“Manual leg selection/recording” means the tourist can record a chosen mode; it does **not** mean SAMAL NAV has verified service or route feasibility. “Fixed commitment capture” means local tourist-entered data can be preserved; it does not mean the external operator confirmed it. The false circuit transport-evaluation flags do not disable existing circuit destination-selection functionality; they state that circuit transport feasibility is not yet evaluated. Circuit and MO-GA flags may be enabled per mode only after the corresponding workflow has evidence-backed implementation and acceptance tests. Changing capability flags increments `catalogVersion`.

### 3.3 Alias, version, label, active, and unknown rules

Known aliases are exact, case-sensitive strings in the decoder registry:

| Legacy string | Canonical ID |
|---|---|
| `public transportation` | `public_transportation` |
| `publicTransportation` | `public_transportation` |
| `walking`, `bicycle`, `motorcycle`, `car`, `ferry`, `boat` | Same lowercase ID |

No trimming/case folding beyond explicit aliases is performed; this avoids accidental equivalence. Unknown raw IDs are retained byte-for-byte as `UnsupportedMode(rawId, labelSnapshot?)`. The application displays them as unsupported and disables new route selection, but preserves them on save/load. Inactive known IDs remain decodable/editable as historical values but are unavailable for new selection. Neither unknown nor inactive IDs are silently substituted.

`catalogVersion` begins at 1. Additions are append-only; removals set `isActive=false`; labels may change without changing ID; aliases are retained indefinitely while any supported Hive record may contain them. A decoder supports all published historical catalog versions. It may canonicalize a known alias on a future, separately authorized serialization, but must keep the original raw payload recoverable until migration validation succeeds.

Each persisted leg/commitment stores `modeId` and `labelSnapshot`. The stable ID drives comparisons; `labelSnapshot` preserves historic display when the catalog label later changes. Unknown values preserve their raw identifier and snapshot.

### 3.4 Service availability boundary

Availability is separately modeled per directed route and relevant travel conditions:

```text
RouteEvidence {
  fromEntryId: String,
  toEntryId: String,
  modeId: String,
  durationMinutes: int?,             // null means unknown; never zero by default
  status: EvidenceStatus,             // verified | estimated | unverified | stale | unknown
  sourceId: String?,
  recordedAt: DateTime?,
  updatedAt: DateTime?,
  validForDate: DateTime?,
  timeZoneId: String?,
  reasonCode: String?
}
```

Only `verified` evidence from an approved source with required provenance/freshness may establish route-time feasibility. `estimated`, `unverified`, `stale`, `unknown`, missing source, or unsupported mode cannot establish Feasible. D31A-04 means tourist-entered ferry/boat details remain unverified by SAMAL NAV absent a separately approved authoritative source. The system must not fabricate service operators, departures, arrivals, fares, or duration.

### 3.5 Serialization examples

Canonical current-mode value:

```json
{"catalogVersion":1,"modeId":"public_transportation","labelSnapshot":"Public transportation"}
```

Legacy value decode only:

```json
{"travelMode":"publicTransportation"}
```

decodes in memory to `modeId: public_transportation`, retaining legacy raw value in migration metadata until a validated migration commits. Unknown mode:

```json
{"modeId":"paratransit_x","labelSnapshot":"Paratransit X"}
```

must survive round-trip without map-to-nearest-mode fallback. The decoder derives “unsupported” from absence of the ID in the catalog; it does not persist a second conflicting support flag.

### 3.6 Catalog acceptance tests

- Validate unique IDs, syntax, category references, maximum category depth, no category cycles, and unique exact aliases.
- Assert all twelve initial IDs, categories, active state, endpoint requirement, and workflow capabilities match this specification.
- Assert canonical encoding uses stable IDs; both public transportation aliases decode; unknown IDs and labels round-trip unchanged.
- Assert inactive mode is readable but cannot be newly selected; workflow flags are independent from active state.
- Assert catalog listing alone never creates `RouteEvidence` or a verified availability state.
- Assert label changes preserve historical `labelSnapshot` and do not change identity.
- Assert catalog schema/version upgrades are deterministic and do not fabricate a missing user preference or leg mode.

## 4. Itinerary and commitment contract

### 4.1 Local record model

All itinerary/commitment records remain local Hive data. No object below represents a SAMAL NAV booking, reservation, provider confirmation, ticket, or payment.

```text
ItineraryDraftV2 {
  draftId: String,
  formatVersion: 2,
  revision: int,
  artifactStatus: Draft | Review | Saved,
  feasibility: FeasibilityAssessment,
  trip: TripContext,
  entries: List<ItineraryEntry>,
  legs: List<ItineraryLeg>,
  commitments: List<FixedCommitment>,
  dependencies: List<ItineraryDependency>,
  legacySource: LegacyReference?
}

TripContext {
  startDate: String?,                  // ISO date, null means not supplied
  durationDays: int,
  availableHoursPerDay: int,
  origin: TripOrigin?                  // selected trip origin, not live GPS
}

TripOrigin { latitude: double, longitude: double, label: String? }

DestinationSnapshot {
  id: String,
  name: String,
  latitude: double?,
  longitude: double?,
  visitDurationMinutes: int?,
  category: String?,
  capturedAt: String?
}

ItineraryEntry {
  entryId: String,
  kind: Stop | Activity,
  commitmentClass: Fixed | Planned | Optional | LegacyUnclassified,
  provenance: List<StopProvenance>,
  destinationId: String?,
  destinationSnapshot: DestinationSnapshot?,
  activityId: String?,
  durationMinutes: int?,
  dayIndex: int?,
  touristSelected: bool,
  isIncluded: bool
}

ItineraryLeg {
  legId: String,
  fromEntryId: String,
  toEntryId: String,
  modeId: String,
  modeLabelSnapshot: String?,
  selectionSource: ExplicitUser | ProfileSuggestion | Optimizer,
  commitmentClass: Fixed | Planned | Optional | LegacyUnclassified,
  commitmentId: String?,
  evidence: RouteEvidence?
}

FixedCommitment {
  commitmentId: String,
  kind: PrebookedTransport | OtherTouristCommitment,
  targetLegId: String?,
  targetEntryId: String?,
  schedule: UserSchedule?,
  revision: int,
  enteredByTourist: bool,
  verifiedBySamalNav: false
}

UserSchedule {
  localDate: String?,                   // ISO YYYY-MM-DD as entered/parsed
  departureLocalTime: String?,          // ISO HH:mm[:ss]
  arrivalLocalTime: String?,
  timeZoneId: String?,                  // IANA ID when known
  departureInstant: String?,            // ISO-8601 instant only when supplied/resolved
  arrivalInstant: String?,
  originalText: String?                 // preserve entry if parse is incomplete
}

ItineraryDependency {
  predecessorId: String,
  successorId: String,
  relation: Before | AdjacentForward | SameProtectedGroup,
  reason: FixedTransfer | FixedSchedule | UserConstraint
}
```

`Draft`, `Review`, and `Saved` are artifact lifecycle states. The allowed lifecycle is `Draft → Review → Saved`; edits from Draft/Review return to Draft. A Saved artifact is not edited in place: a deliberate change creates a new incremented revision in Draft state while preserving the prior saved revision. Feasibility can independently change between states after reassessment and does not drive artifact lifecycle transitions. The mode ID on a leg is per-edge, and the edge always names the directed endpoints. Ferry/boat legs require directed endpoints and preserve the schedule, when entered, in the same fixed commitment revision.

Model validation rules:

- `draftId`, entry IDs, leg IDs, commitment IDs, and dependency endpoints are non-empty; each ID is unique within its own namespace.
- `durationDays` is 1–30 and `availableHoursPerDay` is 1–24, matching current trip validation bounds. Missing optional dates, origin, coordinates, activity duration, schedule, and evidence remain null rather than defaulting.
- A `DestinationSnapshot` has a non-empty ID/name; coordinates are both present or both absent and within geographic bounds; visit duration is null or a nonnegative integer.
- Every leg has two different existing endpoint IDs and one raw/canonical mode ID. A directed mode edge is not inferred from the mode label.
- A fixed commitment targets exactly one leg or one entry, has a positive revision, and persists `enteredByTourist=true`. Tourist-entered transport is never asserted as provider-verified.
- New entries have exactly one of Fixed, Planned, Optional. `LegacyUnclassified` is accepted only during migration/review and cannot enter automatic optimization until explicitly classified.
- Schedule date/time strings must parse strictly when treated as structured values. A timezone must be a valid IANA identifier before local times can be resolved to instants. If information is incomplete or ambiguous, preserve `originalText`; do not guess an offset or resolve DST ambiguity automatically.
- When both instants are present, they must parse and arrival must be after departure. A schedule with only one endpoint or without timezone may be retained but cannot establish schedule feasibility.
- Dependency references must exist; self-edges and precedence cycles are invalid. `AdjacentForward` remains directed.
- For `RouteEvidence`, duration is null or a nonnegative integer; null is unknown. `verified` requires source ID, recorded timestamp, applicable mode/endpoints, and date applicability where route conditions are date-dependent. Missing provenance downgrades evidence to unverified/unknown; it never gets filled with generated values.

### 4.2 Commitment class and ownership semantics

- **Fixed:** tourist-entered pre-booked arrangement. Optimizer cannot delete, replace, reorder internally, reverse, reschedule, or alter the mode/endpoints/schedule. Manual edit requires explicit confirmation and creates a new local revision. Any change invalidates feasibility.
- **Planned:** tourist-selected destination/activity. Retain whenever a feasible solution exists; cannot be silently dropped or demoted. If a proven conflict prevents inclusion, return Infeasible; if evidence is missing, return Indeterminate with the activity retained in the draft.
- **Optional:** optimizer candidate. May be included only when the relevant route/mode/time constraints are supported. Unknown or unsupported optional candidates are omitted with a reason.
- **LegacyUnclassified:** compatibility-only value for format-1 stops whose class cannot be inferred. It is preserved and shown for tourist review but is not eligible for automatic optimization until explicitly classified. This does not replace the three owner-selected classes for new entries.

Provenance (`manualSelection`, `circuit`, `carsRecommendation`) is orthogonal to commitment class. `isIncluded` is also not the commitment class.

### 4.3 Explicit constraints, dependencies, and protected segments

Each leg references two existing entries; the list/order of `entries` defines the candidate sequence, while dependency records impose hard order/adjacency. Validate that all references exist, no dependency self-links, and no `Before` cycle exists. `AdjacentForward(A,B)` means B immediately follows A and cannot be reversed or separated. `SameProtectedGroup` joins connected commitment entries into one indivisible block while preserving their internal order.

Protected blocks are built from connected fixed commitments and their explicit dependencies. Overlapping commitments sharing an endpoint or protected group merge into one ordered block if constraints are consistent. Contradictory direction/order or proven overlapping time windows return Infeasible; unknown times remain Indeterminate. Optimizer may reorder independent blocks and unprotected entries only within legal segments between protected boundaries. It cannot move an entry across a protected boundary if doing so breaks a dependency or leg identity.

An explicit ordinary leg mode attaches to its directed endpoint pair. The optimizer preserves that edge and mode. If a proposed order breaks the edge, the optimizer may retain the pair as an adjacent block; if no legal arrangement exists, it returns an explanatory conflict/Indeterminate result without substituting another mode. A new optimizer-created edge has no mode or duration unless an eligible catalog mode is explicitly selected and its route evidence is evaluated; the optimizer cannot invent a mode.

### 4.4 Editing and serialization rules

Fixed commitment edit flow: show current and proposed fields; require explicit confirmation; validate references, mode, schedule syntax, timezone and internally comparable times; save new revision; preserve previous revision; show resulting conflict/unknown reasons; recompute feasibility. Cancel performs no write. UI must state that editing local details does not modify an external booking.

V2 serialization uses canonical IDs and preserves unknown raw IDs, labels, incomplete schedule text, source snapshots, and class. Unknown enum values are represented by explicit raw-value wrappers, not enum parse exceptions. Absent optional numeric values stay null; no default traveler or travel time is inserted.

Format-1 conversion preserves every existing field. Stops without sufficient classification evidence become `LegacyUnclassified`; no inference from `isIncluded`, provenance, CARS origin, or selection order. Existing `requiredTransfers` are preserved as legacy directed constraints, with the original kind and endpoints; absent schedules remain absent and the corresponding route assessment is Indeterminate. Existing MO-GA outputs remain historical results with their original value/payload and are labeled legacy estimated output; the old Boolean feasibility is not upgraded to verified Feasible.

Example v2 record (illustrative local JSON):

```json
{
  "formatVersion": 2,
  "draftId": "local-draft-42",
  "revision": 3,
  "artifactStatus": "Review",
  "feasibility": {
    "state": "Indeterminate",
    "reasonCodes": ["required_route_evidence_unknown"],
    "assessedRevision": 3
  },
  "entries": [
    {"entryId":"stop-a","kind":"Stop","commitmentClass":"Planned","destinationId":"dest-a","isIncluded":true},
    {"entryId":"stop-b","kind":"Stop","commitmentClass":"Planned","destinationId":"dest-b","isIncluded":true}
  ],
  "legs": [
    {"legId":"leg-a-b","fromEntryId":"stop-a","toEntryId":"stop-b","modeId":"ferry","modeLabelSnapshot":"Ferry","selectionSource":"ExplicitUser","commitmentClass":"Fixed","commitmentId":"commit-7","evidence":{"durationMinutes":null,"status":"unknown","sourceId":null}}
  ],
  "commitments": [
    {"commitmentId":"commit-7","kind":"PrebookedTransport","targetLegId":"leg-a-b","targetEntryId":null,"schedule":{"localDate":"2026-11-24","departureLocalTime":"09:00","arrivalLocalTime":null,"timeZoneId":"Asia/Manila","departureInstant":null,"arrivalInstant":null,"originalText":"9 AM ferry"},"revision":1,"enteredByTourist":true,"verifiedBySamalNav":false}
  ],
  "dependencies": [
    {"predecessorId":"stop-a","successorId":"stop-b","relation":"AdjacentForward","reason":"FixedTransfer"}
  ]
}
```

The record preserves a partial user schedule and unknown service duration without inventing an arrival time. Its `Review` artifact status does not make it Feasible; its assessment remains Indeterminate.

## 5. Feasibility contract

### 5.1 Exact classification rules

Assessment is evaluated against the mandatory core (Fixed + Planned) and any optional candidates proposed for inclusion. It produces exactly one of:

| State | Exact technical condition |
|---|---|
| **Infeasible** | A validated, known contradiction proves the mandatory core cannot satisfy hard constraints. Examples: dependency cycle; reversed fixed directed edge with no legal block ordering; verified travel duration plus verified schedule bounds prove the available interval is exceeded; two complete, timezone-resolved fixed schedules provably overlap incompatibly. Missing evidence alone is never Infeasible. |
| **Indeterminate** | No proven contradiction is present, but any required mandatory-core fact cannot be established: unknown ID/capability, unsupported leg evaluator, missing route time, unavailable or unapproved service evidence, stale/unverified time, incomplete schedule needed for a comparison, or assessment failure. Draft may still be produced under D31A-22, preserving all Fixed/Planned content. |
| **Feasible** | Every mandatory entry and hard dependency is present and valid; every route/mode/time fact necessary to verify the plan has current approved evidence; all required windows/capacity limits pass; no unknown or stale required input remains. Included optional entries individually satisfy the same relevant constraints. |

Aggregation is deterministic: (1) if a hard contradiction is proven, Infeasible; (2) otherwise if any required core condition is unknown/unsupported/stale/unverified, Indeterminate; (3) otherwise Feasible. A computation or parser failure is Indeterminate with an error reason, not Feasible.

### 5.2 Specific edge cases

- **Unknown identifier:** preserve raw value. In mandatory core it makes result Indeterminate. For optional candidate, exclude and explain. Never map to a “close” known mode.
- **Known but unsupported mode/workflow capability:** the app can preserve the selection, but absent a route evaluator it cannot prove feasibility; mandatory leg => Indeterminate, optional candidate => exclude. “Unsupported by this workflow” is not by itself proof that the real-world trip is impossible.
- **Missing/zero duration:** null means unknown. Zero is valid only if explicitly returned by an approved source and semantically meaningful; never use zero as a missing default.
- **Unavailable service evidence:** Indeterminate for mandatory leg; exclude optional candidate. For water modes, D31A-04 means no automatic confirmation without approved maintained source; tourist-entered schedules remain unverified.
- **Stale/unverified evidence:** retain for display/history; not eligible for Feasible. Required stale evidence => Indeterminate.
- **Schedule conflict:** Infeasible only if complete, valid, timezone-resolved data proves a hard contradiction. Missing timezone/date or partial schedule => Indeterminate, not a fabricated time comparison.
- **Optional unknowns:** excluded before final candidate selection; their exclusion does not make an otherwise verified mandatory core Indeterminate. A mandatory core with unknown route remains Indeterminate even if a draft is generated.
- **Indeterminate artifact:** label “Indeterminate — feasibility not verified.” It is a draft artifact, not a verified feasible itinerary. Reassessment is required after any relevant edit or evidence update.

### 5.3 State invalidation

Changing order, membership/class, leg endpoints/mode, schedule/timezone, evidence, destination coordinates/duration, catalog capability, or available trip time invalidates the assessment. Recompute from the current revision. Cached Feasible state cannot survive an input change. Stale assessment is explicitly marked stale/unknown until recalculated.

## 6. MO-GA contract

### 6.1 Chromosome and operators

The current raw-stop permutation chromosome is insufficient. Proposed constrained chromosome:

```text
ConstrainedChromosome {
  orderedBlocksBySegment: List<List<BlockId>>,
  includedOptionalIds: Set<EntryId>,
  assignedDayByBlock: Map<BlockId, int>,
  evidenceAssessmentVersion: int
}
```

Fixed blocks and Planned entries are mandatory genes. Optional selection is a separate inclusion set. Internal fixed block order, mode, endpoints and schedule are immutable data outside the mutable chromosome. Explicit leg modes bind to endpoint pairs and survive legal block movement. Day assignment is a gene only where current trip rules allow it; fixed schedule/day constraints override free assignment.

**Initialization:** validate graph and classify evidence first; group fixed dependencies into protected blocks; retain every planned entry; filter optional candidates to those whose relevant feasibility can be established; produce initial chromosomes by deterministic legal topological ordering per segment and seeded permutations of unconstrained blocks. If there are no legal mandatory arrangements, return Infeasible when contradiction is proven, otherwise Indeterminate.

**Repair:** no deletion/reclassification/mode substitution/schedule change is allowed. A deterministic repair may only reorder free blocks within their segment using a stable topological sort. If repair cannot satisfy a hard relation, reject the child and attach the violated dependency. If the initial population has no valid member, return a classified failure instead of relaxing constraints.

**Crossover:** operate on whole blocks within the same segment. Preserve fixed block membership and internal order. Combine optional inclusion sets only after checking each candidate’s route dependencies. Revalidate all edges after crossover.

**Mutation:** swap or relocate only unconstrained blocks within the same legal segment; toggle only an Optional inclusion gene. Never mutate Fixed/Planned presence, protected internal order, mode, endpoints or schedule. Revalidate after every mutation.

**Selection/fitness:** hard feasibility classification precedes objective comparison. Feasible candidates may be compared only on configured, approved, evidence-supported soft objectives, such as known geographic proximity and approved preferences. Do not use unknown travel minutes, unverified price/rating, catalog presence, or fabricated visit duration numerically. Missing objective data is marked unavailable for the whole comparison dimension or excludes a candidate per an approved rule; it is not scored zero or as favorable. Geometry/average-speed estimates may be displayed only as explicitly non-verified exploratory values and cannot establish feasibility or time capacity.

**Stopping:** retain bounded generation count and deterministic seed for reproducible runs. A wall-clock/resource budget may stop exploration but cannot weaken constraints; return best valid candidate with its correct feasibility state or Indeterminate if mandatory evidence is unknown. No “best effort” candidate is relabeled Feasible.

### 6.2 Pseudocode

```text
assess(input):
  parse known and unknown catalog IDs without fallback
  validate entries, references, explicit modes, schedules and dependencies
  build connected protected blocks; preserve transfer direction/adjacency
  if a proven hard contradiction exists:
    return Infeasible(diagnostics, no constraint relaxation)

  mandatory = all Fixed blocks + all Planned entries
  optional = candidates with required supported modes and evidence
  exclude other Optional candidates and record reason codes
  segments = legal free regions between protected block boundaries
  population = seeded legal permutations of blocks within each segment
  if population is empty:
    return Indeterminate if required inputs unknown else Infeasible

  for generation in 1..limit:
    rank valid chromosomes using approved evidence-backed objectives
    parents = tournament(rank, crowding)
    children = block_crossover(parents)
    mutate_free_segment_order_or_optional_bits(children)
    deterministically_repair_only_free_order(children)
    discard children violating any hard dependency or class invariant

  candidate = choose deterministic best valid chromosome
  resultState = aggregateEvidenceAndConstraints(candidate)
  persist result as Draft with resultState and diagnostics
  return result; never change Fixed/Planned source entries
```

### 6.3 Preserved workflow boundaries

Manual selection continues to let the tourist choose destinations and leg modes; optimization may reorder only within constraints. Circuit selection/grouping remains intact and requires its own adapter implementing the same block constraints. Until such adapter exists, circuit planning remains usable without constrained MO-GA and must not be routed through the current adapter, which rejects circuit drafts. System-generated planning must distinguish CARS-selected/planned destinations from optimizer-selectable optional candidates. MO-GA does not take over CARS scoring.

### 6.4 Deterministic acceptance tests

- Use fixed random seed and repeated runs to prove identical valid input produces identical selected route and diagnostics.
- Across initialization, crossover, mutation and repair: no fixed block splits/reverses; adjacency and endpoints remain exact; planned entries remain present; only optional entries can be excluded.
- Contradictory dependency cycle yields Infeasible with stable conflict IDs.
- Unknown/stale required leg yields Indeterminate, never numeric zero or Feasible.
- Unknown/unsupported optional leg is excluded with stable reason; verified optional candidate may be considered only under approved criteria.
- No operator changes schedule, mode, endpoints, or commitment revision.
- Explicit leg mode survives legal reordering; if edge cannot remain adjacent, result contains a conflict or is Indeterminate without substitution.
- Resource stop returns valid classified result/Indeterminate, never a relaxed or falsely feasible route.
- Existing manual and circuit workflow regression tests preserve selection, day grouping, and circuit identity.

## 7. Hive persistence and recovery contract

### 7.1 Version and non-transactional design constraints

Current format is v1 in `samal_nav_local_itinerary_drafts_v1`. Resolved dependencies are Hive 2.2.3 and hive_flutter 1.1.0. The repository currently calls `Hive.openBox<String>`, `put`, `get`, and reads v1 JSON; it has no recovery journal. This specification does not assume a multi-key or multi-box transaction or automatic rollback. A single awaited `put`/`flush` must not be described as transactionally atomic until verified against this locked version/platform behavior.

### 7.2 Proposed append-only records

Keep the v1 source box unchanged during migration. Use a new v2 data box and a separate recovery metadata box. Proposed keys/records:

```text
draft:<draftId>:rev:<n>     immutable DraftEnvelope {formatVersion, revision, payload, checksum}
journal:<operationId>:<step> immutable JournalEntry {draftId, sourceRevision, targetRevision,
                             sourceChecksum, targetChecksum, phase, timestamp}
commit:<draftId>:<generation> immutable CommitMarker {operationId, revision, checksum, previousMarker}
snapshot:<sourceBox>:<key> immutable RecoverySnapshot {rawValue, checksum, capturedAt}
```

Records are append-only while a recovery operation is active. Avoid updating one mutable “current version” pointer; derive current revision by validating the highest committed marker and its referenced envelope, following the prior marker chain if the newest marker/payload is invalid. Keep source snapshots and prior committed revisions until a reviewed cleanup/retention policy exists.

### 7.3 Save/update state machine

1. Acquire a single-writer local lock; validate input and create idempotent operation ID from draft ID + target revision + payload hash.
2. Save exact prior raw value/checksum into recovery snapshot; await write/flush and read back/verify before proceeding.
3. Append `prepared` journal record; flush/read back.
4. Write immutable target revision envelope to staging namespace; flush/read back; verify checksum, decode and semantic invariants.
5. Append `validated` journal entry only after re-read validation.
6. Append commit marker referencing exact envelope checksum and previous valid marker; flush/read back and validate chain.
7. Only after valid commit marker is observed may repository readers expose target revision. Append `complete` journal entry. Cleanup is separate and deferred.

If any step fails, prior committed revision remains selected. A journal is recovery metadata, not proof a stage is valid. No user data is overwritten or discarded to clear an error.

### 7.4 Startup, interruption, retries and Restricted Safe Mode

Before enabling itinerary APIs, scan journals and validate the committed marker chain and record checksums. Recover deterministically:

| Detected phase/state | Startup action |
|---|---|
| No pending operation; valid commit chain | Enable local itinerary reads/writes after semantic validation. |
| Snapshot missing or checksum invalid | Do not migrate/write; retain source and enter Restricted Safe Mode. |
| Prepared journal, no target envelope | Keep old committed revision; resume idempotently from verified source or offer retry. |
| Target staged, not validated | Re-read/revalidate; commit only if valid; otherwise quarantine stage and keep previous revision. |
| Validated stage, no commit marker | Revalidate and append marker idempotently; if ambiguous, keep old revision and enter Safe Mode. |
| Marker malformed or references missing/invalid payload | Follow prior validated marker chain; if none, isolate itinerary and preserve all raw records. Never guess. |
| Unknown future format or malformed legacy record | Keep raw record read-only/quarantined; do not downgrade, skip silently, or overwrite. |
| Valid latest marker and payload | Expose validated revision; keep recovery source until cleanup policy permits. |

Restricted Safe Mode disables itinerary optimization and destructive editing; offers a non-destructive recovery/status screen; preserves exact source and staged bytes; permits retry only after validation preconditions are met. Other app features may remain available if they do not depend on the affected itinerary store. Do not reset the Hive box or falsely confirm a commitment.

Restoration selects the latest revision whose marker, checksum, decoder and semantic validation all pass. Restored data is read back and revalidated before enabling itinerary functions. If no revision validates, retain all copies and keep the itinerary feature isolated for recovery. Repeated retry with the same operation ID must not duplicate entries or revisions.

### 7.5 Migration and compatibility

For v1 migration, copy raw source records into recovery snapshots first; convert into v2 envelopes in staging; preserve unknown field values and mode aliases; mark stops `LegacyUnclassified`; preserve legacy transfers as directed constraints with absent schedule fields remaining null; retain old MO-GA result payload and mark its feasibility as legacy/unverified. Validate every converted record and dataset references before appending migration commit marker. Only then enable v2 readers. New installs initialize directly with current format.

Hive’s actual durability, write ordering, corruption recovery, backup location, platform shutdown behavior, and multi-box semantics remain subject to package-source analysis and failure injection on supported platforms. This protocol is recoverable by design but is not claimed atomic until those tests pass.

### 7.6 Hive acceptance and failure injection

- Verify v1 alias, null, transfer, unknown field and legacy result fixtures round-trip without loss.
- Terminate execution after every snapshot, journal, envelope, validation, marker and completion write/flush; restart and confirm deterministic recovery.
- Corrupt/remove each record type and validate safe fallback or Restricted Safe Mode.
- Retry every recoverable failure repeatedly; assert no duplicate revisions, entries, markers or silently skipped records.
- Assert readers never expose uncommitted/partially validated target data.
- Assert source v1 raw records remain byte-identical until explicit cleanup eligibility.
- Test new installation, multiple drafts, duplicate IDs, malformed JSON, unknown future version, and disk-full/permission failures.
- Run failure injection for each supported platform before any claim of recovery safety.

## 8. Security and database dependencies

| Decision/gate | Status | Dependency for implementation |
|---|---|---|
| A-09 audit/settings | Owner selected trusted immutable audit and restricted settings; taxonomy, access, redaction, retention and settings allowlist remain open. | Any audit/settings code must use trusted operations and pass security review; unrelated to the pure local catalog slice. |
| A-11 retention | Controlled retention/soft retirement selected; periods, anonymization, account closure, FK behavior and backups remain open. | Required before deletion/retention behavior or database FK actions. Local Hive cleanup also needs a data-retention decision. |
| A-13 scope | Ten-relation candidate scope conditionally approved; exact fields/service compatibility not closed. No catalog relation included. | Bundled catalog avoids scope change. Remote catalog needs separate A-13 scope decision. |
| A-14 security | Least-privilege baseline selected subject to independent review; exact grants/RLS/trusted functions and tests remain open. | Required before any remote catalog, exposed schema, trusted operation, migration execution, or security-sensitive app integration. |
| A-15 non-production | Deferred / not authorized. | Separate target-specific approval after reviewed migration set, local acceptance, hashes, backup/recovery and operator window. |
| A-16 production | Deferred / not authorized. | Separate go/no-go after successful non-production, independent security/release review and recovery evidence. |

No catalog table, server itinerary, reservation, payment, or CARS evidence relation is introduced. No Supabase access, SQL, initialization, or deployment is authorized.

## 9. First coding task preparation

### Proposed task: Pure local transportation catalog and legacy codec

**Files:** create `lib/models/transport_catalog.dart` and `test/transport_catalog_test.dart`. No call sites are changed in this first bounded slice.

**Scope:** implement the catalog records, category validation, twelve stable IDs, exact legacy aliases, unknown/inactive value wrappers, catalog version, historical display labels, and independent workflow capability flags described in Section 3. No Hive or network IO.

**Dependencies:** separate written implementation authorization that references this specification and adopts the registry in Section 3 for this bounded slice. This uses the selected owner direction and does not reopen the transportation decision; if a reviewer finds a conflict with an existing owner condition, return only that conflict for resolution.

**Tests and acceptance:** run focused unit tests in that future authorized task for uniqueness/syntax/category graph; all twelve entries; alias decode/canonical encode; unknown and inactive round-trip/no substitution; capability independence; label update identity; deterministic version behavior. The catalog model cannot create route availability or claim that every mode is routable.

**Exclusions:** no profile/service/UI changes; no Hive writes or migrations; no MO-GA changes; no tests in this current documentation task; no SQL/database/Supabase; no CARS scoring changes.

**Rollback:** remove the isolated model and test file. Because there are no consumers or persisted writes in the slice, rollback requires no data migration and does not affect existing drafts. Future integrations must be authorized separately.

This is the smallest safe proposal, not authorization to implement it.

## 10. Acceptance-test matrix for the complete future contract

| Contract | Minimum acceptance suite |
|---|---|
| Catalog | Registry schema, IDs, aliases, unknown/inactive handling, label snapshot, version and workflow capability matrix. |
| Itinerary model | Entry/leg/dependency references, class/provenance separation, directed endpoints, schedule partial/null handling, invalidation. |
| Fixed commitments | Byte/value preservation through optimization; explicit edit confirmation/revision; no provider or payment claim. |
| Feasibility | Truth table for verified valid, proven conflict, unknown mode, unsupported workflow, missing/stale time, unknown service and incomplete schedule; missing never means zero. |
| Optional selection | Unknown/unsupported candidate excluded with reason; only evidence-supported feasible options considered; mandatory core never displaced. |
| MO-GA | Deterministic seed; legal initialization; block crossover/mutation; repair only free blocks; planned inclusion; fixed adjacency/order; no mode substitution; conflict diagnostics. |
| Manual and circuit | Existing manual selection/day/circuit functionality preserved; constraints use same semantics; circuit is not sent through unsupported adapter. |
| Hive | v1 migration, aliases, legacy unclassified entries, append-only journal/markers, failure injection, startup recovery, safe mode, idempotent retry, validated restoration, new-install path. |
| CARS | Unconfirmed profile preferences, unverified rating/price, catalog membership, unknown/stale transport evidence cannot become numerical scores or feasibility evidence. |
| Security/scope | No unauthorized remote catalog or schema relation; no server itinerary/reservation/payment writes; later RLS/grants tests only under approved security task. |

These are acceptance requirements only. No tests were executed for Task 33A.

## 11. Implementation dependencies and remaining approvals

Technical behavior for the first local catalog slice is specified in Section 3. A new owner decision round is not required for every type or algorithm detail. The remaining gates are:

1. Separate explicit coding authorization naming the catalog model/test-only scope.
2. If the proposed stable registry/capability matrix is not accepted as the technical contract, a narrow review of those exact fields before coding; do not broaden into a new transportation-policy round.
3. Before Hive work: platform-specific Hive 2.2.3 durability/failure analysis, approved backup retention, recovery acceptance fixtures, and Safe Mode UX contract.
4. Before MO-GA work: implementable local types, approved objective/evidence source rules, deterministic property-test suite, and circuit adapter scope.
5. Before account/database/security work: close A-09/A-11/A-13/A-14 as applicable; separate A-15 and A-16 approvals remain mandatory for their respective environment actions.

## 12. Final readiness and authorization statement

**Technical contracts:** sufficiently complete to submit a separate controlled authorization review for the isolated pure local catalog/codec task in Section 9. The full Hive/MO-GA/application contract is specified at design level but still requires platform failure-injection and integration acceptance before those later phases are authorized.

**Project readiness:** not ready for broad application implementation, database changes, or deployment. A-09/A-11/A-13/A-14 conditions remain; A-15/A-16 are deferred. The original D32A worksheet wording is incomplete in the repository, but confirmed Option A selections and the technical details available in this task are carried forward without inventing owner approval.

**Implementation authorization:** not granted. No source or test modifications, SQL, migrations, Hive changes, database access, or Supabase access occurred.

## 13. Validation and closeout

- Current Hive lockfile versions and repository usage were inspected read-only.
- Existing working-tree changes were preserved; the manuscript was not opened or modified.
- No tests, analyzer, or build were run.
- `git diff --check` and new-document whitespace validation: passed (final results below).

