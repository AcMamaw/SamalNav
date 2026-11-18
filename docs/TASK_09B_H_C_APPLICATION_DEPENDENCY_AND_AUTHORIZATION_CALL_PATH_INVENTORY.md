# Task 09B-H-C — Application Dependency and Authorization Call-Path Inventory

**Status:** Read-only repository inventory. This report traces current Flutter-side call paths against the owner-supplied H-A catalog evidence summarized in H-B. It does not establish live API behavior, prove exploitability, or authorize remediation.

## A. Scope and evidence limitations

### Sources reviewed

- `docs/TASK_09B_H_B_PRODUCTION_SECURITY_FINDINGS_AND_REMEDIATION_DESIGN.md`
- `docs/TASK_09B_H_A_SECURITY_EVIDENCE_QUERY_PACK.md`
- `docs/TASK_09B_F_PRODUCTION_SCHEMA_AND_SECURITY_RECONCILIATION.md`
- `docs/TASK_09B_G_FINAL_RESERVATION_IMPLEMENTATION_READINESS.md`
- `docs/TASK_09B_E_RESERVATION_EVENT_TECHNICAL_CONTRACT_AND_RLS_SPECIFICATION.md`
- `docs/TASK_09B_D_APPROVED_RESERVATION_ACTIVITY_POLICY_BASELINE.md`
- Current application Dart files, relevant models, navigation, local migrations, and repository search results.

### Evidence labels

- **Confirmed in repository:** directly observed in checked-in application code or a local file. Local migrations are repository evidence only, not proof of deployed state.
- **Owner-supplied production evidence:** catalog results previously supplied by the project owner and recorded in H-B/F; not independently queried in this task.
- **Partially confirmed:** a call or contract is visible, but the complete behavior, schema compatibility, or caller set is not established.
- **Not found in searched repository:** no matching direct application call was found in the inspected code. This does not prove that no external client, dashboard, deployed function, or unsearched integration exists.
- **Requires runtime/non-production verification:** catalog and source review cannot establish actual PostgREST authorization outcomes, JWT role behavior, data effects, or route exposure.
- **Proposed future behavior only:** described by AP-01–AP-26 or Task 09B-E, but not implemented in the current application.

The H-A results are owner-supplied metadata. Query 2/3 excerpts were truncated. The original Query 5 recursive membership result is provisional due to its reporting flaw; do not infer that no membership paths exist. Query 1 separately confirms `service_role` has `BYPASSRLS=true`. H-A catalog evidence does not prove an endpoint is reachable, a policy was exploited, or an application operation succeeds. This task did not connect to Supabase or execute SQL.

## B. Repository structure and relevant modules

| Concern | Relevant modules and symbols | Observed responsibility |
|---|---|---|
| App/bootstrap and routing | `lib/main.dart` (`main`, `SamalNavApp.onGenerateRoute`); `lib/config/supabase_config.dart`; `lib/config/routes.dart` | Initializes Hive and Supabase; routes users to role-specific screens. The app client is initialized with the configured anon key. |
| Authentication and role lookup | `lib/screens/auth_screens/login_page.dart` (`_handleLogin`); `register_page.dart` (`_handleRegister`); `management_login_page.dart` (`_handleLogin`); `lib/services/role_service.dart` | Supabase Auth sign-in/sign-up, profile role lookup/upsert, and client-side navigation decisions. |
| Profile/preferences | `lib/screens/tourist_screens/profile_page.dart` (`_loadProfile`, `_saveProfile`, `_toggle2FA`); `lib/services/tourist_planning_profile_service.dart` (`fetchCurrent`, `createIfMissing`, `updateCurrent`); `lib/screens/tourist_screens/planning_preferences_page.dart` | Direct `profiles` profile editing and separate session-scoped `tourist_details` planning preferences. |
| Establishment operations | `lib/services/establishment_service.dart`; `lib/services/establishment_dashboard.dart`; `lib/screens/establishment_owner_screens/establishment_dashboard.dart` | Owner establishment lookup and establishment-side reservation/payment/review queries and actions. Two dashboard implementations call the same singleton lookup. |
| Tourism Office operations | `lib/services/administrator_service.dart`; `lib/screens/admin_screens/administrator_dashboard.dart` | Destination status and location-verification actions, aggregate counts, and event listing. |
| Super Administrator operations | `lib/services/super_admin_service.dart`; `lib/screens/admin_screens/super_admin_dashboard.dart` | Profile role listing and direct role updates, audit reads, maintenance settings. |
| Audit | `lib/services/audit_service.dart`; `lib/models/audit_log_record.dart` | Client-side audit insert and audit-log listing. |
| Tourist favorites | `lib/screens/tourist_screens/favorite_page.dart` | Direct `favorites` read/delete/insert. This table is outside the nine H-A relations enumerated by this task. |
| Planning/optimization | `lib/screens/tourist_screens/plan_page.dart`; `lib/models/itinerary_draft.dart`; `lib/algorithms/manual_selection_workflow.dart`; `lib/algorithms/manual_selection_moga_adapter.dart`; `lib/algorithms/moga_engine.dart` | Builds and optimizes in-memory drafts. Current plan page does not persist `itineraries` or `itinerary_stops`. |
| Cache | `lib/services/offline_cache_service.dart`; `lib/state/app_state.dart` | Hive JSON snapshots and in-memory route segments. Hive is local storage, not an outbox or cross-device synchronization service. |

