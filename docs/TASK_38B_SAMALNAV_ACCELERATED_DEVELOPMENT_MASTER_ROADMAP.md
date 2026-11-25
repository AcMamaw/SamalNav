# Task 38B — SAMAL NAV Accelerated Development Master Roadmap

**Project:** SAMAL NAV
**Basis:** Manuscript `manuscript/SAMAL NAV  (1).docx`, current repository source, and existing Task 26–39 contracts/decisions inspected read-only
**Status:** Planning proposal only. No coding, test, database, or deployment authorization is granted.

## 1. Roadmap objective and delivery principle

Deliver the manuscript's functional system in small evidence-backed slices while preserving current working-tree changes and all earlier authorization boundaries. “Accelerated” means removing dependency waits and running bounded workstreams in parallel where their contracts are independent; it does not mean assuming formulae, availability, security, schema, or route evidence that the sources do not provide.

The manuscript remains the primary functional reference. Later owner decisions (notably D31A transport/commitment behavior) add selected constraints where they are explicit. Where the manuscript and owner decisions conflict or are underspecified, mark the feature blocked and obtain a precise resolution instead of silently choosing one.

## 2. Dependency map and critical path

```text
Author-approved manuscript baseline ─┬─> Destination / activity / role data contracts
                                     ├─> CARS criterion and evidence contracts ─┐
                                     ├─> Road / travel-time provider contract ──┼─> CARS-reviewed candidate set
                                     └─> Per-leg / commitment / Hive contract ─┘             │
                                                                                              v
Security + A-13 scope + A-14 review ───────────────────────────────────────────────> MO-GA feasibility/optimization
                                                                                              │
Recorded availability / weather evidence ──────────────────────────────────────────> Alternative/self-healing
                                                                                              │
Hive migration/recovery + sync/conflict contract ──────────────────────────────────> Offline/release readiness
```

**Critical path:** resolve manuscript ambiguities → approve data/evidence and route contracts → CARS input validity → itinerary/day/leg model and storage contract → route-aware MO-GA → user review → alternatives/self-healing → Hive migration and release gates.

The role/content management module can progress beside algorithm work once authorization, schema scope, data stewardship and A-14 review are clear. PWA visual polish can progress beside data work if it does not present unverified route, weather, ranking, or availability outputs as fact. Hive version migration cannot safely be parallelized with an unsettled itinerary schema because every subsequent model change would invalidate conversion assumptions.

## 3. Implementation batches and gates

Every batch below is a proposal. Each still requires a task-specific implementation authorization. “Owner decision exists” means a selected direction exists, not that code work is approved.

