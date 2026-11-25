# Task 08 — CARS Owner Decision Register and Policy Approval Workbook

**Purpose:** Convert the unresolved CARS decisions in Tasks 06–07 into explicit owner choices and approval records.

**Status:** Awaiting owner decisions. No item below is approved by this workbook. Recommendations are technical advice only. CARS remains in its safe unavailable/insufficient-data state until all implementation gates are approved and satisfied.

## How to complete this workbook

For each decision, select one alternative or write a revision, provide the requested evidence, and record approver/date. A recommendation is not an approval. “Not decided” leaves the associated gate blocked. Do not approve production activation through this workbook; that has a separate gate in Section 6G.

## 1. Fixed methodology baseline

The six criteria and survey-derived weights are preserved as the Task 06/07 baseline:

| Criterion | Weight |
|---|---:|
| Tourist preference / interest and activity match | 0.1548 |
| Public destination rating | 0.1718 |
| Weather suitability | 0.1695 |
| Budget compatibility | 0.1785 |
| Travel distance suitability | 0.1627 |
| Available travel time compatibility | 0.1627 |
| **Total** | **1.0000** |

Target formula:

\[
RS(d)=0.1548S_1(d)+0.1718S_2(d)+0.1695S_3(d)+0.1785S_4(d)+0.1627S_5(d)+0.1627S_6(d)
\]

Each score and the total are finite and in [0,1]. All six terms remain present; weights are not redistributed. Eligibility is separate from scoring. Current code still uses 0–100, so this is a target contract, not current runtime behavior.

### D-01 — Confirm criteria and survey weights

**Question:** Do you approve these six criteria and exact weights, and can you identify the survey/methodology record supporting them?

**Alternatives:** (a) Approve as listed and supply source/version; (b) reject and provide the corrected approved set with its source; (c) defer, keeping CARS unavailable.

| Consideration | Notes |
|---|---|
| Advantages | Fixes the criterion set and prevents implementers from substituting test weights. |
| Disadvantages / implication | A different approved weight set changes ranking and requires re-review of tests and methodology. |
| Required evidence | Survey-derived weights/methodology record, owner confirmation, effective version/date. |
| Technical recommendation | Approve the listed values only if the cited survey record confirms them. |
| Approval | Decision: ____  Source/version: ____  Approver: ____  Date: ____ |

### D-02 — Confirm normalized score contract

**Question:** Approve the target 0–1 score range and six-term formula above, replacing current 0–100 behavior through one coordinated migration?

**Alternatives:** (a) Approve 0–1; (b) retain 0–100 and revise Task 06 target/formulas consistently; (c) defer implementation.

| Consideration | Notes |
|---|---|
| Advantages | 0–1 aligns normalized criterion values and total; the weights directly combine scores. |
| Disadvantages / implication | Engine, policy output, UI, explanations and tests currently use 0–100; mixed scales cannot be ranked together. |
| Required evidence | Consumer inventory and acceptance examples for score and contribution display. |
| Technical recommendation | Approve 0–1 if all consumers can migrate atomically; do not run mixed-scale policies. |
| Approval | Decision: ____  Approver: ____  Date: ____ |

## 2. Owner decision register

### D-03 — Interest/activity matching and empty preferences

**Question:** What authoritative, versioned mapping links tourist preference identifiers to destination activity identifiers, and what happens to ranking when no preference is selected?

| Option | Advantages | Costs / methodological effects |
|---|---|---|
| A. Versioned exact-ID catalog; empty preference makes criterion not applicable and blocks ranking under D-14 Option A | Auditable mapping, no name-based inference; preserves missingness | Ranking may be unavailable for tourists with no preference selection |
| B. Versioned exact-ID catalog; empty preference receives an owner-approved fixed treatment | Could permit broader coverage | Fixed value influences rank and changes survey interpretation; value and rationale must be explicitly supplied |
| C. Define a narrower applicability domain requiring at least one confirmed preference | Clear and testable scope | Trips outside domain receive no CARS ranking; UI must explain why |

**Technical implications:** Existing matcher supports injected authoritative mappings, distinguishes no preference, unavailable map, unsupported IDs, missing activities, match and non-match. It does not supply an authoritative mapping. Similar category names are not a valid mapping.

**Required data/evidence:** Mapping source, stable IDs, complete mapping coverage, version/effective dates, destination activity inventory and completeness semantics; explicit empty-preference rule.

