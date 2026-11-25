# Task 36A â€” SAMAL NAV Profile Preference Contract Closure and Acceptance Matrix

**Project:** SAMAL NAV
**Reference:** Tasks 33A, 34, 35, and 36
**Task type:** Technical contract closure
**Status:** Owner decisions D36A-01 through D36A-07 are consolidated below. Technical and remote compatibility dependencies remain.
**Implementation authorization:** **Not granted.**

## 1. Purpose and evidence boundary

This document consolidates the seven owner-selected architectural directions for integrating the local Task 35 transportation catalog into tourist profile preferences. It records current behavior, retained options/recommendations, implementation requirements, and remaining technical dependencies.

The source basis is `docs/TASK_36_SAMALNAV_TRANSPORTATION_CATALOG_INTEGRATION_COMPATIBILITY_REVIEW.md` and read-only inspection of the profile model, service, screen, trip adapter, catalog model, CARS input preparer, and relevant tests. No tests, analyzer, build, Hive data, remote database, or Supabase project was accessed for this task. Catalog membership is not evidence of route, operator, schedule, fare, travel time, or service availability.

## 2. Existing architecture findings

| Area | Verified repository behavior | Compatibility consequence |
|---|---|---|
| Profile model | `lib/models/tourist_planning_profile.dart` declares `travelMode` as a required `String`; `fromJson` requires a nonempty `travel_mode`; `toJson` emits that field; validation requires membership in a caller-provided nonempty set. | Null cannot currently be represented or validated. An empty string is rejected during parsing and not a valid unset representation. |
| Profile service | `lib/services/tourist_planning_profile_service.dart` reads, inserts, and updates `tourist_details`. Create omits profile fields for database defaults. Fetch/create/update snapshots all set `preferencesConfirmed: false`. Update sends the model's `toJson()` fields. | The app does not establish whether a deployed `travel_mode` column accepts null or canonical catalog IDs. Confirmation is not persisted by the current client contract. |
| Profile screen | `lib/screens/tourist_screens/planning_preferences_page.dart` owns a five-string list (`walking`, `bicycle`, `motorcycle`, `car`, `public transportation`). The state can be null, but the control has no unset choice and save uses the current required value as fallback. A saved unsupported string is shown and allow-listed for preservation. | The profile UI cannot clear the current preference and does not expose the seven additional catalog modes. Its â€œConfirm and saveâ€ dialog is not durable preference confirmation. |
| Local catalog | `lib/models/transport_catalog.dart` defines 12 active entries, stable IDs, categories, exact aliases, version fields, and independent workflow capability flags. Exact aliases are `public transportation` and `publicTransportation` for `public_transportation`; no trimming or case folding occurs. Unknown IDs are represented with their raw identifier and optional label; known inactive entries still resolve to a definition. | The catalog supports exact decoding and future filtering but is not currently imported by the profile model, service, or screen. |
| Catalog selection API | `selectableMode()` and `TransportModeReference.canSelectForNewUse` check support and active state only; they do not check a workflow capability. | The profile selector must separately require `isActive == true` and `workflowCapabilities.profilePreference == true`. |
| Itinerary adapter | `lib/services/tourist_planning_profile_trip_adapter.dart` recognizes only the five legacy profile strings as the old `PreferredTravelMode` enum. It applies confirmed profile data only when the corresponding trip field is unset and keeps an explicit trip value. | It cannot represent the other seven catalog modes; no unknown or unmappable value should be coerced into an enum value. |
| CARS | `lib/algorithms/cars_assessment_input_preparer.dart` checks `preferencesConfirmed`; unconfirmed preferences do not produce interest/activity score evidence. The profile service currently always returns false. | A saved or selected transportation preference cannot be treated as CARS confirmation or scoring evidence. Preserve fail-closed behavior. |
| Tests | Existing tests cover profile service snapshots, the five-option screen, and confirmed/unconfirmed adapter behavior. | They do not cover nullable profile preference, catalog capability filtering, canonical catalog IDs, unknown/inactive catalog values, or the additional seven choices. No tests were run here. |

### 2.1 Initial catalog entries to account for

The catalog's current initial entries and profile preference capability are:

