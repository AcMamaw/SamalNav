# Task 38 - SAMAL NAV Accelerated Profile Integration Authorization Review

**Project:** SAMAL NAV
**Development strategy:** Accelerated controlled development
**Type:** Bounded implementation authorization review
**Review date:** 26 November 2026 (Asia/Manila)
**Coding authorization:** NOT GRANTED
**Evidence boundary:** Read-only repository inspection. No tests/builds run; no Supabase, database, or Hive data accessed.

## 1. Executive summary

The proposed profile integration can be bounded to local profile representation, non-destructive profile service updates, catalog capability preparation, and read-only display of the currently saved value. It does not require changing itinerary models, Hive, CARS, MO-GA, circuit planning, dependencies, database schema, or the manuscript.

**Recommendation: B. Ready for owner authorization with conditions.** The owner may consider a separate coding authorization for only the files and behaviors in Section 4. That authorization must keep every remote transportation write and persistent clearing disabled, omit `travel_mode` from unrelated profile PATCH requests, preserve existing raw values, and retain the existing unconfirmed/CARS boundary. This review itself grants no coding authorization.

A later Task 37A decision controls where an earlier Task 36A direction might otherwise allow canonical writes: D36A-02 describes canonical writes after explicit selection and compatibility, while D37A-03 presently gates all transportation writes. Thus this slice has no transportation selection or remote preference write path. D36A-01 nullable local representation is compatible with the remote write restriction; null must not become a remote null.

## 2. Decision traceability

The selections below are adopted from the supplied authoritative decision records. This review does not reopen or amend them.

| Decision | Owner selection | Relevance to this bounded slice |
|---|---|---|
| D36A-01 | Option C - Nullable with Compatibility Protection | The local profile model may represent null; remote null and clearing remain disabled. |
| D36A-02 | Option A - Exact Dual-Read Compatibility | Decode canonical IDs and only exact approved aliases; retain raw source values on unrelated updates. Its eventual canonical-write direction is gated by D37A-03 below. |
| D36A-03 | Option C - Remain Unconfirmed Until a Durable Confirmation Mechanism Exists | Save/fetch/create do not confirm preferences; CARS remains fail-closed. |
| D36A-04 | Option A - Strict Precedence Hierarchy | Profile preference remains lower priority than fixed commitments and explicit itinerary choices; this slice does not change itinerary selection. |
| D36A-05 | Option A - Strict Capability-Based Selection | Future profile choices require active status and `profilePreference == true`; this slice enables no choice UI. |
| D36A-06 | Option A - Local Nullable Model with Existing Remote Contract | Keep the remote field and service boundary; no schema change or remote null write. |
| D36A-07 | Option A - Strict Validation with Preservation | Null is accepted locally, empty new values are rejected, unknown/inactive history is preserved, failures do not replace saved state. |
| D37A-01 | Option C - Evidence-Based Compatibility | Deployed compatibility is not established by checked-in SQL; no canonical remote write is enabled. |
| D37A-02 | Option C - Defer Clearing Entirely | Do not expose a clearing action or claim that the remote value was cleared. |
| D37A-03 | Option C - Gate All Transportation Writes | No remote `travel_mode` writes; omit this field from unrelated update payloads. This is the controlling write restriction. |
| D37A-04 | Option A - Strict Lossless Update Contract | Preserve raw historical values; local null is never remote null; retain last saved snapshot and surface errors honestly. |
| D37A-05 | Option C - Staged, Compatibility-Protected Integration | Staged work may establish local compatibility, service protection, eligibility preparation, and read-only display only. |

### Decision reconciliation

- D36A-02 exact alias decoding remains in force for interpretation and display. It does not authorize a write in this scope.
- D37A-03 is the later, more restrictive remote write policy and gates all profile transportation writes, including existing values and canonical IDs.
- D36A-01 permits a nullable local field. Under D37A-02/03, nullable local representation does not create a clear affordance or remote null request.
- Catalog eligibility is prepared for future use but is not rendered as selectable options and does not imply service availability.