**Recommendation:** Approve an exact-ID versioned catalog and choose the empty-preference behavior only in conjunction with D-14. No numeric formula should be applied until that decision is recorded.

**Approval:** Selected option/revision: ____  Mapping source/version: ____  Approver: ____  Date: ____

### D-04 — Public destination rating

**Question:** Which rating is the approved public destination rating, what scale does it use, and how are zero, verification, source, and freshness established?

| Option | Advantages | Costs / implications |
|---|---|---|
| A. Use an identified external public-rating provider | Clear provider provenance if licensed and current | Requires provider access/terms, stable destination matching and freshness rules |
| B. Use a defined SAMAL NAV destination-review aggregate | Can use first-party review records | Requires a documented aggregate, moderation/eligibility rules, minimum evidence policy and distinction from raw individual reviews |
| C. Exclude rating scoring until an authoritative source is available | Prevents misleading ratings | Under all-six-required policy, candidates cannot rank until D-14/applicability policy allows; no silent omission |

**Proposed formula, only if a verified rating is on an approved 0–5 scale:**

\[
S_2=R/5
\]

Variables/domain: (R) is a verified current rating in [0,5]; output [0,1]. Boundary examples: 0→0, 2.5→0.5, 5→1. Zero is scoreable only when evidence proves it is an actual rating rather than a database default. Missing, malformed, stale, unverified or out-of-range values produce no score. Bias: linear mapping assumes equal spacing in the underlying rating scale; it does not account for review count or confidence unless an approved rule adds such evidence.

**Required data/evidence:** Authority and semantic definition; verified scale and zero semantics; source identifier, retrieval/update time and freshness limit; population and aggregation rules if first-party reviews are used.

**Recommendation:** Select a source and verify scale/provenance before approving the simple normalization. If these are absent, choose C and leave scoring unavailable.

**Approval:** Selected source/option: ____  Scale: ____  Freshness: ____  Approver: ____  Date: ____

### D-05 — Weather suitability

**Question:** Which verified activity requirements, forecast evidence, temporal aggregation, and mapping to a 0–1 score should define weather suitability?

| Option | Advantages | Costs / implications |
|---|---|---|
| A. Activity-specific classifier with approved thresholds and interval aggregation | Relates weather to what visitors plan to do; testable and explainable | Requires activity requirements, thresholds, complete time coverage and versioned classifier |
| B. Destination-level classifier independent of activities | Simpler data contract | Can ignore that conditions affect different activities differently; requires explicit owner rationale and thresholds |
| C. Do not score weather until A or B is approved | Avoids invented suitability claims | No complete CARS ranking where weather remains required |

**Formula structure:** No numeric formula is specified here. Owner must approve a classifier (g(activity, weather, period)), aggregation rule (h), and normalization (n) with output in [0,1]. No thresholds or favorable condition labels are supplied by this workbook.

**Required evidence:** Activity-specific weather requirements or approved destination policy; provider fields/units, location, forecast timestamps, requested itinerary period, coverage/freshness limits, aggregation examples, and rule version. The repository OpenWeatherMap service returns raw 5-day/3-hour forecast evidence; it does not implement CARS classification and may not cover trips up to the trip model's 30-day duration.

**Recommendation:** Prefer A if reliable activity requirements can be maintained; otherwise C. Missing or partial forecast is unscored, never favorable.

**Approval:** Option: ____  Classifier/threshold document: ____  Aggregation: ____  Approver: ____  Date: ____

### D-06 — Budget compatibility and candidate allocation

**Question:** Approve a continuous score and define how a total-trip or per-person budget becomes an allowance for assessing one destination, without treating the full trip budget as independently available at every destination.

**Formula alternatives:**

| Formula | Definition | Boundary / trade-off |
|---|---|---|
| Linear remaining budget | (S_4=\max(0,1-C_d/B_d)) | In [0,1] for (C_d\ge0,B_d>0), but exact-budget cost scores zero, contrary to the requested nonzero boundary. |
| Reciprocal (recommended proposal) | (S_4=1/(1+C_d/B_d)) | In (0,1], lower cost scores higher; verified zero→1, half budget→2/3, exact budget→0.5, twice budget→1/3. |
| Exponential | (S_4=e^{-\lambda C_d/B_d},\lambda>0) | In (0,1], exact budget→(e^{-\lambda}); requires owner-selected decay parameter and calibration rationale. |

