# Task 22 — SamalNav Canonical Database Schema Decision Closure and Approval Register

**Project:** SamalNav
**Status:** Decision and approval workbook; no decision is approved by this document.
**Scope:** Repository-derived architecture decisions for a future canonical database contract.
**Authorization:** Planning only. This document does not authorize SQL, migration design execution, database initialization, application changes, or production deployment.

## 1. Executive summary

Task 21 identified twelve `public` relations queried by current application code, with Supabase Auth as a managed platform dependency. It also identified conditional/future CARS data needs. Task 20 found that the checked-in schema backup and seven migration files do not form a safe, unambiguous initializer. Task 18 query outputs have not been supplied, and the reported non-production absence of application tables is owner-reported, not independently verified in this repository.

This register turns those findings into owner decisions, assigns accountable professional roles without inventing people, and defines evidence and readiness gates. It preserves the distinction between:

- **Scope A:** current runtime relations supported by current Supabase calls.
- **Scope B:** conditional CARS and future server-persistence relations, which are not current runtime dependencies.

No relation, column, constraint, role, policy, seed value, migration sequence, or authorization is approved here. Blank fields and recommendations are not approvals. The immediate blocker is to collect and validate the missing evidence and complete the owner decisions before freezing a schema manifest.

## 2. Evidence basis and status semantics

Reviewed Tasks 17–21 and the repository source/schema inventory summarized there. Task 21 confirms the twelve direct runtime relations and documents model/wire expectations; Task 20 records the migration collision, bootstrap gaps, conflicting domain models, risky role-trigger patterns, and lack of a canonical initializer. These are repository findings, not deployed-schema facts.

The requester previously reported the non-production target as `SamalNav-NonProduction` (`iwzyasdanesaaxxjujxr`, `ap-southeast-2`) and reported application relations absent from inspected schemas and `to_regclass('supabase_migrations.schema_migrations')` as NULL. These observations remain **owner-supplied**. No raw Task 18 output was present for review. No database was accessed as part of this register.

Allowed decision statuses:

- **Unanswered** — no explicit response is recorded.
- **Awaiting evidence** — evidence required to evaluate the choice has not been supplied.
- **Awaiting technical review** — a response/evidence exists but the designated technical review is incomplete.
- **Awaiting owner approval** — reviewed proposal awaits explicit authorized approval.
- **Approved** — explicit approver, evidence, date, and effective version are recorded.
- **Rejected** — an explicit decision rejects the proposal; rationale and replacement path are recorded.
- **Deferred** — an authorized owner explicitly defers it and records the blocker/next review point.

**Current status of every decision in this document: Unanswered**, unless its row explicitly says evidence collection is also pending. Prior approved requirements such as AP-24 are recorded as constraints, not reapproved here.

## 3. Decision register and owner responsibility matrix

Role assignments below identify the recommended accountable discipline only. They do not indicate that any person has accepted responsibility. The approver should be the project owner or the formally delegated authority appropriate to the decision; security-sensitive decisions also require the named security review role to sign off.

