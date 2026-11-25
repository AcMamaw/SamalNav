# Task 24 — SamalNav Supplemental Runtime Schema and Migration History Evidence Collection

**Purpose:** Prepare owner-run, read-only catalog queries for the six Task 21 runtime relations omitted from Task 18’s original target list, plus a careful migration-history inventory.  
**Target to confirm before execution:** SamalNav-NonProduction — `iwzyasdanesaaxxjujxr` — `ap-southeast-2`.  
**Execution status:** Queries are prepared only. No SQL was executed and neither Supabase project was accessed.  
**Approval boundary:** Evidence collection only; no schema, policy, migration, initialization, or deployment is authorized.

## 1. Executive summary

Task 23 found that Task 18’s relation query covered eleven public relations but omitted six current runtime relations identified in Task 21: `favorites`, `reservations`, `payments`, `events`, `audit_logs`, and `system_settings`. This package provides separately runnable catalog `SELECT` statements for their relation/column metadata, constraints, indexes, RLS/policies, and grants/privileges. It also provides a cautious inventory of likely migration-history relations and a conditional query for the standard Supabase CLI migration ledger.

Before running any statement, the project owner must confirm the dashboard project name, exact reference, and region listed above. Stop if any differ. Record outputs as **owner-supplied evidence**. Catalog results do not prove PostgREST access under a tourist JWT, data correctness, or that migration history is absent in every system.

## 2. Six omitted runtime relations

These are repository-confirmed application call-site dependencies from Task 21, not confirmed deployed relations:

1. `public.favorites`
2. `public.reservations`
3. `public.payments`
4. `public.events`
5. `public.audit_logs`
6. `public.system_settings`

Do not assume any exists or is absent. Task 23’s supplied relation output did not cover them. The queries below emit a placeholder row for missing relations in the relation and RLS inventories; empty constraint/index/grant results must always be interpreted alongside the existence query.

## 3. Execution instructions and safety

1. In the Supabase Dashboard, confirm **SamalNav-NonProduction**, reference **`iwzyasdanesaaxxjujxr`**, region **`ap-southeast-2`**. If a value differs, stop and do not run these queries against another project.
2. Run each numbered statement separately in SQL Editor using an authorized read-only evidence session. Do not switch roles or use `service_role` to obtain output.
3. Run Query 24-01 first. Run later catalog queries as written; interpret empty rows only together with the existence result. Run Query 24-06C only if 24-06A/B confirms the exact standard tracking relation and required columns.
4. Preserve exact query ID, execution timestamp/time zone, row count, complete sanitized output, errors, permission limits, and truncation status. Missing relation, empty result, permission error, and query failure are distinct.
5. Do not return application rows, review text, user IDs, emails, payment references, credentials, tokens, connection strings, or personal data. These queries inspect catalog metadata and migration version/name only.
6. If visibility is insufficient, record that limitation and ask the authorized project owner/DBA to run the same read-only query. Do not elevate privileges or substitute another project.

All SQL below uses only `SELECT`/`WITH` and catalog inspection. No statement is executed as part of preparing this pack.

## 4. Read-only SQL query package

### Query 24-01 — Relation existence and column contract

**Purpose:** Report a row for each of the six targets even when absent; if present, return column ordinal, type, nullability, default, identity/generated metadata.

```sql
WITH targets(schema_name, relation_name) AS (
    VALUES
        ('public', 'favorites'),
        ('public', 'reservations'),
        ('public', 'payments'),
        ('public', 'events'),
        ('public', 'audit_logs'),
        ('public', 'system_settings')
)
SELECT
    target.schema_name,
    target.relation_name,
    (rel.oid IS NOT NULL) AS relation_found,
    rel.relkind AS relation_kind,
    attr.attnum AS ordinal_position,
    attr.attname AS column_name,
    CASE WHEN attr.attnum IS NOT NULL
         THEN format_type(attr.atttypid, attr.atttypmod) END AS data_type,
    attr.attnotnull AS not_null,
    pg_get_expr(def.adbin, def.adrelid) AS column_default,
    attr.attidentity AS identity_kind,
    attr.attgenerated AS generated_kind
FROM targets AS target
LEFT JOIN pg_namespace AS ns
    ON ns.nspname = target.schema_name
LEFT JOIN pg_class AS rel
    ON rel.relnamespace = ns.oid
   AND rel.relname = target.relation_name
   AND rel.relkind IN ('r', 'p', 'v', 'm', 'f')
LEFT JOIN pg_attribute AS attr
    ON attr.attrelid = rel.oid
   AND attr.attnum > 0
   AND NOT attr.attisdropped
LEFT JOIN pg_attrdef AS def
    ON def.adrelid = rel.oid
   AND def.adnum = attr.attnum
ORDER BY target.schema_name, target.relation_name, attr.attnum;
```

