-- Task 09B-H-I — Production schema evidence query pack
-- Version: 001 | READ-ONLY | Run each SELECT independently in Supabase SQL Editor.
-- Scope: production catalog metadata only; never reads application table rows.
-- Do not execute DDL or functions. Do not use this file with a migration command.
-- Review the active project banner and confirm the owner-authorized production
-- evidence session before each manual query. This file contains no credentials.
--
-- Standard interpretation: an empty result is not proof of absence. It may
-- indicate a filter mismatch, insufficient catalog visibility, or no matching
-- object. Record query errors separately and request complete/untruncated output.
-- Target relations include the H-G reproduction set and SEC-03 support relations.

-- QUERY 01 — Relation inventory and exact column/type/default metadata
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.relkind AS relation_kind,
    a.attnum AS ordinal_position,
    a.attname AS column_name,
    format_type (a.atttypid, a.atttypmod) AS formatted_type,
    type_ns.nspname AS declared_type_schema,
    typ.typname AS declared_type_name,
    typ.typtype AS declared_type_kind,
    coll_ns.nspname AS collation_schema,
    coll.collname AS collation_name,
    a.attnotnull AS is_not_null,
    pg_get_expr (def.adbin, def.adrelid) AS default_expression,
    a.attidentity AS identity_kind,
    a.attgenerated AS generated_kind,
    CASE
        WHEN a.attgenerated <> '' THEN pg_get_expr (def.adbin, def.adrelid)
        ELSE NULL
    END AS generated_expression
FROM
    pg_class AS c
    JOIN pg_namespace AS n ON n.oid = c.relnamespace
    JOIN pg_attribute AS a ON a.attrelid = c.oid
    JOIN pg_type AS typ ON typ.oid = a.atttypid
    JOIN pg_namespace AS type_ns ON type_ns.oid = typ.typnamespace
    LEFT JOIN pg_collation AS coll ON coll.oid = a.attcollation
    AND a.attcollation <> 0
    LEFT JOIN pg_namespace AS coll_ns ON coll_ns.oid = coll.collnamespace
    LEFT JOIN pg_attrdef AS def ON def.adrelid = c.oid
    AND def.adnum = a.attnum
WHERE
    n.nspname = 'public'
    AND c.relkind IN ('r', 'p', 'v', 'm', 'f')
    AND a.attnum > 0
    AND NOT a.attisdropped
    AND c.relname IN (
        'profiles',
        'establishments',
        'activities',
        'events',
        'itineraries',
        'destinations',
        'itinerary_stops',
        'reservations',
        'audit_logs',
        'notifications'
    )
ORDER BY c.relname, a.attnum;

-- Expected: one row per visible column, including exact formatted type,
-- typmod (length/precision), nullability, defaults, identity/generated data.
-- A missing relation produces no rows; compare with the requested relation list.

-- QUERY 02 — Primary, unique, check, exclusion, and foreign-key constraints
WITH
    target_relations AS (
        SELECT c.oid
        FROM pg_class AS c
            JOIN pg_namespace AS n ON n.oid = c.relnamespace
        WHERE
            n.nspname = 'public'
            AND c.relname IN (
                'profiles',
                'establishments',
                'activities',
                'events',
                'itineraries',
                'destinations',
                'itinerary_stops',
                'reservations',
                'audit_logs',
                'notifications'
            )
    )
SELECT
    source_ns.nspname AS source_schema,
    source_rel.relname AS source_table,
    con.conname AS constraint_name,
    con.contype AS constraint_kind,
    con.convalidated AS is_validated,
    con.condeferrable AS is_deferrable,
    con.condeferred AS initially_deferred,
    target_ns.nspname AS referenced_schema,
    target_rel.relname AS referenced_table,
    CASE
        WHEN con.contype = 'f' THEN ARRAY (
            SELECT source_att.attname
            FROM unnest (con.conkey)
            WITH
                ORDINALITY AS key (attnum, ord)
                JOIN pg_attribute AS source_att ON source_att.attrelid = con.conrelid
                AND source_att.attnum = key.attnum
            ORDER BY key.ord
        )
    END AS source_columns,
    CASE
        WHEN con.contype = 'f' THEN ARRAY (
            SELECT target_att.attname
            FROM unnest (con.confkey)
            WITH
                ORDINALITY AS key (attnum, ord)
                JOIN pg_attribute AS target_att ON target_att.attrelid = con.confrelid
                AND target_att.attnum = key.attnum
            ORDER BY key.ord
        )
    END AS referenced_columns,
    CASE
        WHEN con.contype = 'f' THEN con.confdeltype
    END AS delete_action_code,
    CASE
        WHEN con.contype = 'f' THEN con.confupdtype
    END AS update_action_code,
    CASE
        WHEN con.contype = 'f' THEN con.confmatchtype
    END AS match_type_code,
    pg_get_constraintdef (con.oid, true) AS constraint_definition
