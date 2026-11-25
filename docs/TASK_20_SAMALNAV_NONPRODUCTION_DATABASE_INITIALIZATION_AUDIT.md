# Task 20 — SamalNav Non-Production Database Initialization Audit

**Target:** `SamalNav-NonProduction` (`iwzyasdanesaaxxjujxr`)
**Region:** `ap-southeast-2`
**Assessment date:** 2026-11-19 (Asia/Manila)
**Scope:** Read-only inspection of repository SQL/configuration/documentation and reconciliation with the database findings supplied in this request.
**Database activity:** None. No SQL was executed and no Supabase project was accessed.

## 1. Executive assessment

The requester reports that the intended non-production project has no expected application tables in `public`, no application tables in other inspected schemas, and no `supabase_migrations.schema_migrations` relation. These are treated as **owner-supplied findings**, not independently verified live observations. They indicate that the application schema may need initialization, but do not establish that the database is otherwise empty, that Auth/Storage/platform schemas are absent, or that no other migration ledger/location exists.

The repository does **not** provide a safe, unambiguous canonical first-install procedure:

- `supabase/config.toml` is absent.
- There are two files with the `002_` version prefix, so the numeric sequence has a collision.
- Several scripts assume pre-existing relations and cannot independently bootstrap a clean project.
- `004_full_schema_from_spec.sql` calls itself a full schema and says it can run standalone, but it depends on pre-existing `profiles` and `establishments`, omits some objects represented in the backup, and uses `IF NOT EXISTS` that does not reconcile a pre-existing table's column shape.
- The historical schema backup is a broad schema snapshot, but it is not documented as the versioned canonical baseline for this project; it depends on Supabase-managed `auth` objects and contains policies/functions that require a separate security review. `supabase/backup/data.sql` is a data dump, not a safe seed plan.
- Seed scripts in the migration directory create sample business, booking/reservation, payment, review, audit, event, destination, and verification records. Some select specific sample email addresses and one script writes an auth-user signup trigger that trusts a user metadata role value.

**Conclusion:** Do not apply `supabase/backup/schema.sql` or run migrations `001`–`006` unchanged. First select and approve a canonical baseline, resolve dependencies and security blockers, and produce a uniquely versioned, reviewed migration sequence with isolated synthetic seed data. This audit does not authorize execution or database changes.

## 2. Evidence and confidence

| Claim | Source | Status | Limit |
|---|---|---|---|
| Target project name/ref/region | Requester supplied this task | Owner-supplied | No dashboard/project connection was used to verify it. |
| Expected app tables absent from `public` and inspected schemas | Requester-supplied confirmed findings | Owner-supplied | Inspection scope/query outputs and timestamp were not attached to this task; do not extend absence claims to uninspected schemas or platform objects. |
| `to_regclass('supabase_migrations.schema_migrations')` returned NULL | Requester-supplied | Owner-supplied | Indicates that this qualified relation was not resolved in that inspection; it does not prove the whole database is empty or that no other migration history exists. |
| Repository migration/config/backup contents below | Files inspected in workspace | Repository-confirmed | Describes checked-in files only, not their deployment history or live compatibility. |
| Compatibility and security concerns | Static comparison of local SQL and supplied findings | Static assessment | No PostgreSQL parser/engine or project was used; no execution success is claimed. |

## 3. Supabase repository inventory

### Configuration and supporting files

- `supabase/config.toml`: **absent**. The repository therefore does not state a complete local Supabase CLI project configuration in this expected path.
- `supabase/remote_schema_baseline.sql`: present but **0 bytes**; it is not a baseline.
- `supabase/backup/schema.sql`: 64,057 bytes; broad historical schema dump with functions, tables, constraints, a few indexes, triggers, RLS flags and policies.
- `supabase/backup/data.sql`: 83,721 bytes; data dump. Row contents were not inspected or reproduced in this audit. It must not be assumed to contain only synthetic or safe-to-import data.
- `supabase/non_production/README.md` and `001_current_behavior_reproduction.sql`: the README says the SQL scaffold is comment-only/non-executable and blocked pending exact evidence; the SQL file records that scope and explicitly creates no objects.
- `supabase/non_production/evidence/`: read-only production evidence query packs and README. These are for evidence collection, not schema initialization; the README labels their results as owner-supplied production evidence and sets non-production as the later implementation target.
- Supabase CLI `.temp` files exist under `supabase/.temp`; they are local CLI state/cache, not canonical schema or migration history. Their contents were not inspected or treated as deployment authority.

### SQL migration inventory, lexical order