## C. Supabase client and authentication architecture

**Confirmed in repository:** `lib/main.dart:15-25` calls `OfflineCacheService.initialize()` and `Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey)`. Services generally use `Supabase.instance.client`; `TouristPlanningProfileService` optionally accepts an injected `SupabaseClient` but defaults to the singleton client. No service-role credential or privileged server client was identified in application source. The configured key is the client anon key; this report intentionally does not reproduce credential values.

Email/password authentication is performed through Supabase Auth in `LoginPage._handleLogin`, `RegisterPage._handleRegister`, and `ManagementLoginPage._handleLogin`. Login also supports OAuth in `LoginPage` and account identity linking in `ProfilePage`. `RoleService.fetchCurrentUserRole()` then queries `profiles.role` for the current Auth user and falls back to user metadata on query failure/missing row, finally defaulting to tourist.

`RoleService.guardRoute()` and the role-specific dashboard checks are **client-side navigation guards**. They improve UI routing but do not enforce database authorization. Actual access depends on database grants, RLS, function checks, JWT/session state, and any trusted backend boundary. H-A reports broad table privileges and policies; actual requests and denials still require non-production tests.

**Not found in searched application repository:** `.rpc(...)`, `functions.invoke(...)`/Supabase Edge Function invocation, or a dedicated server-side Supabase client. A repository search for common service-role key variable names found no application source references. This is a bounded source search, not proof about deployment secrets, external services, build-time injection, or infrastructure outside the repository.

## D. Table-operation inventory

The matrix records actual client operations observed in `lib/`. It does not convert current grants into application requirements. “No direct call found” means no direct call was found in the searched Dart code.

| Deployed relation | SELECT | INSERT / UPSERT | UPDATE | DELETE | Call path / qualifications |
|---|---|---|---|---|---|
| `activities` | No direct call found | No direct call found | No direct call found | No direct call found | No end-to-end activity directory or publisher service call was found in the searched application code. Local migration declarations do not establish deployed/current use. |
| `audit_logs` | Yes | Yes | No direct call found | No direct call found | `AuditService.fetchLogs()` selects and orders recent rows; `SuperAdminService` exposes it to Super Admin activity/audit tabs. `AuditService.log()` inserts client-assembled rows. `getActionsTodayCount()` selects IDs by timestamp. |
| `establishments` | Yes | No direct call found in inspected client flow | No direct call found in inspected client flow | No direct call found | `EstablishmentService.getMyEstablishment()` selects by session `owner_id`; `AdministratorService.getReportStats()` reads `is_verified`. The flagged SECURITY DEFINER function has no Dart caller found. |
| `events` | Yes | No direct call found | No direct call found | No direct call found | `AdministratorService.getEvents()` selects events with `profiles(display_name)` for the Tourism Office dashboard; `getReportStats()` reads event IDs. No tourist event save/discovery/update operation found. |
| `itineraries` | No direct call found | No direct call found | No direct call found | No direct call found | The current planner/draft path is in memory. No direct persisted itinerary CRUD call was found in Dart. |
| `itinerary_stops` | No direct call found | No direct call found | No direct call found | No direct call found | No direct persisted stop CRUD call was found in Dart. |
| `notifications` | No direct call found | No direct call found | No direct call found | No direct call found | Home-page notification cards are local/static UI data; no notification table service was found. This does not establish whether external notification infrastructure exists. |
| `profiles` | Yes | Yes | Yes | No direct call found | Auth username lookup, role reads, tourist profile select/upsert, Super Admin user/role operations, and audit role attribution. See Section E/L. |
| `reservations` | Yes | No direct call found in inspected client flow | Yes | No direct call found | Establishment dashboard reads and status updates; Tourism Office reads IDs for counts. No tourist booking insert/update/cancel path was found in searched Dart. This is the existing establishment-side table, not the future tourist-entered external reservation feature. |

