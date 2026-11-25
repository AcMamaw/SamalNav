# Task 37A â€” SAMAL NAV Profile Remote Compatibility and Clearing Contract Closure

**Project:** SAMAL NAV
**Reference:** Tasks 36A and 37
**Type:** Technical contract closure
**Review date:** 26 November 2026 (Asia/Manila)
**Implementation authorization:** **Not granted.**

## 1. Executive summary

Repository-owned SQL artifacts provide limited evidence about a profile transportation field, but they do not establish the current deployed contract. The checked-in backup schema declares `public.tourist_details.travel_mode` as `text DEFAULT 'walking' NOT NULL`; that table definition contains no `travel_mode` check constraint or enum. The same backup data contains a few values (`driving`, `walking`, `transit`), not the twelve catalog identifiers. A separate migration, `supabase/migrations/004_full_schema_from_spec.sql`, creates `tourist_profiles` rather than the application's `tourist_details` table and also declares a non-null text field. Repository documentation explicitly says local SQL is not proof of deployed schema.

Therefore:

- **Checked-in snapshot-level type compatibility:** all twelve canonical identifiers are nonempty text and fit the declared `TEXT NOT NULL` column type; no value allowlist is present in the inspected `tourist_details` declaration.
- **Existing deployed remote compatibility:** **UNKNOWN** for all twelve canonical identifiers. No live database or Supabase access was performed, and the repository does not establish which artifact matches the deployed target or whether other deployed constraints/triggers exist.
- **Remote null compatibility:** the checked-in `tourist_details` snapshot is explicitly `NOT NULL`; this is evidence against remote null writes for that snapshot, not proof of current deployed nullability. Under the selected D36A-01/06 contract, do not write remote null or claim remote clearing.

Owner decisions D37A-01 through D37A-05 are now recorded in Section 9. All remote transportation writes are gated, persistent clearing is deferred, and unrelated profile updates must omit `travel_mode`. No alias-to-different-mode fallback is permitted.

## 2. Evidence inventory and limits

| Repository artifact | What it establishes | What it does not establish |
|---|---|---|
| `supabase/backup/schema.sql`, lines 581â€“596 | Checked-in backup defines `public.tourist_details.travel_mode text DEFAULT 'walking'::text NOT NULL`. The table definition shown has no `travel_mode` CHECK constraint. | That this backup is current, deployed, or complete; hidden triggers/functions or constraints outside this definition; whether canonical values are accepted by the live target. |
| `supabase/backup/data.sql`, lines 557â€“562 | Checked-in sample rows for `tourist_details` include values `driving`, `walking`, and `transit`. | An approved application vocabulary or support for every catalog identifier. Sample row presence is not a complete allowlist. |
| `supabase/migrations/004_full_schema_from_spec.sql`, lines 40â€“50 | Creates `tourist_profiles` with `travel_mode TEXT NOT NULL DEFAULT 'walking'`; no value allowlist appears in that definition. | The application service targets `tourist_details`, and this migration is not evidence that the target table uses this definition or that the migration ran. |
| `supabase/remote_schema_baseline.sql` | File exists in the repository. Targeted search found no `travel_mode` declaration in it. | Any actual current remote contract for `travel_mode`. |
| `lib/models/tourist_planning_profile.dart` | Client requires a nonempty string and serializes it as `travel_mode`. | Database acceptance. Dart model validation is not schema evidence. |
| `test/tourist_planning_profile_service_test.dart`, `test/planning_preferences_page_test.dart`, `test/system_generated_planning_page_test.dart` | Fixtures exercise values such as `walking`; widget test selects `public transportation`. | Live database compatibility or coverage of all canonical identifiers. These are mocked/client tests. |
| `docs/TASK_17_CARS_DATABASE_RELATIONSHIP_AND_EVIDENCE_SOURCE_DISCOVERY.md`, especially Sections 2, 3, and 5 | States checked-in local SQL does not prove deployed schema and distinguishes `tourist_details` from the separate `tourist_profiles` migration/table. | Fresh live evidence. |
| `docs/TASK_36A_FINAL_OWNER_DECISION_SUMMARY.md` and `docs/TASK_37_SAMALNAV_PROFILE_CATALOG_INTEGRATION_AUTHORIZATION_REVIEW.md` | Authoritative owner decisions and the previously identified remote compatibility/clearing blockers. | Any remote schema capability not directly verified. |

