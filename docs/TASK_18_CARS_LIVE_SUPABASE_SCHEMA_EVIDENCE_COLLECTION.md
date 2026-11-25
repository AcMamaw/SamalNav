# Task 18 — CARS Live Supabase Schema Evidence Collection

**Project selected for owner-run inspection:** SamalNav-NonProduction
**Project reference:** `iwzyasdanesaaxxjujxr`
**Environment:** Non-production (selected by owner response in this conversation)
**Inspection date:** 2026-11-18 (Asia/Manila)
**SQL execution status:** Not executed. Deployed findings are pending owner-supplied output.
**Project confirmer:** Requester selected the project/reference in chat; their name and role were not provided.

## 1. Executive summary

The owner selected the dedicated non-production project, removing the ambiguity about whether the production project should be inspected. This session still has no Supabase Dashboard or project-verifiable SQL connector. Accordingly, no live database access or SQL execution occurred. This document provides separately runnable, read-only queries for the owner to run in the SQL Editor **after manually confirming the displayed project reference**. Query outputs and deployed-schema findings remain pending.

Queries cover relation/column definitions, keys and constraints, indexes, RLS policies, SQL privileges, and aggregate-only data-quality indicators. They select no application records or tourist information. The data-quality queries depend on relation/column existence; run them only after Query 18-01 confirms those objects and fields. A missing relation or column is evidence to record, not a reason to substitute a production project.

This task authorizes inspection only. It does not authorize schema changes, policy changes, CARS scores, or production activation.

## 2. Project identity and execution record

| Field | Recorded value |
|---|---|
| Project name | SamalNav-NonProduction |
| Project reference | `iwzyasdanesaaxxjujxr` |
| Environment | Non-production, as selected by the requester |
| Selection evidence | Requester response to Task 18 project confirmation question |
| Confirming person | Name/role not supplied; retain as an outstanding audit-trail field |
| Query execution | None by coding agent; awaiting owner-run SQL Editor results |
| Actual execution time | Pending owner execution |
| Production project | Not selected and must not be used for these queries |

Before running any query, the owner must verify the Dashboard project name and reference match the values above. Stop if either differs. Record the SQL Editor project label, reference, UTC/local timestamp, query ID, row count, errors, and any truncation with the returned output. Do not include keys, tokens, personal data, or unrestricted application rows.

## 3. Query run instructions

1. Open the selected project in Supabase Dashboard and independently confirm `iwzyasdanesaaxxjujxr` in project settings/URL.
2. Run each `SELECT` below separately in SQL Editor. Do not run migrations or edit objects.
3. Run 18-01 through 18-05 first. Run 18-06A through 18-06F only when 18-01 confirms the required relation and column names and compatible types.
4. Save sanitized outputs per query. An empty result, missing relation, query error, permission error, and truncated output are distinct outcomes. Preserve the exact non-sensitive error text.
5. Do not execute 18-06 queries for a missing relation. Report that evidence item as unavailable/missing and include the 18-01 result.
6. Return query outputs and the execution record to complete reconciliation. Do not paste tourist identifiers, emails, review text, coordinates tied to a person, or other personal data.

The catalog queries establish definitions/SQL privileges visible to the SQL Editor role. They do **not** prove that an anon/authenticated PostgREST request succeeds under a particular JWT or row-level policy. That requires a separately approved, synthetic-identity non-production authorization test.

## 4. Read-only catalog queries

### Query 18-01 — Relation and column inventory

**Purpose:** Confirm requested relations and exact column metadata; missing relations remain visible as one `relation_found=false` row.
**Expected:** One row per column plus a placeholder row for any absent relation.
**Limitations:** Does not establish row population, grants, RLS outcomes, or source semantics.

