# Task 30 — SamalNav Final Owner Decision Consolidation and Implementation Readiness

**Project:** SAMAL NAV
**Source:** Owner-supplied “Task 29 — Final Owner Decision Summary”
**Status:** Selections consolidated; implementation authorization **not granted**. Owner name, role, decision date, and effective policy version were not supplied and are not inferred.

**Restrictions observed:** No application source, tests, configuration, SQL, migration, or database object was changed. No SQL was executed and neither Supabase project was accessed. Tasks 06–29 are preserved.

## 1. Executive summary

This report records the 17 selected options exactly as stated in the supplied owner decision summary. It resolves conflicting provisional entries in Task 29: notably D29-10 is **Option C**, D29-12 selects rating **Option A** and duplicate-review **Option 2**, D29-14 is **Option C**, and D29-17 is **Option A**. The latest owner summary is the controlling decision record for this consolidation; older recommendation-only worksheet text is not treated as an alternative approval.

The selections establish architectural direction. They do not finish implementation policy or authorize coding, migrations, non-production initialization, or production deployment. Conditions remain for app compatibility, lifecycle vocabularies, rating range verification, age definitions, retention periods, independent A-14 security review, migration testing, and separate A-15/A-16 approvals.

Scope remains ten core relations only: `profiles`, `destinations`, `establishments`, `location_verifications`, `tourist_details`, `favorites`, `reviews`, `events`, `audit_logs`, and `system_settings`. Payments, server-side reservations, server itinerary persistence, and CARS evidence tables remain excluded. Tourist-entered pre-booked details remain local Hive itinerary data, not SAMAL NAV reservations or confirmations; MO-GA must preserve them as fixed constraints.

## 2. Owner decision consolidation: D29-01–D29-17

“Selected” below means the owner selected an architectural option. It does not mean implementation details or policies are technically validated. Conditions and formal-record gaps remain visible.

