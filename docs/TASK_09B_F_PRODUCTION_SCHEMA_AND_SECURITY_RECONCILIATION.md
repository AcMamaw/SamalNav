# Task 09B-F — Production Schema and Security Reconciliation

**Status:** Read-only reconciliation report. It does not authorize code, migration, RLS, grant, or production changes.

**Policy authority:** The 26 approved policies AP-01–AP-26 in Task 09B-D and the technical contract in Task 09B-E remain authoritative. Any recommendation below is not an additional owner-approved policy.

## A. Executive Summary

The owner-supplied production inventory confirms 26 public tables and reports RLS enabled and not forced for each inspected public table. The proposed `itinerary_drafts`, `itinerary_reservation_events`, and `tourist_activity_event_references` tables were not present in that inventory. The deployed database is not empty: the remote migration-history query returned no migration rows, but that is not evidence that production has no schema or data and does not justify replaying legacy migrations.

Identity is anchored through `profiles.id → auth.users.id`; deployed `itineraries.tourist_id` and `establishments.owner_id` reference `profiles.id`. This supports deriving ownership from `auth.uid()` through the profile identity, subject to deployed constraints and RLS verification. The production `establishments.owner_id UNIQUE` constraint conflicts with the approved one-owner-to-many-establishments requirement and needs a separately reviewed, data-preserving migration.

The existing `public.reservations` table is an establishment-side booking workflow, including status values pending/confirmed/cancelled/completed and establishment/administrator access. It must remain separate from tourist-entered information about external arrangements. Reusing it would conflate separate ownership, lifecycle, privacy, and user expectations.

The supplied RLS summary identifies material exposure risks: public SELECT on `profiles`; overlapping permissive policies on itineraries and stops; broad authenticated event SELECT; and authenticated inserts into `audit_logs`. I-6 also reported table-level SELECT grants on `profiles` for `anon` and `authenticated`. Together, these confirmed grants and permissive policies create a **priority potential exposure** of profile rows and all columns readable through effective table/column privileges, including email and phone. The grants and policy findings are confirmed individually; final effective access by role and column still depends on exact policy role targets, column grants/revokes, schema/API exposure, and views. PostgreSQL combines permissive policies with OR semantics, so narrower policies do not restrict access granted by a broad policy.

The functions `public.current_user_role()` and `public.admin_toggle_owner_verification(uuid, boolean)` are SECURITY DEFINER, owned by postgres, with `search_path=public`. The latter updates all establishments for an owner and creates a default establishment if none exists, which conflicts with independent establishment verification and multi-establishment ownership. Its supplied authorization test also has a SQL NULL edge case: `caller_role NOT IN ('administrator', 'super_admin')` evaluates to NULL when `caller_role` is NULL. A PL/pgSQL `IF` enters its branch only for TRUE, so if that expression is the only rejection guard, a missing profile or unresolved role may fail to enter the exception branch. Treat this as a separate priority security review issue; neither function is changed here.

**Implementation readiness: NOT READY.** Before implementation, obtain complete deployed catalog/policy/grant evidence; resolve the remaining privacy, retention, activity-reference, conflict-UX and feasibility decisions; and prepare an independently reviewed additive schema/RLS design. No SQL was executed and no database or application code was modified.

## B. Evidence and Inspection Scope

### Evidence labels

- **CONFIRMED — owner-supplied:** Production metadata explicitly provided in this task or the preceding approved baseline. It has not been independently re-queried here.
- **CONFIRMED — repository:** Local source or migration content was inspected. This describes the repository only, not production.
- **INFERRED:** A technical implication of supplied facts; not itself a deployed metadata fact.
- **NOT VERIFIED:** The necessary production detail was not supplied or catalog visibility/coverage is incomplete.
- **REQUIRES DECISION:** A policy or user-visible behavior has not been approved.

### Scope and limits

The report reconciles the supplied production facts with `docs/TASK_09B_D_APPROVED_RESERVATION_ACTIVITY_POLICY_BASELINE.md`, `docs/TASK_09B_E_RESERVATION_EVENT_TECHNICAL_CONTRACT_AND_RLS_SPECIFICATION.md`, relevant source/models/services/tests, and checked-in SQL migrations. Migration files were read as repository artifacts only; none were executed. No Supabase connection, credential, private record, or live user row was accessed.

The production inventory and policy summaries are owner-supplied. Some findings are stated at summary level rather than with complete policy expressions, column lists, or grants. Where exact definitions are absent, the report says so instead of reconstructing them. Catalog queries in Section P of Task 09B-E remain unexecuted.

## C. Deployed Schema Inventory

The inspected `public` schema contains the following 26 tables according to owner-supplied inventory. All 26 were reported with **RLS enabled = true** and **RLS forced = false**. The table names establish inventory presence only; unspecified columns/constraints/policies below remain unverified.

