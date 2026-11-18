# Task 09B-H-J — Production Security Evidence Reconciliation and Gap Assessment

**Status:** Documentation-only reconciliation of the project owner's manually collected production catalog results. The evidence below is owner-reported; it was not independently queried or verified by the coding agent. It records neither non-production test results nor remediation.

## 1. Executive summary

The supplied evidence materially advances the production catalog inventory, but it is not sufficient to conclude how PostgREST requests behave or authorize non-production setup. The project owner has now supplied SUP-01 through SUP-06C2 results in addition to the earlier H-I output. The SUP results cover column metadata, indexes/constraints, triggers, policies, stored relation ACLs, effective schema/relation privileges, and effective column privileges. The detailed status and limitations are recorded in Section 3.1 and the Task 09B-H-M report. These are owner-reported catalog observations, not independently verified live results or behavior tests.

Confirmed structural observations include the duplicate reservations-to-itineraries foreign keys, the unique establishment owner constraint, the profile role constraint/reference, and multiple overlapping permissive RLS policies. The function definition and EXECUTE results retain the SEC-02 NULL-role authorization concern. These are production observations reported by the owner, not findings reproduced in non-production and not proof of exploitable API behavior.

The most important remaining reproduction blockers are complete column definitions where SUP-01 output remains incomplete, complete trigger inventory where output coverage is uncertain, exact policy rows/expressions for faithful reproduction, and approved decisions about current-behavior versus candidate testing. SUP-02 and SUP-05/06R now supply index/constraint and relation privilege evidence for their reported scopes; do not repeat those as wholly missing. H-G remains an approval gate: this report does not authorize setup, Auth users, fixtures, SQL execution, or remediation.

## 2. Evidence provenance and interpretation

### Sources and boundaries

- The project owner reports manually executing the Task 09B-H-I queries in the production Supabase SQL Editor and supplying the results summarized in the task request.
- The latest owner-supplied outputs are labeled Query 02 (indexes and constraints), Query 03 (triggers), and Query 05 (RLS). For H-I pack references, owner Query 02 maps to H-I Queries 02 and 03; owner Query 03 maps to H-I Query 04; owner Query 05 maps to H-I Query 05. Preserve the owner's numbering when referring to those supplied outputs.
- The coding agent did not connect to production or non-production, execute SQL, or inspect application rows for this report.
- Query numbers in this report refer to `supabase/non_production/evidence/001_production_schema_evidence.sql`. Do not conflate them with the earlier H-A query numbering used in H-B.
- “Complete” means the owner reports results supplied for that query. It does not mean independently validated, unrestricted catalog visibility, or that every summarized detail is reproduced verbatim here.
- A catalog privilege result is not an RLS or API behavior test. A policy definition is not a request result. SECURITY DEFINER metadata and EXECUTE privilege are not evidence that a function was invoked or exploited.
- “No rows” means the query reportedly executed successfully and returned no rows for its filters. It does not prove global absence of matching objects.

### Status meanings

| Status | Meaning in this report |
|---|---|
| **COMPLETE** | Results were supplied and not described as partial; conclusions remain limited to the query's scope and the supplied summary. |
| **PARTIAL** | Some results were supplied, but the output or requested coverage is explicitly incomplete. |
| **NO ROWS** | The query reportedly executed successfully and returned no rows for its stated filters. |
| **NOT CONFIRMED** | No result is available in the current evidence record; execution is not inferred either way. |

## 3. Query-by-query evidence matrix