```sql
WITH target_relations(schema_name, relation_name) AS (
    VALUES
        ('public', 'destinations'),
        ('public', 'activities'),
        ('public', 'categories'),
        ('public', 'tourist_details'),
        ('public', 'tourist_profiles'),
        ('public', 'reviews'),
        ('public', 'establishment_reviews'),
        ('public', 'destination_availability'),
        ('public', 'weather_cache'),
        ('public', 'establishments'),
        ('public', 'profiles')
)
SELECT
    target.schema_name,
    target.relation_name,
    (rel.oid IS NOT NULL) AS relation_found,
    attr.attnum AS ordinal_position,
    attr.attname AS column_name,
    CASE WHEN attr.attnum IS NOT NULL
         THEN format_type(attr.atttypid, attr.atttypmod) END AS data_type,
    attr.attnotnull AS not_null,
    pg_get_expr(def.adbin, def.adrelid) AS column_default,
    attr.attidentity AS identity_kind,
    attr.attgenerated AS generated_kind,
    coll_ns.nspname AS collation_schema,
    coll.collname AS collation_name
FROM target_relations AS target
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
LEFT JOIN pg_collation AS coll
    ON coll.oid = attr.attcollation
LEFT JOIN pg_namespace AS coll_ns
    ON coll_ns.oid = coll.collnamespace
ORDER BY target.schema_name, target.relation_name, attr.attnum;
```

### Query 18-02 — Primary, unique, check, and foreign-key constraints

**Purpose:** Capture exact constraint definitions and local/referenced relations for the target set.
**Expected:** One row per visible constraint. No rows require comparison with Query 18-01 and visibility limits.
**Limitations:** Catalog visibility applies; definitions do not prove data quality when constraints are absent or unvalidated.

```sql
WITH targets(schema_name, relation_name) AS (
    VALUES
        ('public', 'destinations'), ('public', 'activities'),
        ('public', 'categories'), ('public', 'tourist_details'),
        ('public', 'tourist_profiles'), ('public', 'reviews'),
        ('public', 'establishment_reviews'),
        ('public', 'destination_availability'),
        ('public', 'weather_cache'), ('public', 'establishments'),
        ('public', 'profiles')
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
    SELECT 1 FROM targets AS t
    WHERE t.schema_name = ns.nspname AND t.relation_name = rel.relname
)
AND con.contype IN ('p', 'u', 'f', 'c', 'x')
ORDER BY ns.nspname, rel.relname, con.contype, con.conname;
```

### Query 18-03 — Index definitions

**Purpose:** Report indexes for the requested relations, including uniqueness, validity, readiness, predicates, and full definitions.
**Expected:** One row per index on each present relation.
**Limitations:** Does not recommend or authorize index changes; constraint ownership is separately visible in Query 18-02.

```sql
SELECT
    ns.nspname AS schema_name,
    rel.relname AS relation_name,
    idx.relname AS index_name,
    i.indisprimary AS is_primary,
    i.indisunique AS is_unique,
    i.indisvalid AS is_valid,
    i.indisready AS is_ready,
    i.indislive AS is_live,
    pg_get_expr(i.indpred, i.indrelid) AS predicate,
    pg_get_expr(i.indexprs, i.indrelid) AS expressions,
    pg_get_indexdef(i.indexrelid) AS index_definition
FROM pg_index AS i
JOIN pg_class AS rel ON rel.oid = i.indrelid
JOIN pg_namespace AS ns ON ns.oid = rel.relnamespace
JOIN pg_class AS idx ON idx.oid = i.indexrelid
WHERE ns.nspname = 'public'
  AND rel.relname IN (
      'destinations', 'activities', 'categories', 'tourist_details',
      'tourist_profiles', 'reviews', 'establishment_reviews',
      'destination_availability', 'weather_cache', 'establishments', 'profiles'
  )
ORDER BY rel.relname, idx.relname;
```

### Query 18-04 — RLS flags and exact policy definitions

**Purpose:** Preserve RLS-enabled/forced flags for every requested relation, including relations with no visible policies, and list policy command, roles, mode, `USING`, and `WITH CHECK`.
**Expected:** One placeholder row for each relation without a matching policy and one row per policy otherwise.
**Limitations:** SQL Editor visibility may be privileged; policy metadata does not prove a JWT request's outcome or intended-user access.