| ID | Selected option exactly as supplied | Consolidated owner direction | Conditions / open evidence | Status |
|---|---|---|---|---|
| D29-01 | **A** | Preserve username-based login. Usernames are unique regardless of capitalization; application/database normalization must match. | Define exact normalization (trim, Unicode/case behavior), reserved names, collision handling and login migration behavior. | Owner-selected direction; implementation details open |
| D29-02 | **C** | Defer unused establishment contact fields; retain only fields required by verified application contract; keep business contact separate from owner's private profile. | App audit found no demonstrated business contact field requirement in the inspected `Establishment` model/service. Confirm full forms and any additional screens before manifest lock. | Owner-selected direction; field audit condition remains |
| D29-03 | **A** | One establishment may manage multiple destinations. Each destination may optionally reference one establishment through nullable FK. | Confirmed by owner; preserve one-to-many. Define FK delete/retirement behavior under D29-17. | Owner-selected direction; FK action open |
| D29-04 | **A** | Verification submissions may optionally reference a destination. Only trusted approval operations assign/change the link. | Specify new-destination vs correction workflow and atomic approval operation. | Owner-selected direction; workflow implementation open |
| D29-05 | **A** | Unique destination-linked favorites on `(authenticated user, destination)`; allow multiple no-ID snapshots; no place-name similarity uniqueness. | Partial unique index is appropriate for non-null `destination_id`; test favorite undo/reinsert behavior. | Owner-selected direction; app compatibility open |
| D29-06 | **C** | Existing rating/price values may be displayed, but unverified values are not authoritative CARS inputs. Future CARS use requires verified sources, provenance, freshness and approved policies. | Source/stewardship and freshness remain unapproved. Keep display evidence distinct from scoring evidence; no zero-default interpretation. | Owner-selected direction; CARS integration blocked |
| D29-07 | **A** | Use documented publication lifecycles for destinations and establishments, separate from verification; only authorized operations may change publication state. | Exact state labels, transitions and public predicate still need approval and code mapping. | Owner-selected direction; state contract open |
| D29-08 | **A** | Use separate verification lifecycle; restrict changes to authorized reviewers/trusted backend; record relevant actors/timestamps. | Exact states, transitions, actor fields and atomic operations remain to define. | Owner-selected direction; state/security contract open |
| D29-09 | **A** | Store explicit Boolean preference confirmation and timestamp; changing preferences resets confirmation until explicit reconfirmation. | Confirm UI behavior, timestamp writer and whether confirmation applies to the entire preference set/version. | Owner-selected direction; model/service change needed |
| D29-10 | **C** | Store detailed adults, children and elders counts; require nonnegative integers and a consistent total. Age boundaries and age-dependent prices need separate approval/evidence. | Current profile model stores total, children, elders and derives adults. Define whether adults are stored or derived and exactly how all counts reconcile; do not invent age cutoffs. | Owner-selected direction; validation contract open |
| D29-11 | **A** | Maintain nullable preferred travel mode in tourist profile; separate profile preference from actual trip transport choice; preserve explicit land/water constraints. | Supply approved vocabulary; current enum has land modes only, while trip transfer types model ferry/boat separately. No profile value may silently select every leg. | Owner-selected direction; vocabulary/app contract open |
| D29-12 | **Rating A; Duplicate-Review 2** | Integer stars matching existing Flutter interface; allow multiple dated reviews by the same tourist for same destination or establishment. | Exact UI rating min/max must be verified before DB check. Review submission UI was not identified in the inspected paths; displayed stars alone do not establish the submitted range. No uniqueness on `(tourist,subject)`. | Owner-selected direction; rating range evidence open |
| D29-13 | **A** | Documented moderation lifecycle with trusted moderator-controlled transitions; proposed states: pending, published, rejected, hidden, removed. Only eligible published reviews may contribute to public aggregates under separately approved aggregation policy. | State transitions, author visibility, appeals/removal, audit and public aggregate policy require approval. No aggregate is created by this task. | Owner-selected direction; A-08/A-09 policy details open |
| D29-14 | **C** | Support all-day and timed events; store local event date and IANA timezone. Timed events require valid start/end instants and end later than start. | Confirm app create/edit/display/filter workflow; define exact all-day field invariants and timezone validation in Dart/database. | Owner-selected direction; app verification open |
| D29-15 | **A** | Structured, versioned audit records from trusted backend operations; actor, action, outcome, resource, server timestamp; restricted access/modification. | A-09 approval, event/action taxonomy, metadata redaction, retention and access rules remain open. | Owner-selected direction; security/policy gate open |
| D29-16 | **A** | Versioned setting allowlist with types, validation, defaults and trusted backend modification; sensitive changes audited; no secrets stored as ordinary settings. | A-09 security approval, exact keys/schema/read visibility/writer and emergency access remain open. | Owner-selected direction; security/policy gate open |
| D29-17 | **A** | Controlled account closure/deletion, anonymization and retention; close Auth through trusted operations; retain legitimate historical/security/operational records; decide FK actions individually; audit deletion/anonymization. | Retention periods, anonymization rules, legal basis, backup deletion, actors and per-relation FK actions require formal A-11 approval. | Owner-selected direction; A-11 details open |

### 2.1 Decision status and record quality

- All 17 selected options are now consolidated in one table; no older Task 29 recommendation is treated as a competing owner selection.
- D29-10 is C, not the earlier recommendation B.
- D29-12 duplicate policy is Option 2 (multiple dated reviews), replacing the earlier “pending” state. Rating is Option A, but the actual UI range remains to be verified.
- D29-14 is C, with local date, explicit timezone, all-day/timed representation and timed interval requirements.
- D29-17 is A, consistent with the previous A-11 architectural direction; exact privacy and retention terms remain open.
- Owner name, role, decision date and effective policy version are expressly “to be recorded” in the supplied summary. They remain absent here.
- The owner summary says implementation authorization is not granted. A-15 non-production initialization and A-16 production deployment remain deferred.

## 3. Canonical schema compatibility matrix

This matrix consolidates the selected contract implications for each Scope A relation. It is not migration DDL. Field types and exact constraints remain subject to the conditions in Section 4 and A-13/A-14/A-11 closure.

