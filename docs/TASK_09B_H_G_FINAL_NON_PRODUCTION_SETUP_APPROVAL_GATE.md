# Task 09B-H-G — Final Non-Production Setup Approval Gate

**Status:** Final design package for owner/security review. No setup, SQL, Auth provisioning, database access, or authorization tests are authorized or performed by this document.

## A. Purpose and scope

This concise package consolidates H-A through H-F into the minimum object and approval manifest for later isolated non-production authorization testing. It separates current-production-behavior reproduction from candidate security designs. It does not claim remediation or a passing test and does not change AP-01–AP-26, CARS, or MO-GA.

## B. Evidence and baseline

- H-A through H-D and H-F documents are present and reviewed. No standalone H-E report with the requested baseline-inspection title was found. The available non-production baseline is the owner-supplied project record in H-F.
- Owner-reported non-production project: `SamalNav-NonProduction`, project reference `iwzyasdanesaaxxjujxr`, region `ap-southeast-2`, PostgreSQL 17.11, Healthy. H-F reports the public schema is empty of application objects/policies, migration history is uninitialized, Auth is available, and application roles have no CREATE on public. This was not independently verified in this task.
- H-F reports database roles `anon`, `authenticated`, `service_role`, and `authenticator`; `service_role` has BYPASSRLS, while anon/authenticated do not. This does not prove a service backend or credential exists.
- Owner-supplied production evidence: profiles.id references Auth; broad profile SELECT and relation privileges; overlapping itinerary/stop policies; duplicate reservation itinerary FKs with ON DELETE SET NULL; unique establishments.owner_id; owner-ID verification function updates all owner establishments or creates a default row; reservation policy literal `establishment` conflicts with stored role constraint `owner`.
- Evidence limitations: H-A Query 2/3 excerpts are historically truncated; later SUP-05/06R summaries supplement stored/effective relation privilege coverage for the eleven listed relations and three roles, but do not replace raw output or establish every column/object privilege. The original H-A Query 5 membership query had a reporting flaw. The owner later supplied corrected H-I Query 13 ROOT_STATUS diagnostics for anon, authenticated, and service_role, reporting no visible paths; raw output is not retained and catalog visibility remains a limit. Catalog evidence is not PostgREST behavior evidence. No production or non-production access was made here.

## C. Minimal object manifest

This is a non-executable manifest. Exact data types, nullability, defaults, complete constraints, policy expressions, indexes, and privileges must be copied from verified owner-supplied metadata or inspected in the isolated target before faithful reproduction. Do not guess missing fields or semantics.

### C.1 Current-behavior reproduction objects

| Object | Minimum test fields / relationships | Keys and constraints | Policy / privilege behavior to reproduce | SEC |
|---|---|---|---|---|
| `public.profiles` (minimal) | `id`, `display_name`, `email`, `username`, `phone`, `role`, `preferences`, `budget`, `fcm_token`; add fields only when directly tested and confirmed. `id` maps to Auth UUID. | PK `id`; reported FK to `auth.users(id)`. Reproduce verified role check. | Supplied broad SELECT behavior and relevant own-row UPDATE behavior; record grants separately. | 01, 02, 04, 12 |
| `public.establishments` (minimal) | `id`, `owner_id`, `is_verified`, plus exact required fields used by verified function body. `owner_id → profiles.id`. | PK `id`; current-behavior variant includes UNIQUE(owner_id). | Reproduce exact verified owner/admin/verified-read predicates and grants. | 02, 07, 10 |
| `public.activities` | `id`, `establishment_id`, `destination_id`, plus only columns used by verified policy expressions. | PK `id`; confirmed indexes on destination_id and establishment_id; add only verified FKs/checks. | Reproduce verified policies and relation privileges; exact policy fields/expressions must be confirmed. | 03 |
| `public.events` | `id` plus fields referenced in verified policies. | PK `id`; other constraints only from verified metadata. | Authenticated SELECT true and administrator policy behavior as reported; privileges separate. | 03 |
| `public.itineraries` | `id`, `tourist_id`; add fields only as needed for verified policy tests. | PK `id`; reported tourist_id FK to profiles with ON DELETE CASCADE. | Reproduce the two supplied permissive ALL policy behaviors and exact USING/WITH CHECK. | 03, 05, 06, 09 |
| `public.destinations` (support) | Synthetic `id` and only fields required by stop FK/policy. | PK and target relationship as verified. | Minimum access needed to exercise stop FK; no destination catalog copy. | 06 |
| `public.itinerary_stops` | `id`, `itinerary_id`, `destination_id`; add fields needed for update/reparent tests. | PK `id`; verified FKs to itinerary and destination with exact actions. | Reproduce supplied overlapping policies, including omitted explicit WITH CHECK only if exact USING expression is verified. Grants separate. | 03, 06 |
| `public.reservations` | Supplied names: `id`, `itinerary_id`, `tourist_id`, `establishment_id`, `destination_id`, `eta`, `pax_count`, `reservation_status`, `service_name`, `created_at`. | PK `id`; verified status check/FKs. Include `reservations_itinerary_fk` and `reservations_itinerary_id_fkey`, both to itineraries(id) ON DELETE SET NULL; do not drop/alter. | Reproduce exact tourist/owner/admin policies and grants after full definitions are confirmed. | 03, 07, 08, 09 |
| `public.notifications` | `id` plus recipient field(s) actually referenced by supplied policy; confirm exact name/type from I-2/policy evidence. | PK `id`; only verified constraints. | Reproduce recipient ownership policy and grants once exact expression is confirmed. | 03 |
| `public.audit_logs` | `id`, `user_id`, `actor_id`, `role`, `action`, `action_type`, `description`, `target_id`, `created_at`, limited to confirmed fields. | PK `id`; no unverified FKs/triggers. | Authenticated INSERT and Super Admin SELECT policy behavior; inspect all grants and update/delete outcomes. | 03, 04 |
| `public.current_user_role()` | Exact supplied signature/return/body and role lookup semantics. | Function identity/settings as confirmed by H-A; verify complete definition/ACL. | Reproduce only if required by selected policies; preserve SECURITY DEFINER and EXECUTE behavior only in isolated test copy. | 02, 05–08 |
| Test-only owner-ID function characterization copy | Existing parameters `p_owner_id uuid`, `p_verified boolean`; reads synthetic profile role and writes only synthetic establishments. | Distinct test name; no production object reference. | Characterize observed owner-wide update and default-establishment creation; these effects are not automatically authorized or a security pass. | 02 |