Other repository queries exist for `tourist_details`, `favorites`, `payments`, `reviews`, `location_verifications`, and `system_settings`; they are summarized where relevant. No CRUD operation for a table is assumed necessary merely because H-A reports a grant for it.

## E. Profile field dependency inventory (SEC-01)

| File / method | Requested or written fields | Caller / purpose | Privacy and compatibility notes |
|---|---|---|---|
| `lib/screens/auth_screens/login_page.dart:75-89`, `_handleLogin` | Pre-auth username lookup selects `email`, filters by `username`; then Auth password sign-in. | User can enter username instead of email. | This read occurs before the user has an authenticated session. Owner-supplied H-A says anon has effective SELECT on the listed profile columns and a permissive `USING true` policy. This is a direct dependency on the broad profile-read boundary; actual PostgREST behavior remains untested. |
| `lib/services/role_service.dart:24-51`, `fetchCurrentUserRole` | Selects only `role` for `.eq('id', user.id)`; metadata fallback; defaults to tourist. | Login and route guards. | The result drives UI navigation, not DB authorization. Supplied production role vocabulary and app enum disagree on owner value; see L. |
| `lib/services/role_service.dart:54-62`, `ensureTouristProfile` | Upserts `id`, `email`, `display_name`, and `role='tourist'`. | Called after client sign-up if an Auth user is returned. | Client writes the role field; the fact that this UI chooses tourist does not prove a trusted server-only assignment or DB protection. |
| `lib/screens/tourist_screens/profile_page.dart:87-127`, `_loadProfile` | Calls `.select()` (all selectable profile columns) for own `id`; consumes `display_name`, `username`, `phone`, and `mfa_email_enabled`; email is sourced from Auth. | Profile screen. | Broad `select()` requests more columns than the screen consumes. The supplied H-A effective profile SELECT list does not include `mfa_email_enabled`; production column availability is therefore unresolved against supplied evidence. |
| `lib/screens/tourist_screens/profile_page.dart:130-193`, `_saveProfile` | Upserts `id`, `display_name`, `username`, `phone`, `email`; does not include `role`. Password change uses Supabase Auth. | Tourist profile editing. | Ordinary profile-edit payload does not write role, but that is not a database protection against direct client requests. Email is also Auth identity data; consistency behavior was not tested here. |
| `profile_page.dart:282-298`, `_toggle2FA` | Updates `mfa_email_enabled` on `profiles`. | Email-code setting UI. | Depends on a column not listed in supplied H-A profile column inventory; verify schema and intended meaning before any grant/policy changes. |
| `lib/services/super_admin_service.dart:9-32`, role stats and `getAllUsers` | Selects all `role`; user list selects `id,email,display_name,role`. | Super Admin users/role screen. | Email and role are exposed to this client workflow; H-A reports current Super Admin route is UI-guarded, while database policies/grants determine actual rows. |
| `lib/services/super_admin_service.dart:46-49`, `updateUserRole` | Updates `profiles.role` by target `id`, then asks `AuditService` to log. | Super Admin role dialog. | Role change originates directly from the Flutter client; no RPC was found. Audit is best-effort and separate from the update, not atomic with it. |
| `lib/services/audit_service.dart:10-19`, `log` | Reads current user's `role`; inserts role plus `user_id`, `actor_id`, action/action_type, description, target_id. | Audit actor display for app operations. | Role and actor fields are client-assembled; not a trusted audit identity source solely because they are read from the current session/profile. |
| `lib/services/administrator_service.dart:77-81,111-114` | Event query embeds `profiles(display_name)`; the direct profile relation field requested is display name. | Tourism Office event list. | The query requires relation select visibility and policy behavior; only display name is explicitly requested here. |
| `lib/services/establishment_service.dart:72-94,107-109,127-129` | Reservation/payment/review queries embed `profiles(display_name)`. | Establishment dashboard list views. | Explicit display-name projection is narrower than `select('*')`, but the joined row's effective visibility and relationship policies require runtime checks. |

