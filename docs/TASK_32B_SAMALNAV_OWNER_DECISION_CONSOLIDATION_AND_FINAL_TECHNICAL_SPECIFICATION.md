# Task 32B — SamalNav Owner Decision Consolidation and Final Technical Specification

**Project:** SAMAL NAV
**Review date:** 24 November 2026 (Asia/Manila)
**Status:** Owner selections reconciled from available records and conversation; full D32A worksheet wording remains partly open.
**Authorization:** Documentation and read-only repository inspection only. No application implementation authorized.

## 1. Executive summary

This document consolidates Task 29 and D31A-01–D31A-22 selections, and now records D32A-01–D32A-22 as **Option A** based on the owner’s explicit confirmation in the current conversation. The repository still contains no Task 32A worksheet. The exact full option wording and conditions for D32A-01–D32A-18 were not supplied; for D32A-19–D32A-22, the current request supplies the decision topics but not complete worksheet responses. The selections are confirmed; details requiring documentary reconciliation remain open. No option text or technical conditions are invented.

The technical sections below are proposed specifications, not owner approvals. They define a bundled versioned transportation catalog; separate catalog identity from service availability; model fixed, planned, and optional itinerary content; preserve fixed transfer blocks; distinguish artifact lifecycle from Feasible/Infeasible/Indeterminate; and describe recoverable Hive staging. The existing app has none of the full per-leg, commitment-class, evidence, or recovery contracts required by these proposals.

**Readiness: C. Not ready for coding.** Although all 22 D32A Option A selections are now confirmed in conversation, their complete worksheet wording/conditions are not available for D32A-01–D32A-18 and detailed responses for D32A-19–D32A-22 remain to be reconciled. Stable catalog identifiers and capability policy, fixed-commitment semantics, feasibility acceptance predicates, and platform-tested Hive recovery also remain unresolved. These are owner-selected architectural directions, not implementation authorization.

## 2. Decision hierarchy and evidence limits

### 2.1 Evidence classes

- **Previously owner-selected:** a direction recorded in Task 30 or the Task 31A owner decision matrix. It remains subject to its stated conditions and policy gates.
- **Task 32B requirement:** a requested specification topic. The owner has separately confirmed Option A for every D32A ID in the current conversation; topic summaries and the selected option do not reconstruct omitted worksheet language.
- **Source-verified:** observed in repository code or dependency lockfiles at inspection time. It does not establish deployed database state or external service availability.
- **Engineering proposal:** recommended technical behavior requiring owner/architect acceptance where it affects product semantics.
- **Unresolved approval:** a decision reserved for product, policy, privacy, architecture, or independent security review.

Controlling project documents are Tasks 26–31A Final as identified in the request. Task 32A was not found in `docs/`, and repository history search did not locate it. The current owner message confirms Option A for D32A-01 through D32A-22 and supplies the topic sequence in Section 3. That message is the selection evidence for this revision. It does not contain complete original worksheet wording; for D32A-19–22 it supplies topic descriptions only. No full option text or additional conditions are inferred.

### 2.2 Read-only repository findings

- `pubspec.yaml` pins `hive_flutter: ^1.1.0`; `pubspec.lock` resolves `hive_flutter` **1.1.0** and `hive` **2.2.3**. This records dependency versions, not a guarantee of transaction or crash-atomicity semantics.
- `LocalItineraryDraftStore` uses box `samal_nav_local_itinerary_drafts_v1`, `formatVersion = 1`, JSON string records, and `storageState: localDraft`. `_readRecord` rejects other versions and leaves the raw record unchanged. No staged migration, journal, backup/restore, startup gate, or retry sequence exists in the inspected store.
- `TripConfiguration` has one nullable trip-wide `PreferredTravelMode`; `RequiredTransfer` contains directed destination IDs and `ferry`/`boat` kind only. `DraftStop` has `provenance`, selected activities, `isIncluded`, order, and optional day; no commitment class or per-leg mode exists.
- `RouteChromosome` is a permutation of destination indexes. Initial population shuffles assigned indexes; fitness uses geometric distance scaled by 1.3 and average speed; selection uses rank/crowding; crossover is order-preserving segment fill; mutation swaps two indexes. No repair operator or hard transfer/commitment constraint validation is present. Generation count is the stopping rule; no evidence-aware early stop is shown.
- `ManualSelectionMogaAdapter` passes included stops, a default average speed of 30 km/h, hours/day and origin to `MogaEngine`. It does not pass required transfers, mode or evidence. It explicitly rejects circuit drafts.
- Profile mode is a required string in `TouristPlanningProfile`; the UI lists five current values. Profile and trip values are encoded differently (`public transportation` versus enum/Hive `publicTransportation`). The profile service always reports preferences unconfirmed; the CARS preparer withholds interest/activity scoring if unconfirmed.
- Tests and prior reports were inspected as documentary evidence only. No tests, analyzer, or build were run for Task 32B. No Supabase project was accessed.

## 3. Consolidated owner decision register and master traceability matrix

Each decision ID is represented once in this matrix. D29 and D31A selections are transcribed from the available Task 30 and Task 31A records. The D32A Option A selections are confirmed by the owner's conversation instruction for this revision; full worksheet language remains to reconcile as shown per row. “Acceptance tests” are proposed future tests; no test result is claimed.

