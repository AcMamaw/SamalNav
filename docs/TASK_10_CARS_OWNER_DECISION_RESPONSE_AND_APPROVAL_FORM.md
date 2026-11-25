# Task 10 — CARS Owner Decision Response and Approval Form

**Form status:** Blank response form. No decision or approval is preselected. Completing one decision does not approve another, authorize implementation, or authorize production deployment.

**Project:** SAMAL NAV  
**Owner completing form:** ______________________________  **Role:** ______________________________  
**Date started:** __________________  **Form/policy version:** __________________

## Instructions for the project owner

Complete each decision independently. Mark exactly one response status. “Not decided” is a valid response and leaves that decision blocked. If selecting “Other,” write the complete policy and its technical examples. Attach or cite supporting evidence by safe document reference; do not include credentials, passwords, tokens, or production personal data.

Status choices for each decision:

- [ ] Approved
- [ ] Approved with conditions
- [ ] Rejected
- [ ] Deferred
- [ ] Not decided
- [ ] Response supplied, but evidence is insufficient

An approval requires a named approver, role, date, effective version, and evidence where the decision depends on an authoritative source. Blank fields never mean approved.

## 1. Fixed methodology reference

The Task 06–09 baseline preserves these six criteria and survey-derived weights:

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

The target is a finite [0,1] score for every criterion and the final result. All six terms remain; missing evidence does not receive zero and weights are not redistributed. Eligibility is separate from scoring. Current repository code remains on a 0–100 score contract until a separately approved, coordinated migration is implemented.

## 2. Decision response forms

Use the response status list above independently in every section. Available alternatives are options for consideration, not recommendations approved in advance.

### D-01 — Six criteria and survey weights

**Question:** Do you approve the six criteria and exact weights in Section 1? Identify the supporting survey/methodology record.

**Alternatives:** Approve as listed; reject and provide a corrected set; defer/not decided.

- Selected decision/status: ______________________________
- Revised criteria/weights, if any: ______________________________
- Explanation and rationale: ______________________________
- Supporting survey/methodology evidence and version: ______________________________
- Conditions or limitations: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-02 — Score scale and weighted formula

**Question:** Approve the [0,1] target and six-term weighted formula, with an atomic migration from the current 0–100 code contract?

**Alternatives:** Approve [0,1]; reject and revise the methodology consistently (specify); defer/not decided.

- Selected decision/status: ______________________________
- Revised scale/formula, if any: ______________________________
- Explanation and rationale: ______________________________
- Supporting consumer inventory/acceptance examples: ______________________________
- Conditions or limitations (including mixed-scale prohibition): ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-03 — Interest/activity matching and empty preferences

**Question:** Which versioned authority maps preference identifiers to activity identifiers, and how does an empty preference set affect ranking?

**Alternatives:** Exact-ID mapping plus not-applicable blocks ranking; exact-ID mapping plus a separately specified fixed treatment; define a CARS applicability domain; other; not decided. No name-similarity mapping is assumed.

- Selected decision/status: ______________________________
- Revised policy and empty-preference behavior: ______________________________
- Explanation and rationale: ______________________________
- Required mapping/catalog evidence, version and coverage: ______________________________
- Conditions/limitations: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-04 — Public destination rating

**Question:** What source provides the public destination rating, what does it measure, and how are scale, zero, verification and freshness established?

**Alternatives:** Identified external public-rating provider; approved SAMAL NAV aggregate with documented computation; do not score until authoritative evidence exists; other; not decided.

- Selected source/decision/status: ______________________________
- Rating meaning, scale and normalization (cross-reference Section 3): ______________________________
- Explanation and rationale: ______________________________
- Supporting evidence for authority, default-zero semantics, source and freshness: ______________________________
- Conditions/limitations: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-05 — Weather suitability

**Question:** Should weather suitability be classified per activity or per destination, and what approved classifier, time aggregation and normalization will be used?