| Public table | Supplied production facts relevant here | RLS status supplied | Remaining verification |
|---|---|---|---|
| `activities` | Exists. I-2 column metadata was supplied; `establishment_id` is the relationship field used by the supplied owner-policy summary. Activity policies reportedly authorize owner operations through that field. | Enabled; not forced | Reconcile the supplied columns with exact FK targets, policy expressions/roles, constraints, public fields, indexes and grants. |
| `audit_logs` | Exists. Super Administrators can read under supplied policies; authenticated users can insert. | Enabled; not forced | Exact expressions, whether actor identity is server-derived, update/delete grants, trigger/function behavior, audit coverage and retention. |
| `categories` | Exists; no additional facts in this task. | Enabled; not forced | Complete columns, policies, grants, category/activity relationship. |
| `destination_availability` | Exists; no additional facts in this task. | Enabled; not forced | Columns, policy definitions, provenance/freshness and grants. |
| `destination_gallery` | Exists; no additional facts in this task. | Enabled; not forced | Columns, storage relationship and policies. |
| `destinations` | Exists; supplied earlier inventory states optional establishment relationship and coordinates; an earlier supplied policy summary included permissive public read. | Enabled; not forced | Current exact columns/FKs/policies/indexes/grants. |
| `establishments` | `owner_id → profiles.id ON DELETE CASCADE`; `owner_id` is UNIQUE; coordinates nullable. Public verified-read and authenticated owner/administrator policies were summarized. | Enabled; not forced | Exact policy predicates, grants, verification columns/function effects, dependent views/triggers and all FK actions. |
| `events` | Exists and I-2 column metadata was supplied. Authenticated SELECT policy reportedly uses `true`; administrator ALL policy also exists. | Enabled; not forced | Compare supplied columns with publisher/organizer, schedule, lifecycle and source requirements; verify exact expressions, public/anonymous access, indexes and grants. |
| `favorites` | Exists; no additional facts in this task. | Enabled; not forced | Columns/target FKs, ownership policies, unique constraints and grants. |
| `itineraries` | `tourist_id → profiles.id ON DELETE CASCADE`. Overlapping permissive ALL policies were reported. | Enabled; not forced | Exact policy expressions/roles, complete columns/constraints/grants, status semantics, indexes and write path. |
| `itinerary_stops` | `itinerary_id → itineraries`; `destination_id → destinations`. Overlapping permissive ALL policies include an administrator/super-administrator path. | Enabled; not forced | Exact FK actions and policy predicates, owner path, full columns/constraints/grants. |
| `location_verifications` | Exists; no additional facts in this task. | Enabled; not forced | Columns, who may verify, role helper use, policies/grants and triggers. |
| `moga_results` | Exists; no additional facts in this task. | Enabled; not forced | Columns, itinerary FK, policy/retention and whether currently used. |
| `notifications` | Exists; I-2 column metadata was supplied. Recipient ownership is reported in policy summary. | Enabled; not forced | Compare supplied recipient/read/delivery columns with the exact recipient predicate, permitted write path, grants, dedupe and expiry behavior. |
| `payments` | Exists; no additional facts in this task. | Enabled; not forced | Columns and policies; explicitly out of scope for this feature. |
| `profiles` | `id → auth.users(id) ON DELETE CASCADE`; public SELECT policies using `true` were reported. | Enabled; not forced | Exact selected columns and policy roles, grants, role update protections, views/API exposure. |
| `reservations` | I-2 supplied columns: `id`, `itinerary_id`, `tourist_id`, `establishment_id`, `destination_id`, `eta`, `pax_count`, `reservation_status`, `service_name`, `created_at`. Existing establishment-side table; see Section E. | Enabled; not forced | Column names are supplied; confirm exact types/nullability/defaults plus full policies/grants/constraints/indexes. Do not infer absent permissions. |
| `reviews` | Exists; no additional facts in this task. | Enabled; not forced | Target FKs, internal/public-source semantics and policies. |
| `reviews_legacy` | Exists; no additional facts in this task. | Enabled; not forced | Columns, relationships, grants and whether application uses it. |
| `role_descriptions` | Exists; no additional facts in this task. | Enabled; not forced | Relation to role authorization and read/write policies. |
| `roles` | Exists; no additional facts in this task. | Enabled; not forced | Canonical role values, constraints and how authorization helper maps them. |
| `self_healing_logs` | Exists; presence alone does not prove a working self-healing module. | Enabled; not forced | Columns, policies, itinerary relationship and application usage. |
| `system_settings` | Exists; no additional facts in this task. | Enabled; not forced | Sensitive settings, policies, grants and functions. |
| `tourist_details` | Exists; no additional facts in this task. | Enabled; not forced | Exact policies/grants here are not repeated; no reservation/draft relation was supplied. |
| `tourist_profiles` | Exists; no additional facts in this task. | Enabled; not forced | Its overlap with tourist_details, policies/grants, and application usage remain separate concerns. |
| `weather_cache` | Exists; no additional facts in this task. | Enabled; not forced | Provider/freshness/forecast validity metadata and policies. |

The proposed tables `itinerary_drafts`, `itinerary_reservation_events`, and `tourist_activity_event_references` were absent from the inspected inventory (**CONFIRMED — owner-supplied inventory**). Do not infer that similarly named objects are absent in other schemas or that all catalog access was unrestricted.

### I-2 column evidence reconciliation

The owner-supplied I-2 column inventory for `activities`, `establishments`, `events`, `itineraries`, `itinerary_stops`, `profiles`, `reservations`, `notifications`, and `audit_logs` is treated as **already supplied evidence**; this report does not request that column inventory again. The earlier wording that complete columns were “not included” or “not supplied” was too strong and is corrected here. I-2 remains the source for exact per-column type, nullability, default, identity/generated definition and ordinal position. This summary calls out the fields directly established in the evidence available for this report:

| Table | Supplied I-2 / related column facts carried into this report | Contract reconciliation still needed |
|---|---|---|
| `activities` | I-2 column inventory supplied; owner policy uses `establishment_id`. | Compare supplied destination/establishment/category, schedule, duration, price and source fields (where present) against the listing contract; verify FKs, policy predicates and whether a field denotes verification/current availability. Do not infer a field from a local migration. |
| `establishments` | I-2 includes establishment identity/name/address/category and location/verification fields; `owner_id` FK/UNIQUE and nullable coordinates are separately confirmed. | Compare exact I-2 types/nullability/defaults with directory snapshot and independent per-establishment verification requirements. |
| `events` | I-2 column inventory supplied; authenticated read-all and administrator policies summarized. | Map actual supplied title/description/publisher/date/category or other fields against the contract; determine whether schedule, lifecycle, evidence, freshness and participation requirements are representable. |
| `itineraries` | I-2 fields include owner, itinerary category/type, current stop index, total cost, distance, travel time, fitness score, generated timestamp and status. Owner FK is confirmed. | Existing fields do not establish draft identity/version, atomic promotion, reservation children, or all required lifecycle semantics. |
| `itinerary_stops` | I-2 fields include itinerary/destination IDs, day number, sequence, arrival/departure, estimated travel minutes, contribution score and completion status. Both FKs are confirmed. | Existing fields do not establish reservation-event constraints or all route/provenance requirements; verify exact FK actions and RLS. |
| `profiles` | I-2 includes `id`, email and phone; `id` references `auth.users(id)`. | Treat these contact fields as potentially exposed under the supplied SELECT grants/policies until exact effective access is reviewed. |
| `reservations` | Exact supplied column names are listed in the inventory table and Section E. | This established table remains a separate booking workflow regardless of column overlap with the new event model. |
| `notifications` | I-2 column inventory supplied; recipient-ownership policy summary supplied. | Determine whether supplied columns cover recipient, read state, source version, deduplication or delivery. Do not infer support from table existence. |
| `audit_logs` | I-2 column inventory supplied; super-admin SELECT and authenticated INSERT policy summary supplied. | Determine whether actor/role/target metadata can be forged and whether access events are server-authored/append-only; column presence alone does not prove trustworthy auditing. |