FROM
    pg_constraint AS con
    JOIN pg_class AS source_rel ON source_rel.oid = con.conrelid
    JOIN pg_namespace AS source_ns ON source_ns.oid = source_rel.relnamespace
    LEFT JOIN pg_class AS target_rel ON target_rel.oid = con.confrelid
    LEFT JOIN pg_namespace AS target_ns ON target_ns.oid = target_rel.relnamespace
WHERE
    con.conrelid IN (
        SELECT oid
        FROM target_relations
    )
    OR (
        con.contype = 'f'
        AND con.confrelid IN (
            SELECT oid
            FROM target_relations
        )
    )
ORDER BY source_ns.nspname, source_rel.relname, con.conname;

-- Expected: local constraints plus incoming foreign keys referencing a target.
-- Action codes: a=no action, r=restrict, c=cascade, n=set null, d=set default.
-- `constraint_definition` is authoritative; do not infer constraints from names.

-- QUERY 03 — Index definitions for target relations
SELECT
    ns.nspname AS schema_name,
    tbl.relname AS table_name,
    idx.relname AS index_name,
    i.indisprimary AS is_primary,
    i.indisunique AS is_unique,
    i.indisexclusion AS is_exclusion,
    i.indisvalid AS is_valid,
    i.indisready AS is_ready,
    pg_get_indexdef (i.indexrelid) AS index_definition,
    pg_get_expr (i.indpred, i.indrelid) AS predicate_expression,
    pg_get_expr (i.indexprs, i.indrelid) AS expression_definition
FROM
    pg_index AS i
    JOIN pg_class AS tbl ON tbl.oid = i.indrelid
    JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
    JOIN pg_class AS idx ON idx.oid = i.indexrelid
WHERE
    ns.nspname = 'public'
    AND tbl.relname IN (
        'profiles',
        'establishments',
        'activities',
        'events',
        'itineraries',
        'destinations',
        'itinerary_stops',
        'reservations',
        'audit_logs',
        'notifications'
    )
ORDER BY tbl.relname, idx.relname;

-- Expected: complete visible index definitions, including unique, partial,
-- and expression indexes. No index recommendation is implied by this output.

-- QUERY 04 — Triggers and referenced trigger functions
SELECT
  ns.nspname AS schema_name,
  tbl.relname AS table_name,
  trg.tgname AS trigger_name,
  trg.tgenabled AS enabled_state,
  trg.tgisinternal AS is_internal,
  pg_get_triggerdef(trg.oid, true) AS trigger_definition,
  fn_ns.nspname AS function_schema,
  fn.proname AS function_name,
  fn.oid::regprocedure::text AS function_signature,
  pg_get_functiondef(fn.oid) AS trigger_function_definition
FROM pg_trigger AS trg
JOIN pg_class AS tbl ON tbl.oid = trg.tgrelid
JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
JOIN pg_proc AS fn ON fn.oid = trg.tgfoid
JOIN pg_namespace AS fn_ns ON fn_ns.oid = fn.pronamespace
WHERE ns.nspname = 'public'
  AND tbl.relname IN (
    'profiles', 'establishments', 'activities', 'events',
    'itineraries', 'destinations', 'itinerary_stops', 'reservations',
    'audit_logs', 'notifications'
  )
ORDER BY tbl.relname, trg.tgname;

-- Expected: trigger timing/events/definition and trigger-function body.
-- Zero rows can mean no visible trigger; record query errors separately.

-- QUERY 05 — RLS flags and policy definitions
SELECT
    ns.nspname AS schema_name,
    tbl.relname AS table_name,
    tbl.relrowsecurity AS rls_enabled,
    tbl.relforcerowsecurity AS rls_forced,
    pol.polname AS policy_name,
    CASE pol.polpermissive
        WHEN true THEN 'PERMISSIVE'
        WHEN false THEN 'RESTRICTIVE'
    END AS policy_mode,
    pol.polcmd AS command_code,
    CASE
        WHEN pol.polcmd = '*' THEN 'ALL'
        WHEN pol.polcmd = 'r' THEN 'SELECT'
        WHEN pol.polcmd = 'a' THEN 'INSERT'
        WHEN pol.polcmd = 'w' THEN 'UPDATE'
        WHEN pol.polcmd = 'd' THEN 'DELETE'
    END AS command_name,
    ARRAY (
        SELECT
            CASE
                WHEN role_oid = 0 THEN 'PUBLIC'
                ELSE role_row.rolname
            END
        FROM
            unnest (pol.polroles) AS target (role_oid)
            LEFT JOIN pg_roles AS role_row ON role_row.oid = target.role_oid
    ) AS target_roles,
    pg_get_expr (pol.polqual, pol.polrelid) AS using_expression,
    pg_get_expr (
        pol.polwithcheck,
        pol.polrelid
    ) AS with_check_expression
