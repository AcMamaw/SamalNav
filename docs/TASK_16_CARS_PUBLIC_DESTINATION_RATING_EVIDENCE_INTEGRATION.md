# Task 16 — CARS Public Destination Rating Evidence Integration

**Status:** Evidence-handling improvement implemented; authoritative production rating source remains unverified. No rating normalization or CARS scoring policy was introduced.

## Existing rating architecture and source findings

- `DestinationService.getAll()` loads active `destinations` records using `.select()` and parses rating-related fields from each destination row. Its bundled fallback records are marked `DestinationRecordSource.fallback` and are not valid public-rating evidence.
- `DestinationRecord` retains a parsed rating, explicit verification state, source label, retrieval time, and freshness deadline. The rating parser accepts a finite 0–5 value; missing, malformed, non-finite, and out-of-range values do not become numeric ratings.
- The CARS preparation layer validates the rating range, verification marker, database-versus-fallback origin, nonempty source, retrieval timestamp, freshness deadline, future retrieval, and staleness. It retains the `DestinationRecord` as evidence. With no approved scoring formula, the rating criterion's numeric score remains null.
- `PreparedCarsRecommendationProvider` already prepares and carries per-destination criterion evidence into the recommendation package. The Task 13 review screen already displays evidence status, source, retrieval time, and freshness deadline.
- `EstablishmentService.getReviews(establishmentId)` reads `reviews` filtered by `establishment_id`; its average is an establishment review aggregate. No tourist-facing CARS destination-rating query or configured external rating-provider adapter was found. Static sample reviews in `lib/models/review.dart` are not a verified live source.

### Schema evidence limitation

The checked-in historical `supabase/backup/schema.sql` defines `destinations.rating` and `destinations.rating_average` with `DEFAULT 0 NOT NULL`; its `reviews` table has `destination_id`, `establishment_id`, and `stars`. That artifact does not establish the deployed schema. In the inspected backup, rating verification/source/retrieval/freshness fields are not present. No Supabase project was accessed, so current production columns, values, source semantics, destination-review aggregation, and freshness policy remain unverified. A default zero cannot establish that a destination received an actual zero rating.

## Changes made

- Tightened `DestinationRecord.availableRating`: it now exposes a public rating only when the record is database-sourced, the value is finite and within 0–5, verification is explicitly true, source and both timestamps are present, retrieval is not in the future, and freshness has not expired. A verified-looking value without provenance is preserved in the model but is not displayed by consumers using this getter.
- Extended the CARS review evidence row to show a currently available raw rating value as “Verified rating evidence: …/5 (not a CARS score).” Unavailable values remain represented by the existing status and explanation. No score is derived.
- Added regression coverage for provenance-free values, stale/future evidence, verified zero with and without source metadata, CARS no-score behavior, provider evidence propagation, and tourist review presentation.

## Evidence-state behavior

| Case | Handling |
|---|---|
| Valid, explicitly verified, provenance-complete and fresh value | Retained as available evidence; shown as rating evidence, never as a CARS score. |
| Verified zero with source and fresh timestamps | Retained as an actual zero value, distinct from missing; no CARS score is produced. |
| Zero without source/freshness or verification | Not treated as verified public evidence; CARS reports insufficient data and leaves score null. |
| Missing value | Unavailable; no zero substitution. |
| Malformed, non-finite, negative, or above 5 | Invalid; no score. |
| Numeric but unverified | Preserved as raw model data but not made available to public rating consumers or CARS scoring. |
| Missing source/timestamps | Insufficient provenance; no score/display as available. |
| Future retrieval time | Invalid for CARS; unavailable to public display. |
| Expired freshness deadline | Stale for CARS and unavailable to public display. |
| Bundled fallback value | Unsupported as public rating evidence. |

The evidence is attached to the destination row supplied by the injectable CARS source, so its destination identity remains the record's `id`. No separate rating-record retrieval exists in the application to test duplicate rating rows or a foreign destination association. Provider-level duplicate destination identities continue to fail closed. Adding a rating-record source requires an authoritative source contract, identity/join definition, and duplicate-resolution policy first.

## Files changed

- `lib/models/destination_record.dart`
- `lib/screens/tourist_screens/cars_recommendation_review_page.dart`
- `test/destination_record_test.dart`
- `test/cars_assessment_input_preparer_test.dart`
- `test/cars_recommendation_provider_test.dart`
- `test/cars_recommendation_review_page_test.dart`
- `docs/TASK_16_CARS_PUBLIC_DESTINATION_RATING_EVIDENCE_INTEGRATION.md`

## Validation

- Focused tests: **45 passed** across destination records/service, CARS assessment preparation, recommendation provider, and recommendation review-screen tests.
- Full `flutter test --no-pub`: **210 passed**.
- `flutter analyze --no-pub`: **exit 1** with four informational `curly_braces_in_flow_control_structures` findings in pre-existing `lib/services/establishment_dashboard.dart` at lines 180, 376, 537, and 691. No diagnostics were reported in Task 16 files.
- `dart format` applied to changed Dart files.
- `git diff --check`: passed; Git printed only existing LF-to-CRLF working-copy notices.

Tests use synthetic local fixtures. No query was executed and neither Supabase project was accessed. No database, SQL, migration, schema, production data, credential, or scoring-policy change was made.

## Readiness and next dependency

Rating evidence is ready to pass through the existing CARS preparation/provider/review boundary when supplied with complete metadata. It is **not ready for production scoring**: the authority and semantics behind `rating_is_verified`, rating source, actual-zero handling, scale, freshness rule, aggregation population, and current deployed fields have not been verified. The local backup's default-zero fields make this especially important. The production provider remains unavailable; no live recommendation is claimed.

**Recommended next task:** obtain and review a sanitized, owner-supplied authoritative rating-source contract and current schema evidence for the deployed destination/review fields. Only then decide whether an injectable destination-rating source adapter is justified. A separate approved scoring policy is still required before any numeric CARS rating score can be produced.
