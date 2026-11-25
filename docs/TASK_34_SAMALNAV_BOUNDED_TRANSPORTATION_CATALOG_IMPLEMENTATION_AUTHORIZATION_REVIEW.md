# Task 34 â€” SamalNav Bounded Transportation Catalog Implementation Authorization Review

**Project:** SAMAL NAV
**Reference:** Task 33A â€” Final Technical Contract Closure
**Review type:** Pre-implementation authorization review
**Authorization state:** No coding authorization has been granted.

## 1. Executive summary

Task 33A defines a sufficiently bounded, local-only transportation catalog and legacy codec that can be submitted for separate owner authorization. The proposed implementation touches exactly two new files: `lib/models/transport_catalog.dart` and `test/transport_catalog_test.dart`. It adds no consumers, Hive persistence, remote calls, database objects, or routing behavior.

The inspected repository has no existing transport catalog type or file-name collision. Its existing five-value `PreferredTravelMode` enum and profile adapter remain untouched by this proposed slice. This separation limits compatibility risk: the new codec can be tested in isolation before any application integration is separately authorized.

**Verdict: B â€” Ready for owner authorization with clearly stated conditions.** The authorization request must remain limited to the two listed files, and the owner must separately grant implementation authorization. The review itself does not grant that authorization.

## 2. Technical reference and inspection evidence

Task 33A Section 3 is controlling for the proposed registry, field contract, aliases, capability flags, handling rules, and tests. This review does not change that architecture or add owner decisions.

Read-only repository inspection found:

- `lib/models/itinerary_draft.dart` defines `PreferredTravelMode` with `walking`, `bicycle`, `motorcycle`, `car`, and `publicTransportation`; its wire-value extension emits `public transportation`. It separately defines `RequiredTransferKind { ferry, boat }` and `RequiredTransfer` with directed destination IDs.
- `lib/services/tourist_planning_profile_trip_adapter.dart` maps those five profile strings to the existing enum. It has no catalog integration.
- `lib/services/local_itinerary_draft_store.dart` writes the enum `.name` into Hive JSON and decodes it using current enum names. Hive persistence is outside this task.
- No `TransportCatalog`, `TransportMode`, `TransportCategory`, or `transport_catalog` implementation was found under `lib/` or `test/` at inspection time.
- Tests use `flutter_test` groups and ordinary Dart assertions/matchers; a pure model test can follow this pattern without Flutter widgets, Supabase, or Hive setup.
- `pubspec.yaml` requires Dart `^3.10.3`, Flutter SDK dependency; `pubspec.lock` records Dart `>=3.10.3 <4.0.0`, Flutter `>=3.38.1`, `hive` 2.2.3 and `hive_flutter` 1.1.0. The installed Flutter cache reports Flutter 3.41.9 and Dart 3.11.5. No tests, analyzer, or builds were run.

## 3. Exact proposed implementation scope

Only these two new files may be created under the proposed authorization:

| File | Purpose |
|---|---|
| `lib/models/transport_catalog.dart` | Immutable typed catalog/category/mode/capability values, registry, validation, alias-aware decoder, canonical encoder and unknown-mode preservation. |
| `test/transport_catalog_test.dart` | Isolated unit acceptance coverage for registry, validation, codec, version, labels, capabilities and no-availability boundary. |

No existing file may be edited. In particular, no imports or references are to be added to profile, itinerary, screens, services, Hive store, MO-GA, CARS, or circuit planning. No dependency changes are required or authorized by this scope.

## 4. Canonical registry and category hierarchy

Canonical identifiers are immutable lowercase snake_case values. The initial catalog contains exactly these twelve entries:

| Canonical ID | Display label | Category ID | Directed endpoints required | Initially active |
|---|---|---|---:|---:|
| `walking` | Walking | `land_non_motorized` | No | Yes |
| `bicycle` | Bicycle | `land_non_motorized` | No | Yes |
| `motorcycle` | Motorcycle | `land_motorized` | No | Yes |
| `car` | Car | `land_motorized` | No | Yes |
| `public_transportation` | Public transportation | `public_transport_local` | No | Yes |
| `jeepney` | Jeepney | `public_transport_local` | No | Yes |
| `tricycle` | Tricycle | `public_transport_local` | No | Yes |
| `multicab` | Multicab | `public_transport_local` | No | Yes |
| `van` | Van | `public_transport_local` | No | Yes |
| `bus` | Bus | `public_transport_local` | No | Yes |
| `ferry` | Ferry | `water_transfer` | Yes | Yes |
| `boat` | Boat | `water_transfer` | Yes | Yes |