| Stable ID | Display concept | Category ID | Active now | `profilePreference` now |
|---|---|---|---:|---:|
| `walking` | Walking | `land_non_motorized` | Yes | Yes |
| `bicycle` | Bicycle | `land_non_motorized` | Yes | Yes |
| `motorcycle` | Motorcycle | `land_motorized` | Yes | Yes |
| `car` | Car | `land_motorized` | Yes | Yes |
| `public_transportation` | Public transportation | `public_transport_local` | Yes | Yes |
| `jeepney` | Jeepney | `public_transport_local` | Yes | Yes |
| `tricycle` | Tricycle | `public_transport_local` | Yes | Yes |
| `multicab` | Multicab | `public_transport_local` | Yes | Yes |
| `van` | Van | `public_transport_local` | Yes | Yes |
| `bus` | Bus | `public_transport_local` | Yes | Yes |
| `ferry` | Ferry | `water_transfer` | Yes | Yes |
| `boat` | Boat | `water_transfer` | Yes | Yes |

These are catalog display concepts, not claims that any service is available or that a profile preference creates an itinerary leg. Ferry and boat as profile preferences do not by themselves record fixed transfer endpoints or schedules.

## 3. D36A-01 â€” Nullable profile preference

**Owner selection: Option C — Nullable with Compatibility Protection.** Local profile preference supports null. Remote null writes and clearing remain deferred until remote compatibility is verified and separately authorized. This selection confirms the compatibility-protection recommendation above.

**Original decision question (resolved by the owner selection above):** May a tourist leave the profile transportation preference unset, and what persistence behavior is approved?

| Option | Behavior |
|---|---|
| A | Preference is optional. Model and selector support null; explicit clear writes JSON `travel_mode: null` only where the approved storage contract accepts it. No default is created. |
| B | Preference remains required. Existing value remains until replaced; UI does not offer clearing. |
| C | Preference is optional locally, but remote writes of null are deferred until schema compatibility is confirmed; old values are preserved meanwhile and clear is unavailable or reported as unsupported. |

**Original recommendation (retained for traceability): C as the transition policy, followed by A once nullability is verified and separately approved.** This avoids pretending that an unseen remote schema accepts null while allowing the client contract to be designed as nullable. It must not silently write an empty string, sentinel identifier, or default mode to mean â€œnone.â€

**Proposed contract:** local profile preference type is nullable. `null` means â€œno preferenceâ€; `''` is invalid. A missing JSON key and explicit JSON null must be distinguished if partial updates are supported. For full profile serialization, emit `travel_mode: null` only after target compatibility is verified. Existing non-null values remain unchanged on load and unrelated saves. A default transportation mode is not permitted unless the owner separately approves one; none is proposed.

**Decision status:** Owner selection received. Remaining items below are implementation or compatibility dependencies, not pending owner choice.

## 4. D36A-02 â€” Legacy value compatibility

**Owner selection: Option A — Exact Dual-Read Compatibility.** Decode canonical identifiers and explicitly approved aliases; preserve original raw values during unrelated updates; write canonical identifiers upon explicit selection; preserve unknown identifiers without substitution.

**Original decision question (resolved by the owner selection above):** What exact values should be accepted and when should they be canonicalized on write?

| Option | Behavior |
|---|---|
| A | Exact, dual-read compatibility: decode canonical IDs and the two catalog-approved public-transport aliases; preserve original raw value until an explicit transportation selection or clear; new selections write canonical IDs. Unknown values are preserved verbatim. |
| B | Read legacy spellings and immediately canonicalize every recognized value on any profile save. |
| C | Accept canonical IDs only; all legacy values require manual repair. |

**Original recommendation (retained for traceability): A.** It retains recoverability and prevents unrelated edits from rewriting a historical value. The catalog's `decodeMode` currently maps exact canonical IDs and aliases; it does not trim, case-fold, or expand aliases. Do not infer aliases beyond the catalog list.

**Proposed exact behavior:**

