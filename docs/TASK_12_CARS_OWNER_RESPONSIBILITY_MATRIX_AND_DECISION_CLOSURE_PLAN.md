# TASK 12 --- CARS Owner Responsibility Matrix and Policy Decision Closure Plan

**Status:** Planning and responsibility assignment only. Roles below are
recommendations, not confirmed appointments. No owner decisions,
approvals, external source verification, implementation authorization,
or production authorization are created by this document.

## 1. Executive summary

Task 11 reports that all sixteen decisions D-01--D-16 are
**UNANSWERED**. The Task 10 response form and source declaration
worksheet were blank. Policy readiness and technical readiness are both
**NO**; controlled implementation and production deployment are **NOT
AUTHORIZED**.

This plan identifies the recommended accountable role, supporting
reviewers, exact information and evidence required, expected
deliverable, dependencies, and current blocker status for each decision.
It does not invent names or assume any role has accepted responsibility.

The six criteria, survey-derived weights, and target 0--1 weighted
formula are documented in the prior design record. However, Task 11
reports D-01 and D-02 as unanswered for formal provenance/approval.
Those target statements are not treated here as signed approvals.

## 2. Scope and evidence basis

The supplied Task 11 report is the detailed status baseline. The Task
06--10 decision descriptions and prior design outputs are used as
project context; their exact files were not independently re-opened
during preparation of this plan. Where detail is needed, this document
follows the statuses and blocker descriptions recorded in Task 11 and
does not claim a fresh file-level audit.

Evidence rules: - A recommended role is not an assigned or accepting
owner. - A prior recommendation is not an owner approval. - A repository
interface, local schema backup, test fixture, or parser does not prove a
deployed source contract or populated production data. - No actual owner
names, approver identities, dates, policy versions, provider
credentials, or external evidence are invented. - All D-01--D-16
statuses remain **UNANSWERED**, as reported by Task 11.

## 3. Decision owner responsibility matrix

