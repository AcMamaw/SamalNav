-- Task 09B-H-K — Supplemental production catalog evidence
-- Version: 002 | READ-ONLY | Run one SUP identifier at a time in SQL Editor.
-- This file is query preparation only. No statement changes database objects.
-- Target set: H-G relations plus public.roles, a confirmed supporting
-- dependency because profiles.role references roles(name). Supabase-managed
-- auth relations are not copied; Auth remains the identity source.

-- SUP-01 — Complete column metadata for profiles/reservations and ordinal
-- verification for destinations/establishments; includes roles dependency.
-- Expected: one row per visible, non-dropped column in the five named tables,
-- ordered by relation and ordinal. Includes formatted type/typmod, collation,
-- nullability, default, identity and generated attributes/expressions.
-- Limits: metadata only; a missing row can mean relation/column absence or
-- catalog visibility. It does not return application values.
SELECT
    ns.nspname AS schema_name,
    rel.relname AS table_name,
    rel.relkind AS relation_kind,
    att.attnum AS ordinal_position,
    att.attname AS column_name,
    format_type (att.atttypid, att.atttypmod) AS formatted_type,
    type_ns.nspname AS declared_type_schema,
    typ.typname AS declared_type_name,
    typ.typtype AS declared_type_kind,
    coll_ns.nspname AS collation_schema,
    coll.collname AS collation_name,
    att.attnotnull AS is_not_null,
    pg_get_expr (def.adbin, def.adrelid) AS default_expression,
    att.attidentity AS identity_kind,
    att.attgenerated AS generated_kind,
    CASE
        WHEN att.attgenerated <> '' THEN pg_get_expr (def.adbin, def.adrelid)
        ELSE NULL
    END AS generated_expression
FROM
    pg_class AS rel
    JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
    JOIN pg_attribute AS att ON att.attrelid = rel.oid
    JOIN pg_type AS typ ON typ.oid = att.atttypid
    JOIN pg_namespace AS type_ns ON type_ns.oid = typ.typnamespace
    LEFT JOIN pg_collation AS coll ON coll.oid = att.attcollation
    AND att.attcollation <> 0
    LEFT JOIN pg_namespace AS coll_ns ON coll_ns.oid = coll.collnamespace
    LEFT JOIN pg_attrdef AS def ON def.adrelid = rel.oid
    AND def.adnum = att.attnum
WHERE
    ns.nspname = 'public'
    AND rel.relkind IN ('r', 'p', 'v', 'm', 'f')
    AND att.attnum > 0
    AND NOT att.attisdropped
    AND rel.relname IN (
        'profiles',
        'reservations',
        'destinations',
        'establishments',
        'roles'
    )
ORDER BY rel.relname, att.attnum;

-- SUP-02 — Index definitions and associated constraints for all H-G targets
-- plus roles.
-- Expected: visible index definition, uniqueness/validity/readiness, key and
-- total attribute counts, predicate/expression, and any constraints recorded
-- against the index (including constraint definition text).
-- Limits: no index recommendation follows. Catalog visibility applies; this
-- does not supply query plans or prove runtime performance.
SELECT
    ns.nspname AS schema_name,
    tbl.relname AS table_name,
    idx.relname AS index_name,
    ind.indisprimary AS is_primary,
    ind.indisunique AS is_unique,
    ind.indisexclusion AS is_exclusion,
    ind.indisvalid AS is_valid,
    ind.indisready AS is_ready,
    ind.indislive AS is_live,
    ind.indnullsnotdistinct AS nulls_not_distinct,
    ind.indnkeyatts AS key_attribute_count,
    ind.indnatts AS total_attribute_count,
    pg_get_indexdef(ind.indexrelid) AS index_definition,
    pg_get_expr(ind.indpred, ind.indrelid) AS predicate_expression,
    pg_get_expr(ind.indexprs, ind.indrelid) AS expression_definition,
    ARRAY (
        SELECT format(
            '%I (%s): %s',
            con.conname,
            CASE con.contype
                WHEN 'p' THEN 'PRIMARY KEY'
                WHEN 'u' THEN 'UNIQUE'
                WHEN 'x' THEN 'EXCLUSION'
                ELSE con.contype::text
            END,
            pg_get_constraintdef(con.oid, true)
        )
        FROM pg_constraint AS con
        WHERE con.conindid = ind.indexrelid
        ORDER BY con.conname
    ) AS associated_constraints
