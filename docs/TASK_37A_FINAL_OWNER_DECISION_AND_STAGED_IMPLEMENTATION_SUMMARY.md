# Task 37A - Final Owner Decision and Staged Implementation Summary

**Project:** SAMAL NAV
**References:** Tasks 36A, 37, and 37A
**Status:** Five owner decisions consolidated; implementation authorization not granted.
**Evidence boundary:** Repository-owned documentation/schema artifacts and read-only source inspection only. No Supabase or live database access; no tests or builds run.

## 1. Owner decision record

All five selections below are approved architectural directions. They do not authorize code, schema, database, or deployment changes.

| Decision | Selection | Binding direction |
|---|---|---|
| D37A-01 | Option C - Evidence-Based Compatibility | Require approved, target-specific schema evidence before enabling canonical transportation writes. Verify deployed column type, nullability, defaults, constraints, relevant triggers, and migration provenance. Unverified identifiers remain non-persistent. Checked-in backup SQL is not proof. |
| D37A-02 | Option C - Defer Clearing Entirely Until a Complete Persistent Mechanism Is Authorized | Defer preference clearing until a complete persistent mechanism is verified and separately authorized. Local nullability does not authorize remote null writes. Never report a clear while the stored remote value remains. |
| D37A-03 | Option C - Gate All Transportation Writes | Disable every remote transportation preference write for now. Existing remote values remain readable and preserved. Omit `travel_mode` from unrelated profile updates; do not automatically rewrite canonical or legacy values. |
| D37A-04 | Option A - Strict Lossless Update Contract | Unrelated updates omit `travel_mode`; retain unknown, inactive, legacy, and historical identifiers exactly; never turn local null into remote null; on failure retain the last successfully saved snapshot; distinguish validation, network, and storage errors; never substitute another mode. |
| D37A-05 | Option C - Staged, Compatibility-Protected Integration | Prepare local nullable/lossless compatibility, protected service updates, catalog eligibility evaluation, and read-only display in stages. Do not enable new preference selection or remote persistence. Clearing remains deferred. |

**All five Task 37A owner decisions have been received. Profile catalog integration remains unauthorized pending a separate implementation authorization review.**

## 2. Consolidated contract and verified evidence

The repository backup schema declares `public.tourist_details.travel_mode` as `TEXT NOT NULL DEFAULT 'walking'` without a visible allowlist in that table definition. Sample backup rows contain `driving`, `walking`, and `transit`. A separate migration creates `tourist_profiles`, not the `tourist_details` table used by the current service. These artifacts establish only snapshot-level observations. They do not establish the deployed target's schema, constraints, triggers, or accepted vocabulary.

Deployed compatibility for each of the twelve canonical catalog IDs remains **UNKNOWN**. No value is approved for remote persistence by this evidence. The existing service updates the full profile JSON, including `travel_mode`, and the current profile model requires a nonempty string. The service reports preference confirmation as false. The profile selector is currently editable and offers five legacy values. These are source findings; none changes the owner selections above.

### Remote update rules

- Existing values are readable and must remain losslessly preserved, including approved aliases, unknown values, and inactive identifiers.
- An unrelated profile update omits `travel_mode` entirely. Omission preserves the remote field; it does not clear it.
- A local nullable value never serializes automatically as remote `travel_mode: null`.
- No explicit transport selection is sent remotely while writes are gated. Do not claim it was saved.
- No canonicalization, alias rewrite, fallback, or substitution occurs as a side effect of unrelated edits.
- A failed update leaves the last successful saved snapshot unchanged and reports failure. No success notification is shown.
- Clearing is not offered under the selected policy until a complete persistent mechanism and separate authorization exist.
- Profile values remain unconfirmed; CARS confirmation/scoring behavior stays fail-closed.

## 3. Staged implementation proposal

Each stage below is a future bounded scope, not current authorization. A separate implementation authorization review is required before editing source or tests.

