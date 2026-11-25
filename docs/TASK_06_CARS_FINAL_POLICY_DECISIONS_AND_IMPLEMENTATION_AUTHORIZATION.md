# Task 06 — CARS Final Policy Decisions and Implementation Authorization

**Status:** Final policy decision record for review. This document makes no source, test, configuration, database, or Supabase changes. It does not authorize implementation while essential rules and data contracts remain unresolved.

## 1. Executive decision

The six CARS criteria and their survey weights are confirmed for this specification. The 0–1 scale and explicit six-term weighted formula are also adopted as the target contract. This target conflicts with the current engine's 0–100 contract and therefore is not yet active behavior.

The repository has safe architectural boundaries: typed evidence preparation, injectable assessment source and scoring policy, eligibility separate from ranking, missing-score rejection, and an unavailable default provider. It does not contain approved numeric policies for the six criteria or verified source contracts sufficient to produce live recommendations. No production scoring is authorized by this document.

**Implementation readiness: BLOCKED.** Weather classification, budget and time allocation, distance normalization, not-applicable handling, eligibility vocabulary, verified water routes, and source completeness require decisions or evidence before numeric policy implementation. Preserve the unavailable/no-fabricated-score behavior until these gates pass.

## 2. Decision register

Status labels mean: **FINALIZED** = fixed project-level contract; **PROPOSED FOR OWNER APPROVAL** = concrete option awaiting explicit approval; **REQUIRES EXTERNAL DATA** = policy may be defined, but scoring depends on sourced evidence; **BLOCKED BY MISSING INFORMATION** = required decision or contract is absent. A decision may have more than one status.

| ID | Decision | Status | Resolution and remaining action |
|---|---|---|---|
| D-01 | Six criteria and survey weights | **FINALIZED** | Preserve the six criteria and exact weights in Section 3. Confirm provenance of the survey record before implementing the production configuration. |
| D-02 | Score scale and total formula | **FINALIZED** (target); current implementation mismatch | Target scores and total are finite values in [0,1]; use all six weighted terms. Engine/UI currently use [0,100]. Approve a coordinated contract migration before changing code. |
| D-03 | Interest/activity match | **BLOCKED BY MISSING INFORMATION** | Use exact authoritative category identifiers only. No selected preference is not an assumed match; the score cannot be finalized until not-applicable policy is resolved. Confirm the authoritative taxonomy and whether no preference blocks ranking. |
| D-04 | Public rating | **PROPOSED FOR OWNER APPROVAL**, **REQUIRES EXTERNAL DATA** | Proposed `score = verifiedRating / 5` for an authoritative current 0–5 rating. Approve scale, source authority, and freshness limit; current provenance must meet them. |
| D-05 | Weather suitability | **BLOCKED BY MISSING INFORMATION**, **REQUIRES EXTERNAL DATA** | Requires verified activity-weather requirements, supported forecast evidence and coverage, approved classifier thresholds, aggregation, freshness, and normalization. None are invented here. |
| D-06 | Budget compatibility | **PROPOSED FOR OWNER APPROVAL**, **BLOCKED BY MISSING INFORMATION**, **REQUIRES EXTERNAL DATA** | Proposed reciprocal formula in Section 4. Approve the candidate-level allocation from overall budget, zero-budget behavior, applicable cost components, group/pricing semantics, and source/freshness contract. |
| D-07 | Distance suitability | **BLOCKED BY MISSING INFORMATION**, **REQUIRES EXTERNAL DATA** | Approve distance measure and normalization per supported mode and how a selected mode context is supplied. No limit, decay function, or mode choice is inferred. |
| D-08 | Available travel time | **PROPOSED FOR OWNER APPROVAL**, **BLOCKED BY MISSING INFORMATION**, **REQUIRES EXTERNAL DATA** | Proposed reciprocal formula in Section 4. Approve candidate-level time allocation, duration scope, and treatment of over-allowance destinations. Visit duration is not currently included in route assessment. |
| D-09 | GPS-default origin with manual fallback | **BLOCKED BY MISSING INFORMATION** | User instruction establishes the desired policy, but current `TripOrigin` comments say live GPS is not modeled and travel assessment uses the selected trip origin. Define permission denial, unavailable GPS, consent, and origin provenance behavior before integration. |
| D-10 | Whole-trip or per-leg mode | **FINALIZED** (user policy); **BLOCKED BY MISSING INFORMATION** (contract) | User may select a whole-trip mode or explicit modes per leg; MO-GA may recommend feasible arrangements when mode is not fixed. Current `TripConfiguration` has one nullable `travelMode`, not a per-leg mode representation. Define the typed input contract. CARS must not select a best mode. |
| D-11 | Verified water transport | **FINALIZED** (separate from road); **REQUIRES EXTERNAL DATA** | A verified connection, source, relevant schedule/date, mode/transfer identity, and supported duration are needed. No road or straight-line substitute and no invented ferry data. |
| D-12 | Eligibility and traveler suitability | **BLOCKED BY MISSING INFORMATION** | Keep separate from score. Establish authoritative dataset presence, approval/accreditation values, and traveler requirement semantics. Existing evaluator takes caller-provided status sets; this does not establish canonical production values. |
| D-13 | Mixed-group requirements | **FINALIZED** (counts must be accounted for when price basis requires); **BLOCKED BY MISSING INFORMATION** (source contract) | Current trip model has total group, children, elders and derives adults; confirm reliable population and price eligibility rules per group type. Do not infer child/elder discounts or per-person applicability. |
| D-14 | Not-applicable criteria | **BLOCKED BY MISSING INFORMATION** | Alternatives: (a) treat not-applicable as blocking under all-six-required policy; (b) approve a fixed, non-redistributing treatment that preserves the six-term formula; or (c) define a specific approved applicability domain. Explicitly reject silent weight redistribution. Owner must select and define behavior. |
| D-15 | Evidence state semantics | **FINALIZED** | Distinguish missing, invalid, stale, unsupported, not applicable, and verified zero. Only valid, fresh, supported evidence with an approved rule may produce a number. No default zero or favorable substitution. |
| D-16 | Candidate return-to-origin | **FINALIZED** (user policy); **BLOCKED BY MISSING INFORMATION** (model) | Tourist chooses whether to return to origin. Represent explicitly for MO-GA; it does not make CARS a route optimizer. Current inspected `TripConfiguration` has no return-to-origin field. |

