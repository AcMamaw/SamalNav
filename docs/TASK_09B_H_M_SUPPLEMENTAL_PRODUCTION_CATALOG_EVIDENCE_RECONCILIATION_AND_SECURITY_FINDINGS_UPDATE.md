# Task 09B-H-M — Supplemental Production Catalog Evidence Reconciliation and Security Findings Update

**Status:** Documentation-only reconciliation of owner-supplied production catalog results for SUP-01 through SUP-06C2. The coding agent did not access either Supabase project or execute SQL. No behavior test, remediation, or production change is established by this report.

## 1. Executive summary

The project owner supplied production SQL Editor results for the supplemental evidence statements. These results strengthen catalog evidence for broad stored and effective relation privileges, selected effective column privileges, policy overlap, index/constraint relationships, and trigger behavior. They corroborate security review priorities for SEC-01, SEC-03 through SEC-10, and SEC-12. SEC-02's function authorization finding and SEC-11's `service_role` BYPASSRLS concern remain supported by earlier H-A/H-I evidence; the supplemental results do not replace those sources.

Catalog privileges and policies do not establish that a PostgREST route is reachable or that a request succeeds. No vulnerability is claimed exploited, no finding is closed or downgraded, and no test is reported as passed. AP-01 through AP-26, CARS criteria, and MO-GA objectives are unchanged. H-G remains an approval gate; this report does not authorize non-production setup or remediation.

## 2. Evidence sources and collection boundaries

### Sources reviewed

- `supabase/non_production/evidence/001_production_schema_evidence.sql` and its README.
- `supabase/non_production/evidence/002_supplemental_production_catalog_evidence.sql` and its README.
- `docs/TASK_09B_H_J_PRODUCTION_SECURITY_EVIDENCE_RECONCILIATION_AND_GAP_ASSESSMENT.md`.
- `docs/TASK_09B_H_B_PRODUCTION_SECURITY_FINDINGS_AND_REMEDIATION_DESIGN.md`.
- `docs/TASK_09B_H_C_APPLICATION_DEPENDENCY_AND_AUTHORIZATION_CALL_PATH_INVENTORY.md`.
- `docs/TASK_09B_H_D_NON_PRODUCTION_AUTHORIZATION_VERIFICATION_PLAN.md`.
- `docs/TASK_09B_H_F_NON_PRODUCTION_TEST_SCHEMA_ARCHITECTURE_AND_CONTROLLED_SETUP_DESIGN.md`.
- `docs/TASK_09B_H_G_FINAL_NON_PRODUCTION_SETUP_APPROVAL_GATE.md`.
- `docs/TASK_09B_D_APPROVED_RESERVATION_ACTIVITY_POLICY_BASELINE.md` for the AP-01–AP-26 policy baseline.

The repository does not contain separate report files titled as the H-K supplemental evidence-pack report or H-L SQL source verification report. The actual supplemental SQL file and README were inspected instead; no missing report contents are inferred. The owner supplied the result summaries used below. They were not independently checked against a live database. The evidence remains limited to the supplied result descriptions and any output limitations they state.

### Interpretation boundaries

- Stored ACLs, effective SQL privilege checks, RLS policy definitions, constraints, and trigger metadata are different evidence layers.
- `is_grantable=false` means a grantee cannot grant the privilege onward; it does not negate the privilege itself.
- RLS does not govern `TRUNCATE`; SQL grants do not prove a PostgREST operation is exposed or permitted for a row.
- Applicable PERMISSIVE policies combine with OR for the same command and role. A policy for one command does not grant another command. An omitted explicit `WITH CHECK` is not, by itself, proof of unrestricted writes.
- Column privilege evidence applies only to columns present in the supplied output. Column privilege checks do not cover DELETE.
- No raw application records or secrets are included or required for this reconciliation.

## 3. SUP-01–SUP-06C2 evidence reconciliation