| File | Repository purpose/content | Dependencies and initialization concerns |
|---|---|---|
| `001_add_role_to_profiles.sql` | Adds `profiles.role`; defines `public.handle_new_user()` and installs an `auth.users` insert trigger. | Requires `profiles` and Supabase `auth.users`. The SECURITY DEFINER trigger copies `raw_user_meta_data->>'role'` into the database role column. User-editable metadata must not be authoritative for privileged role assignment. Requires security redesign/review before use. |
| `002_fix_current_user_role.sql` | Described as a quick repair; replaces `current_user_role()` and `log_audit()`, then drops/recreates policies. | Requires `profiles`, `audit_logs`, `establishments`, `destinations`, `bookings`, `transactions`, `location_verifications`, and `system_settings` plus columns/functions. It is not a bootstrap migration and destructively replaces named policies. It shares the `002_` prefix with another file. |
| `002_rbac_dashboard_tables.sql` | Adds role check, establishments, destinations, bookings, transactions, establishment reviews, location verifications, audit logs, settings; helper functions, Auth/destination triggers, RLS and policies; inserts a setting, sample destinations and possibly a verification row. | Header says `profiles` and `favorites` already exist. The DDL also depends on Supabase Auth and profile identity. Its destination/business schema and `bookings`/`transactions` domain differ from the later `004`/backup `reservations`/`payments` model. Writes reference and mutate policies; not a harmless schema-only file. |
| `003_seed_dashboard_sample_data.sql` | PL/pgSQL block inserts a sample establishment, bookings, transactions, establishment reviews and audit records for selected accounts. | Requires accounts matching literal example emails and prior tables/roles. Creates sample financial/review/audit records; not suitable for automatic initialization or a shared project without an approved synthetic-fixture plan. |
| `004_full_schema_from_spec.sql` | Adds functions/profile columns and tourist profile, destination, availability, itinerary/stops, MO-GA result, self-healing log, weather cache, reservation/payment, notification, event, review and audit tables; sets RLS and policies; updates destinations and inserts sample events. | Header says “after 002 … (or standalone if fresh DB),” but standalone use still requires `profiles`, `establishments`, Supabase `auth`, and required existing columns. It does not create all relations present in the backup (for example, categories/roles/favorites) and does not create the profile/establishment foundations. `CREATE TABLE IF NOT EXISTS` does not make an existing incompatible table match the desired definition. It also repeats/changes destination and audit fields, status values, functions/policies and trigger setup. |
| `005_seed_sample_reservations.sql` | PL/pgSQL block creates sample reservations/payments/reviews and audit rows. | Requires matching literal sample accounts, establishment/destination rows, and `004`-style relations/columns. It is synthetic transactional data but includes personal-looking review text and financial amounts; do not run as generic setup. |
| `006_seed_all_samal_places.sql` | Inserts named destination and pending verification fixtures; destination rows carry ratings, entrance fees, durations, status/verification flags and image URLs. | Depends on the destination and verification schema, profile roles, and existing name uniqueness/shape. Data is authored in SQL and not established here as verified current source data; it must not be presented as live/verified CARS evidence. |

There are seven `.sql` files under `supabase/migrations/`. The two `002_` files make filename order ambiguous for any runner that interprets the prefix as a migration version. The scripts also contain manual-console instructions and seed behavior, so the folder is not a clean, deterministic migration ledger as currently organized.

## 4. Canonical schema determination

**No canonical schema source is established by the repository.**

1. The checked-in backup is the broadest single schema artifact. It describes approximately two dozen public application relations plus functions, FKs, indexes, triggers and policies. However, it is labeled/located as a backup, has no matching migration manifest or timestamped baseline contract, relies on Supabase Auth objects, includes security-sensitive policies, and its paired `data.sql` has not been approved as synthetic seed content. It is evidence of a historical shape, not authorization to restore it.
2. Migration `004_full_schema_from_spec.sql` is the closest item to an intended full application schema by filename and comments, but it is not self-contained as written, overlaps with objects from `002_rbac_dashboard_tables.sql`, and is not a reconciled, immutable versioned baseline. Its “standalone if fresh” comment conflicts with its references to existing profile/establishment/auth relations.
3. Migrations `001`–`006` are a mixture of profile/RBAC patches, alternate table models, repairs, schema declarations and sample-data scripts. Their order and prerequisites are not fully represented in configuration or migration history.
4. The `001_current_behavior_reproduction.sql` in the non-production directory is explicitly comment-only. It is not a candidate initializer.