| Decision ID | Owner selection / evidence status | Technical specification | Affected components | Acceptance tests | Remaining blocker |
|---|---|---|---|---|---|
| D29-01 | A — Retain username login; case-insensitive uniqueness. | Normalize identically at register, update, lookup and unique enforcement. | Profile/auth model, service, login/register UI. | Alias/collision/lookup tests. | Unicode/case/trim/reserved-name and legacy collision policy. |
| D29-02 | C — Defer unused establishment contacts. | Only verified consumed business fields; personal profile contact remains distinct. | Establishment model/service/forms. | Field round-trip and UI payload audit. | Complete form/service evidence. |
| D29-03 | A — Optional destination-to-establishment link; one establishment may associate to many destinations. | Nullable relationship; no duplicate owner field. | Destination/establishment models/services. | Null, ownership and relation tests. | Product relationship confirmation and retention-policy FK action. |
| D29-04 | A — Optional verification destination link set by trusted approval operation. | Atomic, idempotent approval; reviewer-controlled linkage. | Verification model, admin service/UI, trusted operation. | New/correction/retry/unauthorized tests. | Supported new-vs-correction workflow and duplicate policy. |
| D29-05 | A — Unique linked favorite per user/destination; permit multiple null-ID snapshots. | Partial uniqueness only for non-null destination identity. | Favorite repository/UI. | Duplicate and undo conflict tests. | Snapshot behavior and retention/FK handling. |
| D29-06 | C — Ratings/prices may display, but unverified values are not CARS evidence. | Omit authoritative scoring use pending source and stewardship. | Destination/favorite models, CARS preparer. | Missing/stale/unverified never yields numeric score. | Authoritative source, scale/units, steward, freshness. |
| D29-07 | A — Separate publication lifecycle. | Explicit approved states/transitions; publication independent of verification. | Destination/establishment models, listing/admin UI. | State mapping and public visibility tests. | Exact vocabulary, transitions, actors. |
| D29-08 | A — Separate verification lifecycle. | Trusted reviewer transitions and metadata. | Verification/destination/establishment services/UI. | Transition, actor and unauthorized tests. | Exact states and transition authority. |
| D29-09 | A — Persist explicit preference confirmation Boolean/time; edits reset confirmation. | Confirmation is explicit, not inferred from populated fields. | Tourist profile/service/UI, CARS input. | Edit-clear, reconfirm, timestamp and CARS gate tests. | Confirmation scope/version and UI contract. |
| D29-10 | C — Detailed adults/children/elders counts with nonnegative integers and consistent total. | No age cutoffs or pricing semantics inferred. | Profile/trip models and preference UI. | Null/partial/count-equation tests. | Adults stored vs derived, completeness and equality rule. |
| D29-11 / D29-11A | A nullable profile preference; later D29-11A selects flexible catalog Option C and names 12 initial concepts. | Keep profile suggestion separate from trip/leg choice; use catalog contract below. | Profile, transport catalog/codec, planner UI. | Nullability, alias, precedence and inactive-mode tests. | Stable IDs, category registry, governance, A-13 scope. |
| D29-12 | Rating Option A after UI scale verification; Duplicate-review Option 2 (multiple dated reviews). | Integer scale and no author/subject unique constraint. | Review model/repository/UI. | Exact scale boundaries, duplicate dated review tests. | Actual submission min/max and aggregation policy. |
| D29-13 | A — Moderation lifecycle with trusted transitions. | Only eligible published reviews exposed; aggregate is separately governed. | Review/admin services/UI. | Transition and public filter tests. | States, appeal/author visibility, aggregate policy. |
| D29-14 | C — All-day and timed events, local date, timezone, optional instants. | All-day omits instants; timed requires valid start/end and end after start. | Event model/service/UI. | Date, interval, timezone/DST tests. | Confirm current app workflows and exact constraints. |
| D29-15 | A — Structured trusted audit records, conditional on A-09. | Server actor/time, versioned action/outcome/resource, restricted access. | Audit service/admin callers. | Client denial, redaction, access tests. | Taxonomy, retention and A-09 approval. |
| D29-16 | A — Typed/versioned allowlisted settings, conditional on A-09. | Trusted writes; validate keys/types; no secrets. | Settings service/admin UI. | Allowlist, type, privilege tests. | Exact keys, readers, emergency path and A-09. |
| D29-17 | A — Controlled account closure, anonymization and historical retention. | Per-relation deletion/retention; no blanket cascade assumption. | Profile/account lifecycle and FK contract. | Closure/anonymization/backup tests. | A-11 periods, actors, lawful basis, backup policy. |
| D31A-01 | C — Flexible transportation vocabulary scope. | Versioned catalog; no assumption that every workflow supports every mode. | Catalog/codec/UI/Hive. | All initial entries and unsupported capability tests. | Exact ID/category/capability registry; A-13 scope. |
| D31A-02 | A — Independent transportation per itinerary leg. | Leg has explicit endpoints and catalog mode; profile suggestion cannot override explicit choice. | Draft model, planner, manual/circuit/MO-GA. | Mixed-mode path and precedence tests. | Leg identity and mode-lock behavior during reorder. |
| D31A-03 | A — Pre-booked ferry/boat are fixed constraints. | Local commitment immutable during ordinary optimization. | Commitment model/Hive/MO-GA/UI. | Value and schedule preservation. | Schedule representation and partial details. |
| D31A-04 | C — No automated water verification; manual confirmation only. | Tourist input stays unverified by SAMAL NAV; no fabricated service facts. | Local commitment/UI/route evidence. | Unverified label/no substitution tests. | Manual confirmation wording and representation. |
| D31A-05 | A — Strict transfer direction and adjacency. | Endpoints consecutive; no reversal or inserted unrelated stop. | Optimizer/manual/circuit workflows. | Property tests for route invariants. | Multi-day and connected transfer semantics. |
| D31A-06 | A — Preserve commitments and report infeasibility. | Never relax protected constraints to produce apparent success. | Feasibility service/MO-GA/UI. | Proven conflict diagnostics. | Conflict taxonomy and completeness. |
| D31A-07 | A — Three commitment classes: fixed, planned, optional. | Class is distinct from provenance and transport. | Entry/activity/transfer model, Hive. | Class preservation and no demotion tests. | Class granularity and legacy classification. |
| D31A-08 | A — Preserve planned activities when feasible; otherwise report infeasibility. | Planned items are mandatory; optional items yield first. | MO-GA/manual/circuit. | Mandatory inclusion/conflict tests. | Interaction with unknown core route evidence. |
| D31A-09 | A — MO-GA selects feasible optional destinations. | Optional inclusion is explicit and constrained by approved objectives. | Candidate provider, optimizer, review UI. | Candidate inclusion/exclusion tests. | Candidate pool, objectives, weights. |
| D31A-10 | A — Feasibility-based destination limits. | No forced extras; fit only if constraints/evidence allow. | Optimizer/feasibility. | Capacity boundary tests. | Accepted duration/evidence basis. |
| D31A-11 | A — Preferences and approved criteria prioritize optional destinations. | No unverified rating, price or unsupported transport numeric input. | CARS boundary/optimizer. | Evidence gating tests. | Weights, normalization, preference confirmation. |
| D31A-12 | A — Missing/incomplete/unverified travel time is unknown. | Unknown has no numeric duration and cannot establish feasibility. | Evidence model/optimizer/UI. | Missing and stale propagation. | Source/threshold approval. |
| D31A-13 | A — Travel-time records include source, endpoints, mode, timestamps and status. | Provenance/freshness accompany any route-time record. | Evidence value/repository. | Required-field and unknown-state tests. | Approved sources and freshness policy. |
| D31A-14 | A — Retain stale data but treat as unverified. | History preserved; stale record cannot establish Feasible. | Evidence lifecycle/cache. | Staleness and history tests. | Source-specific expiry thresholds. |
| D31A-15 | A — Feasible, Infeasible, Indeterminate. | Evidence-aware predicates and aggregation. | Assessment/MO-GA/result UI. | State truth table and mixed-leg aggregation. | Exact predicates and precedence. |
| D31A-16 | A — Generate verified core; exclude optional destinations with unknown feasibility. | Unknown optional candidates omitted and explained. | Candidate filtering/review. | Optional unknown exclusion. | Meaning of “verified core” if required core is unknown. |
| D31A-17 | A — Protect fixed commitment from ordinary edit; explicit confirmed manual edit allowed. | Confirm, validate, show changes/conflicts, reassess. | Edit UI/local store/assessment. | Cancel/confirm/invalidation tests. | History expectations and editing UX. |
| D31A-18 | A — Backward-compatible versioned Hive migration. | Legacy values readable; no invented class. | Hive model/store/startup. | Format-1 fixtures and alias decoding. | Target version and unknown legacy policy. |
| D31A-19 | A — Recoverable migration with source preservation and retry. | Staging/recovery; no record discard. | Hive journal/backup/recovery. | Failure injection and restore tests. | Storage platform atomicity and backup durability. |
| D31A-20 | A — Automatic versioned startup migration. | Do not expose new-format data until validation and commit. | App startup/repository gate. | Restart/idempotency tests. | Locking and commit-marker mechanism. |
| D31A-21 | B — Isolate itinerary after migration failure; keep unrelated safe features available. | Preserve original data, show clear failure and retry route. | App startup/feature gate/recovery UI. | Safe-mode and retry tests. | Isolation granularity. |
| D31A-22 | A — Clearly labeled Indeterminate itinerary draft. | Artifact lifecycle is separate; never present Indeterminate as verified feasible. | Result model, persistence, review UI. | Artifact/feasibility independence tests. | Exact labels/save semantics. |
| D32A-01 | **Option A — owner-selected in conversation.** Topic: transportation catalog architecture. | Bundled/versioned local catalog is specified below as the technical proposal; exact worksheet wording/conditions were not supplied. | Catalog, codec, Hive, UI. | Catalog acceptance suite proposed below. | Reconcile full D32A-01 worksheet text and technical conditions. |
| D32A-02 | **Option A — owner-selected in conversation.** Topic: stable identifiers. | Lowercase snake_case ID design below is a proposal, not recovered worksheet wording. | Catalog/codec/UI. | ID uniqueness and immutability tests. | Reconcile exact ID selection/conditions. |
| D32A-03 | **Option A — owner-selected in conversation.** Topic: legacy compatibility. | Alias decoder and unknown-value preservation below are proposed technical mapping. | Catalog data/codec/Hive. | Version/alias tests. | Reconcile migration aliases and stated conditions. |
| D32A-04 | **Option A — owner-selected in conversation.** Topic: inactive modes. | Keep inactive entries readable, block new selection, never substitute; proposal only. | Capability registry/workflows. | Inactive/history tests. | Reconcile exact inactive-mode policy. |
| D32A-05 | **Option A — owner-selected in conversation.** Topic: categories. | Two-level taxonomy proposed below; exact category values are not owner-verified. | Catalog/update process. | Category validation tests. | Reconcile full category hierarchy and wording. |
| D32A-06 | **Option A — owner-selected in conversation.** Topic: typed attributes. | Typed catalog fields and workflow capability flags proposed below. | Catalog model/codec. | Required fields and type tests. | Reconcile required attribute set and conditions. |
| D32A-07 | **Option A — owner-selected in conversation.** Topic: service availability. | Catalog identity remains separate from route/date service availability. | Evidence model/availability UI. | Catalog must not imply service tests. | Reconcile exact availability states and requirements. |
| D32A-08 | **Option A — owner-selected in conversation.** Topic: catalog versioning. | Versioned catalog and compatibility policy proposed below. | Catalog/update process/Hive. | Idempotent version update tests. | Reconcile version policy conditions. |
| D32A-09 | **Option A — owner-selected in conversation.** Topic: historical labels. | Preserve saved display-label snapshot when labels change; proposal only. | Catalog, local draft model/Hive. | Label-change preservation tests. | Reconcile exact history behavior. |
| D32A-10 | **Option A — owner-selected in conversation.** Topic: unknown identifiers. | Preserve raw ID and render unsupported; no fallback mapping. | Codec/Hive/UI. | Unknown identifier round-trip tests. | Reconcile unknown-value recovery behavior. |
| D32A-11 | **Option A — owner-selected in conversation.** Topic: MO-GA compatibility. | Workflow capability flags are independent; existing outputs remain historical and are not upgraded to verified feasibility. | Catalog, MO-GA adapter/result model. | Existing result preservation tests. | Reconcile allowed MO-GA support and compatibility conditions. |
| D32A-12 | **Option A — owner-selected in conversation.** Topic: usage permissions. | Per-workflow capability flags gate selection/use; they do not grant security authorization. | Catalog and workflow services/UI. | Per-workflow permission matrix tests. | Reconcile what “permissions” means for user vs workflow access. |
| D32A-13 | **Option A — owner-selected in conversation.** Topic: unsupported modes. | Unsupported/inactive modes remain visible and are never silently substituted. | Codec, UI, route assessment. | Unsupported-mode no-substitution tests. | Reconcile exact user actions for unsupported values. |
| D32A-14 | **Option A — owner-selected in conversation.** Topic: mixed supported/unsupported transportation. | Support known leg choices independently; unsupported legs make route outcome unknown/unsupported, not silently remapped. | Leg model, MO-GA, manual/circuit UI. | Mixed capability path tests. | Reconcile exact mixed-route behavior and conditions. |
| D32A-15 | **Option A — owner-selected in conversation.** Topic: unsupported legs connected to fixed commitments. | Keep the fixed commitment and dependency; do not optimize through or substitute the unsupported leg. | Commitment model/MO-GA. | Connected fixed-edge and unsupported-mode tests. | Reconcile exact worksheet response and conditions. |
| D32A-16 | **Option A — owner-selected in conversation.** Topic: protected segment boundaries. | Build optimization segments around immutable commitment boundaries; boundary values are not crossed or rewritten. | Block construction/MO-GA. | Segment boundary property tests. | Reconcile exact boundary definition and conditions. |
| D32A-17 | **Option A — owner-selected in conversation.** Topic: overlapping commitments. | Detect shared endpoints/dependencies and group consistently; report contradictory overlap rather than weakening either commitment. | Commitment graph/conflict detector. | Overlap, merge and conflict tests. | Reconcile the complete D32A-17 worksheet response. |
| D32A-18 | **Option A — owner-selected in conversation.** Topic: manual editing protection. | Explicit deliberate edit/confirmation, validation, revision and feasibility reassessment; ordinary optimization cannot edit. | Edit UI/local store/assessment. | Confirm/cancel/invalidation tests. | Reconcile the complete D32A-18 worksheet response. |
| D32A-19 | **Option A — owner-selected in conversation.** Topic: commitment version history and recovery. | Retain prior recoverable commitment revision; exact worksheet response was not supplied. | Hive draft model/journal/recovery. | Revision and restore tests proposed. | Supply/reconcile complete worksheet response where recorded. |
| D32A-20 | **Option A — owner-selected in conversation.** Topic: staged Hive writes and recovery journal. | Staged-write/journal protocol in Section 6 is a technical proposal, not recovered owner wording. | Hive writer/journal. | Interrupted write/replay tests. | Supply/reconcile complete worksheet response where recorded. |
| D32A-21 | **Option A — owner-selected in conversation.** Topic: Restricted Safe Mode. | Safe Mode should isolate itinerary functions while retaining source data; exact scope must be reconciled. | App startup/features/recovery UI. | Safe mode and retry tests. | Supply/reconcile complete worksheet response where recorded. |
| D32A-22 | **Option A — owner-selected in conversation.** Topic: validation-based restoration. | Restore/expose only after structural and semantic validation; exact worksheet response was not supplied. | Hive recovery/validation. | Integrity and retry tests. | Supply/reconcile complete worksheet response where recorded. |