"Recommended accountable role" means the role that should coordinate and
submit the decision. The project owner must formally assign an
individual and confirm acceptance.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ID      Decision             Recommended            Supporting / reviewing      Exact information required    Required evidence          Expected           Dependencies   Status
                               accountable role       roles                                                                                deliverable                       
  ------- -------------------- ---------------------- --------------------------- ----------------------------- -------------------------- ------------------ -------------- ----------------
  D-01    Six criteria and     Project owner /        Research adviser;           Confirm criterion wording,    Approved methodology;      Signed             D-02, D-14     **UNANSWERED**
          survey weights       research lead          statistics expert           exact weights, derivation,    survey instrument/results  criterion/weight                  
                                                                                  source instrument/results,    or weight derivation;      decision and                      
                                                                                  rounding and authoritative    dated adviser/owner        provenance record                 
                                                                                  version                       sign-off                                                     

  D-02    Score scale and      Project owner /        Mathematics/statistics      Confirm \[0,1\] domain,       Approved methodology;      Versioned score    D-01; precedes **UNANSWERED**
          weighted formula     research lead          expert; system architect;   finite-value rules, six-term  synthetic worked examples; contract and       scoring work   
                                                      backend and UI leads        formula, sum tolerance,       consumer inventory and     migration                         
                                                                                  display semantics and         migration review           acceptance                        
                                                                                  migration from current                                   criteria                          
                                                                                  \[0,100\] consumers                                                                        

  D-03    Interest/activity    Project owner /        Taxonomy data steward;      Confirm preference/activity   Authoritative taxonomy     Versioned mapping  D-14; activity **UNANSWERED**
          match and empty      research lead          backend lead; methodology   IDs, authoritative mapping,   export/API documentation;  contract and       source; D-15   
          preference                                  reviewer                    completeness/version,         mapping                    approved matching                 
                                                                                  preference confirmation,      version/completeness       rule                              
                                                                                  unsupported IDs and empty-set record; synthetic edge                                       
                                                                                  behavior                      cases; D-14-compatible                                       
                                                                                                                decision                                                     

  D-04    Public destination   Project owner / data   Rating provider/steward;    Select source; define 0--5    Provider documentation;    Approved rating    D-02; D-15     **UNANSWERED**
          rating               policy owner           backend lead; methodology   meaning, aggregate type,      sample records with        source/evidence                   
                                                      reviewer                    identity matching,            provenance;                contract and                      
                                                                                  verified-zero semantics,      scale/aggregation and      normalization                     
                                                                                  freshness and fallback        freshness definitions      decision                          
                                                                                  behavior                                                                                   

  D-05    Weather suitability  Project owner / domain Weather provider; activity  Define activity-specific      Activity-weather           Versioned weather  D-02, D-03,    **UNANSWERED**
                               policy owner           steward; meteorology/domain weather requirements, visit   authority; provider        classifier,        D-15           
                                                      expert; statistics          window, forecast horizon,     coverage/API docs;         aggregation and                   
                                                      reviewer; backend lead      variables/units, classifier   units/freshness;           source contract                   
                                                                                  thresholds, coverage,         representative forecasts;                                    
                                                                                  aggregation and normalization approved classifier and                                      
                                                                                                                test vectors                                                 

  D-06    Budget score and     Project owner /        Finance/costing expert;     Select formula; define        Approved budget            Approved candidate D-02, D-13,    **UNANSWERED**
          candidate allocation research lead          pricing steward; backend    candidate allocation from     methodology; provider rate budget allocation  D-15           
                                                      lead; statistics reviewer   overall budget; per-person vs cards/sample prices;       and score policy                  
                                                                                  group basis; group            cost-component rules;                                        
                                                                                  composition; applicable       group rates; synthetic                                       
                                                                                  components; units/currency;   examples                                                     
                                                                                  package deduplication;                                                                     
                                                                                  zero-budget behavior                                                                       

  D-07    Distance metric and  Project owner /        Routing                     Define distance measure,      Routing documentation and  Versioned distance D-02,          **UNANSWERED**
          normalization        transportation policy  specialist/provider; system supported supplied mode,      sample responses; mode     policy and route   D-09--D-11,    
                               owner                  architect; backend lead     per-mode normalization, route coverage; units/freshness; evidence contract  D-15           
                                                                                  type/direction/date and       approved policy and                                          
                                                                                  unavailable behavior; CARS    boundary vectors                                             
                                                                                  must not choose mode                                                                       

  D-08    Available            Project owner /        Transportation specialist;  Define candidate allowance,   Time-allocation            Candidate time     D-02, D-07,    **UNANSWERED**
          travel-time          research lead          MO-GA architect; backend    daily/trip allocation,        methodology; route         contract and       D-09--D-11,    
          compatibility                               lead; methodology reviewer  one-way/round-trip, visit and duration docs; destination approved scoring   D-15           
                                                                                  transfer duration, and        visit-duration source;     rule                              
                                                                                  over-limit treatment          synthetic cases                                              

  D-09    GPS default and      Project owner /        Privacy/security officer;   Define consent, permission    Platform permission        Approved origin    D-07, D-08,    **UNANSWERED**
          manual fallback      product owner          mobile/location engineer;   request, GPS default,         documentation; privacy     policy and typed   D-10, D-16     
                                                      architect; UX lead          denial/unavailable/timeout,   review; UX flow; origin    provenance                        
                                                                                  manual fallback, provenance   model review               contract                          
                                                                                  and correction                                                                             

  D-10    Whole-trip/per-leg   Project owner / system Transportation specialist;  Define precedence, explicit   Trip/leg model; provider   Versioned mode     D-07--D-09,    **UNANSWERED**
          modes                architect              MO-GA lead; backend and UX  per-leg mode, unspecified     mode coverage; workflow    input contract for D-11, D-16     
                                                      leads                       mode, persistence/handoff and diagram; API/model         CARS/MO-GA                        
                                                                                  provider capability; CARS     contract and precedence                                      
                                                                                  must not select best mode     tests                                                        

  D-11    Verified water       Project owner /        Maritime/ferry              Identify maintained           Official operator          Approved           D-07, D-08,    **UNANSWERED**
          transport            transportation policy  authority/provider;         authority; define             schedule/API docs; dated   water-connection   D-10, D-16     
                               owner                  transportation specialist;  connection/terminal identity, sample connections; source contract, or                      
                                                      backend lead                schedule/date, transfer mode, terms; route-segment       documented                        
                                                                                  distance/duration, freshness  review                     unavailable policy                
                                                                                  and disruption behavior                                                                    

  D-12    Eligibility and      Project owner / domain Accreditation authority;    Define canonical              Official status            Versioned          D-01, D-13;    **UNANSWERED**
          traveler suitability policy owner           destination steward;        approval/accreditation        definitions; source field  eligibility policy destination    
                                                      suitability/accessibility   statuses, source, required    docs; approved suitability and vocabulary     source         
                                                      expert; backend lead        fields, suitability code      taxonomy; sample records                                     
                                                                                  meanings and unknown/missing                                                               
                                                                                  treatment                                                                                  

  D-13    Mixed-group          Project owner /        Finance/pricing expert;     Define adult/child/elder      Official provider rate     Group composition  D-06, D-12;    **UNANSWERED**
          composition and      costing policy owner   provider data steward;      bands only from authority,    cards/terms; age-band      and pricing        price sources  
          pricing                                     suitability expert; backend counts, group consistency,    definitions; sample price  applicability                     
                                                      lead                        price units, subgroup         records; group model       contract                          
                                                                                  applicability and             review                                                       
                                                                                  missing-count behavior                                                                     

  D-14    Not-applicable       Project owner /        Research adviser;           Select and justify handling   Methodology rationale;     Formal             D-01, D-02,    **UNANSWERED**
          criteria             research-methodology   statistics expert;          while preserving fixed six    alternatives comparison;   not-applicable     D-03, D-15     
                               authority              architect; backend lead     weights and no silent         worked                     rule with testable                
                                                                                  redistribution; define        denominator/contribution   examples                          
                                                                                  ranking consequence and       examples; signed decision                                    
                                                                                  applicability domain                                                                       

  D-15    Evidence-state       Project owner / data   Architect; backend lead;    Confirm missing, invalid,     Data dictionary; freshness Versioned          D-02;          **UNANSWERED**
          semantics            governance owner       data stewards;              stale, unsupported, not       policies; evidence-state   evidence/result    D-03--D-13;    
                                                      privacy/security officer    applicable, verified zero and contract;                  contract and       D-14           
                                                                                  insufficient; reason codes,   privacy/retention decision reason-code                       
                                                                                  provenance, freshness, rule   if snapshots retained;     catalogue                         
                                                                                  version and retention/display test cases                                                   

  D-16    Return-to-origin for Project owner /        MO-GA architect;            Define explicit tourist       Approved user flow and     Explicit           D-09--D-11     **UNANSWERED**
          MO-GA                product owner          transportation specialist;  choice, default/unspecified   trip model; provider       return-to-origin                  
                                                      backend and UX leads        behavior, missing origin and  return-leg capability;     input contract for                
                                                                                  unsupported return route;     architecture decision      MO-GA                             
                                                                                  confirm no effect on CARS     record; synthetic cases                                      
                                                                                  ranking                                                                                    
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 4. Decision dependency matrix

  ------------------------------------------------------------------------
  Decision                Coordinate with         Dependency reason
  ----------------------- ----------------------- ------------------------
  D-01                    D-02, D-14              Criteria/weights
                                                  establish methodology;
                                                  not-applicable handling
                                                  must preserve it.

  D-02                    D-03--D-08, D-14, D-15  Numeric policies need
                                                  common score and
                                                  evidence contracts.

  D-03                    D-14, activity catalog, Empty preference and
                          D-15                    incomplete taxonomy
                                                  require
                                                  applicability/evidence
                                                  rules.

  D-04                    D-15, rating provider   Rating depends on
                                                  authority, scale, zero
                                                  semantics and freshness.

  D-05                    D-03, D-15, weather     Weather depends on
                          provider                activities, activity
                                                  requirements and
                                                  forecast coverage.

  D-06                    D-13, D-15, pricing     Candidate budget
                          sources                 requires group basis,
                                                  rates, units and package
                                                  rules.

  D-07                    D-09--D-11, D-15,       Distance needs origin,
                          routing provider        supplied mode and
                                                  road/water route
                                                  evidence.

  D-08                    D-07, D-09--D-11, D-15  Candidate duration needs
                                                  route, visit and
                                                  transfer evidence plus
                                                  allowance.

  D-09                    D-07, D-08, D-10, D-16  Origin is an input to
                                                  route, mode and return
                                                  behavior.

  D-10                    D-07, D-08, D-11, D-16  Mode semantics govern
                                                  route requests and
                                                  optimizer handoff.

  D-11                    D-07, D-08, D-10, D-16  Water segments affect
                                                  distance, duration, mode
                                                  and return feasibility.

  D-12                    Destination/status      Eligibility requires
                          source, D-13            authoritative
                                                  destination status and
                                                  group suitability
                                                  semantics.

  D-13                    D-06, D-12              Group counts/rates
                                                  affect cost and
                                                  potentially approved
                                                  suitability gates.

  D-14                    D-01--D-03, D-15        Not-applicable handling
                                                  governs whether the
                                                  six-term score can be
                                                  produced.

  D-15                    D-03--D-13              Shared evidence rules
                                                  govern scoreability and
                                                  provenance.

  D-16                    D-09--D-11              Return-to-origin depends
                                                  on origin, mode and
                                                  route/transfer
                                                  availability.
  ------------------------------------------------------------------------

