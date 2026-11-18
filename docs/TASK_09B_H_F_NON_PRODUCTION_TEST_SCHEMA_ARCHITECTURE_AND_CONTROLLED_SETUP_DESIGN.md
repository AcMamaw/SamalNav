# Task 09B-H-F — Non-Production Test Schema Architecture and Controlled Setup Design

**Status:** Documentation-only design. The owner reports that a clean dedicated non-production Supabase project exists. This report does not connect to it, create objects, provision users, execute SQL, or modify any database. It does not claim any authorization test passed.

## A. Purpose and scope

Define a minimal isolated architecture for the SEC-01–SEC-12 authorization tests in H-D. Separate (1) current-behavior reproduction for characterization, (2) separately reviewed candidate security objects, and (3) synthetic Auth identities and fixtures. This is not a production baseline, executable setup, remediation, or authorization to make changes. AP-01–AP-26, CARS, MO-GA, and the existing public.reservations contract remain unchanged.

## B. Environment baseline and evidence classification

**Owner-supplied non-production baseline:** Project SamalNav-NonProduction, reference iwzyasdanesaaxxjujxr, region ap-southeast-2, Healthy, PostgreSQL 17.11. The owner reports the public schema has no application tables, views, sequences, functions, custom types, or RLS policies; migration history is uninitialized; Supabase Auth is available; roles include anon, authenticated, service_role, authenticator; service_role has BYPASSRLS=true; anon/authenticated do not; application roles and PUBLIC have public USAGE but not CREATE; no default privilege entries or public relation grants were returned. These facts were not independently rechecked. Verify project identity in a future authorized setup session; production is out of scope.

**Owner-supplied production evidence from H-A/F, summarized in H-B/G:** profiles.id references auth.users.id; profile SELECT exposure and broad relation privileges were reported; establishments.owner_id is unique, conflicting with AP-24; itineraries/stops have ownership relationships and overlapping permissive policies; reservations has two itinerary FKs to itineraries(id) with ON DELETE SET NULL; admin_toggle_owner_verification(p_owner_id uuid,p_verified boolean) updates all establishments for an owner or creates one if none exists; the role guard has a NULL concern; reservation policy uses establishment while the profile role constraint allows tourist, owner, administrator, super_admin. H-A Query 2/3 excerpts are truncated. The original H-A Query 5 membership query had a reporting flaw; later owner-supplied H-I Query 13 records ROOT_STATUS diagnostics for anon, authenticated, and service_role and no visible paths. Its raw output is not retained, and catalog visibility remains a limitation. Query 1 separately confirms service_role BYPASSRLS. These are supplied metadata facts, not independently queried here.

Do not copy production rows. Reproduce only the minimum behavior needed, and label approximations. Local migrations are not proof of deployed or current objects.

## C. Architecture principles and isolation boundaries

1. Use only the dedicated non-production project after separately verifying its identity; never connect this work to production.
2. Provision Auth users through Supabase Auth signup or an approved Auth administration workflow. Never insert directly into auth.users.
3. Keep current-behavior reproduction and candidate objects distinct by names/version and preferably project. Do not let a candidate pass stand in for current behavior.
4. PostgREST tests require an API-exposed schema. A non-exposed namespace supports catalog/SQL checks but does not prove client API behavior. Any schema exposure change requires separate review.
5. Copy exact types, nullability, defaults, constraints, and policy expressions only from verified evidence. Unknown details remain unknown.
6. Do not treat Flutter role state, user metadata, or client-supplied role as authorization authority. Verify Auth subject and trusted role source for each request.
7. Separate SQL privileges, RLS, function EXECUTE, Auth identity, function checks, and UI visibility.
8. Use the least-privileged setup operator authorized for the non-production setup. Do not use service_role for ordinary-user tests.
9. Preserve AP policies: do not use public.reservations for future tourist-entered external arrangements; no default owner/Tourism Office access to those future private records; no cross-device-sync claim; AP-24 is not resolved by removing uniqueness alone.

**Recommended layout:** reproduce exact relevant object names in the isolated project’s public schema for PostgREST behavior tests; keep candidate objects in a separately named candidate namespace or disposable project. No schema is created by this task.

## D. Proposed test schemas and object inventory

This is a conceptual inventory, not DDL. auth.users remains Supabase-managed. Exact types and required columns must come from verified metadata. Do not invent mandatory fields/defaults for function side effects.

### D.1 Current-behavior reproduction group

