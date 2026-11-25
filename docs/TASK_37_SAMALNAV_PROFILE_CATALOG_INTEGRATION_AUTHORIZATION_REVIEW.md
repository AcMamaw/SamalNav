# Task 37 â€” SAMAL NAV Profile Catalog Integration Authorization Review

**Project:** SAMAL NAV
**Type:** Pre-implementation authorization review
**Basis:** Tasks 33A, 34, 35, 36, and the authoritative Task 36A final owner decision summary
**Review date:** 26 November 2026 (Asia/Manila)
**Implementation authorization:** **Not granted.**

## 1. Executive summary

The Task 36A owner selections provide a clear profile preference direction: nullable locally; exact legacy decoding and preservation; catalog-capability filtering; unconfirmed status until durable confirmation exists; strict preference precedence; and validation without substitution. The current Flutter profile model, service, and screen do not implement that contract. The catalog is not currently consumed by these paths.

The largest release dependency is the remote boundary. The existing service updates the `tourist_details.travel_mode` field, but this review did not inspect any deployed schema and is prohibited from doing so. Task 36A explicitly defers remote null writes and clearing. Acceptance of new canonical IDs through the existing field is also unverified. The app has no identified local profile preference store that could make a local null or newly selected catalog value persist independently. Therefore coding a working profile integration without either target-specific compatibility evidence or an explicitly non-persistent prototype risks a broken save, silent loss of a clear, or a false success message.

**Final verdict: C â€” Not ready for authorization.** Resolve the remote write/clear behavior and the model's lossless representation first. This is a readiness recommendation only; it does not grant implementation or database authorization.

## 2. Existing profile architecture

Read-only inspection covered the current profile model/service/screen/adapter, the local transportation catalog, related profile tests, the Task 36A summary, and Git status.