**Alternatives:** Activity-specific classifier; destination-level classifier; do not score pending a policy/data source; other; not decided. Thresholds must be supplied by the owner or cited approved standard; none are prefilled.

- Selected decision/status: ______________________________
- Classifier/threshold/aggregation/normalization reference: ______________________________
- Explanation and rationale: ______________________________
- Supporting activity requirement and provider evidence: ______________________________
- Conditions (forecast horizon, partial/stale coverage): ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-06 — Budget compatibility and candidate allocation

**Question:** Which cost score is approved, and how is an overall total-group or per-person budget allocated to an individual destination assessment?

**Alternatives:** Reciprocal score; exponential score with specified parameter; another fully specified formula; do not score until allocation/evidence exists; not decided. The linear remaining-budget option scores exact-budget spend zero; select it only with explicit rationale against the nonzero-boundary requirement.

- Selected formula/decision/status: ______________________________
- Candidate allocation rule (including budget basis and trip length): ______________________________
- Zero-budget behavior: ______________________________
- Explanation and rationale: ______________________________
- Evidence for pricing units, currency, required components, group rates and package inclusions: ______________________________
- Conditions/limitations (unknown prices, mixed currency, freshness): ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-07 — Distance suitability

**Question:** Which distance measure and mode-specific normalization may CARS use for an individual destination, without choosing a mode or optimizing destination order?

**Alternatives:** Verified provider route distance with approved mode-specific rule; straight-line geometry under a separately approved and accurately labeled rule; do not score if supported route evidence is absent; other; not decided. No threshold or parameter is prefilled.

- Selected decision/status: ______________________________
- Formula/parameters and supported modes (cross-reference Section 3): ______________________________
- Explanation and rationale: ______________________________
- Route provider, route type, origin/date and freshness evidence: ______________________________
- Conditions (road/water distinction and selected mode context): ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-08 — Available travel-time compatibility

**Question:** Which formula and candidate-level time allowance are approved, and which duration components count?

**Alternatives:** Reciprocal formula; exponential formula with specified parameter; another fully defined formula; do not score until time allocation/duration evidence exists; not decided.

- Selected formula/decision/status: ______________________________
- Candidate allowance allocation rule: ______________________________
- Duration scope (one-way/return travel, visit, transfer): ______________________________
- Over-allowance eligibility/feasibility behavior: ______________________________
- Supporting duration sources and freshness: ______________________________
- Conditions/limitations: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-09 — GPS default and manual origin

**Question:** Approve GPS as the default origin with manual fallback, and define consent, permission denial, disabled/unavailable GPS, and provenance behavior?

**Alternatives:** Attempt GPS with permission/consent then manual fallback; ask tourist to choose GPS or manual each trip; manual-only; other; not decided.

- Selected decision/status: ______________________________
- Permission/consent and fallback policy: ______________________________
- Explanation and rationale: ______________________________
- Required privacy/provenance/coordinate evidence: ______________________________
- Conditions/limitations: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-10 — Whole-trip, per-leg and unspecified modes

**Question:** How are a single trip mode, explicit per-leg modes and an unfixed mode represented, including precedence and MO-GA recommendations?

**Alternatives:** Whole-trip mode only; whole-trip plus explicit per-leg modes and an unspecified state; defer travel scoring until mode is selected; other; not decided. CARS does not choose the best transportation arrangement.

- Selected decision/status: ______________________________
- Leg identity and mode precedence/unassigned-leg rule: ______________________________
- MO-GA recommendation behavior when mode is not fixed: ______________________________
- Supporting routing-provider mode coverage: ______________________________
- Conditions/limitations: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-11 — Verified water transportation

**Question:** Which authoritative source establishes boat/ferry connection, route identity, service dates/schedule, and transfer duration?

**Alternatives:** Approved operator/provider timetable; curated official directory with named steward; keep water leg unavailable pending manual confirmation; other; not decided.

