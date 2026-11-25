# Task 14 — CARS Core Engine Methodology Alignment and Validation

**Project:** SamalNav

**Branch:** `secondtemppush`

**Status:** Existing score contract centralized and validated; original methodology verification remains blocked because its source was not found.

## 1. Methodology verification

The repository contains the six criterion weights in Tasks 06–12, but those files are decision/readiness records, not the original approved research methodology. The Task 11 record says owner decisions remain unanswered. A repository search found no original methodology source that substantiates the weights or resolves the intended score scale.

The six documented weights remain **unverified**:

| Criterion | Documented weight | Verification status |
|---|---:|---|
| Tourist preference / interest and activity match | 0.1548 | Unverified against original source |
| Public destination rating | 0.1718 | Unverified against original source |
| Weather suitability | 0.1695 | Unverified against original source |
| Budget compatibility | 0.1785 | Unverified against original source |
| Travel distance suitability | 0.1627 | Unverified against original source |
| Available travel time compatibility | 0.1627 | Unverified against original source |
| **Total** | **1.0000** | Arithmetic sum only; not source verification |

The engine accepts an injected map containing exactly the six criteria and weights summing to one; it does not hard-code these survey values. Existing CARS unit tests deliberately use synthetic weights and do not establish the production weight set.

The original methodology was also unavailable to confirm 0–1 versus 0–100. No scale migration was made. The existing runtime is consistently 0–100: UI labels, engine validation/calculation, and the optional scoring-policy boundary all used that range.

## 2. Changes made

Added `CarsScoreContract` to `cars_models.dart` as the single definition of the current inclusive finite score range (0–100). The engine and scoring-policy applier now use its validator; the review screen obtains its `/100` display maximum from the same contract. This centralizes current behavior and does not approve it as the final research-methodology scale.

Added synthetic mathematical checks for the existing weighted-sum implementation. With test weights `0.25, 0.20, 0.15, 0.15, 0.15, 0.10` and scores `100, 50, 0, 80, 20, 40`, expected contributions are `25, 10, 0, 12, 3, 4`; the total is `54 / 100`. These test weights are not the survey weights.

Tests also verify supplied zero remains a valid numeric score, all-zero and all-maximum inputs yield totals of 0 and 100, and the policy boundary accepts both endpoints. Existing tests verify missing remains null, incomplete candidates are excluded without reweighting, ineligible candidates are separated from score outcomes, invalid values are rejected, and ranking ties are deterministic by destination ID.

No criterion-specific formula, threshold, evidence source, eligibility rule, production weight, or MO-GA behavior was added or changed. The assessment preparer continues to preserve unsupported/unavailable evidence as unscored.

## 3. Files changed

- `lib/models/cars_models.dart` — shared current score contract and model documentation.
- `lib/algorithms/cars_engine.dart` — uses the shared contract for score validation and result scale text.
- `lib/algorithms/cars_assessment_input_preparer.dart` — uses the same contract for injected policy output validation.
- `lib/screens/tourist_screens/cars_recommendation_review_page.dart` — obtains score scale label from the shared contract; also retains Task 13 evidence-review changes.
- `test/cars_engine_test.dart` — hand-calculated six-criterion contribution/total and numeric endpoint tests.
- `test/cars_assessment_input_preparer_test.dart` — injected-policy score endpoint test.
- `test/system_generated_planning_page_test.dart` and `lib/screens/tourist_screens/system_generated_planning_page.dart` — pre-existing Task 13 evidence handoff changes remain in the working tree; the widget test passed in final validation.
- `docs/TASK_14_CARS_CORE_ENGINE_METHODOLOGY_ALIGNMENT_AND_VALIDATION.md` — this report.

All pre-existing untracked Task 06–13 documents were preserved.

## 4. Validation results

- Focused engine, assessment-preparer and provider tests: **37 passed**.
- System-generated planning widget tests: **9 passed** after correcting a test scroll setup that initially attempted to tap an off-screen evidence tile.
- Full `flutter test --no-pub`: **196 passed**.
- Dart formatting: ran `dart format` on all eight modified Dart files; a final `--output=none --set-exit-if-changed` check reported **0 files requiring formatting** (exit 0).
- `flutter analyze --no-pub`: **exit code 1**, with four informational `curly_braces_in_flow_control_structures` findings in existing `lib/services/establishment_dashboard.dart` at lines 180, 376, 537, and 691. No diagnostic was reported in the files changed for Task 14. Those unrelated findings were not modified.
- `git diff --check`: passed. Whitespace scan of Task 14's changed source, tests, and report: passed.
- Flutter initially appeared stalled because the CLI could not acquire the SDK lock under `C:\flutter`. Validation completed by invoking the installed Flutter tool snapshot with reviewed local execution access. No unrelated Dart processes were terminated.

## 5. Remaining blockers and limitations

1. Supply the original approved methodology or research record and owner confirmation before treating the six documented weights as verified.
2. Confirm the score scale from that methodology. The code currently has one internally consistent 0–100 runtime contract, but this does not settle the research decision.
3. The engine still accepts injected weights; no production weight source/configuration is established by this task.
4. Production numeric recommendations remain unavailable because criterion-specific scoring policies and verified data-source contracts remain unresolved. The test-only policy fixtures do not represent production recommendations.
5. The analyzer remains non-clean due to four unrelated informational findings listed above.

No Supabase project was accessed, no SQL was executed, and no database, Auth, migration, credential, or production configuration was changed.

## 6. Recommended next task

Obtain and record the original methodology and explicit owner decisions for the weight set and score scale. Reassess only those decisions against that source before authorizing any scoring-policy implementation; preserve the current 0–100 runtime contract until then.