The repository scan was read-only. No Supabase configuration was used to connect, and no live database was accessed.

## 3. D37A-01 â€” Canonical remote identifier compatibility

**Owner selection: Option C — Evidence-Based Compatibility.** Require approved, target-specific remote schema evidence before enabling canonical transportation identifier writes. Verify column type, nullability, defaults, constraints, relevant triggers, and migration provenance. Unverified identifiers remain non-persistent. The checked-in backup SQL is not proof of deployed compatibility.

### 3.1 Evidence matrix

The â€œcompatibility statusâ€ below separates the checked-in SQL declaration from the deployed contract. All catalog IDs are nonempty text, so they fit the backup's declared SQL type. That type-level fact does not prove that a deployed project accepts them.

| Canonical ID | Existing repository evidence | Compatibility status |
|---|---|---|
| `walking` | Backup `tourist_details.travel_mode` is `TEXT NOT NULL`; backup data contains a `walking` row. | Snapshot-level: observed value and type-compatible. Deployed remote: **UNKNOWN**. |
| `bicycle` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `bicycle` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `motorcycle` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `motorcycle` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `car` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `car` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `public_transportation` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for this canonical ID found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `jeepney` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `jeepney` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `tricycle` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `tricycle` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `multicab` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `multicab` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `van` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `van` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `bus` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `bus` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `ferry` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `ferry` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |
| `boat` | Backup column is `TEXT NOT NULL`; no row or allowlist entry for `boat` found. | Snapshot-level: fits text declaration. Deployed remote: **UNKNOWN**. |

No repository artifact proves that all twelve values are in the currently deployed `tourist_details` contract. The backup's lack of an allowlist is not enough to certify deployed compatibility.

### 3.2 Owner options for unverified canonical writes

| Option | Policy | Consequence |
|---|---|---|
| A | Defer remote writes of all canonical catalog IDs until target-specific evidence confirms accepted values. Continue reading and preserving existing raw values. | Safest against failed or invalid writes; catalog choices cannot be presented as persistently saved yet. |
| B | Treat the checked-in backup's unconstrained `TEXT` declaration as sufficient for remote canonical writes. | Fastest, but assumes the backup matches deployment and omits unknown deployed constraints/triggers. Not recommended by this review. |
| C | Obtain approved, target-specific schema evidence first; then enable only the canonical IDs explicitly confirmed by that evidence. | Preserves a precise evidence gate; requires separate evidence collection/authorization and may initially enable a subset. |

**Original recommendation (retained for traceability; now aligned with the selected Option C).** Until target-specific evidence exists, apply the conservative part of Option A. No value may be mapped to a different transportation mode as a fallback.

**Decision status:** Owner selection received; see the consolidated matrix. Implementation remains unauthorized.

## 4. D37A-02 â€” Profile clearing user experience

**Owner selection: Option C — Defer Clearing Entirely Until a Complete Persistent Mechanism Is Authorized.** Do not provide persistent clearing until a complete mechanism is verified and separately authorized. Local nullability does not authorize remote null writes. Never report successful clearing while the remote preference is unchanged.

The approved contract allows a local nullable model but defers remote null writes. The current profile is fetched from and updated in remote `tourist_details`; no local profile persistence mechanism was identified. If the service omits `travel_mode` from an update, the remote value remains unchanged and will appear again on a later fetch.

| Option | Behavior | Data consistency and UX consequences |
|---|---|---|
| A | Disable persistent preference clearing until remote null compatibility is separately verified and authorized. | Remote value remains authoritative and consistent. UI must not offer a control that looks like a successful clear. Users cannot clear the saved preference yet. |
| B | Allow session-only clearing, with an explicit warning that the saved remote preference remains unchanged and may return after reload. | Local screen state may be null for the current session, but remote and local state intentionally differ. The warning must be prominent; reload restores the remote value. |
| C | Defer the clearing feature entirely until a complete persistent clearing mechanism is authorized. | Simplest state model: no local clear affordance and no apparent clear. Clearing becomes available only with verified remote null support or another separately approved persistence design. |