## 4. Transportation catalog specification (engineering proposal)

### 4.1 Placement and ownership

Use a **bundled, versioned local catalog** as the initial design. A reviewed application release is the catalog update mechanism; no client or administrator edits the catalog at runtime. This satisfies stable local decoding without adding an unapproved relation to A-13’s ten-relation Scope A. A future remote/hybrid catalog would require an explicit A-13 scope decision, D32A evidence, A-14 security review, trusted update operation, and cache/version policy. It is not authorized here.

Catalog membership means only “this mode is known to the app.” It does not establish service, route, operator, schedule, fare, duration, or workflow support.

### 4.2 Proposed typed structure

```text
TransportCatalog {
  schemaVersion: int,
  entries: List<TransportMode>
}

TransportMode {
  id: StableTransportId,              // immutable lowercase snake_case
  labelKey: String,                    // stable localization key
  categoryId: TransportCategoryId,     // first-level category
  modeKind: TransportModeKind,         // second-level mode identity
  isActive: bool,                      // offer for new selection
  aliases: Set<String>,                // decode-only legacy aliases
  capabilities: WorkflowCapabilities, // independent UI/workflow support flags
  waterTransfer: bool                  // identifies water semantics, not availability
}

WorkflowCapabilities {
  profilePreference: bool,
  manualLegSelection: bool,
  circuitPlanning: bool,
  mogaOptimization: bool,
  fixedCommitment: bool
}
```