| ID    | Decision                                                   | Responsible role                         | Supporting roles                                            | Required reviewer / approval authority                                      | Exact information required before decision                                                                               | Documentary evidence and expected deliverable                                        | Dependencies                             | Status                    |
| ----- | ---------------------------------------------------------- | ---------------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------ | ---------------------------------------- | ------------------------- |
| DB-01 | Canonical Scope A relation set                             | System architect                         | Flutter lead, database administrator (DBA), feature owners  | Architecture reviewer; project owner                                        | Confirm each table has a current user-visible/runtime consumer; identify exclusions/additions                            | Current query inventory and approved relation manifest                               | All feature decisions; Task 21 mapping   | Awaiting technical review |
| DB-02 | Auth-to-profile lifecycle and provisioning                 | Backend developer                        | Supabase/Auth specialist, Flutter lead, DBA                 | Security/privacy reviewer and project owner                                 | Email/OAuth lifecycle, duplicate/idempotency behavior, role source, failure/retry behavior                               | Profile lifecycle sequence and threat review                                         | DB-03, DB-04                             | Unanswered                |
| DB-03 | Role vocabulary and assignment authority                   | Project owner / product authority        | Backend developer, DBA, security reviewer                   | Project owner plus security approval                                        | Decide `establishment` vs `owner`; enum/check vs role catalog; authorized grant/revoke path                              | Approved role vocabulary and role-administration workflow                            | DB-02, DB-10, DB-17                      | Awaiting evidence         |
| DB-04 | MFA state ownership                                        | Identity/security architect              | Supabase/Auth specialist, Flutter lead                      | Privacy/security reviewer and project owner                                 | Whether `mfa_email_enabled` is application preference, Auth state, or stale UI field; source of truth                    | Identity/MFA contract and data-protection rationale                                  | DB-02, DB-17                             | Awaiting technical review |
| DB-05 | Establishment ownership cardinality                        | Project owner / product authority        | DBA, backend developer, establishment workflow owner        | Architecture reviewer and project owner                                     | Preserve approved AP-24 one owner to multiple establishments; reconcile `.maybeSingle()` consumer                        | Cardinality confirmation and app query behavior decision                             | DB-01                                    | Awaiting technical review |
| DB-06 | Tourist profile defaults and preferences                   | Tourist product owner                    | Flutter lead, DBA, research/methodology reviewer            | Project owner; privacy reviewer for profile data                            | Which fields are nullable/defaulted at creation; preference confirmation source and semantics                            | Create-if-missing field contract; explicit confirmed/unconfirmed/no-selection states | DB-02, DB-17; CARS DB-23                 | Awaiting evidence         |
| DB-07 | Destination publication, status, and verification          | Destination product owner                | Administrator workflow owner, DBA, security reviewer        | Project owner / authorized publication authority                            | Canonical status vocabulary; relationship of `status`, `is_active`, `is_verified`; allowed transitions and public fields | State-transition table, publication criteria, source authority                       | DB-01, DB-17                             | Awaiting evidence         |
| DB-08 | Destination rating and price data contract                 | Data steward / destination product owner | CARS owner, DBA, finance/pricing reviewer                   | Project owner; methodology approval for CARS use                            | Rating meaning/scale/provenance/freshness; price amount/currency/unit/source/verification                                | Versioned rating and price-source contract; actual-zero semantics                    | DB-07; CARS DB-22–DB-24                  | Awaiting external data    |
| DB-09 | Reservation lifecycle and ownership                        | Reservation product owner                | Backend developer, establishment workflow owner, DBA        | Project owner and security reviewer                                         | Status vocabulary/transitions; tourist, establishment, destination links; which role may change each field               | Reservation state machine and authorization matrix                                   | DB-03, DB-05, DB-17                      | Unanswered                |
| DB-10 | Payment currency and trusted settlement                    | Payments product owner                   | Payment-provider/backend specialist, DBA, security reviewer | Project owner plus security/finance authority                               | Currency, provider event verification, reference uniqueness, reversal/refund states, allowed writers                     | Payment contract and trusted settlement sequence                                     | DB-03, DB-09, DB-17                      | Awaiting external data    |
| DB-11 | Review publication and aggregation                         | Review/data product owner                | Moderation owner, CARS methodology reviewer, DBA            | Project owner and privacy reviewer                                          | Choose `reviews`/`establishment_reviews`; publication/moderation; destination vs establishment aggregate semantics       | Review lifecycle, visibility, aggregation/source contract                            | DB-07, DB-17; CARS DB-22                 | Awaiting evidence         |
| DB-12 | Audit event integrity                                      | Security architect                       | Backend developer, DBA, audit/compliance owner              | Security reviewer and project owner                                         | Trusted actor identity, immutable timestamp, event vocabulary, allowed metadata/retention                                | Server-authored audit contract and access matrix                                     | DB-02, DB-03, DB-17                      | Awaiting technical review |
| DB-13 | Category/activity taxonomy                                 | CARS/data steward                        | Research/methodology reviewer, destination owner, DBA       | Project owner and methodology reviewer                                      | Stable IDs, activity-to-destination links, canonical preference mapping and completeness/versioning                      | Authoritative taxonomy/mapping with coverage and stewardship                         | CARS DB-22, DB-23                        | Awaiting external data    |
| DB-14 | Future CARS source scope                                   | CARS product/methodology owner           | Data stewards, routing/weather/pricing providers, DBA       | Project owner and methodology reviewer                                      | Approved source per criterion, provenance/freshness, missing-data semantics, policy status                               | Source register and evidence contracts; no scores implied                            | DB-08, DB-11, DB-13; CARS DB-22–DB-27    | Awaiting evidence         |
| DB-15 | Server-side itinerary persistence                          | Itinerary product owner                  | Flutter/MO-GA lead, DBA, security reviewer                  | Project owner                                                               | Decide device-only vs synchronized drafts; ownership, versioning, selected stops, day/order and accepted/complete states | Server persistence requirement and lifecycle/RLS contract                            | DB-01, DB-17; CARS integration decisions | Unanswered                |
| DB-16 | Migration, configuration, and seed architecture            | DBA / release engineer                   | Backend developer, security reviewer, project owner         | Architecture reviewer; explicit non-production operator authorization later | Unique versioning, tool/config, clean install, dependency and transaction strategy, separation of reference/test data    | Approved migration manifest, local validation and recovery plan                      | DB-01–DB-15, DB-17                       | Awaiting technical review |
| DB-17 | RLS, grants, and administrative privilege model            | Database security reviewer               | DBA, backend developer, privacy/security officer            | Security authority and project owner                                        | Per-relation/per-command roles, column exposure, `USING`/`WITH CHECK`, grants, functions and embedded reads              | Reviewed access matrix and synthetic identity test plan                              | DB-02–DB-12; DB-16                       | Awaiting evidence         |
| DB-18 | Canonical column, key, null/default, and deletion contract | DBA                                      | Flutter lead, backend developer, data stewards              | Architecture reviewer and project owner                                     | Exact types, nullability, defaults, key/FK actions, lifecycle and compatibility for each accepted relation               | Versioned schema manifest reconciled with Task 18 and call sites                     | DB-01–DB-17                              | Awaiting evidence         |