| Object | Purpose / tests | Minimum fields, keys and relationships | Constraints, RLS and privileges | Fixture / classification |
|---|---|---|---|---|
| public.profiles (minimal) | SEC-01/12; SEC-02 role lookup; SEC-04 actor context | id tied to Auth UUID; fields needed for tested paths: display_name, email, username, phone, role, preferences, budget, fcm_token. Add other fields only when tested and confirmed. | PK id; reported FK to auth.users(id). Reproduce selected production role constraint and tested SELECT/UPDATE policy behavior. Broad access only in a clearly labeled current-behavior reproduction. | Synthetic public/private markers. Do not include mfa_email_enabled unless confirmed. |
| public.establishments (minimal) | SEC-02/07/10 | id, owner_id, is_verified, plus exact fields required by verified function and required column contract. owner_id references profiles.id. | PK id; current-behavior variant reproduces unique owner_id and relevant policies. Required fields/defaults must be verified. | Owner A with zero establishments and an owner with multiple only in candidate/AP-24-compatible setup. |
| public.itineraries (minimal) | SEC-05/06/09 | id, tourist_id, plus fields required by policy/test; tourist_id references profiles.id. | PK and confirmed owner FK/action; reproduce verified permissive policies, USING/WITH CHECK, grants. | One synthetic itinerary each for A/B. |
| public.destinations (support) | SEC-06 stop FK | Stable synthetic id and only fields required by the referenced FK/policy. | PK; no copied destination catalog. Privileges only as reviewed. | A few synthetic destination IDs. |
| public.itinerary_stops (minimal) | SEC-06 | id, itinerary_id, destination_id and only fields necessary for insert/update/reparent tests; FKs to itinerary/destination. | PK and verified FK actions. Reproduce overlapping policy and omitted explicit WITH CHECK only when its expression is verified. Grants tracked separately. | A/B stops plus cross-parent and reparent fixtures. |
| public.reservations (minimal) | SEC-07/08/09 | Supplied names: id, itinerary_id, tourist_id, establishment_id, destination_id, eta, pax_count, reservation_status, service_name, created_at. | PK id; reproduce verified FKs/status check/policies. Include both confirmed itinerary constraints reservations_itinerary_fk and reservations_itinerary_id_fkey, both to itineraries(id) ON DELETE SET NULL. Do not drop/alter. | Same-owner and cross-owner cases. Existing establishment booking only. |
| public.audit_logs (minimal) | SEC-04 | id plus confirmed fields used by client: user_id, actor_id, role, action/action_type, description, target_id, created_at, subject to exact metadata. | PK id; do not invent FKs/triggers. Reproduce supplied authenticated INSERT and Super Admin SELECT semantics where verified; separately test UPDATE/DELETE. | Forged actor/role/action/target markers. |
| public.hfc_owner_verification_characterization (test-only function) | SEC-02 existing behavior characterization | Same owner-id and verified-state inputs; reads synthetic profile role and targets only test establishments. | Separately named isolated copy; preserve observed owner-wide update/default-create behavior for characterization. Exact body/security settings and ACL require verified source. Never deploy/call production function. | Owner with multiple and zero establishments; characterization only, not security approval. |

### D.2 Candidate security-design group

Use a separate candidate namespace/project with versioned object names/results. If API behavior is tested, expose only after separate review.

| Candidate object | Purpose / minimum contract | Security and fixtures |
|---|---|---|
| Candidate profile projection | SEC-01: approved public fields separated from private fields. | Review base table, views/RPC and grants together. Test anonymous and A/B access. |
| Candidate profile/role policy | SEC-12: user-editable fields separated from privileged role changes. | Define approved role transitions and Super Admin path; A/B synthetic profiles. |
| Candidate establishment-scoped verification function | SEC-02/10: specific establishment target rather than owner-wide target. Exact signature is undecided. | If reviewed, reject missing/unresolved identity and unauthorized/cross-owner target; permit only approved scope. Test target, sibling, and foreign establishment separately. |
| Candidate itinerary/stop policies | SEC-05/06: explicit per-command access and parent-child owner invariant. | A/B itineraries and stops; exceptional admin access only if explicitly approved. |
| Candidate audit path | SEC-04: trusted actor derivation, write/read/mutation scope, atomicity contract. | Synthetic forged actor inputs and controlled failure case; trusted service only if actually configured. |
| AP-24 candidate establishment contract | SEC-10: multi-establishment cardinality and independent verification. | Two establishments for Owner A, one for B; service/dashboard selection must be explicit. Not achieved by removing unique owner_id alone. |

Candidate objects are not ready for creation until expected behavior, API exposure, role matrix, and policy are reviewed. They must not be confused with production or current-behavior reproduction.

### D.3 Synthetic fixture relationship map