| Query | Status | Owner-reported result and supported interpretation | Limitations / reproduction consequence |
|---|---|---|---|
| **01 — Columns and type metadata** | **PARTIAL** | Results were supplied for `activities`, `audit_logs`, `destinations`, `establishments`, `events`, `itineraries`, `itinerary_stops`, and `notifications`. Fields reported include `activities.price`, `destinations.entrance_fee`, destination rating fields, `itineraries.total_cost`, and reservation-related identifiers. | Some ordinal positions are missing in the pasted `destinations` and `establishments` output. No result is reported here for `profiles` or `reservations`. Missing output is not evidence that a column or table is absent. Exact types, defaults, nullability, and complete column order remain blockers for those objects. |
| **02 — Constraints** | **OWNER-SUPPLIED** | Newly supplied owner Query 02 reports `reservations_itinerary_fk` and `reservations_itinerary_id_fkey`, both from `reservations.itinerary_id` to `itineraries.id` with `ON DELETE SET NULL`; `profiles.role` references `roles(name)`; `tourist_profiles_user_id_fkey` and `tourist_profiles_user_id_fkey1` reference `profiles(id)` with `ON DELETE CASCADE`; and unique `establishments.owner_id`. Earlier H-I constraint output reported the returned constraints as validated and non-deferrable. | The supplied outputs confirm these reported objects; do not infer omitted constraints. The duplicate FK origin, necessity, dependencies, and safe remediation remain unverified. Independent FKs do not prove a same-tourist ownership invariant. |
| **03 — Indexes** | **OWNER-SUPPLIED** | Newly supplied owner Query 02 reports index records including `establishments_owner_id_key`, enforcing uniqueness on `establishments.owner_id`. Supplied index records have `is_valid`, `is_ready`, and `is_live` all true. | Supersedes the former NOT CONFIRMED status for the supplied index evidence. Completeness is limited to the supplied output. The AP-24 conflict remains; this report does not recommend or implement a production change. |
| **04 — Triggers** | **OWNER-SUPPLIED (COMPLETENESS UNCONFIRMED)** | Newly supplied owner Query 03 confirms application triggers `activities.set_activities_updated_at` and `destinations.destinations_updated_at`, both referencing `public.set_updated_at()`. The supplied function behavior sets `NEW.updated_at = now()` and returns `NEW`. `RI_ConstraintTrigger_*` entries are PostgreSQL internal referential-integrity triggers. | Updates the former PARTIAL status to owner-supplied, but completeness of the target-relation trigger inventory and all trigger definitions/states is not established. RI triggers are not ordinary application triggers and must not be manually recreated. |

