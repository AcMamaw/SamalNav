# Task 27 — SamalNav Remaining Architecture Decisions and Final Owner Decision Closure

**Status:** Owner responses to A-13 through A-16 received and recorded. A-13/A-14 are approved subject to their stated technical conditions; A-15/A-16 are deferred and authorize no execution.
**Basis:** Tasks 22–26, repository application contracts, and owner-supplied A-01–A-12 selections.
**Evidence boundary:** No Supabase project was accessed and no SQL was executed. Earlier relation-absence summaries remain owner-supplied; raw query outputs were not available for independent verification.
**Authorization:** This document does not authorize code changes, migration creation/execution, database initialization, or deployment.

## 1. Executive summary

Task 26 defines the four remaining decisions as:

- **A-13:** Approve the exact Scope A relation/column/type/nullability/constraint/index manifest after service mapping.
- **A-14:** Approve the RLS/grant invariants and require independent policy review and test evidence.
- **A-15:** Separately authorize controlled non-production initialization after implementation and testing.
- **A-16:** Separately authorize production release after non-production acceptance and security review.

The owner has selected approaches A-01 through A-12 in supplied responses. This document preserves those selections, including the correction that pre-booked details are tourist-entered, itinerary-local information and not actual SAMAL NAV reservations or confirmations. Payments remain excluded from the proposed core database. The selections do not constitute technical validation or authorization under A-13 through A-16.

The owner has now selected A for A-13 and A-14, subject to field-level amendments, service compatibility review, independent security review and testing. The owner selected C (defer) for A-15 and A-16. The decision register records those answers as owner-supplied; no separate approver name, role, signature, date, or effective version was included. Technical conditions remain open, and no migration, database initialization, or production release is authorized.

## 2. A-13 — Exact Scope A manifest approval

**Task 26 question:** “Approve exact Scope A relation/column/type/nullability/constraint/index manifest after service mapping?”

### Purpose and importance

A-13 freezes what the initial database is intended to contain. Without an accepted manifest, migration authors cannot reliably decide which objects, data types, defaults, constraints, indexes, and relationships to implement. The selected A-01–A-12 decisions narrow the proposed core schema to ten candidate relations: `profiles`, `destinations`, `establishments`, `location_verifications`, `tourist_details`, `favorites`, `reviews`, `events`, `audit_logs`, and `system_settings`.

`payments` is excluded. Pre-booked tourist itinerary details remain local Hive itinerary data under A-06/A-10; they are not a `reservations` database table. Existing application calls to `payments` and booking-like `reservations` still require compatibility changes before a complete release.

### Available options

| Option | Description | Advantages | Disadvantages / effects |
|---|---|---|---|
| **A — Approve the Task 26 ten-relation candidate manifest with documented field-level amendments** | Owner accepts the ten-relation scope and records every required field, type, nullability, default, relationship, delete action, constraint and index decision. | Gives implementation a stable, reviewable target and preserves the selected exclusions. | Requires resolving all fields marked optional/decision, agreeing status vocabularies, and completing service mapping. Approval alone does not authorize migration execution. |
| **B — Approve a revised manifest** | Owner identifies additions, exclusions or changed contracts and supplies the exact replacement requirements. | Can align scope with product needs that Task 26 missed. | Requires renewed dependency, security, application and migration review; cannot be treated as a minor informal edit if cardinality or access changes. |
| **C — Defer manifest approval** | Keep Task 26 as a proposal and collect remaining evidence/service decisions first. | Avoids freezing an incomplete schema. | Migration design and initialization remain blocked. |

### Application and security effects

- A-01/A-02 require an Auth-linked profile and trusted role assignment; no client-selected role is accepted.
- A-03/AP-24 requires one owner to many establishments, with no unique `owner_id`; the current `.maybeSingle()` lookup must be adapted.
- A-04 requires nullable planning data and explicit confirmation; current model/service create-if-missing behavior must be reconciled.
- A-05 requires publication and verification to be separate concepts. The accepted state values and compatibility mapping from current `status`, `is_active`, and `is_verified` fields must be explicit.
- A-06/A-10 put pre-booked details in the local itinerary. Current repository code has no pre-booking commitment model or MO-GA constraint adapter; this is an application feature gap, not a database-table dependency.
- A-07 excludes payments, but current establishment dashboard/services still query `payments`.
- A-08 requires one unified `reviews` table with exactly one subject (`destination_id` XOR `establishment_id`) and moderation; no automatic CARS rating aggregation.
- A-09 requires trusted immutable audit creation and controlled settings operations; existing client writes need redesign.
- A-11 requires soft retirement and controlled retention rather than blanket cascades.
- A-12 selects a new uniquely versioned migration chain, schema/seed separation and local-first validation; it does not approve or create migration files.