FROM
    pg_class AS tbl
    JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
    LEFT JOIN pg_policy AS pol ON pol.polrelid = tbl.oid
WHERE
    ns.nspname = 'public'
    AND tbl.relkind IN ('r', 'p')
    AND tbl.relname IN (
        'profiles',
        'establishments',
        'activities',
        'events',
        'itineraries',
        'destinations',
        'itinerary_stops',
        'reservations',
        'audit_logs',
        'notifications'
    )
ORDER BY tbl.relname, pol.polname;

-- Expected: one row per policy; a target with no policies still appears with
-- NULL policy fields and RLS flags. Policy text does not establish effective
-- access without grants, role membership, caller identity, and API testing.

-- QUERY 06 — Explicit schema ACL entries (including default ACL expansion)
SELECT
    ns.nspname AS schema_name,
    CASE
        WHEN ns.nspacl IS NULL THEN 'POSTGRESQL_DEFAULT_ACL'
        ELSE 'STORED_ACL'
    END AS acl_source,
    CASE acl.grantee
        WHEN 0 THEN 'PUBLIC'
        ELSE grantee.rolname
    END AS grantee,
    grantor.rolname AS grantor,
    acl.privilege_type,
    acl.is_grantable
FROM
    pg_namespace AS ns
    CROSS JOIN LATERAL aclexplode (
        COALESCE(
            ns.nspacl,
            acldefault ('n', ns.nspowner)
        )
    ) AS acl
    LEFT JOIN pg_roles AS grantee ON grantee.oid = acl.grantee
    LEFT JOIN pg_roles AS grantor ON grantor.oid = acl.grantor
WHERE
    ns.nspname !~ 'pg_'
    AND ns.nspname <> 'information_schema'
ORDER BY ns.nspname, grantee, acl.privilege_type, grantor;

-- Expected: explicit ACL entries plus PostgreSQL defaults when ACL is NULL
-- for non-system schemas. PUBLIC is ACL grantee OID 0. Catalog visibility may
-- limit results.

-- QUERY 07 — Explicit relation ACL entries, preserving grantor and grant option
SELECT
    ns.nspname AS schema_name,
    rel.relname AS relation_name,
    rel.relkind AS relation_kind,
    CASE
        WHEN rel.relacl IS NULL THEN 'POSTGRESQL_DEFAULT_ACL'
        ELSE 'STORED_ACL'
    END AS acl_source,
    CASE acl.grantee
        WHEN 0 THEN 'PUBLIC'
        ELSE grantee.rolname
    END AS grantee,
    grantor.rolname AS grantor,
    acl.privilege_type,
    acl.is_grantable
FROM
    pg_class AS rel
    JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
    CROSS JOIN LATERAL aclexplode (
        COALESCE(
            rel.relacl,
            acldefault ('r', rel.relowner)
        )
    ) AS acl
    LEFT JOIN pg_roles AS grantee ON grantee.oid = acl.grantee
    LEFT JOIN pg_roles AS grantor ON grantor.oid = acl.grantor
WHERE
    ns.nspname = 'public'
    AND rel.relname IN (
        'profiles',
        'establishments',
        'activities',
        'events',
        'itineraries',
        'destinations',
        'itinerary_stops',
        'reservations',
        'audit_logs',
        'notifications'
    )
ORDER BY rel.relname, grantee, acl.privilege_type, grantor;

-- Expected: table-level direct/default ACL entries. This does not include
-- column grants (Query 08) or calculate inherited/effective privileges (Query 10).

-- QUERY 08 — Explicit column-level ACL entries for target tables
SELECT
    ns.nspname AS schema_name,
    rel.relname AS table_name,
    att.attname AS column_name,
    CASE acl.grantee
        WHEN 0 THEN 'PUBLIC'
        ELSE grantee.rolname
    END AS grantee,
    grantor.rolname AS grantor,
    acl.privilege_type,
    acl.is_grantable