The intended canonical schema must therefore be selected by the project owner/database reviewer from a reviewed schema manifest. The selection must identify which objects are in-scope for SAMAL NAV, which historical/alternate models are excluded, exact object versions, and the source for each column/constraint/policy. It must reconcile, at minimum, `bookings` vs `reservations`, `transactions` vs `payments`, `establishment_reviews` vs `reviews`, `tourist_details` vs `tourist_profiles`, category/role catalogs, and destination rating/price semantics. Do not infer that every object in the dump is wanted merely because it is present.

## 5. Dependency and initialization analysis

### Core dependency ordering visible in repository SQL

The static foreign-key/function references imply the following broad dependency order if these objects are selected and approved:

1. Supabase-managed prerequisites (including `auth.users`, `auth.uid()` and standard API roles) must be verified as platform-provided; do not recreate them.
2. Canonical role/catalog tables and `profiles`, with an owner-approved role vocabulary and a safe Auth-to-profile lifecycle.
3. `establishments` and approved category/reference objects.
4. `destinations` and destination-linked activity, gallery, availability, review and verification objects.
5. Tourist profile/preferences, itineraries and itinerary stops.
6. Itinerary dependents such as MO-GA results and self-healing logs.
7. Reservations/payments, events/notifications, settings and audit objects according to approved scope.
8. Functions before policies/triggers that call them; then constraints/indexes, RLS, grants, triggers and reviewed reference seed data in dependency order.

This is a dependency outline, not an executable migration plan. Cycles, exact types, triggers, grants, policy requirements and chosen domain tables must be resolved in the selected canonical source.

### Known mismatch/conflict set

- **Version collision:** `002_fix_current_user_role.sql` and `002_rbac_dashboard_tables.sql` both use version `002`.
- **Bootstrap gap:** `001` assumes `profiles`; `002_rbac_dashboard_tables` says `profiles` and `favorites` already exist; `004` relies on `profiles` and `establishments`. No unambiguous first migration creates all prerequisites in the numbered set.
- **Alternate domain models:** `002` creates `bookings`, `transactions`, `establishment_reviews`; `004` creates `reservations`, `payments`, `reviews`. Backup content contains the latter models and can also contain both review variants. The application’s actual service usage cannot determine which server schema is canonical.
- **Destination drift:** `002` creates a destination shape, `004` uses `IF NOT EXISTS` and adds selected columns, while backup has a broader shape including categories and fields not necessarily created by the sequence. Conditional creation does not verify or repair column/type/constraint differences.
- **Profile drift:** the backup and `004` contain `tourist_profiles`; the backup also contains `tourist_details`; application profile service uses `tourist_details`. No deployed choice follows from these artifacts.
- **Role/catalog inconsistency:** `001` and `002` check text role values; backup has a `roles` table and a profile role FK. The initialization source must choose one explicit, tested contract.
- **Constraint mismatch with approved requirement:** the backup and `002` declare `UNIQUE(establishments.owner_id)`, which conflicts with approved AP-24 (one owner may manage multiple establishments). A non-production initializer must not silently carry this conflict forward; any change requires an approved design and data-preservation review.
- **Duplicate/overlapping functions, policies and triggers:** role/audit/profile helper functions and Auth/destination triggers recur across migration files and the backup. Replacing policies by name does not establish the complete effective policy set or prove safe access.
- **Sample destination conflicts:** `002` and `006` contain overlapping destination names/records with differing coordinates and details; `006` uses `WHERE NOT EXISTS` by name and ends `ON CONFLICT DO NOTHING`, which can mask the distinction between pre-existing rows and fixture rows.
- **History mismatch:** no `supabase/config.toml`, no non-production SQL migration ledger output, and owner-reported qualified `to_regclass` NULL. Thus no reliable “already applied” map is present in this task’s evidence.

## 6. Functions, triggers, indexes, RLS and security review

### Functions and triggers

The backup defines `current_user_role`, `handle_new_user`, `log_audit`, `set_updated_at`, `admin_toggle_owner_verification`, and `increment_review_helpful`. Migration files repeat or redefine several helpers. `001` and `002_rbac_dashboard_tables` attach an Auth signup trigger; `002_rbac_dashboard_tables` and `004` attach destination timestamp triggers; the backup also defines activity timestamp behavior. Before any initialization, each selected function needs a complete body, owner, SECURITY DEFINER status, fixed `search_path`, EXECUTE ACL, and dependency review. Auth triggers must be installed once and tested without accepting user-editable metadata as a privileged role source. Owner-verification and audit functions must be reviewed separately before inclusion.

### Indexes and constraints