For the reciprocal proposal: (C_d\ge0) is a supported estimated cost for destination (d); (B_d>0) is a candidate-level allocation derived by an approved rule. If (B_d=0), result is unavailable pending a separate rule. Missing price is not zero. Mixed currencies cannot be combined without a verified conversion source. Formula bias: it is smooth and rewards lower expenses but does not itself encode affordability, user utility, total-trip feasibility, or uncertainty in the estimate.

**Allocation alternatives:**

- **A. Owner-defined fixed per-destination/per-day share** of total budget: simple and reproducible, but may not reflect trip order or destination count. Requires explicit allocation values/rule.
- **B. Candidate comparison against a selected portion of overall budget**: flexible, but requires the tourist or policy to define that portion and may yield inconsistent comparisons.
- **C. Do not score budget until allocation is supplied:** safest when no defensible allocation exists, but blocks complete score where all criteria are required.

Per-person budget must be scaled only using verified applicable counts/rates. Total-group budget remains total-group. Adults, children and elders may be counted, but no age discounts or applicability are inferred. Include entrance/activity/transport/food/accommodation only if required and priced with clear units. Package-included components must not be double-counted.

**Required evidence:** Currency, basis, allocation rule, group composition, component applicability, price units, source/verification/freshness, package inclusions and conversion authority if needed.

**Recommendation:** Approve reciprocal scoring only alongside an explicit allocation rule; otherwise select C and leave budget unscored.

**Approval:** Formula: ____  Allocation option/rule: ____  Zero-budget behavior: ____  Approver: ____  Date: ____

### D-07 — Distance suitability

**Question:** What distance evidence and mode-specific normalization should score one destination without CARS selecting a mode or optimizing a route?

| Option | Advantages | Costs / methodological effects |
|---|---|---|
| A. Verified provider route distance with approved per-mode function (f_m(D)) | Reflects mode-specific network distance; separates walking/road/water | Requires provider coverage, route type, mode, origin/date and approved normalization for every supported mode |
| B. Straight-line distance with approved per-mode suitability function | Can be computed from valid coordinates; transparent geometry | Not road/water distance and can misrepresent island/barrier access; must be labeled geometry, not a route |
| C. Do not score distance where verified mode-specific evidence is unavailable | Avoids fabricated reachability | Leaves criterion unavailable; D-14 determines ranking consequence |

**Formula interface only:** (S_5=f_m(D_{d,m};\theta_m)), where (D) is an approved distance measure for already selected context (m); (	heta_m) denotes owner-approved parameters. No (f_m), threshold, or parameter is set here. Output must be [0,1].

**Required evidence:** Origin and destination coordinates/provenance; route provider and route type; travel mode; date; distance units; freshness; verified water connection if water route. Straight-line Haversine is not a road route; Haversine×1.3 must not be treated as one.

**Recommendation:** A for a mode already selected by the tourist; C if route data is missing. Keep per-leg choices as explicit input. CARS never chooses the best mode.

**Approval:** Option and per-mode rule: ____  Route source: ____  Approver: ____  Date: ____

### D-08 — Available travel time and candidate allocation

**Question:** Approve a candidate-level time allowance and define which durations count for an individual destination assessment.

**Formula alternatives:**

| Formula | Definition | Boundary / trade-off |
|---|---|---|
| Linear remaining-time | (S_6=\max(0,1-t_d/T_d)) | Scores exact use of the allowance zero. |
| Reciprocal (recommended proposal) | (S_6=1/(1+t_d/T_d)) | (t=0→1), half allowance→2/3, exact allowance→0.5, twice allowance→1/3. |
| Exponential | (S_6=e^{-\mu t_d/T_d},\mu>0) | Exact allowance→(e^{-\mu}), but needs an approved decay parameter. |

Here (t_d\ge0) is a verified required duration for one destination assessment and (T_d>0) is an approved candidate-level allowance. Output is [0,1]. If (T_d=0) or a required duration is missing, return unavailable unless a separate approved rule applies. Reciprocal scoring does not itself decide whether exceeding the allowance is infeasible; that belongs to owner-defined eligibility/feasibility policy. Bias: a smooth time preference may rank an over-limit candidate rather than exclude it unless eligibility handles that case.

**Allocation alternatives:** (A) use a defined fraction of daily available time; (B) divide available time among candidate destinations under an explicit rule; (C) do not score until candidate allocation is supplied. Each requires owner-defined values; no allocation is inferred here. Define whether (t_d) includes one-way/return travel, visit time and transfers. CARS evaluates one destination; MO-GA schedules cumulative itinerary time.