Category parent map:

| Category ID | Parent ID |
|---|---|
| `land` | null |
| `land_non_motorized` | `land` |
| `land_motorized` | `land` |
| `public_transport` | null |
| `public_transport_local` | `public_transport` |
| `water` | null |
| `water_transfer` | `water` |

The maximum hierarchy depth is two edges from a root to a leaf. IDs must be unique, match `^[a-z][a-z0-9_]*$`, and references must exist. Category parents must be acyclic. Every mode must reference one category. Ferry and boat must reference `water_transfer` and require directed endpoints.

## 5. Field contract, capability policy, and codec behavior

The implementation should expose immutable value objects matching Task 33A:

| Type | Proposed fields |
|---|---|
| `TransportCatalog` | `schemaVersion: int`, `catalogVersion: int`, `categories: List<TransportCategory>`, `modes: List<TransportMode>` |
| `TransportCategory` | `id: String`, `labelKey: String`, `parentId: String?` |
| `TransportMode` | `id: String`, `categoryId: String`, `labelKey: String`, `isActive: bool`, `legacyAliases: List<String>`, `requiresDirectedEndpoints: bool`, `workflowCapabilities: WorkflowCapabilities` |
| `WorkflowCapabilities` | independent booleans `profilePreference`, `manualLegSelection`, `circuitPlanning`, `mogaRouteEvaluation`, `fixedCommitmentCapture` |
| Unsupported decoded value | preserve `rawId` exactly and optional `labelSnapshot`; do not map it to another mode |

Both versions are positive integers. Initial `schemaVersion` and `catalogVersion` are 1. Initial capabilities for all twelve entries are: profile preference enabled; manual leg selection/recording enabled; circuit transport evaluation disabled; MO-GA route evaluation disabled; fixed commitment capture enabled. These flags do not derive from `isActive` and do not indicate service availability. Inactive known entries remain decodable and preserved but cannot be offered as new selections.

Known exact, case-sensitive aliases are `public transportation` and `publicTransportation`, each decoding to `public_transportation`; the exact legacy lowercase IDs `walking`, `bicycle`, `motorcycle`, `car`, `ferry`, and `boat` decode to themselves. Encoding emits canonical IDs only. No implicit trimming, case folding, or unapproved substitution is allowed. Unknown values preserve raw ID and historical label snapshot byte/value-for-value through round trip.

Catalog identity is separate from service availability. The catalog must not create route evidence, availability, operators, schedules, fares, or travel durations. The future model may carry historical label snapshots, but this slice does not add route-time or commitment persistence.

## 6. Repository compatibility findings and risks

There is no current type/file naming collision. The primary risk is future integration drift: current profile and itinerary paths still use the legacy enum/string representations while the new catalog has canonical IDs. Because this proposed slice adds no consumers and does not edit Hive, these existing code paths remain behaviorally unchanged until a later separately authorized integration.

Other risks and controls:

- **Alias collisions:** validate that each alias maps to exactly one mode and collides with neither a canonical ID nor another alias.
- **Identifier evolution:** IDs are immutable; additions are append-only; retiring an entry sets inactive rather than reusing/removing its ID. Updates increment `catalogVersion`; shape changes increment `schemaVersion`.
- **Localization/history:** labels are represented by stable label keys in the catalog. Existing leg/commitment snapshot handling is out of scope; consumers must later preserve label snapshots as Task 33A specifies.
- **Capability confusion:** flags are independent booleans; tests must prove circuit/MO-GA false does not disable profile/manual/fixed capture.
- **Availability confusion:** no availability API or status belongs in this catalog. Membership is not proof of a route or service.
- **Serialization drift:** deterministic ordering/serialization and exact alias handling must be covered by tests. Do not make the catalog persistent as part of this task.
- **Working-tree contamination:** existing CARS modifications, untracked project documents, and manuscript files are present. They must not be staged, overwritten, reverted, or included in the proposed two-file change.

## 7. Future test acceptance matrix

Tests are specified for the separately authorized implementation; none were run during this review.