No direct application consumer of `profiles.preferences`, `budget`, `fcm_token`, `avatar_url`, or `profile_image_url` was found by the targeted `lib/` search. This is not a recommendation to expose them. H-A reports effective SELECT on all listed columns for anon/authenticated/service_role; H-B treats that as a priority potential exposure. `ProfilePage`'s broad select may retrieve additional columns even though it only consumes a subset.

## F. Function/RPC caller inventory (SEC-02)

**Target:** `public.admin_toggle_owner_verification(uuid, boolean)`.

**Not found in searched application repository:** no `.rpc()` call and no textual reference to the function name in `lib/`, tests, or the local migration files searched. No Flutter service/screen caller, RPC arguments, result mapping, or error handling can therefore be documented. The Tourism Office verification flow in `lib/services/administrator_service.dart:42-73` is a separate direct-table path: approve/reject `location_verifications`, insert an approved `destinations` record for approval, and call the client `AuditService`. It does not call the owner-verification function.

Owner-supplied H-A/H-B evidence says the function is SECURITY DEFINER, owned by postgres, has `search_path=public`, is executable by PUBLIC/effectively anon, authenticated, and service_role, and contains a NULL-sensitive `caller_role NOT IN (...)` authorization condition as well as owner-wide establishment update/default creation behavior. The app search did not find a caller; this does not prove the function has no callers from SQL, REST/RPC clients outside this repository, dashboards, or other deployed services. No behavior or function execution was tested. Preserve the H-B authorization concern and do not infer that app absence mitigates database exposure.

## G. Itinerary and itinerary-stop ownership call paths (SEC-05/06)

**Confirmed in repository:** `lib/screens/tourist_screens/plan_page.dart` creates and edits a typed `ItineraryDraft`, carries stable destination UUIDs/day assignment through `ManualSelectionDraftBuilder`, and explicitly transitions the draft through `readyForOptimization`, `optimizing`, results, and review before invoking `ManualSelectionMogaAdapter`. The adapter maps draft destination UUIDs to engine-local indices and maps results back. The resulting state is used by planner/results UI; it is not written to `itineraries` or `itinerary_stops` in the inspected Dart code. `PlanResultsPage`, `HistoryPage`, and `AppState` do not establish server persistence or cross-device access in the reviewed path. Hive snapshots in `OfflineCacheService` are device-local and have no outbox, synchronization loop, version conflict handling, or server itinerary CRUD.

**Not found in searched repository:** direct SELECT/INSERT/UPDATE/DELETE calls to `itineraries` or `itinerary_stops`; client payloads for `tourist_id`/`itinerary_id`; a cross-user administrator itinerary workflow; or a path that changes either ownership field. Therefore there is no current application call path from which to establish whether the client supplies owner IDs, checks parent ownership before stop operations, or can reparent a stop.

**Owner-supplied evidence:** H-A reports permissive itinerary and stop policies, including an administrator/super-admin branch in a parent predicate and a NULL catalog `with_check` for one ALL policy; H-B explains policy combination and implicit WITH CHECK semantics. This repository inventory neither replaces nor strengthens that evidence. Since the current app does not call these relations, validate the deployed API/policies in a controlled non-production environment before introducing persistence. Do not claim application checks replace RLS.

## H. Existing reservation call paths (SEC-07/08/09)

### Establishment-side workflow

`lib/services/establishment_service.dart` is the direct client service:

- `getOverviewStats(establishmentId)` selects reservation `id`, `reservation_status`, `eta` by `establishment_id`; computes visitor/booking counts client-side.
- `getArrivalAlerts(establishmentId)` selects confirmed future rows for that establishment and embeds `profiles(display_name)`.
- `getReservations(establishmentId)` selects rows for the establishment and embeds only profile display name.
- `updateReservationStatus(reservationId,status)` updates by reservation `id` and then calls `AuditService.log`; the client query itself does not add an `establishment_id` predicate. Row authorization is therefore dependent on deployed RLS and should be tested with own/cross-establishment IDs.
- `AdministratorService.getReportStats()` selects reservation IDs for a count; no admin reservation detail/update path was found in that service.

Both establishment dashboard implementations call `getMyEstablishment()` and use its returned ID to call these methods. The application’s service-level filters are useful query scoping but not a replacement for RLS.

### Tourist workflow and deployed policy comparison

**Not found in searched Dart code:** a tourist reservation INSERT, update, cancellation, or DELETE path to `public.reservations`. No claim is made that tourists cannot use another client or an unsearched external path. H-A/H-B owner-supplied evidence reports tourist-scoped SELECT and INSERT policies, no tourist UPDATE/DELETE policy in the supplied inventory, and broad SQL relation grants. The intended tourist cancellation/edit workflow remains a policy question/runtime verification item, not a current observed app feature.