The original I-2 column listing should remain with the sanitized evidence bundle. This report treats it as supplied evidence and does not replace it with guessed columns or local migration definitions. Remaining verification requests concern constraints, policies, grants, functions/triggers and whether confirmed columns safely support the proposed contracts.

### I-4 index inspection results (owner-supplied)

The following results are from the supplied I-4 `pg_indexes` output for the nine inspected `public` tables. They are **CONFIRMED — owner-supplied query results**, not independently re-queried in this task.

| Table | Returned indexes |
|---|---|
| `activities` | Primary key on `id`; indexes on `destination_id` and `establishment_id`. |
| `audit_logs` | Primary key on `id` only. |
| `establishments` | Primary key on `id`; unique index `establishments_owner_id_key` on `owner_id`. |
| `events` | Primary key on `id` only. |
| `itineraries` | Primary key on `id` only. |
| `itinerary_stops` | Primary key on `id` only. |
| `notifications` | Primary key on `id` only. |
| `profiles` | Primary key on `id` only. |
| `reservations` | Primary key on `id` only. |

No partial or expression indexes appeared in the returned results. The unique owner index reinforces the AP-24 conflict: the current deployed schema restricts one establishment row per owner. Removing that constraint remains a separate migration and compatibility effort, not part of the reservation-event migration.

This result is limited to the nine named tables and the catalog visibility of the query execution role. It does not establish that indexes are absent from other schemas/tables or outside that visibility. The “only” descriptions above refer only to indexes returned for the specified table in the supplied output. Do not recommend creating indexes solely from this inventory; review actual query patterns, row counts/selectivity, and execution plans first. The proposed reservation-event table is not deployed, so its future indexes and constraints remain design work and require workload/security review.

## D. Identity and Ownership Analysis

### Confirmed relationship chain

```text
auth.users.id
   ↑ profiles.id (FK, ON DELETE CASCADE)
   ├── itineraries.tourist_id (FK to profiles.id, ON DELETE CASCADE)
   └── establishments.owner_id (FK to profiles.id, ON DELETE CASCADE, UNIQUE)
```

These relationships are **CONFIRMED — owner-supplied**. `auth.uid()` represents the authenticated auth user UUID. Since `profiles.id` references `auth.users.id`, the IDs align by FK identity (**INFERRED from confirmed relationship**). A service can therefore derive an owner from the authenticated session and relate it to profile ownership; it should not trust a client-submitted `tourist_user_id` as authority.

### Draft ownership implication

No deployed draft table exists in the supplied inventory. A proposed draft owner should be a non-null FK to `profiles.id`; RLS and write operations should compare it to `auth.uid()`. A foreign key alone proves that a profile exists, not that the caller owns it. The draft row and event child need parent-owner enforcement in both database constraints and RLS/transaction logic.

### Reservation-event ownership implication

The proposed event must be tied to exactly one draft or saved itinerary, and both must belong to the session user. A simple FK to a parent ID does not prove that a redundant child owner ID matches that parent. Recommended mechanism: unique parent key `(id, tourist_user_id)`, composite child FK `(parent_id, tourist_user_id)`, an exactly-one-parent check for the shared event table, and RLS predicates that also require `tourist_user_id = auth.uid()`. Alternatively, omit child owner duplication and enforce parent ownership through secure `EXISTS` policies/RPC; that needs careful performance and authorization testing. Do not trust UUID secrecy.

### Multiple-establishment ownership conflict

`establishments.owner_id` is both an FK to `profiles.id` and UNIQUE. That means one profile cannot own multiple establishment rows under the current constraint. This directly conflicts with approved AP-24. Removing UNIQUE alone is insufficient: every affected layer must be reviewed for cardinality and independent-establishment semantics before a separate migration. In the current repository, `EstablishmentService.getMyEstablishment()` filters by `owner_id` and calls `.maybeSingle()`, which assumes at most one row. Also review owner-specific service queries, both establishment dashboard entry points/widgets, verification functions (including the owner-wide function in Section G), RLS ownership predicates, establishment creation/management workflows, and any model/UI state that stores only one establishment. Queries may need a list/current-establishment selection contract; verification must apply to a specific establishment, not implicitly every establishment for an owner. Preserve current rows, owner IDs, and per-establishment verification state. This work remains separate from the reservation-event migration.

## E. Existing Reservation Table Assessment

### Supplied production contract

`public.reservations` contains `id`, `itinerary_id`, `tourist_id`, `establishment_id`, `destination_id`, `eta`, `pax_count`, `reservation_status`, `service_name`, and `created_at`. The status check permits `pending`, `confirmed`, `cancelled`, and `completed`. Existing policies allow establishment owners and administrators to access certain records. RLS is enabled and not forced, per inventory.

The exact policy predicates, role targets, grants, unique/check constraints beyond the status values, and deletion actions were not fully supplied; treat them as **NOT VERIFIED** until catalog output is reviewed.

### Assessment

This table belongs to the current establishment-side reservation workflow. Its fields/statuses and owner/admin access do not represent a private tourist log of an independently arranged external activity, dining appointment, accommodation stay, or other commitment. The product language “confirmed/cancelled” could falsely imply SAMAL NAV controls the external arrangement.