**Interpretation limit:** A `relation_found=false` row applies to the named schema/relation and catalog visibility of this query. It says nothing about similarly named relations in other schemas. No row values are read.

### Query 24-02 — Primary, unique, check, and foreign-key constraints

**Purpose:** Return definitions, validation/deferrability, referenced relation, and referential actions for constraints on the six present relations. `pg_get_constraintdef` includes the key columns and FK action clauses.

```sql
WITH targets(schema_name, relation_name) AS (
    VALUES
        ('public', 'favorites'), ('public', 'reservations'),
        ('public', 'payments'), ('public', 'events'),
        ('public', 'audit_logs'), ('public', 'system_settings')
)
SELECT
    ns.nspname AS schema_name,
    rel.relname AS relation_name,
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    ref_ns.nspname AS referenced_schema,
    ref_rel.relname AS referenced_relation,
    pg_get_constraintdef(con.oid, true) AS definition,
    con.convalidated AS validated,
    con.condeferrable AS deferrable,
    con.condeferred AS initially_deferred
FROM pg_constraint AS con
JOIN pg_class AS rel ON rel.oid = con.conrelid
JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
LEFT JOIN pg_class AS ref_rel ON ref_rel.oid = con.confrelid
LEFT JOIN pg_namespace AS ref_ns ON ref_ns.oid = ref_rel.relnamespace
WHERE EXISTS (
    SELECT 1 FROM targets AS target
    WHERE target.schema_name = ns.nspname
      AND target.relation_name = rel.relname
)
AND con.contype IN ('p', 'u', 'f', 'c', 'x')
ORDER BY ns.nspname, rel.relname, con.contype, con.conname;
```

**Interpretation limit:** No rows may mean there are no visible constraints on existing relations, or that the target relations are absent/not visible. Compare with Query 24-01. Constraint metadata does not prove existing data satisfies constraints that are absent or unvalidated.

### Query 24-03 — Index definitions and validity

```sql
SELECT
    ns.nspname AS schema_name,
    rel.relname AS relation_name,
    idx.relname AS index_name,
    ind.indisprimary AS is_primary,
    ind.indisunique AS is_unique,
    ind.indisvalid AS is_valid,
    ind.indisready AS is_ready,
    ind.indislive AS is_live,
    pg_get_expr(ind.indpred, ind.indrelid) AS predicate,
    pg_get_expr(ind.indexprs, ind.indrelid) AS expressions,
    pg_get_indexdef(ind.indexrelid) AS index_definition
FROM pg_index AS ind
JOIN pg_class AS rel ON rel.oid = ind.indrelid
JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
JOIN pg_class AS idx ON idx.oid = ind.indexrelid
WHERE ns.nspname = 'public'
  AND rel.relname IN (
      'favorites', 'reservations', 'payments', 'events',
      'audit_logs', 'system_settings'
  )
ORDER BY rel.relname, idx.relname;
```

**Interpretation limit:** Indexes support access paths/constraints but their presence does not approve schema changes or establish application performance. Compare against Query 24-01.

### Query 24-04 — RLS flags and policy definitions

**Purpose:** Preserve one row for each target relation, including absent relations and present relations with no visible policy. For policies, report command, roles, permissive/restrictive mode, `USING`, and `WITH CHECK`.