### 3.1 Decision response record

For each DB-ID, maintain a separate record (in this document or a linked decision log):

- Selected option/revised contract: **************\_\_**************
- Rationale and consequences: ****************\_\_\_\_****************
- Evidence reference(s) and evidence classification: ******\_\_******
- Conditions/limitations: ********************\_********************
- Responsible role: ********\_\_******** Reviewer role: ********\_\_********
- Approver name/role: ********\_\_******** Decision date: ****\_\_****
- Effective schema/policy version: **************\_\_\_\_**************
- Status (one allowed value): ********\_\_********

Do not fill the approval fields with inferred values. A role assignment alone is not acceptance by an individual.

## 4. Scope A — Twelve-table current runtime schema review

Inclusion below means current source contains a Supabase data-access path. It does not approve the table definition or prove deployed availability. Required fields are concise summaries of Task 21’s runtime wire contract; consult Task 21 before drafting exact types/nullability. All relation policies remain subject to DB-17 and exact SQL has not been selected.

| Relation                 | Inclusion justified by code?                                                               | Runtime-required field groups                                                                                                  | Key relationships / constraints to decide                                                                  | Security requirement                                                                              | Outstanding decisions |
| ------------------------ | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | --------------------- |
| `profiles`               | Yes: registration, role, login-by-username, profile page, admin and related profile embeds | Auth ID, email/display name, username, phone, role; app also references `mfa_email_enabled`                                    | PK maps to Auth user; conditional unique username; FKs for embedded profile relationships                  | Self-service cannot change privileged role; protect contact/MFA fields; no public full-row access | DB-02/03/04/17/18     |
| `destinations`           | Yes: tourist/admin reads, state updates, verification approval insertion                   | ID/name/location/category/status, coordinates, active/verified flags; optional descriptive/media/operating/rating/price fields | PK; optional owner/establishment link; taxonomy FK only after approved catalog; no assumed name uniqueness | Public reads limited to approved published fields; protected admin/owner writes                   | DB-07/08/13/17/18     |
| `establishments`         | Yes: owner dashboard and admin verification                                                | ID, owner ID, name, address/category and verification state                                                                    | PK; owner FK; one-to-many ownership under AP-24; no `UNIQUE(owner_id)`                                     | Owner access only to owned rows; verification staff controlled                                    | DB-03/05/09/17/18     |
| `location_verifications` | Yes: admin pending queue, review update, destination approval flow                         | ID, submitted place fields, status, creation/review fields                                                                     | PK; submitter/reviewer links; optional destination link; deletion and atomic approval behavior             | Submitter cannot self-approve; reviewer identity and transition protected                         | DB-07/17/18           |
| `tourist_details`        | Yes: current authenticated tourist planning profile service                                | User ID, budget/time/preferences/origin/mode and optional group counts                                                         | PK; one profile per user; Auth/profile FK selected consistently                                            | All rows scoped to `auth.uid()`; no inference of preference confirmation                          | DB-02/06/17/18        |
| `favorites`              | Yes: load/delete/undo insert                                                               | ID, user ID, place name, optional location/category/rating/created time                                                        | PK; owner FK; optional destination FK only if chosen; duplicate rule unresolved                            | User may operate only on own rows; favorited rating is not CARS evidence                          | DB-17/18              |
| `reservations`           | Yes: establishment dashboard updates/list and admin count                                  | ID, establishment/tourist IDs, status, pax/time; optional destination/service                                                  | PK; participant and establishment FKs; optional destination; embedded profile relationship                 | Tourist/establishment/admin visibility and update rights separated                                | DB-03/05/09/17/18     |
| `payments`               | Yes: dashboard read, aggregate, status update                                              | ID, participant IDs, amount/status, optional reservation/provider fields and timestamps                                        | PK/FKs; currency and provider-reference rules unresolved                                                   | Settlement must be trusted-provider/server verified, not asserted by client                       | DB-03/09/10/17/18     |
| `reviews`                | Yes: establishment dashboard list and average                                              | ID, tourist/destination, optional establishment, stars, text/time                                                              | PK/FKs and profile embed; publication and aggregate rules open                                             | Review text/identity protected per approved publication/moderation rules                          | DB-11/17/18           |
| `events`                 | Yes: administrator count/list and profile embed                                            | ID/title/category/date/publisher and optional description                                                                      | PK; publisher relationship for embed                                                                       | Published read and management rights separately defined                                           | DB-17/18              |
| `audit_logs`             | Yes: current client insert and super-admin list/count                                      | ID/time, actor/user, action/type, description/target; optional metadata                                                        | PK; actor reference; aliases resolved to one canonical contract                                            | Prefer trusted server-authored immutable records; no caller-chosen actor/role                     | DB-03/12/17/18        |
| `system_settings`        | Yes: super-admin maintenance read/upsert                                                   | Key, JSON value, update actor/time                                                                                             | Key PK; optional actor FK                                                                                  | Restricted administration access; no secret storage                                               | DB-03/17/18           |

