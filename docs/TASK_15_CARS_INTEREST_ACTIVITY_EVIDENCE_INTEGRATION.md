# Task 15 — CARS Interest and Activity Evidence Integration

**Project:** SAMAL NAV  
**Branch:** `secondtemppush`  
**Status:** Safe evidence handling and review handoff strengthened. Live activity retrieval and production matching remain blocked by the absence of an authoritative preference-to-activity relationship. No numeric interest score was introduced.

## 1. Repository evidence and relationship assessment

Repository inspection found the following:

| Record | Representation observed | What it establishes / limitation |
|---|---|---|
| Tourist preferences | `tourist_details.preferred_categories` is a `text[]` in the checked-in historical `supabase/backup/schema.sql`; `TouristPlanningProfile` parses a nullable list of strings. | The profile service sets `preferencesConfirmed: false` because no confirmation field is part of its current data contract. A stored value is therefore not sufficient to treat preferences as confirmed. The backup is not proof of deployed schema. |
| Destinations | `DestinationRecord` contains `id`, nullable UUID `categoryId`, and a separate display `category`. The historical backup relates `destinations.category_id` to `categories.id`. | Destination category UUIDs and display labels are not evidence of an activity or preference mapping. |
| Activities | The historical backup defines `activities.id` (UUID), `destination_id` (UUID), `category` (text), and `is_active`; its category is constrained to text values such as `water_sport`, `cultural`, and `nature`. `destination_id` relates an activity to a destination. | The activity category is not a category UUID and has no shown FK to `categories` or the preference values. No authoritative relationship from `preferred_categories` to `activities.category` or activity IDs was found. This historical backup does not establish current deployed definitions or records. |
| Application retrieval | No Dart activity catalog/service query was found. `DestinationService` loads destinations and may fall back to bundled records. | The app has no verified activity retrieval adapter for this evidence, and fallback destinations cannot be treated as live activity evidence. |

The repository therefore does **not** establish an authoritative identifier-based mapping for CARS. Matching by label, enum name, UUID resemblance, or a hand-authored alias would invent taxonomy and was not added. No Supabase project was accessed.

## 2. Changes made

- Extended `CarsInterestActivityMatchAssessment` to preserve optional mapping source/version and activity source/retrieval/freshness metadata.
- Added explicit assessment states for incomplete relationships, duplicate IDs, inactive records, stale evidence, and invalid activity identifiers. The matcher rejects these conditions before reporting a match or verified non-match.
- Kept the matching rule exact-ID-only. Multiple preferences and activities are compared as sets, so a preference matching multiple activities is counted once in the evidence result.
- Updated the assessment preparer to map the new states to unavailable, insufficient, stale, or invalid inputs. Those states remain unscoreable even when a test-only scoring policy is injected.
- Updated the existing review evidence display to show source/version and activity retrieval/freshness metadata when supplied. Task 13’s existing provider-package-to-review handoff is reused.
- Added matcher, preparer, and provider regression tests. The provider test confirms evidence metadata survives into its review package without creating an interest score; empty source results stay empty and source errors propagate to the existing workflow error handling.

No concrete database activity adapter was added: the observed records do not supply the authoritative relationship required to implement one safely. The existing injectable `CarsRecommendationAssessmentSource` remains the integration boundary and can supply an assessment only when a future verified adapter has sufficient evidence. The tourist planning flow’s production default remains `UnavailableCarsRecommendationProvider`.

## 3. Evidence-state behavior

| Evidence condition | Matcher result | Numeric criterion score |
|---|---|---|
| No selected preferences | `noPreferenceSelected` | None; preparer marks not applicable, not a positive match or zero |
| Mapping unavailable/unreviewed | `mappingUnavailable` | None |
| Unknown preference ID | `unsupportedPreferenceIdentifiers` | None |
| Missing activity records | `activityCategoriesUnavailable` | None |
| Incomplete activity/category relationships | `activityRelationshipsIncomplete` | None; cannot be labeled a verified non-match |
| Duplicate activity identifiers | `duplicateActivityIdentifiers` | None; invalid input |
| Invalid activity identifiers | `invalidActivityEvidence` | None; invalid input |
| Inactive activity records without an approved applicability rule | `inactiveActivityRecords` | None; insufficient data, not silently included or discarded |
| Expired activity evidence | `staleActivityEvidence` | None |
| Complete authoritative exact-ID overlap | `matched` | None; evidence only |
| Complete authoritative exact-ID non-overlap | `noMatch` | None; evidence only |
| Unconfirmed profile preference | Existing preparer behavior | None; insufficient data |

Metadata is retained when its source provides it. Absence of a production catalog or mapping is not converted into a non-match. The feature does not define or apply a preference-match ratio or any other criterion scoring rule.

## 4. Files changed for Task 15

- `lib/algorithms/cars_interest_activity_matcher.dart`
- `lib/algorithms/cars_assessment_input_preparer.dart`
- `lib/screens/tourist_screens/cars_recommendation_review_page.dart`
- `test/cars_interest_activity_matcher_test.dart`
- `test/cars_assessment_input_preparer_test.dart`
- `test/cars_recommendation_provider_test.dart`
- `test/cars_recommendation_review_page_test.dart`
- `docs/TASK_15_CARS_INTEREST_ACTIVITY_EVIDENCE_INTEGRATION.md`

Existing Task 06–14 documents and other working-tree changes were preserved. No database, SQL, migration, schema, credential, or production configuration change was made.

## 5. Validation

Validation commands were run using the installed Flutter tool snapshot because the SDK lockfile under `C:\flutter` is outside the writable workspace:

- Focused interest matcher, assessment preparer, recommendation provider, CARS review, and system-generated planning tests: **45 passed**.
- Full `flutter test --no-pub`: **204 passed**.
- `flutter analyze --no-pub`: **exit 1**, with four informational `curly_braces_in_flow_control_structures` findings in existing `lib/services/establishment_dashboard.dart` at lines 180, 376, 537, and 691. No Task 15 file was reported.
- `dart format --output=none --set-exit-if-changed` on the six Task 15 Dart files: **exit 0; zero files needed formatting**.
- `git diff --check`: **passed** (Git emitted line-ending normalization warnings for existing modified working-tree files; no whitespace errors).

## 6. Remaining limitations and next dependency

The criterion is **not ready for production evidence retrieval or future scoring-policy integration**. Required inputs still missing are:

1. A verified deployed activity source contract and completeness semantics, including how inactive activities apply to a visit.
2. An authoritative, versioned mapping from saved preference identifiers to activity identifiers/categories.
3. An explicit source contract for preference confirmation; current profile service reports saved preferences as unconfirmed.
4. Source identity, retrieval time, freshness rules, and verified destination-to-activity coverage for the activity catalog.
5. Separate approval of a numeric CARS scoring rule; Task 15 intentionally supplies none.

The next useful task is to obtain owner-reviewed schema/data evidence for the preference taxonomy and activity-category relationship, then implement a concrete adapter only if that evidence establishes a complete, authoritative join. Until then, keep this criterion unscored and keep production recommendations unavailable.