| Relation | Canonical fields/constraints to carry forward | Owner / relationship / deletion contract | Current app compatibility |
|---|---|---|---|
| `profiles` | Auth UUID `id`; `role`; email/display name/username/phone only where retained by app; timestamps. Username normalized case-insensitively and unique if username login remains. | One-to-one with managed `auth.users`; trusted signup trigger sets tourist. User cannot change role. Account closure through trusted process. | `login_page.dart` looks up username; `profile_page.dart` writes profile; `RoleService` can upsert; `SuperAdminService` changes role client-side. Must adopt consistent normalization, trigger-safe idempotency and trusted role changes. |
| `destinations` | Stable ID/name/location/category, nullable coordinate pair, descriptions/images/hours/duration where consumed; publication state separate from verification; rating/price may be display values only, no unverified CARS use. | Optional `establishment_id → establishments.id` under D29-03; one establishment to many destinations. Soft retirement; per-relation delete behavior per A-11. | `DestinationRecord` still parses legacy `status`/`is_active`/`is_verified` and aliases, defaults fallback values for display; `AdministratorService` writes old fields. Must map new lifecycle and prevent fallbacks being persisted as facts. |
| `establishments` | `id`, `owner_id`, `name`, address/category and only verified-contract fields, separate publication/verification states, timestamps. No unused contact fields under D29-02. | `owner_id → profiles.id`; one owner to many; **no unique owner_id**. Soft retirement and retained references. | `Establishment` currently uses `is_verified`; `EstablishmentService.getMyEstablishment()` calls `.maybeSingle()`. Change to list/selected establishment ID and update dashboards. |
| `location_verifications` | Submission identity/content/coordinates/status/submitter/reviewer/timestamps; nullable `destination_id` assigned only by trusted approval operation. | Submitter/reviewer profile links; optional destination link. No submitter self-approval. Preserve audit/retention. | `AdministratorService` separately updates verification and inserts destination. Replace with a trusted atomic operation; split submitter fields from reviewer-controlled fields. |
| `tourist_details` | `user_id` unique; nullable budget bounds/basis/currency, hours/days, preferences, origin, mode, total and nullable `adults_count`, `children_count`, `elders_count`; explicit preference confirmation boolean/timestamp. Counts nonnegative; when total and all subgroup counts are supplied/confirmed, adult + child + elder count must equal total. No age boundaries/defaults. | Tourist owns row; user-scoped RLS. Preference changes clear confirmation/time. Profile preference mode is not actual trip mode. | `TouristPlanningProfile` requires budget/time/mode; service creates missing row and adapter uses fields. Nullable contract, confirmation reset and explicit adult count require model/service/UI/test updates. |
| `favorites` | `user_id`, optional `destination_id`, snapshot display fields; partial unique `(user_id,destination_id)` when destination ID is non-null; no name similarity key. | Tourist owns favorite. A destination link can be NULL for snapshots; preserve snapshot on retirement. | `favorite_page.dart` reads/deletes/undo-inserts; verify it sends destination identity when known, handles multiple NULL-ID snapshots, and catches unique conflicts on undo. |
| `reviews` | Author; nullable `destination_id` and `establishment_id` with exactly-one-subject XOR; integer `stars`; text; moderation state; creation/update times. Allow multiple dated reviews per author/subject (no such unique constraint). | Author owns submission; moderators control state. Subject retirement preserves history. Aggregation remains separately approved. | `ReviewRecord` requires destination ID, incompatible with establishment-only review; model should use exclusive subject. Existing average query is establishment-only and has no moderation filter; revise before public aggregate claims. Verify rating submission UI/range. |
| `events` | `event_date date NOT NULL`, `is_all_day boolean NOT NULL`, nullable `starts_at/ends_at timestamptz`, `event_timezone text NOT NULL` (IANA), title/category/description/publisher/publication state/timestamps. For all-day: no instants; timed: both instants and end > start. | Publisher profile FK; public read of published events only. Retention/retirement follows A-11. | `AdministratorService` orders by `event_date` and lists events; no event edit/create workflow was found in inspected paths. Review model, parser, display and timezone filtering before adopting columns. |
| `audit_logs` | Trusted server event: actor, role snapshot where justified, versioned action/outcome, resource, safe metadata/description, server time. No client-authored aliases. | Append-only; no ordinary client writes. Restricted privileged read; retention and redaction under A-09/A-11. | `AuditService.log()` inserts client-supplied actor/action aliases; replace with trusted writer. Super-admin reads need least-privilege projection. |
| `system_settings` | Key/value with per-key type/default/validator, updater, server time; no secrets. | Trusted allowlisted writes, narrow safe reads; security changes audited. | `SuperAdminService` directly upserts generic setting. Replace with trusted operation and validate the exact allowlist; avoid table-wide client access. |