## 3. Existing profile architecture (verified source findings)

| Component | Current implementation | Consequence for the proposed slice |
|---|---|---|
| `lib/models/tourist_planning_profile.dart` | `travelMode` is required `String`; `fromJson` requires nonempty `travel_mode`; `toJson()` always includes it; validation checks a caller-provided supported-mode set. | Must become nullable locally and preserve raw value. Its generic JSON output cannot be sent unchanged to the remote update endpoint under D37A-03. Validation must allow a retained historical value while rejecting empty input and any unsupported new selection path. |
| `lib/services/tourist_planning_profile_service.dart` | Fetch parses the full row. `createIfMissing()` inserts only `user_id`, then reads server defaults. `updateCurrent()` validates and sends full `profile.toJson()` including `travel_mode`, filters by authenticated user, and returns the saved row. Confirmation is always false. | Update must construct a payload that omits `travel_mode`. Create must continue omitting it. Server defaults may still populate the remote value; that value is not evidence of tourist selection or confirmation. Keep auth ownership and the last returned snapshot on failure. |
| `lib/screens/tourist_screens/planning_preferences_page.dart` | Has five hard-coded editable transport options, no unset option, preserves current selection as fallback, includes the mode in review dialog, and only replaces `_snapshot` after a successful service result. UI errors are generic except validation/authentication. | Replace the dropdown with a read-only display of the existing raw value (or a clearly labeled unset state), state that it is unconfirmed, do not offer selection/clear, and keep form state/snapshot on failure. Do not claim a mode was saved by an unrelated profile update. |
| `lib/services/tourist_planning_profile_trip_adapter.dart` | Receives a confirmed snapshot only; maps the five legacy values into the old trip enum; explicit trip mode wins; unrecognized profile values map to null. | If the profile field becomes nullable, the adapter signature needs a null-safe adjustment to compile and return no suggestion for null. Do not add catalog-to-old-enum coercion or change precedence. Production service currently always supplies unconfirmed snapshots. |
| `lib/models/transport_catalog.dart` | Contains twelve stable mode IDs, exact public-transport aliases, historical/unknown decoding, active status, and independent capability flags. `selectableMode()` checks activity, not a workflow-specific capability. | The catalog is already present and should not be redesigned. A profile eligibility helper, if included, must require both active and profile capability. Do not use the helper to offer new choices in this slice. |
| `test/tourist_planning_profile_service_test.dart` | Mocked service tests cover fetched/default values, unconfirmed state, authenticated update filters, and request behavior. | Extend with nullable/alias/unknown decoding, omission of `travel_mode`, no remote null/write, and failed update snapshot assertions. Do not use a live backend. |
| `test/planning_preferences_page_test.dart` | Covers current form save, unconfirmed state, and editable travel-mode dropdown. | Replace dropdown assertions with read-only/historical display and no selection/clear controls; retain unrelated profile save and error-state coverage. |
| `test/system_generated_planning_page_test.dart` | Covers confirmed adapter defaults and preservation of explicit trip choices/transfers. | Add only null-safe profile adapter regression cases if the nullable model requires adapter signature changes. Keep all itinerary behavior out of scope. |
| `test/transport_catalog_test.dart` | Covers initial catalog, aliases, serialization, unknown/inactive references, and capabilities. | Add profile eligibility filtering assertions only if a pure catalog helper is introduced. No catalog edit is needed if eligibility is evaluated in the profile slice without changing the catalog API. |

The repository's checked-in SQL is not evidence of the deployed schema. No Supabase or live database inspection was performed for this review. The Task 37A record reports the backup `tourist_details.travel_mode` declaration as non-null text with a default; treat that only as snapshot-level evidence. No production compatibility is inferred.

## 4. Minimum file-level scope proposal

