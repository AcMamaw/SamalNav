# Task 09B-H-D — Non-Production Authorization Verification Plan

**Status:** Test plan only. No test in this document has been executed. Use an isolated non-production Supabase project with synthetic identities and data. This plan does not authorize production access, schema changes, policy changes, or remediation.

## A. Purpose and scope

This plan turns owner-supplied H-A catalog evidence and the application call paths documented in H-C into non-production authorization tests for SEC-01 through SEC-12. It separates catalog inspection, PostgREST behavior, Flutter workflows, trusted backend behavior, and privileged SQL-session checks. Success at one layer does not establish behavior at another.

References reviewed:

- `docs/TASK_09B_H_B_PRODUCTION_SECURITY_FINDINGS_AND_REMEDIATION_DESIGN.md`
- `docs/TASK_09B_H_C_APPLICATION_DEPENDENCY_AND_AUTHORIZATION_CALL_PATH_INVENTORY.md`
- `docs/TASK_09B_H_A_SECURITY_EVIDENCE_QUERY_PACK.md`
- `docs/TASK_09B_F_PRODUCTION_SCHEMA_AND_SECURITY_RECONCILIATION.md`
- `docs/TASK_09B_G_FINAL_RESERVATION_IMPLEMENTATION_READINESS.md`
- `docs/TASK_09B_D_APPROVED_RESERVATION_ACTIVITY_POLICY_BASELINE.md`
- `docs/TASK_09B_E_RESERVATION_EVENT_TECHNICAL_CONTRACT_AND_RLS_SPECIFICATION.md`

H-A results are metadata evidence, not test results. Query 2/3 excerpts were truncated; Query 5 membership output is provisional pending corrected-query confirmation; Query 1 separately confirms `service_role` has `BYPASSRLS=true`. No production test, code change, migration, or policy change is included here.

Supplemental owner-supplied catalog evidence SUP-01 through SUP-06C2 is reconciled in `docs/TASK_09B_H_M_SUPPLEMENTAL_PRODUCTION_CATALOG_EVIDENCE_RECONCILIATION_AND_SECURITY_FINDINGS_UPDATE.md`. It updates the catalog baseline but does not change this plan's status: no authorization behavior has been tested. Associate those results with relevant cases below, but do not treat grants or policy definitions as PostgREST test outcomes.

## B. Test-environment architecture

Provision a separate Supabase project or otherwise isolated non-production instance with:

1. A reviewed schema, policies, and functions representative of the target. Record differences and object versions. Do not treat local legacy migrations as a production baseline.
2. A dedicated project URL and anon/public client key for test clients only. Do not copy production credentials or records.
3. Synthetic Auth users and synthetic rows with test-only identifiers. Use no real tourist, owner, staff, contact, itinerary, or reservation data.
4. Separate test runs for PostgREST, Flutter UI, backend, and SQL/catalog access. Preserve sanitized results; redact tokens, passwords, emails, phone numbers, and private payloads.
5. Email, push, webhook, and external booking side effects disabled or routed to controlled test sinks.
6. A disposable reset/reseed capability or short-lived project. Destructive tests run only against disposable fixtures and with explicit non-production approval.

Record the schema snapshot/version before testing. If a relevant function, policy, constraint, or role behavior is absent, mark that test BLOCKED/NOT RUN rather than substituting an unreviewed object.

## C. Test identities and fixtures

Create dedicated Auth users through the non-production signup/admin workflow. Verify each authenticated session’s Auth subject against its synthetic profile UUID. Do not establish a role by changing Flutter state, editing local metadata alone, or assuming a JWT claim creates a database role. Seed role values through an explicitly trusted non-production setup path and record that source.