| **06 — Schema ACL** | **COMPLETE** | Supplied result reports `USAGE` on `public` for `anon` and `authenticated`, with no `CREATE` for those roles in the supplied public-schema ACL. Supabase-managed schema ACL entries also appeared. | Schema `USAGE` does not grant access to every relation or column. This is schema-level privilege evidence only; relation privileges and RLS are separate. |
| **07 — Relation ACL** | **PARTIAL** | Visible stored ACL grants for `anon` and `authenticated` were reported on `public.activities`, `public.audit_logs`, and `public.destinations`; visible privileges included SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, and MAINTAIN. Output began `public.establishments` and ended before completion. | Do not extrapolate the visible grants to establishments' complete ACL or any other relation/role. Complete relation ACL evidence is still needed for reproduction. A stored grant is not proof an RLS-protected row operation succeeds. |
| **08 — Column ACL** | **NO ROWS** | The query reportedly executed successfully and returned no explicit column-level ACL entries matching its filters. | This does not negate table-level grants, establish effective denial, or prove absence outside the query filters/catalog visibility. |
| **09 — Sequence ACL and ownership** | **COMPLETE** | One sequence was reported: `auth.refresh_tokens_id_seq`, owned by `supabase_auth_admin`, automatically associated with `auth.refresh_tokens.id`; grants shown for `dashboard_user`, `postgres`, and `supabase_auth_admin`. No application-role grants appeared in the supplied result. | Preserve query scope. This does not establish that no other sequences exist outside the filters or visible catalog. This sequence may be outside the minimal application reproduction set; dependency and scope must be reviewed before inclusion. |
| **10 — Effective privileges** | **PARTIAL** | Visible rows report `anon` effective INSERT, REFERENCES, SELECT, and UPDATE privileges on displayed columns of `public.activities` and `public.audit_logs`; output ended at `audit_logs.ip_address`. | Results for other roles, relations, and remaining columns are unavailable. Do not use this partial Query 10 output to claim effective privileges across all H-G relations or all roles. Effective SQL privileges still do not establish RLS row access or PostgREST behavior. |
| **11 — Function definitions** | **COMPLETE** | Supplied definitions report `admin_toggle_owner_verification(uuid,boolean)` as SECURITY DEFINER, postgres-owned, `search_path=public`, reading the caller's profile role with a nullable `NOT IN` guard, updating all establishments for the supplied owner or inserting a default establishment when none exists. `current_user_role()` is SECURITY DEFINER, postgres-owned, STABLE, `search_path=public`, and returns profile role or `tourist`. `set_updated_at()` is not SECURITY DEFINER. `auth.uid()` is identified as the Supabase helper. Five internal RI_FKey trigger functions also appeared. | The NULL-role case remains an authorization concern: SQL NULL in the `NOT IN` condition does not make a PL/pgSQL IF condition true, so the exception branch may not be entered. Owner-wide mutation/default creation are characterization behaviors, not security passes. Internal RI_FKey functions are not application functions. No function was invoked. |
| **12 — Function EXECUTE privileges** | **COMPLETE** | Supplied results report effective EXECUTE for `anon`, `authenticated`, and `service_role` on `admin_toggle_owner_verification(uuid,boolean)`, `current_user_role()`, and `set_updated_at()`; `auth.uid()` was executable by selected roles. Internal RI_FKey functions also appeared. | Function EXECUTE plus SECURITY DEFINER metadata elevates SEC-02 review priority but does not prove an API route is exposed or that an authorization bypass succeeded. Internal trigger-function entries should not be treated as ordinary application-callable routines. |
| **13 — Role memberships** | **COMPLETE** | ROOT_STATUS rows were supplied for `anon`, `authenticated`, and `service_role`; no membership paths were visible from those roots. | The query itself cautions that no visible paths do not prove global absence of membership edges. Catalog visibility and root-role visibility still qualify interpretation. This result does not calculate all effective privileges. |
| **14 — Catalog dependencies** | **COMPLETE** | Supplied dependencies confirm both reservation-to-itinerary FKs and the establishment owner uniqueness relationship. They also show distinct `audit_logs.actor_id` and `audit_logs.user_id` FKs to profiles; separate `tourist_details.user_id` and `tourist_profiles.user_id` relationships; and other FK, check-constraint, and default-value dependencies. | Dependency records do not prove runtime call paths or all dynamic SQL dependencies. Separate user relationships must not be collapsed into one assumed profile contract. |
| **15 — Custom types** | **NO ROWS** | The query reportedly executed successfully and returned no custom types matching its filters. | This does not prove PostgreSQL has no custom types; it is limited to target-column traversal, catalog visibility, and the query's filters. |

### 3.1 Supplemental pack status (SUP-01–SUP-06C2)

The project owner supplied production SQL Editor results for the supplemental statements in `supabase/non_production/evidence/002_supplemental_production_catalog_evidence.sql`. The coding agent did not execute these statements. The supplied result summaries do not include every raw row in this report; findings below are limited to the stated output.