**Original recommendation (retained for traceability; now aligned with the selected Option C)** for a production-facing profile screen; Option B is only appropriate if there is a concrete session-only workflow and explicit product approval. Option A and C are similar but differ in emphasis: A disables persistent clear while leaving room for a clearly non-persistent UX; C removes clearing entirely until persistence is complete.

**Decision status:** Owner selection received; see the consolidated matrix. Implementation remains unauthorized.

## 5. D37A-03 â€” Canonical write policy

**Owner selection: Option C — Gate All Transportation Writes.** Temporarily disable all remote transportation preference writes until target-specific compatibility evidence and separate authorization exist. Existing remote values remain readable and preserved. Exclude `travel_mode` from unrelated remote profile updates. Do not automatically rewrite canonical or legacy values.

### 5.1 Current values and proposed treatment

| Value group | Repository evidence/current behavior | Historical proposal before owner decision |
|---|---|---|
| Existing five preference values: `walking`, `bicycle`, `motorcycle`, `car`, `public transportation` | Current screen offers these strings. Client model accepts the current stored string if allow-listed. Backup rows include `walking`, `driving`, and `transit`; those sample values do not prove the full set is supported. | Read and preserve exact remote raw value. Do not rewrite a stored value merely because another profile field changes. New canonical writes still require the D37A-01 compatibility choice. |
| Canonical public transport ID: `public_transportation` | Catalog resolves the exact aliases `public transportation` and `publicTransportation`; the database uses `TEXT` in the checked-in snapshot. | Explicit selection may construct canonical ID locally. Do not claim remotely saved until compatibility is established. |
| Seven additional catalog modes: `jeepney`, `tricycle`, `multicab`, `van`, `bus`, `ferry`, `boat` | Catalog IDs exist locally; no matching profile database row or allowlist evidence found. | Preserve/select locally only as permitted by owner UX decision; remote persistence remains gated. Never map to `public transportation`, `car`, or another value. |
| Exact aliases `public transportation`, `publicTransportation` | Catalog codec recognizes only these exact aliases for `public_transportation`. | Preserve the original alias during unrelated updates; explicit selection of public transportation creates canonical `public_transportation`, subject to remote write gate. |
| Unknown historical identifier | Profile `String` currently round-trips exact string if the screen allow-lists the saved current value; catalog reference preserves unknown raw IDs. | Preserve exact raw identifier during unrelated changes. Do not substitute. If the user explicitly selects a different mode, write that selected canonical value only after compatibility gate; otherwise keep old remote value. |
| Known inactive identifier | Catalog can resolve it as historical, but it must not be offered as a new selection. | Preserve on unrelated update; no silent clear or replacement. Explicit replacement uses the selected canonical ID subject to the write gate. |

### 5.2 Owner options

| Option | Policy |
|---|---|
| A | Preserve existing remote values; allow canonical remote writes only after D37A-01 evidence/owner gate; rejected writes fail honestly and do not fall back. |
| B | Continue remote writes only for current legacy spellings and defer new canonical catalog IDs; preserve unknown values on unrelated updates. |
| C | Gate every explicit transport-mode write until target-specific compatibility is established, while allowing unrelated profile-field updates that omit `travel_mode`. |

**Original recommendation (retained for traceability): Option C initially**, then move to A for explicitly verified identifiers. It minimizes assumptions while preserving unrelated profile edits. Option B still assumes that all current legacy spellings are accepted for a changed row; existing row values alone do not prove every value is accepted by all deployed constraints.

Remote rejection of an explicit selection must leave the previous remote value in place, surface a storage error, and retain the unsaved selection for user correction/retry. There is no fallback to an alternate transportation value.

**Decision status:** Owner selection received; see the consolidated matrix. Implementation remains unauthorized.

## 6. D37A-04 â€” Lossless profile update contract