### Dependency sequence

1.  Confirm decision authority; resolve D-01 and D-02 as formal
    methodology/score-contract decisions.
2.  Resolve D-14 and D-15 early; coordinate D-14 with D-03.
3.  Define D-12 and D-13 with authoritative destination status and
    pricing evidence.
4.  Resolve D-03--D-08 only when their mathematical domains and source
    requirements are defined.
5.  Resolve D-09--D-11 and D-16 as a coordinated transportation/model
    package.
6.  Verify source contracts for every required criterion before
    technical readiness is reconsidered.
7.  Request controlled implementation authorization only after policy
    and technical gates pass; production authorization remains separate.

## 5. Priority classification

These priorities are work queues, not status changes. All decisions
remain **UNANSWERED** until formally closed.

### Priority 1 --- Foundational methodology

-   D-01: Criteria and survey-weight provenance.
-   D-02: Score scale, formula and coordinated migration target.
-   D-14: Not-applicable handling without silent redistribution.
-   D-15: Evidence-state and provenance semantics.

These establish what a score means, when ranking is possible, and how
missing/inapplicable evidence is represented.

### Priority 2 --- Mathematical scoring policies

-   D-03: Interest/activity matching.
-   D-04: Rating normalization.
-   D-05: Weather classifier, aggregation and normalization.
-   D-06: Budget formula and candidate allocation.
-   D-07: Distance measure and normalization.
-   D-08: Candidate time allowance and duration scope.