| Item | Owner-supplied result | Supported conclusion | Limitation |
|---|---|---|---|
| **SUP-01 — Column metadata** | Owner-collected supplemental column metadata, including profiles/reservations and checks for earlier omitted destination/establishment ordinal positions. | This supplements the earlier incomplete Query 01 evidence. | The earlier omissions remain part of the historical record. Do not infer columns, types, nullability, defaults, or positions that are not present in the supplied output. |
| **SUP-02 — Indexes and constraints** | `establishments_owner_id_key` uniquely constrains `establishments.owner_id`; reservation column `reservations.itinerary_id` has two named FKs to `itineraries.id`: `reservations_itinerary_fk` and `reservations_itinerary_id_fkey`; `profiles.role` references `roles(name)`; `tourist_profiles_user_id_fkey` and `tourist_profiles_user_id_fkey1` reference `profiles(id)` with `ON DELETE CASCADE`. Supplied index records show `is_valid`, `is_ready`, and `is_live` all true. | The unique owner index/constraint is a confirmed AP-24 schema conflict. The two reservation FK names and referenced relation are confirmed by the SUP-02 summary. Their delete actions are not stated in that summary; the earlier owner-supplied Query 02 evidence recorded in H-J reports `ON DELETE SET NULL`. | Keep indexes defined on a relation distinct from constraints that reference an index on another relation. Do not infer unreported rows or recommend index changes without query-pattern and plan review. The two reservation FKs' origin and safe remediation remain unverified. |
| **SUP-03 — Triggers** | Application triggers `activities.set_activities_updated_at` and `destinations.destinations_updated_at` call `public.set_updated_at()`. The supplied function assigns `NEW.updated_at = now()` and returns `NEW`. All supplied trigger rows were enabled. `RI_ConstraintTrigger_*` rows are also present. | The named application trigger behavior and enabled status are owner-supplied. RI triggers implement PostgreSQL foreign-key behavior. | Do not treat RI triggers as ordinary application triggers or manually recreate them. Do not infer that unsupplied trigger rows do not exist. |
| **SUP-04 — Policies** | Owner supplied policy output for all eleven target relations. `profiles` has unconditional public SELECT and overlapping permissive policies; `destinations` has unconditional public SELECT alongside filtered public-read policies; `itineraries` has overlapping permissive ALL policies; `itinerary_stops` has overlapping ALL policies, including one without an explicit `WITH CHECK`; `reservations_insert` tests `establishment`, while the known database role vocabulary uses `owner`; no tourist-specific reservation UPDATE or DELETE policy appears. `audit_logs` allows authenticated INSERT with `WITH CHECK (true)`. `roles_select` allows authenticated SELECT with `USING (true)`; `roles_manage` is restricted to `super_admin`. All supplied policies are PERMISSIVE. RLS is enabled but not forced on all eleven relations. | This report records the supplied policy summary and exact policy details already preserved in H-B/H-J, but not every raw policy row/expression. No tourist-specific UPDATE/DELETE policy is not a claim that there are no owner/admin policies. Effective request behavior remains untested. |
| **SUP-05 — Stored relation ACLs** | Complete supplied ACL results for `activities`, `audit_logs`, `destinations`, `establishments`, `events`, `itineraries`, `itinerary_stops`, `notifications`, `profiles`, `reservations`, and `roles`: `anon`, `authenticated`, and `service_role` have entries for DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, and UPDATE. All supplied entries have `is_grantable=false`. | Broad stored privileges are corroborated across the eleven named relations and three grantees, subject to the supplied output and catalog visibility. | No grant option does not mean no granted privilege. RLS does not apply to TRUNCATE. These ACLs do not establish row access or API reachability. |
| **SUP-06R — Effective schema/relation privileges** | Supplied results report all eight listed relation privileges effective for `anon`, `authenticated`, and `service_role` on all eleven relations. For schema `public`, USAGE is true and CREATE is false for all three. | Effective SQL relation privilege breadth is corroborated for the reported role/object pairs. | Effective privilege functions do not evaluate RLS row visibility or PostgREST/JWT behavior. |
| **SUP-06C1/C2 — Effective column privileges** | For columns displayed in the supplied results, effective INSERT, REFERENCES, SELECT, and UPDATE are reported across the three roles. Notable profile columns include `email`, `username`, `phone`, `role`, `preferences`, `budget`, and `fcm_token`. | Column-level evidence supports targeted privacy and profile-role testing for the shown fields. | Do not infer privileges for columns absent from the output. Column-level checks do not include DELETE and do not prove a row can be read or changed under RLS. |

## 4. Confirmed catalog observations

