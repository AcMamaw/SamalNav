# Task 09B-G — Final Reservation Implementation Readiness

**Status:** Final readiness assessment; analysis and documentation only. **Overall readiness: NOT READY FOR IMPLEMENTATION.**

**Policy authority:** Task 09B-D AP-01–AP-26. Task 09B-E supplies the technical proposal, and Task 09B-F-R1/R2 supplies the production evidence reconciliation. This report does not amend or authorize changes to those policies.

## A. Approved policy baseline

The following summarizes the 26 approved decisions without changing their meaning. The detailed canonical wording and consequences remain in Task 09B-D.

| ID | Approved baseline |
|---|---|
| AP-01 | Reservation information is server-persisted on a draft before itinerary save; authenticated tourists can continue across devices. Offline sync is separate future work and is not currently implemented. |
| AP-02 | Tourists may select a catalog establishment or enter an off-directory name/location snapshot; do not fabricate IDs. |
| AP-03 | The only reservation event types are Accommodation, Activity, Dining, and Other; Other requires a description. |
| AP-04 | Start-only appointments may be saved but cannot be called fully schedule-feasible without end or duration. |
| AP-05 | Tourist supplies end time or duration; preserve the supplied value and identify a calculated counterpart. |
| AP-06 | Use half-open `[start,end)` intervals; adjacency is not overlap, while travel feasibility is separate. |
| AP-07 | No invented early-arrival, parking, setup, grace, or travel buffers; unreliable route estimates remain unknown. |
| AP-08 | Use Asia/Manila schedule semantics; timestamps are timezone-aware and accommodation dates remain date-only. |
| AP-09 | Accommodation is one continuous stay with preserved dates and optional, non-defaulted times; it is the overnight location and requires travel reassessment on extension. |
| AP-10 | Preserve planned/actual extension history, label tourist reports unverified, reassess remaining plan, and require tourist approval before applying proposed changes; preserve completed stops and external commitments. Applies to all methods. |
| AP-11 | Prefer official/verified sources; show provenance, freshness and incomplete data; do not claim availability/open status without current evidence. |
| AP-12 | Tourism Office publishes official events/public activities; verified establishment owners publish their own activities, including those open to non-guests; external listings need evidence/source labels; tourists do not publish official listings. |
| AP-13 | Tourists control optional notification categories; disabling notifications does not remove directory access. |
| AP-14 | Event changes/cancellations notify affected users, stale relevant itinerary references, and may prompt a proposed reassessment; no silent rearrangement and tourist approval is required. |
| AP-15 | Participation classes are Open Participation, Registration Required, Reservation Required, and Not Verified; SAMAL NAV does not register/book/confirm participation. |
| AP-16 | Past events become Ended and are excluded from new recommendations/notifications, but remain for itinerary history; Cancelled/Postponed remain distinct and records are not deleted just because dates passed. |
| AP-17 | Activities/events stay separate from CARS. Preserve six CARS criteria/weights and three MO-GA objectives; discovery factors do not become CARS criteria or MO-GA objectives. |
| AP-18 | Activity discovery is available from Tourist Home, a directory, planner suggestions, and Notification Center. |
| AP-19 | In-app notifications are the signed-in user baseline; PWA push is optional, permission- and capability-dependent, with in-app fallback. |
| AP-20 | Tourism Office and verified establishment publishers have role-specific management; Super Admin oversees moderation/permissions; tourist reports require authorized review; changes are audited. |
| AP-21 | Tourists may edit/remove reservation information on unfinished drafts and saved itineraries; draft deletion removes its children; completed history remains absent explicit delete; retention is bounded by an approved policy; deletion is not external cancellation. |
| AP-22 | Reservation data is private to its tourist. Establishment owners and Tourism Office have no default access. Exceptional admin access is limited, justified and audited. |
| AP-23 | Missing/unverified location does not remove an event; retain manual snapshots and do not invent IDs, distance or duration; feasibility is unknown without reliable location. |
| AP-24 | One owner may manage multiple independently identified/verified establishments; owners manage only theirs; Tourism Office verifies. Existing UNIQUE owner constraint needs a separate reviewed migration preserving records. |
| AP-25 | Conflicts are explained; alternatives may rearrange flexible destinations only; tourist chooses; external commitments are never silently changed. Overall labels are exactly Feasible, Partially Feasible, Infeasible, Unknown. |
| AP-26 | Deleting a saved/completed itinerary warns/confirms and deletes associated reservation information under approved retention behavior; retained history retains the information; external booking is not cancelled and audit minimizes private notes. |