FROM
    pg_attribute AS att
    JOIN pg_class AS rel ON rel.oid = att.attrelid
    JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
    CROSS JOIN LATERAL aclexplode (att.attacl) AS acl
    LEFT JOIN pg_roles AS grantee ON grantee.oid = acl.grantee
    LEFT JOIN pg_roles AS grantor ON grantor.oid = acl.grantor
WHERE
    ns.nspname = 'public'
    AND rel.relname IN (
        'profiles',
        'establishments',
        'activities',
        'events',
        'itineraries',
        'destinations',
        'itinerary_stops',
        'reservations',
        'audit_logs',
        'notifications'
    )
    AND att.attnum > 0
    AND NOT att.attisdropped
ORDER BY rel.relname, att.attnum, grantee, acl.privilege_type;

-- Expected: explicit column ACL entries only; no row means no column-specific
-- ACL entry, not no access (relation grants and membership may still apply).

-- QUERY 09 — Explicit sequence ACLs and sequence ownership
SELECT
  seq_ns.nspname AS sequence_schema,
  seq.relname AS sequence_name,
  seq_owner.rolname AS sequence_owner,
  dep.deptype AS ownership_dependency_type,
  tbl_ns.nspname AS owning_table_schema,
  tbl.relname AS owning_table,
  att.attname AS owning_column,
  seq_data.seqstart AS start_value,
  seq_data.seqincrement AS increment_by,
  seq_data.seqmin AS minimum_value,
  seq_data.seqmax AS maximum_value,
  seq_data.seqcache AS cache_size,
  seq_data.seqcycle AS cycles,
  CASE WHEN seq.relacl IS NULL THEN 'POSTGRESQL_DEFAULT_ACL' ELSE 'STORED_ACL' END AS acl_source,
  CASE acl.grantee WHEN 0 THEN 'PUBLIC' ELSE grantee.rolname END AS grantee,
  grantor.rolname AS grantor,
  acl.privilege_type,
  acl.is_grantable
FROM pg_class AS seq
JOIN pg_namespace AS seq_ns ON seq_ns.oid = seq.relnamespace
JOIN pg_roles AS seq_owner ON seq_owner.oid = seq.relowner
JOIN pg_sequence AS seq_data ON seq_data.seqrelid = seq.oid
LEFT JOIN pg_depend AS dep
  ON dep.classid = 'pg_class'::regclass
 AND dep.objid = seq.oid
 AND dep.refclassid = 'pg_class'::regclass
 AND dep.deptype IN ('a', 'i')
LEFT JOIN pg_class AS tbl ON tbl.oid = dep.refobjid
LEFT JOIN pg_namespace AS tbl_ns ON tbl_ns.oid = tbl.relnamespace
LEFT JOIN pg_attribute AS att
  ON att.attrelid = dep.refobjid AND att.attnum = dep.refobjsubid
CROSS JOIN LATERAL aclexplode(
  COALESCE(seq.relacl, acldefault('S', seq.relowner))
) AS acl
LEFT JOIN pg_roles AS grantee ON grantee.oid = acl.grantee
LEFT JOIN pg_roles AS grantor ON grantor.oid = acl.grantor
WHERE seq.relkind = 'S'
  AND (seq_ns.nspname IN ('public', 'auth')
       OR tbl.relname IN (
         'profiles', 'establishments', 'activities', 'events',
         'itineraries', 'destinations', 'itinerary_stops', 'reservations',
         'audit_logs', 'notifications'
       ))
ORDER BY seq_ns.nspname, seq.relname, grantee, acl.privilege_type;

-- Expected: sequences in relevant schemas plus sequences owned by target-table
-- columns, ownership dependency, parameters, and ACLs. Empty ACL output must not
-- be interpreted independently of role membership or sequence visibility.

-- QUERY 10 — Effective schema, relation, column, and sequence privileges
WITH target_roles AS (
  SELECT oid, rolname FROM pg_roles
  WHERE rolname IN ('anon', 'authenticated', 'service_role')
), target_relations AS (
  SELECT rel.oid, ns.nspname, rel.relname, rel.relkind
  FROM pg_class AS rel
  JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
  WHERE ns.nspname = 'public'
    AND rel.relname IN (
      'profiles', 'establishments', 'activities', 'events',
      'itineraries', 'destinations', 'itinerary_stops', 'reservations',
      'audit_logs', 'notifications'
    )
)
SELECT
  r.rolname AS checked_role,
  'schema'::text AS object_kind,
  ns.nspname AS object_schema,
  NULL::text AS object_name,
  NULL::text AS column_name,
  priv.privilege_name,
  has_schema_privilege(r.oid, ns.oid, priv.privilege_name) AS has_effective_privilege