## 3. Criteria, weights, and target contract

| Criterion | Symbol | Weight |
|---|---:|---:|
| Tourist preference / interest and activity match | (S_1) | 0.1548 |
| Public destination rating | (S_2) | 0.1718 |
| Weather suitability | (S_3) | 0.1695 |
| Budget compatibility | (S_4) | 0.1785 |
| Travel distance suitability | (S_5) | 0.1627 |
| Available travel time compatibility | (S_6) | 0.1627 |

The weights sum to 1.0000. For an eligible destination with six valid applicable scores:

\[
RS(d)=0.1548S_1(d)+0.1718S_2(d)+0.1695S_3(d)+0.1785S_4(d)+0.1627S_5(d)+0.1627S_6(d)
\]

Every (S_i(d)) and (RS(d)) must be finite and in [0,1]. Validate exactly six weights, finite nonnegative values, and sum to one within the implementation's documented numeric tolerance. Do not renormalize scores or weights. Eligibility is evaluated separately. No numeric rank is produced when required evidence or an applicable score is absent.

## 4. Criterion policies

The formulas below are proposed decisions only where identified. None may be activated without the approvals and source conditions in the decision register.

### 4.1 Interest/activity match

Use confirmed selected preference identifiers (P), authoritative mapping (M), and verified destination activity identifiers (A_d):

\[
S_1(d)=\frac{\sum_{p\in P}\mathbf{1}[M(p)\cap A_d\ne\varnothing]}{|P|}
\]

Only exact supported identifiers qualify. Unknown mappings are unsupported; missing activity categories or mapping source is unavailable. Unconfirmed preferences are insufficient. When (P) is empty, the criterion is not applicable—not a perfect match or zero—but the consequence for the six-term ranking is blocked by D-14.

### 4.2 Public rating

Proposed normalization for an authoritative verified rating (R_d\in[0,5]):

\[
S_2(d)=R_d/5
\]

Examples: 0 → 0, 2.5 → 0.5, and 5 → 1. A verified zero is a valid rating. Missing, malformed, out-of-range, unverified, stale, or fallback-only data are not scoreable. Require source, retrieval time, and approved freshness policy. The 0–5 range and source authority require approval/evidence; the repository parser's accepted shape does not establish a trusted external rating contract.

### 4.3 Weather

No numeric classification threshold is approved. A future policy must connect destination activities to verified weather requirements, evaluate provider evidence for the relevant location and itinerary date/time coverage, apply an approved classifier and aggregation rule, then map the result to [0,1]. Preserve units, source, observation/forecast timestamps, retrieval time, and coverage. Partial, stale, unsupported, or absent evidence is not favorable. Raw OpenWeatherMap forecasts are not scores.