These depend on Priority 1 and, for several criteria, verified external
data.

### Priority 3 --- External data and source verification

Run source collection in parallel where possible:

-   Destination directory, stable IDs, statuses and coordinates.
-   Activity catalog, activity IDs and complete preference mapping.
-   Public rating source, aggregation, zero provenance and freshness.
-   Weather provider, coverage, units and activity-weather requirements.
-   Pricing/rate sources, group rates, units, currencies and package
    inclusions.
-   Date-specific destination availability, where relevant.
-   Road routing provider, supported modes, route types, units and
    freshness.
-   Official water-transport connection/schedule authority.

A formula without supported inputs cannot produce a valid production
score.

### Priority 4 --- Architecture and transportation contracts

-   D-09: GPS/manual origin, consent and provenance.
-   D-10: Whole-trip/per-leg/unfixed mode contract.
-   D-11: Verified water transport representation.
-   D-16: Return-to-origin choice for MO-GA.

Coordinate these with D-07 and D-08. CARS must not choose a best mode or
optimize route order.

### Priority 5 --- Final implementation authorization

This is a gate, not an additional D-number. It requires closed policy
decisions, verified sources, approved typed contracts, test vectors,
scoped change plan, rollback, security/privacy review where applicable,
and explicit written authorization. Production deployment requires a
separate later approval.