This table is the existing establishment-side reservation workflow. It must remain distinct from AP-01–AP-26 tourist-entered information about external arrangements; that future information must not reuse `public.reservations`.

### Role vocabulary

`lib/models/app_role.dart:8-19,35-50` emits owner role value `establishment`; it parses several establishment aliases. Owner-supplied H-A/H-B production evidence says the profile role constraint uses `owner`, while the reservation INSERT policy tests `establishment`. This mismatch is confirmed between repository and supplied evidence. Actual owner policy outcomes require non-production tests; changing the string alone would not establish ownership of the referenced establishment.

### Duplicate itinerary foreign keys

Repository search found no application reference to `reservations_itinerary_fk` or `reservations_itinerary_id_fkey`; no local migration reference to either exact name was found. H-A I-3 evidence, as reconciled in H-B/G, confirms both deployed constraints from `reservations.itinerary_id` to `itineraries(id)` with `ON DELETE SET NULL`. Their origin, necessity, dependencies, and remediation remain unverified. The independent references do not enforce same-tourist ownership; do not drop or modify either constraint based on application search alone.

## I. Audit-log writer and reader inventory (SEC-04)

### Writer

`lib/services/audit_service.dart:8-33`, `AuditService.log(action,description,{targetId})`, runs in the Flutter client. It reads `Supabase.auth.currentUser`; if present it separately selects `profiles.role` for that user. It then inserts client-assembled `user_id`, `actor_id`, `role` (profile value or tourist fallback), `action`, `action_type`, `description`, and optional `target_id` into `audit_logs`. It catches every error and returns without surfacing failure. Thus audit entries are non-blocking/best-effort, and the privileged mutation and audit insert are not atomic.

Observed callers:

- `LoginPage._handleLogin` and `ManagementLoginPage._handleLogin`: login labels/actions.
- `AdministratorService.setDestinationActive`, `approveVerification`, `rejectVerification`: destination/location verification actions.
- `EstablishmentService.updateReservationStatus`, `markPaymentPaid`: owner reservation/payment actions.
- `SuperAdminService.updateUserRole`, `setMaintenanceMode`: role and maintenance actions.

The writer accepts action text/description/target from application callers. A caller can supply IDs/descriptions and the role is read by a separate client query; this is not equivalent to a trusted server deriving the authoritative actor/role/action. The current ordinary profile edit does not call this writer for role changes; the Super Admin role update calls it after direct role UPDATE. H-A reports authenticated INSERT `WITH CHECK true` and broad table privileges; exact accepted columns and other constraints/triggers are not behavior-tested.

### Readers

- `AuditService.fetchLogs(limit)` selects audit rows ordered newest-first and limits results; it has no client-side user filter.
- `SuperAdminService.getRecentActivity()` and `getAuditLogs()` delegate to that method; the Super Admin dashboard calls recent activity and the audit tab reads logs.
- `SuperAdminService.getActionsTodayCount()` selects IDs from `audit_logs` since local date start and counts the returned rows client-side.

The UI’s Super Admin route guard is not the data boundary. H-A reports a Super Admin SELECT policy; actual RLS enforcement/API behavior and whether the broad SQL grant is safely constrained were not exercised. `AuditLogRecord` can parse joined/profile identity fields, but the current `fetchLogs()` query is bare `.select()` rather than an explicit profile embedding; email enrichment should not be assumed from that call.

## J. Establishment-owner and AP-24 compatibility inventory (SEC-10)

**Confirmed in repository:** `EstablishmentService.getMyEstablishment()` obtains `auth.currentUser?.id`, selects establishments filtered by `owner_id`, and calls `maybeSingle()` (`lib/services/establishment_service.dart:10-23`). Both `lib/services/establishment_dashboard.dart` and `lib/screens/establishment_owner_screens/establishment_dashboard.dart` call it and keep a single `Establishment?`; their detail/stat/reservation/payment/review requests use that single establishment ID. This assumes one result at the UI/service boundary.

**Owner-supplied production evidence:** `establishments_owner_id_key` is a unique index on `owner_id`, which currently enforces at most one row per owner. It conflicts with AP-24’s approved one-owner-to-many-establishments rule. Removing uniqueness alone is insufficient: both dashboards, singleton `maybeSingle()` service, all establishment-specific queries/actions, owner verification function behavior, RLS owner predicates, and future creation/edit/selection flows must be reviewed. No client establishment creation or editing call was found in the searched code. The Tourism Office destination-verification flow creates a destination, not an establishment.