### 4.4 Budget

Proposed reciprocal score:

\[
S_4(d)=\frac{1}{1+C_d/B_d}
\]

where (C_d\ge0) is a verified supported estimate for this candidate destination, and (B_d>0) is an approved candidate-level budget allocation derived from the tourist's overall budget. Examples: (C_d=0\Rightarrow1); (C_d=0.5B_d\Rightarrow2/3); (C_d=B_d\Rightarrow0.5); (C_d=2B_d\Rightarrow1/3). This is monotone decreasing in cost and gives exact-budget spend a nonzero score.

Task 04 compared the linear remaining-budget formula (\max(0,1-C_d/B_d)), which scores exact budget zero, and exponential decay (e^{-\lambda C_d/B_d}), which requires an approved (\lambda). The reciprocal form is recommended for owner approval; no formula is active yet.

The candidate allocation rule must explicitly consume budget basis (total-group or per-person), group composition, trip context, and supported cost requirements. Include entrance, activity, transport, food, or accommodation only when the item is actually required and its amount, currency, unit, verification, source, and freshness are reliable. Deduplicate included package components. Do not combine currencies without verified conversion. A zero candidate budget requires an approved rule; it cannot be divided by or treated as an assumed affordability result. The current cost assessor can assess item evidence and group counts but does not supply the proposed CARS normalization/allocation policy.

### 4.5 Distance

No scoring formula is finalized. A mode-conditioned function (S_5=f(D_{d,m};\theta_m)) requires owner-approved distance evidence type and normalization. CARS receives an already selected whole-trip mode or an explicitly selected candidate-leg mode; it does not choose a mode, destination order, or route arrangement. Great-circle Haversine distance is geometry only. Haversine × 1.3 must not be represented as a road route. Verified boat/water connections are separate route evidence. If the selected mode/route evidence is unavailable, the criterion is unscored.

### 4.6 Available time

Proposed reciprocal score:

\[
S_6(d)=\frac{1}{1+t_d/T_d}
\]

where (t_d\ge0) is supported required time for this destination and (T_d>0) is an approved candidate-level allowance. Examples: 0 → 1; (t_d=0.5T_d\) → 2/3; exact allowance → 0.5; twice allowance → 1/3. It distinguishes time requirements without assigning zero at the exact limit.

Approval must define allocation of trip/day time to one candidate, whether travel is one-way or round-trip, visit-duration inclusion, transfer time, and over-limit eligibility. The repository travel assessor currently evaluates route travel against per-day available minutes and explicitly excludes visit/wait/meal/transfer durations. Its multi-day assessment is not by itself a candidate-level (t_d,T_d) scoring contract. CARS must not accumulate a route; MO-GA schedules the itinerary.

## 5. Input/output and evidence contracts

### Inputs

Each candidate assessment must carry:

- Stable destination identity and display record.
- Separate eligibility facts and applicable traveler requirements.
- Typed evidence for all six criteria, including availability/validation state.
- Source/provider, source identity where available, retrieval/observation timestamp, freshness boundary, units, and relevant context.
- Confirmed preference status and exact category identifiers; no inferred taxonomy.
- Rating value and provenance; raw weather observations/forecasts and coverage; typed cost items and group/budget basis; route evidence with origin/mode/date and road/water type.
- Scoring-policy reference and version whenever a numeric score is emitted.

No proposed field name here implies a deployed Supabase column. Map verified source records into domain contracts only after the deployed/source contract is reviewed. Do not use local backups as proof of production metadata.

### Outputs

Per criterion: evidence status, explanation, provenance/freshness, policy reference if applied, and nullable score. Per candidate: eligibility result, outcome (`ranked`, `ineligible`, or `insufficientData`), missing/non-applicable criterion identifiers, six criterion scores and contributions only when complete, and a [0,1] total only when eligible and fully scoreable under the approved policy. Retain deterministic tie breaking. Do not present insufficient-data candidates as ranked recommendations.

### Evidence status rules

- **Missing:** no value/evidence; no score.
- **Invalid:** malformed, non-finite, out of domain, or inconsistent; no score.
- **Stale:** exceeds approved freshness; no score.
- **Unsupported:** no authoritative mapping, route type, or scoring rule; no score.
- **Not applicable:** criterion applicability decision says it does not apply; no implicit score and D-14 governs ranking effect.
- **Verified zero:** valid sourced zero (e.g., cost or rating); may be scored by an approved rule.
- **Insufficient:** evidence exists but cannot support a complete assessment (e.g., partial forecast/required cost data); no score.