| Stored value | Read interpretation | New write behavior |
|---|---|---|
| `walking`, `bicycle`, `motorcycle`, `car` | Exact canonical ID; recognized | Explicit user selection writes same canonical ID. Unrelated save preserves raw value. |
| `public_transportation` | Canonical ID for public transportation | Explicit selection writes `public_transportation`. |
| `public transportation` | Exact approved legacy alias resolving to `public_transportation` | Preserve raw spelling on unrelated save; explicit reselection writes canonical ID. |
| `publicTransportation` | Exact approved legacy alias resolving to `public_transportation` | Preserve raw spelling on unrelated save; explicit reselection writes canonical ID. |
| Other known catalog IDs, including `jeepney`, `tricycle`, `multicab`, `van`, `bus`, `ferry`, `boat` | Recognized canonical IDs | Explicit selection writes the same stable ID. |
| Unknown nonempty identifier | Preserve exact raw identifier and any saved historical label; mark unresolved; do not substitute or offer as a new choice | Unrelated save preserves it; explicit user selection writes the chosen canonical ID; explicit clear writes null only if approved. |
| Known inactive identifier | Preserve ID/label and show as historical/inactive; do not offer as a new choice | Unrelated save preserves it; replacing or clearing requires deliberate user action. |
| Null | No preference under the owner-selected nullable local contract | Represent locally as null; remote null writes and clearing remain deferred. |
| Empty string or malformed type | Invalid input/data; surface a validation or load error, do not reinterpret as null | Never emit. |

To implement preservation safely, the future profile representation should retain both the decoded reference and original raw identifier (or an equivalent lossless value object). Canonicalizing during parse and then serializing during an unrelated profile update would lose the original alias/unknown raw value.

**Decision status:** Owner selection received. Remaining items below are implementation or compatibility dependencies, not pending owner choice.

## 5. D36A-03 â€” Profile preference confirmation

**Owner selection: Option C — Remain Unconfirmed Until a Durable Confirmation Mechanism Exists.** Saving, creating, updating, or fetching preferences does not establish confirmation. CARS must not treat unconfirmed preferences as confirmed recommendation evidence.

**Original decision question (resolved by the owner selection above):** What is confirmation, and how does it relate to saving a preference?

| Option | Behavior |
|---|---|
| A | Selection or save is confirmation. Persist the value and mark it confirmed together. |
| B | Persistence and confirmation are separate. A distinct explicit confirmation action confirms the current preference set; any relevant edit clears confirmation. |
| C | No durable confirmation is available yet; all loaded and saved preferences remain unconfirmed until an authorized persistence contract exists. |

**Original recommendation (retained for traceability): C now; use B as the future contract if/when confirmation fields and reset behavior are approved and supported.** The current service reports all profiles unconfirmed, and the current dialog does not persist confirmation. Do not infer durable confirmation from selection, save, nonempty defaults, or the dialog acknowledgment.

**Proposed current behavior:** continue setting `preferencesConfirmed` to false at fetch/create/update boundaries. CARS continues to exclude unconfirmed preference-derived interest/activity evidence. A future explicit confirmation operation must be separate from profile persistence, version or identify the confirmed preference set, and define reset-on-edit; it requires a compatible persistence contract and authorization. Existing saved values gain no retroactive confirmation.

**Decision status:** Owner selection received. Remaining items below are implementation or compatibility dependencies, not pending owner choice.

## 6. D36A-04 â€” Profile and itinerary precedence

**Owner selection: Option A — Strict Precedence Hierarchy.** Fixed commitments > explicit individual leg selections > explicit trip-wide transportation preferences > profile transportation preferences > system-generated suggestions. Higher-priority selections must not be silently overwritten by lower-priority preferences.

**Original decision question (resolved by the owner selection above):** How should profile suggestion, trip-wide preference, per-leg selection, and fixed commitments relate?

| Option | Behavior |
|---|---|
| A | Profile is suggestion-only. Existing trip-wide and leg selections are preserved; per-leg selection governs its leg; fixed commitments remain immutable to defaults. |
| B | Confirmed profile preference automatically fills any unset trip and leg modes. Existing explicit values still win. |
| C | Profile preference is never applied to itinerary state; tourist chooses trip/leg modes explicitly. |

**Original recommendation (retained for traceability): A**, consistent with D31A-02's owner-selected rule that profile preferences may be suggestions but cannot override explicit trip/leg choices. Existing `TouristPlanningProfileTripAdapter` currently fills a missing trip-wide mode only from confirmed preferences. That behavior must be reviewed when moving to catalog IDs and per-leg fields; it must not coerce unmappable catalog values.