## 6. Evidence collection checklist

### 6.1 Available or reported as available

-   [ ] Task 11 report: D-01--D-16 unanswered; Task 10 response and
    source declaration worksheets blank.
-   [ ] Task 10 blank response/source form, as described in Task 11.
-   [ ] Prior task decision descriptions and proposals as referenced in
    the project record. Confirm exact current repository versions before
    formal assignment.
-   [ ] Repository architecture described by Task 11: weighted engine,
    typed evidence preparation, injectable provider/scoring boundaries,
    separate eligibility evaluator and unavailable default.
-   [ ] Known mismatches described in Task 11: current \[0,100\] vs
    target \[0,1\]; absent per-leg mode and return fields; GPS not
    modeled as planner origin; visit/transfer duration exclusions;
    evidence metadata not reaching review UI.

These are design/repository evidence only, not proof of deployed data or
operational provider access.

### 6.2 Formal owner approvals required

-   [ ] Decision authority and delegated approvers, with role and scope.
-   [ ] D-01 methodology and weight provenance.
-   [ ] D-02 numeric scale, formula and migration acceptance.
-   [ ] D-03--D-08 criterion policies and synthetic boundary examples.
-   [ ] D-09--D-16 architecture, eligibility, applicability and evidence
    decisions.
-   [ ] D-14 methodology rationale for not-applicable handling.
-   [ ] Privacy/security review for location permission, provenance and
    any retained evidence snapshot.
-   [ ] Separate controlled implementation authorization after readiness
    validation.
-   [ ] Separate production deployment/security authorization after
    implementation acceptance.

### 6.3 External evidence required

-   [ ] Destination authority, stable IDs, status definitions,
    coordinates and update cadence.
-   [ ] Activity catalog authority, stable IDs, destination-activity
    relationships, lifecycle and completeness.
-   [ ] Complete, versioned preference-to-activity mapping from an
    authorized domain owner.
-   [ ] Rating provider docs, scale/aggregate meaning, destination
    matching, timestamps, zero provenance and freshness.
-   [ ] Weather provider docs, forecast horizon, interval granularity,
    units, location coverage, retrieval time and freshness.
-   [ ] Authoritative activity-specific weather requirements and their
    policy owner.
-   [ ] Price/rate evidence for applicable
    destination/activity/transport/food/accommodation components;
    currency, quantity, unit, group basis, verification, source,
    timestamp and package inclusions.
-   [ ] Adult/child/elder definitions and applicable rates from
    authoritative providers; do not infer age bands or discounts.
-   [ ] Road routing provider contract: modes, network distance,
    duration, route type, units, date sensitivity, availability and
    freshness.
-   [ ] Official water-transport schedule/API with dated connection,
    terminals, route/duration and disruption updates.
-   [ ] Date-specific destination availability source where used.
-   [ ] Deployed schema/API compatibility evidence obtained through
    separately authorized review; local backups are not production
    proof.

### 6.4 Technical validation evidence required

-   [ ] Source-to-domain field mapping for every criterion, including
    nullability and provenance.
-   [ ] Data dictionary and reason codes for missing, invalid, stale,
    unsupported, not applicable, verified zero and insufficient.
-   [ ] Typed input/output contracts and versioned policy identifiers.
-   [ ] Synthetic test vectors for boundaries, monotonicity, missing and
    invalid data.