Auth-generated UUID → profiles.id (reported FK). Tourist A → itinerary A → stops A; Tourist B → itinerary B → stops B. Owner A → establishment A1 (and A2 only in candidate AP-24 setup); Owner B → establishment B1. Synthetic reservations reference profile, itinerary, establishment and destination. Audit rows use synthetic actor/target markers only. This describes fixture relationships, not new production constraints. Independent FKs do not establish that reservation tourist and itinerary owners match.

## E. Synthetic identities and role mapping

| Identity | Canonical stored role | Use |
|---|---|---|
| Anonymous visitor | No Auth session/profile | Anonymous API checks. |
| Tourist A | tourist | Own/cross-user profile, itinerary, stop, reservation and role tests. |
| Tourist B | tourist | Cross-user control. |
| Establishment Owner A | owner | Own establishment/reservation tests. |
| Establishment Owner B | owner | Cross-owner control. |
| Tourism Office Administrator | administrator | Explicitly scoped admin tests. |
| Super Administrator | super_admin | Separately scoped privileged tests. |

These canonical values are owner-supplied production evidence. Preserve the mismatch: some reservation policy logic tests establishment, whereas the profile role constraint allows owner. Do not coerce one to the other. If a test safely uses establishment and the constraint rejects it, record that result.

Provision identities via non-production Supabase Auth. Let Auth generate the UUID, then associate the exact subject with a synthetic profile through an approved setup flow. Never insert auth.users manually. Verify each request subject and role source. User metadata, request role fields and Flutter state are not authorization sources. Include a service/backend identity only if an actual test backend is confirmed; a database role’s existence does not prove configured backend/key.

## F. Synthetic data and fixture relationships

Use generated identifiers and clearly synthetic values only.

| Fixture set | Required scenarios |
|---|---|
| Profile | Distinct public and private markers for email, phone, role, budget/preferences, FCM token where columns exist; username marker for pre-auth lookup. |
| Role edge cases | No session; valid A/B profiles; test Auth subject with no profile if safely provisioned; NULL/unresolved role only in isolated function fixture if schema permits; unauthorized tourist/owner. |
| Establishments | Owner A zero-row case for default-creation characterization; multiple rows only in candidate AP-24 schema; Owner B control row. |
| Itineraries/stops | A/B parents, destination fixtures, own stops, cross-parent insert/reparent/delete cases, tourist_id mutation attempts. |
| Reservations | Same-owner and cross-owner tourist/itinerary pairs, A/B establishments, verified status values. Do not create external-reservation-event fixtures here. |
| Audit | Synthetic actor A/B, role markers, fake action/action_type and unrelated target. No private notes/secrets. |
| FK deletion | Disposable itinerary/reservation pair for ON DELETE SET NULL characterization, only after destructive-test approval in disposable scope. |
| Functions | Existing-behavior copy with owner-wide and zero-establishment cases; separate candidate target/sibling/cross-owner cases. |

If the characterization function requires additional mandatory establishment fields, use the verified function/schema contract; do not invent values or defaults.

## G. SEC-01 through SEC-12 traceability matrix

| SEC | Objects and fixtures | Identities/layers | Prerequisite and interpretation |
|---|---|---|---|
| 01 | Profiles, private markers, optional candidate projection | Anonymous/A/B; PostgREST, username UI, applicable view/RPC | Reproduce broad policy separately from candidate. Test private fields; catalog alone does not prove endpoint exposure. |
| 02 | Existing-function characterization copy, establishments; separate candidate function | Anonymous/A/B, owners, admin/Super Admin; catalog and isolated invocation | Characterize owner-wide update/default creation, not a pass. Test missing identity/profile, NULL role and unauthorized roles with no mutation expectation. Candidate has separate reviewed contract. Never call production. |
| 03 | Minimum of nine H-A relations needed per operation; privilege snapshot | All test roles; API and privileged catalog session | Match H-C actual calls; inspect TRUNCATE/REFERENCES/TRIGGER separately; grants differ from RLS. |
| 04 | Audit logs, profiles, synthetic action | A/B, owner, admin/Super Admin; API/UI/backend only if configured | Forged fields, read/update/delete, atomicity. No assumed backend. |
| 05 | Profiles/itineraries and policies | A/B/admin/Super Admin; direct API | Own/cross-user CRUD, tourist_id reassignment, permissive policy behavior; admin exception requires decision. |
| 06 | Itineraries, destinations, stops and policies | A/B/admin/Super Admin; API and catalog | Cross-parent insert/reparent/delete and implicit WITH CHECK behavior; no current app persistence per H-C. |
| 07 | Profiles, establishments, reservations | Owner A/B/tourist; API and owner UI | Compare owner/establishment vocabulary; role string alone never authorizes foreign establishment. |
| 08 | Existing reservations and related fixtures | Tourist A/B, owners/admins; API/UI | Per-command CRUD and cross-owner cases; tourist cancellation/deletion remains unresolved. |
| 09 | Reservations, itineraries, both named FKs | Privileged catalog, A/B API, disposable SQL characterization | Confirm both constraints and ON DELETE SET NULL; test same-owner separately; no dropping/altering. |
| 10 | Current unique-owner variant and separate AP-24 candidate | Owners A/B; catalog/API/UI/service | Characterize unique constraint; candidate requires service/dashboard/maybeSingle and independent verification review. |
| 11 | Client artifacts/logs and backend only if configured | Secret-safe scanner; backend requests if applicable | No secret values printed. BYPASSRLS is not authorization or evidence of client key exposure. |
| 12 | Profiles, role constraint/policies, audit logs | Tourist A, Owner A, Super Admin; API and UI | Own/cross role updates, legitimate role workflow, ordinary edit. Preserve role mismatch. |