The minimum coherent scope is the model, service, preferences screen, and one adapter null-safety adjustment. A catalog helper is optional and should be included only if the implementation needs a reusable, independently testable eligibility list. The catalog's existing registry does not need content changes.

| File | Proposed modification and reason | Dependencies | Regression risks | Required tests |
|---|---|---|---|---|
| `lib/models/tourist_planning_profile.dart` | Change local `travelMode` to nullable; allow JSON null on read/local serialization; preserve exact nonempty stored raw strings including unknown/inactive IDs; reject empty strings. Keep transport field separate from the service's remote-update payload. | Existing profile constructor/callers and validation policy need compile-safe migration. Distinguish local JSON serialization from remote PATCH serialization. | Null might accidentally reach a remote payload; a canonicalized parse could lose the original alias; existing validation could block unrelated edits with unknown retained IDs. | Null read/local round-trip; absent vs explicit null semantics where relevant; empty string rejection; legacy and unknown raw preservation; existing profile model/service regression. |
| `lib/services/tourist_planning_profile_service.dart` | Build unrelated update payload without `travel_mode` under all conditions. Keep insert limited to `user_id`. Preserve the returned/current saved snapshot unless a full unrelated update succeeds. Translate validation separately from network and storage failures without false success. | Do not alter authentication ownership, row filtering, creation defaults, confirmation behavior, or remote schema. All transport write paths must be absent. | Accidentally sending model `toJson()` unchanged; interpreting omitted returned columns as cleared; mapping a network error to saved success; broad exception handling that hides auth/validation errors. | Request payload has no `travel_mode`; no JSON null; server's existing value remains; failure keeps previous snapshot; validation/storage/network distinction; authentication/RLS and creation regressions. |
| `lib/screens/tourist_screens/planning_preferences_page.dart` | Remove transport editing/clear control. Show the exact saved raw value read-only, with a non-confirmed label; show null as no profile preference only if locally represented. Keep other profile controls editable. | Model nullable type; service transport-free update. Do not create a misleading success message about a transportation preference. | Existing form could fail validation on an unsupported historical mode; unrelated saves could appear to change a mode; dialog wording could imply confirmation. | Existing value and unknown/inactive value display; no dropdown, new selection, or clear action; unrelated profile update works; no false persistence/confirmation; failed save retains values. |
| `lib/services/tourist_planning_profile_trip_adapter.dart` | Accept nullable profile mode and return null for null/unmapped values; retain current exact mappings and explicit-trip precedence. This is a type-safety adjustment only. | Profile model becomes nullable. No itinerary model, per-leg logic, or profile confirmation change. | Accidental map of new catalog IDs to legacy enum or overriding explicit trip mode. | Null profile preference creates no suggestion; legacy supported map remains; unrecognized canonical/additional ID does not substitute; explicit trip choice remains. |
| `lib/models/transport_catalog.dart` (optional) | Add a pure profile-eligible mode query only if reused by callers: active AND `workflowCapabilities.profilePreference`. Otherwise leave this already-tested catalog untouched. | No remote dependency; must not conflate eligibility with availability. | Reusing active-only `selectableMode()` could ignore capability; exposing eligible entries as available transportation services. | A mode with either inactive status or capability false is excluded; eligible initial entries resolve; no availability assertion. |
| `test/tourist_planning_profile_service_test.dart` | Extend mocked model/service acceptance tests. | Existing mock HTTP infrastructure. | Do not weaken existing assertions. | Service/model items in Section 5. |
| `test/planning_preferences_page_test.dart` | Replace tests of selecting a transport mode with read-only display and gated behavior tests. | Widget test service fake. | Accidentally retaining UI path that mutates `travelMode`. | No selection/clear; existing mode remains shown; unrelated update does not report mode saved. |
| `test/system_generated_planning_page_test.dart` (conditional) | Add regression for adapter null handling only if adapter signature changes. | No generated-planning feature changes. | Scope expansion into CARS/MO-GA. | Existing explicit trip choice and transfer preservation remain unchanged. |
| `test/transport_catalog_test.dart` (conditional) | Extend only if a reusable eligibility query is added. | Optional catalog helper. | Catalog test scope must not imply routing support. | Workflow flag and active status jointly gate profile eligibility. |