All three planning methods share an **optional** reservation-information step after selection/recommendation review and before optimization. Manual Selection and Circuit-Based Planning do not require CARS; System-Generated Planning does. This is not a fourth method. Reservation entries describe fixed external commitments, not ordinary destination genes and not bookings made by SAMAL NAV.

## B. Technical contract readiness

| Contract area | Readiness | Basis and gate |
|---|---|---|
| Draft persistence and itinerary promotion | **Blocked by production architecture/security evidence** | D/E propose stable server draft identity and atomic promotion. No draft table/promotion operation is in supplied inventory. Need complete itinerary schema, same-owner enforcement, transaction/idempotency strategy, lifecycle/retention approval. |
| Reservation-event records and lifecycle | **Requires clarification** | Four types and external-arrangement semantics are approved. New table absent. Need exact timing serialization, ownership, parent transition, retention, conflict and deletion policies. Keep separate from `public.reservations`. |
| Establishment reference/off-directory snapshots | **Ready for implementation design** | Catalog reference vs tourist snapshot/no fabricated UUID is clear. Production establishment coordinates nullable; model/directory and source/coordinate validation still need contract confirmation. |
| Time, duration, accommodation | **Requires clarification** | Start-only, provenance, half-open intervals, Asia/Manila and continuous accommodation policy are set. All-day serialization, same-day stays, duration precision and missing-time aggregate status remain open. |
| Location provenance | **Requires clarification** | Missing location remains unknown; no fake route inputs. Geocoding/provider, coordinate validation, freshness and privacy are undecided. |
| Extension history | **Ready for implementation design** | Preserve original/revised planned/actual data and tourist-reported status; propose schedule only and require approval. Retention and exact recovery cases remain open. |
| Feasibility and proposed revisions | **Requires clarification** | Four labels and no-silent-change policy are fixed; aggregation and Partially Feasible/Unknown boundary are not approved. Current MO-GA does not implement event constraints. |
| Activity/event directory | **Blocked by production architecture/security evidence** | Tables `activities` and `events` exist, but supplied metadata/policies do not establish that the full publisher, source, lifecycle, participation, freshness and moderation contract is supported. |
| Tourist activity/event references | **Requires clarification** | Save/dismiss/add are approved behaviors; standalone persistence vs itinerary-scoped reference and lifecycle are not decided. |
| Notifications and preferences | **Blocked by production architecture/security evidence** | `notifications` exists with recipient-ownership summary; exact columns, delivery semantics, privileges, deduplication and push are not verified. |
| Audit/access records | **Blocked by security evidence** | `audit_logs` exists; authenticated inserts are reported and cannot alone prove trusted audit. Privileged reservation access and event auditing need secure server-authored design/retention decision. |

“Ready for implementation design” means enough policy exists to define a detailed contract, not approval to write code or migrations.

## C. Production schema reconciliation

### Inventory and RLS baseline

Owner-supplied inventory lists 26 public tables: `activities`, `audit_logs`, `categories`, `destination_availability`, `destination_gallery`, `destinations`, `establishments`, `events`, `favorites`, `itineraries`, `itinerary_stops`, `location_verifications`, `moga_results`, `notifications`, `payments`, `profiles`, `reservations`, `reviews`, `reviews_legacy`, `role_descriptions`, `roles`, `self_healing_logs`, `system_settings`, `tourist_details`, `tourist_profiles`, and `weather_cache`. All inspected public tables were reported RLS-enabled and RLS-forced=false. This is supplied metadata, not a fresh catalog query.

The proposed `itinerary_drafts`, `itinerary_reservation_events`, and `tourist_activity_event_references` were not in the inspected inventory. Absence only applies to that inventory/query visibility.

### Relevant supplied columns and relationships