| Component                                                    | Verified current behavior                                                                                                                                                                                | Required compatibility change                                                                                                                                                                                             |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/models/tourist_planning_profile.dart`                   | `travelMode` is required `String`; `fromJson` rejects null/missing/empty `travel_mode`; `toJson` writes the value; validation compares against a caller-provided nonempty supported-mode set.            | Represent local null; distinguish invalid empty/new values from unknown historical strings; provide lossless alias/unknown handling.                                                                                      |
| `lib/services/tourist_planning_profile_service.dart`         | Uses remote `tourist_details`; creates by inserting only `user_id`; updates the full profile `toJson()` payload; fetch/create/update snapshots set `preferencesConfirmed: false`.                        | Preserve existing remote field and raw value; do not send null; do not claim local clear persisted remotely; distinguish validation from storage errors. Canonical ID acceptance must be verified before enabling writes. |
| `lib/screens/tourist_screens/planning_preferences_page.dart` | Hard-coded five strings; no null choice; save falls back to current required mode; unsupported saved value is shown as a preservation item; review dialog says preferences remain unconfirmed.           | Build options from active catalog entries with profile capability; retain unknown/inactive values visibly; avoid a persistent clear control until remote behavior is resolved.                                            |
| `lib/services/tourist_planning_profile_trip_adapter.dart`    | Converts only five legacy strings to `PreferredTravelMode`; applies values only from confirmed snapshots and only when trip mode is unset; current service never returns confirmed snapshots.            | If the profile model changes to nullable, make the adapter type-safe without adding itinerary integration or coercing new catalog IDs. Explicit trip selections remain untouched.                                         |
| `lib/models/transport_catalog.dart`                          | Local `TransportCatalog.initial` has version 1 and twelve stable IDs, exact aliases, active status, category, and workflow flags.                                                                        | Selector must test both `isActive` and `workflowCapabilities.profilePreference`; `selectableMode()` alone is insufficient because it checks active status only.                                                           |
| Existing profile tests                                       | `test/tourist_planning_profile_service_test.dart`, `test/planning_preferences_page_test.dart`, and `test/system_generated_planning_page_test.dart` cover legacy profile/service/UI and adapter behavior. | Extend them for null, aliases, canonical IDs, unknown/inactive values, save failures, capability filtering, and precedence regressions. No tests were run for this review.                                                |

The repository already contains unrelated CARS modifications and numerous untracked documents/catalog artifacts. Those files were preserved. No working-tree cleanup was performed.

## 3. Task 36A decision traceability

| Decision | Owner-selected direction                                                      | Task 37 handling                                                                                                                                                                                                     |
| -------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D36A-01  | Option C â€” Nullable with Compatibility Protection                           | Local model may represent null; remote null write and clearing remain deferred. Do not treat local null as persisted remotely.                                                                                       |
| D36A-02  | Option A â€” Exact Dual-Read Compatibility                                    | Read canonical IDs and approved exact aliases; preserve raw value on unrelated updates; explicit selection writes canonical ID when remote compatibility permits; unknown values are preserved without substitution. |
| D36A-03  | Option C â€” Remain Unconfirmed Until a Durable Confirmation Mechanism Exists | Fetch/create/save/update do not imply confirmation; keep CARS fail-closed.                                                                                                                                           |
| D36A-04  | Option A â€” Strict Precedence Hierarchy                                      | Fixed commitments > explicit leg selections > explicit trip-wide preferences > profile preferences > system-generated suggestions. Task 37 does not implement itinerary behavior.                                    |
| D36A-05  | Option A â€” Strict Capability-Based Selection                                | New profile choice requires active mode and `profilePreference == true`; unknown/inactive historical values are display-only.                                                                                        |
| D36A-06  | Option A â€” Local Nullable Model with Existing Remote Contract               | Keep remote `travel_mode`; no remote null write, schema change, or migration.                                                                                                                                        |
| D36A-07  | Option A â€” Strict Validation with Preservation                              | Accept local null; reject empty/invalid new inputs; preserve unknown/inactive history; retain last saved data after failed updates; do not claim confirmation.                                                       |

These owner selections are architectural requirements. They are not implementation authorization.

## 4. Exact proposed file modifications

The scope below is the smallest plausible profile slice, conditional on the dependencies in Sections 5 and 11. No file is modified by this review.

| File                                                         | Current behavior                                                                                                     | Proposed behavior                                                                                                                                                                                                                                                                                                      | Reason / dependencies                                                                                                                                            | Risks and tests                                                                                                                                                                                                                                                                             |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/models/tourist_planning_profile.dart`                   | Required non-null string; raw string round-trips today; no catalog decode.                                           | Make the local preference nullable. Keep a lossless raw string for recognized aliases and unknown historical IDs. Validate new selections against canonical catalog entries/capability while allowing preservation of existing historical values.                                                                      | D36A-01/02/05/07. Must distinguish â€œunchangedâ€ from explicit local null; remote null remains prohibited.                                                      | Risk of canonicalizing or dropping raw aliases during parse/serialization. Add model/service tests for null, empty, raw legacy, canonical, unknown, inactive, and malformed input.                                                                                                          |
| `lib/services/tourist_planning_profile_service.dart`         | Whole-field update uses `profile.toJson()` and always reports false confirmation.                                    | Keep remote field name and false confirmation. Ensure a local null does not generate remote `travel_mode: null`; preserve the existing remote value on unrelated updates. Do not claim a remote clear. Gate canonical writes until accepted-value compatibility is known.                                              | D36A-03/06/07. Requires an explicit update payload rule; current whole-object `toJson()` cannot safely represent local null as a remote update without a policy. | Risk: after reload, remote old preference may reappear because remote clear is deferred. Service tests must verify null omission, unchanged raw value, failed-write preservation, and no false success.                                                                                     |
| `lib/screens/tourist_screens/planning_preferences_page.dart` | Five hard-coded values, no unset option, save falls back to current value.                                           | Generate choices from catalog entries where active and profile capability are true. Keep unknown/inactive saved values visible and retained. Do not present catalog entries as available services. A persistent clear action must remain unavailable until the remote limitation has an honest user-facing resolution. | D36A-01/02/05/07. Dynamic catalog filtering replaces, rather than permanently hard-codes, the initial twelve choices.                                            | Risk of dropdown assertion/value mismatch and accidental loss of unsupported stored value. Widget tests for all current catalog entries, capability filtering, historical display, selection, failed save, and null UX.                                                                     |
| `lib/services/tourist_planning_profile_trip_adapter.dart`    | Non-null string switch maps five legacy values; returns unchanged for unconfirmed snapshot; explicit trip mode wins. | Only make nullable input safe if the model type change requires it. Preserve the existing confirmed-only behavior and trip selection. Do not map `jeepney`, `ferry`, or other unrepresentable IDs into an old enum. No leg logic.                                                                                      | D36A-04 and compile compatibility. Current profile service always reports false.                                                                                 | Risk of changing downstream planning behavior or implying new catalog modes are itinerary-supported. Regression tests must prove explicit trip value wins and unsupported profile IDs are not substituted. This file may be excluded if a compatibility accessor avoids a signature change. |