**Recommendation: keep `public.reservations` separate and unchanged.** Do not add tourist external-arrangement data to it, use it as a draft child, or reinterpret its status. Build the approved event contract on a separately reviewed additive structure with tourist ownership and the four-state schedule feasibility contract. This follows AP-01, AP-03, AP-15, AP-21, AP-22 and AP-26.

## F. RLS and Privilege Assessment

### Supplied policy findings

All public tables were reported RLS-enabled and not forced. The following policy summaries are **CONFIRMED — owner-supplied summaries**, but full expressions/role arrays were not included here:

| Table | Supplied policies/behavior | Combined-access concern |
|---|---|---|
| `profiles` | Public SELECT policy/policies use `true`. | Any permissive SELECT policy with `true` can expose every row/column allowed by grants; an owner-only policy does not narrow it because permissive policies OR together. Minimize exposed profile fields and separately review grants/views. |
| `itineraries` | Overlapping permissive `ALL` policies. | For each command, allowed rows can be the union of every applicable permissive policy. An admin/owner path may unintentionally broaden access or mutation. Exact union cannot be calculated without expressions. |
| `itinerary_stops` | Overlapping permissive `ALL` policies; one includes administrator/super-administrator access. | Parent-owner policy plus admin path is broader than owner-only. Any `WITH CHECK` must also prevent moving a stop to another tourist's itinerary. |
| `activities` | Owner policies rely on `establishment_id`. | Validate the referenced establishment is owned by the session and is eligible/verified; inspect whether other broad policies bypass this predicate. |
| `establishments` | Public verified-read plus authenticated owner/administrator policies. | Verify exactly which columns/rows are public, whether owner/admin write predicates are role-safe, and whether policies expose private owner/profile data. |
| `events` | Authenticated SELECT policy uses `true`; administrator `ALL` policy. | Broad authenticated read may include draft/unpublished/private rows unless publication state is constrained by all effective policies. Admin ALL does not restrict existing permissive policies. |
| `reservations` | Owners and administrators can access certain records. | Inconsistent with the new feature's tourist-only private data baseline; keep this existing workflow separate. Do not carry those policies to the new table. |
| `notifications` | Recipient ownership. | Verify owner predicate is enforced for both read and update, and clients cannot forge recipient or create arbitrary notices. |
| `audit_logs` | Super Administrators can read; authenticated users can insert. | Client inserts may forge actor/action/metadata unless server-derived and constrained. Sensitive access auditing should be server-authored and append-only. |

### OR semantics and policy implications

For permissive RLS policies applying to the same role/command, PostgreSQL combines the predicates with **OR**. Thus `owner_id = auth.uid()` OR `true` is `true`; adding another owner-scoped policy does not restore confidentiality. Restrictive policies combine differently, but none are confirmed for these tables. Table privileges are a separate gate: a policy does not grant a SQL privilege, and a grant does not bypass RLS (except owner/bypass roles and service-role behavior). RLS not forced also means table owners may bypass it in appropriate contexts; the application must not use privileged client credentials.

### Proposed-table intent

For new drafts/events, use no public read policy and no generic admin `ALL` policy. Authenticated tourist operations must be constrained to `auth.uid()` and the same-owner parent. Publisher listing policies should be separate from private draft/event policies. Tourist Office/Super Admin support access to private reservation information is not a default; exceptional access needs explicit purpose, narrow operation, independent audit, and owner approval. Grants must be least privilege and reviewed with all permissive policies together.

### Grants gap

I-6 specifically reported table-level SELECT grants on `profiles` to both `anon` and `authenticated`; those grants are **CONFIRMED — owner-supplied** and are not part of the remaining evidence request. Combined with the supplied permissive `true` SELECT policy, they establish a priority potential exposure of profile-readable columns including email and phone. The exact effective role-by-column exposure still requires the policy role targets, column-level ACLs/revokes, schema/API privileges, views and any other applicable policies. For other tables, complete per-role table/column/schema/sequence/function privileges and relevant role memberships remain incomplete. Effective access across the database is therefore not fully determined. Obtain the remaining grant and role evidence before implementation; do not assume RLS alone is sufficient.

## G. Function and Trigger Assessment

### `public.current_user_role()`

Supplied facts: SECURITY DEFINER, postgres owner, `search_path=public`; function uses `auth.uid()` to retrieve `profiles.role` and defaults to `tourist`. This is **CONFIRMED — owner-supplied**.

Implications: role helper influences policy decisions and must be reviewed as a security boundary. Verify execute grants, exact body, null/error behavior, profile role mutation protections, and whether the function can be shadowed or resolve unqualified objects unexpectedly. A `public` search path can be risky for SECURITY DEFINER code if object resolution is not fully qualified and safe; do not change it in this task. The helper's default-to-tourist behavior is preferable to privilege escalation but still needs role consistency tests.

### `public.admin_toggle_owner_verification(uuid, boolean)`

Supplied facts: SECURITY DEFINER, postgres owner, `search_path=public`; updates verification across all establishments for one owner and creates a default establishment if none exists. **CONFIRMED — owner-supplied.**

Risk: a single owner-level toggle conflicts with independent establishment identity/verification and AP-24's one-to-many ownership. Creating a synthetic/default establishment can create records not explicitly entered by a publisher and may conceal missing catalog data. Review caller authorization, exact target behavior, audit, function execute grants, and compatibility with existing rows. Keep separate from this feature and do not invoke it for reservation selection.

#### Authorization NULL edge case in `admin_toggle_owner_verification`

The supplied function implementation checks authorization with `caller_role NOT IN ('administrator', 'super_admin')`. In SQL three-valued logic, when `caller_role` is NULL, this expression evaluates to NULL (unknown), not TRUE. A PL/pgSQL `IF` whose condition is NULL does not enter the branch. Therefore, if this is the only rejection guard, a missing `profiles` row or unresolved role can skip the exception branch and continue to the privileged update/create path. This is a **priority security risk requiring separate review**, not a proven exploit without inspecting the full deployed body/control flow and execute grants. A future approved correction should explicitly reject NULL/unresolved roles as well as non-admin roles. This report does not modify the function.