**Scope A exclusions:** `auth.users` and Auth APIs are managed platform dependencies, not application tables to recreate. `bookings`, `transactions`, `establishment_reviews`, and `tourist_profiles` are not selected merely because they appear in local artifacts; current services use `reservations`, `payments`, `reviews`, and `tourist_details`. The owner must approve Scope A before a canonical manifest is frozen.

## 5. Security and authentication decision worksheets

Each worksheet begins **Unanswered**. Choose an option, record rationale/evidence, name the reviewer and approver, and version the result. Options are alternatives, not endorsements.

### DB-02/03 — Profile provisioning and `establishment` versus `owner`

**Question:** How are profiles created for email/OAuth identities, and what is the sole trusted source for role assignment?

| Option                                                                                                              | Consequence / required evidence                                                                                                                                                         |
| ------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Auth lifecycle invokes a trusted, idempotent server-side profile provisioner                                        | Requires reviewed server function/trigger or server API, safe `search_path`, owner/grants, retry/idempotency tests, and role assignment that ignores user-editable privileged metadata. |
| Client creates only its own basic profile; privileged roles assigned through a separate trusted administration path | Keeps ordinary signup simple, but needs restrictive insert/update checks and secure role promotion workflow. Avoid competing trigger and client writes.                                 |
| Other (fully specify)                                                                                               | Must cover signup, OAuth, duplicate callback, deleted Auth user, retries and failed profile creation.                                                                                   |

Role vocabulary decision: **Option A:** canonical role remains `establishment`; **Option B:** canonical role is `owner`; **Option C:** map both through a versioned compatibility policy; **Option D:** other. The application enum uses `establishment`, while backup constraints include `owner`. Evidence needed: current app role consumers, approved product terminology, existing profile values if safely available from owner-run aggregates, and migration/compatibility effects. Do not seed or assign a role until decided. **Status: Awaiting evidence.**

### DB-04 — `mfa_email_enabled` field ownership

**Alternatives:** A. Auth/provider is authoritative and app field is removed or derived; B. application-owned notification/security preference with explicit non-authentication meaning; C. retain a database field with separately defined source/update path; D. other. Evidence: current UI behavior, Supabase Auth MFA/OTP contract, privacy review, and backup-vs-code discrepancy. Consequences: wrong ownership can falsely represent account security state. **Status: Awaiting technical review.**

### DB-05 — AP-24 ownership cardinality

**Approved invariant:** one owner may manage multiple establishments. Do not adopt `UNIQUE(establishments.owner_id)`. **Open implementation decision:** change the service to a collection/selection workflow or explicitly define an active-establishment selector that still preserves multiple rows. Evidence: product workflow and current `.maybeSingle()` call behavior. Any schema and app changes require their own approvals. **Status: Awaiting technical review.**

### DB-06 — Tourist defaults and preference confirmation

**Alternatives:** A. database supplies documented neutral defaults for fields genuinely optional at profile creation; B. creation flow supplies explicit values; C. make fields nullable and keep profile incomplete until confirmed; D. other. Evidence: model requiredness, `createIfMissing` insert shape (currently only `user_id`), UI onboarding requirements, and serialization round trips. Preference states must distinguish confirmed selections, unconfirmed saved values, no selection, and unavailable profile. Never infer confirmation from row existence or set a confirmation timestamp without an approved field. **Status: Awaiting evidence.**

### DB-07 — Destination status/publication/verification