| Object | Confirmed evidence from supplied metadata | Still not established |
|---|---|---|
| `profiles` | I-2 includes `id`, email and phone; `id → auth.users(id) ON DELETE CASCADE`. | Full effective column access, role mutation protections and exact grants/policy role targets. |
| `establishments` | I-2 establishment identity/name/address/category/location/verification fields; `owner_id → profiles.id ON DELETE CASCADE`; nullable coordinates; unique owner index. | Complete per-column contract/policies and every owner-specific workflow dependency. |
| `activities` | I-2 column inventory supplied; owner policies rely on `establishment_id`; I-4 has PK and indexes on `destination_id`, `establishment_id`. | Whether fields support required listing schedule/source/eligibility/lifecycle and exact FK/policy/grants. |
| `events` | I-2 column inventory supplied; authenticated SELECT `true` and administrator ALL summarized; I-4 PK only. | Whether current fields support event lifecycle, publisher, source/freshness and public/private separation. |
| `itineraries` | I-2 includes owner, itinerary type/category, current stop index, total cost, distance, travel time, fitness score, generated timestamp and status; `tourist_id → profiles.id ON DELETE CASCADE`; overlapping permissive ALL policies; I-4 PK only. | Complete constraints/grants and draft/promotion/version support. |
| `itinerary_stops` | I-2 includes itinerary/destination IDs, day/sequence, arrival/departure, estimated travel minutes, contribution score/completion status; FKs to itineraries/destinations; overlapping permissive ALL policies including admin path; I-4 PK only. | Exact FK actions, complete policy union and reservation relationships. |
| `reservations` | I-2 columns: `id`, `itinerary_id`, `tourist_id`, `establishment_id`, `destination_id`, `eta`, `pax_count`, `reservation_status`, `service_name`, `created_at`; status constraint allows pending/confirmed/cancelled/completed; owner/admin access summary; I-4 PK only. Supplied I-3 confirms two FKs from `reservations.itinerary_id` to `itineraries(id)`: `reservations_itinerary_fk` and `reservations_itinerary_id_fkey`, both `ON DELETE SET NULL`. | Duplicate relationship is confirmed; its origin, necessity, exact dependencies and safe remediation remain unverified and require separate review. Verify whether `tourist_id` and referenced itinerary owner are constrained to the same person. |
| `notifications` | I-2 columns supplied; recipient-ownership policy summary; I-4 PK only. | Exact columns/constraints, allowed writes, dedupe, delivery, read state and effective grants. |
| `audit_logs` | I-2 columns supplied; Super Admin read and authenticated insert summary; I-4 PK only. | Server authorship/tamper resistance, exact grants, update/delete, retention and access coverage. |

Task 09B-F-R2 I-4 results: `activities` PK `id` plus destination/establishment indexes; `establishments` PK and unique `establishments_owner_id_key(owner_id)`; each of `audit_logs`, `events`, `itineraries`, `itinerary_stops`, `notifications`, `profiles`, `reservations` returned only its `id` PK within the result. No partial or expression indexes appeared in that nine-table result. Do not infer global index absence or add indexes without query-pattern and execution-plan review. The proposed event table has no deployed indexes or constraints.

### Functions, grants, types and migration history

- `public.current_user_role()` is supplied as SECURITY DEFINER, postgres-owned, `search_path=public`, reads `profiles.role` via `auth.uid()` and defaults to `tourist`. Exact execute grants/body hardening and role-resolution edge cases remain security review items.
- `public.admin_toggle_owner_verification(uuid, boolean)` is supplied as SECURITY DEFINER, postgres-owned, `search_path=public`; it updates establishments by owner and creates a default establishment if none exists. The NULL-role issue is in Section D.
- The `information_schema.triggers` query returned no rows; this is not proof that no triggers exist globally. No public sequence, enum/domain, view/materialized view rows were returned in the supplied queries, within their scope/visibility. Extensions supplied: `pg_stat_statements 1.11`, `pgcrypto 1.3`, `plpgsql 1.0`, `supabase_vault 0.3.1`, `uuid-ossp 1.1`.
- `supabase_migrations.schema_migrations` has `version text NOT NULL`, nullable `statements text[]`, nullable `name text`; zero records returned. Production objects exist despite empty history. Do not replay or register legacy migrations without object-level evidence.
- I-4 covered nine named tables only. Grants are partly known for profiles; do not generalize its index result or supplied grants to other schemas/tables/roles.

## D. Security blockers

### D.1 Potential public exposure of profile columns — priority review

**Confirmed individually:** I-2 includes email and phone columns; I-6 reports table-level SELECT grants to both `anon` and `authenticated`; public SELECT policy/policies using `true` were supplied. Together these present a priority potential exposure of all profile rows and all table-readable columns, including email and phone. Final effective exposure by role and column still depends on policy role arrays, column ACLs/revokes, schema/API privileges, views and other applicable policies. This needs separate security review before feature work. Do not overstate it as a proven externally exploitable disclosure without the complete effective-access evidence.