### Scope minimization decision

- **Required production files:** profile model, profile service, preferences page, and profile-to-trip adapter (null-safe signature only).
- **Catalog production file:** no change by default. Add a narrowly scoped pure eligibility helper only if it is needed beyond the page; otherwise filter using the two explicit properties in the profile layer.
- **Required tests:** existing profile service and preferences page tests; adapter regression test changes if the nullable signature changes.
- **Unchanged:** all itinerary and commitment models, Hive store/data, CARS and MO-GA algorithms, circuit/manual planning behavior, dependency files, SQL/schema, and manuscript.

## 5. Required acceptance-test matrix

All are future tests for a separately authorized implementation; none was run for this review.

| # | Acceptance case | Required result |
|---:|---|---|
| 1 | Nullable local preference | Model represents null without inventing a default. |
| 2 | Null JSON read/local serialization | Explicit local JSON null is read and round-tripped; service remote payload never contains null for `travel_mode`. |
| 3 | Empty string | Empty string is invalid and is not treated as null. |
| 4 | Existing five-value compatibility | Existing `walking`, `bicycle`, `motorcycle`, `car`, and `public transportation` values remain readable. |
| 5 | Exact alias decoding | Only exact approved aliases `public transportation` and `publicTransportation` resolve to `public_transportation`; no trim/case folding. |
| 6 | Unknown ID preservation | Unknown nonempty historical ID remains exact on read and unrelated update. |
| 7 | Inactive value preservation | Known inactive value remains visible and is not offered as a new choice. |
| 8 | Raw alias preservation | Alias spelling remains exact in the saved raw model and remote row after unrelated update. |
| 9 | Unrelated update payload | `travel_mode` is absent from the remote update body. |
| 10 | Existing remote value unchanged | Mock server retains and returns the same raw travel mode after an unrelated update. |
| 11 | Failed update snapshot | Failed request leaves the UI/service's last successful snapshot unchanged and produces no success message. |
| 12 | Error distinction | Validation, network, and storage/PostgREST failures have distinct types/messages and retain form state. |
| 13 | Eligibility filtering | If prepared, list includes only `isActive && workflowCapabilities.profilePreference`. |
| 14 | No new persistent selection | No transport selection control or remote write path exists. |
| 15 | No remote transportation writes | Assert PATCH body never contains `travel_mode`, regardless of local value. |
| 16 | No remote null write | Assert no `travel_mode: null` and no empty/sentinel substitute in request body. |
| 17 | No persistent clearing | No clear affordance; remote existing value may reappear after a fetch and is not described as cleared. |
| 18 | Unconfirmed remains unconfirmed | Fetch/create/update snapshots remain false; no CARS preference evidence is enabled. |
| 19 | Existing profile regressions | Authenticated owner filter, non-transport fields, creation defaults, validation, categories/coordinates/group values, and current error behavior regressions remain valid. |

## 6. Regression and compatibility risks