**Consolidated precedence rule:** Fixed commitment mode/endpoints/schedule are protected; explicit leg choice outranks trip-wide preference; trip-wide preference outranks profile preference; profile preference outranks generated suggestions. Lower-priority values may only fill unset choices where the workflow allows suggestions and may never overwrite a higher-priority explicit choice. Unknown or inactive profile values are not substituted.

**Decision status:** Owner selection received. Remaining items below are implementation or compatibility dependencies, not pending owner choice.

## 7. D36A-05 â€” Catalog-based profile selection

**Owner selection: Option A — Strict Capability-Based Selection.** A new profile choice requires both `isActive == true` and `workflowCapabilities.profilePreference == true`. Unknown and inactive historical values remain preserved but are not new choices.

**Original decision question (resolved by the owner selection above):** Which catalog entries can the profile selector offer?

| Option | Behavior |
|---|---|
| A | Offer a mode only when it is active and its `profilePreference` capability is true. Preserve unknown/inactive saved references visibly, but never present them as new choices. |
| B | Offer every active mode regardless of workflow capability. |
| C | Keep the existing five options until all itinerary modes are integrated. |

**Original recommendation (retained for traceability): A.** It applies the catalog's independent workflow capability instead of treating activity as universal permission. A picker must not call `selectableMode()` alone because that helper checks activity only.

**Proposed rule:** `isActive == true && workflowCapabilities.profilePreference == true`. Under the current catalog initial state, all twelve entries in Section 2.1 are offered. If a future catalog version changes active/capability values, the selector filters by both values at runtime. Unknown and inactive saved values are displayed as retained historical values, are not silently cleared, and are not included in selectable options. Display names should resolve from catalog localization keys; where no current definition exists, use the saved label snapshot, then raw identifier as a final fallback. Display text must not be mistaken for service availability.

**Decision status:** Owner selection received. Remaining items below are implementation or compatibility dependencies, not pending owner choice.

## 8. D36A-06 â€” Local and remote data compatibility

**Owner selection: Option A — Local Nullable Model with Existing Remote Contract.** Support local nullability while preserving the existing remote `travel_mode` field. Defer remote null writes, schema changes, and migrations until verified and separately authorized.

**Original decision question (resolved by the owner selection above):** How should nullable/catalog values be introduced without assuming remote schema behavior?

| Option | Behavior |
|---|---|
| A | Local model and JSON codec become nullable/catalog-aware, while remote writes remain gated until schema evidence and separate database authorization establish nullability and accepted values. |
| B | Change client writes immediately to canonical IDs and null, assuming the existing `travel_mode` column accepts them. |
| C | Keep both model and service strictly legacy/non-null until a separate remote schema change is completed. |

**Original recommendation (retained for traceability): A**, with a strict boundary: the JSON key remains `travel_mode`; nullable serialization emits JSON null only after verified schema acceptance. Canonical IDs are ordinary strings but acceptance, constraints, triggers, and RLS behavior are not known. No live schema or Supabase project was accessed.

**Selected local/remote transition contract:**

1. Preserve the existing remote `travel_mode` field; do not add a remote field, schema change, or migration under this decision.
2. The local model may represent null, recognized canonical IDs, exact aliases, inactive IDs, and unknown raw values.
3. Do not send remote JSON null or claim remote clearing while that write is deferred. A local null value cannot be reported as remotely persisted.
4. Preserve raw historical values on unrelated updates. Explicit selection uses a canonical identifier through the existing field only when its acceptance is verified.
5. Before enabling remote null or canonical-ID writes, obtain approved target-specific schema evidence and separate authorization. Production authorization remains independent.

**Decision status:** Owner selection received. Target-specific schema compatibility remains unverified and requires separate authorization; this selection does not authorize remote access or schema changes.

## 9. D36A-07 â€” Validation and error handling

**Owner selection: Option A — Strict Validation with Preservation.** Accept null; reject empty strings as new values; accept canonical identifiers and approved aliases; preserve unknown/inactive historical values; reject invalid new values; preserve saved data after failed updates; keep preferences unconfirmed without durable confirmation evidence.