**Not found in searched application repository:** activity management by establishment, multi-establishment selector, owner creation workflow, or call to `admin_toggle_owner_verification`. The presence/absence of server-side workflows and deployed function callers needs separate evidence. No AP-24 change is part of this report.

## K. Service-role and privileged backend usage review (SEC-11)

**Repository search result:** no `service_role`, `serviceRoleKey`, `SUPABASE_SERVICE_ROLE`, or `service_role_key` reference was found in application source. The only matching service-role references found in the repository-wide filename search were security/design documentation. No privileged server client, `functions.invoke`, Edge Function caller, or RPC caller was found in the searched app code. `lib/main.dart` initializes the Supabase Flutter client with the configured anon key only. No credential values are reproduced here.

This does not prove that hosting secrets, CI/CD variables, an external backend, or deployed Edge Functions do not exist. H-A Query 1 separately confirms `service_role` has `BYPASSRLS=true`; that is a database role capability, not evidence the key is in the app. Any future privileged backend must keep its secret server-side and add explicit scoped authorization; a bypassing service role is not a substitute for authorization.

## L. Profile role assignment and update workflow (SEC-12)

1. **Signup:** `RegisterPage._handleRegister()` sends Auth user metadata `{display_name, role: AppRole.tourist.value}` to `auth.signUp`. If Supabase returns a user, it calls `RoleService.ensureTouristProfile(userId,email,displayName)`, which client-upserts `profiles.id`, email, display name, and `role='tourist'`.
2. **Login/route:** `RoleService.fetchCurrentUserRole()` reads the current profile role and, when missing/error, can use Auth `userMetadata.role`; it defaults to tourist otherwise. `guardRoute()` redirects in the Flutter app. Management login logs out a role that resolves to tourist. These are UI decisions, not server authorization.
3. **Ordinary profile edit:** `ProfilePage._saveProfile()` upserts id, display name, username, phone, email; the payload does not include `role`. It does not establish that a client cannot send a different role through PostgREST.
4. **Super Admin role workflow:** `SuperAdminDashboard` presents a role choice; `SuperAdminService.updateUserRole(userId,role)` directly updates `profiles.role` by ID from the client, then attempts a separate audit insert. The UI route guard is not the authorization boundary.
5. **Vocabulary mismatch:** `AppRole.establishmentOwner.value` is `establishment`; H-A/H-B supplied profile role constraint allows `owner`, not `establishment`. The app’s role counters also count `establishment`. Production role initialization/change success and all permitted role transitions require non-production testing.

H-A/H-B confirms an own-row profile UPDATE policy and broad UPDATE grant, while the policy itself does not express a role-column restriction. This creates the documented self-assignment concern, but this source review cannot establish whether column grants, triggers, constraints, or other server protections block it. Signup hardcoding `tourist` and profile-edit omission of `role` are not database safeguards. Do not claim that self-escalation succeeded or that the role cannot be changed.

## M. Future reservation-event architecture dependencies

These are future requirements under AP-01–AP-26 and Task 09B-E, not current application functionality.

| Future need | Existing structure found | Gap/dependency |
|---|---|---|
| Server itinerary draft identity and cross-device continuation | In-memory `ItineraryDraft`; local Hive snapshot utility | No `itineraries`/`itinerary_stops` client persistence; no server draft identity/version or synchronization. AP-01 needs a new reviewed persistence/RLS design. |
| Event child ownership | No tourist-entered reservation-event model/service/table call found | Must derive owner from authenticated draft parent and enforce parent/child ownership; do not reuse `public.reservations`. |
| Appointment/accommodation timing | Existing reservation records use establishment-side `eta`; no draft event timing model | Separate timed appointments, date-only accommodation stays, Asia/Manila semantics, supplied/derived timing provenance, incomplete state, and interval feasibility need new contracts. |
| Activities/events | Admin reads deployed `events`; no tourist event reference or full activity directory workflow found | Verify deployed schemas and publisher ownership; retain source/version snapshots. Existing establishment `activities` calls were not found. |
| Notifications | Static home-page notification examples; no `notifications` data service | In-app notification persistence, recipient isolation, deduplication/read state, and optional push are future work. |
| Audit | Current client-side best-effort audit writer/reader | Future publishing, schedule updates, exceptional access, and destructive actions need trusted actor derivation, privacy minimization, and audited access. |
| Re-optimization | Existing MO-GA optimizes destination sequences only | It does not model fixed events, overnight locations, or accommodation. Future scheduling must preserve MO-GA’s three objectives and require tourist approval for proposals; no self-healing implementation was found. |
| Deletion/retention | No persisted draft/event lifecycle in the planner | AP-21/AP-26 retention, deletion confirmation, child behavior, and “does not cancel external booking” UX must be designed before persistence. |

