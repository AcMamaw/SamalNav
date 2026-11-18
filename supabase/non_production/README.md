# Non-production authorization setup scaffold

This directory is for the isolated `SamalNav-NonProduction` project only:

- Project reference: `iwzyasdanesaaxxjujxr`
- Region: `ap-southeast-2`
- Prohibited production reference: `kmypkzusxxlyojkzrrtn`

`001_current_behavior_reproduction.sql` is intentionally comment-only and is
not setup DDL. The reviewed H-A through H-G documents establish selected field
names, relationships, policy summaries, and function behavior, but do not
provide all exact typed table definitions, complete policy/grant output, or a
complete function body needed for faithful reproduction. No schema objects are
prepared as executable SQL until those gaps are resolved.

Before any future, separately authorized manual setup, run
`scripts/non_production/Assert-NonProductionTarget.ps1` with the project name,
reference, and region copied from the selected Supabase dashboard. The script
fails closed on missing or nonmatching inputs and performs no network, SQL,
Auth, or database operation. It validates operator-supplied values only; it
cannot prove which dashboard is open. Independently verify the dashboard
project and connection target immediately before any approved action.

## Current evidence blockers

1. Obtain untruncated typed I-2 metadata and complete constraints for every
   table to be created, including `profiles`, `establishments`, `destinations`,
   `itineraries`, `itinerary_stops`, `reservations`, and `audit_logs`.
2. Use the later owner-supplied SUP-05/06R summaries for their stated eleven-relation,
   three-role scope; do not treat them as full column/object ACL output. The original
   H-A Query 5 membership result was flawed. Corrected H-I Query 13 was later reported
   with ROOT_STATUS rows for anon, authenticated, and service_role and no visible paths.
   Preserve its catalog-visibility limitation; the raw result is not retained here.
   Do not rerun solely to recreate missing raw output unless a specific setup decision
   needs details not established by the supplied summary.
3. Obtain the full Query 7 policy rows for all selected relations, including
   exact roles, commands, permissive/restrictive mode, `USING`, and `WITH CHECK`.
4. Use the complete Query 8/9 definitions and ACL results to review
   `current_user_role()` and `admin_toggle_owner_verification(uuid, boolean)`.
   The owner-verification characterization copy must be distinctly named and
   isolated to synthetic establishments. Its owner-wide update/default-create
   effects are characterization only and require explicit policy review.
5. Confirm all required establishment fields/defaults used by the function's
   default-creation path. Do not invent values or make the copy create real or
   production objects.
6. Keep current-behavior reproduction separate from candidate improvements.
   This task prepares no candidate object, Auth user, synthetic row, or
   migration-history entry.

No SQL has been executed. No Supabase project has been accessed or modified.