- Selected source/decision/status: ______________________________
- Connection/schedule/duration contract: ______________________________
- Explanation and rationale: ______________________________
- Supporting authority, validity and freshness evidence: ______________________________
- Conditions/limitations (no road substitution): ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-12 — Eligibility and traveler suitability

**Question:** Which authoritative approval/accreditation values and traveler requirements determine eligibility, and who maintains them?

**Alternatives:** Retain configurable evaluator with approved canonical values; define a narrower publication/verification gate; leave uncertain eligibility unavailable/excluded; other; not decided. Do not invent accessibility, age, safety, or family rules.

- Selected decision/status: ______________________________
- Canonical statuses and suitability requirements: ______________________________
- Explanation and rationale: ______________________________
- Supporting source and data-steward evidence: ______________________________
- Conditions/limitations for missing or stale eligibility facts: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-13 — Mixed-group and pricing basis

**Question:** How should adults, children, elders, total group size and explicit price units be used, and which age-dependent rules are authoritative?

**Alternatives:** Calculate only explicitly supported pricing units and otherwise return insufficient; restrict to an approved subset of units; defer group-dependent scoring; other; not decided.

- Selected decision/status: ______________________________
- Group definitions and supported pricing units: ______________________________
- Explanation and rationale: ______________________________
- Supporting rates/count source and evidence: ______________________________
- Conditions/limitations (no inferred discounts/quantities): ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-14 — Not-applicable criteria

**Question:** How should a genuinely not-applicable criterion affect a six-term recommendation score without silently imputing a value or redistributing weights?

**Alternatives:** A. Block ranking; B. apply a specified fixed treatment while retaining all weights; C. define a CARS applicability domain; other. No option is selected by this form.

- Selected decision/status: ______________________________
- Exact rule, scope and examples (required for B/C): ______________________________
- Explanation and methodology rationale: ______________________________
- Evidence supporting applicability definitions: ______________________________
- Conditions/limitations and user-facing outcome: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-15 — Evidence-state semantics

**Question:** Approve current distinct states, and decide whether missing-field, source-unavailable and partial-evidence reasons need separate structured codes?

**Alternatives:** Retain current typed statuses; add reason codes; defer finer detail while retaining no-score behavior; other; not decided. Verified zero remains a value with provenance, not missing data.

- Selected decision/status: ______________________________
- Required states/reason codes and definitions: ______________________________
- Explanation and rationale: ______________________________
- Supporting examples by criterion: ______________________________
- Conditions/limitations: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

### D-16 — Return-to-origin

**Question:** How does the tourist choose whether the itinerary returns to its starting point, and what happens if origin or a supported return route is unavailable?

**Alternatives:** Explicit required yes/no choice; optional choice with an owner-specified default; defer return-leg optimization; other; not decided. This affects MO-GA route planning, not CARS destination scoring or objectives.

- Selected decision/status: ______________________________
- Tourist workflow/default and missing-origin behavior: ______________________________
- Explanation and rationale: ______________________________
- Supporting route/mode/water evidence needs: ______________________________
- Conditions/limitations: ______________________________
- Approver name/role: ______________________________
- Approval date: __________________  Effective policy version: __________________

## 3. Mathematical approval worksheet

Complete one row per criterion. If the rule is not ready, write **Not decided**; do not copy a suggested formula as approved without selecting it. All final numeric scores must be finite and in [0,1].

| Criterion / weight | Approved formula | Variables and units | Valid input domain | Output range | Boundary examples | Missing-data behavior | Required source evidence | Policy version / status |
|---|---|---|---|---|---|---|---|---|
| Interest/activity — 0.1548 |  |  |  | [0,1] or no score |  |  |  |  |
| Public rating — 0.1718 |  |  |  | [0,1] or no score |  |  |  |  |
| Weather — 0.1695 |  |  |  | [0,1] or no score |  |  |  |  |
| Budget — 0.1785 |  |  |  | [0,1] or no score |  |  |  |  |
| Distance — 0.1627 |  |  |  | [0,1] or no score |  |  |  |  |
| Available time — 0.1627 |  |  |  | [0,1] or no score |  |  |  |  |