No automatic persistence, offline sync, or background synchronization is established by the current Hive cache. The future contract should preserve all three planning methods; CARS remains exclusive to System-Generated Planning; fixed events remain constraints, not MO-GA genes/objectives.

## N. SEC-01 through SEC-12 application dependency matrix

| Finding | Repository dependency/call path | Assessment and evidence boundary |
|---|---|---|
| SEC-01 Profile privacy | Username pre-auth lookup; profile `select()` and edit; role reads; admin user list; `profiles(display_name)` embeds; planning profile is separate `tourist_details`. | **Confirmed dependency.** Broad profile SELECT is used in ProfilePage and anon lookup requests email. H-A confirms effective SELECT for listed profile columns/roles; API exposure is untested. No direct code use found for preferences/budget/FCM token. |
| SEC-02 SECURITY DEFINER RPC | Search of app and local SQL found no caller for `admin_toggle_owner_verification`; admin location verification is a separate direct-table flow. | **Not found in searched repository.** Function remains a database security concern per H-A/H-B, independent of app call absence. External callers/runtime reachability unresolved. |
| SEC-03 Broad relation privileges | Actual client operation inventory in Section D; no app use found for many available privileges, including relation TRUNCATE/REFERENCES/TRIGGER. | **Partially confirmed.** Calls are known; least privilege cannot be derived from grants alone. Trace backend/admin tooling and test before changes. |
| SEC-04 Audit integrity | `AuditService.log` reads role and client-inserts actor/action fields; multiple screens/services call it; Super Admin reads logs. | **Confirmed client writer/reader path.** H-A confirms permissive authenticated INSERT and Super Admin read policy; other DB constraints/triggers and effective API outcomes remain unverified. |
| SEC-05 Itinerary RLS | Draft construction/optimization is local; no direct `itineraries` access found. | **No current database call found.** H-A policy unions still require behavior tests before any future persistence. |
| SEC-06 Stop RLS | No direct `itinerary_stops` call found; no owner IDs/parent changes in a persistence payload. | **No current database call found.** Parent-child authorization is a future persistence prerequisite; policy semantics are not settled by this source inventory. |
| SEC-07 Reservation role mismatch | Owner dashboard reads/updates reservations; app role emits `establishment`; supplied DB role constraint uses `owner`; supplied policy checks `establishment`. | **Confirmed mismatch, runtime effect pending.** Do not repair by literal replacement without owner-establishment checks. |
| SEC-08 Reservation policy asymmetry | App reads and owner status-updates; Tourism Office count only; tourist CRUD not found. | **Partially confirmed.** H-A policy/grant evidence is supplied; actual tourist/owner/Admin outcomes and intended cancellation rules need non-production tests/decisions. |
| SEC-09 Duplicate FK | No exact constraint-name reference in application/local migration search. | **No repository dependency found.** Duplicate deployed FK confirmed by supplied I-3 evidence; provenance, database dependencies and remediation remain separate review. |
| SEC-10 AP-24 multiple establishments | `getMyEstablishment()` filters `owner_id` and `maybeSingle`; two dashboards store one establishment; no create/edit/multi-selector found. | **Confirmed incompatibility.** Supplied owner unique index enforces current one-row contract. Service, dashboards, verification function, RLS and workflows need coordinated review. |
| SEC-11 Service role | App initializes anon client; no service-role key/client/RPC/Edge Function reference found in searched source. | **No client usage found; external infrastructure unknown.** H-A confirms DB `service_role` BYPASSRLS; do not equate role existence with client key exposure. |
| SEC-12 Profile role self-assignment | Signup metadata and profile upsert submit tourist role; normal profile edit omits role; Super Admin client directly updates target role. | **Confirmed client behavior; DB protection unresolved.** H-A own-row policy/grant and H-B risk warrant non-production verification. No successful escalation is claimed. |

## O. Missing evidence and unresolved questions