**Owner selection: Option A — Strict Lossless Update Contract.** Unrelated profile updates exclude `travel_mode`; preserve unknown, inactive, legacy, and historical values exactly; local null never becomes remote null automatically; failed updates retain the last successfully saved snapshot; validation, network, and storage errors are distinct; unsupported identifiers are never substituted.

### 6.1 Update payload rules

1. Decode a fetched value for display, but retain the exact original remote string separately from any canonical resolution.
2. For an unrelated profile update, omit `travel_mode` from the remote PATCH payload. If the service must send it for a legacy reason, send the exact original raw value; never send a canonicalized alias as a side effect.
3. A local null means â€œno local preference.â€ It never serializes to remote JSON null under the current authorization. Omit the key; do not claim the remote preference was cleared.
4. Do not send any explicit transportation selection remotely while D37A-03 is in force. Retain it only as an unsaved form value if the UI later permits a draft; do not report persistence.
5. No transportation PATCH is attempted while writes are gated. If a separately authorized future phase enables writes and the server rejects one, do not retry with an alias, parent category, or alternate mode; retain the last saved snapshot and surface a storage error.
6. Update the in-memory saved snapshot only after a successful server response. On error, retain the prior saved snapshot and unsaved form state. Do not show success.
7. A successful unrelated update does not imply a preference write or confirmation; `preferencesConfirmed` remains false.

### 6.2 Before-and-after examples

**Example 1 â€” Unrelated budget update with a legacy alias**

Before fetch:

```json
{"budget_min": 1000, "travel_mode": "public transportation"}
```

User changes only `budget_min` to `1500`. Preferred remote PATCH:

```json
{"budget_min": 1500}
```

The remote `travel_mode` remains exactly `public transportation`; the alias is not rewritten to `public_transportation`.

**Example 2 â€” Unrelated edit with an unknown stored value**

Before: `{"travel_mode":"legacy_motorized_2"}`. User changes trip duration. The patch contains only `trip_duration_days`; `legacy_motorized_2` remains unchanged. No replacement is inferred.

**Example 3 â€” Local null while remote clearing is disabled**

Fetched remote value: `{"travel_mode":"walking"}`. The local editing candidate may represent null, but the remote patch omits `travel_mode`; remote value remains `walking`. UI must not say â€œsaved preference cleared.â€ Under selected D37A-02, no user-facing clearing feature is exposed until a complete persistent mechanism is authorized.

**Example 4 - Explicit canonical selection (deferred)**

User explicitly selects Jeepney. Candidate is `{"travel_mode":"jeepney"}`. Under the current selected policy, this PATCH is not sent. Any future enabling requires target-specific compatibility evidence and separate authorization; no success is reported before an authorized write succeeds.

**Example 5 - Explicit canonical selection, remote write disabled**

Previous saved value: `{"travel_mode":"walking"}`. While writes are gated, no `{"travel_mode":"jeepney"}` PATCH is attempted. The saved snapshot remains unchanged; the UI must not claim persistence or try `public transportation` or another mode.

These examples specify the selected target contract, not current service behavior. Current `updateCurrent()` sends the full `profile.toJson()` and does not yet meet the required omission rule.

## 7. D37A-05 â€” Implementation readiness

**Owner selection: Option C — Staged, Compatibility-Protected Integration.** Stage 1 supports nullable local representation, legacy decoding, unknown/inactive preservation, and existing-value display. Stage 2 protects remote updates by excluding `travel_mode`. Stage 3 evaluates catalog eligibility without enabling new selection. New selections, transportation writes, remote integration, and persistent clearing remain disabled pending target-specific compatibility evidence and separate authorization.