### Weather parameters (owner supplied; no defaults)

- Approved activity/weather conditions and thresholds: ______________________________________________
- Units and valid ranges: ______________________________________________________________
- Forecast/observation time window and aggregation: ______________________________________________
- Minimum coverage and freshness rule: __________________________________________________
- Mapping to normalized output [0,1]: ___________________________________________________
- Rule/source/version and approver/date: __________________________________________________

### Distance parameters (owner supplied; no defaults)

- Distance evidence type (network route / geometry / other): ______________________________________
- Supported modes and separate rules/parameters for each: _______________________________________
- Straight-line labeling and limitations, if applicable: ___________________________________________
- Road/water route distinction and unsupported-route behavior: __________________________________
- Normalization mapping to [0,1] and boundary examples: _________________________________________
- Rule/source/version and approver/date: __________________________________________________

### Budget candidate allocation (required)

- Overall budget interpretation (total-group/per-person): __________________________________________
- Currency and verified conversion authority, if any: _____________________________________________
- Candidate-level allocation rule: ______________________________________________________
- Group-size and subgroup count application: ______________________________________________
- Included package/cost-component deduplication: __________________________________________
- Zero allocation behavior: _____________________________________________________________
- Rule/version and approver/date: _______________________________________________________

### Time candidate allocation (required)

- Candidate allowance (T_d) calculation: __________________________________________________
- Required duration (t_d) components (travel/visit/transfer/return): ______________________________
- One-way versus round-trip meaning: ____________________________________________________
- Over-allowance score/eligibility behavior: _______________________________________________
- Rule/version and approver/date: _______________________________________________________

## 4. External data source declaration worksheet

Declare sources and evidence, not credentials. Production availability must be verified separately; repository code or a local schema file alone does not establish operational access or current data.

| Source | Provider / authoritative organization | Data steward | Supported fields / units | Verification method | Freshness requirement | Missing-data behavior | Evidence reference / version | Status / approval |
|---|---|---|---|---|---|---|---|---|
| Destination directory |  |  | IDs, coordinates, status, category/activity links |  |  |  |  |  |
| Activity catalog |  |  | Activity IDs, destination links, categories, requirements |  |  |  |  |  |
| Preference/activity mapping |  |  | Canonical IDs and mapping version |  |  |  |  |  |
| Public destination ratings |  |  | Rating scale, aggregate meaning, review count if applicable |  |  |  |  |  |
| Weather provider |  |  | Forecast fields, units, timestamps, coverage |  |  |  |  |  |
| Destination/activity pricing |  |  | Amount, currency, unit, components, inclusions |  |  |  |  |  |
| Group pricing |  |  | Adult/child/elder rates and applicability |  |  |  |  |  |
| Date-specific availability |  |  | Opening/closure/eligibility by date |  |  |  |  |  |
| Road routing |  |  | Mode-specific route, distance, duration, date |  |  |  |  |  |
| Water transportation |  |  | Connection, operator, schedule, duration, validity |  |  |  |  |  |

## 5. Architecture approval worksheet

| Contract | Owner decision / selected behavior | Supporting requirement/evidence | Conditions / limitations | Approval status |
|---|---|---|---|---|
| GPS permission and manual fallback |  |  |  |  |
| Origin provenance and failure behavior |  |  |  |  |
| Whole-trip transportation mode |  |  |  |  |
| Per-leg mode and precedence |  |  |  |  |
| Unspecified mode behavior / MO-GA recommendation |  |  |  |  |
| Water-transfer evidence and unsupported route behavior |  |  |  |  |
| Return-to-origin tourist choice |  |  |  |  |
| Evidence shown/passed through tourist review |  |  |  |  |
| Evidence snapshot retention and privacy |  |  |  |  |
| Eligibility vocabulary and traveler suitability |  |  |  |  |

**Architecture approver name/role:** ______________________________  **Date:** __________  **Version:** __________

## 6. Consolidated approval summary