### Triggers and other functions

The owner's `information_schema.triggers` query returned no rows. This means that query returned no visible rows for its scope; it does **not** prove no triggers exist anywhere or that no non-public/partition/internal triggers exist. The exact query scope, permissions, and catalog output must be retained. The migration files contain trigger declarations, but that is repository-only evidence. Full deployed function inventory/definitions, execute grants, triggers, timing/events and attached functions were not provided (**NOT VERIFIED**, except the two functions above).

## H. Types, Extensions, Views, and Sequences

| Area | Supplied result | Correct interpretation |
|---|---|---|
| Public sequences | No rows returned. | No visible public sequences in that query. UUID defaults may use functions and do not require sequences. Do not generalize to other schemas. |
| Public enums/domains | No rows returned. | No visible public enum/domain rows in the queried public schema. Text/check constraints may still encode values. |
| Public views/materialized views | No rows returned. | No visible public views/materialized views in that query. Do not generalize beyond schema/permissions/query. |
| Installed extensions | `pg_stat_statements 1.11`, `pgcrypto 1.3`, `plpgsql 1.0`, `supabase_vault 0.3.1`, `uuid-ossp 1.1`. | Owner-supplied extension inventory. Presence does not mean the application uses each extension or that installing another extension is approved. |
| RLS force | All inspected public tables reportedly `relforcerowsecurity=false`. | Table owners/privileged contexts may bypass RLS; app clients must remain unprivileged. Verify ownership and service pathways. |

No extensions, types, views, sequences, or triggers are added or changed by this report.

## I. Migration History Assessment

The table `supabase_migrations.schema_migrations` has columns `version text NOT NULL`, `statements text[] NULL`, and `name text NULL`. The migration query returned zero rows. These are **CONFIRMED — owner-supplied**.

An empty migration-history table does not imply a database without schema/data and does not establish that migrations were never applied manually, through another process, or before history tracking. It is not authorization to replay or register the seven legacy migration files. The repository has duplicate `002` prefixes and overlapping schema definitions; the legacy directory is not a safe production baseline.

**Safe baseline direction:** preserve the supplied inventory and a read-only schema snapshot as evidence; determine which deployed objects exist and their ownership; reconcile every proposed future migration against that state. Establishing a new migration tracking baseline is a separate change-management decision and must not mark legacy scripts as applied without object-by-object evidence. No `migration repair`, migration insert, `db push`, reset, or migration execution is recommended here.

## J. Task 09B-E Contract Reconciliation

| 09B-E contract requirement | Production evidence | Reconciliation / readiness |
|---|---|---|
| Draft-first persistence, all three planning methods | Proposed draft table absent from inspected inventory; current repo draft is in-memory. | Requires additive design and server persistence. Keep same draft ID through all methods; no fourth method. |
| Exactly one draft or itinerary parent per event | No proposed event table; current itinerary FKs are known only at a high level. | Use XOR parent invariant plus owner relationship. Choose composite FKs/secure operation only after full type and FK metadata. |
| Composite owner FKs or enforceable equivalent | `profiles` identity chain and itinerary tourist FK supplied. | Technically feasible in principle; confirm exact FK types, unique keys and RLS. Parent FK alone does not establish caller ownership. |
| Atomic promotion and same-owner validation | No draft table/promotion function supplied. | Requires a reviewed transaction/RPC or equivalent. Must create itinerary/stops and associate children atomically, validate session owner at server boundary, preserve event UUIDs and idempotent retries. |
| Off-directory establishment snapshot | `establishments` exists; coordinates nullable; no event snapshot schema supplied. | Add snapshot/provenance fields. No fabricated FK or coordinates. |
| Four event types, timing provenance, intervals, timezone | No new event contract present in deployed inventory. | Implement only after exact versioned serialization rules; start-only valid but incomplete; `[start,end)` and Asia/Manila remain requirements. |
| Accommodation continuity and overnight location | No supplied stay contract in current itinerary schema. | Model separate continuous date interval; optional times; no default. |
| Planned/actual extension history | `self_healing_logs` table exists, but purpose/columns and code use unverified. | Do not repurpose it without schema/semantics review. Define append-only extension history and proposal separately. |
| Four feasibility states and tourist approval | No deployed feasibility/revision contract supplied; current MO-GA has no fixed-event scheduling. | Separate assessment/proposal from objective vector. Agree aggregation semantics before implementation. |
| Tourist-only privacy | Existing reservation policy summary permits owner/admin access for a different workflow; profile/event policies have broad read risks. | New event data requires dedicated owner-only RLS/grants. Do not copy old policies. |
| Activity/event discovery and references | `activities`, `events`, and `notifications` exist; exact deployed shapes and policies incomplete. Proposed reference table absent. | Reconcile exact columns/constraints and distinguish listings from tourist references/reservation entries. |
| Notification preferences/delivery | `notifications` exists with recipient ownership summary. | Existing table's categories/dedupe/push support are unverified. Additive changes only after catalog review; no claim of feature support. |
| Audit | `audit_logs` exists; client insert is reported. | Not sufficient proof for trusted privileged-access audit. Review server authorship, grants, append-only and privacy payload. |
| Retention/deletion | No approved retention periods; existing FK delete behavior only partially supplied. | Requires owner/privacy approval and verified FK cascades. Do not choose cascade/soft delete blindly. |
| CARS/MO-GA separation | Existing six CARS criteria and three MO-GA objectives are approved. | Preserve them exactly. Activity discovery and fixed event constraints are separate from CARS scoring and MO-GA objective definitions. |

## K. Four Technical Clarifications

### K.1 `profiles.id` versus `auth.uid()`