### D.2 NULL role in `admin_toggle_owner_verification()` — priority review

The supplied condition `caller_role NOT IN ('administrator', 'super_admin')` evaluates to NULL when `caller_role` is NULL. A PL/pgSQL `IF` branch is taken only when its condition is TRUE; NULL therefore does not enter the rejection branch. A missing profile or unresolved role could skip the exception path if this is the sole guard and reach privileged behavior. Review full deployed body, all branches, caller checks and execute grants. No function is modified here.

### D.3 `current_user_role()` security and execution privileges

SECURITY DEFINER with postgres ownership makes this a security boundary. Supplied `search_path=public` requires review of object qualification/shadowing risk, body, exception/null behavior and execute privileges. The `tourist` fallback is supplied, but does not establish that every user has a profile or that callers cannot change profile role. These exact grants and profile role write controls remain unverified. Do not change the helper here.

### D.4 Confirmed duplicate itinerary foreign keys in `reservations`

**CONFIRMED — supplied I-3 catalog output:** both `reservations_itinerary_fk` and `reservations_itinerary_id_fkey` reference `itineraries(id)` from `reservations.itinerary_id`, and both use `ON DELETE SET NULL`. The duplicate relationship is confirmed; the I-4 index output alone did not establish it, but the supplied I-3 constraint output does.

The duplicate constraints' origin, necessity, creation history, dependencies and safe remediation are **NOT VERIFIED**. Do not assume one can safely be dropped or that either is accidental. Review full constraint definitions/validation, dependent objects and migration history as a separate database task before proposing any repair. This duplicate does not itself prove that `reservations.tourist_id` matches the owner of its linked itinerary; same-owner enforcement remains a distinct question. No constraint is modified here.

### D.5 Permissive policy interaction and effective access

Permissive policies OR together per role and command. An owner-only policy does not narrow a `true` policy. Confirmed summary risks include public profiles SELECT, overlapping itinerary ALL policies, overlapping stop ALL policies with admin/super path, authenticated events SELECT `true`, reservation owner/admin access, recipient-scoped notifications and client-authenticated audit inserts. Exact role applicability and every expression are not reproduced in the supplied findings; calculate full effective access from all policies plus grants before drafting new policies. RLS is enabled but not forced on supplied tables; table owner/privileged contexts require separate treatment.

### D.6 Reservation ownership and cross-owner access

Existing `public.reservations` is establishment-side with owner/admin access for certain records. Exact row predicates and whether `tourist_id` and `itinerary_id` are constrained to the same owner were not supplied. A foreign key on each column independently would not, by itself, prove that both parents belong to the same tourist. Do not use the table for new private external-arrangement data. For proposed records, enforce session-derived owner and parent-owner equality via constraints and RLS/transaction logic, then test cross-owner access denial.

### D.7 Draft promotion ownership

No deployed draft table or promotion function exists in the supplied inventory. Promotion must validate `auth.uid()` equals draft owner and that the resulting itinerary and every child event share that owner, with atomicity and idempotent retry. Composite owner FKs plus RLS or a tightly scoped transactional operation are candidates; exact mechanism awaits catalog and platform review. Client UUIDs are not authorization.

### D.8 Privileged audit and sensitive external reservation details

Authenticated inserts into `audit_logs` are reported; this allows potential client-forged entries unless actor/action are server-controlled elsewhere. Super Admin read is reported. The supplied facts do not prove a dedicated audit trail for exceptional reservation access, purpose limitation, append-only storage, or safe metadata minimization. New reservation events reveal schedules/location and must remain tourist-private. Support/Super Admin access needs owner/security decisions and independent audit before implementation.

## E. Unresolved decisions register

These decisions are not resolved by technical recommendations. Approved AP-01–AP-26 remain fixed.