**Required evidence:** Candidate allocation rule, visit duration, route mode/date/duration and scope, transfer/water duration, source/freshness, over-limit behavior. Current travel assessment is route-time only and explicitly excludes visit and transfer durations.

**Recommendation:** Reciprocal formula with allocation option chosen explicitly; do not score until the required components are supported.

**Approval:** Formula: ____  Allocation: ____  Duration scope: ____  Over-limit rule: ____  Approver: ____  Date: ____

### D-09 — GPS and manual origin

**Question:** Confirm GPS as default with manual fallback and define consent, failures and provenance.

**Alternatives:** (A) attempt GPS after permission/consent, then request manual origin if denied/unavailable; (B) ask tourist to select GPS or manual origin each trip; (C) manual origin only. A best preserves the stated default while preserving control; B gives clearer per-trip choice; C is compatible with current `TripOrigin` but does not implement GPS default.

**Implications:** Origin affects distance and route-time evidence; it is not a destination. Store origin source (GPS/manual), timestamp where relevant, and selected coordinates. Do not substitute a map's current-location marker unless the tourist confirms it as trip origin. Current trip model stores coordinates/label only; planner does not integrate GPS default.

**Required evidence:** Permission UX and error states; explicit fallback; coordinate validation; privacy/retention handling.

**Recommendation:** A, because it implements requested GPS default and preserves manual fallback, subject to privacy/permission review.

**Approval:** Option: ____  Consent/fallback wording: ____  Approver: ____  Date: ____

### D-10 — Whole-trip and per-leg transport modes

**Question:** Approve how one itinerary-wide selected mode, explicit per-leg modes, and an unfixed mode are represented and processed.

**Alternatives:** (A) whole-trip mode only (smallest change, cannot express requested per-leg variation); (B) whole-trip mode or complete/partial explicit per-leg mode map plus unspecified state (supports stated choices; needs leg identity and conflict rules); (C) defer travel scoring until mode is fixed (safe but limits recommendations).

**Implications:** CARS receives a selected mode context and scores the destination; it must not pick the best mode. If mode is unfixed, MO-GA may recommend feasible transport using verified providers, separately from CARS. Current `TripConfiguration` has one nullable `travelMode`, and current travel assessor applies it to all legs. MO-GA has no inspected route-mode assignment abstraction.

**Required information:** Leg identity (origin→destination or destination pair), precedence if whole-trip and per-leg selections conflict, behavior for unassigned legs, provider support and provenance.

**Recommendation:** B, since it preserves both approved tourist choices; define precedence as an explicit decision before model implementation. Do not silently fall back to a mode.

**Approval:** Option: ____  Conflict/unassigned-leg rule: ____  Approver: ____  Date: ____

### D-11 — Verified water transportation

**Question:** Which authoritative source can establish date-relevant boat/ferry connection, route identity, schedule, and duration?

**Alternatives:** (A) approved provider/operator timetable; (B) curated official transport directory with update process; (C) mark water legs unavailable and require manual confirmation outside CARS/MO-GA routing.

**Implications:** Must represent water segment separately from road route and straight-line geometry. No ferry schedule or duration may be inferred. Existing `RequiredTransfer` records requested ferry/boat intent; travel assessment returns unavailable and does not substitute land routing.

**Required evidence:** Connection endpoints/identity, operator/source, service dates/times, duration semantics, retrieval/update time and validity/freshness, outage/missing behavior.

**Recommendation:** A or B only if authoritative and maintained; otherwise C.

**Approval:** Source/option: ____  Freshness/update owner: ____  Approver: ____  Date: ____

### D-12 — Eligibility and traveler suitability

**Question:** What authoritative destination status values and traveler requirements make a destination eligible, and which role/source maintains them?

**Alternatives:** (A) keep current configurable gate (dataset presence, approval, required accreditation, code requirements) while owner supplies canonical sets; (B) define a narrower eligibility policy from authoritative destination publication/verification fields; (C) exclude a criterion until source values are verified.

**Implications:** Eligibility is not a weighted criterion and cannot be repaired by a high score. Do not invent accessibility, age, disability, family, safety, or group rules. Current evaluator uses caller-provided approved/accredited status sets.