| Supplement | Status | Owner-supplied evidence | Limitation |
|---|---|---|---|
| **SUP-01 — Columns** | **OWNER-SUPPLIED; PRIOR OUTPUT GAPS PARTLY ADDRESSED** | Supplemental column metadata was supplied for profiles/reservations and to check earlier omitted destination/establishment ordinal positions. | Earlier Query 01 output remains partial as a historical result. Do not infer unreported columns or details; preserve raw-result completeness limits where not included. |
| **SUP-02 — Indexes and constraints** | **OWNER-SUPPLIED** | Confirms `establishments_owner_id_key` unique on `establishments.owner_id`; both reservation-to-itinerary FKs (`reservations_itinerary_fk`, `reservations_itinerary_id_fkey`) from `reservations.itinerary_id` to `itineraries.id`; `profiles.role → roles(name)`; and `tourist_profiles_user_id_fkey` and `tourist_profiles_user_id_fkey1` to `profiles(id) ON DELETE CASCADE`. Supplied index rows report `is_valid`, `is_ready`, and `is_live` true. | Constraints referencing an index are distinct from indexes defined on the source relation. Do not infer unreported indexes or constraint details. No index/constraint change is authorized. |
| **SUP-03 — Triggers** | **OWNER-SUPPLIED** | Application triggers `activities.set_activities_updated_at` and `destinations.destinations_updated_at` reference `public.set_updated_at()`. The supplied function behavior assigns `NEW.updated_at = now()` and returns `NEW`. All supplied trigger rows report enabled status; `RI_ConstraintTrigger_*` implement PostgreSQL referential integrity. | Internal RI triggers are not application triggers to recreate manually. Do not infer that trigger rows not represented in supplied output do not exist. |
| **SUP-04 — RLS policies** | **OWNER-SUPPLIED for eleven target relations** | Owner reports policy output for the eleven target relations; all supplied policies are PERMISSIVE and all listed relations have RLS enabled but not forced. Specific observations are summarized in Query 05 and Section 4.2. | This report contains a summary rather than every raw policy row and expression. Applicable permissive policies OR by command/role; no policy result proves API reachability or request behavior. |
| **SUP-05 — Stored relation ACLs** | **OWNER-SUPPLIED for eleven relations** | `anon`, `authenticated`, and `service_role` each have stored ACL entries for DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, and UPDATE on all eleven listed relations. All supplied entries have `is_grantable=false`. | `is_grantable=false` removes grant-option capability, not the privilege. Stored ACL evidence is distinct from effective privileges and RLS. RLS does not govern TRUNCATE. |
| **SUP-06R — Effective schema/relation privileges** | **OWNER-SUPPLIED for eleven relations and three roles** | The same three roles have all eight effective relation privileges on all eleven relations; `USAGE` on `public` is true and `CREATE` is false. | Effective SQL privilege checks do not establish RLS row access, PostgREST exposure, or application need. |
| **SUP-06C1/C2 — Effective column privileges** | **OWNER-SUPPLIED for displayed columns** | Effective INSERT, REFERENCES, SELECT, and UPDATE are reported for displayed columns across the three roles; notable profile columns include email, username, phone, role, preferences, budget, and `fcm_token`. | Do not infer privileges for columns absent from supplied output. Column-level privilege checks do not include DELETE and do not establish row access. |

The supplemental file remains a read-only query source, not a migration. The owner-reported execution status does not imply independent verification or remediation.

## 4. Reconciled findings by evidence layer

### 4.1 Catalog structure and schema conflicts

- **Duplicate reservation foreign keys (SEC-09):** H-I Query 02 and the newly supplied owner Query 02 report `reservations_itinerary_fk` and `reservations_itinerary_id_fkey` from `reservations.itinerary_id` to `itineraries.id`, both with `ON DELETE SET NULL`. H-I Query 14 supplies catalog dependency evidence, not the delete action. Their duplicate status is established by supplied catalog evidence; provenance, necessity, dependent objects, and safe remediation are not.
- **Establishment owner uniqueness (SEC-10 / AP-24):** H-I Query 02 and the newly supplied owner Query 02 confirm `establishments_owner_id_key` on `owner_id`; supplied index flags are `is_valid`, `is_ready`, and `is_live` = true. It enforces at most one establishment per owner, conflicting with AP-24's approved multiple-establishments rule. This is a schema/application compatibility conflict, not an authorization test result. No production change is recommended or implemented; any future change requires separate review of service, `maybeSingle()`, dashboard, verification, RLS, and owner workflows.
- **Profile role contract (SEC-07 / SEC-12):** Query 02 reports a role check and FK to `roles(name)`. The supplied role vocabulary permits `owner`, while the reservation policy checks `establishment`. Preserve this mismatch for characterization; do not silently translate the role or treat a role-string edit as a complete ownership check.
- **Additional foreign keys:** Newly supplied owner Query 02 reports `profiles.role` referencing `roles(name)` and `tourist_profiles_user_id_fkey` plus `tourist_profiles_user_id_fkey1` referencing `profiles(id)` with `ON DELETE CASCADE`. `tourist_profiles` is outside the ten H-G target relations; it is recorded as an evidenced dependency, not added to that target set.
- **Column and trigger completeness:** Original Query 01 remains historically partial; SUP-01 supplies additional profiles/reservations column metadata and checks earlier destination/establishment ordinal gaps. Compare supplied coverage to the required target columns before claiming completeness. H-I Query 04 now has owner-supplied evidence through owner Query 03: the two application triggers call `public.set_updated_at()`, which sets `NEW.updated_at = now()` and returns `NEW`. Trigger inventory completeness remains unconfirmed. Do not treat omitted columns/triggers as absent.
- **Custom types:** Query 15 returned no matches within its filters. Query 02's reported `roles(name)` FK implies a referenced relation/column dependency; the no-row type result does not remove that dependency.