- **Evidence — CONFIRMED:** `profiles.id` has an FK to `auth.users(id) ON DELETE CASCADE`; `itineraries.tourist_id` and `establishments.owner_id` reference `profiles.id`.
- **Inference:** these IDs are the same UUID identity because of the FK. `auth.uid()` is the session's auth user UUID, so it can be compared to the profile-linked owner key after the profile exists.
- **Risk:** a missing profile or misconfigured profile trigger can prevent ownership resolution; a client-supplied profile ID must not be trusted. `current_user_role()` is SECURITY DEFINER and is part of authorization.
- **Recommended rule:** server derives user identity from `auth.uid()`. Require corresponding profile/parent ownership for draft and event operations. Insert owner fields from trusted session context; reject a mismatch. For APIs requiring `profiles.id`, validate the profile identity through the FK-backed mapping.
- **Remaining decision/evidence:** verify complete profile creation trigger, role constraints/privileges, function execute grants/body, and whether every authenticated user has a profile. Owner approval is not needed for the security principle; implementation needs production evidence.

### K.2 Promotion ownership and same-owner validation

- **Evidence — CONFIRMED:** itinerary tourist FK goes to profiles; proposed drafts/events do not exist in the inspected inventory. No promotion operation was supplied.
- **Risk:** client-side sequencing can create an itinerary for one tourist and attach events from another, leave partially promoted children, or duplicate records on retry.
- **Recommended contract:** one atomic trusted operation checks `auth.uid() = draft.tourist_user_id`, creates the itinerary with the same owner, validates each child belongs to that draft/owner, associates all children while preserving event UUIDs, advances lifecycle/version, and returns one result. Add unique promotion/idempotency key and composite owner constraints. Client cannot provide an authoritative tourist ID. A stale version fails without partial writes.
- **Remaining decision/evidence:** transaction/RPC mechanism depends on verified deployed constraints and Supabase execution pattern. Confirm whether a saved itinerary should retain a draft link or promotion reparents event rows; the proposed 09B-E XOR-parent relation recommends reparenting atomically. Owner should approve lifecycle and conflict UX (OQ-05–OQ-07).

### K.3 Activity/event references without a draft or itinerary

- **Evidence — CONFIRMED policy:** tourists may discover, save, dismiss, or add activities/events. The deployed reference table was not present in the inventory. AP-18 names directory discovery beyond itinerary planning.
- **Risk:** requiring a draft parent for every save/dismiss would block standalone discovery; allowing arbitrary unparented references can create unclear retention and duplicate semantics.
- **Recommended contract:** permit a tourist-owned standalone `saved` or `dismissed` reference with no draft/itinerary; when action is `added`, require exactly one draft or saved-itinerary parent. Use an action-dependent check and parent-owner constraints, or use separate bookmark and itinerary-reference tables. Do not treat any state as registration/booking.
- **Remaining decision:** confirm whether save/dismiss actions are persistent cross-device bookmarks or transient UI state, and whether dismissed references can be re-saved/expire. This is a user-visible persistence decision requiring owner approval. Production columns/RLS for `activities`/`events` must be inspected before choosing FK targets.

### K.4 Feasibility aggregation and Partially Feasible vs Unknown

- **Evidence — CONFIRMED policy:** only four overall labels are allowed. Unknown information must not be fabricated; known conflicts require explanation; fixed commitments are preserved. The exact aggregate boundary was left open.
- **Risk:** if the labels conflate missing evidence and a known unsatisfied constraint, the UI may claim certainty or conceal conflict.
- **Recommended candidate rule (NOT approved):** aggregate by itinerary and report per-day/event issues. `Feasible` only if all required constraints have adequate evidence and pass. `Unknown` when a material required check cannot be evaluated and no known hard contradiction is established. `Partially Feasible` when at least one defined optional/flexible portion is known schedulable while another known portion cannot be included/satisfied, but no fixed external commitment is falsely declared feasible. `Infeasible` when a known hard conflict means the required fixed commitments cannot all be respected. If both a hard conflict and unknowns occur, report Infeasible plus unknown issue details. Never use Partially Feasible solely as a synonym for missing data.
- **Examples for review:** missing route estimate only → Unknown; overlapping fixed appointments → Infeasible; all required commitments fit but a flexible requested destination cannot fit under an approved daily limit → candidate Partially Feasible; all inputs supported and all required constraints pass → Feasible.
- **Remaining decision:** owner/researcher approval is required for whether destinations are required vs optional, how partial stop coverage is aggregated, and precedence in mixed cases (OQ-19). No scoring or optimization formula is defined here.

## L. Security and Privacy Risks

| Risk | Evidence | Required mitigation before release |
|---|---|---|
| **Priority: profile column exposure** | Public SELECT policy/policies using `true`; I-6 table-level SELECT grants to `anon` and `authenticated`; I-2 includes email and phone columns. | Potentially exposes every profile row and all table-readable columns, including email and phone, subject to effective role/policy and column/API privileges. Confirmed grant and policy evidence warrants separate security review. Determine exact role targets, column ACLs/revokes, schema/API exposure and views before final role-by-column determination. |
| Broad itinerary access | Overlapping permissive ALL policies reported. | Evaluate union for SELECT/INSERT/UPDATE/DELETE; verify owner and `WITH CHECK`; remove/replace only under separately approved policy plan. |
| Stop reassignment/visibility | Overlapping stop policies including admin/super path. | Ensure parent owner is checked for both USING and WITH CHECK; test attempted parent UUID change. |
| Event listing overexposure | Authenticated `events` SELECT `true`. | Verify publication/draft state; ensure private moderation data is not exposed and role-only listing assumptions are correct. |
| Reservation privacy mismatch | Existing reservation policies grant some owner/admin access. | Keep separate table; new external information gets tourist-only policy and no establishment-owner visibility by default. |
| Client-forged audit | Authenticated INSERT into `audit_logs`. | Do not use client insert as proof of security audit; trusted server writes actor/target and restricts mutation. Minimize data. |
| **Priority: SECURITY DEFINER unresolved-role path** | `admin_toggle_owner_verification` uses `caller_role NOT IN (...)`; NULL role yields NULL and does not enter a PL/pgSQL IF branch. | Separate security review of full function flow, missing-profile behavior, execute grants and role resolution. Future correction must explicitly reject NULL/unresolved roles; no function change here. |
| One-establishment assumption | Unique owner key and `EstablishmentService.getMyEstablishment()` `.maybeSingle()` query by `owner_id` found in repository. | AP-24 needs more than dropping UNIQUE: review owner-scoped service queries and single-row assumptions, establishment dashboards, verification functions, RLS ownership predicates, and creation/management workflows. Keep this as a separate migration/compatibility task; preserve records and ownership. |
| RLS not forced | All public tables reportedly force=false. | App must use unprivileged authenticated sessions; review owner/service access paths. Do not expose service-role credentials. |
| Policy OR semantics | Multiple permissive policies reported. | Inventory all applicable policies by command/role and compute effective union. A new restrictive-looking policy may not narrow access. |
| Sensitive schedule/location data | Proposed reservation events can reveal travel plans and absence from accommodation. | Collect minimum data, owner-only access, avoid notes in notifications/audit, set approved retention, and threat-model privileged support access. |
| Untrusted external data | No full source/freshness contract supplied. | Label source and verification status; avoid claims of availability, open status, fees, or schedule freshness without evidence. |