| Identity | Fixture purpose |
|---|---|
| Anonymous visitor | No Auth session; profile projection, public listing, unauthenticated function checks. |
| Tourist A and Tourist B | Distinct Auth subjects/profile rows; separate synthetic itineraries, stops, and reservation fixtures where supported. |
| Establishment Owner A and Owner B | Separate identities and establishments; reservations attached to each owner’s establishment. |
| Tourism Office Administrator | Dedicated identity for explicitly scoped administrator checks. |
| Super Administrator | Dedicated identity for separately authorized privileged-workflow checks. |
| Trusted backend/service context | Include only if actually configured in the test environment. Record the boundary and credential custody without exposing the secret. |

Use synthetic marker values for public and private profile fields. Include email, phone, role, budget/preferences, and FCM token or equivalent only if those columns exist in the test schema. For ownership tests, create distinct tenant groups. Fixture role values must satisfy the actual test schema; record vocabulary mismatches instead of silently coercing them.

## D. Test safety and cleanup rules

- Verify project URL/environment before each run; abort if it is production.
- Use test-only credentials from an approved local secret store; never place credentials in source, reports, screenshots, or logs.
- Run destructive checks only in a disposable project or on disposable rows. Prefer fixture recreation to deletion where practical.
- Track fixture IDs in a run manifest and clean up only that run’s records/accounts. Verify cleanup or reset afterward.
- Never alter production JWTs, policies, grants, functions, or rows.
- Do not call production `admin_toggle_owner_verification`. SEC-02 requires a reviewed non-production equivalent or isolated copy; otherwise it is blocked.
- Keep request evidence minimal: method/table or function, status/error code, safe row counts, and redacted assertions.
- Do not use `service_role` for ordinary user tests. If a test-only trusted context exists, test it separately and do not print/export its key.
- Do not assume a successful UI check demonstrates direct API authorization.

## E. SEC-01–SEC-12 test cases

Expected behavior follows H-B’s intended privacy/security boundary and approved AP policies. H-A evidence suggests some tests may fail under current policies. A failure is evidence for review, not authorization to change production. Record environment/schema version and test layer for every case.

### SEC-01 — Profile privacy

| Test ID | Identity and operation | Expected behavior | Evidence and pass criteria |
|---|---|---|---|
| 01-A | Anonymous client performs the LoginPage username lookup shape: select email filtered by a synthetic username. | Anonymous callers must not retrieve account email. If username login remains a feature, it must not disclose the associated email before authentication; its safe behavior needs an explicit decision. | Capture status and whether any row/email was returned, redacted. Pass only if email is not disclosed. H-A suggests current policy/grants may allow this; catalog evidence alone is not a behavior pass. |
| 01-B | Anonymous and Tourist A request the approved public profile projection, if present, and separately attempt base-table reads. | Only explicitly approved public display fields are returned. Private fields are not exposed through the base table. If no projection exists, mark the test blocked by missing design/implementation. | Compare returned columns against an approved allowlist. Test base table and every applicable view/RPC separately. |
| 01-C | Anonymous and Tourist A request synthetic email, phone, role, budget/preferences, FCM token, and other private fields through direct table, applicable view, and applicable RPC paths. | Deny unauthorized private-field access. Tourist A may access only its own fields where approved. RLS is not column privacy. | Test paths/columns separately; pass only if unauthorized values are not returned. Requires verified schema. |
| 01-D | Tourist A reads/updates permitted own fields and attempts to read Tourist B by ID and username. | Own allowed operations work; cross-user private rows are not returned or changed. | Record status, redacted result, and post-request state. Direct PostgREST is required in addition to UI. |

### SEC-02 — SECURITY DEFINER authorization function

Separate **characterization of the existing function** from **verification of a proposed candidate**. The existing `admin_toggle_owner_verification(p_owner_id uuid, p_verified boolean)` accepts an owner ID, updates all establishments belonging to that owner, or creates a default establishment if none exists, according to the supplied implementation evidence. Use only a reviewed non-production equivalent or isolated copy to characterize it; never invoke the production function. Record this behavior as characterization evidence, not as a security pass, even when the caller is an Administrator or Super Administrator. Owner-wide updates and default-establishment creation require explicit authorization and review against the intended establishment-verification policy.