Category is a two-level taxonomy, not a claim of feasibility. Proposed first-level categories: `land`, `public_transport`, `water`. Proposed second-level kinds include `non_motorized`/`motorized` under land and individual modes as stable mode IDs; the exact hierarchy and category spelling need owner approval. Keep the mode ID authoritative; do not encode a display label as identity.

Capability flags are independent per mode and workflow. A mode may be active in the catalog yet unsupported for MO-GA or circuit planning. Do not derive all flags from `isActive`. Current UI evidence supports only the five historical general choices in profile/trip controls; it does not establish that the seven additional concepts are currently supported in every planner. Initial capability values must be explicitly reviewed and cannot be inferred merely from catalog inclusion.

### 4.3 Proposed initial identifier examples

These are implementation examples, **not an approved identifier registry**:

| Display concept | Proposed ID | Proposed category | Legacy aliases / note |
|---|---|---|---|
| Walking | `walking` | `land.non_motorized` | Current enum value. |
| Bicycle | `bicycle` | `land.non_motorized` | Current enum value. |
| Motorcycle | `motorcycle` | `land.motorized` | Current enum value. |
| Car | `car` | `land.motorized` | Current enum value. |
| Public transportation | `public_transportation` | `public_transport` | Decode `public transportation`, `publicTransportation`. |
| Jeepney | `jeepney` | `public_transport` | Newly named owner concept; capability values need review. |
| Tricycle | `tricycle` | `public_transport` | Newly named owner concept; capability values need review. |
| Multicab | `multicab` | `public_transport` | Newly named owner concept; capability values need review. |
| Van | `van` | `public_transport` | Newly named owner concept; capability values need review. |
| Bus | `bus` | `public_transport` | Newly named owner concept; capability values need review. |
| Ferry | `ferry` | `water` | Must retain directed transfer endpoints and fixed-commitment semantics. |
| Boat | `boat` | `water` | Must retain directed transfer endpoints and fixed-commitment semantics. |