| ID | Exact unresolved question | Why it matters | Supported options / recommendation | Owner approval? | Dependencies |
|---|---|---|---|---|---|
| G-01 | What are retention periods by draft, reservation, saved itinerary, activity reference, notification and audit record? | Privacy, deletion and backup lifecycle. | Define explicit periods by data class; avoid indefinite retention. | Yes, privacy/owner. | Data classes and legal/institutional review. |
| G-02 | Soft delete or hard delete, and which audit/legal exceptions survive? | AP-21/AP-26 require clear deletion/history semantics. | Decide by object; no universal choice inferred. | Yes. | G-01, backup behavior. |
| G-03 | May support/Super Admin access reservation content, under what reason, approval, duration and review? | High sensitivity and AP-22. | No default content access; any break-glass path least-privilege and audited is only a recommendation. | Yes, security/owner. | Role inventory, audit design, RLS. |
| G-04 | How are date-only/all-day events represented and converted at local-day boundaries? | Avoid device timezone shifts and incorrect overlap. | Timed instants plus date-only dates are directionally supported; all-day mapping needs examples. | Yes for user-visible behavior. | Wire contract and timezone tests. |
| G-05 | What draft lifecycle names, expiry, abandonment and recovery apply? | Cross-device identity, stale drafts, retention. | Stable server UUID recommended; statuses/expiry unresolved. | Yes. | Persistence and G-01/G-02. |
| G-06 | How does atomic promotion work and does event parent reparent or retain a draft link? | Prevent partial/duplicate children and ensure ownership. | One trusted transaction and stable event IDs recommended. | Yes for lifecycle; technical mechanism based on production architecture. | I-3 constraints, Supabase execution design, idempotency. |
| G-07 | What does a concurrent cross-device edit show and how does a tourist resolve it? | Never silently overwrite fixed external commitments. | Optimistic expected-version conflict is recommended; UX not approved. | Yes. | Version contract, server API. |
| G-08 | What exact DB mechanism enforces event-parent owner equality? | Prevent cross-tourist attachment or ID substitution. | Composite FK + RLS or validated transactional operation; test both. | Security review required; implementation detail approval. | Full parent keys/FKs/RLS and grants. |
| G-09 | Are tourist activity saves/dismissals persistent standalone bookmarks or transient; can dismissed items be re-saved/expire? | Determines relationship, retention, cross-device behavior. | Standalone saved/dismissed plus parent-required added is a design option, not approved. | Yes. | `activities`/`events` FKs and retention. |
| G-10 | What coordinate validation/geocoder/provider is allowed? | Route feasibility and location privacy. | Manual snapshots and source provenance are approved; provider/range rules require research. | Yes. | Provider terms/security and route source. |
| G-11 | What evidence verifies external listings and how fresh must data be? | Avoid false availability/schedule claims. | Curated evidence or approved API; no provider selected. | Yes, plus external research. | Listing schema and licensing/terms. |
| G-12 | Which notification retries, expiry, read state, dedupe and affected-user scope apply? | Avoid duplicate/missed event notices and privacy leakage. | Source-version dedupe recommended; exact behavior unresolved. | Yes for user-visible delivery. | Existing `notifications` columns/policies, event references. |
| G-13 | With accommodation dates but missing check-in/out times, is overall feasibility Unknown or Partially Feasible in each case? | Consistent schedule claims. | Preserve stay and do not claim full feasibility; exact classification needs examples. | Yes, researcher/product. | G-19 and schedule tests. |
| G-14 | How does fixed-event scheduling evaluate MO-GA candidates? | Current MO-GA lacks fixed windows; objectives must not change. | Study a constraint-aware adapter over Pareto candidates; not yet validated or approved. | Yes, researcher/owner. | Engine/result contracts and feasibility rules. |
| G-15 | What happens after an actual extension where a stop/event was already missed or completed? | Preserve history and avoid fictional rescheduling. | Preserve completed/fixed events; define missed status and proposal cases. | Yes for edge behavior. | Self-Healing design and acceptance cases. |
| G-16 | What exact activity/event snapshot and retention survive when a listing changes/expires? | Itinerary history must remain understandable. | Minimal immutable reference snapshot is a recommendation. | Yes, privacy/owner. | G-01/G-02 and listing contract. |
| G-17 | How will multiple establishments per owner be supported end-to-end? | Current unique index and singleton assumptions conflict with AP-24. | Separate reviewed migration plus query/dashboard/verification/RLS/workflow review. | Yes, database/owner. | Schema dependencies and compatibility tests. |
| G-18 | What are full deployed grants, policy role arrays/expressions, function grants and role memberships? | Effective access cannot be inferred from policy names or RLS flag alone. | Obtain catalog evidence; do not guess. | No policy choice yet; production evidence is required. | Owner-run I-5/I-6 and function queries. |
| G-19 | What are exact aggregation rules for Feasible/Partially Feasible/Infeasible/Unknown? | Avoid contradictory claims and false feasibility. | Candidate definitions in 09B-E/F are proposals only. | Yes, researcher/owner. | Per-day/event acceptance examples, MO-GA boundary. |
| G-20 | What duration units, precision, rounding and validation bounds apply? | Input validity and interval calculations. | Store supplied end or duration and source; do not invent limits. | Yes, product/researcher. | Time contract and UI. |
| G-21 | Which saved/dismissed/added users and itinerary stages are affected by event changes/cancellation? | Notification scope, stale states and dedupe. | Notify users linked by approved persistent references; exact scope unresolved. | Yes. | G-09/G-12, listing version model. |
| G-22 | What is the origin, necessity, dependency impact and safe remediation, if any, for the two confirmed `reservations.itinerary_id → itineraries(id)` FKs? | Duplicate constraints may be redundant or independently depended upon; removing one without history/dependency review may break behavior or deployment reproducibility. | Supplied I-3 confirms `reservations_itinerary_fk` and `reservations_itinerary_id_fkey`, both `ON DELETE SET NULL`. Preserve pending a separate evidence-based review; do not assume repair is required. | Yes, separate database/security review and explicit approval before any constraint change. | Full definitions/validation, migration/object provenance, dependent objects, deployed behavior and verified migration-history strategy. |
| G-23 | What profile exposure is actually effective for `anon`/`authenticated` by column? | Email/phone potentially readable. | Separate security review; consider only policy/grant design supported by evidence. | Yes, security/owner for remediation. | Column grants, role targets, schema/API/views. |
| G-24 | What is the intended handling for NULL role in verification helper? | SECURITY DEFINER authorization bypass risk. | Explicit NULL/unresolved-role rejection is a security recommendation, not an executed fix. | Security owner approval. | Full function body/grants and missing-profile tests. |