**Required evidence:** Canonical values, meaning of missing/pending/expired, source and maintenance authority, exact traveler requirement identifiers and destination capability evidence.

**Recommendation:** A as a structure, but do not populate canonical sets until the owner/source authority confirms them.

**Approval:** Status vocabulary: ____  Suitability requirements: ____  Source owner: ____  Approver: ____  Date: ____

### D-13 — Mixed-group and price basis

**Question:** Approve group-count interpretation and the evidence needed to apply per-person, subgroup, group, vehicle, room, activity, or other prices.

**Alternatives:** (A) calculate only units explicitly represented by verified cost items and matching group facts; otherwise insufficient; (B) restrict scoring to a subset of supported pricing units approved by owner; (C) do not score group-dependent costs until rates are supplied.

**Implications:** Current trip model records total, child, elder counts and derives adults; it does not establish age definitions, rates, or age-dependent eligibility. Never infer discounts or vehicle/room quantities.

**Required evidence:** Definitions of adult/child/elder, counts and their source, item price unit and quantity, applicability, currency, source, verification and freshness.

**Recommendation:** A, with no inferred rate or count. Incomplete group facts make dependent cost assessment insufficient.

**Approval:** Option: ____  Age/count definitions: ____  Supported units: ____  Approver: ____  Date: ____

### D-14 — Not-applicable criteria (required choice)

**Question:** How should CARS handle an otherwise eligible destination when one criterion genuinely does not apply, including empty preferences?

| Option | Mathematical consistency | Fairness/methodology | Missing-data behavior | UX/testability |
|---|---|---|---|---|
| A. Not-applicable blocks ranking | Six-term sum is not emitted without six numeric terms; no denominator change | Preserves fixed survey weight meaning; can exclude no-preference tourists from ranking | Strictly distinct from missing; nothing is imputed | Easy to explain/test, but can make CARS unavailable for broad cases |
| B. Fixed owner-approved treatment | Six weights remain in formula; each term still has a defined value | Assigned contribution influences rankings and could create systematic bias; requires methodological rationale | Not-applicable remains separately labeled, never treated as missing | Testable only after exact value, scope, rationale and review UI are approved |
| C. Explicit applicability domain | Formula applies only to a defined set where all six criteria are applicable | Preserves weights within domain, but limits who/cases may be ranked | Outside-domain returns a clear not-applicable/unsupported outcome | Testable predicates and clear scope; requires product eligibility messaging |

**Recommendation:** No option selected. A is the conservative interim behavior because current engine requires all six scores and does not redistribute. It is not a permanent policy approval. Owner must choose A/B/C or supply a complete alternative with examples.

**Approval:** Option: ____  Rationale (required for B/C): ____  Examples: ____  Approver: ____  Date: ____

### D-15 — Evidence-state semantics

**Question:** Approve the status distinctions and whether “missing field” must differ from “source unavailable” in the user-facing/API contract?

**Alternatives:** (A) retain current statuses and explanations, with verified zero represented as a value plus provenance; (B) add structured missing-reason codes for field absent, source unavailable, partial data, and unsupported mapping; (C) defer finer distinction but never collapse any to numeric score.

**Implications:** Existing preparer distinguishes available, insufficient, unavailable, invalid, stale, unsupported, notApplicable. Verified zero is data, not a state. Some source models do not distinguish all reasons. Any added reason codes should preserve current safe no-score behavior.

**Required evidence:** UX needs for reason display, source-specific status contract, examples per criterion.

**Recommendation:** B if the UI/support process needs actionable reason detail; otherwise A with stable typed explanations. In all cases zero/missing remain distinct.

**Approval:** Option: ____  Required reason codes: ____  Approver: ____  Date: ____

### D-16 — Return to origin

**Question:** How does the tourist state whether MO-GA’s itinerary returns to the starting point, and what happens if origin is absent?

**Alternatives:** (A) explicit required yes/no choice; (B) optional choice with a clearly documented default; (C) no return leg until this feature is approved.

**Implications:** This affects complete-route optimization, not CARS candidate ranking or objectives. Current `TripConfiguration` has no return flag; current adapter passes origin but no return intent.

**Required information:** UI wording/default, whether return is valid for all modes, routing/water evidence, missing-origin behavior and persistence compatibility.

**Recommendation:** A for explicit user control; no default should be inferred until approved. If origin or return route is unsupported, report itinerary feasibility as unknown rather than inventing a leg.