-   [ ] Hand-calculated weighted examples using the exact six weights.
-   [ ] Tests proving no missing score becomes zero and no weight is
    redistributed.
-   [ ] Tests proving eligibility remains separate and CARS does not
    optimize route order or choose modes.
-   [ ] Evidence/provenance continuity tests through tourist review,
    subject to privacy approval.
-   [ ] Regression evidence for manual/circuit planning and unchanged
    MO-GA objectives.
-   [ ] After authorized implementation: focused tests, full Flutter
    tests, static analysis and diff checks.
-   [ ] Before production: release review, rollback, access controls,
    monitoring and operational owner.

## 7. Decision closure workflow

1.  **Assign owners:** The project owner names one accountable
    individual per decision and confirms reviewer roles and acceptance.
    Until then, Section 3 contains recommendations only.
2.  **Issue decision packets:** Each packet states the exact question,
    current status, options (clearly marked proposals), required
    evidence, dependencies and blank response fields.
3.  **Collect evidence:** Owners obtain source documents, provider
    contracts, sample records, policy references and technical
    specifications. Record source/version/date/units/coverage; never
    place credentials in the decision record.
4.  **Independent review:** Methodology decisions go to
    research/statistics reviewers; formulas to mathematics and
    engineering reviewers; source contracts to data stewards/providers;
    transport to routing/MO-GA specialists; location to privacy/security
    and mobile reviewers.
5.  **Record owner decision in Task 10:** Record explicit outcome,
    rationale, approver, role, date, effective version, evidence
    references, conditions and scope. Blank or ambiguous responses
    remain unanswered.
6.  **Validate decision and evidence:** Check authority, authenticity,
    completeness, mathematical domain, units, freshness, edge cases,
    consistency with other decisions and CARS/MO-GA boundaries. Return
    contradictions to the owner; do not silently reconcile them.
7.  **Update registers:** Update the decision and blocker registers with
    outcome, evidence, version, conditions, dependencies and validator.
    Preserve prior versions and audit history.
8.  **Reassess readiness:** Policy readiness requires approved, testable
    methodology and scoring rules. Technical readiness requires verified
    source contracts, typed inputs/outputs, provenance and acceptance
    tests. Unmet conditions remain blockers for affected scope.
9.  **Obtain controlled implementation authorization:** Submit exact
    scope, files, tests, acceptance criteria, risks and rollback. Obtain
    explicit written authorization. This does not authorize production
    access or deployment.
10. **Obtain production authorization separately:** After implementation
    acceptance, complete security, privacy, data-access, operational and
    release reviews; confirm monitoring, incident response, rollback and
    support ownership; record separate deployment approval.

## 8. Decision closure criteria

A decision is **CLOSED --- APPROVED** only when:

1.  An explicit decision is recorded; no implied or conversational-only
    approval.
2.  Approver name, role, authority and scope are recorded.
3.  Decision date and effective policy/version are recorded.
4.  Required evidence is attached or cited with source, version/date and
    limitations.
5.  Independent review is documented where appropriate.
6.  Mathematical rules define domain, units, boundaries, missing-data
    behavior and reproducible examples.
7.  Technical contracts identify field meaning, source, provenance,
    freshness, nullability and unsupported cases.
8.  Dependencies and cross-decision consistency are checked.
9.  Conditions, exclusions and limitations are documented with follow-up
    ownership.
10. Decision and blocker registers are updated without erasing history.

Other outcomes: - **APPROVED WITH CONDITIONS:** conditions and approver
recorded; affected work remains blocked until conditions are met. -
**REJECTED:** rationale recorded; a replacement decision is required if
the capability remains in scope. - **DEFERRED:** reason and
reconsideration trigger recorded; dependent capability remains
blocked. - **INSUFFICIENT EVIDENCE:** missing evidence is itemized and
assigned; no score/source claim is activated. - **UNANSWERED:** no valid
owner decision exists.

Administrative closure as rejected or deferred does not make the
dependent capability ready.