**Original decision question (resolved by the owner selection above):** What is the accepted behavior for each profile transport value and service failure?

| Input/state | Proposed validation and behavior |
|---|---|
| Null preference | Valid no-preference value in the local model under D36A-01/06; do not write remote null or claim remote clearing before separate verification/authorization. |
| Empty string | Invalid; never normalize to null. Show validation/data error and preserve source record for correction. |
| Valid canonical ID | Accept if it resolves to a catalog definition. For a new selection, additionally require active and profile capability true. |
| Approved legacy alias | Decode exact string to a known mode reference; preserve raw alias on unrelated update; explicit selection writes canonical ID. |
| Unknown nonempty ID | Preserve exact raw value and label snapshot; show unresolved state; do not treat as selectable, map to a different value, or infer availability. |
| Known inactive ID | Preserve and visibly mark inactive/historical; disallow a new selection; do not silently clear or replace. |
| Invalid identifier/type | Fail validation or parsing with a field-specific error. Do not substitute, trim, case-fold, or coerce. Retain original remote value for recovery where available. |
| Failed profile update | Keep the user's unsaved selection in the form, show an actionable save error, and leave the last successfully fetched/saved snapshot unchanged. Do not optimistically report persistence or confirmation. Retry only on an explicit user action. |
| Unconfirmed preference | Retain/display it, but do not send it as confirmed CARS evidence. Continue the existing fail-closed assessment behavior. |
| Canonical value rejected by remote contract | Surface the service error and keep the prior persisted value; do not fall back to a different mode. Disable that write path pending compatibility closure. |

**Options retained for traceability:** Option A is the owner-selected strict validation and preservation policy; Option B would reject unknown/inactive values on load/update; Option C would coerce unsupported values to a default. The selected Option A rejects invalid new inputs, while preserving unknown/inactive historical values already stored.

**Decision status:** Owner selection received. Remaining items below are implementation or compatibility dependencies, not pending owner choice.

## 10. Consolidated selected profile contract

The following consolidates owner-selected architectural direction. It is not implementation authorization or a statement about deployed remote schema:

```text
ProfileTransportPreference {
  modeId: String?              // null = no preference
  rawStoredIdentifier: String? // lossless legacy/unknown source value, if needed
  labelSnapshot: String?       // historical display context; not service evidence
  resolution: known | inactive | unknown | none
  catalogVersionAtSelection: int? // optional provenance, if approved
}
```

The implementation may use an existing `TransportModeReference` plus an explicit raw value rather than these exact field names. The key properties are nullable semantics, lossless read/preserve behavior, exact alias decoding, and explicit canonical writes only when the user selects a catalog entry. Do not persist the local `resolution` as remote truth unless a separate contract requires it.

**JSON boundary examples (proposed):**

```json
{"travel_mode": null}
```

```json
{"travel_mode": "public_transportation"}
```

Reading `{"travel_mode":"publicTransportation"}` resolves to `public_transportation` for display/logic while retaining the original raw value until explicit reselection. An unknown identifier is preserved exactly and never replaced by another mode. Local JSON null means no preference; remote null writes and clearing remain deferred. A missing key in a partial patch means unchanged, and an explicit local clear must not be reported as persisted remotely while remote null writes are disabled.

**Validation invariants:**

1. No default mode is inferred.
2. A new selection must resolve to a catalog definition that is active and has `profilePreference == true`.
3. A local clear is explicit and distinct from unchanged patch data; remote clearing remains disabled until separately verified and authorized.
4. Unknown/inactive existing values round-trip losslessly and are not selectable for new use.
5. Catalog ID, label, and capability do not imply service availability.
6. Profile preference does not become an itinerary mode unless a separately approved precedence flow applies it as a suggestion; explicit itinerary choices always remain intact.
7. Confirmation is independent of value persistence; unconfirmed values remain fail-closed for CARS.

## 11. Future acceptance-test matrix

No tests are to be executed during this task. The following are future tests after separate implementation authorization.