These objects are a minimum starting set, not a claim that all can be faithfully reproduced from current metadata. H-A Query 2/3 truncation and incomplete exact policy/function dependencies block finalizing grants and some object definitions.

### C.2 Candidate security objects — separate namespace/project and results

| Candidate object | Minimum purpose | Required separation |
|---|---|---|
| Candidate profile projection and private profile policy | SEC-01: approved public fields separated from private fields. | Separate from baseline profiles; base table, views/RPC and grants tested together. Public field allowlist pending owner approval. |
| Candidate profile role-update boundary | SEC-12: deny self-assignment/cross-user changes while testing authorized Super Admin workflow. | Distinct policy/object version; approved role transitions required. |
| Candidate establishment-scoped verification function | SEC-02/10: specific establishment target rather than owner-wide target. Exact signature undecided. | Separately designed/reviewed; reject missing/unresolved identity and unauthorized/cross-owner target. |
| Candidate itinerary/stop policies | SEC-05/06: explicit per-command access and parent-child owner invariant. | Explicit role matrix and admin exception decision required. |
| Candidate audit path | SEC-04: trusted actor derivation, read/mutation scope and atomicity contract. | Requires approved trusted-write contract; do not assume a backend exists. |
| AP-24-compatible establishment shape/workflow | SEC-10: multi-establishment cardinality and independent verification. | Requires service/dashboard/verification/RLS/creation workflow design; removing UNIQUE alone is insufficient. |

Candidate behavior must never be reported as current production behavior. A candidate pass is not production remediation.

## D. Synthetic identity and fixture manifest

Provision accounts only through non-production Supabase Auth. Auth generates the UUID; the synthetic profile must use that exact ID. Never insert into auth.users. Verify the active Auth subject and trusted role source for each request; Flutter state, user metadata and client role fields are not authorization authority.

| Identity | Stored role | Minimum fixture |
|---|---|---|
| Anonymous visitor | No Auth session | Anonymous profile, projection, function and relation requests. |
| Tourist A | tourist | Own profile, itinerary A, stop A, same-owner reservation, role-update attempt. |
| Tourist B | tourist | Separate profile, itinerary B, stop B; cross-user control. |
| Establishment Owner A | owner | Establishment A1; zero-establishment and multiple-establishment cases only in isolated function/candidate fixtures. |
| Establishment Owner B | owner | Establishment B1 and reservation; cross-owner control. |
| Tourism Office Administrator | administrator | Synthetic target for explicitly scoped admin operations. |
| Super Administrator | super_admin | Synthetic target for separately approved privileged workflows and audit read. |
| Trusted backend/service context | Only if an actual test backend is confirmed | No identity is assumed from database role alone. Keep credential server-side and never print it. |