## 9. Remaining blocker summary

  -----------------------------------------------------------------------
  Area                    Current finding         Closure requirement
  ----------------------- ----------------------- -----------------------
  Owner decisions         D-01--D-16 unanswered   Assign approvers;
                                                  complete and validate
                                                  Task 10 responses

  Methodology/weights     Target documented, but  Confirm source
                          D-01/D-02               methodology and approve
                          approval/provenance     versioned score
                          unanswered              contract

  Score scale             Target \[0,1\]          Approve coordinated
                          conflicts with current  migration before
                          \[0,100\]               changes

  Interest/activity       Mapping authority and   Supply complete
                          empty-preference        mapping; resolve D-14
                          consequence unresolved  

  Rating                  Source, scale, zero     Approve provider
                          provenance and          contract and evidence
                          freshness unverified    policy

  Weather                 Activity requirements,  Approve versioned
                          classifier, aggregation classifier and verify
                          and normalization       forecast
                          absent                  source/coverage

  Budget                  Candidate allocation,   Approve allocation and
                          group/pricing basis,    verified pricing
                          components and          contracts
                          zero-budget behavior    
                          unresolved              

  Distance                Metric and mode         Approve policy and
                          normalization           verify routing evidence
                          unresolved              

  Time                    Candidate allowance and Approve
                          duration scope          duration/allocation
                          unresolved;             contract and verify
                          visit/transfer          sources
                          durations excluded by   
                          current assessment      

  Eligibility             Canonical               Obtain authoritative
                          status/accreditation    definitions
                          and suitability         
                          vocabulary unconfirmed  

  Origin/modes            GPS/manual behavior     Approve
                          conflict; per-leg       consent/fallback and
                          contract absent         typed mode contract

  Water transport         No authoritative        Verify source or retain
                          connection/schedule     unavailable behavior
                          evidence                

  Return-to-origin        No explicit trip-model  Approve tourist choice
                          field reported          and MO-GA handoff

  Evidence/privacy        Prepared evidence       Approve
                          reportedly does not     display/retention
                          reach review; retention contract and test
                          unresolved              continuity

  Authorization           No controlled           Obtain separate written
                          implementation or       approvals after
                          production approval     readiness gates
  -----------------------------------------------------------------------

## 10. Recommended final sequence

1.  Project owner confirms decision authority and assigns accountable
    individuals/reviewers.
2.  Close foundational D-01, D-02, D-14 and D-15, including methodology
    provenance and not-applicable handling.
3.  Launch source-evidence collection in parallel for destination,
    activity/taxonomy, rating, weather, pricing/group rates,
    availability, routing and water transport.
4.  Close D-12 and D-13 using authoritative status and pricing
    definitions.
5.  Approve D-03--D-08 with mathematical domains, source requirements,
    boundaries and synthetic test vectors.
6.  Close D-09--D-11 and D-16 together as a transportation/model
    package.
7.  Independently validate each response, evidence reference, condition,
    dependency and version.
8.  Publish a new decision matrix and readiness assessment; do not claim
    readiness while required policies or sources remain unverified.
9.  Request controlled implementation authorization with exact scope,
    tests, acceptance criteria, risks and rollback.
10. Implement and test only within the authorized scope; preserve safe
    unavailable behavior outside it.
11. Obtain production security, privacy, data-access and operational
    approval separately after implementation acceptance.

## 11. Final determination

This plan proposes a role-based accountability structure, dependency
order, evidence checklist and closure workflow. It does **not** assign
named individuals, record owner acceptance, approve formulas, verify
providers, or change decision status.

Until owners are assigned and evidence and approvals are validated:

-   D-01--D-16 remain **UNANSWERED**, as reported by Task 11.
-   Policy readiness: **NO**.
-   Technical readiness: **NO**.
-   Controlled implementation: **NOT AUTHORIZED**.
-   Production deployment: **NOT AUTHORIZED**.

**Closeout:** Planning document only. No application code, tests,
configuration, SQL, database object or Supabase project is changed or
authorized by this plan. Existing Task 06--11 documents must be
preserved.