FROM target_roles AS r
CROSS JOIN pg_namespace AS ns
CROSS JOIN (VALUES ('USAGE'), ('CREATE')) AS priv(privilege_name)
WHERE ns.nspname IN ('public', 'auth')
UNION ALL
SELECT
  r.rolname, 'relation', rel.nspname, rel.relname, NULL::text, priv.privilege_name,
  has_table_privilege(r.oid, rel.oid, priv.privilege_name)
FROM target_roles AS r
CROSS JOIN target_relations AS rel
CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'),
                   ('TRUNCATE'), ('REFERENCES'), ('TRIGGER')) AS priv(privilege_name)
UNION ALL
SELECT
  r.rolname, 'column', rel.nspname, rel.relname, att.attname, priv.privilege_name,
  has_column_privilege(r.oid, rel.oid, att.attname, priv.privilege_name)
FROM target_roles AS r
CROSS JOIN target_relations AS rel
JOIN pg_attribute AS att ON att.attrelid = rel.oid
CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('REFERENCES')) AS priv(privilege_name)
WHERE att.attnum > 0 AND NOT att.attisdropped
UNION ALL
SELECT
  r.rolname, 'sequence', ns.nspname, seq.relname, NULL::text, priv.privilege_name,
  has_sequence_privilege(r.oid, seq.oid, priv.privilege_name)
FROM target_roles AS r
JOIN pg_class AS seq ON seq.relkind = 'S'
JOIN pg_namespace AS ns ON ns.oid = seq.relnamespace
LEFT JOIN pg_depend AS dep
  ON dep.classid = 'pg_class'::regclass AND dep.objid = seq.oid
 AND dep.refclassid = 'pg_class'::regclass AND dep.deptype IN ('a', 'i')
LEFT JOIN pg_class AS owned_table ON owned_table.oid = dep.refobjid
CROSS JOIN (VALUES ('USAGE'), ('SELECT'), ('UPDATE')) AS priv(privilege_name)
WHERE ns.nspname IN ('public', 'auth')
   OR owned_table.relname IN (
      'profiles', 'establishments', 'activities', 'events',
      'itineraries', 'destinations', 'itinerary_stops', 'reservations',
      'audit_logs', 'notifications'
   )
ORDER BY checked_role, object_kind, object_schema, object_name, column_name, privilege_name;

-- Expected: PostgreSQL effective privilege booleans for the selected roles,
-- including inherited/PUBLIC privilege effects that the checker recognizes.
-- This is not an RLS/API behavior test; compare with Queries 05–09 and 11–13.

-- QUERY 11 — Relevant routines, overloads, full definitions, and settings
WITH target_relations AS (
  SELECT rel.oid
  FROM pg_class AS rel
  JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
  WHERE ns.nspname = 'public'
    AND rel.relname IN (
      'profiles', 'establishments', 'activities', 'events',
      'itineraries', 'destinations', 'itinerary_stops', 'reservations',
      'audit_logs', 'notifications'
    )
), target_policies AS (
  SELECT pol.oid
  FROM pg_policy AS pol
  WHERE pol.polrelid IN (SELECT oid FROM target_relations)
), target_routines AS (
  SELECT p.oid
  FROM pg_proc AS p
  JOIN pg_namespace AS ns ON ns.oid = p.pronamespace
  WHERE ns.nspname = 'public'
    AND p.proname IN ('current_user_role', 'admin_toggle_owner_verification')
  UNION
  SELECT trg.tgfoid
  FROM pg_trigger AS trg
  WHERE trg.tgrelid IN (SELECT oid FROM target_relations)
  UNION
  SELECT dep.refobjid
  FROM pg_depend AS dep
  WHERE dep.classid = 'pg_policy'::regclass
    AND dep.objid IN (SELECT oid FROM target_policies)
    AND dep.refclassid = 'pg_proc'::regclass
)
SELECT
  ns.nspname AS function_schema,
  p.proname AS function_name,
  p.oid::regprocedure::text AS exact_signature,
  pg_get_function_identity_arguments(p.oid) AS identity_arguments,
  pg_get_function_result(p.oid) AS return_type,
  p.prokind AS routine_kind,
  lang.lanname AS language_name,
  owner_role.rolname AS function_owner,
  p.prosecdef AS security_definer,
  p.provolatile AS volatility_code,
  p.proparallel AS parallel_safety_code,
  p.proconfig AS function_settings,
  pg_get_functiondef(p.oid) AS complete_definition
FROM target_routines AS target
JOIN pg_proc AS p ON p.oid = target.oid
JOIN pg_namespace AS ns ON ns.oid = p.pronamespace
JOIN pg_language AS lang ON lang.oid = p.prolang
JOIN pg_roles AS owner_role ON owner_role.oid = p.proowner
ORDER BY p.proname, exact_signature;