**Alternatives:** A. canonical lifecycle with distinct publication and verification states; B. one authoritative status with derived active/verified semantics; C. other. Specify allowed state transitions, who can perform them, tourist-visible predicate, unpublished/admin behavior, and how fallback records are labeled. Evidence: destination/admin UI, verification workflow, owner publication requirements, and privacy/security review. `status`, `is_active`, and `is_verified` must not be treated as equivalent without a decision. **Status: Awaiting evidence.**

### DB-10 — Payment settlement and currency

**Alternatives:** A. trusted payment-provider webhook/server operation is authoritative; B. verified external/manual settlement through authorized backend operation; C. no in-app settlement/status mutation until trusted flow exists; D. other. Require currency per amount, provider event/reference verification, idempotency, refund/reversal behavior and allowed transitions. Current client `markPaymentPaid` is not settlement evidence. No credentials belong in this register. **Status: Awaiting external data.**

### DB-12 — Audit integrity

**Alternatives:** A. server-only append operation stamps actor, role, time and event type; B. narrowly constrained client event ingestion with server-derived identity and schema validation; C. no client audit writes until a trusted path is implemented; D. other. Require threat model, event/retention contract, redaction policy and access test. Reject caller-controlled actor/role/timestamp as authoritative. **Status: Awaiting technical review.**

### DB-17 — RLS and administrative privilege model

The reviewer must approve an access matrix for every table, every command (SELECT/INSERT/UPDATE/DELETE), and each exposed role; include schema/table/column grants, sequences, function EXECUTE, RLS enabled/forced choice, `USING`, `WITH CHECK`, PostgREST embeds, and fallback/error behavior. Specify self/participant/owner/reviewer/admin scope separately. Do not copy backup policies: Task 17/20 identify overlapping permissive policies and unsafe examples. Required evidence: exact selected schema manifest and synthetic-identity tests for anon, tourist A/B, establishment owner A/B, administrator, and super-admin as applicable. **Status: Awaiting evidence.**

## 6. Scope B — Future CARS and optional server feature requirements

The following are conditional requirements, not additions to Scope A. A relation enters a future canonical schema only after a current feature contract, source, security policy, and implementation approval justify it.

| Feature/data area               | Conditional fields/relationships needed                                                                                                                        | Current status and evidence gate                                                                                                   |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Activities                      | Stable activity ID; destination FK; active/completeness state; canonical category identifier; source/update provenance; duration/price only with units         | No current activity reader/model; authoritative activity source and category mapping absent; DB-13/14.                             |
| Category and preference mapping | Versioned exact-ID mapping from confirmed preference identifiers to activity category IDs; effective dates/completeness                                        | Similar text values do not prove equivalence; no approved mapping source; DB-06/13/14.                                             |
| Public destination ratings      | Approved destination aggregate/source, scale, actual-zero distinction, verification/source/freshness, destination identity                                     | Existing establishment review average is not a destination rating source; Task 18 result and policy required; DB-08/11/14.         |
| Weather                         | Provider/forecast evidence keyed by requested destination/location and visit interval; observation/forecast timestamp, units, retrieval freshness and coverage | Raw provider boundary exists; no approved suitability classifier. Persistent cache is optional and needs a separate policy; DB-14. |
| Verified prices                 | Cost components, amount, currency, pricing unit, applicability, source/verification/freshness and package-inclusion relation                                   | Raw zero-default amounts are ambiguous; group rates and candidate allocation unresolved; DB-08/10/14.                              |
| Road routing                    | External provider contract with endpoints, mode, route type, date, distance/duration, retrieval time                                                           | No configured live route source or approved mode-specific score rule; DB-14.                                                       |
| Water transportation            | Authoritative connection/operator, date-valid schedule, duration/transfer and freshness, separated from road route                                             | No verified connection data; remain unavailable absent authority; DB-14.                                                           |
| Visit/travel/transfer duration  | Source and unit per activity/destination, route duration, transfer/return scope and freshness                                                                  | Current travel assessment does not supply a verified full candidate duration; DB-14.                                               |
| Date availability               | Destination/date/timezone, open/closed/unknown state, source/steward and coverage/freshness                                                                    | Backup declaration is not runtime integration; no current reader or operational source; DB-07/14.                                  |
| Server itineraries              | Tourist owner, draft/accepted/completed state, destination IDs/order/day assignment, commitment integrity, timestamps/version and RLS                          | Current drafts are Hive-local and MO-GA in-app; only add after product decision DB-15.                                             |

No CARS numeric formula, threshold, weight, source value, score or production recommendation is approved by this register. Preserve safe unavailable/insufficient behavior until separate policy decisions and source contracts are completed.

## 7. Canonical schema approval worksheet