**Excluded relations/features:** no `payments`, no server `reservations`, no server itinerary/draft tables, no CARS evidence tables, activities, or MO-GA persistence in initial Scope A. These exclusions are owner decisions, not evidence that current source code no longer calls the legacy relations.

## 4. Field-level compatibility audit

| Decision | Verified repository behavior | Required application/schema work before compatibility |
|---|---|---|
| D29-01 username | Login performs username lookup; profile flow edits username; `profiles` embeds rely on Auth/profile relation. | Agree normalization algorithm and apply identically at registration, update, lookup, and unique index. Handle duplicate legacy usernames before migration. Remove `maybeSingle` ambiguity through uniqueness. |
| D29-02 contacts | `Establishment` model consumes id/owner/name/address/category/is_verified; inspected establishment service uses owner ID and current reservation/payment/review data; no `contact_phone` on model found. | Exclude unconsumed contact columns. Verify all establishment screens/forms before closing the field inventory; keep personal profile phone separate. |
| D29-03 destination link | `DestinationRecord` parses category ID but no establishment ID relationship use found in current Flutter destination service. | Add optional destination-to-establishment model/service behavior only if used; maintain nullable FK and ownership/publication rules. One establishment may link to many destinations. |
| D29-04 verification link | Verification approval currently updates request and creates destination through separate calls. | Implement a trusted atomic approval/correction operation; idempotency, duplicate handling and submitter/reviewer field protections. |
| D29-05 favorites | UI inserts and deletes snapshot favorite records; relation ID is used for deletion. | Add destination ID on catalog favorites where known; partial uniqueness for non-null ID; support multiple null-ID snapshots and undo result conflict. |
| D29-06 rating/prices | `DestinationRecord` consumes rating aliases and raw entrance fee; verified-rating getter requires verified/source/timestamp/fresh-until; `PriceInfo` distinguishes display label. | Preserve only display contract. Do not treat favorite or destination raw rating/price as CARS evidence. If provenance fields are retained, validate source/freshness; CARS remains unavailable absent approved policies/data. |
| D29-07 publication | Destination parser and admin service still use `status`/`is_active`; public destination service filters active rows. | Define lifecycle transitions and map old fields atomically; update list filters to publication state; keep separate from verification. |
| D29-08 verification | Models/screens use boolean `is_verified`; verification queue has string status. | Replace mixed booleans/status with a documented lifecycle; trusted reviewer writes actor/time; align destination and establishment UI. |
| D29-09 preference confirmation | Tourist profile service deliberately treats stored preferences as unconfirmed; model has no confirmation timestamp/flag. | Add explicit confirmation state; save preference edits as unconfirmed; clear timestamp on change; require explicit reconfirmation. |
| D29-10 group composition | Profile model contains total tourists, children and elders; `adultsCount` is derived only when group data is valid. UI/tests validate subgroup counts and total. | Extend typed contract to adults if independently stored, or formally derive adults from total minus children/elders; enforce nonnegative integer and total consistency. Define age boundaries and rate applicability separately; no defaults. |
| D29-11 travel mode | Profile model requires mode; validation consumes caller-supplied supported set. `PreferredTravelMode`: walking, bicycle, motorcycle, car, public transportation. Local trip supports nullable mode and `RequiredTransferKind` ferry/boat. | Make profile preference nullable; preserve existing five strings unless owner adopts another vocabulary. Keep actual trip-wide/per-leg selection and explicit boat/ferry transfer context in trip config, not profile default. Add approved water modes only with verified semantics/provider. |
| D29-12 review scale/duplicates | `ReviewRecord` stores integer stars; dashboard renders up to its displayed star count. No review submission UI/range validation was found in inspected paths. | Inspect actual review input screen/source and prove min/max. Add matching DB and app validation. Remove unique author/subject constraint; support ordered multiple dated reviews and update listing/pagination semantics. |
| D29-13 moderation | Review records/services have no moderation state in current parser/query. | Add moderation model and trusted transitions; filter public queries to eligible published reviews. Define public aggregate separately; retain no CARS rating input until approved. |
| D29-14 events | Service orders `events` by `event_date`; query embeds publisher profile. No create/edit workflow located. | Add all-day/timed fields and validation; event-local date plus IANA timezone; convert/filter in event timezone rather than server timezone. Update model/service/screens and tests. |
| D29-15 audit | `AuditService` client inserts action/type, actor/user, role and description aliases; super-admin reads audit relation. | Replace client insert with trusted server operation; canonical versioned action/outcome and resource schema; server actor/time; remove duplicate aliases; audit access reviewed. |
| D29-16 settings | `SuperAdminService` reads and generic-upserts key/value; maintenance flag is consumed by UI. | Define versioned allowlist and validators/defaults; trusted writes only; narrow public maintenance read; audit sensitive changes; no secrets. |
| D29-17 retention | Current models/services do not define per-relation account closure/anonymization or retained history policy. | Design trusted closure operation and per-FK actions; soft close Auth/profile; retain legitimate history; anonymize/delete personal data by approved schedule; audit operation and manage backups. A-11 formal review required. |