```sql
WITH targets(schema_name, relation_name) AS (
    VALUES
        ('public', 'favorites'), ('public', 'reservations'),
        ('public', 'payments'), ('public', 'events'),
        ('public', 'audit_logs'), ('public', 'system_settings')
)
SELECT
    target.schema_name,
    target.relation_name,
    (rel.oid IS NOT NULL) AS relation_found,
    COALESCE(rel.relrowsecurity, false) AS rls_enabled,
    COALESCE(rel.relforcerowsecurity, false) AS rls_forced,
    policy.policyname,
    policy.permissive,
    policy.cmd AS command,
    policy.roles AS target_roles,
    policy.qual AS using_expression,
    policy.with_check AS with_check_expression
FROM targets AS target
LEFT JOIN pg_namespace AS ns ON ns.nspname = target.schema_name
LEFT JOIN pg_class AS rel
    ON rel.relnamespace = ns.oid
   AND rel.relname = target.relation_name
   AND rel.relkind IN ('r', 'p')
LEFT JOIN pg_policies AS policy
    ON policy.schemaname = target.schema_name
   AND policy.tablename = target.relation_name
ORDER BY target.schema_name, target.relation_name, policy.policyname;
```

**Interpretation limit:** False RLS flags on an absent relation do not establish that any existing relation has RLS disabled. Policy catalog results do not prove a JWT/PostgREST request outcome.

### Query 24-05A — Relation ACL entries and effective relation privileges

**Purpose:** Report stored/default-expanded relation ACL entries and effective relation-level SELECT/INSERT/UPDATE/DELETE/REFERENCES/TRIGGER privileges for `anon`, `authenticated`, and `service_role` when those roles exist.

```sql
WITH targets(schema_name, relation_name) AS (
    VALUES
        ('public', 'favorites'), ('public', 'reservations'),
        ('public', 'payments'), ('public', 'events'),
        ('public', 'audit_logs'), ('public', 'system_settings')
), target_relations AS (
    SELECT ns.oid AS namespace_oid, ns.nspname,
           rel.oid AS relation_oid, rel.relname, rel.relowner, rel.relacl
    FROM targets AS target
    JOIN pg_namespace AS ns ON ns.nspname = target.schema_name
    JOIN pg_class AS rel
      ON rel.relnamespace = ns.oid
     AND rel.relname = target.relation_name
     AND rel.relkind IN ('r', 'p', 'v', 'm', 'f')
)
SELECT
    'ACL_ENTRY'::text AS evidence_kind,
    relation.nspname AS schema_name,
    relation.relname AS relation_name,
    CASE acl.grantee WHEN 0 THEN 'PUBLIC' ELSE grantee.rolname END AS grantee,
    grantor.rolname AS grantor,
    acl.privilege_type,
    acl.is_grantable AS grant_option,
    NULL::text AS checked_role,
    NULL::boolean AS has_select,
    NULL::boolean AS has_insert,
    NULL::boolean AS has_update,
    NULL::boolean AS has_delete,
    NULL::boolean AS has_references,
    NULL::boolean AS has_trigger
FROM target_relations AS relation
CROSS JOIN LATERAL aclexplode(
    COALESCE(relation.relacl, acldefault('r', relation.relowner))
) AS acl
LEFT JOIN pg_roles AS grantee ON grantee.oid = acl.grantee
LEFT JOIN pg_roles AS grantor ON grantor.oid = acl.grantor
UNION ALL
SELECT
    'EFFECTIVE_RELATION_PRIVILEGE'::text,
    relation.nspname,
    relation.relname,
    NULL::text,
    NULL::text,
    NULL::text,
    NULL::boolean,
    role_row.rolname,
    has_table_privilege(role_row.oid, relation.relation_oid, 'SELECT'),
    has_table_privilege(role_row.oid, relation.relation_oid, 'INSERT'),
    has_table_privilege(role_row.oid, relation.relation_oid, 'UPDATE'),
    has_table_privilege(role_row.oid, relation.relation_oid, 'DELETE'),
    has_table_privilege(role_row.oid, relation.relation_oid, 'REFERENCES'),
    has_table_privilege(role_row.oid, relation.relation_oid, 'TRIGGER')
FROM target_relations AS relation
CROSS JOIN pg_roles AS role_row
WHERE role_row.rolname IN ('anon', 'authenticated', 'service_role')
ORDER BY schema_name, relation_name, evidence_kind, grantee, checked_role;
```

### Query 24-05B — Effective column privileges