FROM pg_index AS ind
JOIN pg_class AS tbl ON tbl.oid = ind.indrelid
JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
JOIN pg_class AS idx ON idx.oid = ind.indexrelid
WHERE ns.nspname = 'public'
  AND tbl.relname IN (
      'profiles', 'establishments', 'activities', 'events', 'itineraries',
      'destinations', 'itinerary_stops', 'reservations', 'audit_logs',
      'notifications', 'roles'
  )
ORDER BY tbl.relname, idx.relname;

-- SUP-03 — Complete trigger inventory and trigger-function definitions for
-- all H-G targets plus roles.
-- Expected: one row per visible trigger with internal status, enabled state,
-- timing/event/definition text and referenced function signature/definition.
-- Limits: RI_ConstraintTrigger rows are PostgreSQL internal referential-
-- integrity triggers; do not treat them as application triggers. Trigger
-- function bodies may reference dynamic behavior not represented in catalogs.
SELECT
    ns.nspname AS schema_name,
    tbl.relname AS table_name,
    trg.tgname AS trigger_name,
    trg.tgenabled AS enabled_code,
    CASE trg.tgenabled
        WHEN 'O' THEN 'ORIGIN_AND_LOCAL'
        WHEN 'D' THEN 'DISABLED'
        WHEN 'R' THEN 'REPLICA'
        WHEN 'A' THEN 'ALWAYS'
    END AS enabled_state,
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
      'profiles', 'establishments', 'activities', 'events', 'itineraries',
      'destinations', 'itinerary_stops', 'reservations', 'audit_logs',
      'notifications', 'roles'
  )
ORDER BY tbl.relname, trg.tgname;

-- SUP-04 — Exact RLS flags and policy definitions for all H-G targets plus
-- roles.
-- Expected: one row per policy; a table with no policy still appears with
-- NULL policy columns and its RLS enabled/forced flags.
-- Limits: policy definitions alone do not establish effective access. Include
-- grants, role context, function behavior, and API tests in any assessment.
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
    CASE pol.polcmd
        WHEN '*' THEN 'ALL'
        WHEN 'r' THEN 'SELECT'
        WHEN 'a' THEN 'INSERT'
        WHEN 'w' THEN 'UPDATE'
        WHEN 'd' THEN 'DELETE'
    END AS command_name,
    ARRAY (
        SELECT CASE
            WHEN role_oid = 0 THEN 'PUBLIC'
            ELSE role_row.rolname::text
        END
        FROM unnest(pol.polroles) AS target(role_oid)
        LEFT JOIN pg_roles AS role_row ON role_row.oid = target.role_oid
    ) AS target_roles,
    pg_get_expr(pol.polqual, pol.polrelid) AS using_expression,
    pg_get_expr(pol.polwithcheck, pol.polrelid) AS with_check_expression
FROM pg_class AS tbl
JOIN pg_namespace AS ns ON ns.oid = tbl.relnamespace
LEFT JOIN pg_policy AS pol ON pol.polrelid = tbl.oid
WHERE ns.nspname = 'public'
  AND tbl.relkind IN ('r', 'p')
  AND tbl.relname IN (
      'profiles', 'establishments', 'activities', 'events', 'itineraries',
      'destinations', 'itinerary_stops', 'reservations', 'audit_logs',
      'notifications', 'roles'
  )
ORDER BY tbl.relname, pol.polname;

-- SUP-05 — Stored relation ACL entries for all H-G targets plus roles.
-- Expected: relation, ACL source, grantee (including PUBLIC), grantor,
-- privilege, and grant option. A NULL ACL is expanded to PostgreSQL's default
-- relation ACL to make the default source visible.
-- Limits: this is stored/default ACL evidence, not effective role inheritance,
-- RLS evaluation, or proof of a PostgREST operation.
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
        'notifications',
        'roles'
    )
ORDER BY rel.relname, grantee, acl.privilege_type, grantor;

-- SUP-06R — Effective schema and relation privileges for anon,
-- authenticated, and service_role.
-- Expected: separate schema/relation rows with one effective privilege boolean
-- per role/object/privilege. MAINTAIN is included for PostgreSQL 17.
-- Limits: SQL privilege results do not evaluate RLS, JWT state, API exposure,
-- or whether the application needs a privilege.
WITH target_roles AS (
    SELECT oid, rolname
    FROM pg_roles
    WHERE rolname IN ('anon', 'authenticated', 'service_role')
), target_relations AS (
    SELECT rel.oid, ns.nspname, rel.relname, rel.relkind
    FROM pg_class AS rel
    JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
    WHERE ns.nspname = 'public'
      AND rel.relname IN (
          'profiles', 'establishments', 'activities', 'events', 'itineraries',
          'destinations', 'itinerary_stops', 'reservations', 'audit_logs',
          'notifications', 'roles'
      )
)
SELECT
    role_row.rolname AS checked_role,
    'schema'::text AS object_kind,
    ns.nspname AS object_schema,
    NULL::text AS object_name,
    priv.privilege_name,
    has_schema_privilege(role_row.oid, ns.oid, priv.privilege_name)
        AS has_effective_privilege