| Test ID | Function under test, identity and operation | Expected behavior / classification | Evidence and dependencies |
|---|---|---|---|
| 02-A | **Existing isolated copy:** invoke as Administrator and Super Administrator with an owner ID that has multiple synthetic establishments. | Characterize and record whether all of that owner’s establishments are updated. This is not a pass based on caller role; owner-wide scope requires explicit authorization and policy review. | Record function signature/version, verified caller identity/role, input owner alias, every affected establishment alias, before/after verification state, and audit evidence. Requires isolated copy and verified EXECUTE ACL. |
| 02-B | **Existing isolated copy:** invoke for an owner ID with no establishment. | Characterize and record whether a default establishment is created. Treat creation as a behavior requiring explicit authorization/review, not an expected security success. | Record synthetic row count/IDs and fields created, before/after state, and audit evidence. Use disposable fixtures; verify no unrelated row changes. |
| 02-C | **Existing isolated copy:** invoke without identity, with missing profile, NULL/unresolved role, anonymous identity, Tourist A, and Owner A. | Unauthorized or unresolved identities/roles must be rejected with no mutation. If current behavior allows a call, record a failure/risk; do not classify it as acceptable. | Capture safe status/error and before/after establishment state. Specifically exercises the nullable `NOT IN` concern from H-B. |
| 02-D | **Existing isolated copy:** invoke with Administrator/Super Administrator against a nonexistent or other-owner target. | Characterize the result and any effects. A role alone does not prove target scope is authorized. Any cross-owner mutation or unintended creation is a failure/risk pending explicit policy review. | Record target/owner aliases, all resulting state changes, and error/status. Requires synthetic cross-owner fixtures. |
| 02-E | **Proposed candidate only, if separately designed and reviewed:** invoke an establishment-scoped function using a specific synthetic establishment ID as an authorized caller, then as an unauthorized caller. | If approved, the candidate may change only the specifically authorized establishment and must reject cross-owner targets without mutation. This expected behavior applies to the candidate, not to the existing owner-ID function. | Requires a reviewed candidate signature/authorization contract, isolated schema, verified identities, before/after state for all establishments, and audit evidence. If no candidate is designed/reviewed, mark not applicable/not run. |
| 02-F | **Candidate only, if it supports an owner with multiple establishments:** request a change for one of that owner’s two synthetic establishments. | Only the specifically identified and authorized establishment changes; the sibling establishment remains unchanged. | Requires an AP-24-compatible non-production schema and reviewed establishment-level verification policy. Otherwise blocked by SEC-10/AP-24. |

### SEC-03 — Relation privileges

Test the nine H-A relations—`activities`, `audit_logs`, `establishments`, `events`, `itineraries`, `itinerary_stops`, `notifications`, `profiles`, and `reservations`—against H-C’s actual client-operation inventory. Do not infer a requirement from an existing grant.

| Test ID | Operation | Expected behavior | Evidence and limitations |
|---|---|---|---|
| 03-A | By anon, Tourist A/B, Owner A/B, Administrator, and Super Administrator, test only identified required SELECT/INSERT/UPDATE/DELETE through PostgREST and the applicable Flutter flow. | Only approved commands/rows/columns are allowed; cross-owner and unrelated operations are denied. | Per-table/command matrix and minimal fixture state. Requires an approved role-operation matrix. |
| 03-B | In a privileged non-production catalog session, inspect effective table/column privileges and RLS independently. | Metadata establishes grants, not row access; PostgREST outcomes must separately match intent. | Record role, object, command, and policy version. Catalog query is not a CRUD test. |
| 03-C | Inspect TRUNCATE, REFERENCES, and TRIGGER privileges. | Ordinary client roles should not have these capabilities absent a documented need. Do not execute them against application fixtures. | Metadata checks only; any execution test needs a disposable schema and separate approval. RLS does not replace these privilege checks. |