No additional application file is required for the bounded profile slice based on current inspection. Candidate tests are listed in Section 8. Adding a local persistence layer, remote schema, itinerary leg model, or availability provider is outside this task.

## 5. Data compatibility design

### 5.1 Identifier and raw-value rules

The catalog's canonical ID for public transportation is `public_transportation`. Its only currently approved aliases are the exact strings `public transportation` and `publicTransportation`. The codec does not trim or case-fold. Existing `walking`, `bicycle`, `motorcycle`, and `car` strings match canonical IDs. The other initial catalog IDs are `jeepney`, `tricycle`, `multicab`, `van`, `bus`, `ferry`, and `boat`.

For the proposed profile slice:

1. Decode exact canonical IDs and exact approved aliases for display/validation.
2. Preserve the original raw string separately; do not canonicalize it just because another profile field was edited.
3. When the tourist explicitly selects a catalog option, use the canonical ID in the local candidate.
4. Preserve unknown and inactive historical values in the model and show them as historical/unavailable choices; do not include them in the list of new choices and do not substitute a mode.
5. Empty string is not equivalent to null. Reject it as a new value and surface malformed stored values as a field/data error without a replacement.
6. Catalog version, capability, category, and label are not route availability evidence.

### 5.2 Local null versus remote behavior

The selected contract allows local null but explicitly defers remote null writes and remote clearing. The current profile service stores the profile remotely and has no local profile cache. Consequently:

- The model can represent local null and parse a nullable local JSON fixture.
- The service must not send `travel_mode: null` to remote storage.
- A remote update that omits `travel_mode` leaves the remote value unchanged; a subsequent fetch can return that old non-null preference.
- The UI must not claim that a remote preference was cleared when the service only omitted the field.
- Before an integrated selector writes canonical IDs, accepted remote values must be established from approved schema evidence or the selection write must remain disabled. The review does not assume the text column is unconstrained.
- No remote read, write, migration, or schema inspection is authorized in this review.

This means local nullability is contract-ready but persistent remote clearing is not. This gap is the principal reason the proposed profile integration is not yet ready for implementation authorization.

## 6. Profile selector behavior

Selector choices must be derived from the catalog at runtime, not coded as a permanent twelve-item list. The inclusion predicate is exactly:

```text
mode.isActive == true && mode.workflowCapabilities.profilePreference == true
```

Current initial catalog entries satisfying this predicate are:

`walking`, `bicycle`, `motorcycle`, `car`, `public_transportation`, `jeepney`, `tricycle`, `multicab`, `van`, `bus`, `ferry`, and `boat`.

The labels should come from each mode's catalog label key. A known inactive saved mode remains visible with an inactive/historical marker; an unknown saved identifier uses a preserved label snapshot when available, otherwise the raw identifier. Neither case is a new selectable option. The selector must not imply a bus, ferry, or boat operator or that a service runs for the tourist's route/date. Profile values remain preferences, not trip or leg instructions.

## 7. Confirmation and error-handling rules