-- Expected: every visible overload, exact arguments/result, owner, security,
-- volatility, settings (including configured search_path), and full body.
-- NULL function_settings means no per-function setting is stored. No row may
-- mean absent function, different schema/name, or catalog visibility limitation.

-- QUERY 12 — Function EXECUTE ACLs, defaults, and effective checks
WITH target_functions AS (
  SELECT p.oid, p.proowner
  FROM pg_proc AS p
  JOIN pg_namespace AS ns ON ns.oid = p.pronamespace
  WHERE ns.nspname = 'public'
    AND p.proname IN ('current_user_role', 'admin_toggle_owner_verification')
  UNION
  SELECT fn.oid, fn.proowner
  FROM pg_proc AS fn
  JOIN pg_trigger AS trg ON trg.tgfoid = fn.oid
  JOIN pg_class AS rel ON rel.oid = trg.tgrelid
  JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
  WHERE ns.nspname = 'public'
    AND rel.relname IN (
      'profiles', 'establishments', 'activities', 'events',
      'itineraries', 'destinations', 'itinerary_stops', 'reservations',
      'audit_logs', 'notifications'
    )
  UNION
  SELECT fn.oid, fn.proowner
  FROM pg_proc AS fn
  JOIN pg_depend AS dep ON dep.refobjid = fn.oid
  JOIN pg_policy AS pol ON pol.oid = dep.objid
  JOIN pg_class AS rel ON rel.oid = pol.polrelid
  JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
  WHERE dep.classid = 'pg_policy'::regclass
    AND dep.refclassid = 'pg_proc'::regclass
    AND ns.nspname = 'public'
    AND rel.relname IN (
      'profiles', 'establishments', 'activities', 'events',
      'itineraries', 'destinations', 'itinerary_stops', 'reservations',
      'audit_logs', 'notifications'
    )
), target_roles AS (
  SELECT oid, rolname FROM pg_roles
  WHERE rolname IN ('anon', 'authenticated', 'service_role')
)
SELECT
  fn.oid::regprocedure::text AS exact_signature,
  CASE acl.grantee WHEN 0 THEN 'PUBLIC' ELSE grantee.rolname END AS acl_grantee,
  CASE WHEN (SELECT p.proacl FROM pg_proc AS p WHERE p.oid = fn.oid) IS NULL
    THEN 'POSTGRESQL_DEFAULT_ACL' ELSE 'STORED_ACL' END AS acl_source,
  grantor.rolname AS grantor,
  acl.privilege_type,
  acl.is_grantable,
  r.rolname AS checked_role,
  CASE WHEN r.oid IS NOT NULL
    THEN has_function_privilege(r.oid, fn.oid, 'EXECUTE')
    ELSE NULL
  END AS has_effective_execute
FROM target_functions AS fn
CROSS JOIN LATERAL aclexplode(
  COALESCE((SELECT p.proacl FROM pg_proc AS p WHERE p.oid = fn.oid),
           acldefault('f', fn.proowner))
) AS acl
LEFT JOIN pg_roles AS grantee ON grantee.oid = acl.grantee
LEFT JOIN pg_roles AS grantor ON grantor.oid = acl.grantor
LEFT JOIN target_roles AS r ON true
ORDER BY exact_signature, acl_grantee, checked_role;

-- Expected: ACL entries including PUBLIC (OID 0), grantor/grant option, and
-- effective EXECUTE results for anon/authenticated/service_role. NULL proacl
-- is expanded through PostgreSQL's default function ACL. This does not prove
-- PostgREST exposure or authorization correctness inside the routine.