### SEC-04 — Audit integrity

| Test ID | Identity and operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 04-A | Tourist A/Owner A submit synthetic audit rows with forged actor, user, role, action/type, description, and target. | Client input cannot be authoritative privileged history. Trusted writes derive actor and validate action/target. | Record accepted fields and persisted synthetic row, redacted. H-A’s insert policy makes this a priority. Requires confirmed schema and desired writer. |
| 04-B | Test audit SELECT/UPDATE/DELETE as anon, Tourist A, Owner A, Administrator, Super Administrator. | No anonymous or ordinary-user audit browsing/mutation; Super Admin read follows approved limited purpose; authoritative history is not client-mutable. | Direct API results and state. Test commands separately. |
| 04-C | Perform a synthetic privileged mutation while causing the later audit write to fail. | Establish actual atomicity and user-visible behavior. If audited action is required, the system must not claim a complete audited action while its audit entry is absent. | Capture both states. H-C shows current client insert is best-effort/non-atomic; behavior still needs a test. |

### SEC-05 — Itinerary ownership and policy unions

Use Tourist A/B with separate synthetic itineraries. AP-22 gives no default Tourism Office access and limits Super Admin access to legitimate, controlled, audited need.

| Test ID | Operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 05-A | A/B SELECT own and cross-user itinerary IDs. | Tourists read own only; cross-user rows are hidden. Admin has no default plan access; exceptional Super Admin access requires approved purpose/control/audit. | Safe row counts/status; direct API required. |
| 05-B | Tourist A INSERT own itinerary, attempt B’s tourist_id, then UPDATE own tourist_id to B. | Approved own writes work; owner assignment/reassignment to another user is denied. | Read back synthetic owner values. Requires verified schema/policy. |
| 05-C | A UPDATE/DELETE B’s itinerary; B reads afterward. | Deny cross-user writes; B’s row remains unchanged. | Per-command request and read-back; zero-row response alone is insufficient. |
| 05-D | Exercise Admin/Super Admin paths under the explicit access decision and overlapping permissive policies. | Behavior matches approved scope; no accidental privilege from the broadest permissive clause. Evaluate USING and WITH CHECK separately. | Record role source and each command. Exceptional access policy decision is prerequisite. |

### SEC-06 — Itinerary-stop ownership and parent-child invariants

| Test ID | Operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 06-A | A reads/creates/updates/deletes a stop on A’s itinerary; repeat against B’s. | Own-parent operations work as approved; cross-parent access is denied. | API result and read-back as both users; valid FK fixtures required. |
| 06-B | A inserts stop under B’s itinerary, reparents A stop to B, changes any child owner field, or deletes B’s stop. | Child ownership cannot diverge from authenticated parent owner; cross-owner reparent/delete denied. | Check child/parent mapping after every request. |
| 06-C | Admin/Super Admin cases and the policy reporting NULL explicit with_check. | Match approved role scope. Verify actual implicit WITH CHECK behavior; catalog NULL is not an unconditional write grant. | Record policy catalog output separately from API results. Requires verified sessions and fixtures. |

### SEC-07 — Reservation role mismatch and ownership

| Test ID | Operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 07-A | Owner A with canonical test-schema role accesses its own establishment’s synthetic reservation. | Only operations approved for that establishment owner succeed. | Record role source, response, and establishment alias. H-A reports stored role vocabulary includes owner. |
| 07-B | Repeat with app literal establishment where schema permits; also test tourist. | Role-string equality alone never grants access to another owner’s establishment. Record invalid-literal constraint/policy result exactly. | Requires actual target schema; do not change production to create the case. |
| 07-C | Owner A reads/updates Owner B reservation, including status update by reservation ID without establishment filter. | Deny cross-establishment access; B’s row remains unchanged. | Direct API plus owner UI; verify as B. |

### SEC-08 — Existing reservation policy asymmetry

This section concerns establishment-side `public.reservations`, not AP-01 tourist-entered external reservation events.