### Recommendation (not an approval)

**Recommend Option A only after** the owner and system architect/DBA complete a field-by-field manifest and reconcile current service contracts. If any relation or field has no current consumer or approved requirement, omit it from the initial schema. Do not include `payments`, a server `reservations` table, CARS evidence tables, or server itinerary persistence in the initial scope under the supplied decisions.

### Owner response

- Selected option: **A — approved subject to documented field-level amendments and application service compatibility review.**
- Owner response: Ten-relation candidate manifest is approved in scope; final schema must still state exact columns, types, nullability, PK/FK, unique constraints, indexes and delete behavior. Preserve AP-24 one-to-many ownership and A-08 unified reviews.
- Rationale and conditions: Scope approval is not migration creation or execution authorization.
- Supporting application/data evidence: Field-level manifest and service compatibility review remain required; raw live schema evidence remains unavailable for independent verification.
- Approver name and role/date/version: Not separately supplied with the response; retain as an audit-record gap.
- Status: **Owner-approved with conditions; technical manifest closure remains pending.**

## 3. A-14 — RLS and grant invariants approval

**Task 26 question:** “Approve RLS/grant invariants and require independent policy review/test evidence?”

### Purpose and importance

A-14 determines the authorization contract for every exposed relation and operation. RLS alone is insufficient unless schema usage, table/column grants, sequences, function execution privileges, `SECURITY DEFINER` behavior, PostgREST embeds, and field-level update rules are also reviewed. The Task 26 matrix is a proposed access model, not policy SQL and not evidence of current deployed behavior.

### Available options

| Option | Description | Advantages | Disadvantages / effects |
|---|---|---|---|
| **A — Accept the Task 26 least-privilege matrix as the security baseline, subject to independent security review** | Keep anon access narrow, scope tourist data to `auth.uid()`, establish owner/participant/admin predicates, deny client audit writes, and use trusted operations for protected transitions/settings. | Provides a consistent minimum baseline and includes role-specific synthetic tests. | Matrix still needs exact predicates, grant details, function contracts, and review against the final A-13 schema. Does not itself authorize deploying policies. |
| **B — Return a revised table/command/role matrix** | Security owner supplies exact alternatives and rationale for affected relations/operations. | Makes access choices explicit where business needs differ. | Requires full security review and tests; broader access increases exposure risk and may conflict with A-01/A-02/A-09. |
| **C — Defer approval pending threat model or source evidence** | Do not freeze RLS/grants yet. | Appropriate where role claims, data visibility, or trusted operations are not sufficiently specified. | A-13 migration design and all database initialization remain blocked. |

### Application and security effects

- Tourists must not change their own role or access another tourist’s `tourist_details` or favorites.
- Establishment owners may access only records tied to establishments they own; owner cardinality follows AP-24.
- Admin review/publication operations require a trusted role check and cannot permit submitter self-approval.
- Reservation-like booking operations and payment operations are outside current scope; do not create RLS for excluded tables as a substitute for removing current app queries.
- Reviews expose only the selected publication fields; authors cannot moderate their own records unless an explicit policy permits it.
- Audit events are server-generated and immutable through ordinary client roles; settings are allowlisted and written through a trusted administrative operation.
- The first super-admin bootstrap and role changes must not rely on user-editable metadata.

### Recommendation (not an approval)

**Recommend Option A as a security baseline, not as deployable policy.** Require an independent reviewer to convert it to exact grants and RLS predicates after A-13 is closed. Test anon, two tourists, two establishment owners, administrator and super-admin using synthetic identities; test SELECT/INSERT/UPDATE/DELETE and protected columns independently. Do not use service-role credentials in the client.

### Owner response