| Stage | Scope | Files | Tests and acceptance |
|---|---|---|---|
| 1 - Local compatibility foundation | Nullable local representation; exact alias decoding; lossless unknown/inactive values; display existing values without enabling new selection. | `lib/models/tourist_planning_profile.dart`; `lib/services/tourist_planning_profile_trip_adapter.dart` only if needed for null-safety; `test/tourist_planning_profile_service_test.dart` for mocked model/service compatibility coverage. | Null local value is distinct from missing key and remote null; empty string rejected; aliases decode exactly; unknown/inactive values survive; no trip-mode substitution; explicit itinerary value wins. |
| 2 - Lossless service protection | Omit `travel_mode` from unrelated remote update payloads; retain the last saved snapshot on failure; distinguish validation from request/storage errors; keep confirmation false. | `lib/services/tourist_planning_profile_service.dart`; `test/tourist_planning_profile_service_test.dart`. | Request payload excludes `travel_mode`; no remote null or explicit mode write; unrelated field updates preserve the remote value; failure produces no success and retains the prior snapshot; ownership/auth behavior regresses cleanly. |
| 3 - Catalog eligibility and read-only display | Evaluate active status and `workflowCapabilities.profilePreference`; show the current saved value read-only, including unknown/inactive history; expose no new-choice or clear control. | `lib/screens/tourist_screens/planning_preferences_page.dart`; `test/planning_preferences_page_test.dart`. `lib/models/transport_catalog.dart` should need no change if the screen applies the existing fields directly. | Only active+capable modes enter prepared eligibility data; inactive entries are not choices; saved values remain visible; no availability claim, new selection, clear, or false saved message. |
| 4 - Remote transportation integration (deferred) | Enable only explicitly authorized identifiers after target-specific compatibility evidence and a separate implementation/security review. | Exact files to be defined in that later authorization. | Prove target-specific accepted values; failed writes preserve prior state; no fallback or substitution. No Supabase access or schema change is authorized here. |
| 5 - Persistent clearing (deferred) | Design and implement a complete, verified persistent clearing mechanism. | Exact files and persistence contract to be defined separately. | Clearing is only reported after the authorized persistence operation succeeds; no remote null is sent before compatibility and authorization. |

Stages 1-3 must not imply that a transportation choice was persisted remotely. Stages 4-5 are explicitly deferred and require new evidence and authorization.

## 4. Acceptance test matrix

These are future tests only; they were not run for this documentation task.

| Test | Acceptance criterion |
|---|---|
| Existing values readable | Current remote values display without loss or unsupported normalization. |
| Alias compatibility | Exact `public transportation` and `publicTransportation` resolve for display; original remote raw value remains preserved. |
| Unknown/inactive preservation | Unknown and inactive identifiers remain visible and unchanged on unrelated edits; neither is offered as a new choice. |
| No substitution | Unsupported values never map to a parent, default, or alternative mode. |
| Writes gated | No request under the current policy submits any `travel_mode` write, explicit or implicit. |
| Unrelated update payload | Profile updates for other fields omit `travel_mode`. |
| Null boundary | Local null never appears as remote JSON null; no empty string sentinel is emitted. |
| Clearing deferred | No clear affordance or success claim is exposed. |
| Failure snapshot | Failed unrelated update preserves the last successful profile snapshot and does not show success. |
| Error distinction | Validation errors are distinguishable from network/storage failures. |
| Catalog eligibility | Prepared eligibility requires both active status and `profilePreference == true`. |
| Read-only display | Existing canonical, alias, unknown, and inactive values can be displayed without claiming service availability. |
| No false persistence | New transportation selection is absent/disabled; no view or model claims it was remotely saved. |
| Confirmation boundary | Fetch/create/update remain unconfirmed; CARS receives no confirmed preference evidence. |
| Regression | Existing profile fields, ownership rules, form validation, and unrelated update behavior remain intact. |

## 5. Remaining dependencies and readiness

1. Target-specific deployed schema evidence is still required before any remote transportation write; repository SQL snapshots are insufficient.
2. Any future write or clearing behavior needs a separate implementation authorization, plus applicable A-13/A-14/A-15/A-16 security and database gates.
3. The service currently sends `travel_mode` in full profile JSON; it does not meet the selected omission contract yet.
4. The profile model remains non-nullable and the screen remains a five-choice editable dropdown; the proposed Stages 1-3 are unimplemented.
5. No implementation changes, tests, or builds are authorized or performed here.

**Readiness verdict:** The owner contract is consolidated. A compatibility-protected staged implementation plan is specified, but profile catalog integration remains unauthorized pending a separate implementation authorization review. Remote preference writes and persistent clearing remain deferred.

**Implementation authorization: NOT GRANTED.** No source/tests, SQL/migrations, Hive data, database, Supabase, CARS/MO-GA, or manuscript changes were made. No tests or builds were run; nothing was staged, committed, or pushed.