| Capability | Readiness under existing remote contract | Notes |
|---|---|---|
| Local nullable profile model | Technically implementable in isolation | Model can represent null without changing remote schema. It does not by itself persist null or clear the remote value. |
| Read existing remote raw value | Current implementation exists for non-null strings | Backup schema says NOT NULL; current model rejects null. Deployed behavior remains unverified. |
| Catalog-driven display/filter | Technically implementable in UI/model | Must filter active AND profile capability; must retain unknown/inactive raw value; does not establish persistence or service availability. |
| Fully persistent profile catalog selection | **Not ready** | Canonical ID acceptance is unknown on deployed `tourist_details`; all 12 remain UNKNOWN as deployed compatibility. |
| Unrelated profile field updates | Implementable with lossless patch payload | Must omit `travel_mode` when unchanged/null so original value is preserved; current service sends full model JSON. |
| Persistent clearing | **Deferred / not ready** | D36A-01/06 defer remote null writes; the checked-in backup is NOT NULL; no local profile store was found. |
| Session-only clearing | Technically possible but owner decision required | Requires explicit warning and a decision about reload behavior; does not persist. |
| Durable preference confirmation | **Deferred** | No current storage field/mechanism; snapshots always false. CARS remains fail-closed. |
| Schema/migration change for nullable remote field | **Separate authorization required** | Outside Task 37A; must include database scope/security review and target-specific deployment authorization. |

### Smallest functional implementation scope

The smallest coherent persisted implementation would include the profile model, service update-payload construction, profile preferences screen, and focused profile tests. It must preserve the original remote value on unrelated edits and gate canonical writes. However, until compatibility and clearing decisions are closed, that scope cannot provide the full requested catalog selection and persistent-clear behavior. A model-only or display-only slice would be explicitly partial and must not be presented as completed profile catalog integration.

## 8. Acceptance-test matrix

No tests were executed. These are future tests for a separately authorized implementation.

| T1 | Existing remote values readable | Existing non-null values in fixtures parse and display without lossy conversion; no compatibility is inferred for new IDs. |
| T2 | Unknown identifier preservation | Unknown raw IDs survive unrelated edits exactly and remain visible; no substitution. |
| T3 | Legacy alias decoding | Exact `public transportation` and `publicTransportation` resolve for display; raw remote value is preserved. |
| T4 | No automatic substitution | Unknown, inactive, or unsupported values never map to another catalog ID or legacy value. |
| T5 | No remote transportation writes | Any explicit selection cannot submit a `travel_mode` remote update under D37A-03. |
| T6 | `travel_mode` excluded from unrelated updates | PATCH payloads for unrelated fields omit `travel_mode`, preserving the exact remote value. |
| T7 | Local null never becomes remote null | Null is absent from remote update JSON; no `travel_mode: null` request is sent. |
| T8 | Persistent clearing unavailable | No clear action is exposed in the staged slice; UI does not claim a remote clear. |
| T9 | Failed updates preserve snapshot | Rejected unrelated update leaves the last successful snapshot intact and displays no success. |
| T10 | Validation/network/storage errors differ | Invalid new local input is identified as validation; request failures are surfaced as network/storage errors without state loss. |
| T11 | Catalog capability filtering | Eligibility helper includes only active entries with `profilePreference == true`; it does not expose a selection control. |
| T12 | Inactive modes not new choices | Known inactive value is displayed historically and excluded from eligibility. |
| T13 | Existing preferences display | Known canonical/alias, unknown, and inactive saved values render read-only with no availability claim. |
| T14 | No false persistence report | Selection is disabled; no UI or snapshot claims a new transportation value was saved. |
| T15 | Unconfirmed state retained | Fetch, create, and update continue to produce `preferencesConfirmed == false`; CARS remains fail-closed. |
| T16 | Local nullable model | Null parses/serializes locally; empty string is rejected as a new value; no remote null write occurs. |
| T17 | Failed update keeps unsaved selection | If a later authorized write attempt fails, retain prior saved snapshot and attempted form choice; no fallback. |
| T18 | Existing profile regression | Ownership, unrelated fields, form validation, and current unconfirmed behavior remain intact. |

No tests were executed. These are acceptance tests for separately authorized staged implementation.

## 9. Consolidated owner decision matrix

These five owner selections are approved architectural directions, not implementation authorization. Earlier option wording and recommendations remain in Sections 3-7 as historical decision context; the selected directions here govern future proposals.