| Test ID | Operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 08-A | Tourist A SELECT/INSERT own synthetic row, then cross-user SELECT/INSERT. | Only explicitly approved own-row booking behavior succeeds; cross-user access denied. | Record status and owner linkage. H-A reports tourist SELECT/INSERT; verify API and same-owner behavior. |
| 08-B | Tourist A UPDATE/DELETE own and another user’s rows. | Follow an explicit product decision. If not approved, deny both. Never infer row rights from SQL grants or tourist_id alone. | H-A lists no tourist UPDATE/DELETE policy; direct API/read-back and owner decision required. |
| 08-C | Owner A, Administrator, Super Administrator test each approved SELECT/UPDATE/DELETE scope, including foreign establishment rows. | Only approved command and scope succeeds. Role labels alone do not imply access. | Record per-role/command outcomes; role/owner policy matrix required. |

### SEC-09 — Duplicate reservation foreign keys and same-owner relationship

| Test ID | Operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 09-A | Privileged non-production catalog inspection of both constraint names, definitions, validation state, and dependencies. | Establish whether both reference itineraries and their delete action; make no schema change. | Sanitized catalog output/version. FKs do not prove same-owner equality. |
| 09-B | A reservation references Tourist A as tourist_id and Tourist B’s itinerary_id. | Deny mismatched ownership if required by approved invariant. | Record error and state. Requires an approved enforcement design; otherwise blocked. |
| 09-C | In disposable non-production transaction/fixture, test ON DELETE SET NULL for a synthetic itinerary. | Only the specified synthetic child link becomes NULL; no unrelated changes. Never drop/alter either FK. | Before/after synthetic state and rollback/reset. Explicit approval required for destructive test. |

### SEC-10 — Multiple establishments per owner (AP-24)

| Test ID | Operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 10-A | Under current non-production constraint, attempt a second synthetic establishment for Owner A. | Record whether current unique owner constraint rejects it; this documents incompatibility, not remediation. | Constraint response and no partial row. Isolated fixture only. |
| 10-B | Only after separately reviewed candidate schema supports AP-24, create two establishments for A and one for B; read/update independently. | A manages both own records independently and cannot access B; verification remains per-establishment. | Compare IDs, state and RLS results. Candidate schema work is a prerequisite. |
| 10-C | Exercise getMyEstablishment and both owner dashboards with multiple rows. | Must not silently choose a wrong establishment or fail because of maybeSingle; selection must be explicit. | UI/service test against candidate schema. Current code has singleton assumptions. |

### SEC-11 — Service-role security

| Test ID | Operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 11-A | Secret-safe scan of source, build outputs, browser bundles, source maps, client config, and logs for service-role credential material/names. | No service-role secret in client-accessible artifact/log. Never print a value; report only path/variable and exposure classification if found. | Scanner/version and paths, redacted. Source scan does not prove deployed bundle safety. |
| 11-B | Review test backend secret custody in approved platform controls without displaying values. | If a backend exists, secrets stay server-side and scoped. If absent, mark not configured/not run, not passed. | Record component and reviewer, never key value. |
| 11-C | Exercise each actual trusted operation with unauthenticated, unauthorized, and cross-owner requests, even if DB context bypasses RLS. | Backend explicitly authenticates/authorizes and scopes callers. BYPASSRLS is not authorization. | Requires actual test backend; otherwise not run. |

### SEC-12 — Profile role self-assignment

| Test ID | Operation | Expected behavior | Evidence and dependencies |
|---|---|---|---|
| 12-A | Tourist A sends direct PostgREST UPDATE changing own role to an elevated synthetic role; verify DB role and harmless protected test resource. | Deny role self-assignment and leave role unchanged. Do not rely on Flutter form omission. | Disposable account only. If it succeeds, stop privilege tests, isolate and tear down the project. |
| 12-B | Owner A tries assigning self or Tourist B administrator/super_admin. | Deny unauthorized assignment and cross-user update. | Direct API and state read-back through test setup identity. |
| 12-C | Super Admin uses role-management UI/service on a synthetic target; verify audit. Ordinary profile edit also updates allowed fields without role. | Permit only explicitly approved transitions; preserve trustworthy audit evidence and deny ordinary role assignment. | UI plus direct negative API tests. Resolve owner/establishment role vocabulary before setup. |