| ID | Test | Acceptance criteria |
|---|---|---|
| T1 | Nullable preference creation | Local profile represents no preference without fabricating a mode; remote profile creation continues under the existing remote contract. |
| T2 | Null serialization/deserialization | Local explicit JSON null round-trips as null; partial patch omission means unchanged; no remote null write occurs before compatibility authorization; empty string is rejected. |
| T3 | Existing five profile values | `walking`, `bicycle`, `motorcycle`, `car`, and `public transportation` remain readable; unrelated save preserves legacy raw spelling. |
| T4 | Exact alias decoding | Both `public transportation` and `publicTransportation` resolve exactly to `public_transportation`; near-miss case or whitespace is not silently normalized. |
| T5 | Canonical persistence | An explicit selection writes its stable canonical ID, including `public_transportation`, only when the write contract permits it. |
| T6 | Unknown identifier preservation | Unknown raw ID/label is visible and round-trips through unrelated edits without substitution. |
| T7 | Inactive mode preservation | Known inactive ID remains visible as historical, cannot be newly selected, and is not cleared automatically. |
| T8 | All initial catalog entries | Verify all twelve IDs are represented and their display concepts/categories match the catalog. |
| T9 | Capability-based filtering | Only entries where both active and profile capability are true appear as new choices; active entries with capability false do not. |
| T10 | Confirmation remains false | Fetch/create/update/save do not establish confirmation without a durable confirmation mechanism. |
| T11 | Unconfirmed CARS behavior | Unconfirmed preferences do not reach interest/activity scoring as confirmed evidence; missing status remains fail-closed. |
| T12 | Trip-wide precedence | Explicit trip-wide preference outranks profile preference and is never overwritten by it. |
| T13 | Leg and fixed commitment precedence | Explicit leg selection outranks trip-wide/profile preferences; fixed commitment mode/endpoints/schedule remain unchanged. |
| T14 | Failed update | Form retains attempted value, reports failure, and persisted snapshot remains the previously fetched state; no false success/confirmation. |
| T15 | Existing profile regression | Current profile creation, partial/group field preservation, validation, authenticated ownership, and unconfirmed state regressions pass. |
| T16 | Remote incompatibility | If null or canonical ID is rejected by the remote contract, no fallback mode is written and user receives a clear error. |
| T17 | System suggestion precedence | Generated suggestions cannot overwrite fixed commitments, explicit leg choices, explicit trip-wide preferences, or profile preferences. |
| T18 | No silent substitution | Unknown, inactive, or unmappable values remain preserved and do not become another mode or an availability claim. |

Candidate existing files: `test/tourist_planning_profile_service_test.dart`, `test/planning_preferences_page_test.dart`, and `test/system_generated_planning_page_test.dart`. Add focused model codec tests in a separately authorized test file if needed; do not broaden tests into Hive, itinerary-leg, MO-GA, CARS routing, or database integration scope for the first profile slice.

## 12. File-level implementation proposal (not authorization)

| File | Proposed bounded change | Dependencies / exclusions |
|---|---|---|
| `lib/models/tourist_planning_profile.dart` | Nullable, lossless profile preference representation; parse null/exact aliases/unknown IDs; validate explicit selection using catalog capability. | Must not assume remote schema nullability; avoid unrelated profile fact changes. |
| `lib/services/tourist_planning_profile_service.dart` | Preserve unconfirmed state; apply explicit write semantics; handle rejected null/canonical value without fallback or false success. | Separate schema evidence/authorization required before writes that remote contract may reject. No live Supabase inspection in this task. |
| `lib/screens/tourist_screens/planning_preferences_page.dart` | Build choices from active catalog modes with profile capability; represent local null; do not claim remote clearing until enabled; retain unknown/inactive value visibly; preserve failed draft input. | No claim of service availability; no itinerary leg editor. |
| `lib/services/tourist_planning_profile_trip_adapter.dart` | Preserve explicit trip values; never map unsupported catalog IDs to a different old enum; apply profile only as an approved suggestion. | Full per-leg support requires later itinerary model work; no Hive/MO-GA changes here. |
| `test/tourist_planning_profile_service_test.dart` | Null, canonical, alias, unknown, inactive, failure, and confirmation boundary tests. | Mocked service only; no Supabase access. |
| `test/planning_preferences_page_test.dart` | Twelve-item catalog/capability filtering, local null behavior with remote clear gated, historical value retention, failed save and confirmation messaging. | Existing behavior regression retained. |
| `test/system_generated_planning_page_test.dart` | Profile/trip explicit precedence and no unsupported conversion; explicit leg precedence later when leg type exists. | No optimizer/CARS route-provider changes. |
| Proposed new `test/tourist_planning_profile_test.dart` | Model/codec validation independent of widget/service. | Add only if authorized; exact test target can be chosen by implementation task. |