Fixtures: synthetic public/private profile markers; A/B itineraries and stops; A1/B1 establishments; same-owner and cross-owner reservation-to-itinerary links; synthetic destination IDs; forged audit actor/role/action/target fields. A2 exists only in candidate AP-24 setup. Use no real data. Reproduce the owner versus establishment mismatch; do not silently coerce it.

## E. Explicit role-operation matrix

“Reproduction” means owner-supplied policy evidence, not behavior-tested. Candidate boundaries are intended targets or pending decisions.

| Role | Profiles | Establishments / activities / events | Itineraries / stops | Existing reservations | Audit / functions |
|---|---|---|---|---|---|
| Anonymous | Reproduction: supplied broad profile SELECT and effective SELECT evidence. Candidate: no private fields; approved public projection only (decision pending). | Test only supplied public/anon policies; do not infer. Candidate listing scope needs review. | No private access is the target. | No access unless verified explicit policy says otherwise; not inferred from grants. | No audit read/write target. SEC-02 unauthenticated invocation should deny; characterize isolated function safely. |
| Tourist | Own profile access; role self-assignment must be denied in candidate. | Read approved public listings; no owner writes. | Own-only target; supplied policies overlap and must be tested per command. No default cross-user/admin support access. | Supplied own SELECT/INSERT policies; UPDATE/DELETE unresolved. | No audit browsing or forged authoritative audit; no privileged verification. |
| Owner (stored role owner) | Own profile under approved field boundary. | Own establishment/authorized activity operations only; exact current predicates incomplete. Reproduce establishment literal separately. | No default access to private tourist plans. | Own-establishment scope according to verified policy; cross-establishment denied. | No audit browsing or authoritative client audit. Function access not inferred from role string. |
| Administrator (stored role administrator) | Own profile plus only expressly approved operational fields. | Admin operations within reviewed scope; current app reads events and handles destination/location verification. | No default tourist-plan access under AP-22; characterize supplied policy branch separately. | Only explicitly approved operations; test policy and SQL grant independently. | Client audit insert is characterization only. Existing owner-wide function behavior is not presumed safe. |
| Super Administrator (stored role super_admin) | Own profile; exceptional profile access separately justified/audited. | Oversight within approved scope. | No routine browsing; exceptional access requires decision and audit. | Only explicitly approved oversight. | Supplied audit read policy; write/mutation scope requires review. Role alone does not authorize owner-wide verification/default creation. |

H-A reports all seven tested relation privileges for anon/authenticated/service_role across the nine named relations; this does not establish row access or application need. Test SELECT/INSERT/UPDATE/DELETE separately; inspect TRUNCATE/REFERENCES/TRIGGER as SQL privileges, not ordinary PostgREST CRUD. Service role is not a human role.

## F. Production definitions: confirmed versus still needed

| Area | Confirmed from owner-supplied evidence | Still required before faithful reproduction |
|---|---|---|
| Profiles | Listed columns/effective SELECT, public SELECT policy behavior, Auth FK, role vocabulary. | Complete explicit grants and policy expressions/role targets; verify mfa_email_enabled existence. |
| Establishments | Owner FK, unique owner index, verification behavior summary. | Exact required fields/types/defaults, all constraints/policies/grants, function dependencies/default-create fields. |
| Activities/events/notifications | I-2 column inventory and summarized policies/index evidence. | Exact fields/types needed, all policy expressions, grants, constraints and relationship columns. |
| Itineraries/stops | Owner/parent FK and overlapping policy summaries. | Complete definitions, FK actions, per-command USING/WITH CHECK and privileges. |
| Reservations | I-2 field names, status behavior, duplicate itinerary FKs and role mismatch. | Exact types/null/defaults, all FK actions, complete policies/grants and same-owner behavior. |
| Audit | Column inventory, authenticated insert and Super Admin read summaries. | Complete grants/policies, triggers/functions, accepted fields and server-authorship constraints. |
| Functions | current_user_role and owner-ID verification summaries, SECURITY DEFINER/search path/ACL evidence. | Preserve full definitions/dependencies and the corrected H-I Query 13 result if retained; no visible paths were reported, subject to catalog visibility. External caller inventory remains separate. |
| Non-production baseline | H-F owner-reported clean-project details. | Independent project reference/region/status check in future authorized setup; not checked here. |

No standalone H-E report was located. H-F is the available baseline record. No missing detail is filled by assumption.

## G. Setup, baseline and test order