Use the statuses in Section 2 and complete the decision-specific details in Section 3.1. Every row must have evidence classification, reviewer, and an explicit owner decision before it can be marked **Approved**.

| Approval item                 | Scope                  | Required record                                                                                                 | Current status            |
| ----------------------------- | ---------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------- |
| Relation manifest             | Scope A                | Approved inclusion/exclusion of each of twelve tables; platform dependencies listed separately                  | Awaiting owner approval   |
| Column contract               | Scope A                | Name, type, nullability, default, source, semantic meaning, compatibility and sensitivity per column            | Awaiting evidence         |
| Keys and relationships        | Scope A                | PK/unique/FK fields, target, cardinality and delete/update behavior                                             | Awaiting evidence         |
| Constraints and indexes       | Scope A                | Each constraint/index tied to a use case and integrity/performance requirement; no unsupported uniqueness       | Awaiting technical review |
| Auth dependency               | Scope A                | Profile identity/lifecycle, trusted role assignment, MFA ownership                                              | Awaiting owner approval   |
| Functions and triggers        | Scope A                | Body/owner/security mode/search path/grants/trigger event, or explicit decision that none are needed            | Awaiting technical review |
| RLS and grants                | Scope A                | Per-relation command/role matrix, predicates, column exposure, function/sequence grants and tests               | Awaiting evidence         |
| Seed/reference data           | Scope A                | Exact synthetic/reference values, source, idempotency, environment and owner                                    | Awaiting owner approval   |
| Future CARS objects           | Scope B                | Feature requirement, approved data provider/authority, evidence contract and separate inclusion approval        | Awaiting evidence         |
| Migration architecture        | Both                   | Unique migration versions, runner/config, dependency order, transaction/recovery and clean-install proof        | Awaiting technical review |
| Non-production initialization | Separate authorization | Project reference confirmation, reviewed hashes, operator, stop conditions and explicit non-production approval | Unanswered                |
| Production deployment         | Separate authorization | Security acceptance, release/rollback/monitoring, owner and authorized deployment approval                      | Unanswered                |

### Schema manifest sign-off

- Canonical schema bundle/version: **************\_\_**************
- Scope A relation manifest reference/hash: **********\_**********
- Scope B exclusions/conditional additions reference: ****\_\_\_\_****
- Evidence package reference(s): **************\_\_\_\_**************
- DBA reviewer/role/date: ******************\_\_\_******************
- Security reviewer/role/date: ****************\_\_****************
- Architecture reviewer/role/date: **************\_\_**************
- Project owner/authorized approver, role/date: ********\_\_********
- Decision status: ********\_\_********
- Conditions and unresolved exceptions: ************\_************

An `Approved` status is invalid if any required field is blank, required evidence is missing, or an unresolved condition changes the contract.

## 8. Evidence collection checklist

### Already available (repository-derived only)

- [x] Task 21 runtime query/table inventory and application wire-contract mapping.
- [x] Task 20 migration inventory, version collision, bootstrap dependencies, seed risks, and local schema conflicts.
- [x] Task 21 list of current CARS data boundaries and absent activity/category/availability database adapters.
- [x] Approved AP-24 one-owner-to-many-establishments requirement (must be preserved).

### Still required from owner / project decision-makers

- [ ] Completed, versioned decision records DB-01–DB-18 with approver role/name/date and rationale.
- [ ] Explicit confirmation of Scope A and each table's current feature owner.
- [ ] Role vocabulary and trusted assignment authority; Auth/profile lifecycle; MFA ownership.
- [ ] Tourist profile field defaults/nullability and preference confirmation contract.
- [ ] Destination publication state machine and relationship between active/verified/status.
- [ ] Reservation lifecycle, payment states/currency, review moderation/aggregation, audit ownership.
- [ ] Per-table RLS/grant matrix and separate security review.
- [ ] Decision whether itineraries remain local-only or require a separately scoped server feature.
- [ ] Canonical schema manifest sign-off and separate development/non-production authorization.

### Required owner-supplied technical evidence

- [ ] Complete, sanitized Task 18 Query 18-01 through 18-05 outputs, including errors/visibility limitations and execution metadata, from the explicitly selected non-production project.
- [ ] Applicable aggregate-only Query 18-06 results only where Query 18-01 confirms compatible relations/fields; do not expose user-level records.
- [ ] Clarification of the reported project identity and inspected schema scope; no inference from `.temp` files or production connection configuration.
- [ ] If catalog visibility is limited, record the limitation; do not elevate privileges or use `service_role` to bypass it.

### External-provider / steward evidence (conditional Scope B)

