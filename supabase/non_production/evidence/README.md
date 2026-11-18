# Task 09B-H-I — Production schema evidence pack

**Version:** 001
**Pack:** `001_production_schema_evidence.sql`
**Purpose:** collect owner-reviewed, read-only PostgreSQL catalog evidence needed to resolve the H-H non-production reproduction blockers.

No query has been executed as part of preparing this pack. Run each numbered or SUP-identified `SELECT` separately in Supabase SQL Editor through a manually reviewed, read-only production evidence session. This task authorizes query preparation only. It does not authorize DDL, a migration, a function call, fixture creation, or a production change. Never use `service_role` merely to obtain output; if a catalog result is not visible, record the permission limitation and ask the project owner to run the relevant read-only query.

**Owner-reported execution update:** The project owner supplied production SQL Editor results for this pack. Query numbering in the latest submission differs from this file: owner Query 02 covers indexes and constraints (H-I Queries 02 and 03), owner Query 03 covers triggers (H-I Query 04), and owner Query 05 covers RLS (H-I Query 05). See [`Task 09B-H-J`](../../../docs/TASK_09B_H_J_PRODUCTION_SECURITY_EVIDENCE_RECONCILIATION_AND_GAP_ASSESSMENT.md) for the reconciled status and limits. This supersedes the earlier H-J note that H-I Query 03 had no available result; the supplied index evidence is limited to the owner's pasted output. H-I Query 04 trigger completeness remains unconfirmed, and H-I Query 05 is summarized without every exact policy row/expression. Queries 01, 07, and 10 remain partial; Queries 08 and 15 reportedly returned no rows for their filters. The statement above means the pack author did not execute the queries; the coding agent did not access either Supabase project or execute SQL for the reconciliation.

**Supplemental pack:** [`002_supplemental_production_catalog_evidence.sql`](002_supplemental_production_catalog_evidence.sql) contains read-only supplements SUP-01 through SUP-06C2 for the identified metadata gaps. It includes `public.roles` because the supplied profile role foreign key references `roles(name)`. The coding agent did not execute the pack. The project owner later supplied production SQL Editor results for SUP-01 through SUP-06C2; status and limitations are summarized in [`Task 09B-H-M`](../../../docs/TASK_09B_H_M_SUPPLEMENTAL_PRODUCTION_CATALOG_EVIDENCE_RECONCILIATION_AND_SECURITY_FINDINGS_UPDATE.md). These owner-reported results do not establish API behavior or authorize changes.

## Run order and result handling

1. Confirm the selected project is the intended production evidence source for this **read-only inventory**. The non-production project is the only authorized target for later implementation; this pack does not authorize production writes. Do not use production secrets or credentials in the report.
2. Run Queries 01–04 for relation columns, constraints, indexes, and triggers.
3. Run Query 05 for RLS flags and policies.
4. Run Queries 06–10 for schema, relation, column, sequence, and effective privileges.
5. Run Queries 11–12 for every matching function overload, full definitions, ACLs, and effective EXECUTE.
6. Run Query 13 for role membership paths and per-root diagnostics.
7. Run Queries 14–15 for catalog-recorded object dependencies and custom types.
8. Save each result separately with query number, timestamp, selected database/project label, row count, and any UI truncation or SQL error. Do not paste secrets or application rows into the evidence bundle.
9. If output is truncated, rerun the query with a narrower target list or split it by relation/function. Do not infer omitted rows.

All queries reference catalogs, `information_schema` is not needed, and target user data is never selected. Query 13's `ROOT_STATUS` rows distinguish an invisible root or no visible membership edges from query failure; they cannot rule out catalog visibility limitations. Empty catalog results can mean absence, filtering, or insufficient visibility. A SQL error is not an empty result; preserve the error text without credentials and resolve it separately.

## Coverage matrix: H-A–H-G evidence gaps