### 4.2 RLS policy observations

The owner-supplied Query 05 reports unconditional PUBLIC-role `SELECT` policies on `profiles` and `destinations`, with an additional active-and-verified public-read policy on destinations; overlapping profile write policies; overlapping permissive `ALL` policies on `itineraries` and `itinerary_stops`; and `roles_select`/`roles_manage`. The supplied summary does not contain every exact policy row, role array, or expression, so missing details are not reconstructed. Exact policy details retained from earlier supplied records are:

- `Users can manage their own itineraries`: authenticated `ALL`; `USING` and `WITH CHECK` require `tourist_id = auth.uid()`.
- `itineraries_own`: authenticated `ALL`; `USING` allows own tourist or administrator/super_admin, while `WITH CHECK` allows own tourist only.
- `Users can manage stops of their own itineraries`: authenticated `ALL`; parent-itinerary ownership is checked in `USING` and `WITH CHECK`.
- `stops_via_itinerary`: authenticated `ALL`; `USING` allows the parent owner or administrator/super_admin; no explicit `WITH CHECK` was recorded in the supplied catalog summary.
- `reservations_insert`: authenticated `INSERT`; condition includes the tourist's own row or `current_user_role()` in `establishment`, administrator, or super_admin. The established role vocabulary uses `owner`, so `establishment` conflicts.
- `activities`: public `SELECT` with `USING (true)`.
- `audit_insert`: authenticated `INSERT` with `WITH CHECK (true)`; `audit_select`: authenticated `SELECT` with `current_user_role() = 'super_admin'`.
- `roles_select`: authenticated `SELECT` with `USING (true)`. `roles_manage` is restricted to `super_admin`; its full command and expressions were not included in the supplied summary.

The owner-supplied result reports no tourist-specific reservation `UPDATE` or `DELETE` policy. This does not establish absence of owner/admin policies for those commands. Permissive policies combine with OR only among applicable policies for the same command and role; a SELECT policy does not authorize UPDATE or DELETE. For ALL policies, a NULL catalog `with_check` indicates no explicit expression; it does not by itself mean there is no check, because PostgreSQL can use the USING expression as the implicit check for applicable writes.

This interpretation is especially relevant to:

- **SEC-01:** unconditional public profile SELECT and overlapping write policies; RLS is row-level and does not provide per-column privacy. Exact names/expressions for every profile policy are not present in the supplied summary.
- **SEC-04:** authenticated audit INSERT with `WITH CHECK true`; catalog policy alone does not identify trusted actor derivation or prove successful forgery.
- **SEC-05/06:** overlapping permissive ALL policies on itineraries and stops; one stop policy has no explicit `WITH CHECK`. Test each command, including INSERT/UPDATE and parent changes, in isolation.
- **SEC-07/08:** `reservations_insert` uses `establishment` while the role vocabulary uses `owner`; no tourist-specific reservation UPDATE/DELETE policy appears in the supplied result. Policy/grant presence does not establish actual owner or tourist request behavior.
- **Destinations and roles:** destinations has unconditional public SELECT alongside active-and-verified public-read. `roles_select` permits authenticated SELECT with `USING (true)` and `roles_manage` is restricted to `super_admin`; full policy metadata remains needed for exact reproduction.