- `preferencesConfirmed` remains false on fetch, create, and update until a durable confirmation mechanism is separately specified and implemented.
- A selection, review dialog, save attempt, successful profile write, database default, or nonempty value is not confirmation.
- CARS remains fail-closed for preference-derived evidence when the snapshot is unconfirmed. Do not alter CARS in this slice.
- Validation failures are field-specific and occur before service update. Invalid new IDs, empty strings, malformed types, and inactive/unsupported new selections are rejected.
- Existing unknown/inactive raw values are preserved when the user is editing unrelated profile fields.
- Storage/network errors are distinct from validation errors. Preserve the previous saved snapshot and the user's unsaved form selection; show the failure and do not display a success state.
- If a canonical ID is rejected by remote storage, retain the previously saved value and report the storage failure. Never retry with another transportation mode.
- A local null candidate cannot be sent remotely as null. If the UI allows a local clear for the current session, it must explicitly explain that the remote saved value remains unchanged and may return after reload; otherwise omit the clear affordance until that behavior is resolved.

## 8. Acceptance-test matrix

No tests or builds were run for this review. The following are future tests for a separately authorized implementation.

| ID  | Test                                     | Acceptance criteria                                                                                                                                |
| --- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| T1  | Nullable profile creation                | Local profile object can represent null without generating a default mode; remote create still follows the existing server contract.               |
| T2  | Null serialization/deserialization       | Local JSON null round-trips; null is omitted from the remote update payload; omitted patch key preserves remote value; empty string is rejected.   |
| T3  | Empty-string rejection                   | Empty string is rejected as a new preference and never normalized to null.                                                                         |
| T4  | Existing five-value compatibility        | `walking`, `bicycle`, `motorcycle`, `car`, and `public transportation` remain readable and are not lost on unrelated edits.                        |
| T5  | Approved alias decoding                  | Exact `public transportation` and `publicTransportation` resolve to `public_transportation`; near-miss casing/whitespace is not silently accepted. |
| T6  | Canonical identifier encoding            | Explicit selection produces its canonical ID locally; remote submission is enabled only after accepted-value compatibility is established.         |
| T7  | Raw legacy preservation                  | An unrelated profile update preserves the original alias/raw value byte-for-byte.                                                                  |
| T8  | Unknown identifier preservation          | Unknown identifier and historical label remain visible and round-trip without substitution.                                                        |
| T9  | Inactive mode preservation               | Known inactive value remains visible, is not offered as a new selection, and is not cleared/replaced automatically.                                |
| T10 | Catalog capability filtering             | Runtime selector includes only modes with active=true and profilePreference=true; changing either flag excludes the mode.                          |
| T11 | Explicit selection behavior              | A deliberate selection updates the candidate to the selected canonical ID; no automatic default or unrelated alias rewrite occurs.                 |
| T12 | Unconfirmed preference handling          | Fetch/create/update/save all continue to produce unconfirmed snapshots.                                                                            |
| T13 | CARS fail-closed compatibility           | Unconfirmed profile preference is not passed as confirmed CARS interest/activity evidence.                                                         |
| T14 | Profile update failure preservation      | Validation/storage failures keep previous saved data; the form retains the attempted selection; no false success or confirmation.                  |
| T15 | Existing profile regression              | Authentication ownership, create-if-missing, partial profile values, validation, and existing screen behavior remain covered.                      |
| T16 | Local/remote serialization compatibility | Local nullable representation is separate from remote payload; remote field remains `travel_mode`; null is never written.                          |
| T17 | No automatic transportation substitution | Unknown, inactive, unmappable, or remote-rejected values are never mapped to another mode.                                                         |
| T18 | Fixed commitment precedence              | Any later adapter use cannot change a fixed commitment's mode, endpoints, or schedule from profile preference.                                     |
| T19 | Individual leg precedence                | Any later suggestion cannot overwrite an explicit leg selection.                                                                                   |
| T20 | Trip-wide preference precedence          | A profile preference cannot overwrite an explicit trip-wide preference.                                                                            |
| T21 | Profile fallback precedence              | Profile can only be a lower-priority suggestion where no higher-priority selection exists and the separately implemented flow allows it.           |
| T22 | Generated suggestion precedence          | System-generated suggestion cannot overwrite fixed, leg, trip-wide, or profile selection.                                                          |