FROM target_roles AS role_row
CROSS JOIN pg_namespace AS ns
CROSS JOIN (VALUES ('USAGE'), ('CREATE')) AS priv(privilege_name)
WHERE ns.nspname = 'public'
UNION ALL
SELECT
    role_row.rolname,
    'relation'::text,
    rel.nspname,
    rel.relname,
    priv.privilege_name,
    has_table_privilege(role_row.oid, rel.oid, priv.privilege_name)
FROM target_roles AS role_row
CROSS JOIN target_relations AS rel
CROSS JOIN (VALUES
    ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE'), ('TRUNCATE'),
    ('REFERENCES'), ('TRIGGER'), ('MAINTAIN')
) AS priv(privilege_name)
ORDER BY checked_role, object_kind, object_schema, object_name, privilege_name;

-- SUP-06C1 — Effective column privileges for profiles, establishments,
-- activities, events, itineraries, itinerary_stops, and supporting roles.
-- Expected: one row per role, relation, column, and SELECT/INSERT/UPDATE/
-- REFERENCES privilege, with its effective privilege boolean.
-- Limits: SQL column privileges do not prove RLS row access or API exposure.
WITH
    target_roles AS (
        SELECT oid, rolname
        FROM pg_roles
        WHERE
            rolname IN (
                'anon',
                'authenticated',
                'service_role'
            )
    ),
    target_relations AS (
        SELECT rel.oid, ns.nspname, rel.relname
        FROM
            pg_class AS rel
            JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
        WHERE
            ns.nspname = 'public'
            AND rel.relname IN (
                'profiles',
                'establishments',
                'activities',
                'events',
                'itineraries',
                'itinerary_stops',
                'roles'
            )
    )
SELECT
    role_row.rolname AS checked_role,
    rel.nspname AS object_schema,
    rel.relname AS relation_name,
    att.attname AS column_name,
    priv.privilege_name,
    has_column_privilege (
        role_row.oid,
        rel.oid,
        att.attname,
        priv.privilege_name
    ) AS has_effective_privilege
FROM
    target_roles AS role_row
    CROSS JOIN target_relations AS rel
    JOIN pg_attribute AS att ON att.attrelid = rel.oid
    CROSS JOIN (
        VALUES ('SELECT'),
            ('INSERT'),
            ('UPDATE'),
            ('REFERENCES')
    ) AS priv (privilege_name)
WHERE
    att.attnum > 0
    AND NOT att.attisdropped
ORDER BY role_row.rolname, rel.relname, att.attnum, priv.privilege_name;

-- SUP-06C2 — Effective column privileges for destinations, reservations,
-- audit_logs, and notifications.
-- Expected and limitations: the same columns and interpretation as SUP-06C1;
-- this second group keeps the result size manageable.
WITH
    target_roles AS (
        SELECT oid, rolname
        FROM pg_roles
        WHERE
            rolname IN (
                'anon',
                'authenticated',
                'service_role'
            )
    ),
    target_relations AS (
        SELECT rel.oid, ns.nspname, rel.relname
        FROM
            pg_class AS rel
            JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
        WHERE
            ns.nspname = 'public'
            AND rel.relname IN (
                'destinations',
                'reservations',
                'audit_logs',
                'notifications'
            )
    )
SELECT
    role_row.rolname AS checked_role,
    rel.nspname AS object_schema,
    rel.relname AS relation_name,
    att.attname AS column_name,
    priv.privilege_name,
    has_column_privilege (
        role_row.oid,
        rel.oid,
        att.attname,
        priv.privilege_name
    ) AS has_effective_privilege
FROM
    target_roles AS role_row
    CROSS JOIN target_relations AS rel
    JOIN pg_attribute AS att ON att.attrelid = rel.oid
    CROSS JOIN (
        VALUES ('SELECT'),
            ('INSERT'),
            ('UPDATE'),
            ('REFERENCES')
    ) AS priv (privilege_name)
WHERE
    att.attnum > 0
    AND NOT att.attisdropped
ORDER BY role_row.rolname, rel.relname, att.attnum, priv.privilege_name;