- Selected option: **A — accept the Task 26 least-privilege matrix as the baseline, with independent security review/testing required.**
- Owner response: No unrestricted client access to sensitive administrative operations, audit records, or protected system settings. Final RLS and grants require technical validation and separate implementation authorization.
- Revised matrix/threat model: Task 26 matrix remains the baseline, not deployable policy SQL.
- Independent reviewer, synthetic identity evidence, exceptions: Must be supplied during technical review.
- Approver name and role/date/version: Not separately supplied with the response; retain as an audit-record gap.
- Status: **Owner-approved with conditions; security validation and implementation authorization remain pending.**

## 4. A-15 — Separate controlled non-production initialization authorization

**Task 26 question:** “Separately authorize controlled non-production initialization after implementation/testing?”

### Purpose and importance

A-15 is an execution authorization, not a schema design choice. It allows a named operator to apply a specific reviewed migration sequence to a specifically identified non-production project after required preparation and validation. A-12’s selected migration strategy and any successful local tests do not automatically grant this authorization.

### Available options

| Option | Description | Advantages | Disadvantages / effects |
|---|---|---|---|
| **A — Authorize a defined non-production run after all prerequisites pass** | Identify exact project/reference, migration file hashes, operator, execution window, backup/recovery plan, stop conditions, and post-run checks. | Creates a bounded and auditable execution scope. | Irreversible or partially reversible effects may remain; requires all preflight evidence and explicit operator approval. |
| **B — Authorize only a subset or rehearsal** | Permit a clearly named, non-destructive/preflight activity or a limited migration subset. | Can validate specific assumptions while limiting scope. | The authorization must enumerate exact operations; it cannot be generalized to the full initializer. No SQL was authorized by this Task 27. |
| **C — Defer / do not authorize** | Continue local validation and resolve blockers before any remote execution. | Preserves the project while design and compatibility are incomplete. | Non-production database remains uninitialized and remote integration cannot be validated. |

### Current prerequisites and effects

The repository currently has conflicting historical migration files, duplicate `002` prefixes, mixed schema/seed content, and no approved new migration chain. Owner-supplied relation absence summaries lack retained raw query output and independent verification. Application compatibility changes remain outstanding: profile trigger behavior, AP-24 multi-establishment support, nullable tourist data, pre-booked local constraints, payment UI removal/redesign, booking-like dashboard removal/redesign, atomic verification, and trusted audit/settings paths. No migration files or post-migration tests are prepared by this document.

### Recommendation (not an approval)

**Recommend Option C at this time.** A-15 should be reconsidered only after a reviewed new migration chain exists, it passes clean local install and security/application regression tests, the target is independently confirmed, backups and recovery are verified, and the exact migration hashes/operator/window/stop criteria are listed. The reported non-production project reference remains owner-supplied, not independently verified here.

### Owner response

- Selected option: **C — defer.**
- Owner response: Wait for finalized canonical schema/contracts; reviewed new uniquely versioned migration chain; verified application compatibility; reviewed RLS/grants/constraints/relationships; passing local clean-install tests; documented and tested backup/recovery; confirmed non-production project; and separate explicit execution authorization.
- Exact project, migration hashes, operator/window, backup/recovery and post-run results: Not applicable yet; prerequisites are not complete.
- Approver name and role/date/version: Not separately supplied with the response; retain as an audit-record gap.
- Status: **Deferred; no SQL execution or database initialization is authorized.**

## 5. A-16 — Separate production deployment authorization

**Task 26 question:** “Separately authorize production release after non-production acceptance/security review?”

### Purpose and importance

A-16 is a production release gate, separate from approving a schema, creating migration files, or initializing non-production. It applies only to a specific accepted release and production change set. It must not be inferred from Task 26, A-12’s migration strategy, a completed non-production run, or a general project-owner statement.

### Available options

| Option | Description | Advantages | Disadvantages / effects |
|---|---|---|---|
| **A — Authorize a defined production release after acceptance gates pass** | Specify release/migration hashes, systems affected, deployment window, accountable operator, backup/restore plan, monitoring and rollback decision. | Provides a controlled path to release after evidence is reviewed. | Carries production risk and must be signed by an authorized production approver after independent security/operations review. |
| **B — Conditional authorization for a future release** | Record prerequisites and scope, but require a second explicit go/no-go after those conditions are evidenced. | Allows scheduling while preserving a final release gate. | Conditions cannot be treated as passed; no execution until the recorded go/no-go is complete. |
| **C — Defer / do not authorize** | Wait for implementation and non-production evidence. | Avoids premature production changes. | No production schema or feature release can proceed. |