```sql
WITH targets(schema_name, relation_name) AS (
    VALUES
        ('public', 'destinations'), ('public', 'activities'),
        ('public', 'categories'), ('public', 'tourist_details'),
        ('public', 'tourist_profiles'), ('public', 'reviews'),
        ('public', 'establishment_reviews'),
        ('public', 'destination_availability'),
        ('public', 'weather_cache'), ('public', 'establishments'),
        ('public', 'profiles')
)
SELECT
    t.schema_name,
    t.relation_name,
    (rel.oid IS NOT NULL) AS relation_found,
    COALESCE(rel.relrowsecurity, false) AS rls_enabled,
    COALESCE(rel.relforcerowsecurity, false) AS rls_forced,
    pol.policyname,
    pol.permissive,
    pol.cmd AS command,
    pol.roles AS target_roles,
    pol.qual AS using_expression,
    pol.with_check AS with_check_expression
FROM targets AS t
LEFT JOIN pg_namespace AS ns ON ns.nspname = t.schema_name
LEFT JOIN pg_class AS rel
    ON rel.relnamespace = ns.oid
   AND rel.relname = t.relation_name
   AND rel.relkind IN ('r', 'p')
LEFT JOIN pg_policies AS pol
    ON pol.schemaname = t.schema_name
   AND pol.tablename = t.relation_name
ORDER BY t.schema_name, t.relation_name, pol.policyname;
```

### Query 18-05 — Stored relation ACL and effective SQL privileges

**Purpose:** Show stored/default-expanded relation ACL entries and effective relation-level privileges for API roles when those roles exist.
**Expected:** ACL rows plus per-role relation privilege rows.
**Limitations:** Privilege checks do not evaluate RLS, JWT claims, PostgREST exposure, data predicates, or actual tourist access.

```sql
WITH targets(schema_name, relation_name) AS (
    VALUES
        ('public', 'destinations'), ('public', 'activities'),
        ('public', 'categories'), ('public', 'tourist_details'),
        ('public', 'tourist_profiles'), ('public', 'reviews'),
        ('public', 'establishment_reviews'),
        ('public', 'destination_availability'),
        ('public', 'weather_cache'), ('public', 'establishments'),
        ('public', 'profiles')
), target_relations AS (
    SELECT ns.oid AS namespace_oid, ns.nspname, rel.oid AS relation_oid,
           rel.relname, rel.relowner, rel.relacl
    FROM targets AS t
    JOIN pg_namespace AS ns ON ns.nspname = t.schema_name
    JOIN pg_class AS rel
      ON rel.relnamespace = ns.oid AND rel.relname = t.relation_name
     AND rel.relkind IN ('r', 'p', 'v', 'm', 'f')
)
SELECT
    'ACL'::text AS evidence_kind,
    r.nspname AS schema_name,
    r.relname AS relation_name,
    CASE acl.grantee WHEN 0 THEN 'PUBLIC' ELSE grantee.rolname END AS grantee,
    grantor.rolname AS grantor,
    acl.privilege_type,
    acl.is_grantable AS grant_option,
    NULL::text AS checked_role,
    NULL::boolean AS has_select,
    NULL::boolean AS has_insert,
    NULL::boolean AS has_update,
    NULL::boolean AS has_delete
FROM target_relations AS r
CROSS JOIN LATERAL aclexplode(
    COALESCE(r.relacl, acldefault('r', r.relowner))
) AS acl
LEFT JOIN pg_roles AS grantee ON grantee.oid = acl.grantee
LEFT JOIN pg_roles AS grantor ON grantor.oid = acl.grantor
UNION ALL
SELECT
    'EFFECTIVE_RELATION_PRIVILEGE'::text,
    r.nspname,
    r.relname,
    NULL::text,
    NULL::text,
    NULL::text,
    NULL::boolean,
    role_row.rolname,
    has_table_privilege(role_row.oid, r.relation_oid, 'SELECT'),
    has_table_privilege(role_row.oid, r.relation_oid, 'INSERT'),
    has_table_privilege(role_row.oid, r.relation_oid, 'UPDATE'),
    has_table_privilege(role_row.oid, r.relation_oid, 'DELETE')
FROM target_relations AS r
CROSS JOIN pg_roles AS role_row
WHERE role_row.rolname IN ('anon', 'authenticated', 'service_role')
ORDER BY schema_name, relation_name, evidence_kind, grantee, checked_role;
```