## F. Implementation prerequisites

| Workstream | Must be completed first |
|---|---|
| Final database schema design | Full I-2/I-3/I-4 evidence reconciled, including the confirmed duplicate reservation FKs and their provenance/necessity/remediation review; verify existing activity/event/notification structures; resolve parent model, retention and promotion. No legacy migration replay. |
| RLS policy design | Complete I-5/I-6 policy/grant/role/function evidence; evaluate permissive OR unions; assess profiles and events exposure; establish parent-child same-owner checks; resolve exceptional access. |
| Draft persistence | Approved lifecycle/expiry, owner identity mapping, expected-version/idempotency contract, transaction/promotion design and non-prod security test plan. |
| Reservation UI | Stable persisted draft service contract, four event type validation, source/unknown states, local time/date contract, retention/deletion notices and access tests. |
| Activity/event discovery | Actual deployed `activities`/`events` column/constraint/policy review; publisher authorization, source/freshness, listing lifecycle, activity reference persistence and moderation decisions. |
| Notifications | Existing notification compatibility plus approved categories, dedupe/retry/expiry, recipient writes and affected-user rules; in-app first, push optional. |
| Dynamic Self-Healing | Reservation event/history and feasibility contract; four-state aggregation approved; completed/fixed commitment semantics and constraint-aware MO-GA research approved. |

## G. Safe implementation sequence

Each phase is a separate authorized task; the sequence is conditional, not permission to begin.