RLS was reported enabled but not forced on the listed relations. The supplied information does not establish the behavior of table owners, bypass roles, every caller context, or PostgREST endpoints.

### 4.3 SQL privileges versus effective privileges

- Query 06 provides complete schema ACL evidence as reported. Schema `USAGE` is not relation authorization.
- Query 07 is partial stored relation ACL evidence. Broad privileges are confirmed only for the visible rows/roles/relations described above. The truncated result cannot support generalization to all nine relations.
- Query 08's no-row result means no explicit column ACL matched its filters; table-level grants remain relevant.
- Query 09 is limited to the one reported sequence and its filters.
- Query 10 is partial effective-privilege evidence, limited to visible `anon` rows for displayed activities/audit columns. It does not confirm effective privileges for other roles, relations, or all columns.
- SUP-05 and SUP-06R now provide owner-reported stored ACL and effective relation privilege coverage for the eleven supplemental target relations and three named roles, including all eight listed relation privileges. This supplements the partial H-I Query 07/10 results for that scope; it does not retroactively make those original query outputs complete. SUP-06C1/C2 cover only columns represented in their supplied output.
- Query 12's effective function EXECUTE results are distinct from relation privileges and RLS. They do not establish the route by which a client could invoke a function.

Earlier H-A/H-B evidence is a separate evidence source and uses its own query numbering. In particular, the partial H-I Query 07/10 output must not be described as a complete result for all roles and relations. Retain earlier observations with their original provenance; do not silently use similarly numbered H-I queries as if they confirmed the earlier H-A result set.

### 4.4 Function authorization concerns (SEC-02, SEC-11)

Owner-supplied Query 11/12 evidence confirms the described SECURITY DEFINER function definition and effective EXECUTE for the selected roles. The `caller_role NOT IN (...)` condition is NULL-sensitive: when `caller_role` is NULL, the predicate evaluates to NULL, and a PL/pgSQL `IF` does not enter its branch unless the condition is true. This is a high-priority authorization concern for controlled non-production characterization, not proof that a bypass was exercised.

The existing function accepts an owner ID and reportedly updates every establishment for that owner or creates a default establishment if none exists. Characterize those effects using only the distinctly named isolated copy specified by H-G/H-D; do not call the production function. Do not count an Administrator/Super Administrator result as a security pass solely because of role. Whether owner-wide verification or default creation is intended requires explicit policy review. A candidate establishment-scoped function is a separate design and test subject.

Query 13's no-visible-path result is complete for the supplied query result but is not proof that no membership edges exist globally. It does not change separately supplied evidence about `service_role` attributes or its `BYPASSRLS` capability; this H-I evidence record alone does not add a new role-attribute result.

## 5. Mapping to SEC-01–SEC-12

