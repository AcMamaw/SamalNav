# Task 36A â€” Final Owner Decision Summary

**Project:** SAMAL NAV
**Reference:** Task 36A â€” Profile Preference Contract Closure and Acceptance Matrix
**Status:** Seven owner selections consolidated
**Implementation authorization:** **Not granted.**

## 1. Owner selections

| Decision | Owner selection | Selected direction |
|---|---|---|
| D36A-01 â€” Nullable profile preference | Option C â€” Nullable with Compatibility Protection | Local profile preference supports null. Remote null writes and clearing remain deferred until remote compatibility is verified and separately authorized. |
| D36A-02 â€” Legacy value compatibility | Option A â€” Exact Dual-Read Compatibility | Recognize canonical identifiers and explicitly approved aliases. Preserve original raw values during unrelated updates. Write canonical identifiers upon explicit selection. Preserve unknown identifiers without substitution. |
| D36A-03 â€” Profile preference confirmation | Option C â€” Remain Unconfirmed Until a Durable Confirmation Mechanism Exists | Create, fetch, save, and update do not establish confirmation. CARS does not treat unconfirmed preferences as confirmed recommendation evidence. |
| D36A-04 â€” Profile and itinerary precedence | Option A â€” Strict Precedence Hierarchy | Fixed commitments > explicit individual itinerary-leg selections > explicit trip-wide transportation preferences > profile preferences > system-generated suggestions. Lower-priority preferences cannot silently overwrite higher-priority selections. |
| D36A-05 â€” Catalog-based profile selection | Option A â€” Strict Capability-Based Selection | A mode is a new profile choice only if active and `workflowCapabilities.profilePreference == true`. Unknown and inactive historical values remain visible/preserved, not new choices. |
| D36A-06 â€” Local and remote data compatibility | Option A â€” Local Nullable Model with Existing Remote Contract | Support local nullability while retaining the remote `travel_mode` field. Defer remote null writes, schema changes, and migrations until verified and separately authorized. |
| D36A-07 â€” Profile validation and error handling | Option A â€” Strict Validation with Preservation | Accept null; reject empty strings as new values; accept canonical IDs and approved aliases; preserve unknown/inactive history; reject invalid new values; preserve saved data after failed updates; remain unconfirmed absent durable evidence. |

These are owner-selected architectural directions. They do not grant implementation or database authorization.

## 2. Consolidated profile preference contract

- The local profile preference is nullable; null means â€œno preference.â€ Empty string is invalid. Do not invent a default mode or sentinel.
- Preserve the existing remote `travel_mode` field. Do not send null remotely or claim that a remote clear succeeded until compatibility has been verified and separately authorized.
- Decode canonical IDs and only the exact approved aliases. For `public_transportation`, approved aliases are `public transportation` and `publicTransportation`.
- Preserve the original stored raw value on unrelated profile updates. Explicit user selection writes the canonical ID through the existing field only when accepted-value compatibility has been established.
- Unknown and inactive stored modes remain visible and losslessly preserved. Do not present them as new selectable values or silently replace them.
- New profile choices must satisfy both active status and the profile preference capability. Current catalog state offers the twelve entries: walking, bicycle, motorcycle, car, public transportation, jeepney, tricycle, multicab, van, bus, ferry, and boat.
- Catalog inclusion, label, and capability do not establish route availability, operator, schedule, fare, or travel time.
- Preference persistence and preference confirmation are separate. Until a durable confirmation mechanism exists, profile snapshots remain unconfirmed and CARS remains fail-closed.

## 3. Precedence hierarchy

1. Fixed transportation commitments.
2. Explicit individual itinerary-leg selections.
3. Explicit trip-wide transportation preferences.
4. Tourist profile transportation preferences.
5. System-generated transportation suggestions.

A lower-priority value may only suggest/fill an unset selection where the workflow permits it. It may not silently overwrite a higher-priority explicit choice. Unknown or inactive profile values are not mapped to another mode. Fixed commitment endpoints, mode, and schedule remain protected.

## 4. Validation and failure behavior

- Accept local null as no profile preference; reject empty string and malformed types.
- Accept exact canonical identifiers and catalog-approved aliases.
- Preserve unknown and inactive historical values for display and unrelated updates, but reject them as new selections.
- Require a new selection to be active and have the profile preference capability.
- On failed profile update, keep the prior saved state, retain the user's unsaved form selection, report failure, and do not claim persistence or confirmation.
- Do not substitute a default mode when an identifier is unknown, inactive, unsupported, or rejected by the remote contract.

## 5. Future acceptance tests

Future implementation tests must cover nullable profile values; null JSON round-trip and remote write gating; empty-string rejection; the five existing profile values; exact alias decoding; canonical writes on explicit selection; raw unknown and inactive value preservation; all twelve initial catalog entries; capability filtering; confirmation remaining false; CARS fail-closed behavior; fixed/leg/trip/profile/system precedence; failed-update preservation; existing profile regressions; and no silent transportation substitution. Tests were not run for this decision consolidation.

## 6. Remaining technical dependencies

1. Verify the actual remote `travel_mode` nullability, constraints, defaults, accepted canonical values, and update behavior before enabling remote null or canonical writes. No live schema is inferred here.
2. Ensure a full profile update can preserve the raw legacy/unknown value instead of canonicalizing it during parse and serialization.
3. Durable confirmation storage and reset behavior remain unimplemented; all current service snapshots report false.
4. The itinerary adapter still supports only the legacy five-value enum. Do not map the other catalog IDs to parent or â€œnearestâ€ modes; itinerary model integration is separate.
5. Enforce capability filtering in the future selector; the current catalog selection helper checks active status only.
6. Separate any remote schema change and access from this owner decision. A-13 scope, A-14 review, A-15 non-production authorization, and A-16 production authorization remain independent gates.

## 7. Proposed next implementation task

Prepare a separate, narrowly scoped authorization review for a **profile preference catalog compatibility slice** covering the profile model, profile service, preferences screen, and profile-to-trip adapter, with focused mocked service/model/widget tests. Before implementation, settle the remote write gate and define behavior when local null cannot be persisted remotely. Exclude Hive, per-leg itinerary data, MO-GA, CARS routing, database migrations, and Supabase operations from that first slice unless separately authorized.

## 8. Authorization status

All seven Task 36A owner decisions have been received. Profile integration remains unauthorized pending a separate implementation authorization review.

No application code, tests, dependencies, Hive data, SQL, migration, database, Supabase, or manuscript changes are authorized by this summary.
