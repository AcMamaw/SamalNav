# Task 09B-H-A — Security Evidence Completion and Read-Only SQL Query Pack

**Status:** Query preparation only. No query in this document has been executed, and no database connection was made.

## 1. Purpose and evidence boundary

This pack is based on the owner-supplied findings documented in `docs/TASK_09B_F_PRODUCTION_SCHEMA_AND_SECURITY_RECONCILIATION.md` and `docs/TASK_09B_G_FINAL_RESERVATION_IMPLEMENTATION_READINESS.md`. The requested filename `TASK_09B_F_FINAL_RESERVATION_IMPLEMENTATION_READINESS.md` was not found; the readiness report is Task 09B-G. These reports are evidence supplied by the owner, not an independent production inspection.

The pack contains only read-only `SELECT` statements against PostgreSQL catalogs and information schema. It does not query application rows. In particular, it does not select profile, reservation, itinerary, notification, or audit-log records. Run queries individually in Supabase SQL Editor using an authorized project-owner session. Save the sanitized outputs with the task evidence; catalog visibility can depend on the executing role.

### Existing security evidence to verify or complete

- Owner-supplied I-6 reports table-level `SELECT` grants on `public.profiles` for `anon` and `authenticated`.
- Owner-supplied policy summaries report permissive profile `SELECT` policies using `true`.
- `profiles` includes email and phone according to supplied column metadata. The grant and policy findings indicate potential exposure of every profile column readable under effective table/column privileges, including email and phone. They do not by themselves establish final role-and-column access: schema `USAGE`, exact policy roles, column ACLs, inherited/PUBLIC grants, API exposure, views, and execution context matter.
- SQL grants and RLS are independent gates. RLS does not provide column-level privacy. A broad permissive policy can widen rows visible to roles to which it applies; permissive policies combine with OR semantics.
- The supplied report describes `admin_toggle_owner_verification(uuid, boolean)` as `SECURITY DEFINER` and includes the authorization expression `caller_role NOT IN ('administrator', 'super_admin')`. When `caller_role` is `NULL`, `NOT IN` evaluates to SQL `NULL`; a PL/pgSQL `IF` enters its branch only when its condition is true. If that expression is the only rejection guard, a missing profile or unresolved role may fail to enter the rejection branch. This is an authorization risk for separate review, not a verified exploit and not a proposed change in this task.
- The existing `public.reservations` table is an establishment-side workflow. It must not be treated as the proposed tourist-entered reservation-event store.
- Supplied I-3 confirms two foreign keys from `reservations.itinerary_id` to `itineraries(id)`, both `ON DELETE SET NULL`: `reservations_itinerary_fk` and `reservations_itinerary_id_fkey`. Their origin, necessity, and remediation are unverified.
- Supplied policy summaries mention tourist/owner/admin reservation access, Super Administrator audit-log reads, and authenticated audit-log inserts. Exact predicates and effective access remain to be inspected.

## 2. How to interpret the catalog results

1. A privilege result establishes SQL privilege according to the catalog and the inspection role's visibility. It does not bypass RLS or prove which rows a request will return.
2. An RLS policy result describes policy expressions, command, role targets, and permissive/restrictive mode. It does not establish the caller's grants, JWT claims, function behavior, or final API behavior.
3. PostgreSQL combines applicable permissive policies with OR and applicable restrictive policies with AND, after policy applicability is determined. RLS is enabled but not forced on the supplied inspected tables, so owner/bypass contexts need separate treatment.
4. “No rows” can mean no matching object, insufficient catalog visibility, or a role/filter mismatch. It is not proof that production is empty or secure.
5. `service_role` is included in role-targeted checks if visible, but its presence and behavior must not be inferred from an empty result. Do not share its credentials or use it for client access.
6. These queries do not prove data contents, application-level authorization, view/API exposure, or exploitability. Any behavior testing should use an approved non-production environment and test identities, never private production records.

## 3. Read-only query pack

### Query 1 — Schema privileges and role attributes

```sql
SELECT
  r.rolname AS role_name,
  r.rolcanlogin AS can_login,
  r.rolsuper AS is_superuser,
  r.rolinherit AS inherits_privileges,
  r.rolbypassrls AS bypasses_rls,
  n.nspname AS schema_name,
  has_schema_privilege(r.oid, n.oid, 'USAGE') AS has_schema_usage,
  has_schema_privilege(r.oid, n.oid, 'CREATE') AS has_schema_create
FROM pg_roles AS r
CROSS JOIN pg_namespace AS n
WHERE r.rolname IN ('anon', 'authenticated', 'service_role', 'public')
  AND n.nspname = 'public'
ORDER BY r.rolname;
```