Use only these statuses: Approved; Approved with conditions; Rejected; Deferred; Unanswered; Insufficient evidence. “Insufficient evidence” requires an actual response that lacks evidence; if no response was made, mark “Unanswered.”

| Decision | Current status before owner completion | Owner status | Conditions/evidence reference | Approver/date/version |
|---|---|---|---|---|
| D-01 Criteria and weights | Unanswered |  |  |  |
| D-02 Scale and formula | Unanswered |  |  |  |
| D-03 Interest/activity | Unanswered |  |  |  |
| D-04 Rating | Unanswered |  |  |  |
| D-05 Weather | Unanswered |  |  |  |
| D-06 Budget | Unanswered |  |  |  |
| D-07 Distance | Unanswered |  |  |  |
| D-08 Available time | Unanswered |  |  |  |
| D-09 GPS/manual origin | Unanswered |  |  |  |
| D-10 Transportation modes | Unanswered |  |  |  |
| D-11 Water transport | Unanswered |  |  |  |
| D-12 Eligibility/suitability | Unanswered |  |  |  |
| D-13 Mixed group/pricing | Unanswered |  |  |  |
| D-14 Not applicable | Unanswered |  |  |  |
| D-15 Evidence states | Unanswered |  |  |  |
| D-16 Return to origin | Unanswered |  |  |  |

### Separate authorization decisions

#### A. Methodology approval

- [ ] Approved
- [ ] Approved with conditions
- [ ] Rejected
- [ ] Deferred
- [ ] Unanswered

Conditions/evidence: _________________________________________________________________  
Approver name/role: ______________________________  Date: __________  Version: __________

#### B. Mathematical policy approval

- [ ] Approved
- [ ] Approved with conditions
- [ ] Rejected
- [ ] Deferred
- [ ] Unanswered

Conditions/evidence: _________________________________________________________________  
Approver name/role: ______________________________  Date: __________  Version: __________

#### C. Data-source approval

- [ ] Approved
- [ ] Approved with conditions
- [ ] Rejected
- [ ] Deferred
- [ ] Unanswered

Conditions/evidence: _________________________________________________________________  
Approver name/role: ______________________________  Date: __________  Version: __________

#### D. Architecture approval

- [ ] Approved
- [ ] Approved with conditions
- [ ] Rejected
- [ ] Deferred
- [ ] Unanswered

Conditions/evidence: _________________________________________________________________  
Approver name/role: ______________________________  Date: __________  Version: __________

#### E. Controlled development implementation authorization

- [ ] Approved
- [ ] Approved with conditions
- [ ] Rejected
- [ ] Deferred
- [ ] Unanswered

Authorized implementation scope/branch/environment: _____________________________________  
Conditions/evidence: _________________________________________________________________  
Approver name/role: ______________________________  Date: __________  Version: __________

#### F. Production deployment authorization — separate from implementation

- [ ] Approved
- [ ] Approved with conditions
- [ ] Rejected
- [ ] Deferred
- [ ] Unanswered

Release/systems covered: _____________________________________________________________  
Security, rollback and operational evidence reference: ____________________________________  
Authorized approver name/role: __________________________  Date: __________  Version: __________

**Important:** Development implementation authorization does not authorize production deployment or CARS activation. Production approval requires its own completed security and operational review. Neither is granted by this blank form.

## 7. Owner closeout

- Decisions approved: _________________________________________________________________
- Decisions rejected or deferred: ______________________________________________________
- Decisions still unanswered/insufficient: _______________________________________________
- Evidence attached or referenced: ____________________________________________________
- Follow-up owner and due date: _______________________________________________________
- Owner name/role: ______________________________  Signature/record reference: ______________________________
- Completion date: __________________  Effective policy bundle version: __________________

**Pre-completion state:** All fields in this document are blank response fields. No formulas, alternatives, source declarations, conditions, or approvals are automatically accepted. Keep CARS unavailable for ranking until the required policy and evidence gates are separately validated.