### Current prerequisites and effects

No canonical migration has been implemented, reviewed, or run in non-production; no acceptance results, backup/restore evidence, operational monitoring plan, or independent security sign-off are provided in this task. The production Supabase project must not be accessed or modified under the Task 27 restrictions.

### Recommendation (not an approval)

**Recommend Option C.** Consider a production decision only after A-13/A-14 closure, controlled implementation, non-production acceptance, independent security review, tested backup/restore and rollback, release monitoring, and explicit approval by the designated production authority.

### Owner response

- Selected option: **C — defer.**
- Owner response: Wait for implementation completion and successful non-production validation, full application regression tests, independent security/RLS review, verified backup/recovery, documented migration history/release evidence, and separate explicit production go/no-go approval.
- Release version/hashes, acceptance evidence, recovery/monitoring references and operator: Not supplied; production prerequisites are incomplete.
- Approver name and role/date/version: Not separately supplied with the response; retain as an audit-record gap.
- Status: **Deferred; production access, migration execution and deployment are not authorized.**

## 6. Consistency review of A-01 through A-12

The table records the owner-supplied selected directions without changing them. “Selected” is not a claim that implementation is technically complete.

| Decision | Preserved owner selection | Consistency finding / remaining dependency |
|---|---|---|
| A-01 Auth/profile | Auth database trigger; Auth UUID profile ID; default `tourist`; no user metadata role; idempotent; restricted definer/search path; trigger failure prevents orphan account | Consistent with A-02. Trigger function ownership, grants, email/OAuth behavior, retry/recovery and test design require review. No implementation authorized. |
| A-02 Roles | `tourist`, `establishment`, `administrator`, `super_admin`; privileged assignment trusted; initial super-admin separately controlled | Consistent with A-01. Existing `owner` values in local artifacts need explicit mapping; current client role/profile writes must be adapted. |
| A-03 Establishments | AP-24 one owner to many establishments; no unique `owner_id`; preserve IDs and ownership | Consistent with owner model; current `.maybeSingle()` query is incompatible and needs separate app change. |
| A-04 Tourist profile | Nullable until explicitly supplied/confirmed; no invented budget/origin/mode/group/preference defaults; partial updates preserve unspecified values | Consistent with safe CARS handling. Existing model/service requires changes; age-group definitions remain unresolved. |
| A-05 Destinations | Publication separate from verification; nullable coordinate pair; rating/pricing display-only absent provenance | Consistent with CARS safe-unavailable behavior. State vocabulary, source metadata contract, rating scale and pricing units still require technical/source decisions. |
| A-06 Pre-booked commitments | Tourist-entered external arrangement details, associated with itinerary; edits only SAMAL NAV’s local copy; MO-GA preserves commitments as fixed constraints | Consistent with A-10 only when stored in Hive itinerary data. Not an actual SAMAL NAV reservation or confirmation. Current repository lacks the commitment model/MO-GA adapter. |
| A-07 Payments | No payment processing or persistence in current scope; no payments table | Consistent as scope decision. Existing `payments` queries and payment dashboard behavior conflict and require separately authorized removal/redesign. |
| A-08 Reviews | One unified `reviews` relation; exactly one destination or establishment subject; moderation; no automatic CARS aggregate | Internally consistent. Existing establishment review query can be retained only with approved subject/publication fields and privacy-safe embeds. Aggregation policy remains separate. |
| A-09 Audit/settings | Trusted immutable audit events; settings through restricted trusted administrative operations | Consistent with least privilege. Current client audit inserts and generic settings upserts conflict; event taxonomy, retention and settings schema remain to be specified. |
| A-10 CARS/itinerary persistence | Exclude CARS evidence storage and server itinerary persistence from core; itinerary drafts remain Hive-local | Consistent with A-06 when commitment details are part of the local draft. CARS remains unavailable until sources/policies are approved. |
| A-11 Retention | Soft retire destinations/establishments; preserve required history; reviewed anonymization; no blanket cascades | Consistent with reservation history preservation. Exact periods, account closure, backup retention and lawful deletion process remain unresolved. |
| A-12 Migration/seed | New unique chain; preserve old migrations; schema/seed separate; local-first validation; environment-specific approvals | Consistent with Task 20/25 findings. No new chain exists yet; this selection is not an execution authorization. |