### 4.1 Pre-booked itinerary details and MO-GA

Current `LocalItineraryDraftStore` persists unoptimized manual-selection drafts in Hive and serializes trip, stops and transfer intent. `ItineraryDraft`/`TripConfiguration` has no dedicated external pre-booked commitment entity or confirmed external booking state. MO-GA must preserve tourist-entered commitments as fixed constraints; that feature remains a separate local application gap. Task 30 does not add a database relation or represent these details as SAMAL NAV bookings. Keep them separate from actual external reservation confirmation. Add tests in a future authorized implementation phase for Hive round-trip preservation and optimizer invariant preservation.

### 4.2 Current incompatibilities requiring app work

1. Establishment ownership is one-to-many, but the service returns one `.maybeSingle()` record.
2. The `tourist_details` model requires budget, time and mode fields despite the approved nullable profile direction.
3. Destination and establishment UI uses legacy boolean/status fields instead of separate lifecycle state contracts.
4. Tourist profile preferences lack explicit confirmation state.
5. Group counts have no independently stored adult count; exact Option C consistency contract needs alignment with model and pricing inputs.
6. Review model cannot represent an establishment-only review under subject XOR; moderation is not represented; no review submit range UI was found.
7. Event handling lacks timezone and all-day/timed contract; no authoring workflow found.
8. Client can write role, audit and system setting fields currently restricted by selected decisions.
9. Verification review and destination creation are separate network operations.
10. Current code queries `reservations` and `payments`; these are excluded and must be removed or redesigned. Do not substitute local pre-booked details for a database booking table.

### 4.3 Existing test coverage inspected (not executed)

- `test/tourist_planning_profile_service_test.dart` and `test/planning_preferences_page_test.dart` exercise current required profile values, group validation, travel-mode selection and adapter behavior; they will need updates for nullable profile values, explicit preference confirmation, detailed adults/children/elders consistency and separation of profile preference from trip choice.
- `test/local_itinerary_draft_store_test.dart`, `test/local_itinerary_draft_ui_test.dart`, `test/manual_selection_workflow_test.dart`, and `test/moga_engine_test.dart` cover local draft round-trip, local planning and optimizer behavior. Existing coverage does not establish a pre-booked commitment data type or prove fixed-commitment preservation; add targeted tests in a future authorized code task.
- No review submission, event authoring, audit writer, or system-settings service test file was found by the repository test-file search. Add focused tests for the selected review scale/duplicate behavior/moderation, event timezone boundaries, trusted audit writer and setting allowlist as part of implementation.
- This was read-only repository inspection. No tests were run for Task 30.

## 5. Relationship and constraint closure matrix

| Relationship / invariant | Consolidated target | Closure condition |
|---|---|---|
| Auth to profile | One `profiles.id` per managed Auth UUID; trusted trigger, idempotent, `tourist` default | Review trigger/function owner, search path, grants, failure/retry and account closure |
| Profile to establishment | One profile to many establishments | No unique `owner_id`; app list/selected-ID redesign |
| Establishment to destination | One establishment to many, destination optional FK | D29-03 selected; approve FK delete action and publication/ownership operation |
| Verification to destination | Optional FK assigned only by trusted approval operation | D29-04 selected; atomic create/link and correction workflow contract |
| Tourist to details | One tourist to zero/one details row | Nullable profile facts; explicit confirmation and RLS |
| Tourist to favorite | One tourist to many; stable destination-linked favorites unique by user+destination | Allow duplicate snapshots with NULL destination ID; partial unique index tests |
| Review to subject | Exactly one of destination or establishment | XOR check; multiple dated reviews allowed; no author/subject unique constraint |
| Event to publisher | Event has publisher profile | Public only under approved publication state; local date/timezone invariants |
| Actor to audit/settings | Nullable trusted actor reference where necessary | Append-only audit, restricted settings, A-09/A-11 retention and deletion action review |
| Soft retirement | Destinations and establishments retire instead of ordinary hard delete | Define lifecycle states and ensure retained reviews/favorites/history remain coherent |