| Case | Required assertion |
|---|---|
| Canonical registry uniqueness | Exactly twelve unique mode IDs and seven unique category IDs; no duplicate aliases. |
| ID syntax | Valid lowercase snake_case accepted; invalid empty, uppercase, whitespace, punctuation or leading digit rejected. |
| Category references | Missing parent/category reference rejected. |
| Category topology | Cycles and depth greater than two rejected; expected hierarchy accepted. |
| Initial registry | IDs, labels/keys, categories, active state and endpoint flags match Section 4 exactly. |
| Legacy alias decode | Both public-transport aliases map to `public_transportation`; specified identity aliases decode exactly; near-miss/case variants stay unknown. |
| Canonical encode | Known modes always encode their canonical ID and never an alias. |
| Unknown round trip | Unknown raw identifier and optional historical label survive encode/decode unchanged and remain unsupported. |
| Inactive mode | Known inactive mode decodes and round-trips; is not selectable as a new choice; capability flags remain unchanged. |
| Independent capabilities | Each capability is asserted independently for all initial entries; activity does not rewrite flags. |
| Historical label | Snapshot survives catalog label change while ID remains stable. |
| Version determinism | Same catalog serializes identically; unsupported/nonpositive version input is rejected; registry update increments catalog version by explicit definition. |
| Invalid definitions | Duplicate IDs/aliases, malformed IDs, blank labels, dangling references, invalid water endpoint flag/category and cycles are rejected. |
| Availability boundary | Catalog lookup alone produces no route-evidence object and cannot report a route as available or verified. |
| Serialization stability | Round-trip preserves all typed fields, version, active state, flags, aliases, unknown values and deterministic collection order. |

Use the existing `flutter_test` conventions in one isolated test file. No widget, Supabase, Hive, network or platform fixtures should be needed.

## 8. Explicit exclusions

The proposed two-file implementation authorization must exclude:

- Existing UI/screens, profile service, itinerary model, or any existing source/test edits.
- Hive serialization, format versions, migrations, persistence or local user data.
- MO-GA, CARS, manual/circuit planner behavior or route evaluation.
- Supabase, SQL, database schema, network services, live availability, deployment or initialization.
- Application integration or migration of existing values in stored records.
- Any third file, dependency update, generated file or unrelated formatting change.

Any scope expansion requires a fresh, explicit authorization and its own compatibility/test plan.

## 9. Rollback and isolation

If a separately authorized implementation fails review, rollback is limited to deleting only the two newly added files: `lib/models/transport_catalog.dart` and `test/transport_catalog_test.dart`. Since no existing consumer, persisted data, dependency, or database object changes, there is no data rollback or migration step. Before any rollback, verify each target is one of the task-created files and contains no unrelated user work. Do not revert or clean the rest of the working tree.

## 10. Authorization checklist

| Check | Result |
|---|---|
| Task 33A transportation contract reviewed | Pass |
| Twelve identifiers verified against Task 33A | Pass |
| Category hierarchy verified | Pass |
| Alias mappings verified | Pass |
| Capability flags verified | Pass |
| Existing model, codec and test conventions inspected | Pass; no catalog type/file found |
| Dart/Flutter constraints and resolved Hive versions inspected | Pass: Dart 3.11.5, Flutter 3.41.9; Hive 2.2.3, hive_flutter 1.1.0 |
| Exact two-file future scope confirmed | Pass |
| Acceptance tests defined | Pass; not executed |
| Rollback procedure documented | Pass |
| Existing working-tree changes protected | Pass; observed unrelated modifications remain untouched |
| Unresolved blocker affecting isolated implementation | None identified within this two-file, non-integrated scope; owner authorization is still required |

## 11. Final recommendation

**B â€” Ready for owner authorization with clearly stated conditions.** The contract and isolated test plan are specific enough to request owner authorization for exactly the two new files. Keep all integration, persistence, routing, database, network, and deployment work excluded. Do not proceed until a separate explicit authorization is received; this review is not that authorization.

**Task 34 is an authorization review only. No coding authorization has been granted.**

## 12. Validation and closeout

- `git diff --check` completed successfully for whitespace; Git emitted existing LF-to-CRLF working-copy warnings for unrelated modified files. No whitespace errors were reported.
- New document whitespace was inspected as part of the diff check.
- No tests, analyzer, build, SQL, migration, Hive operation, database operation, or Supabase access was performed.
- Only this requested review document was created; no existing source, test, or document was edited.