- [ ] Activity catalog, canonical category mapping and completeness/stewardship evidence.
- [ ] Public rating authority and aggregation/publication contract.
- [ ] Weather provider contract, coverage/freshness, plus separately approved activity classifier.
- [ ] Verified pricing source and currency/unit/group/package rules.
- [ ] Mode-specific routing provider and distinct authoritative water-transfer source.
- [ ] Date-specific availability authority and complete visit/transfer duration sources.

Do not submit credentials, tokens, passwords, raw tourist data, review text, or unnecessary production data in this register.

## 9. Decision dependencies

| Depends on                          | Must be resolved before                                                | Reason                                                                           |
| ----------------------------------- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| DB-01 Scope A                       | DB-16/18; migration readiness Gate 1                                   | Cannot freeze columns or schema while relation scope is uncertain.               |
| DB-02 + DB-03                       | DB-17 and profile policies                                             | RLS and trusted role checks need a defined identity and role source.             |
| DB-05 AP-24                         | establishment key/index/query contract                                 | No unique owner constraint; service must support multiple establishments.        |
| DB-06                               | tourist profile defaults and future CARS preference contract           | Creation and confirmation semantics must not be inferred.                        |
| DB-07 + DB-08 + DB-11               | public destination/review contract; CARS source scope                  | Rating and public visibility rely on publication and review semantics.           |
| DB-09 + DB-10                       | participant RLS, FK lifecycle and payment tests                        | Payment and reservation state are coupled but separately authorized.             |
| DB-12                               | audit policy, write API and grants                                     | Actor identity and immutability must be secured before permitting writes.        |
| DB-13 + DB-14                       | any Scope B CARS adapter/table                                         | Stable IDs, authority and evidence semantics precede schema choice.              |
| DB-15                               | any itinerary persistence schema                                       | Current Hive behavior does not justify remote tables.                            |
| DB-01–DB-15 + DB-17                 | DB-18 canonical manifest                                               | Field/key/policy decisions depend on all use cases and authorization rules.      |
| DB-18 + Task 18 evidence            | schema approval and migration design                                   | Must reconcile the proposed contract with owner-supplied deployed catalog facts. |
| Approved manifest + security review | local migration test and then independent non-production authorization | Approval of design is not permission to execute.                                 |

## 10. Migration readiness gates and independent authorizations

| Gate                                     | Measurable exit criteria                                                                                                                                                                                                                                                                    | Separate authorization required?                                 | Current state                                           |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | ------------------------------------------------------- |
| **G1 — Canonical schema approval**       | DB-01–DB-18 have explicit dispositions; Task 18 catalog output reviewed or its limits formally accepted; every Scope A column/type/null/default/key/FK is versioned; Scope B objects are explicitly excluded or separately approved; conflicts and exceptions are signed                    | Yes: project owner + DBA/architecture + security approval        | **Blocked** — decisions and raw evidence are incomplete |
| **G2 — Migration design**                | A unique ordered migration manifest (no duplicate versions); each object has prerequisites/postconditions; schema and seed scripts separated; no unreviewed sample/personal data; idempotency and failure behavior documented; trusted function/trigger and policy review complete          | Yes: architecture/DBA/security design approval; not execution    | **Not ready**                                           |
| **G3 — Local migration testing**         | Clean isolated PostgreSQL/Supabase-compatible install succeeds; repeat-install/upgrade and rollback/recovery behavior documented; catalog diff equals approved manifest; all FKs/constraints/indexes and function grants verified; synthetic seeds only; automated authorization tests pass | Yes: controlled test-environment approval                        | **Not started / not authorized**                        |
| **G4 — Non-production initialization**   | Exact project name/reference confirmed in dashboard by operator; reviewed migration hashes and run order; backup/recovery/stop conditions; RLS and synthetic identities ready; named operator and window; post-run catalog/health checks specified                                          | **Yes: explicit non-production execution authorization**         | **Not authorized**                                      |
| **G5 — Application integration testing** | App contract aligns with installed schema; each current runtime table path tested under intended anon/auth roles; embedded joins, profile lifecycle, AP-24, reservation/payment/review/admin workflows pass; failures and fallback behavior documented                                      | Yes: integration test environment and synthetic-account approval | **Not started**                                         |
| **G6 — Production deployment**           | G1–G5 evidence accepted; production source/project identity and schema-diff review; secrets custody, access review, monitoring, rollback and operational ownership; release acceptance and explicit deployment record                                                                       | **Yes: separate production deployment authorization**            | **Not authorized**                                      |

Approval of G1 does not authorize G2 execution. Local tests do not authorize non-production execution. Non-production initialization does not authorize production deployment. A table manifest does not authorize CARS activation.

## 11. Remaining blockers