1. **Actual non-production authorization outcomes:** anon username lookup, public/profile column access, each role’s reads/writes, direct RPC execution, profile role self-update, reservation owner scope, audit forgery, and policy unions have not been exercised.
2. **Complete grants:** H-A Query 2/3 excerpts were truncated. Query 4/10 give effective checks for listed profile columns and named relations, but not every explicit ACL grant or other object.
3. **Membership paths:** the earlier Query 5 no-rows output is provisional pending corrected-query confirmation. Do not use it to infer there are no inherited memberships.
4. **Schema compatibility:** `mfa_email_enabled` is used in ProfilePage but absent from the supplied H-A profile-column list; confirm deployed column existence and intended policy. `tourist_details` policies/privileges and actual service success are outside the nine-table H-A matrix in this report.
5. **External callers/configuration:** the repository search cannot rule out deployed Edge Functions, other apps, dashboards, scripts, CI secrets, SQL clients, or server code outside this checkout. No credentials are requested or exposed.
6. **Function origin and dependencies:** no app caller found for `admin_toggle_owner_verification`; identify other callers before changing its EXECUTE ACL or body. Its NULL-role behavior and broad effects remain as reported in H-B.
7. **Existing reservations policy intent:** decide tourist update/cancellation requirements; test owner reads/status changes against foreign establishment IDs; resolve role literal and same-owner itinerary invariant separately.
8. **Audit authenticity:** identify whether triggers, defaults, constraints, or trusted jobs constrain submitted actor/role/action fields. H-A catalog policy alone does not answer this.
9. **AP-24 complete impact:** inspect every deployed owner-scoped query, `maybeSingle()` assumption outside current Dart search, function, policy, and establishment creation/management path before any owner uniqueness change.
10. **Future itinerary/event persistence:** no current application call path can establish future draft/event ownership, atomic promotion, version conflicts, retention, or cross-device behavior. These remain proposed design only.

## P. Recommended order for subsequent security design work

1. Preserve this call-path baseline and complete a source-to-operation inventory for any backend, dashboard, SQL client, or deployment code outside this repository.
2. Build a controlled non-production test matrix for SEC-01, SEC-02, SEC-04, SEC-05/06, SEC-07/08, and SEC-12. Use synthetic identities/data; test both direct PostgREST and applicable UI flows. Do not use production records.
3. Trace all profile consumers and confirm `mfa_email_enabled` schema status; define the public projection/private profile boundary before considering grant changes.
4. Trace audit dependencies and decide trusted actor derivation and whether audit writes must be atomic with privileged mutations.
5. Inventory all callers of both SECURITY DEFINER functions outside the app checkout; verify membership evidence and the NULL/missing-profile cases in non-production.
6. Resolve reservation operation intent, owner-role vocabulary, same-owner integrity, and duplicate-FK provenance before designing any change to existing `public.reservations`.
7. Treat AP-24 as its own compatibility effort across schema, service queries, both owner dashboards, verification, RLS, and establishment lifecycle. Do not remove the unique index alone.
8. Only after evidence and owner decisions, produce narrowly scoped security changes with regression tests and explicit rollback/verification criteria. Keep the future AP-01–AP-26 event feature separate from existing establishment reservations.

## Q. Implementation readiness assessment

**Application dependency inventory: complete for the searched Flutter client paths; security remediation readiness: not established.** The principal table operations and their client callers are documented above. Current code shows direct anon-client database operations, UI role guards, client-side audit insertion, a one-establishment lookup assumption, and in-memory itinerary planning. It does not show a caller for the flagged SECURITY DEFINER RPC, direct itinerary persistence, an activity/notification client service, an Edge Function invocation, or service-role key use.

These findings are not proof of production exploitability or absence of external callers. Before changing grants, RLS, function ACLs, role fields, reservation policy, or establishment uniqueness, complete the missing external caller/dependency inventory and non-production authorization tests in Section O. No remediation, migration, or production change is authorized by this report. AP-01 through AP-26 and the six CARS criteria/three MO-GA objectives remain unchanged.

## Completion record

- **Created:** `docs/TASK_09B_H_C_APPLICATION_DEPENDENCY_AND_AUTHORIZATION_CALL_PATH_INVENTORY.md`
- **Coverage:** Sections A–Q; repository call paths and owner-supplied H-A/H-B evidence are labeled separately.
- **Files:** This report is the only file created by this task. Existing modified and untracked files were preserved.
- **Database/code:** No source code, SQL, migration, Supabase connection, query, or database object/data was changed or accessed.
- **Verification:** `git diff --check` passed.