| Evidence gap / object | Query numbers | What results supply | Remaining limitation |
|---|---:|---|---|
| Exact columns, PostgreSQL types/typmods, collation, nullability, defaults, identity/generated definitions for H-G relations | 01, 15 | Per-column definitions for profiles, establishments, activities, events, itineraries, destinations, itinerary_stops, reservations, audit_logs, notifications | Catalog visibility; missing table is distinguishable only by comparing requested names. |
| Primary/unique/check/FK constraints, referenced columns and actions, including duplicate reservation itinerary FKs | 02 | Constraint definitions plus ordered source/reference column arrays and FK action codes | Catalog visibility; deferrability/validation included. |
| Primary, unique, partial, expression, and ordinary indexes | 03 | Full index DDL text and predicate/expression | Does not recommend indexes; use application patterns/plans separately. |
| Trigger definitions and trigger functions | 04 | Trigger timing/events/enable state and complete trigger-function definition | Dynamic dependencies inside function bodies may not be catalog tracked. |
| RLS enabled/forced and complete policy inventory | 05 | RLS flags, policy names, modes, commands, roles, USING, WITH CHECK | Does not establish final access without grants, role context, function behavior, and API tests. |
| H-A Query 2/3 truncated explicit grants and H-H grant omissions | 06–09 | Schema/relation/column/sequence ACLs, grantor, grant option, default ACL expansion where applicable | ACL visibility and role memberships can affect interpretation; absent ACL rows are not effective-denial proof. |
| Effective role privileges for anon/authenticated/service_role | 10 | Effective schema USAGE/CREATE, relation, column, sequence privilege booleans | PostgreSQL privilege checks, not RLS/PostgREST behavior. |
| `current_user_role()` and every `admin_toggle_owner_verification` overload | 11–12 | Complete definitions, exact signatures, owner, language, return/args, security, volatility, settings/search_path, EXECUTE ACL/effective checks | Does not prove API exposure, caller reachability, or runtime authorization. Handle function body output as sensitive implementation metadata. |
| Trigger routine definitions and related named function overloads | 04, 11 | Trigger references/bodies and the named security functions | Query 11 covers required named routines; Query 04 returns trigger functions attached to target tables. |
| H-A Query 5 membership reporting flaw / incomplete membership evidence | 13 | Cycle-protected edges report member, inherited role, grantor, and `admin_option`, `inherit_option`, and `set_option`; status row per target role | `inherit_option` and `set_option` require PostgreSQL 16+; empty visible paths remain provisional if catalog visibility is restricted; paths do not calculate every effective privilege. |
| Referenced objects, routine dependencies, sequence ownership and type dependencies | 01, 02, 04, 09, 14 | FK targets, column type identity, owned sequences, trigger functions, and catalog-recorded dependencies | PostgreSQL does not record every PL/pgSQL/dynamic SQL dependency; supplement with source review and definition tracing. |
| Supplemental production metadata results | SUP-01–SUP-06C2 in `002_supplemental_production_catalog_evidence.sql` | Owner-supplied columns, indexes/constraints, triggers, policies, stored relation ACLs, effective schema/relation and displayed-column privileges | Owner-executed and summarized in H-M; agent did not execute. Raw output completeness, catalog visibility, API behavior, and unshown column privileges remain qualified as described in H-M. |
| Enum/domain/composite definitions used by target columns | 01, 14, 15 | Enum labels, domain base/default/checks, composite attributes, and dependency links | Built-in types are omitted from Query 15; catalog visibility applies. |
| H-G current reproduction set and SEC-01–SEC-12 objects | 01–14 | Profiles, establishments, activities, events, itineraries, destinations, stops, existing reservations, audit_logs, notifications; functions/policies/grants | SEC-01–12 coverage matrix below; no behavior test, remediation, or candidate object is created by evidence collection. |

### Supplemental execution status (owner-reported)

| Supplement | Result status and scope | Limitation |
|---|---|---|
| SUP-01 | Owner supplied column metadata, including profile/reservation coverage and earlier destination/establishment ordinal checks. | Do not infer fields or metadata absent from the supplied output. |
| SUP-02 | Owner supplied indexes/constraints; supplied index `is_valid`, `is_ready`, and `is_live` flags were true. | Preserve index-versus-referencing-constraint distinction; no changes recommended. |
| SUP-03 | Owner supplied trigger output; named application triggers and trigger function behavior recorded in H-M; supplied rows enabled. | RI triggers are internal. Unsupplied triggers are not proven absent. |
| SUP-04 | Owner supplied policies for eleven relations; all supplied policies PERMISSIVE; RLS enabled and not forced on all listed relations. | See H-M for the evidence summary and exact-detail limits; no API behavior established. |
| SUP-05 | Owner supplied stored ACL results for eleven relations, all eight listed privileges, three roles; `is_grantable=false`. | Grant-option false does not remove privileges; RLS does not govern TRUNCATE. |
| SUP-06R | Owner supplied effective schema/relation checks for three roles and eleven relations. | SQL privileges do not prove RLS or PostgREST access. |
| SUP-06C1/C2 | Owner supplied effective column checks for displayed columns. | No inference for unshown columns; no column-level DELETE result. |