Existing test files to extend: `test/tourist_planning_profile_service_test.dart`, `test/planning_preferences_page_test.dart`, and `test/system_generated_planning_page_test.dart`. A dedicated model test may be added if authorized. Do not execute these tests as part of this review.

## 9. Risks and rollback procedure

### Risks

- The current remote value constraint may reject canonical catalog IDs; the actual deployed constraint is unknown.
- The remote field may be non-nullable or apply a default; this review did not verify its deployed behavior.
- Since remote clearing is deferred and there is no local profile cache, an apparent clear could revert on reload unless the UI prevents or clearly explains it.
- A model that canonicalizes on parse could rewrite aliases/unknown values during an unrelated update.
- Displaying all active capability-approved modes can imply service availability unless the UI labels the selection as preference only.
- Changing the profile model to nullable may require a null-safe adapter signature adjustment; broadening that adapter could unintentionally change itinerary behavior.
- Confirmation remains permanently false through the current service; do not enable CARS preference scoring as part of this work.

### Rollback

If a separately authorized implementation fails acceptance, revert only the authorized profile-slice changes in the model, service, screen, adapter, and newly authorized tests. Do not revert or reset pre-existing working-tree changes. Do not modify remote data during rollback. Because remote null writes are prohibited in this scope, rollback must not require data repair; if a canonical value was written before compatibility was established, stop writes and request a separate data recovery authorization rather than changing records without approval.

## 10. Excluded work

This review grants no authorization for itinerary model or per-leg integration, fixed commitment implementation, Hive changes/migrations/data access, MO-GA, CARS, circuit planning, database/schema changes, SQL, Supabase operations, manuscript edits, deployment, staging, committing, or pushing. The precedence hierarchy is recorded for later integration only.

## 11. Authorization checklist and remaining blockers

Before a separate implementation authorization review can approve a usable profile integration:

1. Establish through approved, target-specific evidence whether the existing remote `travel_mode` field accepts canonical catalog IDs and how it handles null. This review did not and must not inspect Supabase.
2. Decide how profile clearing behaves in the UI while remote null writes remain deferred: unavailable, local-session-only with explicit warning, or postponed until remote compatibility/authorization.
3. Define an update payload that preserves raw legacy/unknown values on unrelated edits and never sends remote null.
4. Confirm profile service failure semantics and canonical write gate using mocked tests; no database test is part of this slice.
5. Preserve D36A-03's unconfirmed status. Durable confirmation and CARS scoring changes require separate authorization.
6. Keep the profile-to-trip adapter from coercing the seven catalog-only values into the existing five-mode enum. Any future itinerary/catalog integration needs a separate task and authorization.

The first blocker is essential: without a verified canonical write path, the selector may not be able to persist a user's selection. Without a user-approved remote-clear experience, local null can mislead the tourist about stored state.

## 12. Final recommendation

**Verdict: C â€” Not ready for authorization.**

The Task 36A decisions are complete, but implementation of the profile selector is not yet safely authorizable as a functional persisted feature. The remote `travel_mode` constraints and canonical-ID acceptance are unknown, while remote null writes/clearing are explicitly deferred. A local-only implementation would either fail to persist a newly selected mode or misrepresent clearing unless its non-persistence behavior is resolved. The model's lossless alias/unknown strategy and null-safe adapter boundary also need to be specified in the bounded implementation request.

Once the remote compatibility and clear UX conditions in Section 11 are closed, prepare a new narrow authorization request for the model/service/screen profile slice, plus only the adapter's null-safe compatibility change if required. Include the acceptance tests in Section 8 and keep all excluded work out of scope.

**Required statement:** â€œTask 37 is an authorization review only. Profile catalog integration coding has not been authorized.â€

**Closeout:** Read-only repository inspection only. Git status was inspected and existing changes were preserved. No tests/builds were run; no application files, remote data, SQL, Hive records, Supabase state, or manuscript were modified or accessed. No implementation authorization is granted.