**Purpose:** Capture column-level SELECT/INSERT/UPDATE/REFERENCES privileges that relation-level privilege booleans may not show.

```sql
WITH targets(schema_name, relation_name) AS (
    VALUES
        ('public', 'favorites'), ('public', 'reservations'),
        ('public', 'payments'), ('public', 'events'),
        ('public', 'audit_logs'), ('public', 'system_settings')
), target_relations AS (
    SELECT ns.nspname, rel.oid AS relation_oid, rel.relname
    FROM targets AS target
    JOIN pg_namespace AS ns ON ns.nspname = target.schema_name
    JOIN pg_class AS rel
      ON rel.relnamespace = ns.oid
     AND rel.relname = target.relation_name
     AND rel.relkind IN ('r', 'p', 'v', 'm', 'f')
)
SELECT
    relation.nspname AS schema_name,
    relation.relname AS relation_name,
    attr.attname AS column_name,
    role_row.rolname AS checked_role,
    has_column_privilege(role_row.oid, relation.relation_oid, attr.attname, 'SELECT') AS has_select,
    has_column_privilege(role_row.oid, relation.relation_oid, attr.attname, 'INSERT') AS has_insert,
    has_column_privilege(role_row.oid, relation.relation_oid, attr.attname, 'UPDATE') AS has_update,
    has_column_privilege(role_row.oid, relation.relation_oid, attr.attname, 'REFERENCES') AS has_references
FROM target_relations AS relation
JOIN pg_attribute AS attr
  ON attr.attrelid = relation.relation_oid
 AND attr.attnum > 0
 AND NOT attr.attisdropped
CROSS JOIN pg_roles AS role_row
WHERE role_row.rolname IN ('anon', 'authenticated', 'service_role')
ORDER BY relation.nspname, relation.relname, attr.attnum, role_row.rolname;
```

**Interpretation limit for 24-05A/B:** Privilege functions report SQL privileges visible to the SQL Editor context. They do not evaluate RLS, JWT claims, PostgREST exposure, row predicates, or actual user access. Do not use `service_role` to bypass restrictions; the query only reports its privilege metadata if visible.

### Query 24-06A — Migration-history relation discovery

Supabase CLI documentation identifies `supabase_migrations.schema_migrations` as its remote migration tracking relation. A NULL lookup for that one qualified name is limited to that object/visibility; custom migration tools or manually managed history may use other locations. This query checks the known name and inventories likely history relation names across non-system schemas without reading rows.

```sql
WITH candidate_relations AS (
    SELECT
        ns.nspname AS schema_name,
        rel.relname AS relation_name,
        rel.relkind AS relation_kind
    FROM pg_class AS rel
    JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
    WHERE ns.nspname NOT IN ('pg_catalog', 'information_schema')
      AND ns.nspname NOT LIKE 'pg_toast%'
      AND rel.relname IN (
          'schema_migrations', 'migration_history',
          'migration_versions', 'migrations'
      )
      AND rel.relkind IN ('r', 'p', 'v', 'm', 'f')
)
SELECT
    cli.relation_name AS supabase_cli_history_relation,
    candidate.schema_name,
    candidate.relation_name,
    candidate.relation_kind
FROM (
    SELECT to_regclass('supabase_migrations.schema_migrations')::text
        AS relation_name
) AS cli
LEFT JOIN candidate_relations AS candidate ON true
ORDER BY candidate.schema_name, candidate.relation_name;
```

**Interpretation limit:** This discovers only visible catalog relations with these names. It cannot prove there is no history table under an unrelated name, an external migration service, or another inaccessible schema. A NULL `to_regclass` value is not a global absence finding.

### Query 24-06B — Candidate migration-history column inventory

**Run after 24-06A** if it returns a candidate relation. This reports columns only, not migration contents.