## F. Cross-cutting tests

| Test ID | Property | Procedure/evidence |
|---|---|---|
| X-01 | JWT/session identity | Verify Auth subject matches synthetic profile and intended role source for every request. Anonymous tests have no session. Redact JWTs; record aliases only. |
| X-02 | RLS and SQL privileges | Capture RLS enabled/forced and effective table/column/function privileges from a privileged non-production catalog session; separately test PostgREST. Grants do not prove rows; RLS is not column privacy and does not govern TRUNCATE. |
| X-03 | Policy composition | Capture roles, commands, permissive/restrictive mode, USING/WITH CHECK; verify OR/AND behavior via requests. Include NULL catalog with_check implicit behavior. |
| X-04 | Function EXECUTE | Inspect test function ACL/metadata and separately invoke the isolated equivalent per identity. EXECUTE grant does not prove function authorization. |
| X-05 | Parent-child ownership | Test parent and child independently for insert/update/delete/reparent; verify both rows. FK existence does not prove owner equality. |
| X-06 | Partial writes | Induce controlled later-step failure (e.g., audit write) and inspect earlier state; record transaction boundary and UI result. Sequential awaits do not establish atomicity. |
| X-07 | Audit evidence | Verify actor ties to request identity and client fields cannot impersonate another user. Retain only synthetic safe metadata. |
| X-08 | Role/command matrix | Exercise relevant identity against own, unrelated, invalid, missing references and SELECT/INSERT/UPDATE/DELETE separately. |
| X-09 | Regression/schema contract | Verify username login, own profile edit, role screen, owner reservation/payment, admin verification, planning preferences against the reviewed candidate schema. No itinerary persistence is implied. |

## G. Execution order and dependencies

1. **Environment gate:** confirm non-production URL, schema version, synthetic-only data, controlled outbound sinks, and reset capability. Abort if production.
2. **Catalog baseline:** capture test-project roles, RLS, policies, grants, function definitions/ACLs, and constraints. This is metadata evidence, not a behavior pass.
3. **Identity validation:** complete X-01. Stop if identity or role source is ambiguous.
4. **Priority isolation:** SEC-01, SEC-12, SEC-02 (only with isolated equivalent), SEC-04. If unexpected elevation succeeds, stop, isolate, preserve sanitized evidence, and do not continue privileged tests under that account.
5. **Tenant/parent authorization:** SEC-05/06 and SEC-07/08 plus X-03/X-05. Verify state after each operation.
6. **Privilege breadth:** SEC-03 CRUD by actual need; separately inspect structural privileges. Execute dangerous operations only in separately approved disposable schema.
7. **Integrity/AP-24:** SEC-09; SEC-10 current singleton constraint, then candidate multi-establishment behavior only after a separately reviewed candidate schema exists.
8. **Trusted backend:** SEC-11 only if actually configured; otherwise record not configured/not run.
9. **Flutter regression:** run app workflows after direct API tests using the same synthetic identities. UI checks do not replace API tests.
10. **Cleanup/closeout:** remove only run fixtures/accounts or reset the disposable project, verify cleanup, and produce sanitized results.

For unresolved policies (e.g., tourist cancellation or exceptional admin itinerary access), mark BLOCKED: decision required. Do not decide policy during test execution.

## H. Evidence and result-recording template

Record one entry per test:

```text
Run ID:
Test ID / SEC finding:
Date and non-production environment alias:
Schema/policy/function version:
Identity alias and verified Auth subject alias (never token):
Role source/setup reference:
Test layer: catalog | PostgREST | Flutter UI | trusted backend | privileged SQL session
Synthetic fixture aliases:
Operation/table/function (no secrets or private payload):
Expected result:
Observed status/error and redacted summary:
Before/after synthetic state check:
Audit evidence, if applicable:
Pass | Fail | Blocked | Not applicable | Not run:
Reason/dependency:
Artifacts retained and redaction check:
Cleanup/reset verification:
Reviewer:
```

Retain only evidence needed to reproduce results. Never record passwords, access/refresh tokens, anon/service keys, private rows, full profiles, or reservation notes. A sanitized request shape and status/error are sufficient for failed cases.

## I. Pass/fail and severity rules

- **Pass:** observed behavior matches written expected outcome; identity/layer are verified; post-operation state is checked; evidence is sanitized and reproducible.
- **Fail:** unauthorized data/access is obtained, protected row changes, trusted audit identity is forged, privileged action escapes scope, or an approved ownership/role rule is violated. Contain within disposable environment.
- **Blocked:** prerequisite schema/function/backend is absent, identity is ambiguous, policy decision unresolved, or isolated target lacks approval.
- **Not applicable:** component is confirmed unconfigured in the test scope, with evidence. “Not found in this repository” alone is not enough.
- **Not run:** no attempt occurred. Planned tests are never reported as passed.

Use H-B severity as review urgency, not proof of exploitation. A grant, UI guard, missing row, or successful own-user request does not establish behavior at another layer.

## J. Regression testing

After a separately authorized candidate security change, repeat relevant direct API tests and focused Flutter regressions:

1. Auth: username/email login, registration, management routing, OAuth callback, role loading/fallback.
2. Profile: own display name/username/phone update; Auth email/password behavior; two-factor setting only if mfa_email_enabled exists in candidate schema.
3. Roles: Super Admin user list/change, protected-role cases, canonical role vocabulary, audit evidence; ordinary profile edit must not gain role assignment.
4. Establishment: owner lookup, both dashboard implementations, own reservation/status/payment flows, cross-establishment denial; for AP-24 candidate schema, deliberate establishment selection and independent verification.
5. Tourism Office: destination activation/location verification, event reads, role-scoped writes and audit behavior.
6. Planning: in-memory manual draft, day assignment, explicit MO-GA invocation, results/review, unchanged CARS/MO-GA behavior. Do not infer persistence.
7. Privacy/API: repeat direct PostgREST negative cases; a hidden UI control is not authorization.

All integration tests use the isolated project and synthetic identities.

## K. Unresolved questions

1. Which fields belong in an approved public profile projection, and how should username login avoid disclosing email pre-auth?
2. Does mfa_email_enabled exist in deployed/test schema, and is it a profile preference or Auth security control?
3. Which roles may access itineraries/stops, including exceptional support access, and what same-owner parent-child invariant is required?
4. What tourist update/cancel/delete rights are approved for existing establishment reservations?
5. What canonical owner role is used across profile constraint, Flutter, and RLS?
6. Are there callers of admin_toggle_owner_verification outside this checkout, and what establishment-level operation is approved?
7. What trusted path derives authoritative audit actor/action, and what is the atomicity/failure requirement?
8. Which real backend operations need a privileged service context? Database role existence does not establish backend configuration.
9. Which deployment artifacts, CI settings, bundles, logs, and external apps are in scope for secret scanning?
10. What separately reviewed candidate schema enables AP-24, and how should both dashboards select among multiple establishments?
11. How will duplicate reservation FKs be traced and same-tourist integrity enforced without changing them in this plan?
12. Which schema/policy version should test environment represent given truncated H-A Query 2/3 and provisional Query 5?

## L. Readiness assessment

**Plan readiness:** suitable for staged isolated setup once prerequisites are met. **Execution readiness:** partial. Before running tests, the owner/security reviewer must identify a dedicated non-production project, confirm its schema/policy/function version, provision synthetic identities through a trusted setup, and resolve policy-dependent outcomes in Section K.