No missing state becomes zero, favorable evidence, or redistributed weight.

## 6. Eligibility and mixed-group policy

Eligibility remains a gate and never changes the weighted result. The existing evaluator checks dataset presence, accepted approval status, required accreditation, and required suitability codes against supported codes. It is technically reusable, but production status vocabularies and authoritative sources remain unconfirmed; caller-provided sets are not policy approval.

Trip configuration currently represents total group size, children, elders, and derives adults when counts are internally consistent. It includes budget basis and currency. It does not establish age definitions, differing eligibility restrictions, or price multipliers. Use subgroup counts only where a verified item pricing rule requires them. Do not invent child/elder rates or eligibility rules. Missing group facts make dependent cost assessment insufficient, not default group size one.

## 7. Transportation responsibilities

- **Origin:** GPS is the requested default; manual location remains available as fallback. Obtain permission and confirm location availability before using GPS; on denial/unavailability, request or retain a manual origin. Never silently substitute another point. This desired policy must be reconciled with current `TripOrigin`, which models explicit coordinates and says live GPS is not modeled.
- **Mode:** tourist can select one mode for the whole itinerary or explicitly select different modes per leg. If no mode is fixed, MO-GA may recommend feasible arrangements using verified route data. CARS evaluates candidates in supplied context; it never selects the best mode.
- **Water:** verified boat/ferry transfer evidence is distinct from land routing and must include a reliable source and date-relevant connection/duration. Missing transfer evidence remains unknown; no road substitute.
- **Return:** tourist explicitly chooses whether the itinerary returns to origin. This affects MO-GA route construction, not destination CARS ranking. Add a typed trip input only through a separately approved model change; current trip model has no return flag.
- **Optimization:** CARS ranks individual destinations. MO-GA handles order, day assignment, travel arrangements, cumulative time/distance and return leg. Keep the approved MO-GA objectives unchanged.

## 8. Repository implementation map

These are likely implementation targets, not authorization to change them now.

| File | Required future work |
|---|---|
| `lib/models/cars_models.dart` | Align score/evidence/result contracts to approved 0–1 range; retain six criterion identifiers and evidence separation. |
| `lib/algorithms/cars_engine.dart` | Validate 0–1 scores and compute the explicit weighted sum; preserve exact weight validation, eligibility separation, no missing-score redistribution, and deterministic order. |
| `lib/algorithms/cars_assessment_input_preparer.dart` | Map verified typed assessments to states and invoke only approved, versioned policies; current policy boundary validates 0–100. |
| `lib/services/cars_recommendation_provider.dart` | Connect verified adapters and approved weights/policies; preserve unavailable default until all prerequisites exist. |
| `lib/algorithms/cars_interest_activity_matcher.dart` | Use authoritative identifiers only and surface no-preference/unsupported/unavailable distinctly. |
| `lib/algorithms/cars_budget_assessment.dart` | Supply verified candidate-level cost evidence after allocation policy approval; avoid inventing prices or double counting. |
| `lib/algorithms/cars_travel_assessment.dart` | Preserve geometry versus provider route distinction; extend typed input only for approved candidate-level scoring and explicit per-leg modes. |
| `lib/services/open_weather_map_service.dart` | Remain raw weather provider; add no score thresholds until policy approval. |
| `lib/models/itinerary_draft.dart` | Only if approved: explicit GPS/manual origin provenance, per-leg modes, and return-to-origin input; preserve current planning compatibility. |
| `lib/screens/tourist_screens/cars_recommendation_review_page.dart` | Display 0–1 scores, evidence status, and limitations after contract migration; keep review before selection/optimization. |
| `lib/screens/tourist_screens/system_generated_planning_page.dart` | Preserve loading, unavailable and error behavior; never imply live recommendations when provider unavailable. |
| `lib/services/destination_service.dart` and verified source adapters | Supply only confirmed destination/eligibility/evidence fields; no bundled fallback presented as verified. Exact provider file(s) remain to be identified after source-contract inspection. |

No Supabase schema change is specified. The repository has Supabase client/service code and local schema artifacts, but this task did not access either project and does not establish deployed columns, policies, or data quality. If required provenance or fields are absent, stop for separate schema/data-contract review; do not assume fields or alter schemas as part of CARS policy implementation.

Potential new files only after approvals: an immutable approved scoring policy implementation (e.g. `lib/algorithms/cars_approved_scoring_policy.dart`), source adapters for verified data providers, and a typed per-leg transportation contract if existing models cannot represent the approved inputs. Do not add placeholder numeric policies.

## 9. Required automated tests

### Unit