```sql
SELECT
    ns.nspname AS schema_name,
    rel.relname AS relation_name,
    attr.attnum AS ordinal_position,
    attr.attname AS column_name,
    format_type(attr.atttypid, attr.atttypmod) AS data_type,
    attr.attnotnull AS not_null,
    pg_get_expr(def.adbin, def.adrelid) AS column_default
FROM pg_class AS rel
JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
JOIN pg_attribute AS attr
  ON attr.attrelid = rel.oid
 AND attr.attnum > 0
 AND NOT attr.attisdropped
LEFT JOIN pg_attrdef AS def
  ON def.adrelid = rel.oid
 AND def.adnum = attr.attnum
WHERE ns.nspname NOT IN ('pg_catalog', 'information_schema')
  AND ns.nspname NOT LIKE 'pg_toast%'
  AND rel.relname IN (
      'schema_migrations', 'migration_history',
      'migration_versions', 'migrations'
  )
  AND rel.relkind IN ('r', 'p', 'v', 'm', 'f')
ORDER BY ns.nspname, rel.relname, attr.attnum;
```

### Query 24-06C — Standard Supabase CLI applied version/name list (conditional)

**Run only if** 24-06A confirms `supabase_migrations.schema_migrations` and 24-06B confirms `version` and `name` columns. This reads migration identifiers/names only; it deliberately omits stored statement text.

```sql
SELECT version, name
FROM supabase_migrations.schema_migrations
ORDER BY version;
```

If the table or either column is absent, do not run this statement. Record the absent object/column and stop; do not substitute a guessed history table. For a custom candidate, request DBA/owner identification of the tracking contract first and prepare a separately reviewed, minimal query if needed. Do not inspect migration row contents from an unconfirmed relation.