1. The owner uniqueness constraint/index on `establishments.owner_id` enforces one establishment per owner in the reported schema. This conflicts with AP-24, which approves one owner managing multiple establishments. Removing the unique constraint alone would not address singleton application queries, dashboards, verification logic, RLS predicates, or owner lifecycle workflows.
2. Two separate FKs from `reservations.itinerary_id` reference `itineraries.id`. The earlier owner-supplied Query 02 evidence recorded in H-J reports `ON DELETE SET NULL`; that action is not stated in the supplemental SUP-02 summary. Ordinary foreign keys do not enforce that a reservation's tourist and itinerary have the same owner. Their origin, necessity, and safe remediation remain a separate review.
3. The supplied profile role FK points to `roles(name)`. The supplied duplicated `tourist_profiles` FK names point to `profiles(id)` with cascade delete; `tourist_profiles` is a supporting dependency, not an addition to the H-G eleven-relation policy target list.
4. The named activities and destinations update triggers use `public.set_updated_at()`. Supplied trigger rows were enabled; internal referential-integrity triggers must remain distinguished from application triggers.
5. All supplied policies were permissive. Where policies overlap, OR composition applies only to policies applicable to the same command and role. For example, a public SELECT policy does not grant UPDATE or DELETE.
6. All eight supplied relation privileges are reported in stored ACL and effective checks for the named roles/relations. The grant-option flag is false, but the underlying privilege is still present. RLS does not constrain TRUNCATE.
7. Displayed profile columns include sensitive contact, role, planning, and device-token fields. Treat those fields as private candidates for review; the exact field-level effective privilege claim is limited to columns actually included in supplied output.

## 5. SEC-01 through SEC-12 evidence mapping

| Finding | Evidence classification and supplemental impact | Current conclusion and boundary |
|---|---|---|
| **SEC-01 — Profile privacy** | **Multiple independent catalog sources corroborate exposure potential:** SUP-01 provides column metadata; SUP-04 reports unconditional public SELECT and overlapping policies; SUP-05/06R report broad profile relation privileges; SUP-06C1 reports effective privileges on displayed columns; earlier H-A Query 4 reported effective SELECT on listed profile columns. | Potential SQL/policy exposure is reinforced. RLS is not column security. Actual PostgREST field/row exposure is untested; do not infer privileges for unshown columns. |
| **SEC-02 — SECURITY DEFINER authorization** | **Earlier evidence only; supplemental pack does not independently address function authorization.** H-A/H-I function definition/EXECUTE evidence remains the basis; SUP-03 provides only trigger-function context. | Retain NULL-role concern. Function authorization behavior is unresolved until isolated characterization and unauthorized-role/no-mutation tests; no function was invoked. |
| **SEC-03 — Broad relation privileges** | **Directly corroborated by multiple supplemental catalog checks:** SUP-05 and SUP-06R report eight stored/effective relation privileges for three roles across eleven relations; SUP-06C1/C2 add displayed-column privileges. | Broad grants are strongly corroborated at catalog level, including TRUNCATE and MAINTAIN. API reachability and exploitability remain untested. |
| **SEC-04 — Audit integrity** | **Catalog concern corroborated across policy and privilege evidence:** SUP-04 reports authenticated `audit_logs` INSERT with `WITH CHECK (true)`; SUP-05/06R report broad audit relation privileges; SUP-03 supplies trigger inventory. | Whether clients can forge accepted audit rows, whether triggers constrain them, and whether the operation is atomic remain application/database behavior questions. |
| **SEC-05 — Itinerary policy overlap** | **Directly corroborated by policy and privilege evidence:** SUP-04 reports overlapping permissive ALL policies; SUP-05/06R report broad relation privileges. | Per-command `USING`/`WITH CHECK` outcomes and administrator paths require tests. |
| **SEC-06 — Itinerary-stop ownership** | **Directly corroborated by policy and relationship evidence:** SUP-04 reports overlapping ALL policies, including one without explicit `WITH CHECK`; SUP-02 supplies relationship metadata; SUP-05/06R report broad privileges. | Absence of an explicit check is not itself an unrestricted-write result. Parent ownership and implicit check behavior require controlled tests. |
| **SEC-07 — Reservation role mismatch** | **Corroborated by role-reference and policy evidence:** SUP-02 confirms the profile role reference; SUP-04 reports `reservations_insert` uses `establishment`, while known vocabulary uses `owner`; SUP-02 also confirms reservation FKs. | Role-literal mismatch is corroborated; actual owner authorization and referenced-establishment scope are untested. |
| **SEC-08 — Reservation operation asymmetry** | **Directly corroborated in supplied policy/privilege evidence:** SUP-04 reports no tourist-specific reservation UPDATE/DELETE policy; SUP-05/06R show SQL privileges separately. | Do not infer tourist row mutation from SQL grants. Owner/admin scope and intended tourist mutation remain unresolved and require command-specific tests. |
| **SEC-09 — Duplicate itinerary FKs** | **Corroborated by multiple catalog sources:** SUP-02 confirms both names and referenced relation; the earlier owner-supplied Query 02 evidence recorded in H-J reports `ON DELETE SET NULL`, and H-I Query 14 supplies dependency evidence. | Duplicate relationship confirmed; no same-owner invariant follows from independent FKs. The delete action is supported by the earlier Query 02 evidence, not the SUP-02 summary. Origin, dependencies, and remediation remain unverified. |
| **SEC-10 — AP-24 establishment cardinality** | **Directly corroborated by constraint/index evidence:** SUP-02 confirms unique `establishments.owner_id` and valid/ready/live flags; SUP-03/04/05/06R add trigger, policy, and privilege context. | Schema conflict confirmed. Do not remove uniqueness as a standalone change; test current rejection and separately review candidate multi-establishment behavior and application compatibility. |
| **SEC-11 — service_role boundary** | **Earlier and supplemental catalog evidence:** SUP-05/06R corroborate broad service_role privileges; earlier H-A Query 1 reports `BYPASSRLS=true`; H-I membership evidence has its own limits. | Database role capability is not evidence that credentials exist in client artifacts or that any route is exposed. Keep credential custody and backend authorization separate. |
| **SEC-12 — Profile role self-assignment** | **Catalog concern corroborated, application behavior unresolved:** SUP-04 reports overlapping profile policies; SUP-05/06R report relation UPDATE; SUP-06C1 includes `role` among notable displayed profile columns with column privilege results. | Effective SQL UPDATE is not proof a role change succeeds under RLS or a specific API path. Direct self-assignment and privileged-role tests remain necessary. |