-- QUERY 13 — Direct and recursive role membership paths with no-path diagnostics
WITH RECURSIVE roots AS (
  SELECT r.oid, r.rolname
  FROM pg_roles AS r
  WHERE r.rolname IN ('anon', 'authenticated', 'service_role')
), walk AS (
  SELECT root.rolname AS starting_role,
         root.oid AS current_role_oid,
         ARRAY[root.oid] AS visited_role_oids,
         0::integer AS depth,
         NULL::oid AS edge_member_oid,
         NULL::oid AS edge_role_oid,
         NULL::oid AS edge_grantor_oid,
         NULL::boolean AS edge_admin_option,
         NULL::boolean AS edge_inherit_option,
         NULL::boolean AS edge_set_option
  FROM roots AS root
  UNION ALL
  SELECT walk.starting_role,
         edge.roleid,
         walk.visited_role_oids || edge.roleid,
         (walk.depth + 1)::integer,
         edge.member,
         edge.roleid,
         edge.grantor,
         edge.admin_option,
         edge.inherit_option,
         edge.set_option
  FROM walk
  JOIN pg_auth_members AS edge ON edge.member = walk.current_role_oid
  WHERE NOT edge.roleid = ANY(walk.visited_role_oids)
), paths AS (
  SELECT
    walk.starting_role::text AS starting_role,
    walk.depth AS membership_depth,
    member_role.rolname::text AS member_role,
    inherited_role.rolname::text AS inherited_role,
    grantor_role.rolname::text AS grantor,
    walk.edge_admin_option AS admin_option,
    walk.edge_inherit_option AS inherit_option,
    walk.edge_set_option AS set_option
  FROM walk
  JOIN pg_roles AS member_role ON member_role.oid = walk.edge_member_oid
  JOIN pg_roles AS inherited_role ON inherited_role.oid = walk.edge_role_oid
  JOIN pg_roles AS grantor_role ON grantor_role.oid = walk.edge_grantor_oid
  WHERE walk.depth > 0
), root_status AS (
  SELECT expected.role_name AS starting_role,
         root.oid IS NOT NULL AS starting_role_visible,
         count(paths.membership_depth) AS visible_path_edge_count
  FROM (VALUES ('anon'::text), ('authenticated'::text), ('service_role'::text))
       AS expected(role_name)
  LEFT JOIN roots AS root ON root.rolname::text = expected.role_name
  LEFT JOIN paths ON paths.starting_role = expected.role_name
  GROUP BY expected.role_name, root.oid
)
SELECT
  'EDGE'::text AS row_kind,
  paths.starting_role,
  true AS starting_role_visible,
  paths.membership_depth,
  paths.member_role,
  paths.inherited_role,
  paths.grantor,
  paths.admin_option,
  paths.inherit_option,
  paths.set_option,
  NULL::text AS interpretation
FROM paths
UNION ALL
SELECT
  'ROOT_STATUS',
  status.starting_role,
  status.starting_role_visible,
  NULL::integer,
  NULL::text,
  NULL::text,
  NULL::text,
  NULL::boolean,
  NULL::boolean,
  NULL::boolean,
  CASE WHEN NOT status.starting_role_visible
       THEN 'Role not visible to this inspection session; result incomplete.'
       WHEN status.visible_path_edge_count = 0
       THEN 'No membership edges visible from this root; not proof of global absence.'
       ELSE 'Visible membership edges reported above; paths are not a full privilege calculation.'
  END
FROM root_status AS status
ORDER BY starting_role, row_kind, membership_depth, member_role, inherited_role;

-- Expected: each traversed edge reports its actual member and granted role,
-- grantor, and admin/inherit/set options; visited OIDs prevent cycles. A
-- ROOT_STATUS row is always emitted per target role, distinguishing a
-- missing/invisible root and zero visible edges from query failure. Catalog
-- visibility may still hide memberships. Membership paths alone do not
-- calculate every effective privilege.

-- QUERY 14 — Direct catalog dependencies for target relations and routines
WITH target_relations AS (
  SELECT rel.oid
  FROM pg_class AS rel
  JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
  WHERE ns.nspname = 'public'
    AND rel.relname IN (
      'profiles', 'establishments', 'activities', 'events',
      'itineraries', 'destinations', 'itinerary_stops', 'reservations',
      'audit_logs', 'notifications'
    )
), target_routines AS (
  SELECT p.oid
  FROM pg_proc AS p
  JOIN pg_namespace AS ns ON ns.oid = p.pronamespace
  WHERE ns.nspname = 'public'
    AND p.proname IN ('current_user_role', 'admin_toggle_owner_verification')
  UNION
  SELECT trg.tgfoid
  FROM pg_trigger AS trg
  JOIN pg_class AS rel ON rel.oid = trg.tgrelid
  JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
  WHERE ns.nspname = 'public'
    AND rel.relname IN (
      'profiles', 'establishments', 'activities', 'events',
      'itineraries', 'destinations', 'itinerary_stops', 'reservations',
      'audit_logs', 'notifications'
    )
), target_policies AS (
  SELECT pol.oid
  FROM pg_policy AS pol
  JOIN pg_class AS rel ON rel.oid = pol.polrelid
  JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
  WHERE ns.nspname = 'public'
    AND rel.relname IN (
      'profiles', 'establishments', 'activities', 'events',
      'itineraries', 'destinations', 'itinerary_stops', 'reservations',
      'audit_logs', 'notifications'
    )
)
SELECT
  pg_describe_object(dep.classid, dep.objid, dep.objsubid) AS dependent_object,
  pg_describe_object(dep.refclassid, dep.refobjid, dep.refobjsubid) AS referenced_object,
  dep.deptype AS dependency_type