The backup declares PK/unique/FK/check constraints and only a small explicit secondary-index set in the inspected SQL. Migration files define various PK/unique/FK constraints inline. A reviewed initializer must inventory all indexes and constraints from the chosen canonical manifest and verify exact source/target columns, delete/update actions, deferrability, validation, and uniqueness. Do not assume the backup’s index list is a performance-complete design. Resolve duplicate FKs and AP-24 before preparing a baseline.

### RLS and grants

`002` and `004` enable RLS for their respective table sets and drop/recreate named policies. The backup carries multiple overlapping permissive policies on some tables. Static review shows policy definitions in source files, not the final effective policy/grant result for the target project. A successful initial schema load requires a table-by-table RLS-enabled/forced inventory, exact policy/role/command/USING/WITH CHECK review, schema/table/sequence/function grants, and tests through anon/authenticated role paths. Owner-supplied absence of application tables does not authorize installing the backup’s policies blindly.

Particular concerns requiring explicit review include the SECURITY DEFINER signup trigger’s role source in `001`/`002`, broad profile SELECT policy examples, policies with unconditional predicates, policies that rely on `current_user_role`, and write-capable audit policy examples. These are repository risks, not claims about current deployed policy state.

## 7. Seed-data requirements

Separate schema initialization from data loading.

- `002_rbac_dashboard_tables.sql` inserts system settings, destination examples and a location-verification example.
- `003_seed_dashboard_sample_data.sql` selects literal example account emails and writes establishment, booking, transaction, review and audit rows.
- `005_seed_sample_reservations.sql` selects literal example account emails and writes reservation, payment, review and audit rows.
- `006_seed_all_samal_places.sql` inserts a larger set of hard-coded destinations and an optional verification row, including hard-coded ratings, entrance fees, duration, active/verified flags and external image URLs.
- `004_full_schema_from_spec.sql` inserts sample events and performs a status update.
- `supabase/backup/data.sql` is a dump, not a declared test fixture set. Its records were not inspected in this audit and must not be imported until provenance, privacy, ownership, and synthetic-data suitability are established.

For a safe non-production setup, seed only explicitly approved reference rows and synthetic test records. Keep Auth accounts/fixtures separate and synthetic; do not depend on placeholder email addresses or copy production data. Mark unverified destination values as fixtures rather than verified evidence. Maintain a seed manifest with stable IDs or idempotency strategy, ownership, dependencies, expected row counts, and teardown/reset authorization. Do not seed CARS rating, price, weather, or availability as if verified live data.

## 8. Ordered non-production initialization plan

The following is a gated plan, not permission to execute it.

| Order | Required action | Gate / stop condition |
|---:|---|---|
| 0 | Record owner-confirmed project name, ref, region, operator, timestamp, and independently verified dashboard target. Preserve the owner-supplied evidence behind the empty-schema findings. | Stop if target identity differs or the output scope/timestamp is unknown. Never use the production project. |
| 1 | Obtain a complete sanitized catalog baseline for the target, including all schemas inspected, platform-vs-application object scope, migration-history relations, roles, extensions, and any objects not covered by Task 18. | “No app tables found” and one NULL `to_regclass` result are not a full database inventory. Stop on catalog visibility limitations. |
| 2 | Approve a canonical object manifest and resolve domain conflicts (table variants, profile source, categories/roles, destination fields, AP-24, required activity/weather/rating/price fields). | No migration authoring until owner, backend, database and security reviewers agree on exact scope. |
| 3 | Build a clean, unique, ordered migration design from the approved manifest. Split schema migrations from seed scripts; remove prefix collisions; state prerequisites; make each migration transaction/error behavior explicit; include rollback/forward-repair strategy. | Existing `001`–`006` are not approved for blind replay. Review exact DDL, policies, functions and grants line-by-line. |
| 4 | Validate the proposed sequence in a disposable local PostgreSQL/Supabase-compatible environment with the required platform extensions/Auth stubs handled per approved test harness. Check clean install, repeatability where intended, dependency order, and post-migration schema diff. | No use of the target project for first syntax/debug cycles. Any failure or unexpected object diff returns to design review. |
| 5 | Approve seed manifest and synthetic-only fixture policy. Exclude `backup/data.sql`, demo booking/payment/review scripts and unverified CARS values unless individually reviewed and specifically authorized. | Stop if any seed requires real account identifiers, production rows, credentials, or unverified claims. |
| 6 | Prepare a pre-change non-production backup/export and recovery plan; verify restore procedure in an isolated environment. Confirm project reference immediately before the approved run. | No destructive reset or drop/recreate without separate explicit approval and verified recoverability. |
| 7 | Obtain written, scoped non-production implementation authorization naming exact migration hashes, runner, operator, target, time window, seed set, and stop/rollback authority. | This Task 20 audit grants no authorization. |
| 8 | Under that separate authorization only, execute the reviewed sequence with per-migration checkpoints and capture results. | Stop on the first unexpected object, error, mismatch, or security finding; do not improvise edits in SQL Editor. |
| 9 | Re-run read-only catalog verification; compare exact schema/policies/grants/functions/triggers/indexes and migration history with the approved manifest. Run authorized synthetic identity isolation tests and app smoke tests. | Do not enable application writes or CARS ranking until acceptance criteria and source semantics are verified. |