- Six exact criterion keys and survey weights sum to 1; invalid/missing/extra weights rejected.
- Each score accepts finite 0 and 1; rejects negative, above 1, NaN, and infinities.
- Hand-calculated weighted contributions and total match formula and remain within [0,1].
- Interest: exact authoritative mapping, multiple preferences/activities, no selection, unconfirmed input, unknown identifier, missing category, unsupported mapping.
- Rating: verified 0/midpoint/max; missing/null, malformed, invalid range, unverified, stale, missing provenance, fallback source.
- Weather: valid/partial/stale/unavailable coverage; date/location/units/provenance retained; no score without approved rule; classifier boundary tests only after thresholds are approved.
- Budget: total-group and per-person allocation; adult/child/elder compositions; each supported pricing unit; verified zero vs absent price; mixed currency; stale/unverified/ambiguous cost; package inclusion/double-counting; zero candidate budget; incomplete required cost components.
- Distance/time: valid and invalid coordinates; origin provenance; mode context; road versus water transfer; source/freshness; missing route; visit duration inclusion; candidate allowance boundaries. Policy numeric cases only after owner approves normalization/allocation.
- Eligibility independent of scores; unsupported required suitability remains ineligible; missing criteria cannot become zero or redistributed.
- Not-applicable behavior follows the approved D-14 rule; until decided, assert no rank is emitted for unresolved applicability.

### Integration

- Source adapter → preparation → policy → engine preserves destination identity, evidence, source, freshness, state, and rule version.
- No policy or unavailable source produces no numeric scores and no ranked recommendations.
- Policy cannot score stale/invalid/unsupported/insufficient evidence; missing rule reference and invalid output are rejected.
- Eligible partial evidence yields insufficient data and exact missing criteria; ineligible candidates remain unranked.
- Candidate duplicates/empty identities and provider errors fail clearly without fabricated fallback scores.
- Budget/time/distance source assessments are not mistaken for scores.

### Regression

- Review UI labels the adopted 0–1 scale and accurately displays unavailable/insufficient evidence.
- CARS ranking remains individual-destination ranking; no cumulative route optimization occurs in CARS.
- Tourist review and selection precede explicit MO-GA invocation; recommendation loading/editing does not invoke MO-GA.
- Origin, selected destination IDs, CARS provenance, group/trip context, and day assignments survive handoff.
- Whole-trip and explicit per-leg mode inputs are preserved; return-to-origin intent reaches MO-GA if implemented.
- Manual and circuit-based planning remain usable without CARS, network weather, or scoring credentials.
- Bundled fallback data is never labeled verified live recommendation evidence.
- Existing MO-GA objectives and behavior remain unchanged.

## 10. Implementation sequence and authorization gates

1. Obtain explicit owner decisions for D-03 through D-16, especially weather, budget/time allocation, distance normalization, not-applicable handling, eligibility vocabulary, GPS fallback, per-leg mode contract, water evidence, and return-to-origin.
2. Verify authoritative data-source contracts and deployed-schema evidence through separately authorized review. Identify source, units, provenance, freshness, and expected missingness for every required field.
3. Approve a versioned six-criterion scoring policy and exact [0,1] contract; define testable examples and edge behavior.
4. Design any required model/API changes without changing Supabase until separately reviewed and authorized.
5. Implement and test engine/model scale migration as one coordinated change. Keep no-policy path unavailable.
6. Implement approved criterion policies incrementally with unit tests and provenance validation.
7. Integrate only verified source adapters; validate all-six completeness before ranking.
8. Update UI and workflow messaging; preserve review, selection, explicit MO-GA action, and alternatives for unavailable inputs.
9. Run the focused suite, full Flutter tests, `flutter analyze --no-pub`, and `git diff --check`; review manual/circuit regressions and data disclosure.
10. Obtain separate release/security approval after acceptance evidence. This document grants none.

## 11. Final readiness determination

**CARS is not ready for implementation of production scoring and is not authorized for live recommendations.** The target criteria, weights, and 0–1 weighted formula are fixed here, but essential criterion policies and data contracts remain unresolved. The current engine and preparer use 0–100, and no verified provider for all six criteria was established by repository inspection. In particular, weather thresholds/classification, destination-level budget allocation, candidate-level time allocation, distance normalization by supported mode, not-applicable handling, eligibility values, and GPS/per-leg/return input representation remain blockers.

Until these are resolved and approved, retain the repository's safe unavailable behavior: no fabricated scores, no partial-weight ranking, and no claim of production-ready CARS. This document does not authorize code, schema, or database changes.