Alias decoding is one-way compatible: known legacy values decode to stable IDs; writing uses one canonical ID after migration authorization. Unknown IDs remain an `UnsupportedTransportMode(rawId, savedLabel?)` value and render with their historical saved label where available. Inactive modes remain readable and displayable for historical drafts but cannot be newly selected. No unknown/inactive mode is replaced automatically.

Persist a historical display-label snapshot with a saved leg/commitment when label preservation is required. A catalog label change affects new selections; saved drafts continue to show the stored label or a deliberate migration result. Keep existing MO-GA result data and algorithm version as historical output. A legacy boolean/estimated feasibility result must be labeled as a legacy estimate, not promoted to verified Feasible.

### 4.4 Catalog acceptance tests

- Every stable ID is unique, lowercase snake_case, immutable across label changes, and round-trips by version.
- All twelve initial concepts exist; aliases for both `public transportation` and `publicTransportation` decode to the same proposed stable ID.
- Unknown identifiers are preserved and visible as unsupported; inactive identifiers remain readable; neither is silently substituted.
- `isActive` and per-workflow capability flags are independent; UI/API rejects a mode unsupported by that workflow while retaining the saved value.
- Catalog presence alone never produces an availability or verified-route state.
- A label update preserves old saved display snapshots and does not mutate existing MO-GA results.
- Catalog version migration is idempotent and does not assign a transport mode when a legacy record lacks one.

## 5. MO-GA protected commitment specification (engineering proposal)

### 5.1 Proposed data and dependency structures

```text
CommitmentEntry {
  entryId, commitmentClass, kind,
  transportModeId?, fromEntryId?, toEntryId?,
  userSchedule?, timezone?, scheduleSource = touristEntered,
  providerVerification = unverifiedBySamalNav,
  protectedRevision, historicalLabel?
}

CommitmentDependency {
  predecessorEntryId, successorEntryId,
  relation: before | adjacentForward | sameProtectedGroup,
  reason: fixedTransfer | schedule | ownerRule
}

ProtectedBlock {
  blockId, orderedEntryIds, internalLegs,
  fixedModes, fixedSchedules, boundaryBefore?, boundaryAfter?
}
```

This is local conceptual data, not a SQL design. A fixed ferry/boat transfer is a directed adjacent edge between two itinerary endpoints. Its schedule and mode are user-entered data, preserved exactly during ordinary optimization and marked unverified by SAMAL NAV.

### 5.2 Protected block construction

1. Validate that each dependency references existing entries and does not contradict direction/order.
2. Add fixed transfer endpoints and transfer details as one indivisible ordered block.
3. Merge overlapping blocks connected by `sameProtectedGroup` or shared fixed entries; preserve internal order. A cycle in strict precedence dependencies is a proven conflict and yields Infeasible with the dependency IDs.
4. Add fixed schedule windows as constraints on the block; do not translate missing time to a default.
5. Keep planned activities as mandatory genes. Optional destinations are separate candidate genes that may be excluded only after feasibility filtering.
6. Partition reorderable regions between protected blocks. Only unconstrained entries may move within a region; a mode-bound edge may not be broken or reassigned silently.

The exact boundary rule for a planned activity that shares a protected location, and whether a time window creates adjacency or only precedence, require owner/architect closure. Connectedness must be defined over explicit dependency edges, not inferred from proximity or provenance.

### 5.3 Segment-based optimization and invariants

For a route with protected blocks `B1..Bn`, optimize only legal sequences of blocks and unprotected entries between fixed boundaries. The chromosome should represent block IDs plus optional inclusion bits, not raw destination indexes. Crossover and mutation operate on whole blocks and must revalidate all dependencies. Invalid offspring are rejected; repair may not drop, reverse, split, reschedule, or reclassify protected data. If no valid candidate remains, return an explicit infeasible or indeterminate assessment according to evidence.

```text
parse and validate itinerary entries, catalog capabilities and evidence
construct dependency graph and protected blocks
if graph has a proven cycle or contradictory fixed schedule: Infeasible(conflicts)
retain all fixed blocks and planned activities as mandatory
remove optional candidates with unsupported mode or unknown required feasibility
partition route into legal segments around protected blocks
initialize chromosomes from legal block permutations and optional inclusion bits
for each generation up to the configured generation count:
  select by approved objective values only
  crossover whole blocks; mutate only legal block order / optional bits
  reject any child violating order, adjacency, class or fixed-value invariants
  assess route evidence: unknown remains unknown, never numeric zero
if mandatory core contains unknown required evidence: return Indeterminate draft
else if hard constraints cannot be satisfied: return Infeasible with reasons
else if every required condition is evidence-supported: return Feasible
```

Generation count remains the current optimizer’s stopping mechanism, but convergence, budget/time limits, and deterministic tie-breaking need technical design. Existing numeric fitness objectives (distance, count fitting hours, variance) cannot prove real route feasibility under D31A-12; geometric estimates may be shown only as clearly labeled non-verified estimates if separately approved.