### Cross-decision issue requiring explicit handling

Current Dart code still depends on server `reservations` and `payments` relations. The owner’s selections mean these paths cannot be carried unchanged into the proposed core schema: pre-booked itinerary details are local and payments are excluded. Task 27 records this compatibility work as outstanding; it does not remove the code or add a substitute table. A-06 commitments must remain visible and fixed during MO-GA operations, but they must never be represented as confirmed external reservations by SAMAL NAV.

## 7. Consolidated decision register

This register records the owner selections for A-01–A-16. A-13/A-14 are approved subject to technical conditions; A-15/A-16 are deferred. The supplied response did not include a separate approver name/role/date/effective policy version, so those audit fields remain unfilled rather than inferred.

| ID | Selected option / owner response | Rationale recorded | Dependencies | Required evidence | Approval status | Outstanding conditions |
|---|---|---|---|---|---|---|
| A-01 | B — Auth database trigger; tourist default | Atomic profile creation; no user role metadata | A-02, A-11 | Reviewed function/trigger design; email/OAuth and failure/retry tests | Owner selected; technical review pending | Trigger security, operational recovery, deletion policy |
| A-02 | A — preserve existing four app roles | Flutter compatibility and trusted role control | A-01, A-14 | Canonical role check/mapping; super-admin bootstrap procedure | Owner selected; technical review pending | Legacy owner mapping; server-side authorization |
| A-03 | A — one owner to many establishments | AP-24 | A-13, application adaptation | Query/UI behavior and multi-establishment tests | Owner selected; app compatibility pending | Remove `.maybeSingle()` assumption |
| A-04 | A — nullable fields and explicit confirmation | Avoid invented defaults and false confirmation | A-13, A-14 | Field-level profile contract and tests | Owner selected; contract work pending | Budget basis/currency; age/group definitions; model/service changes |
| A-05 | A — separate publication and verification | Preserve independent state semantics | A-13, source provenance | State contract and destination evidence contract | Owner selected; technical/source review pending | State vocabulary; rating/pricing data sources and metadata |
| A-06 | Corrected — local tourist-entered pre-booked itinerary data, fixed for MO-GA | Tourist’s record does not alter or verify external arrangements | A-10, local planner/MO-GA feature | Hive compatibility and commitment-preservation tests | Owner selected; feature not implemented | Add model/UI/constraint behavior; no database booking table |
| A-07 | B — no payment persistence | Payments outside current app scope | A-13, app adaptation | Payment functionality inventory and removal/redesign acceptance | Owner selected; app compatibility pending | Remove/rework current payments queries/UI |
| A-08 | A — unified reviews with exactly one subject and moderation | One coherent review contract; no automatic CARS aggregate | A-13, A-14 | Review moderation/privacy contract and tests | Owner selected; details pending | Moderation states, duplicate/edit rule, aggregation and exposure |
| A-09 | A — trusted immutable audit and restricted settings | Prevent client-forged audit and arbitrary setting changes | A-14, backend operations | Threat review, event taxonomy, settings allowlist/tests | Owner selected; security review pending | Retention, PII minimization, trusted writer design |
| A-10 | A — exclude CARS/server itineraries from core; Hive drafts | Keep core scope and CARS availability independent | A-06, A-13 | Local storage boundary and CARS safe-unavailable regressions | Owner selected | Ensure A-06 remains local; no server sync |
| A-11 | A — soft retirement and controlled retention | Preserve history and avoid blanket cascades | A-13, privacy review | Retention schedule and account closure plan | Owner selected; policy details pending | Periods, anonymization, backups, exceptional deletion |
| A-12 | A — new uniquely versioned migrations and separate seeds | Reproducibility and safer environment separation | A-13, A-14, A-15 | Approved manifest, runner, hashes, local clean install/recovery | Owner selected; implementation not authorized | Detailed migration/seed plan and separate execution approvals |
| A-13 | A — approve ten-relation candidate manifest subject to field-level amendments and service compatibility review | Scope can be frozen while preserving explicit contract corrections | A-01–A-12; application service map; A-14 | Exact field-level manifest and service compatibility review | **Owner-approved with conditions** | Final exact fields/types/nullability/keys/indexes/delete actions still need technical closure; no migration authorization |
| A-14 | A — accept Task 26 least-privilege matrix as baseline; require independent review/testing | Security baseline accepted; exact policy/grant implementation is still separately validated | A-13; trusted role/operation design | Exact RLS/grants, independent review, synthetic identity tests | **Owner-approved with conditions** | No final policy SQL or implementation authorization; deny unrestricted sensitive client access |
| A-15 | C — defer non-production initialization until all listed prerequisites and a separate authorization are complete | Avoids remote changes before local and security validation | A-12; A-13/A-14 closure; implementation/tests; recovery plan | Local clean install, compatibility/security results, confirmed project, hashes, backup/recovery | **Deferred; not authorized** | Complete prerequisites, then request a separate explicit execution approval |
| A-16 | C — defer production until implementation, successful non-production validation and separate go/no-go | Keeps production as an independent release gate | A-15 success; application acceptance; security/operations review | Full regression, security/RLS, restore/rollback, migration history and release evidence | **Deferred; not authorized** | Separate production go/no-go must still be explicitly recorded |