Supabase’s official migration guide and CLI reference state that CLI remote migration history is tracked in `supabase_migrations.schema_migrations` and compared with the local migration directory: [Database migrations](https://supabase.com/docs/guides/deployment/database-migrations), [CLI `migration list`](https://supabase.com/docs/reference/cli/supabase-migration-list). This documents the known CLI convention; it does not prove this project uses it.

## 5. Repository migration inventory (static, not live history)

Task 20 inspected seven files in `supabase/migrations/`:

| File | Filename version | Repository-level description |
|---|---:|---|
| `001_add_role_to_profiles.sql` | 001 | Profile role patch and Auth signup trigger; existing Task 20 security concerns apply. |
| `002_fix_current_user_role.sql` | 002 | Repair/policy replacement script with prerequisites; not a clean bootstrap. |
| `002_rbac_dashboard_tables.sql` | 002 | Alternate dashboard schema and seed behavior; shares a version prefix with the preceding file. |
| `003_seed_dashboard_sample_data.sql` | 003 | Sample business/dashboard data; not approved as generic seed. |
| `004_full_schema_from_spec.sql` | 004 | Broad schema/migration with pre-existing dependencies and overlapping definitions. |
| `005_seed_sample_reservations.sql` | 005 | Sample reservation/payment/review/audit rows. |
| `006_seed_all_samal_places.sql` | 006 | Destination/verification seed records not established as authoritative evidence. |

These filenames describe repository files only. They do not prove any file was applied. The duplicate `002` prefix and Task 20’s bootstrap/conflict findings remain unresolved. Do not infer applied status from filenames, dashboard display alone, `.temp` files, or one NULL migration lookup.

## 6. Query coverage and known limits

| Query ID | Evidence | Expected scope | Critical limit |
|---|---|---|---|
| 24-01 | Six relation existence and columns | `public` targets in this package | Catalog visibility and exact project must be recorded. |
| 24-02 | PK/unique/check/FK definitions and actions | Constraints on present six targets | Empty output is ambiguous without 24-01. |
| 24-03 | Index definitions/flags | Indexes on present six targets | No performance conclusion or proposed index approval. |
| 24-04 | RLS flags and policies | Present/absent six targets | False on absent relation is not an RLS-disabled finding. |
| 24-05A | Relation ACL and table-level privileges | Present six targets; `anon`, `authenticated`, `service_role` if roles are visible | Does not evaluate RLS/JWT/PostgREST. |
| 24-05B | Column-level privileges | Present six targets and API roles if visible | Does not evaluate row policies or request claims. |
| 24-06A | Known/suspected history relation names | Visible non-system schemas | Name pattern cannot prove global absence. |
| 24-06B | Candidate history relation columns | Only named candidate relations | Catalog visibility remains a limitation. |
| 24-06C | Applied CLI migration version/name entries | Exact standard table only after metadata confirmation | Do not run on a guessed relation; query does not show migration SQL. |

## 7. Owner evidence recording template

Use one record per query. Duplicate this block for every run, including queries that return zero rows or errors.

| Field | Owner entry |
|---|---|
| Query ID and exact query revision | |
| Dashboard project name | |
| Project reference | |
| Region | |
| Execution date/time and time zone | |
| SQL Editor role/context (if known) | |
| Returned row count | |
| Complete sanitized output attached/reference | |
| Was output truncated? | |
| Error or permission limitation (exact non-sensitive text) | |
| Owner name and role confirming execution/project | |
| Sanitization confirmation (no secrets/personal/application rows) | |

**Evidence classification before independent review:** Owner-supplied evidence. A later repository review may verify output consistency and query-to-result mapping; it is not live-database independent verification.

## 8. Task 22/23 reconciliation addenda

This package prepares queries only. **No relation has been newly inspected and no new relationship, security, grant, or migration-history finding is established at preparation time.** After the owner returns results:

1. Add an evidence-only addendum to Task 22 and Task 23; do not rewrite their historical conclusions.
2. For each of the six relations, report `present`, `not found in inspected scope`, `permission-limited`, or `query error`, and link the 24-01 result and timestamp.
3. Report constraints/relationships from 24-02 only for confirmed-present relations. List FK target/action exactly; do not infer a relationship from similar column names.
4. Report indexes and `is_valid`/`is_ready`/`is_live` from 24-03 as owner-supplied catalog observations. Do not recommend changes solely from their presence/absence.
5. Report RLS/policies and grants as separate evidence. Do not infer access from policy metadata or table privileges alone.
6. Report migration history as: standard Supabase CLI table found/absent/not visible; any candidate relation; and exact scope. A NULL standard lookup leaves custom/external tracking unresolved.
7. Preserve all Task 22 DB-01–DB-18 statuses unless evidence and an explicit owner decision satisfy that decision’s closure criteria. Database relation absence does not approve the proposed schema.
8. Identify decisions that can proceed to technical review, but keep owner approval and execution authorization separate.

### Addendum recording template

- New relation(s) checked and query IDs: ______________________________
- Owner-supplied result classification and timestamp: ___________________
- Constraints/FK relationships established by supplied output: ___________
- Index and validity observations: _____________________________________
- RLS/policy/grant observations and limitations: _______________________
- Migration-history result and lookup scope: ___________________________
- Evidence not supplied / permissions / truncation: ____________________
- Task 22 decisions eligible for technical review (not approved): _______
- Task 22 decision statuses changed, with decision evidence/authorization: _
- Remaining unknowns and next evidence owner: ___________________________
- Reviewer role/date: __________________  Owner approval (if any): ______

## 9. Remaining blockers and next-step recommendations

- Owner execution and sanitized outputs are still required; the coding agent did not run these queries.
- The six relation states, constraints, indexes, RLS/policies, ACLs, and column grants remain unknown until outputs arrive.
- The standard migration-history lookup and any custom/external history remain unconfirmed; a NULL lookup must not be generalized.
- The seven checked-in migration files still have the duplicate `002` prefix and documented conflicts. They are not approved for execution.
- Task 22 owner decisions and canonical schema approval remain open. No absence result can substitute for those decisions.
- A separate synthetic-identity authorization test would be needed to establish actual application access after a schema exists; this catalog package does not perform that test.

**Recommended next action:** the project owner confirms the exact project and returns retained raw outputs for 24-01 through 24-06A/24-06B where applicable. Run 24-06C only if its prerequisite metadata is confirmed. Then reconcile the supplied results into Task 22 and Task 23 without changing decision status absent explicit approval.

## 10. Validation and closeout

- Query text is limited to read-only `SELECT`/`WITH` catalog queries; no application row data is selected.
- No query was executed or connected to PostgreSQL/Supabase during preparation.
- Project name/reference/region are included as owner-confirmation instructions, not independently verified target facts.
- The query pack does not authorize schema, migration, policy, grant, initialization, or production changes.
- **Created:** `docs/TASK_24_SAMALNAV_SUPPLEMENTAL_RUNTIME_SCHEMA_AND_MIGRATION_EVIDENCE_COLLECTION.md`.