## 6. Security and policy gates

Owner-selected architecture does not replace the required independent review:

- **A-14:** exact grants and RLS predicates by relation, command, role and column; trusted functions/RPC ownership, `search_path`, caller checks and execute grants; PostgREST embed field exposure; synthetic identity adversarial tests. Security reviewer must be independent and named before sign-off.
- **A-09:** audit event coverage/taxonomy, metadata redaction, audit access/retention, settings key/value allowlist, emergency access and trusted writer must be specified.
- **A-11/D29-17:** per-relation retention, lawful basis, anonymization, account closure, FK delete actions, backup retention/deletion and exceptional permanent deletion actors must be approved.
- User-controlled `user_metadata` cannot set roles. Ordinary clients cannot write `role`, verification/publication state, moderation state, audit events, or unrestricted settings.
- Synthetic tests must include anon, unrelated tourists, multiple establishments per owner, distinct owners, admin and super-admin, rejected self-approval, role forgery, audit immutability and settings allowlist.

## 7. Proposed migration dependency plan

This sequence is planning only. No SQL or migration files were created. Existing migration files are not assumed safe to execute; Tasks 20–28 record duplicate `002` prefixes, incomplete prerequisites, schema variants, role metadata trust, policy replacement, and mixed seed/sample writes.

1. **Decision and manifest lock:** incorporate D29-01–17; close precise normalization, state vocabularies, event/review/group details, defaults, unique/check constraints, indexes and deletion actions. Record owner/role/date/version and A-13 closure evidence.
2. **Application compatibility design:** prepare exact Dart model/service/UI changes and tests for every matrix item. Retire incompatible `payments`/`reservations` server workflows; preserve local Hive and manual/circuit/MO-GA boundaries.
3. **A-09/A-11/A-14 review:** finalize security, audit/settings, privacy/retention, grants/RLS and trusted operation contracts; complete independent review before any implementation is considered ready.
4. **New migration chain design:** use uniquely ordered versions; do not reorder or execute historical migrations. Separate schema-only migrations from an independently reviewed synthetic reference-data manifest.
5. **Foundation:** Auth-linked profile and trusted idempotent provisioning, with role constraint and no metadata role. Validate in an isolated local environment.
6. **Core ownership/catalog:** establishments and destinations, then optional destination-establishment FK; add approved lifecycle state and retirement behavior.
7. **Tourist-owned data:** tourist details, favorites and their nullability, confirmation, group integrity, and partial uniqueness.
8. **Moderation/workflow:** unified reviews with subject XOR and multiple dated rows; location verifications with trusted atomic approval; events with all-day/timed date rules.
9. **Administrative support:** trusted audit writer and allowlisted settings operations. Apply RLS/grants only with independent review.
10. **Local validation:** clean install, repeatability, schema diff, constraints/FK action tests, Auth trigger tests, PostgREST embed tests, per-role RLS tests, Flutter contract/regression tests, and backup/restore rehearsal. Record migration hashes and results.
11. **A-15 separate authorization:** after implementation readiness, request a target-specific non-production approval with project, operator, hashes, window, backup, stop conditions and postchecks. Currently deferred.
12. **A-16 separate authorization:** only after successful non-production validation and full regression/security/operations evidence, obtain distinct production go/no-go. Currently deferred.

## 8. Implementation-readiness assessment