1. **Security evidence/remediation review:** obtain complete deployed policies/grants/function details. Prioritize profile column exposure, NULL role guard, policy OR combinations, audit authorship, and reservation owner isolation. Any remediation requires separate approval.
2. **Existing schema compatibility:** reconcile all 26 tables and migration history. Separately investigate the confirmed duplicate reservation FKs (G-22), same-owner integrity, and `activities/events/notifications` capabilities. Do not replay old migrations or remove a constraint without review.
3. **AP-24 ownership compatibility:** separately design and approve the `UNIQUE(establishments.owner_id)` change with all affected services, `maybeSingle()` assumptions, dashboards, verification, RLS and creation/management workflows. Preserve all current rows and verification state.
4. **New schema design:** finalize draft/event/reference/extension contracts, owner constraints, retention, idempotency and promotion. Specify new RLS/grants after schema review.
5. **Migration review and application (future authorized task):** additive forward migration, rehearsal, backup/rollback plan, exact post-migration catalog verification. Never register/replay legacy scripts without evidence.
6. **Models and services:** typed draft/event/reference/provenance, session-derived ownership, optimistic versioning and idempotent operations; no offline sync claim.
7. **Server draft persistence:** authenticated cross-device retrieval and atomic promotion, then test conflict/retry/access behavior.
8. **Reservation UI integration:** shared optional step in Manual, Circuit and System-Generated methods; same draft ID; skip/add/edit/remove; clear “Externally Arranged Reservation” disclaimer. CARS only in System-Generated.
9. **Schedule feasibility:** interval overlap, accommodation continuity, route unknowns, daily limits and approved four-state results; preserve fixed commitments and request tourist approval for proposals.
10. **MO-GA constraint research/integration:** evaluate existing Pareto candidates with fixed events only after research; preserve the three objective values/formulas and day boundaries.
11. **Activity/event directory:** publisher and moderation permissions, reliable source metadata, broad activity scope and tourist references; do not integrate discovery factors into CARS.
12. **Notifications:** in-app center and preferences, source-version dedupe/update effects; optional push after platform/security review.
13. **Dynamic Self-Healing:** planned/actual extension history, revised schedule proposal and tourist approval across all three methods.
14. **Retention/audit and offline sync:** implement approved deletion/retention/audit; offline synchronization is a distinct later feature after server persistence.
15. **Testing and deployment:** continuous unit, integration, RLS/security, cross-device and acceptance tests; production rollout only after reviewed migration, backup and rollback readiness.

## H. Final readiness assessment

### What can safely proceed

- Design review of the existing owner-supplied metadata and unresolved decision register.
- Owner-run read-only catalog collection and security review; no database write.
- Test-case and acceptance-criteria refinement without changing the approved policies.
- A separate design task for AP-24 compatibility and establishment workflows.

### What is blocked

- Implementing draft/event schema or RLS until complete production policies, grants, functions and relevant constraints are reconciled.
- Building persistent draft/event services until owner identity, atomic promotion, version conflict, retention and deletion are decided.
- Claiming activity/event discovery is supported by current columns/policies without complete metadata review.
- Reservation-aware MO-GA or Dynamic Self-Healing until feasibility aggregation and algorithm integration are researched and approved.
- Cross-device or offline sync claims; no current synchronization implementation is verified.

### Missing evidence

- Task 09B-A, expected title **“Reservation Contract and Lifecycle Design,”** and Task 09B-B, expected title **“Reservation Policy Decisions and Persistence Design,”** were not found under their expected names or alternate filenames/paths in the repository. Their contents are not inferred. D/E/F are present and were reviewed; obtain A/B if they contain authoritative decisions not captured in D.
- Although I-3 confirms the two itinerary FKs, their origin/necessity/dependencies and safe remediation remain unverified. Also verify whether `tourist_id` and linked itinerary ownership are constrained to the same owner.
- Exact full RLS policy expressions/role targets and table/column/schema/function grants, especially effective profile access.
- Complete SECURITY DEFINER definitions/execute grants and profile role mutation/creation path.
- Trigger/function catalog output, constraints, indexes beyond the supplied I-4 scope, and relevant `activities/events/notifications` contract comparisons.
- Non-production transaction/RLS design for atomic promotion; no evidence of this capability exists yet.

### Project-owner decisions still required

At minimum: retention and soft/hard delete; privileged access; draft expiry/lifecycle; cross-device conflict UX; activity bookmark persistence; external source/geocoder choices; notification retries/expiry/affected users; accommodation missing-time classification; feasibility aggregation; duration validation bounds; event-update impact. Separately approve security remediation and the AP-24 owner constraint migration. Recommendations in this report are not approvals.

### Immediate next task

**Task 09B-G-1 — Production Evidence Completion and Security Decision Review (read-only/design-only).** Review the supplied I-3 definitions and provenance/dependencies for the confirmed duplicate reservation FKs, and verify same-owner integrity; complete exact I-5/I-6 policy/grant and function execute evidence; and perform a column-level exposure review for `profiles`. In parallel, locate the missing A/B source documents or confirm with the owner that D is the canonical policy record. Do not create a migration or change production policies until the review and separate approvals are complete.

**Overall readiness: NOT READY FOR IMPLEMENTATION.** The policy baseline is approved, but security findings, production evidence gaps and owner decisions block schema/RLS and feature implementation. This report does not begin the next task.