## 13. Outstanding dependencies and technical blockers

Owner selections are complete. The following are technical, compatibility, or authorization dependencies:

1. Local nullability is selected, but remote `tourist_details.travel_mode` nullability, constraints, and clear behavior are unverified. Do not issue remote null writes or claim a remote clear.
2. Preserve raw aliases and unknown values through unrelated profile updates; canonicalize recognized aliases only on explicit selection.
3. Durable preference confirmation remains absent. Current service snapshots stay false; CARS stays fail-closed until a durable mechanism is separately specified and implemented.
4. The profile catalog has twelve entries while the trip adapter retains a five-value enum. Do not map unsupported IDs to a nearest/parent mode; itinerary integration is separate.
5. Apply the selected precedence hierarchy when trip/leg selection and system suggestions are integrated.
6. Keep catalog membership distinct from route evidence. No service availability may be inferred by CARS or MO-GA.
7. Any remote schema or policy change requires separate A-13 scope closure, A-14 review as applicable, A-15 non-production authorization, and later A-16 production authorization. This document grants none.


## 14. Consolidated owner decision matrix

The following matrix contains each D36A identifier exactly once. The selections are owner-selected architectural directions, not implementation authorization.


| Decision | Owner-selected option | Consolidated direction | Remaining technical dependency |
|---|---|---|---|
| D36A-01 | Option C — Nullable with Compatibility Protection | Local preference supports null; remote null writes and clearing are deferred until compatibility is verified and separately authorized. | Remote nullability and clear behavior are not verified; do not report remote clear as persisted. |
| D36A-02 | Option A — Exact Dual-Read Compatibility | Decode canonical IDs and exact approved aliases; preserve raw value on unrelated updates; explicit selection writes canonical ID; preserve unknown values without substitution. | Preserve raw value through full profile updates. |
| D36A-03 | Option C — Remain Unconfirmed Until a Durable Confirmation Mechanism Exists | Reads and writes do not establish confirmation; CARS remains fail-closed for unconfirmed preference evidence. | Durable confirmation mechanism and reset semantics remain future work. |
| D36A-04 | Option A — Strict Precedence Hierarchy | Fixed commitments > explicit leg selections > explicit trip-wide preferences > profile preferences > system-generated suggestions. | Apply consistently when trip/leg models and suggestion flows are integrated. |
| D36A-05 | Option A — Strict Capability-Based Selection | New choices require active mode and `profilePreference == true`; unknown/inactive values remain visible but are not new choices. | Explicitly enforce capability; existing catalog helper checks active state only. |
| D36A-06 | Option A — Local Nullable Model with Existing Remote Contract | Support nullable local value and preserve remote `travel_mode`; defer remote null writes, schema changes, and migrations pending verification/authorization. | Verify accepted canonical values and nullability before changing remote writes. |
| D36A-07 | Option A — Strict Validation with Preservation | Accept null; reject empty/invalid new values; accept canonical IDs/approved aliases; preserve unknown/inactive history; preserve saved data on failed update; remain unconfirmed absent durable evidence. | Implement field validation and error handling without losing prior saved state. |

## 15. Authorization and closeout

All seven D36A owner decisions have been received and are recorded in the consolidated matrix. They are owner-selected architectural directions; **implementation authorization is not granted.** No Dart file, test, dependency, Hive serialization/data, SQL, migration, remote schema, Supabase state, CARS/MO-GA behavior, or manuscript was changed or accessed. No tests were run.

Whitespace validation: `git diff --check` passed; direct trailing-whitespace scans of both updated documents passed.

All seven Task 36A owner decisions have been received. Profile integration remains unauthorized pending a separate implementation authorization review.

**Final status:** Owner decisions are consolidated. Profile integration remains unauthorized pending a separate implementation authorization review. Remote nullability and durable confirmation remain separate compatibility/security gates.