| Decision | Owner-selected option | Selected direction | Remaining dependency |
|---|---|---|---|
| D37A-01 | Option C - Evidence-Based Compatibility | Require approved target-specific schema evidence before canonical transportation writes; verify deployed type, nullability, defaults, constraints, relevant triggers, and migration provenance. Unverified IDs remain non-persistent; checked-in backup SQL is not proof. | Obtain approved deployment-aligned evidence; no Supabase/live database access in this task. |
| D37A-02 | Option C - Defer Clearing Entirely Until a Complete Persistent Mechanism Is Authorized | Do not offer clearing until a complete persistent mechanism is verified and separately authorized. Local null does not authorize remote null; do not claim a clear while the remote value remains. | Complete persistent clearing mechanism and separate authorization. |
| D37A-03 | Option C - Gate All Transportation Writes | Disable all remote transportation preference writes. Read and preserve existing values; omit `travel_mode` from unrelated updates; never automatically rewrite aliases or canonical values. | Target-specific evidence and later separate authorization before enabling any transportation write. |
| D37A-04 | Option A - Strict Lossless Update Contract | Unrelated updates omit `travel_mode`; preserve unknown, inactive, legacy, and historical values exactly; local null never becomes remote null; failures retain the last successful snapshot; distinguish validation, network, and storage errors; never substitute. | Separately authorized implementation and mocked service acceptance tests. |
| D37A-05 | Option C - Staged, Compatibility-Protected Integration | Stages 1-3 prepare nullable/local compatibility, lossless update protection, catalog eligibility, and read-only display. New selection and remote persistence remain disabled; clearing remains deferred. | Separate implementation authorization review; remote integration and clearing remain later gated stages. |

## 10. Remaining blockers

1. Deployed compatibility of all twelve canonical IDs remains UNKNOWN; checked-in SQL is only snapshot-level evidence.
2. D37A-01 requires target-specific evidence covering type, nullability, defaults, constraints, relevant triggers, and migration provenance.
3. D37A-02 persistent clearing remains deferred; local null cannot be persisted remotely under current authorization.
4. D37A-03 gates every remote transportation write, including previously used values; unrelated updates must omit the field.
5. The current service submits the full `profile.toJson()` object. It needs a transport-free patch path that preserves fetched snapshots and does not falsely claim writes.
6. Profile service snapshots remain unconfirmed; CARS stays fail-closed.
7. Existing trip adapter is limited to the old five-value enum. This staged scope must not add itinerary or MO-GA behavior.

## 11. Staged implementation proposal and exact future file scope

This is a preparation plan only. Each stage requires a separate implementation authorization before code or tests are changed.

### Stage 1 — Local Compatibility Foundation

**Purpose:** Add local nullable representation, exact legacy decoding, lossless preservation, and read-only display of the existing remote preference. No new transport choice is enabled.

| File | Current behavior | Proposed change | Dependencies and regression risks | Required tests |
|---|---|---|---|---|
| `lib/models/tourist_planning_profile.dart` | Required non-null string; `fromJson` rejects null; `toJson` includes `travel_mode`; validation uses caller allowlist. | Support nullable local value and lossless raw historical identifier; decode only approved aliases; reject empty new input; do not canonicalize on unrelated edits. | Must keep local null distinct from remote null and preserve old constructors/callers as needed. | Null local round-trip; empty reject; existing raw values and exact aliases preserved; unknown/inactive values retained. |
| `lib/services/tourist_planning_profile_trip_adapter.dart` | Accepts non-null legacy string and maps five legacy values; does not understand seven other catalog values. | Only make nullable input type-safe if Stage 1 model change requires it; preserve explicit trip value and do not add catalog-to-enum substitutions. | No itinerary behavior or precedence application beyond current safe behavior. | Null/no mapping returns unchanged trip; explicit trip selection wins; unknown/additional IDs do not substitute. |
| `lib/screens/tourist_screens/planning_preferences_page.dart` | Editable five-choice dropdown. | Replace the transport selector with read-only display of the currently saved raw preference; no clear or new selection control. | Read-only display must not imply service availability or persistence of a new choice. | Canonical, alias, unknown, and inactive values render read-only; no clear or selection action. |
| `test/tourist_planning_profile_service_test.dart` | Mocked HTTP profile tests cover legacy non-null profile behavior. | Extend local nullable/raw-value parse and compatibility cases as required. | Tests must remain mocked; no Supabase/database access. | Existing values, alias preservation, unknown and inactive fixtures, null local representation. |