These statuses mean the project owner supplied execution results; neither the coding agent nor the assistant executed the SQL. See [Task 09B-H-M](../../../docs/TASK_09B_H_M_SUPPLEMENTAL_PRODUCTION_CATALOG_EVIDENCE_RECONCILIATION_AND_SECURITY_FINDINGS_UPDATE.md) for finding/test mapping and evidence boundaries.

## SEC coverage

| Finding | Primary evidence queries | Coverage boundary |
|---|---|---|
| SEC-01 profiles | 01, 05–10, 15 | Definitions, policy and SQL grants; does not prove API row/column exposure. |
| SEC-02 SECURITY DEFINER functions | 04, 11–14 | Function and trigger dependencies, definition/settings/ACL; no invocation. |
| SEC-03 broad relation privileges | 01–10 | Relation inventory and direct/effective grants for relevant relations. |
| SEC-04 audit integrity | 01–10, 14–15 | Audit schema, triggers, policies, grants, dependencies; not row contents/authorship behavior. |
| SEC-05 itinerary policies | 01–03, 05–10, 14 | Itinerary structure, policy, grants, dependency metadata. |
| SEC-06 stop ownership | 01–05, 10, 14 | Stop and parent FKs, policies, grants, triggers/dependencies. |
| SEC-07 reservation role mismatch | 01–05, 10–15 | Reservation/establishment/profile definitions, role check constraints, policies, grants, related functions/types. |
| SEC-08 reservation policy asymmetry | 01–05, 10, 14 | Reservation commands/roles and SQL privileges; no request execution. |
| SEC-09 duplicate itinerary FKs | 02, 03, 14 | Both names/definitions/actions, indexes and catalog dependencies. |
| SEC-10 establishment uniqueness | 01–05, 10, 14 | Owner column, unique constraint/index, policies/functions and dependencies. |
| SEC-11 service-role boundary | 06–14 | Catalog ACLs, effective privileges, memberships, functions; does not inspect credentials or infrastructure. |
| SEC-12 profile role updates | 01–02, 05–10, 14–15 | Role type/checks, UPDATE policies, grants and catalog dependencies; behavior remains untested. |

## Static quality and safety notes

- Every executable statement in the SQL pack is a `SELECT` (including `WITH` queries that terminate in `SELECT`). There are no DDL/DML/GRANT/REVOKE statements or function invocations.
- `pg_get_functiondef`, `pg_get_triggerdef`, and `pg_get_constraintdef` retrieve definitions as catalog text; they do not execute those definitions.
- `has_*_privilege` functions inspect privileges; they do not perform the associated operation.
- Query 13 requires PostgreSQL 16 or later because it reads `pg_auth_members.inherit_option` and `set_option`, alongside `admin_option`. PostgreSQL 17 also supports these fields. Confirm the server version before running it; an unsupported-field error is a query error, not an empty membership result.
- Queries contain no references to production credentials, application tokens, or user-record columns as selected data. Column names may include `fcm_token`, but Query 01 returns only metadata, never values.
- Function/default/constraint definitions are source metadata and could themselves contain hard-coded sensitive literals. Review outputs locally and redact any secret before sharing; never include credentials, keys, JWTs, or tokens in the evidence bundle.
- The pack does not verify which Supabase project is selected. The operator must independently verify the evidence source and share only sanitized catalog output.
- Query 14 reports dependencies PostgreSQL records. It is not a complete source-level call graph and cannot discover arbitrary dynamic SQL references.
- These queries complete evidence collection only. They do not make the non-production SQL scaffold executable or authorize implementation. Review outputs, resolve differences and blockers, then request a separate implementation approval.