### Query 18-06A — Destination coordinate, rating, and price aggregates

**Run only if** Query 18-01 confirms `public.destinations` and the referenced fields.
**Purpose:** Return counts only: missing coordinates, null/zero ratings and entrance fees.
**Expected:** One aggregate row, no destination values.
**Limitations:** Zero counts do not distinguish database defaults from actual zero. `rating` and `rating_average` may both exist; this query reports them separately.

```sql
SELECT
    count(*) AS destination_rows,
    count(*) FILTER (WHERE lat IS NULL OR lng IS NULL) AS missing_coordinate_pairs,
    count(*) FILTER (WHERE rating IS NULL) AS null_rating_rows,
    count(*) FILTER (WHERE rating = 0) AS zero_rating_rows,
    count(*) FILTER (WHERE rating_average IS NULL) AS null_rating_average_rows,
    count(*) FILTER (WHERE rating_average = 0) AS zero_rating_average_rows,
    count(*) FILTER (WHERE entrance_fee IS NULL) AS null_entrance_fee_rows,
    count(*) FILTER (WHERE entrance_fee = 0) AS zero_entrance_fee_rows
FROM public.destinations;
```

### Query 18-06B — Activity relationship/category/price aggregates

**Run only if** Query 18-01 confirms `activities.id`, `destination_id`, `category`, and `price`, and `destinations.id`.
**Purpose:** Count unlinked/orphan destination references, missing category labels, and null/zero price fields.
**Expected:** One aggregate row.
**Limitations:** Does not determine whether zero is a real free price; no personal fields are returned.

```sql
SELECT
    count(*) AS activity_rows,
    count(*) FILTER (
        WHERE a.destination_id IS NULL
           OR NOT EXISTS (
               SELECT 1 FROM public.destinations AS d
               WHERE d.id::text = a.destination_id::text
           )
    ) AS missing_or_orphan_destination_refs,
    count(*) FILTER (WHERE category IS NULL OR btrim(category) = '')
        AS missing_activity_categories,
    count(*) FILTER (WHERE price IS NULL) AS null_price_rows,
    count(*) FILTER (WHERE price = 0) AS zero_price_rows
FROM public.activities AS a;
```

### Query 18-06C — Category identifier/name duplicate aggregates

**Run only if** Query 18-01 confirms `categories.id` and `categories.name`.
**Purpose:** Count duplicate IDs and duplicate normalized names without returning category records.
**Expected:** One aggregate row.
**Limitations:** If `id` is a primary/unique key, duplicate IDs should be structurally prevented; this query does not propose a change.

```sql
SELECT
    count(*) AS category_rows,
    count(*) - count(DISTINCT id) AS duplicate_id_excess_rows,
    (SELECT COALESCE(sum(name_count - 1), 0)
     FROM (
         SELECT count(*) AS name_count
         FROM public.categories
         GROUP BY lower(btrim(name))
         HAVING count(*) > 1
     ) AS duplicate_names) AS duplicate_normalized_name_excess_rows
FROM public.categories;
```

### Query 18-06D — Availability coverage aggregate

**Run only if** Query 18-01 confirms `destination_availability.destination_id`, `destination_availability.date`, `destination_availability.is_available`, and `destinations.id`.
**Purpose:** Count destinations with no availability row, plus availability total and null/date status counts where the fields exist.
**Expected:** One aggregate row.
**Limitations:** “No row” is not necessarily “closed”; the product policy and inspected date window are not supplied. This counts any row and does not infer future coverage.

```sql
SELECT
    (SELECT count(*) FROM public.destinations) AS destination_rows,
    (SELECT count(*) FROM public.destinations AS d
     WHERE NOT EXISTS (
         SELECT 1 FROM public.destination_availability AS a
         WHERE a.destination_id::text = d.id::text
     )) AS destinations_with_no_availability_row,
    count(*) AS availability_rows,
    count(*) FILTER (WHERE date IS NULL) AS null_date_rows,
    count(*) FILTER (WHERE is_available IS NULL) AS null_availability_flag_rows
FROM public.destination_availability;
```