### Proposed logical grouping after approval

1. Platform prerequisite verification and role/profile foundation.
2. Reference/catalog schema and establishment/destination domain.
3. Tourist preferences and itinerary/draft domain.
4. Supporting reservation/event/notification/audit domains only if included in the approved scope.
5. Functions/triggers with reviewed security properties.
6. RLS policies and least-privilege grants.
7. Synthetic reference/test seeds in a separate controlled step.

This logical grouping does not assign migration filenames or provide executable SQL. Exact order must follow the final FK/function dependency graph.

## 9. Validation, backup and rollback requirements

Before execution, define pass/fail assertions for:

- all expected relations/columns/types/defaults and no unapproved relations;
- PK/unique/check/FK constraints, source and referenced columns, actions and validation state;
- indexes, validity/readiness and sequence ownership/defaults;
- function signatures, body version/hash, owner, SECURITY DEFINER, `search_path`, volatility and EXECUTE privileges;
- triggers and enabled state, including Auth profile creation behavior;
- RLS enabled/forced state, complete policy inventory, grants and role membership;
- synthetic authenticated user data isolation and anon read boundaries;
- approved reference/seed counts and no imported real user data;
- repository application compatibility for read paths and explicit error behavior.

Back up the non-production project before any approved write and rehearse restoration away from the target. Treat database rollback as restore or a separately reviewed forward-fix plan; do not assume DDL can be safely reversed after data changes. Never use the production database as a rollback source or copy its user data into non-production. The approval must define who can halt the run, how partial migrations are identified, and what happens if restoration fails.

## 10. Explicit implementation authorization requirements

Initialization requires a new explicit approval after the blockers above are closed. The approval should identify:

- the project name, exact ref and region, with operator’s independent dashboard confirmation;
- the approved canonical schema manifest and migration files/hashes;
- an exact execution method/operator and authorized time window;
- whether and which synthetic seeds are allowed;
- backup/restore evidence, validation assertions, stop conditions and rollback owner;
- backend/database/security review of function bodies, signup trigger role assignment, RLS policies, grants, and AP-24 handling;
- confirmation that no production URL, credential, data, or migration target is included;
- separate approvals for schema initialization, synthetic Auth fixtures, and any destructive reset if applicable.

Production deployment and CARS activation remain separate approvals. No authorization is inferred from the supplied empty-schema findings, this audit, or prior CARS work.

## 11. Final determination

- **Canonical schema:** Not determined; no repository artifact is safe to designate as the authoritative initializer without reconciliation and approval.
- **Can existing migrations be applied in order?** No. The duplicate version prefix, unmet prerequisites, overlapping schema variants, seed side effects, and security blockers make blind ordered replay unsafe.
- **Can the backup be restored as-is?** Not authorized or established as safe. It is a historical dump with platform dependencies and security/data-import implications.
- **Initialization readiness:** **BLOCKED** pending canonical schema decision, migration redesign/review, complete target baseline, seed policy, and explicit implementation authorization.
- **Database activity in this audit:** None. No SQL executed; no Supabase connection; no objects/configuration changed.

## 12. Validation record

- Inspected the complete `supabase/` file inventory, all seven migration SQL files, schema dump structure, backup data file metadata (not row contents), non-production README/scaffold, evidence README, and relevant database documentation.
- Confirmed `supabase/config.toml` is absent and `supabase/remote_schema_baseline.sql` is empty.
- Reviewed migration object declarations, dependencies, data-writing blocks, functions, triggers, RLS statements and policy definitions statically. No PostgreSQL engine parsing or SQL execution was performed.
- Owner-supplied non-production findings were recorded as supplied; they were not independently checked against the project.
- **Created:** `docs/TASK_20_SAMALNAV_NONPRODUCTION_DATABASE_INITIALIZATION_AUDIT.md` only.