| Batch / milestone | Scope and dependencies | Candidate surfaces | Exit gate |
|---|---|---|---|
| **M0 — Requirements baseline** | Reconcile manuscript facts and conflicts; confirm which version governs. Close missing formulas, thresholds, and feature contradictions. No code. | Documentation/manuscript-owner record | Approved versioned functional baseline; open items explicitly excluded/blocked; objective-to-acceptance mapping. |
| **M1 — Security/data source readiness** | Approve source authority and freshness for rating, prices, availability, weather, routes; close A-09 audit/settings and A-11 retention; resolve A-13 schema scope; independent A-14 review. | Existing data contracts and security documentation; no live database inspection unless separately authorized | Data classification/provenance, role/RLS policy and threat review signed off; schema and source scope authorized separately. |
| **M2 — Destination and suitability data contract** | Define destination/activity/attributes, group composition, eligibility, missingness, status/accreditation, and source freshness. Explicitly avoid medical inference. | `destination_record.dart`, `cars_models.dart`, source adapters, tests | Fixtures demonstrate known/unknown/invalid/unverified distinctions; no missing-to-zero; owner-approved category/suitability vocabulary. |
| **M3 — CARS score policy** | Implement six normalized criterion computations only after each formula and weight/scale is approved. Distinguish evidence preparation, eligibility and scoring. Preserve fail-closed preference confirmation. | `cars_assessment_input_preparer.dart`, `cars_interest_activity_matcher.dart`, `cars_budget_assessment.dart`, `cars_travel_assessment.dart`, `cars_engine.dart`, provider and review UI | Reproduce manuscript's sample (RS=0.8661 at 0–1 scale) if that is confirmed governing scale; tests for each criterion, missing evidence, weights, exact tie behavior, eligible/ineligible/insufficient data. |
| **M4 — Route evidence provider** | Implement OSM/OSRM route path, road distance/time, start/stop semantics, mode support, freshness/provenance, provider failure. Do not make OSM tiles stand in for OSRM. | New isolated routing service/interface and `cars_travel_assessment.dart` adapter; focused tests | Deterministic mocked provider tests for route, unsupported mode, unknown route, stale evidence, missing origin/date; provenance carried to planner. Live provider verification requires separate environment/network approval. |
| **M5 — Local itinerary/commitment contract** | Define entry/leg identity, origin/final endpoint, per-leg stable mode reference, three commitment classes, fixed transfer endpoints/timing/timezone/user-entered/unverified status, dependencies, protected boundaries, artifact and feasibility status separately. D31A selected directions apply. | `itinerary_draft.dart`, `manual_selection_workflow.dart`; model tests | Invariants for fixed blocks, planned inclusion, optional entries; route leg binds consecutive endpoints; infeasible/indeterminate states are not conflated; legacy/unknown records represented losslessly. |
| **M6 — Hive versioned storage/recovery** | After M5 contract freeze, design version marker, staged write, recovery journal/commit marker, integrity checks, original preservation, Restricted Safe Mode, retry, validation-based restore. Verify exact resolved Hive implementation/version from lockfile at implementation time. | `local_itinerary_draft_store.dart`, startup gating, isolated storage tests | Legacy v1 fixtures preserved; interrupted writes/restart/retry idempotent; invalid data not deleted; no new-format exposure until validated; app isolates itinerary safely on failure. Do not assume Hive transactions. |
| **M7 — MO-GA fidelity and protection** | First reconcile manuscript scalar equations vs “multi-objective” name and current NSGA-II. Decide feasibility semantics, cost/time penalties, no-revisit, candidate selection/subset semantics, one/multi-day starts and returns. Enforce D31A fixed/planned/optional and three-state feasibility. | `moga_engine.dart`, `manual_selection_moga_adapter.dart`, `system_generated_draft_builder.dart`, deterministic optimizer tests | Fixed transfers remain ordered adjacent immutable blocks; planned entries retained; optional only chosen when feasible under approved objectives; unknown inputs produce Indeterminate, no fabricated travel arithmetic; circuit path tested separately. |
| **M8 — Planning workflow integration** | Integrate candidate review, manual selection, generated planning and circuit selection against M5–M7. Preserve the three distinct inputs and source provenance. | `plan_page.dart`, `system_generated_planning_page.dart`, draft review screens, circuit flow | Manual/circuit/generated flows share validators and status labels; explicit user choice wins; unsupported/unknown does not fall back; route and transfer facts survive edit/save/load/optimization. |
| **M9 — Availability / accommodation/activity alternatives** | Define recorded availability vs live confirmation; source timestamps, price provenance, alternative similarity, distance, accessibility, time fit and “replace only unavailable item” semantics. No reservation/payment side effect absent new scope approval. | Establishment/destination services/models, tourist detail/review screens | Mocked source tests for unavailable/unknown/stale, candidate eligibility, tie handling, price/route unknown; tourist confirms replacement; no fabricated or booked service. |
| **M10 — Weather and self-healing** | Resolve Eq 13, thresholds and weather restoration; define forecast time matching, missing coverage, delay zero-denominator, unavailability input and interaction with “Find Similar.” Integrate only after M4/M7/M9. | `open_weather_map_service.dart`, CARS preparation, new isolated self-healing domain/service, draft review UI | Table-driven exact boundary tests at DS .20/.40 and WRS .50/.75; short rain ≤60m; restore only after new evidence and schedule fit; preserve visited/fixed/planned entries; accept applies, reject leaves original unchanged. |
| **M11 — Tourism administration and data lifecycle** | Complete accreditation, official circuit/content/advisory, owner price/availability, ratings/feedback and permissions; resolve table scope and roles. | Admin/owner services and screens, audit, data models | Role-based acceptance tests; negative unauthorized access; lifecycle/source/freshness; independent security review. |
| **M12 — Offline, sync, and release** | Define which destinations/itineraries are syncable, sync ownership, conflict strategy, offline auth, retention, telemetry/privacy, browser compatibility. Then migration release criteria and deployment approvals. | `offline_cache_service.dart`, local draft store, app startup, PWA/platform configuration | Offline view supports only previously synchronized records; conflict and retry tested; A-15 non-production initialization separately authorized; validated migrations; A-16 production approval separately granted. |

## 4. First recommended implementation batch

The smallest meaningful coding task after the read-only analysis is a **bounded local CARS criterion contract and test slice**, but only after the owner approves the exact criterion functions, score scale, weights and treatment of missing evidence. If those decisions are not made, the smallest coding task should instead be a pure value-contract test that does not claim recommendation scores.

**Proposed initial target:** implement one independently approved CARS criterion end-to-end as a pure, source-injected assessment component, with no Supabase, Hive, UI, or optimizer changes. The public destination rating criterion is not automatically the best first slice: its approved source and freshness policy are not currently established. A safer first slice may be the already existing interest/activity matcher only if its exact normalization/weight and profile confirmation conditions are documented and approved.

Candidate source/test paths (final exact list must be in a separate authorization):