**Purpose:** Checks whether the named roles can use or create objects in the `public` schema and returns relevant role attributes.

**Expected columns:** `role_name`, `can_login`, `is_superuser`, `inherits_privileges`, `bypasses_rls`, `schema_name`, `has_schema_usage`, `has_schema_create`.

**Limitations:** `PUBLIC` is a PostgreSQL pseudo-role, not normally a row in `pg_roles`, so it will not appear here. PUBLIC schema grants are covered by Query 2. This does not show all role memberships; use Query 5. Catalog visibility and whether `service_role` is visible depend on the inspection session.

### Query 2 — Explicit table-level grants for security-relevant tables

```sql
SELECT
  table_schema,
  table_name,
  grantee,
  privilege_type,
  is_grantable,
  grantor
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN (
    'profiles', 'establishments', 'activities', 'events',
    'itineraries', 'itinerary_stops', 'reservations',
    'audit_logs', 'notifications'
  )
ORDER BY table_name, grantee, privilege_type;
```

**Purpose:** Lists visible table-level grants, including explicit `PUBLIC` grants if exposed by information schema.

**Expected columns:** `table_schema`, `table_name`, `grantee`, `privilege_type`, `is_grantable`, `grantor`.

**Limitations:** This is an information-schema view subject to its visibility rules. It does not show column grants; Query 3 covers profile column grants. It does not by itself fold all inherited or PUBLIC privileges into an effective check; Query 4 supplies role-specific effective checks. A grant does not establish that RLS permits a row operation.

### Query 3 — Explicit column-level privileges on `profiles`

```sql
SELECT
  table_schema,
  table_name,
  column_name,
  grantee,
  privilege_type,
  is_grantable,
  grantor
FROM information_schema.column_privileges
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND grantee IN ('PUBLIC', 'anon', 'authenticated', 'service_role')
ORDER BY column_name, grantee, privilege_type;
```

**Purpose:** Identifies explicit visible column grants/revokes represented in information schema, including whether sensitive fields such as email or phone have column-specific grants.

**Expected columns:** `table_schema`, `table_name`, `column_name`, `grantee`, `privilege_type`, `is_grantable`, `grantor`.

**Limitations:** This query lists columns that have explicit privilege entries; an absent row is not proof of no access because table-level privileges, PUBLIC privileges, and role membership can grant access. Query 4 checks effective SELECT privilege for every actual profile column. The query does not read profile values.

### Query 4 — Effective SQL SELECT privilege per existing profile column

```sql
SELECT
  r.rolname AS role_name,
  c.column_name,
  c.data_type,
  has_table_privilege(
    r.oid,
    format('%I.%I', c.table_schema, c.table_name),
    'SELECT'
  ) AS has_effective_table_select,
  has_column_privilege(
    r.oid,
    format('%I.%I', c.table_schema, c.table_name),
    c.column_name,
    'SELECT'
  ) AS has_effective_column_select
FROM pg_roles AS r
CROSS JOIN information_schema.columns AS c
WHERE r.rolname IN ('anon', 'authenticated', 'service_role')
  AND c.table_schema = 'public'
  AND c.table_name = 'profiles'
ORDER BY r.rolname, c.ordinal_position;
```

**Purpose:** Checks effective SQL-level `SELECT` privilege for each column that exists on `public.profiles`, without returning any column values. This directly identifies whether email, phone, username, or other actual profile columns are SQL-readable by each listed role.

**Expected columns:** `role_name`, `column_name`, `data_type`, `has_effective_table_select`, `has_effective_column_select`.

**Limitations:** It does not evaluate RLS row visibility, schema/API exposure, views, functions, or the JWT claims used in an API request. It reports privilege checks for database roles, not a complete Supabase PostgREST request simulation. The result should be interpreted together with Queries 1–3 and 6. It uses only column metadata, not user records.

### Query 5 — Direct and transitive role memberships