### Query 18-06E — Weather-cache timestamp and link aggregates

**Run only if** Query 18-01 confirms `weather_cache.destination_id`, `destinations.id`, and `updated_at` is a timestamp type.
**Purpose:** Report row counts, missing/orphan destination links, null timestamp count, and oldest/newest update time.
**Expected:** One aggregate row.
**Limitations:** No freshness threshold is assumed. Compare the oldest/latest age with a separately approved freshness policy; no condition or multiplier is interpreted as a CARS score.

```sql
SELECT
    count(*) AS weather_cache_rows,
    count(*) FILTER (WHERE w.destination_id IS NULL OR NOT EXISTS (
        SELECT 1 FROM public.destinations AS d
        WHERE d.id::text = w.destination_id::text
    )) AS missing_or_orphan_destination_refs,
    count(*) FILTER (WHERE updated_at IS NULL) AS missing_update_time_rows,
    min(updated_at) AS oldest_update_time,
    max(updated_at) AS newest_update_time
FROM public.weather_cache AS w;
```

### Query 18-06F — Tourist profile aggregate shape only

**Run each branch only if** Query 18-01 confirms that profile relation and fields. This query returns counts and never returns `user_id`, preferences, budgets, coordinates, or individual records.
**Purpose:** Compare presence/empty preference-array counts across the two profile relations without exposing their contents.
**Expected:** One row per present relation.
**Limitations:** Aggregate counts do not prove tourist selection/confirmation or row ownership/access. Do not run a branch whose relation or field is absent.

```sql
SELECT
    'tourist_details'::text AS relation_name,
    count(*) AS profile_rows,
    count(*) FILTER (WHERE preferred_categories IS NULL) AS null_preference_rows,
    count(*) FILTER (
        WHERE preferred_categories IS NOT NULL
          AND cardinality(preferred_categories) = 0
    ) AS empty_preference_rows
FROM public.tourist_details
UNION ALL
SELECT
    'tourist_profiles'::text,
    count(*),
    count(*) FILTER (WHERE preferred_categories IS NULL),
    count(*) FILTER (
        WHERE preferred_categories IS NOT NULL
          AND cardinality(preferred_categories) = 0
    )
FROM public.tourist_profiles;
```

## 5. Query coverage and interpretation

| Query | Evidence requested | Key CARS questions addressed |
|---|---|---|
| 18-01 | Relation presence, exact columns, types, nullability, defaults, identity/generated attributes | All six; resolves deployed-vs-local columns before data checks |
| 18-02 | PK, unique, check, FK definitions, target relation and validation state | Activity/category/profile/review/availability/weather/destination relationships |
| 18-03 | Complete index definitions and validity flags | Relationship support and duplicate/unique enforcement context |
| 18-04 | RLS flags and policy command/role/expressions | Read policy inventory; does not prove effective API access |
| 18-05 | Stored ACL entries and effective relation-level SQL privileges | SELECT privilege context only; not RLS access |
| 18-06A | Aggregate missing coordinates and null/zero rating/entrance fee counts | Distance and rating/budget data shape |
| 18-06B | Aggregate missing/orphan activity links/categories and null/zero prices | Interest, time, and budget data shape |
| 18-06C | Duplicate category IDs/names | Taxonomy integrity |
| 18-06D | Availability coverage counts | Date availability shape |
| 18-06E | Weather row links and timestamp bounds | Weather cache quality; freshness policy remains separate |
| 18-06F | Preference row and empty-array counts across profile alternatives | Preference storage; not confirmation or personal values |

These queries do not calculate CARS values. SQL permission functions cannot establish row-policy results for actual tourist JWTs. No query here returns review text, tourist identifiers, or raw row content.

## 6. Reconciliation status

No live query outputs were supplied with the Task 18 request. Therefore:

- Deployed table/column, relationship, index, RLS, ACL, and aggregate findings: **PENDING**.
- Local-vs-deployed discrepancy conclusions: **PENDING**; Task 17's local-artifact findings remain qualified as local only.
- Six-criterion evidence status: no deployed source is upgraded to “verified and usable” by this document. Raw CARS inputs remain subject to prior safe-unavailable behavior.
- Project environment label: confirmed by requester as non-production; confirmer's name/role remains absent from the evidence record.

After owner output arrives, update each result as `owner-supplied`, preserve raw sanitized output separately, and mark independent code review as such. A query result from the SQL Editor is not independently verified by the coding agent and does not prove PostgREST/JWT behavior.

## 7. Owner evidence intake checklist

Please return:

1. Project name, exact reference, environment, and SQL Editor timestamp. The selected reference above must match exactly. Add the confirming person's name/role or document why it cannot be recorded.
2. Separate, untruncated outputs for Queries 18-01 through 18-05, with result row counts and any SQL errors/visibility restrictions.
3. Outputs for each applicable 18-06 aggregate query only after confirming field compatibility. If a relation or field is absent, return the Query 18-01 evidence rather than altering the schema.
4. Sanitization confirmation: no keys/tokens, emails, names, user IDs, review text, tourist preference values, or application row payloads included.
5. Any query errors exactly as shown, without secrets. Do not report an error as an empty result.

The owner should not grant extra privileges or switch to `service_role` to obtain results. If the SQL Editor role cannot see catalog data, record that limit and stop for authorized database-administrator review.

## 8. Repository comparison scope after evidence arrives

Reconcile output against `supabase/backup/schema.sql`, migrations (especially 002 and 004), `lib/models/destination_record.dart`, `lib/models/tourist_planning_profile.dart`, `lib/services/destination_service.dart`, `lib/services/tourist_planning_profile_service.dart`, `lib/services/establishment_service.dart`, `lib/services/open_weather_map_service.dart`, CARS assessment boundaries, and Task 17. Do not treat the empty `supabase/remote_schema_baseline.sql` or local migration text as proof of deployed state.

Expected source questions to close:

- Does activity data have an authoritative stable category identifier and destination FK in the selected project?
- Which tourist preference relation is actually used, and is there a separate explicit confirmation contract?
- Do public rating aggregates or destination-linked reviews exist, and what fields/source semantics distinguish actual values from defaults?
- Do availability/weather tables contain records and source/time/coverage data sufficient for their declared purpose?
- Do price fields carry currency, units, verification and provenance, or are they raw defaults only?
- Are destination coordinates and visit-duration values populated and valid? Aggregate queries here only cover null coordinates; owner can prepare further aggregate checks if requested.
- Do RLS policies and SQL grants allow the intended app path? Catalog evidence alone cannot establish this; test only in a separately authorized synthetic non-production authorization run.

## 9. Validation and safety record

- Branch and working-tree status inspected; existing Task 06–17 files and prior modifications preserved.
- SQL text in this document consists solely of catalog/aggregate `SELECT` statements (including `WITH`/CTE forms where applicable); no DDL, DML, role switching, grants, revokes, or function execution is included.
- Queries were prepared, not parsed or executed against PostgreSQL. Query syntax must be validated by owner execution and errors retained; no deployed results are claimed.
- No Supabase project was accessed. No tests are applicable to this documentation-only query-intake deliverable.
- `git diff --check` result is recorded in the completion message.

## 10. Recommended Task 19

Once sanitized owner results are provided, create a focused evidence reconciliation that maps each result to Task 17's table/criterion matrix, identifies only confirmed deployed-vs-local differences, and updates the six evidence statuses. Do not create adapters or schema changes in that reconciliation. Any data-source implementation, authorization test, migration, or production activation requires its own decision and approval.

## 11. Closeout

- **Created:** `docs/TASK_18_CARS_LIVE_SUPABASE_SCHEMA_EVIDENCE_COLLECTION.md`
- **Deployed queries/results:** None; owner execution is pending.
- **Database objects/data:** unchanged.
- **CARS scores/activation:** none produced or authorized.