### 5.4 Manual edit and reassessment

Ordinary drag/reorder/optimization cannot modify confirmed fixed commitments. An explicit edit flow must show the old and proposed values, request confirmation, validate endpoints/mode/timezone/schedule consistency, save a new local commitment revision, explain that SAMAL NAV does not update an external booking, and invalidate the prior feasibility assessment. The next optimization uses the revised values as fixed constraints. Cancel leaves the prior record unchanged.

### 5.5 Failure scenarios and acceptance tests

| Scenario | Expected result | Acceptance test |
|---|---|---|
| Endpoint removed or absent | Do not weaken edge; report conflict/invalid draft. | Missing endpoint rejection. |
| Crossover splits or reverses fixed transfer | Reject offspring; source commitment unchanged. | Property tests across seeds/generations. |
| Fixed dependency cycle | Infeasible with cycle entries listed. | Directed graph cycle fixture. |
| Overlapping schedules proven impossible | Infeasible; retain original commitments. | Deterministic window conflict tests. |
| Required schedule/route evidence missing | Indeterminate draft; no fabricated duration. | Unknown propagation tests. |
| Unsupported/inactive mode | Preserve and display unsupported; no fallback. | Capability rejection and no-substitution tests. |
| Planned item exceeds capacity | Preserve planned item; report Infeasible if contradiction is established, otherwise Indeterminate. | Planned inclusion and unknown-time tests. |
| Optional candidate is uncertain | Exclude with reason; do not affect mandatory core. | Optional filtering tests. |
| Explicit commitment edit | Confirm, validate, revise locally, reassess; no external update. | Confirm/cancel/conflict tests. |

## 6. Hive persistence and recovery specification (engineering proposal)

### 6.1 Current persistence boundary

The current resolved dependency is Hive 2.2.3 / hive_flutter 1.1.0. The local draft store reads/writes the v1 box directly. The inspected implementation does not establish a transaction across box writes, and this specification does not assume automatic rollback. It does not currently contain a recovery journal, staged-write protocol, commit marker, integrity validator, safe mode, or startup migration gate.

### 6.2 Proposed persistence records

Conceptual metadata and records (not a final storage schema):

```text
StoreMetadata { activeFormatVersion, committedGeneration, migrationState }
DraftEnvelope { draftId, formatVersion, revision, payload, checksum, savedAt }
WriteJournal { operationId, draftId, sourceRevision, targetRevision,
               stagedKey, sourceChecksum, targetChecksum, phase }
RecoverySnapshot { sourceBox, key, exactRawValue, checksum, capturedAt }
CommitMarker { operationId, targetRevision, validatedChecksum, committedAt }
```

Use separate staging keys/box and source-preserving snapshots. Checksums detect accidental byte changes; they do not prove semantic validity or provide security against a malicious writer. Sensitive data protection and backup behavior across device backup/restore require a separate privacy review.

### 6.3 Save/update sequence

1. Validate the proposed commitment/draft in memory. Create operation ID; capture source revision and exact raw bytes/checksum.
2. Persist and flush a journal record in `prepared` state. Re-read and verify it.
3. Persist a staging draft at the next revision without replacing the committed value. Flush, re-read, decode and validate IDs, references, schedules, modes, classes and invariants.
4. Persist a `validated` journal phase and a commit marker only after staged readback succeeds. Commit marker references checksum/revision.
5. Resolve reads by committed marker; only then expose new revision. Preserve previous committed revision/recovery snapshot until an approved cleanup policy permits removal.
6. Mark journal complete and make cleanup a later idempotent operation. A failure before commit leaves prior committed revision active.

Hive’s exact per-operation durability and ordering guarantees must be checked against the locked package source and supported platforms before this design is implemented. If a commit marker plus staged keys is not sufficiently recoverable under crash testing, use a different storage-level protocol; do not label it atomic by assumption.

### 6.4 Startup recovery and Safe Mode

At startup, gate itinerary reads/writes until metadata, journal and active records validate. Recover by journal phase:

- **No pending journal:** validate committed records; enable itinerary feature only after successful integrity checks.
- **Prepared, no valid staged payload:** preserve source, discard no user data, mark recoverable failure, enter restricted Safe Mode.
- **Staged but unvalidated:** validate again; if valid continue; otherwise keep source committed and isolate staged data.
- **Validated but no commit marker:** revalidate checksum then finish commit idempotently, or preserve source and request recovery if ambiguous.
- **Commit marker valid:** ensure referenced payload exists and passes semantic validation before enabling readers; retain source snapshot.
- **Marker/payload mismatch or corrupt source:** do not guess which version is authoritative; preserve all bytes, isolate itinerary feature and offer support/retry path.

Safe Mode here means itinerary draft/commitment reads, edits, optimization and writes are disabled or limited to a non-destructive recovery screen; unrelated features that do not depend on the affected Hive records may remain available. Exact screen/navigation gating and whether unaffected offline cache data shares a storage failure boundary require implementation analysis. Never reset/delete the box to clear an error.

### 6.5 Failure-state matrix

| Failure point | Active readable revision | Required action | Retry condition |
|---|---|---|---|
| Snapshot write/flush failure | Prior committed revision only | Keep source; Safe Mode; report backup failure. | Storage issue resolved and snapshot verified. |
| Journal write failure | Prior revision | No staged write; preserve source. | Journal storage available. |
| Staged payload write/readback failure | Prior revision | Isolate staged key; retain raw source and journal. | Re-run staging from verified source. |
| Semantic validation failure | Prior revision | Preserve malformed source; report record-specific validation issue. | Corrected/approved recovery action. |
| Commit marker failure | Prior revision | Do not expose staged payload; revalidate on restart. | Valid stage and marker write possible. |
| Restart with pending journal | Depends on last verified marker | Run deterministic journal recovery before itinerary access. | Recovery algorithm resolves state. |
| Active marker references missing/corrupt payload | None for that draft/store | Safe Mode; preserve all copies; no fallback guess. | Recovery snapshot validates or user restores. |
| Unknown future format | No new-format access | Preserve raw record; isolate; do not downgrade or overwrite. | App version with decoder or explicit recovery support. |