```sql
WITH RECURSIVE membership_tree AS (
  SELECT
    r.rolname AS starting_role,
    r.oid AS current_member_oid,
    r.rolname AS current_member,
    0 AS membership_depth,
    ARRAY[r.oid] AS visited
  FROM pg_roles AS r
  WHERE r.rolname IN ('anon', 'authenticated', 'service_role')

  UNION ALL

  SELECT
    mt.starting_role,
    m.roleid AS current_member_oid,
    parent_role.rolname AS current_member,
    mt.membership_depth + 1,
    mt.visited || m.roleid
  FROM membership_tree AS mt
  JOIN pg_auth_members AS m ON m.member = mt.current_member_oid
  JOIN pg_roles AS parent_role ON parent_role.oid = m.roleid
  WHERE NOT m.roleid = ANY(mt.visited)
)
SELECT
  mt.starting_role,
  member_role.rolname AS member_role,
  inherited_role.rolname AS inherited_role,
  mt.membership_depth,
  grantor_role.rolname AS grantor,
  m.admin_option
FROM membership_tree AS mt
JOIN pg_auth_members AS m ON m.roleid = mt.current_member_oid
JOIN pg_roles AS member_role ON member_role.oid = m.member
JOIN pg_roles AS inherited_role ON inherited_role.oid = m.roleid
JOIN pg_roles AS grantor_role ON grantor_role.oid = m.grantor
WHERE mt.membership_depth > 0
ORDER BY mt.starting_role, mt.membership_depth, member_role.rolname, inherited_role.rolname;
```

**Purpose:** Shows each membership edge on paths starting at `anon`, `authenticated`, and `service_role`. For each edge it reports the role that is a member and the role inherited/granted to that member, with path depth and the grantor/admin option for that exact `pg_auth_members` row. The recursive traversal starts from each target role and follows memberships where that role is the member.

**Expected columns:** `starting_role`, `member_role`, `inherited_role`, `membership_depth`, `grantor`, `admin_option`.

**Limitations:** The `visited` OID array prevents membership cycles. Membership inheritance behavior can depend on PostgreSQL version and role attributes. Membership paths alone do not calculate every effective privilege; review the role attributes and privilege checks in Queries 1–4 and 9–10. The query intentionally avoids newer-version-only membership fields. No output can mean no membership path or insufficient catalog visibility.

### Query 6 — RLS enabled/forced state for the requested tables

```sql
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS rls_forced,
  c.relkind AS relation_kind
FROM pg_class AS c
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')
  AND c.relname IN (
    'profiles', 'establishments', 'activities', 'events',
    'itineraries', 'itinerary_stops', 'reservations',
    'audit_logs', 'notifications'
  )
ORDER BY c.relname;
```

**Purpose:** Verifies which requested ordinary/partitioned tables exist and their RLS flags.

**Expected columns:** `schema_name`, `table_name`, `rls_enabled`, `rls_forced`, `relation_kind`.

**Limitations:** RLS flags do not show policies or grants. A missing row is not proof of absence if catalog visibility is restricted or the object is not an ordinary/partitioned table. Query 7 supplies policies.

### Query 7 — Complete visible RLS policy inventory

```sql
SELECT
  schemaname AS schema_name,
  tablename AS table_name,
  policyname AS policy_name,
  permissive,
  roles AS target_roles,
  cmd AS command,
  qual AS using_expression,
  with_check AS with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'profiles', 'establishments', 'activities', 'events',
    'itineraries', 'itinerary_stops', 'reservations',
    'audit_logs', 'notifications'
  )
ORDER BY tablename, policyname;
```

**Purpose:** Retrieves policy role targets, command, permissive/restrictive mode, `USING`, and `WITH CHECK` expressions for the requested tables.

**Expected columns:** `schema_name`, `table_name`, `policy_name`, `permissive`, `target_roles`, `command`, `using_expression`, `with_check_expression`.

**Limitations:** Policies are only one part of effective access. Applicable permissive policies combine with OR; restrictive policies combine with AND. Role membership, grants, `auth.uid()`/JWT context, `SECURITY DEFINER` functions, table ownership, and `BYPASSRLS` also matter. RLS is reported not forced on inspected tables in supplied evidence; verify Query 6. Do not infer that no returned policy means the table has no access path. `pg_policies` visibility follows PostgreSQL catalog access rules.

### Query 8 — Function identity, owner, definition, security mode, and search path

```sql
WITH requested_functions AS (
  SELECT to_regprocedure('public.admin_toggle_owner_verification(uuid,boolean)') AS function_oid
  UNION ALL
  SELECT to_regprocedure('public.current_user_role()') AS function_oid
)
SELECT
  n.nspname AS schema_name,
  p.proname AS function_name,
  p.oid::regprocedure AS function_signature,
  pg_get_function_identity_arguments(p.oid) AS identity_arguments,
  pg_get_function_result(p.oid) AS return_type,
  p.prokind AS routine_kind,
  owner_role.rolname AS function_owner,
  p.prosecdef AS security_definer,
  p.proconfig AS configured_settings,
  pg_get_functiondef(p.oid) AS complete_definition
FROM requested_functions AS requested
JOIN pg_proc AS p ON p.oid = requested.function_oid
JOIN pg_namespace AS n ON n.oid = p.pronamespace
JOIN pg_roles AS owner_role ON owner_role.oid = p.proowner
ORDER BY function_signature;
```