1. Raw, sanitized owner-run Task 18 catalog outputs have not been supplied; Task 20 absence statements remain owner-reported.
2. No canonical Scope A selection or column-level approval exists; Task 21 is a proposal, not a frozen schema.
3. Auth profile provisioning and trusted role authority are unresolved; `establishment`/`owner` vocabulary differs across code and backup.
4. AP-24 is approved but local schema has owner uniqueness and the current owner service uses `.maybeSingle()`.
5. `mfa_email_enabled` appears in application use but is absent from the checked-in backup; ownership/source needs decision.
6. Tourist profile create-if-missing defaults and preference confirmation are unresolved.
7. Destination state semantics, price/rating provenance, review aggregation, reservation lifecycle, payment currency/settlement, and audit integrity need explicit contracts.
8. Exact RLS/grants and synthetic identity tests are absent; local policies contain unsafe/overlapping examples and cannot be adopted unchanged.
9. CARS source mappings/providers and scoring decisions remain separate unresolved work; no future CARS table should enter Scope A by assumption.
10. No canonical migration runner/config/version plan, approved synthetic seed pack, or clean-install test exists.
11. No authorization exists to implement schema changes, initialize non-production, or deploy to production.

## 12. Recommended next activities

1. Assign a named decision owner and reviewer for each DB-ID by role, without treating the role matrix as acceptance.
2. Collect the existing owner-run Task 18 output bundle for the correct non-production project, sanitize it, and record its exact query IDs, timestamp, row counts, and limitations.
3. Close foundational decisions DB-01 through DB-07 and DB-17 first, especially identity, role assignment, AP-24, profile defaults, destination publication, and access controls.
4. Close workflow decisions DB-09 through DB-12, then settle column/relationship details under DB-18.
5. Keep DB-13/14/Scope B separate; approve CARS sources and policy only when authoritative evidence is available.
6. Review and sign one versioned canonical schema manifest. Do not convert this register directly into migration SQL.
7. Only after G1 approval, create a separately authorized migration design package. Then pass G2/G3 before seeking explicit G4 non-production execution approval.
8. Complete G5 integration/security acceptance before considering a distinct G6 production deployment request.

## 13. Current determination and closeout

- **Canonical schema approved:** No; this register is blank and all DB decisions remain unanswered or evidence-pending.
- **Scope A:** Twelve relations are justified as current source dependencies, but their schema is not approved.
- **Scope B CARS tables:** Conditional only; not part of the current runtime schema by default.
- **Migration design/execution:** Not authorized.
- **Non-production initialization:** Not authorized.
- **Production deployment or CARS activation:** Not authorized.
- **Created:** `docs/TASK_22_SAMALNAV_CANONICAL_DATABASE_SCHEMA_DECISION_CLOSURE_AND_APPROVAL_REGISTER.md`.
- No application code, existing migrations, SQL, configuration, database object, or Supabase project was changed or accessed. No SQL was executed.

## 14. Task 23 evidence addendum

Task 23 records owner-supplied observations that eleven relations targeted by Task 18 Query 18-01 were reported absent with NULL column metadata, and that the corresponding RLS inspection reported no matching relations/policies. Those observations do not establish the state of the six Task 21 runtime relations omitted from that target list, do not prove RLS is disabled on any existing relation, and do not establish that migration history is absent everywhere. Raw query outputs remain outstanding in the repository; no independent Supabase verification occurred.

The Task 23 reconciliation found that these observations can support scoped technical review of the Scope A manifest and access architecture. They do not close an owner decision or approve a schema. **DB-01–DB-18 statuses in this register are unchanged.** Refer to `docs/TASK_23_SAMALNAV_LIVE_SUPABASE_EVIDENCE_RECONCILIATION_AND_READINESS_REASSESSMENT.md` for the evidence coverage matrix, blocker list, and readiness determination. No migration design, initialization, or deployment authorization is granted.

## 15. Task 24 supplemental evidence package addendum

Task 24 prepares owner-run, read-only queries for the six Task 21 runtime relations omitted from Task 18’s original relation target list: `favorites`, `reservations`, `payments`, `events`, `audit_logs`, and `system_settings`. It also provides a cautious catalog inventory for migration-history relation names and a conditional query for `supabase_migrations.schema_migrations`.

No Task 24 query has been executed and no new relation, relationship, policy, grant, or migration-history result is available. Accordingly, **DB-01–DB-18 statuses remain unchanged**. The query package does not approve the twelve-table proposal, migrations, database initialization, or deployment. See `docs/TASK_24_SAMALNAV_SUPPLEMENTAL_RUNTIME_SCHEMA_AND_MIGRATION_EVIDENCE_COLLECTION.md` for SQL, evidence templates, and limitations.
