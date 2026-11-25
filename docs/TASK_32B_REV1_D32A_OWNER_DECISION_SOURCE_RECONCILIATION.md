# Task 32B Rev 1 — D32A Owner Decision Source Reconciliation

**Project:** SAMAL NAV
**Status:** Conversation decision record reconciled; detailed Task 32A worksheet wording remains incomplete.
**Authorization:** Documentation and read-only inspection only. No implementation authorization.

## 1. Reconciliation result

The owner explicitly confirmed in this conversation that **D32A-01 through D32A-22 are all Option A**. The previous Task 32B specification incorrectly marked every D32A selection unavailable. Its master traceability matrix has been corrected so each D32A row records Option A as owner-selected, with the selection evidence identified as the owner’s conversation decision history.

The repository contains no Task 32A document, and no complete Task 32A worksheet responses were included with this revision request. Accordingly:

- The selected option for each of the 22 decisions is confirmed as Option A.
- The topic sequence below is recorded from the owner’s current instruction.
- The full option wording and technical conditions for D32A-01–D32A-18 remain undocumented here. They are not reconstructed or invented.
- For D32A-19–D32A-22, the current request supplies the topics but not complete worksheet responses. No additional wording is inferred.
- The selections remain architectural directions. They do not grant authorization to modify code, tests, Hive data, SQL, migrations, databases, or Supabase.

## 2. Confirmed selections and established topics

| Decision | Confirmed selection | Topic recorded from the conversation | Documentation status |
|---|---|---|---|
| D32A-01 | Option A | Transportation catalog architecture | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-02 | Option A | Transportation identifiers | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-03 | Option A | Legacy compatibility | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-04 | Option A | Inactive transportation modes | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-05 | Option A | Transportation categories | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-06 | Option A | Typed transportation attributes | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-07 | Option A | Service availability | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-08 | Option A | Catalog versioning | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-09 | Option A | Historical display labels | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-10 | Option A | Unknown transportation identifiers | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-11 | Option A | MO-GA compatibility | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-12 | Option A | Transportation usage permissions | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-13 | Option A | Unsupported transportation modes | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-14 | Option A | Mixed supported/unsupported transportation | Topic known; full worksheet wording/conditions to reconcile. |
| D32A-15 | Option A | Unsupported legs connected to fixed commitments | Topic known; full worksheet response not supplied. |
| D32A-16 | Option A | Protected segment boundaries | Topic known; full worksheet response not supplied. |
| D32A-17 | Option A | Overlapping commitments | Topic known; full worksheet response not supplied. |
| D32A-18 | Option A | Manual editing protection | Topic known; full worksheet response not supplied. |
| D32A-19 | Option A | Commitment version history and recovery | Topic known; complete worksheet response not supplied. |
| D32A-20 | Option A | Staged Hive writes and recovery journal | Topic known; complete worksheet response not supplied. |
| D32A-21 | Option A | Restricted Safe Mode | Topic known; complete worksheet response not supplied. |
| D32A-22 | Option A | Validation-based restoration | Topic known; complete worksheet response not supplied. |

## 3. Changes to the Task 32B specification

Updated [Task 32B — Owner Decision Consolidation and Final Technical Specification](TASK_32B_SAMALNAV_OWNER_DECISION_CONSOLIDATION_AND_FINAL_TECHNICAL_SPECIFICATION.md):

- Replaced the blanket “D32A selections unavailable” statement with the confirmed Option A selections and source limitations.
- Revised all 22 D32A master-matrix rows to show Option A, the supplied topic, a technical mapping clearly labeled as proposal, and the remaining documentary blocker.
- Updated the decision hierarchy, implementation roadmap, blocker list, readiness verdict, and closeout record.
- Left all D29 and D31A selected options unchanged.
- Retained the **Not ready for coding** verdict and separate security/implementation authorization gates.

The technical specification in Task 32B remains a proposal. In particular, catalog identifiers/categories/capabilities, protected-commitment semantics, Hive staging/recovery behavior, and A-13/A-14/A-11 dependencies are not made owner-approved merely by recording Option A selections.

## 4. Validation

- The Task 32B master matrix contains D29-01–D29-17, D31A-01–D31A-22, and D32A-01–D32A-22 exactly once each (61 decision rows).
- No D29 or D31A selection was changed by this reconciliation.
- No tests, analyzer, or build were run.
- No application code, tests, SQL, migrations, Hive data, database, or Supabase state was changed or accessed.
- `git diff --check`: **passed** (exit code 0).
- New-document trailing-whitespace check: **passed**.

## 5. Remaining source and readiness blockers

1. Reconcile the detailed Task 32A worksheet, particularly full option descriptions and conditions for D32A-01–D32A-18 and complete responses for D32A-19–D32A-22, if those records are available.
2. Close the technical contracts listed in the updated Task 32B document. Option A selections alone do not settle schema fields, algorithm rules, catalog capability values, or platform-specific Hive recovery.
3. Obtain separate implementation authorization. A-14 independent security review and applicable A-13/A-11/A-15/A-16 gates remain separate.

**Final status:** The 22 Option A selections are confirmed and recorded. Documentary detail reconciliation and technical readiness remain open. Implementation is not authorized.