1. **Project identity gate:** verify project name, exact reference `iwzyasdanesaaxxjujxr`, and region in the authorized non-production console. Any automation must fail closed unless the target reference exactly matches this allowlist. Any other/missing reference, including production, aborts before SQL, Auth, or API writes. Verify URL/reference pair independently; do not rely only on CLI link state or app config.
2. **Evidence gate:** resolve missing definitions from approved records or authorized non-production inspection. Do not build guessed objects.
3. **Owner approval:** approve object manifest, reproduced policies, test roles/operations, candidate boundary, destructive-test limits and retention.
4. **Schema review:** settle exact columns/types/keys/FKs/indexes, API exposure and function copies.
5. **Privilege/RLS review:** approve grants, policies and function EXECUTE scope separately.
6. **Auth provisioning:** only after approval, create synthetic accounts through Auth; verify UUID-profile link and role source.
7. **Fixture setup:** seed only manifest-listed synthetic rows; record initial state and verify relationships.
8. **Function setup:** install only a distinctly named isolated characterization copy preserving owner-wide/default-create behavior. Candidate function, if approved, remains separate. Never call production function.
9. **Baseline verification:** capture objects, privileges, RLS, policies, function definitions/ACLs, constraints, API exposure and fixture state. Sign off before behavior testing.
10. **Authorization testing:** follow H-D priority order and record each layer/result; stop on unexpected privilege or cross-owner mutation.
11. **Cleanup/reset:** remove only test-run identities/fixtures or reset only the confirmed disposable non-production project; verify cleanup.

Every setup stage needs separate authorization. Stop if target identity, expected policy, schema definition, or project reference is uncertain.

## H. Operations to prepare in a later implementation task (not execute here)

1. Project-reference assertion and fail-closed allowlist guard.
2. Creation of minimal reproduction tables and verified constraints/indexes.
3. RLS enablement and the explicitly selected reproduction policies.
4. Reviewed test-role grants and function EXECUTE settings.
5. Separately named owner-ID function characterization copy; candidate function only if separately approved.
6. API exposure configuration for the test schema, only after review.
7. Synthetic Auth account provisioning through Auth and profile linking.
8. Fixture seeding and pre-test baseline capture.
9. Read-only catalog/API verification followed by individual H-D requests.
10. Fixture/account cleanup or disposable-project reset.

This package contains no executable SQL, migration, function body, policy body, grant script, or Auth request. Do not initialize migration history manually.

## I. Decisions requiring owner/security approval

1. Exact production definitions/policies to reproduce and acceptable approximation where evidence is incomplete.
2. Public profile field allowlist and anonymous username lookup behavior; private email/phone/role/preferences/budget/FCM boundaries.
3. Whether mfa_email_enabled exists and should be included.
4. Role-operation matrix, especially Tourism Office/Super Admin access to itineraries, reservations and profiles.
5. Whether owner-wide verification/default establishment creation is intended. Treat as characterization until explicitly reviewed; candidate establishment-scoped behavior has a separate contract.
6. Canonical owner role and resolution of owner versus establishment mismatch.
7. Tourist update/cancel/delete rights for existing establishment-side reservations.
8. Trusted audit writer, actor derivation, mutation/read scope and atomicity.
9. Exact minimum fields/constraints for activities, events, notifications, audit and FK-dependent tables.
10. Whether an actual backend exists and requires a privileged context.
11. AP-24 scope across unique index, service maybeSingle, both dashboards, verification, RLS, owner lifecycle and data preservation.
12. Destructive test approval, evidence retention, reviewer and cleanup responsibilities.

## J. Safety invariants

- Never run SQL/setup unless the exact project reference matches the non-production allowlist and a separate task authorizes execution.
- Never use production credentials, records, or functions. Never request or print service-role secrets.
- No direct auth.users insert; no migration-history initialization.
- No production object/data changes.
- Do not claim tests passed or findings remediated.
- Keep public.reservations separate from AP-01–AP-26 tourist-entered external events.
- Table existence/grants do not prove application behavior.
- AP-01–AP-26, six CARS criteria and three MO-GA objectives remain unchanged.

## K. Readiness assessment

**Approval package ready for owner/security review; setup is not approved.** Before setup, approve the reproduction/candidate boundary, role-operation matrix, unresolved policy outcomes, verified definitions, destructive-test limits and fail-closed reference gate. H-D testing follows only after setup and baseline verification.

No finding is claimed remediated or tested. No SQL was executed; no Auth users or fixtures were created; neither Supabase project was accessed or modified.

## Completion record

- **Created:** `docs/TASK_09B_H_G_FINAL_NON_PRODUCTION_SETUP_APPROVAL_GATE.md`
- **Coverage:** Minimum object manifest, current/candidate separation, role-operation matrix, identity/fixture plan, evidence gaps, setup order, prepared operation categories, approvals and project-reference guard.
- **Validation:** `git diff --check` result is reported in the completion message.
- **Changes:** This new documentation file only; prior reports and working-tree changes are preserved.