## H. Existing-behavior reproduction versus candidate security design

**Reproduction:** The empty non-production project must first be populated by a separately authorized setup before it can reproduce anything. Reproduce only verified facts. Use a distinct function name for the isolated copy while preserving owner-ID behavior: all establishments for that owner are updated, or a default is created if none exists. Treat both as characterization requiring explicit policy authorization, not as accepted behavior. Broad policies/grants, role mismatch, overlapping policies, duplicate FKs and unique owner constraint are reproduced only where exact evidence supports them. Mark incomplete where grants or definitions are truncated/unverified.

**Candidate:** Keep candidate schema/function/policies separate by name, project/version and results. Candidate tests cannot establish current production safety. Candidate design should explicitly scope profile fields, role mutation, audit authorship/atomicity, per-command itinerary/stop access, canonical owner role, and establishment-specific verification. Do not select a function signature here. Do not treat removal of owner uniqueness alone as AP-24 completion.

## I. Controlled setup sequence and approval gates

No stage authorizes execution. Each requires a separate setup task and approval.

| Step | Prerequisite/action design | Output | Approval/stop condition | Cleanup/rollback |
|---|---|---|---|---|
| 1. Identity/isolation | Verify project name/reference/region/status; confirm not production. | Signed environment alias record. | Owner/security approval; stop on mismatch. | No DB changes; close session. |
| 2. Architecture | Choose reproduction location and separate candidate project/namespace; review API exposure. | Approved diagram/object list. | DB/security/API reviewer; stop if boundaries unclear. | No DB change. |
| 3. Objects/constraints | Resolve exact columns/types/nullability/defaults/FKs/policies and function requirements. | Versioned evidence-to-object manifest. | Schema owner; stop on inferred mandatory field or unknown behavior. | Return to evidence gathering. |
| 4. Roles/privileges | Define identity sources and role-operation matrix; separate grants/RLS/function EXECUTE. | Privilege plan. | Security reviewer; stop if client role or service key is treated as authority. | No DB change. |
| 5. RLS design | Record exact current behavior to reproduce and candidate policies, including USING/WITH CHECK and composition. | Policy trace table. | DB/security approval; stop if policy expressions or expected outcome unresolved. | No DB change. |
| 6. Auth identities | Create dedicated synthetic users through Auth only; record UUID aliases. | Sanitized identity manifest. | Project/Auth owner; stop if direct auth.users insertion or production account proposed. | Revoke synthetic accounts through approved Auth flow. |
| 7. Fixtures | Seed only approved synthetic rows and verify relationships. | Fixture manifest and baseline state. | Test lead approval; stop on real data or unclear owner mapping. | Delete manifest-listed rows or reset disposable project. |
| 8. Function copy | Prepare isolated existing-behavior characterization copy and verify version/ACL. | Function version and state baseline. | Security/DB reviewer; stop if body/guard assumptions lack evidence. | Reset only isolated test objects. |
| 9. Candidate setup | Review candidate objects/function/policies separately, including AP-24 dependencies. | Candidate contract/version. | Separate owner/security/schema approval; stop if candidate is conflated with reproduction. | Reset candidate namespace/project under approved process. |
| 10. Baseline checks | Capture test roles, objects, grants, RLS, policies, ACLs, constraints and API exposure. | Sanitized schema fingerprint. | Reviewer signs baseline; stop on unexplained drift. | Reset unexpected test state. |
| 11. Test execution | Run H-D sequence using verified sessions and synthetic fixtures. | Per-case result records. | Test lead approval per family; stop on unexpected elevation/cross-owner effect. | Isolate and preserve redacted evidence. |
| 12. Cleanup/reset | Remove run fixtures/users or reset only confirmed non-production project. | Cleanup proof and final state. | Owner/reviewer approval and second-person reset check. | Never reset production. |