## M. Proposed Migration Sequence (design only)

Each phase is conditional on approved metadata, policy decisions, migration tooling/history strategy, review, and backup/rollback plan. This is not an instruction to create or execute migrations.

### Production baseline and compatibility

1. Capture a sanitized catalog snapshot and query results for all 26 public tables, policies, grants, constraints, indexes, functions, triggers, types, sequences, extensions, views, and migration history.
2. Reconcile the snapshot to repository migrations and record object provenance where known. Do not replay legacy migrations and do not register them as applied without object-by-object evidence.
3. Establish a separate, owner-approved migration-history strategy. Empty history is not an empty schema. A baseline/repair process needs independent change review and must not mutate production during this design task.

### Additive feature structures (future proposal)

4. Draft aggregate: `itinerary_drafts`, owner FK, method/stage/version/contract version/timestamps and promotion identity. Add unique composite parent key and indexes only after query/RLS review.
5. Reservation events: event table with XOR `draft_id`/`itinerary_id`, owner-safe FKs, closed event-type checks, conditional Other description, provenance/time/stay fields, idempotency/version, and parent indexes. Preserve `public.reservations` unchanged.
6. Extension history: append-only child table with ownership through event parent, original/revised values, actor/source/status and event-time index.
7. Parent/child constraints and promotion operation: composite owner FK or reviewed equivalent; transaction validates session owner and same owner across draft, itinerary, stops and events; stable event IDs and idempotent promotion.
8. RLS/grants: dedicated owner-only draft/event policies, separate publisher policy model, no broad `true` or generic admin ALL on private reservation data. Test the union of every policy and grants before use.
9. Activity/event references: decide standalone saved/dismissed versus itinerary-added parent rules; add FKs to verified listing structures, snapshot/version and unique/dedupe constraints.
10. Activity publishing additions only if current `activities`/`events` cannot support approved roles, lifecycle, source evidence, participation classification, freshness and snapshots. Avoid duplicate listing tables without schema comparison.
11. Notification preference/in-app notification structures only after verifying existing `notifications` compatibility; add source-version dedupe and recipient-only access. Push endpoint storage is separate, optional and security reviewed.
12. Audit/access records: extend only after reviewing `audit_logs`; trusted append-only privileged-access audit must not depend on client-forged inserts.
13. Retention/deletion constraints/jobs after explicit retention approval; define cascade/soft-delete behavior, history exceptions, and audit minimization. Do not add cascading delete that contradicts AP-21/AP-26.

### Backward compatibility, verification and rollback

- Additive changes should not rewrite existing reservations, itineraries, profiles or owner IDs. Existing APIs remain unchanged until new clients/services are deployed and tested.
- Use expand/migrate/contract only where compatibility requires it; do not rename/drop legacy objects in the feature migration.
- Validate migration against a production-equivalent non-production snapshot; inspect query plans and RLS results with least-privilege role fixtures.
- Before production execution, obtain a restorable backup/restore point, migration review, expected catalog diff, success checks, and a written rollback/forward-repair plan. Destructive rollback is not the default; prefer forward repair if data has been written.
- Verify after each approved migration: exact columns/constraints/indexes, policy/grants effective behavior, owner isolation, idempotent retry, promotion atomicity, and no unexpected changes to `public.reservations` or existing records.
- The `UNIQUE(establishments.owner_id)` correction is a separate migration with independent inventory, preservation test and approval. Do not combine it with initial reservation/event tables.

## N. Implementation Readiness Matrix

| Area | Readiness | Evidence/gap | Gate before implementation |
|---|---|---|---|
| Three-method shared draft workflow | Partially specified | 09B-E contract exists; repository supports only in-memory/manual lifecycle. | Server draft contract, state transitions, persistence and method integration approved. |
| Draft/event tables | Not ready | Proposed structures absent in supplied inventory. | Complete deployed columns/constraints, migration baseline strategy, retention and ownership decisions. |
| Parent-child ownership | Design direction specified | Profile/auth/itinerary links supplied; exact policies/grants and composite constraints not. | Confirm identity/role function, constraints, exact RLS union and negative tests. |
| Atomic promotion | Not ready | No draft/promotion operation supplied. | Choose transaction/RPC and verify same-owner, retry, rollback semantics. |
| Existing reservation separation | Ready as a preservation rule | Existing table is establishment-side and has different access/status. | Preserve table; no feature work may repurpose it. |
| Time/accommodation contract | Partially specified | AP-04–AP-09 supplied; event schema absent; detailed all-day/missing-time semantics open. | Close OQ-04/OQ-13/OQ-20 and implement/test serialization. |
| Feasibility aggregation | Not ready | Four names approved; aggregate semantics not. | OQ-19 acceptance rules approved; route source and uncertainty policy available. |
| Activity/event listings | Not ready | Tables exist but full contracts/policies not supplied; local migrations are not proof. | Inspect actual objects; approve source evidence, publisher and lifecycle contracts. |
| Activity references | Not ready | Proposed table absent; standalone save/dismiss semantics unresolved. | Owner decision K.3; verify listing IDs and parent constraints. |
| Notifications | Not ready | Existing table and recipient ownership summary only. | Verify fields/policies; approve dedupe/retry/expiry and push boundary. |
| Audit/support access | Not ready | Existing client insert and Super Admin read summary; helper functions need review. | Define privileged access, server-authored audit, retention and least privilege. |
| Multiple establishments per owner | Blocked by known constraint | Deployed owner key unique. | Separate reviewed migration and code compatibility plan. |
| Offline synchronization | Deferred | Hive snapshots do not prove sync/outbox/conflicts. | Separate approved sync task after server persistence. |
| CARS/MO-GA behavior | Existing policy boundary ready | Six criteria/three objectives are fixed; current MO-GA lacks event scheduling. | Separate researched adapter task; prove objective formulas unchanged. |