### 6.6 Hive acceptance tests

- Inspect and test against locked Hive 2.2.3 on supported platforms; inject process termination after every write/flush boundary.
- Validate journal replay is idempotent, including repeated start/retry and interrupted cleanup.
- Ensure a valid commit marker is the only path that exposes the staged revision.
- Corrupt/missing checksum, payload, journal, marker and snapshot each produce a safe non-destructive state.
- Legacy v1 aliases and all existing destination/stop/transfer fields survive conversion; no missing classification, schedule, or mode is invented.
- New installs start at the current validated format with no fake preferences or commitments.
- Migration failure isolates itinerary functionality while independent app features remain available; recovery restores only validated content.
- Confirm the previous committed revision remains readable until the new revision passes structural and semantic checks.

## 7. Security and database boundaries

- Preserve the approved conditional ten-relation Scope A. Do not add a transportation catalog relation without explicit A-13 scope approval. Bundled local catalog is the proposed initial option.
- Do not persist itineraries, pre-booked transfers, reservations, or payments server-side. Local commitment detail is user-entered and unverified by SAMAL NAV.
- Do not create unauthorized CARS evidence tables. Unverified display rating/price, catalog inclusion, manual water schedules, stale times, or unsupported modes are not CARS numerical evidence.
- Keep profile role and ownership trust under A-01/A-02; client metadata is not role authority. Catalog capabilities never grant authorization.
- D29-15/16 audit/settings remain subject to A-09 allowlist, access, redaction, retention and trusted-operation review. D29-17 retention/deletion details require A-11.
- A-14 independent RLS/grant/trusted-operation review remains required for any exposed or remote functionality. No Supabase access or SQL is performed or authorized here.
- A-15 non-production initialization and A-16 production deployment remain separate, deferred gates. This task does not grant either.
- Any Hive recovery copy may contain personal itinerary data. Encryption, OS backup exclusion/inclusion, retention, device transfer and deletion need privacy review; a local-only boundary is not equivalent to zero privacy risk.

### 7.1 Cross-contract consistency checks

| Boundary | Consistency rule | Current status |
|---|---|---|
| Catalog vs service | A known/active mode is not a service availability claim. | No catalog or live transport source exists in inspected app contract. |
| Capability vs active | Workflow flags are independent from catalog active status. | No capability model exists. |
| Mode vs class | Mode identifies travel; commitment class defines optimizer obligation. | Current model lacks both per-leg mode and class. |
| Dependency vs order | Fixed transfer is directed adjacent edge; dependencies are explicit and validated. | Only a simple transfer tuple exists; MO-GA does not receive it. |
| Feasibility vs artifact | Draft existence does not mean Feasible. | Existing result Boolean is based on estimated arithmetic. |
| Unknown vs conflict | Unknown evidence => Indeterminate; proven contradiction => Infeasible. | Current engine has no evidence state. |
| Legacy vs migration | Preserve original and do not infer class or verified status. | Format-1 reader rejects other versions; no migration/recovery. |
| Local vs remote | Tourist commitments remain local; no reservation/booking claim. | Existing excluded booking/payment services require separate app cleanup per Task 31. |
| CARS vs MO-GA | No unverified numeric scoring; optimization and CARS remain separate. | Current CARS profile gate is fail-closed; maintain it. |

## 8. Test acceptance matrix

The following is a future test plan. No tests were executed.

| Feature | Required coverage | Acceptance criteria |
|---|---|---|
| Catalog codec/version | All 12 initial concepts, aliases, unknown IDs, inactive IDs, label update, version update | Stable IDs, backward decode, preserved historical labels, no silent substitution. |
| Capability flags | Each mode × profile/manual/circuit/MO-GA/fixed-commitment capability | Only explicitly enabled workflows accept mode; active status does not imply capability. |
| Service availability | Unknown, unverified, stale, verified source states | Catalog never implies route; unknown never receives fabricated duration. |
| Profile/leg precedence | Null preference; explicit leg; profile suggestion; unsupported prior value | Explicit user choice wins; profile does not overwrite; unsupported values preserved. |
| Commitment graph | Endpoint resolution, duplicate IDs, cycles, connected groups, directed adjacency | Valid graph yields legal blocks; cycles/conflicts are reported. |
| Protected optimizer | All initial populations, crossover, mutation and generations across seeds | Fixed values, direction, adjacency, schedule and planned activities preserved. |
| Optional selection | Verified feasible, unknown, unsupported, inactive optional candidates | Only permitted candidates included; unknown optional excluded with reason. |
| Feasibility tri-state | Verified all constraints, known conflict, missing/stale evidence, combinations | Exact approved aggregation; Infeasible requires proof; unknown is Indeterminate. |
| D31A-22 draft | Indeterminate core and excluded unknown optional | Draft is saved/displayed as Indeterminate and never as verified feasible. |
| Edit protection | Cancel, confirmed edit, invalid details, resulting conflict | Ordinary optimizer cannot edit; confirmed local edit invalidates assessment and external booking is untouched. |
| Historical MO-GA results | Existing result payloads, algorithm version, old Boolean feasibility | Preserve historical output; never relabel estimate as verified Feasible. |
| Hive save journal | Fail after each write/flush/marker/cleanup boundary | Prior committed revision survives; replay idempotent. |
| Hive startup recovery | Prepared/staged/validated/committed/corrupt/unknown version | Readers gated until validation; safe mode and deterministic retry. |
| Manual and circuit | Existing selection, day groups, circuit groups, reorder and constraints | Same commitment rules; circuit not silently routed through unsupported adapter. |
| CARS boundary | Unconfirmed preferences, unverified rating/price, unknown travel time | No unsupported numerical score/evidence; fail-closed behavior retained. |
| Scope boundary | Static query/persistence scan | No server itinerary/reservation/payment writes or unapproved catalog/CARS tables. |