### Stage 2 — Lossless Profile Service Protection

**Purpose:** Protect the remote contract while allowing unrelated profile data to continue updating. All transportation writes remain disabled.

| File | Current behavior | Proposed change | Dependencies and regression risks | Required tests |
|---|---|---|---|---|
| `lib/services/tourist_planning_profile_service.dart` | `updateCurrent()` sends full `profile.toJson()` including `travel_mode`; snapshots are unconfirmed. | Build remote update payload without `travel_mode` for every update. Preserve the last successful snapshot on request failure; distinguish validation from network/storage errors; keep confirmation false. | D37A-03/04. Remote field must not be nulled or rewritten; no canonical write path in Stage 2. | Request omits travel_mode for unrelated updates; null never sent; exact raw value preserved remotely; rejected update no false success and prior snapshot retained. |
| `test/tourist_planning_profile_service_test.dart` | Current mocked service tests assert full editable-field PATCH. | Update/add assertions for omitted transportation field and failure-state preservation. | Update request expectations only under separately authorized test work; no test weakening. | No `travel_mode` in PATCH, no null body, failure leaves saved state unchanged, auth ownership regression. |

### Stage 3 — Catalog Eligibility Preparation and Read-Only Display

**Purpose:** Evaluate selectable capability for future use and display existing saved preferences without enabling selection or persistence.

| File | Current behavior | Proposed change | Dependencies and regression risks | Required tests |
|---|---|---|---|---|
| `lib/screens/tourist_screens/planning_preferences_page.dart` | Hard-coded five-option editable dropdown; save candidate reuses current value. | Prepare eligible-mode data using active AND `profilePreference`; expose no new selection control and no clear action. Existing preference is already display-only from Stage 1. | D37A-05. Avoid implying availability or that new choice was saved. | Capability predicate; inactive modes excluded; no selectable control or clear; no false saved message; unrelated form save excludes travel_mode. |
| `lib/models/transport_catalog.dart` | Already contains catalog records and workflow capability fields; helper checks active only. | No model edit is required if the screen applies the two-field predicate directly. A helper change is not authorized absent a demonstrated technical need. | Keep existing catalog behavior and stable IDs unchanged. | Screen/model tests verify active plus capability, without enabling selection. |
| `test/planning_preferences_page_test.dart` | Tests five-value dropdown and saves selected value. | Add read-only display/eligibility and no-write behavior coverage for the staged screen. | No tests run during this review. | Existing value display, all capability filtering, transportation control disabled/absent, no remote transport write, existing profile field behavior. |

| `test/tourist_planning_profile_service_test.dart` | Tests mocked profile requests. | Cover Stage 2 lossless update contract and status/error handling. | No live network or schema tests. | See Stage 2 criteria. |

### Stage 4 — Future Remote Integration (Deferred)

Enable canonical writes only after D37A-01 target-specific evidence and a separate authorization. No alias or alternate-mode fallback. Existing service/security checks remain required.

### Stage 5 — Future Preference Clearing (Deferred)

Persistent clearing remains unavailable until a complete mechanism is verified and separately authorized. Local null support alone does not authorize remote null writes.

## 12. Final readiness and authorization

**Compatibility finding:** Checked-in SQL shows snapshot-level text-column compatibility only. Deployed acceptance remains UNKNOWN for all twelve IDs.

All five Task 37A owner decisions have been received. Profile catalog integration remains unauthorized pending a separate implementation authorization review.

**Readiness verdict:** Owner decisions D37A-01 through D37A-05 are complete. Stages 1–3 are proposed as a compatibility-protected implementation plan, but implementation authorization remains separate and ungranted. Remote writes and persistent clearing remain deferred.

No implementation authorization is granted. This was read-only inspection and documentation only; no tests/builds, source changes, SQL execution, migrations, Hive access, Supabase access, live database access, manuscript edits, staging, commits, or pushes occurred. Existing working-tree changes were preserved.

Whitespace validation: completed after editing; `git diff --check` and trailing-whitespace scans passed. No tests or builds were run.