**Purpose:** Looks up the exact two named functions by signature and returns full definitions plus owner, identity arguments, return type, routine kind, `SECURITY DEFINER`, and per-function settings such as `search_path`.

**Expected columns:** `schema_name`, `function_name`, `function_signature`, `identity_arguments`, `return_type`, `routine_kind`, `function_owner`, `security_definer`, `configured_settings`, `complete_definition`.

**Limitations:** Missing function rows may indicate absence, a signature mismatch, or limited catalog visibility. `proconfig` shows function-level settings only; a null value means no function-level setting is recorded, not necessarily a safe effective search path. A definition alone does not establish who may execute it or how the caller context behaves. Review Query 9. Treat function bodies as sensitive implementation metadata when sharing output.

### Query 9 — Function EXECUTE ACL entries and effective role checks

```sql
WITH requested_functions AS (
  SELECT to_regprocedure('public.admin_toggle_owner_verification(uuid,boolean)') AS function_oid
  UNION ALL
  SELECT to_regprocedure('public.current_user_role()') AS function_oid
), target_roles AS (
  SELECT oid, rolname
  FROM pg_roles
  WHERE rolname IN ('anon', 'authenticated', 'service_role')
)
SELECT
  p.oid::regprocedure AS function_signature,
  CASE
    WHEN acl.grantee = 0 THEN 'PUBLIC'
    ELSE grantee_role.rolname
  END AS acl_grantee,
  acl.privilege_type,
  acl.is_grantable,
  r.rolname AS checked_role,
  has_function_privilege(r.oid, p.oid, 'EXECUTE') AS has_effective_execute
FROM requested_functions AS requested
JOIN pg_proc AS p ON p.oid = requested.function_oid
CROSS JOIN LATERAL aclexplode(
  COALESCE(p.proacl, acldefault('f', p.proowner))
) AS acl
LEFT JOIN pg_roles AS grantee_role ON grantee_role.oid = acl.grantee
LEFT JOIN target_roles AS r ON TRUE
ORDER BY function_signature, acl_grantee, checked_role;
```

**Purpose:** Lists explicit/default function ACL entries (including grantee `PUBLIC` where present) and checks effective `EXECUTE` privileges for the listed roles, including inherited/PUBLIC paths understood by PostgreSQL's privilege checker.

**Expected columns:** `function_signature`, `acl_grantee`, `privilege_type`, `is_grantable`, `checked_role`, `has_effective_execute`.

**Limitations:** `aclexplode` and `acldefault` inspect ACL metadata; output depends on catalog visibility. A null `proacl` is expanded using PostgreSQL's default function ACL. Effective checks do not describe RLS behavior inside the function, caller identity assumptions, or whether the function is reachable through an exposed API. Compare with Query 1 and Query 8. If the SQL Editor role cannot inspect function ACLs, record that limitation rather than treating no rows as no grants.

### Query 10 — Effective SQL privileges for reservation and audit relations

```sql
WITH target_roles AS (
  SELECT oid, rolname
  FROM pg_roles
  WHERE rolname IN ('anon', 'authenticated', 'service_role')
), target_tables AS (
  SELECT c.oid, n.nspname, c.relname
  FROM pg_class AS c
  JOIN pg_namespace AS n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relkind IN ('r', 'p')
    AND c.relname IN (
      'reservations', 'audit_logs', 'profiles', 'itineraries',
      'itinerary_stops', 'establishments', 'activities', 'events', 'notifications'
    )
)
SELECT
  r.rolname AS role_name,
  t.nspname AS schema_name,
  t.relname AS table_name,
  has_table_privilege(r.oid, t.oid, 'SELECT') AS can_select,
  has_table_privilege(r.oid, t.oid, 'INSERT') AS can_insert,
  has_table_privilege(r.oid, t.oid, 'UPDATE') AS can_update,
  has_table_privilege(r.oid, t.oid, 'DELETE') AS can_delete,
  has_table_privilege(r.oid, t.oid, 'TRUNCATE') AS can_truncate,
  has_table_privilege(r.oid, t.oid, 'REFERENCES') AS can_reference,
  has_table_privilege(r.oid, t.oid, 'TRIGGER') AS can_create_trigger
FROM target_roles AS r
CROSS JOIN target_tables AS t
ORDER BY t.relname, r.rolname;
```