## O. Outstanding Decisions

The approved AP-01–AP-26 policies remain fixed. These implementation-level choices remain open:

1. Retention periods by draft, reservation event, completed itinerary, listing reference, notification and audit record (owner/privacy approval).
2. Soft versus hard deletion, backup retention, legal/audit exceptions and user deletion semantics (owner/privacy approval).
3. Whether/when support or Super Admin may access reservation content, purpose/approval/audit process (owner/security approval).
4. Date-only/all-day listing event boundary and conversion/display behavior beyond Asia/Manila requirement (product/technical approval).
5. Draft lifecycle names, expiry, recovery and abandoned draft behavior (owner approval).
6. Atomic promotion mechanism, draft link versus event reparenting, and idempotency response contract (production architecture review and owner approval).
7. Concurrent edit/conflict user experience (owner approval; do not silently last-write-wins).
8. Exact DB enforcement for parent-child owner matching after full FK/index/RLS inspection.
9. Location validation, geocoding/provider, coordinate provenance and privacy (research and owner approval).
10. Activity source evidence, freshness, external provider/licensing and manual/API ingestion (research and owner approval).
11. Activity/event reference persistence: standalone saved/dismissed bookmarks vs transient state; added requires itinerary/draft parent (owner approval).
12. Notification dedupe, retries, expiry, read state, affected-user scope and optional push operations (owner/product/security approval).
13. Accommodation missing-time aggregate status and same-day stays (owner/researcher approval).
14. Fixed-event Pareto evaluation/scheduler integration (researcher/owner approval; objectives unchanged).
15. Recovery behavior for actual extension after missed event/completed stop (acceptance examples and owner review).
16. Listing snapshot fields and retention in itinerary history (owner/privacy approval).
17. Separate migration plan for `UNIQUE(establishments.owner_id)` and affected service/UI behavior (owner/database approval).
18. Complete RLS/grants/functions/triggers and role hierarchy evidence (production metadata required).
19. Formal boundary between Partially Feasible, Unknown and Infeasible; aggregation across day/event/itinerary (owner/researcher approval).
20. Appointment duration units, precision, rounding and validation limits (owner/researcher approval).
21. Exact users/itineraries considered affected by event updates/cancellation and notification idempotency (owner approval).

## P. Verification and Rollback Requirements

### Read-only production verification still required

Before future implementation, project owner should run the unexecuted SELECT-only queries from Task 09B-E and supply sanitized results for:

- Full columns/types/default/nullability/generated expressions for all relevant current tables and any proposed names.
- PK/FK/unique/check/exclusion constraints with delete actions and validation state.
- Partial/expression/unique indexes.
- RLS enabled/forced and **all** policies including command, role targets, permissive/restrictive, USING and WITH CHECK.
- Table, column, schema, sequence and function privileges plus relevant role memberships.
- Function signatures/definitions, security-definer flag, owner, explicit search path/config and execute grants.
- Trigger definitions/enablement and functions.
- Extensions, custom types, domains, views, materialized views, sequences/identity relationships.
- Migration-history table columns and identifiers only; no repair or writes.

No personal profile/reservation rows are needed. Do not provide secrets or tokens. Empty catalog output should be reported with query scope/role and not interpreted as proof of global absence.

### Future change controls

1. Require a reviewed migration diff and a production-equivalent rehearsal.
2. Confirm backup/restore capability and exact rollback/forward-repair owner before any production write.
3. Capture before/after catalog snapshots and expected object diffs.
4. Run least-privilege integration tests for each role and cross-owner denial; test the OR-union of permissive policies.
5. Test failure atomicity for promotion and idempotent retry; verify no child/parent mismatch or duplicate itinerary.
6. Confirm old clients and existing establishment reservations continue working, and that `public.reservations` is unchanged.
7. Rollback must not delete newly written tourist data. Prefer a reviewed forward repair or restore plan after writes; never assume dropping new tables is safe.
8. The owner’s decision to establish migration history must be separate from migration application. Do not register old files as applied absent evidence.

No verification or rollback command was run against Supabase as part of this task.

## Q. Final Recommendation

Preserve all AP-01–AP-26 decisions. Keep `public.reservations` dedicated to the existing establishment workflow. Treat `auth.uid()` as the authenticated identity and enforce parent-child ownership with both database integrity and RLS/transaction checks. Build new private reservation-event data only after complete production catalog/security review, explicit retention/support/conflict decisions, and an atomic promotion design.

The most urgent production risks to separately review are public profile SELECT, permissive policy unions on itineraries/stops/events, client-authored audit inserts, SECURITY DEFINER function behavior/search path, and the owner uniqueness constraint. This report does not authorize changing any of them.

**Next task:** Task 09B-G — Sanitized Production Catalog Evidence Review and Final Additive Migration/RLS Proposal. Use the project-owner-run metadata outputs to resolve current-schema gaps, reconcile every proposed table/constraint/policy with production, document the migration baseline strategy, and obtain explicit decisions from Section O. Keep it design-only until the owner approves an implementation task.

**Readiness:** not implementation-ready. Production policy/grant details and multiple owner decisions remain outstanding. No application code, migration, SQL execution, deployed database object, or production record was modified in this task.