- Existing: `lib/algorithms/cars_interest_activity_matcher.dart`, `lib/algorithms/cars_assessment_input_preparer.dart`, `lib/models/cars_models.dart`.
- Existing focused test: `test/cars_interest_activity_matcher_test.dart` and/or `test/cars_assessment_input_preparer_test.dart`.
- Exclude: database schemas, Supabase, route provider, MO-GA, Hive, UI, circuit planning, self-healing, availability alternatives, and CARS scoring criteria not in the approved slice.

Acceptance criteria for that proposal:

1. The criterion function and output scale match an approved written definition.
2. Inputs carry explicit source/status where required; no missing/unknown value becomes a favorable/zero score by default.
3. Confirmed/unconfirmed profile evidence follows the existing fail-closed rule.
4. Eligibility is separate from score and cannot raise ranking.
5. Unit tests cover boundary values, missing/invalid/unverified inputs, and exact expected score.
6. Existing CARS-related tests are run; full focused analysis and diff scope are checked.
7. No remote write, Hive, itinerary, or unapproved criterion behavior is introduced.

If owner contract closure is not available, do not start score implementation. A documentation-only decision/traceability task would then be the only safe next step, and Task 38B does not authorize it beyond the three requested reports.

## 5. Parallelizable workstreams

Parallel work is only appropriate when interfaces are frozen and no shared file is being edited concurrently:

1. **Data governance/security:** A-09/A-11/A-13/A-14 and source data stewardship can proceed alongside pure algorithm contract review, but no schema/remote code changes until approvals are evidenced.
2. **Manuscript resolution:** CARS score definitions and MO-GA equation/feasibility wording can be clarified by separate subject owners. They converge at M0 and must be approved before implementation.
3. **PWA/accessibility prototype review:** screen-flow accessibility and role-flow mapping can progress independent of score implementation if it does not imply unavailable features.
4. **Test fixture inventory:** read-only legacy fixture planning can proceed while M5 data contract is drafted, but Hive write/migration code must wait for the stable serialization contract.

Not safely parallelizable: MO-GA and itinerary/Hive schema work; self-healing and route-time evidence; circuit flow and adapter integration; migration and concurrent draft contract evolution; production schema and application integration absent A-14/A-15.

## 6. Testing gates by phase

- **Contract gate:** each requirement linked to manuscript section/equation/figure or later owner decision; contradictions marked unresolved, not “cleaned up.”
- **Pure model gate:** constructors, codecs, invariants, missing/unknown states, deterministic boundaries.
- **Service gate:** mocked HTTP/provider interfaces; provenance/freshness/errors; no live network unless separately authorized.
- **Algorithm gate:** deterministic seed, fixed/required invariants, candidate feasibility diagnostics, performance limits, known manuscript example reproduction.
- **UI gate:** display unknown/unverified/infeasible distinctly; confirmation/rejection behavior; manual, circuit, generated workflows regression.
- **Persistence gate:** migration fixtures, failure injection, restart, recovery, no record loss/duplication; original format recoverable.
- **Security gate:** role-negative tests, RLS review, A-14 independent review, secret handling, retention and audit controls.
- **Release gate:** A-15 explicit non-production authorization and validated deployment rehearsal; A-16 separate production authorization. Neither is implied by code completion.

## 7. Authorization and governance gates

The roadmap does not grant permission. Before a production implementation task, each task must specify exact files, tests, exclusions, rollback and approval boundary. Security/database dependencies remain distinct:

- **A-09:** audit/settings policy and which data/actions are logged.
- **A-11:** retention/deletion policy, including offline records and personal/location data.
- **A-13:** canonical relation/scope approval; catalog and itinerary changes may expand approved manifest.
- **A-14:** independent security review for schema/RLS/admin and any new remote access.
- **A-15:** explicit non-production initialization authorization after review.
- **A-16:** separate production deployment authorization after acceptance evidence.

No Supabase, database, or SQL access is authorized by Task 38B. Existing Task 39 only authorized a bounded profile compatibility slice and excludes remote transportation writes, clearing, Hive, CARS, MO-GA and deployment.

## 8. Milestone status and exit evidence

At this review, only parts of the app are implemented: authentication/role dashboards, destination browsing/map display, profile management, local manual itinerary drafts, selected CARS evidence/ranking components, a mockable OpenWeatherMap forecast service, and a geometric/Pareto itinerary optimizer. The manuscript's complete CARS scoring, OSRM routing, Tourism Office circuit workflow, protected commitment routing, dynamic self-healing, complete alternatives, and offline synchronization contract are not established as fully implemented.

The first release claim should be bounded to features with end-to-end evidence. No manuscript feature should be marked “complete” from a prototype screenshot, table, model, test file, or incomplete service alone. Each milestone should store acceptance output, source revision, test logs and security approval evidence.

## 9. Closeout

Recommended first development batch is M0 contract resolution followed by one pure CARS criterion slice after score/evidence approval. The larger critical path is M0 → security/data provenance → CARS/route evidence → itinerary/Hive contract → protected MO-GA → workflow integration → alternatives/self-healing → offline/release. No coding authorization is granted; no tests/builds were run for this roadmap task.