H-C documents direct anon-client calls, UI role guards, client-authored audit inserts, role-vocabulary mismatch, singleton establishment lookup, and in-memory planning. H-A/H-B metadata is not behavior verification. No test is claimed passed; this plan does not authorize production tests or object changes.

### Supplemental evidence-to-test crosswalk

Use the owner-supplied SUP evidence as catalog context for these existing test IDs. It is not a substitute for running them in an approved isolated environment:

| Finding / supplemental evidence | Existing H-D test IDs to associate | What remains a behavior test |
|---|---|---|
| SEC-01; SUP-01, SUP-04, SUP-06C1 | 01-A–01-D; X-02, X-03 | Anonymous and authenticated profile column exposure, own-row behavior, and role assignment paths. Only displayed-column privilege results are evidenced. |
| SEC-02; SUP-03, SUP-04, SUP-05, SUP-06R | 02-A–02-F; X-04 | NULL/unresolved-role denial, owner-wide effects/default creation characterization, candidate isolation, and execution scope. Never invoke production function. |
| SEC-03; SUP-05, SUP-06R, SUP-06C1/C2 | 03-A–03-C; X-02, X-08 | Per-command API/UI outcomes and any dangerous operation handling; grants do not prove PostgREST exposure. Do not execute TRUNCATE in ordinary fixtures. |
| SEC-04; SUP-01, SUP-03, SUP-04, SUP-05, SUP-06R | 04-A–04-C; X-06, X-07 | Forged audit payload acceptance, read/mutation boundaries, actor derivation, and write atomicity. |
| SEC-05/06; SUP-01, SUP-02, SUP-03, SUP-04, SUP-05, SUP-06R | 05-A–05-D; 06-A–06-C; X-03, X-05 | Policy union behavior by command, implicit `WITH CHECK`, cross-user parent access, and stop reparenting. |
| SEC-07/08; SUP-01, SUP-02, SUP-04, SUP-05, SUP-06R | 07-A–07-C; 08-A–08-C; X-05, X-08 | Owner literal mismatch effects, own/cross-establishment scope, and tourist UPDATE/DELETE outcomes under approved policy decisions. |
| SEC-09; SUP-02, SUP-03 | 09-A–09-C; X-05 | Catalog/dependency verification in test schema and synthetic FK effects; same-owner enforcement still requires an approved design. Never alter production FKs. |
| SEC-10 / AP-24; SUP-02, SUP-03, SUP-04, SUP-05, SUP-06R | 10-A–10-C; 02-F; X-09 | Current unique-constraint rejection and, only under separately approved candidate schema, multi-establishment isolation and dashboard selection. |
| SEC-11; SUP-05, SUP-06R, H-A Query 1 | 11-A–11-C; X-02 | Secret custody/artifact review and trusted-backend authorization. BYPASSRLS is a role capability, not evidence that credentials are deployed in a client. |
| SEC-12; SUP-01, SUP-04, SUP-05, SUP-06C1 | 12-A–12-C; X-01, X-03 | Self-assignment denial, authorized Super Admin transitions, and relevant column/RLS behavior. Effective SQL UPDATE privilege alone does not prove a successful role change. |

Record each case as BLOCKED or NOT RUN until setup authorization, baseline verification, and the case-specific prerequisites are satisfied. No supplied SUP result is a pass result.

## Completion record

- **Created:** `docs/TASK_09B_H_D_NON_PRODUCTION_AUTHORIZATION_VERIFICATION_PLAN.md`
- **Coverage:** Sections A–L; SEC-01 through SEC-12, cross-cutting cases, safety, sequencing, evidence template, and regression areas.
- **Files:** This new documentation file only; prior reports and existing working-tree changes are preserved.
- **Validation:** `git diff --check` result is recorded in the completion message.
- **Execution:** No authorization test was run. No production connection, SQL execution, source change, migration, or database object change was made.