## 9. Implementation roadmap

Every phase requires separate explicit coding authorization. The selected D32A options are now recorded; the full worksheet wording and conditions still need reconciliation before phases that rely on them.

| Phase | Objective / affected files | Dependencies | Tests and acceptance | Risks / authorization |
|---|---|---|---|---|
| 0. Decision source and contract closure | Obtain Task 32A worksheet text and reconcile exact conditions; approve catalog IDs/capabilities, leg mode policy, feasibility predicates and legacy state. | Owner decision evidence and product/architecture review. | All selections and conditions trace to source; technical contracts closed. | Selections are confirmed, but full wording is a blocker; no coding. |
| 1. Catalog codec/types | New local catalog/codec; `itinerary_draft.dart`, profile model and adapter only as separately scoped. | Approved immutable ID registry and capability matrix. | Alias, unknown, inactive, label-history tests. | Smallest safe coding candidate after authorization; no Hive/schema change. |
| 2. Commitment/evidence values | New local models; `itinerary_draft.dart`; schedule/timezone validation. | D32A worksheet reconciliation; D31A class, schedule and unknown semantics closure. | Pure value/graph validation tests. | Avoid premature field freeze. |
| 3. Hive journal and recovery | `local_itinerary_draft_store.dart`, startup/bootstrap, local repository and safe-mode UI. | Locked-format target; platform recovery design and fixtures. | Failure injection, restart, retry, preservation tests. | High data-loss risk; explicit code authorization and platform validation. |
| 4. Manual/circuit UI | Planning and review screens; manual/circuit adapters. | Data model and mode-lock rules. | Mixed-mode and protected edit tests. | Do not regress current manual/circuit behaviors. |
| 5. Evidence/feasibility service | Local travel evidence and assessment result types; CARS travel assessment boundary. | Approved evidence sources/freshness and tri-state rules. | State truth tables; source/stale tests. | No provider integration absent decision. |
| 6. Constrained MO-GA | `moga_engine.dart`, `manual_selection_moga_adapter.dart`, circuit route path, generated draft builder. | Phases 2, 4, 5; approved objectives and capability flags. | Property/invariant tests across operators/seeds; performance. | Major algorithm redesign; dedicated authorization. |
| 7. Draft/result UX | `plan_page.dart`, generated draft review, itinerary review screens. | Artifact and feasibility labels approved. | Indeterminate/no-feasible-claim tests. | Product accessibility/wording review. |
| 8. Database/security work (separate) | Schema manifest and later migration/security artifacts only. | A-09/A-11/A-13/A-14 closure and separate authorization. | Local clean install, RLS adversarial/security acceptance. | No SQL or remote execution authorized here; A-15/A-16 remain separate. |

**Smallest safe first coding task:** after D32A worksheet reconciliation and explicit authorization, implement a pure bundled catalog/legacy codec with tests, isolated from Hive writes and database access. Until the owner confirms the ID/category/capability registry, even this bounded task is not ready.

## 10. Remaining blockers

1. **Task 32A worksheet detail:** provide/reconcile the full original wording and conditions, especially D32A-01–D32A-18, for which only topics and Option A are confirmed, and any fuller D32A-19–D32A-22 responses. The 22 selected options themselves are confirmed as Option A in conversation.
2. **Catalog contract:** approve stable IDs, alias registry, exact two-level categories, initial capability values, inactive behavior, historical label policy, and versioning rules.
3. **Scope:** resolve local bundled catalog vs any future remote source; do not exceed A-13’s approved ten relations without explicit approval.
4. **Per-leg mode semantics:** decide whether explicit user modes lock endpoint edges during optimization and how new optimizer-created adjacencies receive modes.
5. **Commitment model:** approve schedule/timezone fields, endpoint/entry granularity, dependency relation types, grouping boundaries and conflict semantics.
6. **Feasibility policy:** approve exact predicates, evidence threshold, aggregation, optional filtering and treatment of an Indeterminate mandatory core.
7. **MO-GA objectives:** approve candidate pool, weights, normalizations, unknown objective behavior, time limits and stopping criteria.
8. **Hive recovery:** verify persistence ordering and crash recovery against Hive 2.2.3 on each platform; determine backup durability, journal/marker semantics, Safe Mode scope and data retention. Do not claim atomicity without failure-injection evidence.
9. **Privacy/security:** assess local backup and personal schedule data; close A-09/A-11/A-14 as relevant. Remote catalog access needs independent security review.
10. **Authorization:** obtain a separate explicit implementation authorization. Owner architecture selections are not authorization. A-15 non-production and A-16 production remain independent and unauthorized.

## 11. Final readiness assessment

**C. Not ready for coding.** All 22 D32A Option A selections are now confirmed by the owner in conversation and recorded in the matrix. The full worksheet wording/conditions and technical contracts remain partly unreconciled; core catalog, feasibility, optimizer and Hive recovery decisions also remain open. Do not treat this as complete documentary closure of Task 32A until its detailed responses are reconciled. No code, tests, SQL, migration, Hive operation, Supabase access, initialization, or deployment is authorized.

## 12. Validation and closeout

- Decision IDs D29-01–D29-17, D31A-01–D31A-22 and D32A-01–D32A-22 each appear once in the master matrix.
- D32A-01–D32A-22 are recorded as Option A based on the owner's explicit confirmation in this conversation. Topic details are included only to the extent supplied; missing worksheet conditions are marked for reconciliation.
- Source inspection was read-only; test files were not executed.
- No Dart source, tests, configuration, SQL, migration, Hive data, database, or Supabase state was changed or accessed.
- Existing working-tree changes were preserved.
- `git diff --check` and the new document whitespace validation: **passed**.