## J. SQL, migrations, and credential safety requirements

- No executable schema or remediation SQL is provided. Do not execute SQL based on this design.
- Migration history is reported uninitialized. Do not initialize/populate it manually.
- No db push, db reset, migration repair, schema import, function/policy creation, grant/revoke, or Auth account creation in this task.
- Future setup requires a separately authorized task, exact project identity check, reviewed script/migration, reset plan, and post-setup catalog checks.
- Never insert into auth.users directly. Never request or print production/service-role credentials.
- Any actual backend secret remains in approved server-side secret management; never in Flutter/browser bundles, source maps, logs, or evidence.
- Keep setup/operator credentials separate from anon/authenticated test sessions. Do not run ordinary tests as postgres/service_role.
- Redact tokens, emails, phones, FCM tokens, private profile values, reservation notes and credentials.

## K. Cleanup, reset, and evidence retention

1. Use a unique run ID and manifest of synthetic Auth subject aliases and fixture IDs.
2. Review reset target before use; prefer a disposable-project reset over broad manual deletion.
3. If deleting fixtures, use parent/child-aware cleanup and verify no run rows remain with an approved setup identity.
4. Revoke synthetic Auth users through approved Auth administration; never edit auth.users directly.
5. Reset characterization/candidate objects only under approved isolated cleanup. Never alter production function or duplicate FKs.
6. Retain a sanitized report with environment alias, schema version, test IDs, identity aliases, layer, status/error, state summary and cleanup proof.
7. Exclude credentials, JWTs, full rows, email/phone, FCM tokens and tourist reservation content. Evidence retention period must follow an approved policy.

## L. Unresolved decisions and prerequisites

1. Independently verify the owner-reported project identity/baseline in a future authorized session.
2. Complete exact definitions for faithful reproduction, including grant scope not covered by the later supplemental results; retain the owner-supplied corrected H-I Query 13 membership result with its visibility limitation. Do not rely on the flawed original H-A Query 5 no-rows result.
3. Confirm all mandatory fields/defaults used by the default-establishment characterization behavior.
4. Confirm full tested policy expressions, roles and function security/ACL definition.
5. Decide API exposure approach for candidate objects without unintentionally exposing a schema.
6. Confirm whether an actual trusted backend exists; do not infer one from service_role.
7. Resolve H-D’s policy-dependent outcomes: public profile projection, username lookup, tourist reservation cancellation, exceptional admin access, audit atomicity and permitted role transitions.
8. Preserve and separately resolve owner versus establishment role vocabulary.
9. Obtain explicit authorization policy for owner-wide verification/default creation; review any candidate establishment-scoped behavior separately.
10. Plan AP-24 across service cardinality, both dashboards, verification, RLS, owner lifecycle, data preservation and independent verification.
11. Establish test evidence retention and reviewer roles.
12. Ensure outbound email, push, payment, booking, and notification effects are controlled.

## M. Readiness assessment and next-task recommendation

**Architecture design: complete for review. Setup and test execution: not authorized/not ready.** The owner-reported clean project is suitable in principle for a minimal isolated setup, but fidelity requires the exact object/policy/function evidence, approved role matrix, API exposure choice, characterization copy, candidate boundary, and H-D policy decisions. No users or fixtures were created by this report.

Recommended next task: **Task 09B-H-G — Non-Production Test Schema Specification and Owner Approval Gate.** Reconcile exact object definitions and policy/function evidence; prepare a versioned non-executable object manifest and role matrix; decide whether candidate API tests need another project; and obtain explicit owner/security approval before setup implementation. A later separately authorized setup task may create objects and synthetic Auth accounts; H-D test execution follows baseline verification.

AP-01–AP-26, CARS, and MO-GA remain unchanged. This report authorizes no schema setup, SQL, Auth account creation, or database modification.

## Completion record

- **Created:** `docs/TASK_09B_H_F_NON_PRODUCTION_TEST_SCHEMA_ARCHITECTURE_AND_CONTROLLED_SETUP_DESIGN.md`
- **Coverage:** Sections A–M, minimal object groups, role/fixture design, SEC-01–SEC-12 mapping, approval gates, safety, cleanup, and readiness.
- **Files:** This new documentation file only; prior reports and existing working-tree changes are preserved.
- **Database/actions:** No SQL was executed. No Auth users or synthetic data were created. No production or non-production database object was accessed or changed.
- **Validation:** `git diff --check` result is reported in the completion message.
