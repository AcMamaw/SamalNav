# Task 13 — CARS Methodology-Based Implementation

**Branch:** `secondtemppush`

**Implementation status:** A bounded evidence handoff to the tourist review screen is implemented. Numeric CARS policy and production recommendation generation remain unavailable where the required methodology, owner decisions, or verified sources are absent.

## 1. Methodology and decision basis

Tasks 06–12 consistently record the following six criteria and weights as the target baseline:

| Criterion | Weight |
|---|---:|
| Tourist preference / interest and activity match | 0.1548 |
| Public destination rating | 0.1718 |
| Weather suitability | 0.1695 |
| Budget compatibility | 0.1785 |
| Travel distance suitability | 0.1627 |
| Available travel time compatibility | 0.1627 |
| **Total** | **1.0000** |

These repository records are not the original approved research methodology or a completed owner approval. Accordingly, the weights are preserved without alteration, but could not be independently verified against the original methodology. The proposed 0–1 scale also remains unverified. The existing engine's 0–100 contract, score validation, weighting, eligibility separation, and missing-score behavior were not changed.

## 2. Existing implementation reviewed

Reviewed the existing CARS engine and models, typed assessment preparer, injectable recommendation provider, destination and profile adapters, criterion assessment boundaries, system-generated planning entry point, recommendation review screen, MO-GA handoff, and related tests.

The provider package already carries a destination-keyed `CarsPreparedAssessmentInputs` map. The system-generated planning screen previously forwarded only ranking, destination records, trip configuration, and run reference, dropping prepared criterion states and explanations before tourist review. The review screen displayed scores and engine explanations but not the separate input-state evidence.

## 3. Implemented feature

The system-generated workflow now forwards the provider's existing prepared-assessment map into `CarsRecommendationReviewPage`. Each ranked or excluded candidate with supplied assessment inputs can expand a **Criterion evidence and availability** section. It presents the typed input state, source assessment explanation, optional scoring-rule reference, and whether a numeric criterion score was supplied. For evidence types that already retain provenance, the screen displays limited metadata:

- Verified destination rating source, retrieval time, and freshness deadline.
- Weather forecast provider, requested date range, retrieval time, and coverage state.
- Travel assessment route sources, retrieval times, and limitations.
- Budget assessment currency and explicitly missing information.
- Matched activity identifiers when present.

The screen does not infer provenance fields that the evidence model does not retain. It does not expose raw weather observations or cost line items. Existing score display, destination selection, day assignment, draft creation, and explicit MO-GA action are unchanged. Manual and circuit-based planning are unaffected.

This evidence handoff is not a profile snapshot or persistence feature. It carries provider-prepared evidence through the current recommendation review only. It does not make CARS recommendations live or make current raw assessments into numeric scores.

## 4. Files changed

- `lib/screens/tourist_screens/system_generated_planning_page.dart` — forwards `package.assessmentInputs` to the review screen.
- `lib/screens/tourist_screens/cars_recommendation_review_page.dart` — accepts optional assessment inputs and shows per-criterion states, explanations, rule references, and available provenance metadata for ranked and excluded results.
- `test/system_generated_planning_page_test.dart` — synthetic provider fixture and UI assertions for the evidence handoff.
- `docs/TASK_13_CARS_METHODOLOGY_BASED_IMPLEMENTATION.md` — this required implementation record.

Existing untracked Task 06–12 documents were preserved and not edited.

## 5. Criterion implementation status

| Criterion | Current state in this implementation | Numeric production score |
|---|---|---|
| Interest/activity | Typed match evidence/status can be carried and explained; authoritative taxonomy and approved scoring rule remain absent. | Unavailable |
| Public rating | Existing parser/provenance checks remain; no approved normalization or confirmed authoritative production source. | Unavailable |
| Weather | Raw forecast evidence can retain provider, period, retrieval and coverage metadata; no approved suitability classifier. | Unavailable |
| Budget | Existing assessment can state completeness, currency and missing cost information; no approved allocation/score rule or verified complete cost source. | Unavailable |
| Distance | Existing travel assessment can state route provenance, timing, and limitations; no approved distance score rule or configured verified route provider. | Unavailable |
| Available time | Existing raw route-time assessment and limitations remain; no approved candidate allocation or complete visit/transfer duration rule. | Unavailable |

The existing prepared-input and scoring-policy boundary still rejects unsupported/unscoreable evidence and leaves absent scores null. No new formulas, thresholds, weights, defaults, or eligibility rules were added. No criterion score was generated by this change.

## 6. Validation

- Repository branch inspected as `secondtemppush`.
- Initial and final working-tree review preserved the pre-existing untracked Task 06–12 documents.
- `git diff --check`: passed for the tracked code/test diff. The report is a newly created file and contains no whitespace errors on visual review.
- Focused Flutter tests: **not completed**. `flutter test --no-pub` stalled without producing startup or test output.
- Full Flutter test suite: **not run to completion** for the same SDK stall.
- `flutter analyze --no-pub`: **not completed**. The command stalled for 15 seconds without output; `flutter --version` and `dart --version` also stalled. No analyzer result is claimed.
- Formatting: **not verified** because `dart format` stalled without output.
- No Supabase project was accessed; no SQL was executed; no schema, migration, database, credentials, or production configuration was changed.

## 7. Remaining blockers and limitations

- The original approved research methodology and source record for the weights were not present among the reviewed Task 06–12 repository records; owner approval remains unanswered in Task 11.
- The 0–1 target is not verified against that methodology; current implementation stays on its existing 0–100 contract.
- All six criterion-specific production scoring rules and data-source contracts remain unresolved as summarized in Tasks 06–12. The default recommendation provider therefore remains unavailable, and no live ranking is claimed.
- Rating evidence has source/freshness fields, weather has provider/retrieval/coverage fields, and travel assessments retain source/retrieval/limitations; budget assessments and activity matches do not carry complete source/version/freshness metadata. The screen shows only information actually present.
- Prepared evidence is not persisted into the resulting itinerary draft. Profile confirmation details are not a saved snapshot in this result contract.
- Test and analyzer validation must be rerun when the local Flutter/Dart SDK responds normally.

## 8. Recommended next development task

After Flutter tooling is available, rerun the focused and full test suites, formatting, and analysis for this change. Separately, obtain the original methodology and explicit owner decisions before implementing any numeric CARS scoring policy or changing the score scale.