| Finding | Reconciled evidence | Qualification / current non-production status |
|---|---|---|
| **SEC-01 — Profile privacy** | Q02/SUP-02 role FK; Q05/SUP-04 public and overlapping profile policies; SUP-05/SUP-06R broad relation privileges; SUP-06C1 displayed profile-column privileges; earlier H-A Query 4 effective SELECT evidence. | Supplemental results reinforce potential SQL/policy exposure, including notable contact, role, planning, and device-token columns. Do not infer privileges for unshown columns or API disclosure. No PostgREST behavior test has been reported. |
| **SEC-02 — SECURITY DEFINER authorization** | Q11 function definition/owner/security/search path/behavior; Q12 effective EXECUTE; Q14 dependencies. | NULL-role weakness and owner-wide/default-create behavior warrant isolated characterization. No exploit, invocation, or remediation is confirmed. Candidate establishment-scoped behavior requires separate review. |
| **SEC-03 — Broad relation privileges** | SUP-05 stored ACLs and SUP-06R effective privileges for eleven relations/three roles; SUP-06C1/C2 displayed columns; earlier Q07/Q10 partial outputs. | Supplemental relation privilege evidence now corroborates breadth, including MAINTAIN and TRUNCATE. No SQL privilege proves API reachability or an exploitable operation; RLS does not govern TRUNCATE. |
| **SEC-04 — Audit integrity** | Q05/SUP-04 authenticated `audit_insert` with `WITH CHECK (true)` and `audit_select`; SUP-05/SUP-06R audit relation privileges; SUP-03 trigger inventory; Q14 separate actor/user FKs. | Catalog evidence strengthens concern; client-authored accepted payloads, trigger constraints, and write atomicity remain untested. |
| **SEC-05 — Itinerary policy overlap** | Q05/SUP-04 all-permissive overlapping itinerary policies; SUP-05/SUP-06R relation privileges; Q14 dependencies. | Policy composition by command and effective API outcome remain behavior-test requirements. |
| **SEC-06 — Itinerary-stop parent ownership** | Q05/SUP-04 overlapping permissive stop policies, one without explicit `WITH CHECK`; SUP-05/SUP-06R relation privileges; Q14 relationships. | Missing explicit expression is not an automatic unrestricted write. Implicit check and parent changes require request-level tests; none has passed. |
| **SEC-07 — Reservation role mismatch** | Q02/SUP-02 role FK; Q05/SUP-04 `reservations_insert` role literal `establishment`; SUP-05/SUP-06R relation privileges; Q14 FKs/dependencies. | Mismatch is corroborated by supplied metadata; actual owner operation and establishment relationship enforcement remain untested. |
| **SEC-08 — Reservation operation asymmetry** | Q05/SUP-04 command-specific policy output; SUP-05/SUP-06R relation privileges; Q02/SUP-02 reservation structure. | No tourist-specific UPDATE/DELETE policy appears in supplied policy output. SQL privileges do not establish tourist row mutation. Owner scope and product policy remain unresolved. |
| **SEC-09 — Duplicate itinerary FKs** | H-I Q02 and owner Query 02/SUP-02 report both FK names/relationship and `ON DELETE SET NULL`; H-I Q14 supplies catalog dependency evidence. | Origin, necessity, and safe remediation remain unknown; no change is authorized. FKs do not prove same-tourist ownership. |
| **SEC-10 — AP-24 establishment cardinality** | H-I Q02, owner Query 02/SUP-02 unique `owner_id`; supplied valid/ready/live index flags; Q11 function behavior; Q14 dependencies. | AP-24 conflict is confirmed. Independent verification and service/dashboard/RLS/workflow compatibility remain separate work; no migration is recommended. |
| **SEC-11 — Service-role boundary** | SUP-05/SUP-06R broad relation ACL/effective privileges; Q12 function EXECUTE; Q13 membership status; earlier H-A/H-B Query 1 `BYPASSRLS=true`. | Role capability and SQL privileges are corroborated, but no credentials, backend use, or API exposure are established. Keep credentials server-only; no membership-path inference beyond corrected evidence. |
| **SEC-12 — Profile role updates** | Q02/SUP-02 role check/FK; Q05/SUP-04 overlapping profile policies; SUP-05/SUP-06R relation UPDATE; SUP-06C1 displayed profile columns including role where present; earlier H-A/H-B evidence. | SQL UPDATE privilege does not prove a successful role change. RLS, column-specific presence in supplied output, triggers, Auth/API path, and actual self-assignment remain behavior-test requirements. |

No finding is newly declared exploited or remediated. The evidence confirms catalog definitions and privilege results only to the scopes stated in this report.

## 6. Non-production reproduction readiness and blockers

The H-G approval gate remains in force. The following gaps block or constrain faithful current-behavior reproduction:

1. **Column metadata coverage:** SUP-01 supplies additional `profiles`/`reservations` metadata and checks the earlier `destinations`/`establishments` ordinal gaps. Compare that output against the required H-G column set; seek only any remaining exact type/default/nullability or ordinal evidence not actually represented. Original Query 01 remains partial as recorded.
2. **Index inventory scope:** owner Query 02 now supplies index and constraint evidence, including the owner unique index and valid/ready/live flags. Verify that the supplied output covers every required index before reproducing; do not infer omitted entries or propose index changes without query-pattern/plan review.
3. **Q04 completeness:** owner Query 03 supplies two application triggers and RI trigger entries, but complete target-table trigger coverage and all definitions/enabled states are not established. Obtain complete inventory if those details are required for reproduction.
4. **Q05 exact policy inventory:** owner Query 05 supplies the summarized policy evidence recorded above. Exact complete rows for every relation—including role list, command, permissive/restrictive flag, `USING`, and `WITH CHECK`—remain required for faithful setup; do not fill missing names or expressions by inference.
5. **Privilege evidence scope:** SUP-05/06R provide owner-reported stored ACL and effective relation privilege coverage for eleven relations and three roles, supplementing the partial H-I Query 07/10 output. SUP-06C1/C2 cover only displayed columns. Preserve the original query statuses; obtain additional column or object evidence only where the selected reproduction scope needs information absent from the supplied supplemental output. Keep stored ACLs separate from effective checks and both separate from RLS.
6. **Function fixture safety:** owner-wide/default-create behavior needs a separately named isolated characterization copy, synthetic-only target data, explicit setup approval, and no invocation of the production function.
7. **Approved role-operation matrix and candidate boundary:** unresolved H-G decisions remain, including owner-wide verification intent, canonical owner vocabulary, profile public/private fields, admin scope, reservation mutation rights, trusted audit behavior, destructive-test boundaries, and whether candidate objects are in scope.
8. **Project and execution gates:** H-G requires exact non-production project-reference verification and separate setup authorization. No project identity is independently verified by this report.

Catalog evidence cannot by itself resolve endpoint exposure, JWT role behavior, data effects, external callers, or authorization outcomes. Those require the controlled non-production tests in H-D after setup is separately approved and baseline verification succeeds.

## 7. Smallest recommended next step

Before preparing or executing setup, collect a **sanitized evidence supplement** containing complete Q01 rows for missing/partial target relations, any remaining index rows needed to establish target coverage, full Q04 output if trigger coverage remains incomplete, and exact complete Q05 policy rows. The owner-supplied SUP-05/06R results supplement the partial H-I relation ACL/effective privilege outputs; SUP-06C1/C2 remain limited to displayed columns. Preserve the owner/H-I query-number mapping and do not fill gaps by inference. Then reconcile exact object definitions against the H-G manifest and obtain owner/security approval for the reproduction policies, role-operation matrix, and destructive-test boundary.

If any required result is unavailable, mark the dependent reproduction object/test BLOCKED or explicitly approve a documented approximation. Do not run setup SQL, provision Auth users, or create fixtures as part of this evidence step.

## 8. Safeguards and unchanged decisions

- Current production behavior and candidate security improvements remain separate.
- No production function is called; the isolated function copy is only for a separately approved non-production characterization.
- No SQL, migration, Auth account, fixture, policy, grant, constraint, function, or schema change is authorized by this report.
- AP-01 through AP-26, the six approved CARS criteria, and the three MO-GA objectives remain unchanged.
- No production or non-production database was accessed or modified by the coding agent.

## Completion record

- **Created:** `docs/TASK_09B_H_J_PRODUCTION_SECURITY_EVIDENCE_RECONCILIATION_AND_GAP_ASSESSMENT.md`
- **Updated:** `supabase/non_production/evidence/README.md` to distinguish the pack-preparation statement from later owner-reported query execution and point to this status reconciliation.
- **Coverage:** Query statuses 01–15; catalog, RLS, ACL/effective privilege, function, SEC-01–SEC-12, schema-conflict, and reproduction-gap reconciliation.
- **Supplemental coverage:** Owner-supplied SUP-01–SUP-06C2 results are reconciled in Section 3.1 and the linked H-M report; the original H-I query statuses remain historical and are not silently rewritten.
- **Database:** No database access or SQL execution by the coding agent; no database object or record changes.