1. **Nullable model callers:** Constructor changes affect direct callers, especially the trip adapter. Update only type handling; keep explicit itinerary choices and transfer metadata untouched.
2. **Lossy serialization:** `toJson()` currently includes `travel_mode`. A service payload must explicitly remove or omit that key. Do not rely on a nullable value serializing safely.
3. **Historical values and validation:** The current form allow-lists its saved mode so unsupported values can be preserved. Model validation must not make an unrelated edit impossible merely because an existing mode is now unknown/inactive. New selection remains disabled, so this slice need not accept a new unsupported value.
4. **Service error handling:** Current validation/auth errors are distinct, while update network/PostgREST errors propagate and the page presents a generic message. The implementation should preserve typed validation/auth errors and add explicit request/storage categories without swallowing the failure.
5. **Snapshot semantics:** The page changes `_snapshot` only after success; retain this behavior. If the server returns the unchanged `travel_mode`, display that exact value after unrelated updates.
6. **Server default:** `createIfMissing()` inserts only `user_id`; a database default may create a travel mode. The app must not label this default as tourist-selected or confirmed. Changing the default requires separate schema authorization.
7. **Nullability versus clearing:** Local null is a data representation only. It cannot be exposed as a clear action or transmitted remotely under this scope.
8. **Catalog eligibility versus availability:** Active/profile-capable means eligible for a future profile choice only; it says nothing about route/service availability.
9. **Trip adapter precedence:** Service snapshots remain unconfirmed, so production adapter currently returns the trip unchanged. Preserve this fail-closed boundary and all existing precedence tests.
10. **Worktree isolation:** Existing CARS source/test modifications and untracked Task documentation/catalog/manuscript files are present. Do not overwrite, reset, stage, or include them in a Task 38 implementation.

## 7. Rollback plan

If a separately authorized implementation is rejected or regresses:

1. Revert only the reviewed Task 38 patch hunks in the authorized profile model, service, preferences screen, adapter, and tests.
2. Use a saved pre-change patch or file-level diff to restore those exact paths; do not use a repository-wide reset or checkout.
3. Preserve Task 35 `transport_catalog.dart` and `test/transport_catalog_test.dart` unless the separate authorization explicitly includes an additive eligibility helper. If included, revert only that helper and its tests, not the catalog implementation.
4. Leave unrelated CARS modifications, prior Task documents, manuscript files, Hive data, and all other working-tree changes untouched.
5. Re-run only the acceptance tests authorized by the implementation task, then inspect the exact diff and `git status`; do not stage, commit, or push unless separately directed.

No remote data rollback is expected because this scope sends no transportation writes, nulls, or clears. Other unrelated profile fields remain governed by existing service behavior.

## 8. Excluded work

- Any remote `travel_mode` write, including canonical IDs, old values, or aliases.
- Remote null, persistent preference clearing, and database default changes.
- SQL, migrations, schema changes, Supabase/live database access, or production configuration.
- Hive serialization/data, itinerary or commitment models, per-leg selection, manual/circuit planning, or MO-GA.
- CARS models, scoring, evidence, or providers.
- Dependency changes and manuscript edits.
- New durable confirmation behavior; preferences remain unconfirmed.

## 9. Final authorization recommendation

**Verdict: B. Ready for owner authorization with conditions.**

The existing owner decisions are sufficient to define a safe, bounded profile-only implementation without another decision round. Before coding begins, the owner must issue a separate authorization that names the bounded file/test scope in Section 4 and explicitly retains these limits:

1. No remote transportation preference writes, no remote null, and no clearing.
2. Every unrelated profile update omits `travel_mode` and preserves its raw server value.
3. New transportation selection remains unavailable; existing preference is read-only and visibly unconfirmed.
4. The current authentication/ownership filter and failed-update snapshot behavior remain intact.
5. No Hive, itinerary, manual/circuit, CARS, MO-GA, database, Supabase, dependency, or manuscript work.

This is a recommendation to proceed to an owner authorization decision, **not** coding authorization. No implementation was started.

### Validation record

- Repository source, relevant tests, Task 36A selections, and Task 37A restrictions inspected read-only.
- No tests, analyzer, or build run.
- `git diff --check`: passed with no whitespace errors. A trailing-whitespace scan of this new document also passed. Git emitted line-ending notices for unrelated pre-existing CARS files only.
- No source, test, SQL, migration, Hive, database, Supabase, CARS/MO-GA, or manuscript changes made.
- Existing working-tree changes preserved; nothing staged, committed, or pushed.