**Purpose:** Checks effective SQL-level relation privileges for the roles of interest, with specific attention to the existing `reservations` and `audit_logs` tables and related owner/parent tables.

**Expected columns:** `role_name`, `schema_name`, `table_name`, `can_select`, `can_insert`, `can_update`, `can_delete`, `can_truncate`, `can_reference`, `can_create_trigger`.

**Limitations:** This does not evaluate row-level policy outcomes. It reports database privilege checks, not application CRUD behavior. Column-specific `INSERT`/`UPDATE` grants require separate column checks if the table-level results do not explain access. Table absence/visibility affects output. Do not read actual reservation or audit records as part of this review.

### Query 11 — Reservation and establishment ownership constraints

```sql
SELECT
  con.conname AS constraint_name,
  con.contype AS constraint_type,
  con.convalidated AS is_validated,
  source_ns.nspname AS source_schema,
  source_table.relname AS source_table,
  target_ns.nspname AS referenced_schema,
  target_table.relname AS referenced_table,
  pg_get_constraintdef(con.oid, true) AS constraint_definition
FROM pg_constraint AS con
JOIN pg_class AS source_table ON source_table.oid = con.conrelid
JOIN pg_namespace AS source_ns ON source_ns.oid = source_table.relnamespace
LEFT JOIN pg_class AS target_table ON target_table.oid = con.confrelid
LEFT JOIN pg_namespace AS target_ns ON target_ns.oid = target_table.relnamespace
WHERE source_ns.nspname = 'public'
  AND source_table.relname IN ('reservations', 'establishments')
  AND con.contype IN ('f', 'c', 'u', 'p')
ORDER BY con.contype, con.conname;
```

**Purpose:** Lists foreign keys, checks, unique constraints, and primary keys declared on both `public.reservations` and `public.establishments`. It can verify the supplied duplicate itinerary-FK names/actions, inspect reservation identity/reference constraints, and confirm whether an owner uniqueness constraint exists on establishments.

**Expected columns:** `constraint_name`, `constraint_type`, `is_validated`, `source_schema`, `source_table`, `referenced_schema`, `referenced_table`, `constraint_definition`.

**Limitations:** Ordinary foreign keys and unique constraints do not by themselves establish the full reservation-to-itinerary same-owner authorization invariant. In particular, independent foreign keys from `reservations.tourist_id` and `reservations.itinerary_id` do not prove that both references belong to the same tourist. A missing same-owner constraint does not alone prove an exploitable access path; inspect RLS, grants, write paths, triggers, and function behavior. Constraint metadata does not establish origin, necessity, or safe remediation of the duplicate itinerary FKs. Do not query reservation rows.

## 4. Recommended execution order

1. Query 1 — schema use and role attributes.
2. Queries 2–4 — grants and effective per-column profile SQL access.
3. Query 5 — role memberships.
4. Queries 6–7 — table RLS state and complete visible policy inventory.
5. Queries 8–9 — exact function definitions and execute access.
6. Queries 10–11 — reservation/audit privileges and reservation constraints.

Record the SQL Editor role used, query timestamp, and any permission/catalog visibility errors. Share results with private values omitted; these queries are designed not to return application records. Function definitions and policy expressions may still reveal implementation details, so distribute them only to the authorized reviewers.

## 5. Evidence still needed after query execution

The result bundle should allow reviewers to reconcile:

- Whether `anon` and `authenticated` can use schema `public` and which profile columns they can read at SQL privilege level.
- Whether public or inherited table/column grants alter the supplied I-6 summary.
- Which exact profile RLS policies apply to which roles and commands, and whether permissive `true` policies widen access.
- Exact definitions and EXECUTE ACL/effective execution for both SECURITY DEFINER functions, including function-level `search_path` settings.
- Role membership paths that affect effective grants.
- Exact policy interactions for establishments, activities, events, itineraries, itinerary stops, reservations, audit logs, and notifications.
- Whether database constraints couple reservation tourist identity with itinerary ownership; constraints alone cannot establish the complete authorization invariant.
- The exact table-level permissions relevant to reservation privacy and audit-log forgery concerns.

Even after this catalog collection, a final effective-access assessment may require approved non-production tests using representative roles/JWT claims. Do not test by selecting private production rows, changing roles, attempting privilege escalation, or modifying production objects. No remediation is specified or authorized by this query pack.