## 8. Readiness assessment

| Readiness area | Determination | Evidence and reason |
|---|---|---|
| Methodology readiness | **Partial / not ready for CARS scoring** | Six criteria and historical weights are retained, but weights remain unverified against original research and scoring/data-source policies are unresolved. Existing CARS safe-unavailable behavior and 0–100 runtime contract must remain. |
| Architecture readiness | **Partial; owner direction established** | Owner selected A-01–A-12 and approved the A-13 manifest scope with amendments and A-14 security baseline with independent review. Field-level contract, exact access policies, lifecycle and retention details remain open. |
| Application compatibility readiness | **No** | Current code assumes one establishment per owner; has non-null tourist profile expectations; performs booking-like reservation/payment server queries and writes; has direct audit/settings operations; and lacks the local pre-booked constraint model. Required changes have not been made or verified. |
| Database migration readiness | **No** | A-13/A-14 direction is approved with conditions, but exact field-level manifest, independent security implementation review, new migration chain and local clean-install/security tests remain incomplete. |
| Non-production deployment readiness | **No — deferred** | A-15 selected C. No migration hashes, completed preflight, tested backup/recovery or separate execution authorization. Project evidence remains owner-supplied and not independently verified. |
| Production deployment readiness | **No — deferred** | A-16 selected C. No successful non-production acceptance, full security/operations evidence, rollback/monitoring plan or production go/no-go. |

## 9. Owner response summary and next action

Owner selections for A-13 through A-16 are recorded above. The remaining follow-up is evidence and technical closure, not another option selection: finish A-13 field-level amendments and service compatibility review; conduct A-14 independent security review/tests; complete A-15 prerequisites before requesting a separate non-production authorization; and retain A-16 as a distinct production go/no-go after successful non-production acceptance.

**A-13 selected:** A — approved subject to amendments and compatibility review.
**A-14 selected:** A — baseline accepted subject to independent security review/testing.
**A-15 selected:** C — deferred; no initialization authorized.
**A-16 selected:** C — deferred; no production deployment authorized.
**Approver name/role:** Not separately captured in supplied response. **Date/version:** Not supplied.

## 10. Closeout

- **Created:** `docs/TASK_27_SAMALNAV_REMAINING_ARCHITECTURE_DECISIONS_AND_FINAL_OWNER_DECISION_CLOSURE.md`.
- **Preserved:** A-01–A-12 selections and all Tasks 06–26; no previous records were rewritten.
- **A-13–A-16:** Owner selected A/A/C/C respectively; A-13/A-14 have technical conditions; A-15/A-16 are deferred.
- **Pre-booked commitments:** Local Hive itinerary information, not database bookings or SAMAL NAV confirmations; MO-GA preservation is required but not yet implemented.
- **Payments:** Excluded from proposed core database scope.
- **Code, tests, configuration, migrations, SQL, database objects:** Not modified or executed.
- **Supabase:** Not accessed.
- **Implementation and deployment authorization:** Not granted.