FROM pg_depend AS dep
WHERE (dep.classid = 'pg_class'::regclass
       AND dep.objid IN (SELECT oid FROM target_relations))
   OR (dep.refclassid = 'pg_class'::regclass
       AND dep.refobjid IN (SELECT oid FROM target_relations))
   OR (dep.classid = 'pg_proc'::regclass
       AND dep.objid IN (SELECT oid FROM target_routines))
   OR (dep.refclassid = 'pg_proc'::regclass
       AND dep.refobjid IN (SELECT oid FROM target_routines))
   OR (dep.classid = 'pg_policy'::regclass
       AND dep.objid IN (SELECT oid FROM target_policies))
   OR (dep.refclassid = 'pg_policy'::regclass
       AND dep.refobjid IN (SELECT oid FROM target_policies))
ORDER BY dependent_object, referenced_object, dependency_type;

-- Expected: catalog-recorded object dependencies touching target relations
-- and named/trigger routines, including referenced types/functions/sequences
-- when PostgreSQL records the dependency. PL/pgSQL and dynamic-SQL body
-- references may not be fully tracked; this is not a complete runtime call graph.

-- QUERY 15 — User-defined types, enum labels, domains, and composite fields used by target columns
WITH RECURSIVE
    target_types (type_oid) AS (
        SELECT DISTINCT
            att.atttypid
        FROM
            pg_attribute AS att
            JOIN pg_class AS rel ON rel.oid = att.attrelid
            JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
        WHERE
            ns.nspname = 'public'
            AND rel.relname IN (
                'profiles',
                'establishments',
                'activities',
                'events',
                'itineraries',
                'destinations',
                'itinerary_stops',
                'reservations',
                'audit_logs',
                'notifications'
            )
            AND att.attnum > 0
            AND NOT att.attisdropped
        UNION
        SELECT next_type.type_oid
        FROM
            target_types AS used
            JOIN pg_type AS typ ON typ.oid = used.type_oid
            CROSS JOIN LATERAL (
                SELECT typ.typbasetype AS type_oid
                WHERE
                    typ.typbasetype <> 0
                UNION
                SELECT typ.typelem AS type_oid
                WHERE
                    typ.typelem <> 0
            ) AS next_type
    )
SELECT
    type_ns.nspname AS type_schema,
    typ.typname AS type_name,
    typ.typtype AS type_kind,
    format_type (typ.oid, NULL) AS formatted_type,
    owner_role.rolname AS type_owner,
    CASE
        WHEN typ.typbasetype <> 0 THEN format_type (
            typ.typbasetype,
            typ.typtypmod
        )
        ELSE NULL
    END AS domain_base_type,
    typ.typnotnull AS domain_not_null,
    pg_get_expr (typ.typdefaultbin, 0) AS domain_default,
    ARRAY (
        SELECT enum.enumlabel
        FROM pg_enum AS enum
        WHERE
            enum.enumtypid = typ.oid
        ORDER BY enum.enumsortorder
    ) AS enum_labels,
    ARRAY (
        SELECT pg_get_constraintdef (con.oid, true)
        FROM pg_constraint AS con
        WHERE
            con.contypid = typ.oid
        ORDER BY con.conname
    ) AS domain_constraints,
    ARRAY (
        SELECT format(
                '%I %s%s', attr.attname, format_type (attr.atttypid, attr.atttypmod), CASE
                    WHEN attr.attnotnull THEN ' NOT NULL'
                    ELSE ''
                END
            )
        FROM pg_attribute AS attr
        WHERE
            attr.attrelid = typ.typrelid
            AND attr.attnum > 0
            AND NOT attr.attisdropped
        ORDER BY attr.attnum
    ) AS composite_attributes
FROM
    target_types AS used
    JOIN pg_type AS typ ON typ.oid = used.type_oid
    JOIN pg_namespace AS type_ns ON type_ns.oid = typ.typnamespace
    JOIN pg_roles AS owner_role ON owner_role.oid = typ.typowner
WHERE
    type_ns.nspname <> 'pg_catalog'
ORDER BY type_ns.nspname, typ.typname;

-- Expected: non-built-in types directly used by target columns and recursively
-- referenced domain bases/array elements, with enum labels, domain checks,
-- defaults, nullability, and composite attributes. Empty output means no visible
-- non-built-in type dependency was found, subject to catalog visibility.