**Approval:** Option: ____  Missing-origin behavior: ____  Approver: ____  Date: ____

## 3. Mathematical policy decision sheet

This section summarizes formula choices without approving them. Owners should record selected formula and version in the corresponding D item.

| Criterion | Formula candidate and variables | Valid domain / examples | Missing data and bias |
|---|---|---|---|
| Interest/activity | (S_1=\frac{\#\text{confirmed preferences with ≥1 mapped destination activity}}{|P|}). (P)=confirmed preference IDs; mapping must be authoritative/versioned. | (P\ne\emptyset), complete exact mapping and activity evidence; score [0,1]; none matched→0, all matched→1. | Empty (P) is not applicable; decision D-14. Unknown mapping or incomplete activity coverage gives no score. Counting each preference equally may over/underweight differing preference importance; approved only if equal weighting is intended. |
| Rating | Proposed (S_2=R/5). (R)=verified rating. | (R\in[0,5]); 0→0, 2.5→0.5, 5→1. | No score if source/scale/zero provenance/freshness invalid. Linear mapping assumes interval scale and ignores review-count confidence. |
| Weather | (S_3=n(h(\{g(activity,forecast_t)\}_{t\in visitWindow}))). (g)=approved classifier; (h)=approved period aggregation; (n)=approved normalization. | All functions, thresholds and required fields must be owner-defined; output [0,1]. | No numeric example until thresholds are approved. Partial/stale forecast or missing activity requirements→no score. Aggregation can mask short severe intervals; owner must set policy. |
| Budget | Proposed (S_4=1/(1+C_d/B_d)). (C_d)=verified candidate cost; (B_d)=candidate allocation. | (C_d\ge0,B_d>0); 0→1, (0.5B)→2/3, (B)→0.5, (2B)→1/3. | Missing/ambiguous/unverified/stale price or allocation→no score. Formula is monotone but does not itself mean affordable or allocate a multi-day budget. |
| Distance | (S_5=f_m(D_{d,m};\theta_m)), all terms owner-defined; (m) is supplied whole-trip or explicit leg mode, not selected by CARS. | Finite nonnegative supported distance and approved mode rule; output [0,1]. No threshold/example authorized yet. | Missing route/mode/water evidence→no score. Straight-line distance can bias island/barrier access; do not call it road distance. |
| Available time | Proposed (S_6=1/(1+t_d/T_d)). (t_d)=complete supported candidate duration; (T_d)=approved candidate allowance. | (t_d\ge0,T_d>0); 0→1, (0.5T)→2/3, (T)→0.5, (2T)→1/3. | Missing visit/route/transfer duration or allocation→no score. Smooth preference may give an over-time destination a score; owner decides separate eligibility/feasibility behavior. |

For any criterion: scores must be finite and [0,1]. Missing, invalid, stale, unsupported, or insufficient evidence does not become zero, one, or a redistributed weight. A verified zero is scoreable only when its source confirms an actual zero value.

## 4. Data-source approval register

“Exists in repository” describes a client, model, or interface only. Production availability remains unverified for every row below.

| Source | Required information / authority | Verification and freshness | Missing behavior | Repository status | Production status |
|---|---|---|---|---|---|
| Destination directory | Stable destination ID, name/location, coordinates, active/publication state, category/activity links; authoritative SAMAL NAV directory | Owner/publisher verification and coordinate provenance; date-specific availability if eligibility uses it | Candidate unavailable/ineligible; no fallback as verified source | `DestinationService` query/model and bundled fallback exist | **UNVERIFIED** |
| Activities | Stable activity ID, destination link, category ID, availability, relevant weather/cost requirements; authorized publisher or verified catalog | Source identity, update time, completeness and lifecycle | Interest/weather evidence unavailable or insufficient | Activity model/local schema artifacts exist; no complete CARS source adapter found | **UNVERIFIED** |
| Preference/activity mapping | Canonical preference IDs to canonical activity IDs; owner-approved taxonomy authority | Mapping version and effective period; coverage audit | Unsupported/unavailable; never infer by text | Matcher interface exists; authoritative mapping absent | **UNVERIFIED** |
| Public ratings/reviews | Defined public aggregate or external rating source; rating scale and destination identity mapping | Actual-value vs default evidence, source, update/retrieval time and freshness | Rating criterion unscored | Parser and review services exist; local backup includes rating/review fields | **UNVERIFIED** |
| Weather | Forecast conditions for destination coordinate and visit dates; OpenWeatherMap or separately approved provider | Provider timestamp, retrieved time, units, coverage and stale rule; activity classifier separately approved | Unavailable/partial/stale, no favorable default | Injectable raw OpenWeatherMap service exists (5-day/3-hour); no suitability policy | **UNVERIFIED** |
| Prices | Entrance, activity, transport, food, accommodation/package only when required; authoritative operator/destination source | Currency, unit, quantity/applicability, verification, source, freshness and package inclusion | Insufficient; no zero substitution or mixed-currency sum | Typed cost assessor exists; destination entrance fee lacks required provenance in current adapter | **UNVERIFIED** |
| Group composition | Total/adult/child/elder counts needed by applicable pricing units; tourist input or verified profile | Explicit definitions and count validation; no age assumptions | Group-dependent line item unavailable | Trip model stores total/children/elders and derives adults; no rate policy | **UNVERIFIED** |
| Destination availability | Date-relevant opening/closure/capacity or publication state if used for eligibility | Authorized source and update timestamp | Eligibility unknown or candidate excluded according to approved rule | Local schema has availability artifact; use in current CARS not established | **UNVERIFIED** |
| Routing | Mode-specific route distance and duration, endpoints, date, route type and origin; approved routing provider | Provider, retrieval/freshness, units, mode and route validity | Criterion unavailable; no Haversine road substitution | Injectable `TravelRoutingProvider` interface and assessment exist; configured provider not found | **UNVERIFIED** |
| Water transport | Connection endpoints/identity, operator schedule, date-valid service and transfer duration | Authoritative operator/agency, schedule version, retrieval/update and validity | Water leg unavailable; no road substitution | `RequiredTransfer` intent model exists; no connection/schedule source | **UNVERIFIED** |
| Tourist preferences | Confirmed preference identifiers, confirmation state and authenticated owner | Explicit confirmation semantics, source and update time | No preference is separately represented; not-applicable decision D-14 applies | Profile model/service and trip adapter exist; confirmation handling bounded; mapping absent | **UNVERIFIED** |

### Source approval fields

For each source above, owner/security reviewer records:

| Source name | Approved provider/authority | Contract/version | Verification/freshness rule | Data steward | Approval/date |
|---|---|---|---|---|---|
| __________________ | __________________ | __________________ | __________________ | __________________ | __________________ |
| __________________ | __________________ | __________________ | __________________ | __________________ | __________________ |
| __________________ | __________________ | __________________ | __________________ | __________________ | __________________ |

Do not put credentials, tokens, personal records, or production data in this workbook.

## 5. Architecture and workflow approval points

The current pipeline is:

`Tourist Profile → TripConfiguration → injectable assessment source → evidence preparer → optional scoring policy → eligibility evaluator / engine → recommendation review → explicit selection → explicit MO-GA optimization`

The following facts require approval before implementation:

- The provider package includes `assessmentInputs`, but current planning flow passes only ranking/destinations/trip/run reference to review. Approve a review evidence contract and privacy/retention scope so source, freshness, state, and rule references survive.
- Current `CarsCandidateResult` carries scores/contributions/explanation, not criterion evidence provenance.
- `TripConfiguration` has one nullable whole-trip travel mode, selected coordinate origin, group/budget context, and daily available hours. It does not encode GPS/manual provenance, per-leg mode, or return-to-origin choice.
- MO-GA is invoked after explicit draft action and receives origin; it optimizes destination routing. Do not change MO-GA objectives under this workbook.
- Manual selection and circuit-based planning remain independent from CARS and must not require CARS data providers or scoring configuration.

**Architecture approval:** Evidence carried to review: ____  Origin/mode/return model: ____  Privacy/retention: ____  Approver: ____  Date: ____

## 6. Final implementation authorization checklist

Check only after decisions are recorded and supporting evidence is attached/referenced. Blank means not approved.

### A. Methodology approval

- [ ] D-01 six criteria and survey weights confirmed against source record.
- [ ] D-02 all scores and total use approved 0–1 contract; no mixed-scale consumers remain.
- [ ] D-14 not-applicable rule explicitly selected and consistent with fixed six weights/no redistribution.
- [ ] Eligibility remains separate from scoring; suitability scope is approved.

Approver/date: ____________________

### B. Mathematical policy approval

- [ ] D-03 interest matching and empty preference behavior approved.
- [ ] D-04 rating scale/formula/source semantics approved.
- [ ] D-05 weather classifier, thresholds, aggregation and normalization approved.
- [ ] D-06 budget formula, allocation, currency/unit/group and zero-budget behavior approved.
- [ ] D-07 distance metric/normalization by supplied mode approved.
- [ ] D-08 time formula, allocation, duration scope and over-time rule approved.

Approver/date: ____________________

### C. Data-source approval

- [ ] Destination, activity, taxonomy, rating, weather, pricing, availability, preference and routing sources have named authority/contracts.
- [ ] Water transportation source and schedule evidence are verified or water-dependent scoring remains unavailable.
- [ ] Provenance, verification, freshness and missing-data behavior are specified for every source.
- [ ] No local backup or interface is being treated as proof of deployed data.

Approver/date: ____________________

### D. Architecture and model approval

- [ ] Candidate evidence and provenance survive through tourist review under an approved data/retention contract.
- [ ] GPS/manual origin and permission behavior are defined.
- [ ] Whole-trip/per-leg/unfixed mode behavior is represented without CARS choosing a mode.
- [ ] Return-to-origin intent is defined for MO-GA, not CARS.
- [ ] Required schema/source changes, if any, are separately reviewed; this workbook does not authorize them.

Approver/date: ____________________

### E. UI and workflow approval

- [ ] Loading, unavailable, insufficient, invalid, stale, unsupported, ineligible and not-applicable states are understandable.
- [ ] Numeric scores display the approved scale and evidence limitations.
- [ ] Tourist review/selection happens before explicit MO-GA optimization.
- [ ] No fallback destination, incomplete score, or raw weather/cost value is presented as verified live recommendation data.
- [ ] Manual and circuit planning remain available independently.

Approver/date: ____________________

### F. Testing and acceptance approval

- [ ] Unit vectors and boundary examples for every approved scoring rule are recorded.
- [ ] Provider integration, provenance and incomplete/stale/invalid cases are specified.
- [ ] Eligibility, no-redistribution and D-14 behavior are covered.
- [ ] Evidence handoff, selection and explicit MO-GA workflow are covered.
- [ ] Manual, circuit, MO-GA objective, mode, return and water-routing regressions are covered.
- [ ] Test environment and synthetic fixture policy are approved; no production data required.

Approver/date: ____________________

### G. Production deployment and security approval — separate gate

- [ ] Implementation acceptance has completed in the authorized environment.
- [ ] Security/data access review and operational monitoring are approved.
- [ ] Production source configuration, credentials custody and rollback plan are separately reviewed.
- [ ] Explicit production deployment authorization is recorded by authorized owner.

Approver/date: ____________________

**Implementation authorization (controlled development only):** Approved / Not approved: ____  Scope/version: ____  Owner: ____  Date: ____

**Production activation authorization:** Approved / Not approved: ____  Release/version: ____  Authorized approver: ____  Date: ____

These are separate decisions. Approval to implement does not approve production deployment or activation.

## 7. Remaining external dependencies and readiness

### External data dependencies

At least eight source areas require owner-confirmed authority/contracts: activities/taxonomy mapping, ratings, weather/activity requirements, prices, candidate availability, preferences/confirmation, mode-specific routing, and water transportation. Group price rates and date-specific eligibility evidence are additional dependencies where applicable. Production availability is unverified.

### Decision count and gate status

- **Fourteen decision areas require owner input:** D-03 through D-16.
- D-01 and D-02 also require explicit methodology/scale confirmation as implementation gates, even though Task 06 recorded them as target baseline.
- No approval has been inferred from prior discussion or this workbook.
- Until mathematical policies, applicability, and source contracts are complete, implementation of numeric production scoring remains blocked.
- Existing safe behavior must remain: unavailable provider, null score for unsupported evidence, no partial-weight ranking, no fabricated values.

## 8. Owner closeout record

| Review item | Owner response |
|---|---|
| Decisions completed | ______________________________ |
| Decisions deferred/rejected | ______________________________ |
| Evidence attached or referenced | ______________________________ |
| Controlled implementation approved? | Yes / No — scope: __________________ |
| Production activation approved? | Yes / No — separate release approval required |
| Owner name / role | ______________________________ |
| Date | ______________________________ |

**Current determination:** No unresolved decision is marked approved. CARS implementation is **not authorized** by this workbook. Await explicit owner decisions and evidence; do not activate recommendations.