No finding identifier or severity is changed by this report. SEC-02 remains a high-priority authorization concern; SEC-11 retains the earlier BYPASSRLS evidence. Supplemental evidence does not close any finding.

## 6. AP-24 schema conflict assessment

The supplied unique index/constraint on `establishments.owner_id` currently limits each owner to one establishment, conflicting with approved AP-24. This is a confirmed schema mismatch, not authorization remediation. A future separately reviewed change must assess owner-specific service queries and `maybeSingle()` assumptions, both dashboards, verification functions, RLS ownership predicates, and establishment creation/selection/management flows. The production object is not changed here; no migration or index change is proposed.

## 7. Application-level implications and limitations

H-C records direct anon-client use, profile lookup/edit paths, client-side audit insertion, one-establishment service/dashboard assumptions, and no persisted itinerary/stop client CRUD in the searched Flutter code. These source facts help define test fixtures and operations but do not prove production API behavior. A database grant may be reachable through some client but still filtered by RLS; a UI guard does not replace server authorization. Conversely, absence of a Dart call does not prove no external client or backend caller exists.

Do not use the catalog evidence to claim:

- successful anonymous retrieval or role escalation;
- that a function is reachable or was invoked;
- that a stored/effective privilege guarantees an RLS-protected request succeeds;
- that `service_role` credentials are present in the Flutter app;
- that duplicate FKs enforce tourist/itinerary same-owner integrity;
- that an empty or omitted catalog output proves global absence.

## 8. Non-production testing requirements

Use the existing H-D test IDs with synthetic fixtures only. Associate supplemental evidence as follows:

| Security concern | H-D tests to run when setup is separately approved |
|---|---|
| Profile field disclosure and role self-assignment | 01-A–01-D, 12-A–12-C; cross-cutting X-01–X-03. Include each profile column only if present in the reviewed schema. |
| SECURITY DEFINER behavior and NULL role | 02-A–02-F, X-04. Characterize the existing function only through the isolated test copy; candidate tests remain separate. |
| Broad relation grants, MAINTAIN, TRUNCATE | 03-A–03-C, X-02, X-08. Catalog-check structural privileges; do not execute TRUNCATE outside a separately approved disposable target. |
| Audit insertion/integrity | 04-A–04-C, X-06–X-07. Test forged actor/role/action payloads, read/mutation scope, and failure/atomicity with synthetic rows. |
| Permissive policy overlap and itinerary ownership | 05-A–05-D, 06-A–06-C, X-03, X-05. Exercise commands separately; include parent reparenting and implicit `WITH CHECK`. |
| Reservation role mismatch and owner/tourist scope | 07-A–07-C, 08-A–08-C, X-05, X-08. Keep `establishment` versus `owner` characterization distinct and test each command. |
| Duplicate FKs and same-owner invariant | 09-A–09-C, X-05. Confirm catalog metadata and synthetic FK behavior; same-owner enforcement is blocked pending approved enforcement design. |
| AP-24 uniqueness | 10-A–10-C, 02-F, X-09. Test current unique rejection; candidate multi-establishment tests require a separately approved AP-24-compatible schema. |
| service_role | 11-A–11-C, X-02. Review custody without revealing secrets; only test a trusted backend if it exists in the approved test environment. |

H-D's expected behaviors remain plans, not test outcomes. Do not set any test to PASS based on these catalog results. Preserve H-D's safety gates, owner decisions, and test classifications.

## 9. Outstanding evidence gaps

1. Raw SUP result bundles are not stored as a separate, complete evidence artifact in this repository; this report records the owner-supplied summary and does not claim independent validation.
2. SUP-01 completeness for all target columns, exact types/defaults/nullability, and prior ordinal gaps must be checked against the actual supplied output before faithfully reproducing schemas.
3. SUP-02 output scope must be checked for all indexes/constraints required by the H-G reproduction set. The supplied validity flags do not establish which omitted objects may exist.
4. SUP-03 does not justify treating unsupplied trigger rows as absent; complete source output and function/dependency coverage may still be needed for chosen objects.
5. Exact SUP-04 policy rows for all eleven relations, including full role arrays, commands, modes, USING and WITH CHECK expressions, must be retained for faithful reproduction. This report summarizes the details supplied in the task and prior reports only.
6. SUP-06C1/C2 do not establish column privileges for columns not present in supplied output. Effective privileges still do not settle RLS/JWT/PostgREST behavior.
7. H-I Query 07 and Query 10 retain their historical PARTIAL status. SUP-05/06R owner-supplied results supplement relation ACL/effective-privilege coverage for the eleven named relations and three roles; SUP-06C1/C2 remain limited to displayed columns. Additional evidence is needed only for objects/columns outside that supplied scope, not by treating the older partial query outputs as complete.
8. Test identity/role behavior, function invocation paths, external callers, client credential exposure, audit forgery, cross-owner reservation behavior, same-owner constraints, and AP-24 workflows remain untested.
9. H-G owner approval and exact project-reference gate remain required before any non-production setup. H-K/H-L report documents were not found; their SQL pack source and README were reviewed instead.

## 10. Production safety and approval status

- The results are reported as project-owner execution in the production Supabase SQL Editor; the coding agent did not access either project or execute SQL.
- No production or non-production object/data was modified. No migration, Auth user, test fixture, policy, grant, function, constraint, or index change was made.
- No remediation SQL is prepared or recommended here. H-G remains the setup approval gate; this report does not authorize setup or test execution.
- AP-01 through AP-26, all six CARS criteria, and the three MO-GA objectives are unchanged.

## 11. Files created or modified

**Created:**

- `docs/TASK_09B_H_M_SUPPLEMENTAL_PRODUCTION_CATALOG_EVIDENCE_RECONCILIATION_AND_SECURITY_FINDINGS_UPDATE.md`

**Updated in place:**

- `docs/TASK_09B_H_J_PRODUCTION_SECURITY_EVIDENCE_RECONCILIATION_AND_GAP_ASSESSMENT.md` — supplemental status and SEC evidence mapping.
- `docs/TASK_09B_H_B_PRODUCTION_SECURITY_FINDINGS_AND_REMEDIATION_DESIGN.md` — supplemental evidence note; original SEC IDs/severities retained.
- `docs/TASK_09B_H_D_NON_PRODUCTION_AUTHORIZATION_VERIFICATION_PLAN.md` — evidence-to-test crosswalk; no test status changed.
- `supabase/non_production/evidence/README.md` — owner-supplied execution status and reconciliation link.

The original H-I SQL pack, supplemental SQL pack, migrations, and application files were not modified for this task.