| Readiness area | Result | Basis |
|---|---|---|
| Owner architectural direction | **Consolidated** | All 17 selected options captured from supplied summary; conflicting prior recommendation entries explicitly resolved |
| Exact field-level contract | **Partially ready; not closed** | Options require remaining details: username normalization, status vocabularies, event timezone constraints, rating range, group definitions, audit/settings contracts, and retention schedule |
| Application compatibility | **Not ready** | Service/model/UI mismatches in Sections 3–4 remain unmodified and need focused implementation/tests |
| Security readiness | **Not ready** | A-14 independent review and exact grant/RLS/trusted-operation tests remain required; A-09 details open |
| Migration readiness | **Not ready** | New migration chain not authored; local clean install, schema comparison and recovery validation incomplete |
| Non-production initialization | **Deferred / not authorized** | A-15 remains deferred; no separate execution authorization |
| Production deployment | **Deferred / not authorized** | A-16 remains deferred; requires successful non-production acceptance and separate go/no-go |
| CARS readiness | **Not ready** | D29-06 prohibits unverified values as scoring inputs; CARS source/policy approvals remain outside initial core schema |

## 9. Unresolved blocker register and closure requirements

| Blocker | Closure requirement | Owner/reviewer roles |
|---|---|---|
| Owner identity/version record | Record owner name, role, decision date and effective policy version from the approved summary | Project owner/records steward |
| Username normalization | Specify deterministic Unicode/case/whitespace rules, registration/update/login behavior, reserved names and collision remediation | Product owner, identity engineer, security reviewer |
| Publication/verification states | Exact values, transitions, actors and public visibility predicates; migrate app logic consistently | Project owner, admin workflow owner, architect |
| D29-10 group arithmetic | Map the selected adult/child/elder detail to the existing derived-adult model or add an explicit nullable adult field; define complete-count consistency rule without age cutoffs | Product owner, data/model architect; pricing steward for rates |
| D29-11 travel mode | Approve nullable profile vocabulary and distinguish it from trip-wide/per-leg modes and water-transfer constraints | Product owner, routing specialist |
| D29-12 scale | Inspect review submission interface or confirm new UX; approve exact integer range and input validation | Product owner, UI maintainer |
| D29-13 moderation | Approve state transitions, author view/edit, moderator permissions, public eligibility and audit coverage | Moderation owner, security reviewer |
| D29-14 event compatibility | Verify event authoring/display/filter use; implement local date, all-day flag, instants, IANA timezone and constraints | Event product owner, app architect |
| D29-15/16 A-09 | Action/outcome catalog, metadata redaction/retention, setting registry/defaults/types/access and emergency operation | Security/privacy owner, DBA |
| D29-17 A-11 | Per-relation retention periods, anonymization, FK actions, Auth closure and backup deletion process | Project owner, privacy/legal, DBA |
| Application compatibility | Implement every required change in Sections 3–4 with regression tests and preserve non-CARS/manual/circuit workflows | Flutter team, reviewer |
| Migration and A-14 | New chain, local clean install, schema tests, trusted function review, independent RLS/grant tests, recovery rehearsal | DBA, independent security reviewer |
| Remote gates | Separate written A-15/A-16 authorizations with exact scope and evidence | Authorized environment/release owners |

## 10. Recommended next phase

Proceed with a **controlled implementation-readiness phase**, not database deployment:

1. Append the missing owner identity/role/date/version to the decision record when available; do not infer it.
2. Close the technical details listed above through product/security/privacy reviewers and produce an approved field manifest.
3. Create an application change plan and focused test acceptance matrix covering every incompatibility; preserve manual selection, circuit planning, Hive locality, MO-GA fixed constraints and CARS safe-unavailable behavior.
4. Obtain independent A-14 and formal A-09/A-11 reviews.
5. Only after those gates, authorize a separate coding task to implement app and migration artifacts. This report itself authorizes neither.
6. Complete local validation and request A-15/A-16 separately; both remain deferred now.

## 11. Validation and closeout

- All decision IDs **D29-01 through D29-17** are present in the consolidation table.
- Conflicting prior worksheet recommendations are resolved in favor of the supplied summary: D29-10 C; D29-12 rating A and duplicate 2; D29-14 C; D29-17 A.
- Owner choices are described as architectural directions; formal implementation authorization remains not granted.
- No owner name, role, decision date, or effective policy version was invented.
- No code, tests, configuration, SQL, migrations, database objects, or Supabase projects were changed/accessed.
- **Created:** `docs/TASK_30_SAMALNAV_FINAL_OWNER_DECISION_CONSOLIDATION_AND_IMPLEMENTATION_READINESS.md`.
