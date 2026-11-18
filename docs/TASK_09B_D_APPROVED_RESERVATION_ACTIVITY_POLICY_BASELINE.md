# Task 09B-D — Approved Reservation and Activity Policy Baseline

**Status:** Technical and functional baseline consolidated from the project-owner-approved Task 09B-C decisions. This document records policy; it does not authorize implementation, schema changes, or production access.

## 1. Executive summary

The approved design adds tourist-entered reservation information and organized activity/event discovery to the existing itinerary-planning workflow. Reservation events are fixed scheduling constraints. They are not destinations, ordinary MO-GA genes, bookings made by SAMAL NAV, or a fourth planning method. The three existing planning methods remain Manual Selection, Circuit-Based Planning, and System-Generated Planning; CARS remains exclusive to System-Generated Planning.

The recommended architecture is a server-persisted itinerary draft with owner-scoped reservation-event children, so an authenticated tourist can continue work across devices and enter reservation information before saving an itinerary. This is a design recommendation consistent with the approved policy; the current repository does not implement persisted drafts or cross-device synchronization. Offline synchronization remains a separate future capability.

Activities and events require a separate publishing and discovery capability. The repository has no complete tourist activity/event directory, publisher workflow, notification center, or reservation-aware scheduling integration. Local migrations mention some related structures, but they do not establish the deployed schema. The supplied production facts do establish an existing `public.reservations` table used for establishment-side reservations; it must not be reused for tourist-entered external reservation information.

The existing MO-GA has three objectives: minimize route distance, maximize stops reached within the daily time limit, and minimize variation in visit-plus-travel time. Future scheduling must honor fixed events and preserve those objectives; it must not add budget, weather, event popularity, or reservation data as new objectives. The current engine cannot represent event windows, waiting, accommodation stays, or overnight location continuity. Dynamic Self-Healing is not implemented in the inspected repository.

No code, SQL, migration, production database object, or production record is changed by this baseline. The owner decisions below are treated as approved, while implementation-level details explicitly listed in Section 11 remain unresolved.

## 2. Scope, evidence labels, and non-goals

### Evidence labels

- **Approved policy:** a Task 09B-C project-owner decision captured here as a requirement, not a new recommendation.
- **Verified repository finding:** behavior or structure observed in checked-in application code or local migrations. A migration declaration does not prove a deployed object exists.
- **Owner-supplied production fact:** deployed information supplied by the project owner; it is not independently re-queried in this task.
- **Recommendation:** a proposed implementation direction that still needs design review where identified.
- **Open technical decision:** a detail not settled by the approved policy and requiring evidence, architecture work, or owner approval.

### Non-goals

This document does not implement reservations, activities, circuits, CARS integration, itinerary persistence, event-aware optimization, Dynamic Self-Healing, notifications, offline sync, or any database change. It does not authorize use of `public.reservations`, external provider access, or any new business policy.

## 3. Complete approved policy matrix

The IDs in this table are traceability references used in Section 14. The decisions are approved baseline requirements, not questions reopened for approval.

| ID | Approved policy | Implementation consequence |
|---|---|---|
| AP-01 | Reservation information is persisted with a server-persisted itinerary draft. Tourists can continue drafts and events across devices; reservation information can exist before an itinerary is saved. Offline sync is separate future work and is not currently available. | Draft identity and authenticated ownership must exist before reservation UI is connected to persistence. Do not label local Hive snapshots as synchronization. |
| AP-02 | Establishment selection may use the establishment directory or an off-directory entry. An off-directory entry uses tourist-entered name/location snapshots and has no fabricated establishment or destination UUID. | Model stable IDs as nullable when no verified catalog identity exists; retain entered snapshots. |
| AP-03 | Exactly four reservation event types are supported: Accommodation, Activity, Dining, and Other. Other requires a description. | Use a closed event-type contract; require a non-empty description conditionally for Other. |
| AP-04 | Start-only appointments are allowed, but complete scheduling feasibility cannot be claimed until an end time or duration is supplied. | Preserve an incomplete interval and return an incomplete/unknown feasibility result rather than assuming a duration. |
| AP-05 | The tourist supplies either the end time or duration; the system may calculate the missing counterpart. Preserve which value was supplied and do not invent a value. | Store source input and derived counterpart distinctly, with provenance. |
| AP-06 | Intervals are half-open `[start, end)`: touching boundaries do not overlap. Travel feasibility is checked separately. | Use interval overlap semantics consistently; no assumption that adjacent events are reachable. |
| AP-07 | Do not invent early-arrival, parking, preparation, grace, or travel buffers. Use only supplied or verified values. Route travel is separate and is unknown when supporting data is unreliable. | No hidden padding constants. Carry source and confidence for any future buffer or route estimate. |
| AP-08 | Interpret and display schedules in Asia/Manila (UTC+8); timestamps are timezone-aware; date-only stay dates remain date-only and are not shifted by device timezone. | Use explicit timezone-aware instants for timed events and date-only values for stay dates. Avoid device-local conversion changing a calendar date. |
| AP-09 | Accommodation is one continuous stay with preserved check-in and check-out dates. Do not supply default times. During the stay, accommodation is the overnight location; check travel between it and activities and allow destinations outside the accommodation. If required times are missing, do not claim full feasibility. An extension requires reassessment of affected days. | Represent a stay interval separately from ordinary timed appointments. Preserve unknown time and overnight location continuity. |
| AP-10 | Preserve planned and actual extensions. Record original and revised end/additional duration and history; label tourist-reported data “Tourist-Reported/Not Externally Verified.” Reassess the remaining plan and propose a revised schedule when needed. Flexible, uncompleted stops may be rearranged when feasible; completed stops and external commitments are preserved. Tourist review/approval is required before applying the proposal. This belongs to Dynamic Self-Healing and applies to all three planning methods. | Append change history; distinguish proposal from applied schedule. Do not automatically mutate completed stops or external commitments. |
| AP-11 | Prefer verified establishment and official activity/event sources. Display organizer, location, schedule, eligibility, fees, and details when available. Label incomplete/unverified information; never claim an event is available, open, or accepting participation without reliable current evidence. | Source, verification state, and freshness are first-class data; missing information remains explicit. |
| AP-12 | Tourism Office Administrators publish official tourism events, festivals, public activities, and announcements. Verified establishment owners publish activities for their own establishments, including activities open to non-guests. External listings require supporting evidence and source labels. Tourists discover, save, or dismiss; they do not publish official listings. | Publisher role and ownership must be enforced server-side. External source records must retain evidence/provenance. |
| AP-13 | Tourists control optional notification preferences: all or selected interests, official events, establishment activities, nearby items, and schedule-compatible items. Notifications may be disabled without losing directory access. | Notification preferences are independent from browse access and must be user controlled. |
| AP-14 | Organizer/Administrator updates, postpones, or cancels an event: notify affected users who saved or added it, mark itinerary information outdated, reassess the itinerary, and propose a revised schedule when needed. Tourist approval is required before flexible items are rearranged. Do not silently change commitments; SAMAL NAV does not control external events. | Retain prior schedule/reference state and distinguish notification, stale status, proposal, and tourist-approved change. |
| AP-15 | Participation classification is exactly Open Participation, Registration Required, Reservation Required, or Not Verified. Show organizer instructions. SAMAL NAV does not register, book, or confirm participation. | Store the classification and instructions without implying an integrated booking action. |
| AP-16 | Mark past events Ended from their schedule and exclude them from new recommendations and notifications. Keep them when referenced by itineraries. Keep Cancelled and Postponed distinct. Authorized publishers update their own records; do not delete records merely because their dates passed. | Event lifecycle and itinerary snapshots must preserve history and distinguish end from cancellation/postponement. |
| AP-17 | Activities/events are separate from CARS. The six CARS criteria remain interest/activity match, public rating, weather suitability, budget compatibility, travel distance suitability, and available travel time compatibility. Activity discovery can separately consider interests, eligibility, distance/time, schedule compatibility, and information availability. Adding an activity triggers separate schedule/travel checks. Do not add discovery factors to CARS or change CARS weights, MO-GA objectives, or optimizer policy. | Keep discovery ranking and itinerary feasibility outside the approved CARS criterion/weight set and MO-GA objective set. |
| AP-18 | Activity discovery is available through Tourist Home, a dedicated directory, contextual planner suggestions, and Notification Center for suggestions, official announcements, and updates/postponements/cancellations. | These are future entry points sharing one directory/data contract, not separate taxonomies. |
| AP-19 | Provide an in-app notification center to signed-in tourists. Optional PWA push is only for compatible browsers/devices and requires permission. Tourists control notification categories. In-app notifications remain available when push is denied or unsupported; do not claim universal push support. | In-app delivery is the baseline. Push is an optional delivery channel with capability and permission checks. |
| AP-20 | Tourism Office manages official events/public activities; establishment owners manage their own verified establishment activities; Super Administrators oversee publishing permissions, moderation, and records; tourists report inaccurate/outdated information; authorized review is required before marking a report corrected/verified. Record creators and updates in audit history. | Define role-aware create/update/moderation flows and auditable changes. A user report is not itself verification. |
| AP-21 | Tourists may edit/remove reservation information from unfinished drafts and remove it from saved itineraries when irrelevant. Deleting an unfinished draft deletes its associated reservation rows. Completed itineraries remain history unless an explicit delete request is made. Retention must use an approved period/policy, not unjustified indefinite retention. Deletion does not cancel an external booking. | Parent/child deletion semantics and retention rules must be explicit; clearly communicate that app deletion does not cancel an external reservation. |
| AP-22 | Tourists access only their own reservation information. Establishment owners do not automatically see off-platform tourist-entered details. Tourism Office has no default private-reservation access. Admin support access is limited and controlled; Super Admin access is restricted to legitimate technical/security needs, not browsing. Privileged access is audited. | RLS plus narrowly scoped administrative access and audit requirements; ordinary establishment ownership must not expose reservation notes. |
| AP-23 | Missing/unverified locations do not remove reservation rows. Allow manual name/location snapshots; do not invent IDs, distance, or duration. Feasibility is unknown without a reliable location. Tourists may update it later; reassess after valid coordinates become available. | Location validation and route readiness are separate; retain the event while marking routing unknown. |
| AP-24 | One owner may manage multiple establishments. Each has its own identity, location, activities, and verification. Owners manage only their own records; Tourism Office verifies them. Production `UNIQUE(establishments.owner_id)` must be changed only through a separately reviewed migration that preserves existing records and ownership. No migration is authorized here. | Establishment directory/UI and future migration must support one-to-many owner relationships without reassigning records. |
| AP-25 | When extension, activity, or fixed constraints conflict, explain affected commitments and offer alternatives by rearranging flexible destinations. The tourist chooses; never automatically cancel, shorten, or modify external commitments. Feasibility is classified exactly as `Feasible`, `Partially Feasible`, `Infeasible`, or `Unknown`. | Preserve fixed commitments; return explicit result classification and actionable conflicts. Proposed alternatives require tourist approval. |
| AP-26 | Deleting a saved/completed itinerary also deletes its associated tourist-entered reservation information after warning/confirmation; external bookings are not cancelled. If history is retained, reservation information is retained. Required audit records follow retention rules and avoid unnecessary reservation-note exposure. | Deletion confirmation, history retention, child-row behavior, and minimal audit payloads must agree. |

## 4. Reservation functional requirements

### 4.1 Entry and identity

1. Reservation information is an itinerary-draft child and may be entered before an itinerary is saved (AP-01).
2. A selected establishment may have a verified catalog UUID. An off-directory entry has no fabricated UUID and retains a manually entered name and location snapshot (AP-02, AP-23).
3. The event type is one of Accommodation, Activity, Dining, or Other. Other requires a description (AP-03).
4. The app records tourist-provided details; it does not create, modify, or confirm the corresponding external booking (AP-15, AP-21).
5. Tourist ownership is derived from the authenticated session. A client-provided owner ID is never an authority (AP-22).

### 4.2 Time and completeness

1. Timed appointments can initially have a start only. Such an event is a valid saved entry but cannot produce full schedule feasibility without an end or duration (AP-04).
2. The tourist may enter an end time or duration. If one is derived from the other, retain the original input kind/value and mark the derived value as calculated (AP-05).
3. Appointment intervals use `[start, end)` for overlap. A zero gap at a boundary is not an overlap, but travel feasibility still needs a separate check (AP-06).
4. Do not add unapproved buffers or default time values (AP-07, AP-09).
5. Timed schedule values use Asia/Manila semantics; accommodation calendar dates remain date-only values (AP-08).
6. A single accommodation entry represents one continuous stay with check-in/check-out dates and, when supplied, times. Missing times remain missing (AP-09).

### 4.3 Change and deletion behavior

1. Planned extensions and actual extensions are distinct facts. Preserve the original reservation interval and each reported change; label tourist-reported changes as not externally verified (AP-10).
2. Reassessment may propose a different schedule for flexible, uncompleted stops. Applying it requires tourist approval. Completed stops and external commitments remain intact (AP-10, AP-14, AP-25).
3. Removing an event from an unfinished draft removes its draft child record. Deleting an unfinished draft removes its associated event rows. Saved/completed itinerary deletion follows the confirmation and retention rules in AP-21/AP-26.
4. The interface must state that deleting an in-app record does not cancel a real-world booking (AP-21, AP-26).

## 5. Activity and event discovery requirements

### 5.1 Directory and sources

- Provide a common discovery capability through Tourist Home, a dedicated directory, contextual planner suggestions, and Notification Center (AP-18).
- Official Tourism Office entries and establishment-owner entries must retain publisher identity and authorization (AP-12, AP-20).
- External listings require evidence and a source label. The implementation must not assume API access or represent stale/unverified data as official (AP-11, AP-12).
- Display organizer, location, schedule, eligibility, fees, and details when those fields are available. Missing fields should be visibly incomplete, not silently filled (AP-11).
- Distinguish event lifecycle states such as scheduled, ended, cancelled, and postponed; preserve itinerary references when a listing is no longer current (AP-14, AP-16).

### 5.2 Participation

Use the four approved participation classifications: Open Participation, Registration Required, Reservation Required, and Not Verified. Display organizer-provided instructions. The classification must not present SAMAL NAV as the registration, booking, or confirmation service (AP-15).

### 5.3 Separation from recommendation and optimization

Activity discovery can use its separately approved discovery considerations, but activities/events remain outside CARS scoring as a new criterion. The six CARS criteria and survey-derived weights are unchanged. Event schedule and route feasibility are constraints/checks around the itinerary; the three MO-GA objectives remain unchanged (AP-17).

## 6. Notifications and event updates

1. An in-app center is the dependable product surface for signed-in users. PWA push is optional and conditional on browser/device capability and user permission (AP-19).
2. Tourists can enable all notifications or choose approved categories/interests, official events, establishment activities, nearby items, and schedule-compatible items. Turning off optional notification delivery does not remove directory access (AP-13).
3. A change to an event saved or added by a tourist marks the related itinerary information outdated, triggers a reassessment, and may produce a proposed schedule. No event change silently rearranges the tourist's flexible stops (AP-14).
4. SAMAL NAV cannot guarantee that an external organizer will send updates or that an externally sourced event remains available. Display source/freshness and avoid availability claims without current evidence (AP-11, AP-14).
5. Delivery deduplication, read state, retries, expiry, and notification-to-itinerary association require technical decisions (Section 11); do not assume they are already implemented.

## 7. Privacy, access, audit, and retention

### Approved access rules

- Tourists can access their own reservation information only.
- Establishment owners do not gain access to off-platform reservation details merely by owning the establishment named in an event.
- Tourism Office Administrators have no default access to private reservation details.
- Exceptional support and Super Administrator access is restricted, justified, and audited (AP-22).
- Publishers can manage only the records allowed by their role and ownership; the Tourism Office verifies establishments, and the Super Administrator oversees publishing permission/moderation (AP-12, AP-20, AP-24).

### Deletion and retention

- Draft deletion cascades to draft reservation entries. Removing a reservation from a draft does not cancel a real booking (AP-21).
- Saved/completed itinerary deletion requires warning and confirmation; related tourist-entered reservation information is deleted as approved unless the itinerary/history is retained (AP-26).
- Expired events are not deleted simply because the event date passed. Keep them when referenced by itinerary history (AP-16).
- Retention periods, soft versus hard deletion, legal/audit exceptions, and audit payload retention are unresolved technical/policy details (Section 11).

### Owner-supplied production facts and limits

The supplied deployed metadata reports `public.reservations` as an existing establishment-side workflow table, with `eta`, `pax_count`, `reservation_status`, and `service_name`. The supplied RLS information indicates RLS is enabled on inspected tables; the reservation update policy does not authorize ordinary tourist updates, and no DELETE policy was returned. These are supplied facts, not a complete independent policy audit. This table is not the target for tourist-entered reservation information. Do not infer from it that a new draft/event data contract or its RLS has been deployed.

The deployed `establishments.owner_id` has a UNIQUE constraint. This conflicts with the approved multiple-establishments-per-owner rule and requires a separately reviewed migration preserving current rows and ownership (AP-24). No migration or policy changes are made here.

The supplied metadata also reports `itineraries.tourist_id` referencing profiles and `itinerary_stops` referencing itineraries and destinations. The deployed itinerary contract has not been fully verified for the future draft/event requirements. Existing RLS behavior must be reviewed for each proposed parent/child relationship before implementation. A permissive destination read policy was supplied for the destination directory; it does not authorize private draft/event access.

## 8. Itinerary scheduling and feasibility behavior

### 8.1 Fixed commitments and flexible stops

Reservation appointments and fixed event occurrences are schedule constraints, not ordinary destination genes. Future scheduling should place flexible itinerary stops around fixed commitments while preserving all selected destinations and explaining any constraint conflict. It must not cancel, shorten, or edit external commitments (AP-10, AP-14, AP-25).

The current MO-GA engine only permutes destination indexes and checks cumulative visit plus estimated travel time against daily available hours. It has no fixed-event windows, wait periods, accommodation stay representation, or event-aware day partition. Therefore, the current engine cannot be described as reservation-aware or fully feasible for these constraints.

### 8.2 Feasibility classification

Return exactly one of the approved classifications (AP-25):

- **Feasible:** all required schedule and travel checks have sufficient supported inputs and satisfy constraints.
- **Partially Feasible:** some stops or constraints can be evaluated and satisfied, while a known portion remains infeasible or incomplete; the result must identify which portion and why.
- **Infeasible:** a known, evaluated hard conflict prevents the schedule from satisfying a fixed commitment or approved daily constraint.
- **Unknown:** critical inputs are missing or unreliable, so the system cannot establish feasibility.

The precise boundary between “Partially Feasible” and “Infeasible” for mixed plans needs testable acceptance rules (Section 11). Never label unknown travel as feasible.

### 8.3 Time, travel, accommodation, and extensions

- Use supplied start/end/duration values and half-open intervals. Do not invent early arrival, setup, parking, grace, or travel-buffer values (AP-04 through AP-09).
- Route travel is checked separately from interval overlap and requires a supported location and route estimate. If either endpoint or route estimate is missing/unreliable, report unknown route feasibility (AP-07, AP-23).
- Accommodation is a continuous stay. Its check-in/check-out dates and supplied times constrain the schedule; the accommodation is the overnight location while the tourist is staying there. Activities outside the accommodation are allowed, but route/time continuity must be checked (AP-09).
- If accommodation times are missing, preserve the stay but do not claim full feasibility. The exact handling of an otherwise date-valid stay without times remains an implementation decision; see Section 11.
- On an extension, preserve original and revised commitments, reassess the affected days and remaining stops, and present alternatives. Require tourist approval before applying changes. Preserve completed stops and every external commitment (AP-10).
- For a change to an event, mark related itinerary data outdated and ask the tourist to review a proposed re-plan. The system does not control external event organizers (AP-14).

### 8.4 MO-GA boundary

No new optimization objective is approved. Preserve the existing objectives:

1. Minimize route distance.
2. Maximize stops reached within the daily time limit.
3. Minimize variation in visit-plus-travel time.

Budget, weather, public ratings, activity popularity, and reservation/event records do not become new MO-GA objectives by virtue of this feature. A future adapter/scheduling layer must define how fixed events constrain candidate generation/evaluation without silently changing the existing objective semantics (AP-17, AP-25).

## 9. Existing repository architecture assessment

| Area | Verified repository behavior | Gap relative to approved baseline |
|---|---|---|
| Draft contract | `lib/models/itinerary_draft.dart` defines planning method/stage, trip configuration, selected draft stops, selected circuits, a CARS reference, and optimization result. It is currently an in-memory typed draft. | No reservation-event child collection, activity/event snapshot, server draft identity/version, or persistent lifecycle. |
| Manual selection | `ManualSelectionDraftBuilder` in `lib/algorithms/manual_selection_workflow.dart` builds drafts from selected UUID/day groups and preserves stop provenance. `ManualSelectionMogaAdapter` requires a ready manual draft and maps stable destination UUIDs to MO-GA indexes. | No reservation entry or fixed-event scheduling. |
| Planner UI | `lib/screens/tourist_screens/plan_page.dart` creates/reviews a manual plan in screen/session state and invokes MO-GA only after explicit optimization. The user-selected day grouping is retained. | No reservation/event editor, no server draft continuation, and no cross-device saved draft retrieval. |
| MO-GA | `lib/algorithms/moga_engine.dart` optimizes permutations with non-dominated sorting, crowding distance, tournament selection, order crossover, and swap mutation. Its three objectives are distance, negative count of stops fitting the daily time limit, and visit-plus-travel time variance. Travel is estimated from coordinates using a geometric approximation; no event windows or road-routing guarantee exists. | Cannot currently enforce fixed appointment/stay constraints or report the approved four-state overall feasibility contract. No objective change is authorized. |
| CARS | `lib/algorithms/cars_engine.dart` consumes criterion scores/configured weights for ranking/eligibility. It does not provide the full data acquisition or scoring workflow. | Reservation/event discovery must remain separate; no CARS expansion is needed or authorized. |
| Establishment model/service | `lib/models/establishment.dart` has identity, owner, name, address/category, and verification fields, but no coordinates in that model. `EstablishmentService.getMyEstablishment` uses a single-row owner lookup. | No tourist-facing establishment directory selection contract was identified. The deployed owner uniqueness conflicts with approved multiple establishment ownership. Establishment coordinates are nullable in supplied production metadata. |
| Reservation model/service | `ReservationRecord` and `lib/services/establishment_service.dart` support the existing establishment-side reservation workflow, including `eta`, party size, status, service name, and owner-side listing/status updates. | This is not a tourist-entered external reservation record; it has no full time interval, provenance, extension history, off-directory snapshot, or draft ownership contract. Do not reuse `public.reservations`. |
| Activities/events | The inspected repository has no complete activity/event model, tourist directory, publisher service, or end-to-end publishing workflow. A local migration declares an `events` structure, but that declaration is not proof of the deployed schema. | Verify deployed tables/fields, roles, sources, lifecycle and RLS before building the directory. Keep activity taxonomy separate from destination categories. |
| Notifications | The inspected code does not provide the approved tourist in-app Notification Center or a verified event-update notification pipeline. A migration declaration alone is not functional proof. | Build in-app notification capability before treating update notices as delivered. PWA push remains optional and capability/permission dependent. |
| Dynamic Self-Healing | No working self-healing re-optimization implementation was found. A local migration declaration for a log table does not establish deployed functionality. | Extension/update reassessment, proposal, review, and apply lifecycle remain future implementation. |
| Persistence and offline | The repository's Hive utility stores snapshots; no outbox, conflict detection, or synchronization loop was identified. Itineraries/history are not established as saved cross-device records by the inspected application flow. | Server persistence must precede cross-device drafts; offline sync is separate and must include idempotency/version/conflict policy. |
| Audit | An audit service is used for some administrative/establishment actions. | No evidence was found that exceptional access to private reservation content is purpose-limited and audited under the approved policy. |

### Related existing identifiers

`DraftStop` uses stable destination UUIDs rather than relying only on display names or indexes. `DestinationRecord` supports coordinates and nullable `categoryId`, preserving the original text category. The draft can therefore retain destination identity while reservation/off-directory records need their own optional catalog identities and immutable/display snapshots. Existing category mappings must not be repurposed as activity taxonomy.

## 10. Proposed data contract and relationships

This section is a design proposal, not a claim that these tables/columns exist in production. Prefer additive, versioned contracts and reuse an existing deployed structure only after its full metadata, constraints, and access behavior are verified.

### 10.1 Server-persisted draft aggregate

Recommended conceptual aggregate:

```text
ItineraryDraft
  draftId: UUID                         // required, server-stable
  touristUserId: UUID                   // required; derived from auth session
  planningMethod: enum                  // required: existing three methods
  stage: enum                           // required; lifecycle state
  tripConfiguration: TripConfiguration // required/validated per approved profile policy
  version: integer or equivalent        // required for optimistic conflict detection
  createdAt, updatedAt: timezone-aware  // required
  draftStops: ordered collection        // existing UUID/day/provenance contract
  selectedCircuitReferences: collection // only for circuit method
  carsRunReference: optional             // only for system-generated method
  reservationEvents: collection          // zero or more; AP-01
  selectedActivityReferences: collection // optional; published data source
```

Draft identity is stable across devices. The planning method remains one of the existing three. A reservation entry may exist before an itinerary is saved. A later draft-to-itinerary save/promotion must preserve identity links and tourist ownership and be atomic from the user's perspective (exact DB transaction/RPC strategy is unresolved).

### 10.2 Reservation event

| Field | Requirement | Contract notes |
|---|---|---|
| `eventId` | Required | Stable UUID independent of list order. |
| `draftId` | Required while draft-owned | FK to the owner-scoped draft. On save, retain a verified parent/link to the saved itinerary or perform an atomic promotion. |
| `touristUserId` | Required or derived by parent | Must equal authenticated owner and draft owner; do not trust request payload. |
| `eventType` | Required | Exactly Accommodation, Activity, Dining, Other. |
| `otherDescription` | Conditional | Required only for Other; do not conflate with optional notes. |
| `establishmentId` | Optional | Set only when selected from verified catalog. No invented ID for off-directory entry. |
| `establishmentNameSnapshot` | Required when no catalog identity; otherwise recommended snapshot | Preserve what the tourist selected/entered and avoid display changing unexpectedly if catalog name changes. |
| `locationSnapshot` | Optional | User-entered or catalog-derived label with provenance. Missing location does not delete the event. |
| `latitude`, `longitude` | Optional pair | Only validated coordinates with source/provenance. No fake coordinates. Pair/bounds and geocoding rules remain open. |
| `locationSource` | Required when coordinates exist | Distinguish verified catalog, tourist-entered, or other approved source. |
| `startsAt` | Required for timed appointment; optional/conditional for a date-based stay | Timezone-aware instant with Asia/Manila input/display semantics. Start-only event may be saved but is incomplete for full feasibility. |
| `endsAt` | Optional until supplied or derived | Preserve whether directly supplied or computed from duration. Must be after start for a complete positive interval. |
| `duration` | Optional until supplied or derived | Preserve source and unit; if derived, record derivation metadata. Exact allowed precision/limits need decision. |
| `suppliedTimeKind` | Required for appointment timing | Identifies start-only, explicit end, or supplied duration; supports AP-05 provenance. |
| `checkInDate`, `checkOutDate` | Conditional, accommodation only | Date-only local calendar values, continuous stay. Check-out must follow check-in; exact validation policy follows approved contract. |
| `checkInTime`, `checkOutTime` | Optional | No defaults; absent values reduce feasibility certainty. |
| `notes` | Optional | Tourist-private; minimize collection and exposure. |
| `source/provenance` | Required | Tourist-entered vs catalog/organizer-supplied reference and retrieval/update source where applicable. |
| `verificationState` | Required | At minimum distinguish tourist-reported/not externally verified from supported verified source; exact enum/criteria remain to define. |
| `version`, timestamps | Required for server edits | Needed for optimistic concurrency, idempotent retry, and conflict detection. |
| `extensionHistory` | Conditional | Preserve original and changed planned/actual end/duration, actor/source, time, and tourist-reported status (AP-10). Avoid rewriting history. |
| `deletedAt` or equivalent | Policy-dependent | Soft/hard deletion and audit retention remain open; behavior must satisfy AP-21/AP-26. |

### 10.3 Activity/event listing

Conceptually distinguish a publisher-owned listing from a tourist's saved/selected reference:

```text
PublishedActivityOrEvent
  listingId, publisherRole, publisherUserId/establishmentId
  title, description, eventType/category (separate taxonomy)
  organizer, location, optional coordinates and provenance
  schedule, eligibility, fee details when available
  participationClassification (four approved values)
  source, evidence, verification state, freshness
  lifecycle (scheduled/ended/cancelled/postponed)
  createdAt, updatedAt, version

DraftActivityReference / SavedActivityReference
  draft or itinerary identity, listingId, tourist owner
  selected/saved status and source/version snapshot
```

The exact tables and reuse of deployed `activities` or event structures cannot be decided from local migration declarations. Verify deployed metadata first. A tourist's saved reference should preserve enough snapshot information for itinerary history if the publisher later edits or expires a listing (AP-14, AP-16).

### 10.4 Notification and audit records

Conceptually, an in-app notification needs a stable ID, signed-in tourist recipient, category, source listing/event version, delivery/read state, timestamps, and a deep link or safe itinerary reference. Retry/deduplication/expiry rules remain open. Audit records should capture publisher changes and exceptional administrative access while minimizing private reservation-note contents. These are proposed requirements; the current implementation is incomplete.

## 11. Open technical decisions, options, and risks

Approved policies are not reopened here. The following implementation details remain unresolved and require technical design, evidence, or explicit owner approval where they define user-visible semantics or data retention.

| ID | Open detail | Options / recommended direction | Why it matters and dependency |
|---|---|---|---|
| OQ-01 | Retention periods | Set explicit periods by record type and legal/academic requirements; recommendation: define before persistence release, avoid indefinite retention. | Determines purge/archive, backups, audit, and privacy behavior. Owner/legal approval required. |
| OQ-02 | Soft vs hard deletion and audit exceptions | Soft delete with controlled purge, or hard delete plus minimal retained audit. Recommendation: choose per draft, completed itinerary, event listing, and audit record separately. | AP-21/AP-26 require deletion semantics; must not over-retain private notes. Owner/privacy approval required. |
| OQ-03 | Privileged support access | Options: no content access, time-limited break-glass with reason, or role-scoped support RPC. Recommend least privilege, explicit purpose/reason, short-lived access and immutable audit. | Needed to implement AP-22 safely; requires security/RLS review and owner approval. |
| OQ-04 | Timed appointments vs date-only events | Use timezone-aware instants for timed appointments and date-only start/end for multi-day/date-only listings; define conversion for all-day public events. | Prevents timezone shifts and false conflicts under AP-08. Needs product/technical contract. |
| OQ-05 | Persistent draft identity and lifecycle | Stable UUID generated once; explicit draft statuses and save/promotion semantics. | Required for AP-01, cross-device access, children, and atomic promotion. Owner approval for lifecycle labels/expiry. |
| OQ-06 | Atomic draft-to-itinerary promotion | Database transaction/RPC or equivalent transactional operation; don't leave duplicate/orphan children. | Depends on verified deployed itinerary schema and Supabase transaction strategy. Requires schema/security review. |
| OQ-07 | Concurrent cross-device edits | Optimistic version check, reject-and-reload, or merge field-level changes. Recommend version check with explicit conflict UI; never silent last-write-wins for external commitments. | Required for AP-01 and event edits; affects service API and offline queue. Owner approval of conflict UX. |
| OQ-08 | Parent/child ownership invariant | Enforce event tourist identity through draft parent and prevent mismatched user IDs; DB constraints/RLS/RPC options. Recommend derive owner from parent and authenticated session. | Critical for AP-22; needs deployed FK/RLS review before implementation. |
| OQ-09 | Location validation/geocoding | Manual location text only, client/device geocoding, or approved geocoder. Recommend preserve text independently and only attach coordinates with source/validation metadata. | Geocoding provider, bounds, and privacy implications unresolved; needed for route feasibility (AP-23). |
| OQ-10 | External source verification and freshness | Manual curator evidence, official source URL, or a supported API/provider. Recommend source-specific verification metadata and explicit stale/unknown state; do not assume API access. | Required by AP-11/AP-12; provider terms and freshness thresholds need research/approval. |
| OQ-11 | Activity/event ingestion | Authorized manual publishing, provider API, or both. Recommend begin only with approved verified publisher workflows and add integrations only after source/licensing review. | Repository lacks an end-to-end publisher workflow; affects data contract, moderation, and updates. |
| OQ-12 | Notification dedupe/read/retry/expiry | Define event-version-based idempotency, retry policy, read state, and expiry. Recommend in-app source-version dedupe; push is supplemental. | Required for AP-13/AP-14/AP-19; no existing center was verified. |
| OQ-13 | Accommodation feasibility when times are absent | Keep dates and stay; classify affected scheduling as Unknown or Partially Feasible under approved definitions, then request times. | AP-09 says no full feasibility but not exact classification boundary. Needs acceptance examples/approval. |
| OQ-14 | Fixed event mapping to MO-GA day segments | Pre-filter/partition feasible windows, schedule fixed blocks around permutations, or a constraint-aware adapter. Recommend isolate fixed-event scheduling around existing engine and preserve objectives until validated. | Existing chromosome has only destination indexes; no event genes. Requires algorithm research, then owner/researcher review; no objective changes. |
| OQ-15 | Extension after completed or missed stops | Distinguish actual extension from a missed event; preserve completed status, mark conflicts, propose remaining schedule only. | AP-10 requires completed stops preserved, but recovery states/UI need acceptance tests. |
| OQ-16 | Retention of activity listings used in history | Live FK, immutable itinerary snapshot, or both. Recommend retain a minimal source/version snapshot in itinerary history plus a link when still valid. | AP-16 requires historical references survive event expiration; privacy and storage scope need approval. |
| OQ-17 | `UNIQUE(establishments.owner_id)` migration | Keep as-is (conflicts with AP-24) or separately reviewed additive/constraint migration after inventory and data checks. Recommend preserve rows/owner IDs and remove only the unique restriction after approved migration plan. | Blocks multiple-establishment ownership; migration must not be included here or replayed blindly. Owner/db review required. |
| OQ-18 | Existing deployed RLS/grants | Obtain complete deployed policy/privilege inventory and test parent-child isolation; don't infer from migration files. | Necessary before server drafts, private event data, publisher permissions, and support access. DB/security review required. |
| OQ-19 | Feasibility classification boundary | Define exact cases for mixed known/unknown/infeasible inputs and whether classification applies per day, event, or whole itinerary. | AP-25 names states but not aggregation semantics; needed for UI, tests and optimizer integration. |
| OQ-20 | Duration precision and maximums | Define accepted units, rounding, maximum appointment length and validation without adding defaults. | Required for AP-04/AP-05 and overlap calculations. Owner/product approval if user-visible. |
| OQ-21 | Event update impact detection | Define which itinerary states/users count as affected, snapshot/version matching and cancellation/postponement transitions. | AP-14 requires affected users to be informed; depends on saved references and notification idempotency. |

## 12. Recommended implementation and dependency sequence

Sequence respects the approved design and avoids building user flows on unverified production assumptions. Each step should receive its own review/authorization before implementation.

1. **Finalize versioned contracts and acceptance cases.** Resolve OQ-04 through OQ-08, OQ-13, OQ-14, OQ-19, and OQ-20. Define API/model states, event timing, incomplete-entry behavior, ownership, promotion, and feasibility examples. Keep the 26 approved policies fixed.
2. **Complete deployed schema/RLS verification.** Inventory full deployed `itineraries`, `itinerary_stops`, `activities`, `events`, `establishments`, audit, and notification structures, privileges, policies, triggers, and indexes. Migration files are not a production baseline.
3. **Plan establishment directory and ownership correction.** Add/verify tourist-facing establishment selection and location provenance. Separately design the approved multiple-establishments-per-owner migration, preserving existing records, owner links, and verification state (AP-24).
4. **Design server-persisted draft aggregate and RLS.** Define stable draft IDs, parent/child ownership, versioning, idempotency, and atomic save/promotion; verify no cross-user access. Do not use `public.reservations` (AP-01, AP-22).
5. **Implement draft persistence and reservation-event contracts.** Add reservation event create/read/update/remove for the authenticated tourist, including directory/off-directory entries, timing provenance, timezone handling, accommodation stays, and extensions. Keep edits server-persisted. Offline outbox/sync remains separate (AP-01–AP-10, AP-21–AP-23).
6. **Integrate reservation information with all three draft methods.** Manual, circuit-based, and system-generated flows use the same draft/event contract. CARS remains only in system-generated. Ensure circuit identity and CARS provenance remain intact and no method-specific copy is saved separately.
7. **Build fixed-event scheduling assessment.** First calculate interval overlaps, missing-input states, route unknowns, accommodation continuity, and the four feasibility classifications without changing MO-GA objectives. Validate against researched acceptance scenarios.
8. **Design and implement MO-GA adapter/constraint integration after research approval.** Preserve distance, stops reached within daily limit, and time-variation objectives. Treat fixed events as schedule constraints around/alongside destination permutations, not ordinary genes. Compare candidates with feasible fixed-event assignments; never auto-edit external commitments (AP-10, AP-14, AP-17, AP-25).
9. **Implement Dynamic Self-Healing extension/update proposals.** Preserve original and revised event history, completed stops, and external commitments; generate a proposal and require tourist review/approval before applying (AP-10, AP-14, AP-25).
10. **Verify activity/event publishing contract and permissions.** Confirm deployed schema and source evidence requirements, then implement Tourism Office and verified establishment-owner publishing/moderation, reports, lifecycle, and history (AP-11, AP-12, AP-15, AP-16, AP-20).
11. **Build activity/event directory and planner discovery surfaces.** Integrate Home, dedicated directory, planner suggestions, and itinerary references. Do not route activities through CARS or modify CARS weights/criteria (AP-17, AP-18).
12. **Build in-app Notification Center; add optional push only after capability/security review.** Implement user preferences, event-version dedupe, read/expiry/retry rules, and update impact flow. Keep in-app center available without push (AP-13, AP-14, AP-19).
13. **Implement deletion, retention, and minimal audit behavior.** Resolve retention and deletion policy before production release; verify draft/itinerary cascades, warnings, history retention, and exceptional-access audit without exposing notes (AP-20–AP-22, AP-26; OQ-01–OQ-03).
14. **Add offline synchronization only as a separately approved capability.** Define pending changes, idempotency, version conflicts, reconnection behavior, and data retention. Existing Hive snapshots are not synchronization (AP-01).
15. **Add automated tests continuously and run final acceptance verification.** Cover ownership/RLS, idempotency, conflict handling, timezone/DST-independent local date behavior, interval boundaries, incomplete events, accommodation continuity, all four feasibility states, extension proposals, all three planning methods, publisher permissions, notification dedupe, and deletion/retention. No test should claim live Supabase access unless an authorized integration request actually ran.

## 13. Security, edge-case, and acceptance checklist

Future implementation should not be approved as complete unless these are demonstrable:

- A tourist cannot read, create for, or modify another tourist's draft/event by changing a client-supplied UUID.
- Reservation events are children of the authenticated tourist's draft; child and parent ownership cannot diverge.
- An owner of a named establishment cannot read off-platform tourist reservation details by default.
- Tourism Office and Super Admin roles follow limited, audited access; privileged access is not a browsing feature.
- A missing establishment UUID or location retains the event and yields unknown routing feasibility rather than a fabricated identity or distance.
- “Other” cannot be saved without its description; the event type set is exactly the approved four types.
- Start-only events persist but are not called fully feasible.
- End/duration derivation preserves the user's supplied value and is timezone-aware.
- `[start,end)` means events touching at an endpoint do not overlap, while route feasibility is evaluated separately.
- Accommodation has no invented check-in/out time, remains continuous, and is used as the overnight location while active.
- Extension and event-update flows preserve external commitments and completed stops; proposed changes are not applied before tourist approval.
- The four feasibility classifications are used consistently and unknown inputs never yield a false Feasible result.
- Event expiration does not erase itinerary history; cancellation/postponement remain distinct from Ended.
- Directory access remains available when optional notifications are disabled or push is unavailable/denied.
- Activity/event data do not add CARS criteria or MO-GA objectives.
- Draft edits do not claim offline synchronization until an outbox and conflict-aware sync path is implemented and tested.
- Deleting an app record is clearly distinguished from cancelling an external booking.

## 14. Decision traceability matrix

| Approved decision | Functional requirements | Contract areas | Dependencies / acceptance evidence |
|---|---|---|---|
| AP-01 Server-persisted drafts, cross-device continuation; offline sync separate | 4.1; 10.1 | Draft aggregate, version, stable IDs | OQ-05–OQ-08; owner-scoped server integration tests; no claim of current sync |
| AP-02 Directory and off-directory entries | 4.1 | Optional establishment ID, name/location snapshots | OQ-09; test catalog and no-ID path |
| AP-03 Four reservation types; Other description | 4.1 | Event type, conditional description | Model validation and widget tests for all four types |
| AP-04 Start-only allowed, incomplete feasibility | 4.2 | Start/end/duration completeness | OQ-20; ensure start-only returns incomplete/unknown assessment |
| AP-05 End or duration supplied; preserve source | 4.2 | Supplied-time kind, derived counterpart | Round-trip and derivation-provenance tests |
| AP-06 Half-open intervals | 4.2; 8.2 | Interval comparison | Boundary overlap tests; independent route feasibility test |
| AP-07 No invented buffers | 4.2; 8.3 | Route estimates and optional supported buffers | Tests prove absent buffers remain absent; route provenance tests |
| AP-08 Asia/Manila and date-only stay dates | 4.2 | Zoned instants and date-only values | Cross-device timezone serialization tests; OQ-04 |
| AP-09 Continuous accommodation stay | 4.2; 8.3 | Check-in/out dates/times, overnight location | OQ-13; multi-day continuity and missing-time tests |
| AP-10 Extension history and approved proposal | 4.3; 8.3 | Extension history, proposed schedule state | Dynamic Self-Healing tests; completed/external commitments preserved |
| AP-11 Verified sources and freshness | 5.1 | Source, evidence, freshness, verification state | OQ-10/OQ-11; stale/unverified display tests |
| AP-12 Publisher responsibilities | 5.1 | Publisher identity/role, owner link | RLS/authorization tests for Tourism Office, establishment owner, tourist |
| AP-13 Tourist notification controls | 6 | Notification preference contract | Preferences tests; directory remains accessible when disabled |
| AP-14 Updates/postponements/cancellations | 6; 8.3 | Event versions, stale references, proposals | OQ-12/OQ-21; approval-before-apply and no-silent-change tests |
| AP-15 Participation classifications | 5.2 | Four-value classification and instructions | Enum validation and no-booking/registration claim tests |
| AP-16 Expiration and history | 5.1; 7 | Event lifecycle and itinerary snapshot | Ended vs Cancelled/Postponed tests; history retention tests |
| AP-17 Activities separate from CARS; preserve six criteria/three objectives | 5.3; 8.4 | Discovery and scheduling boundary | Regression tests for unchanged CARS criteria/weights and MO-GA objectives |
| AP-18 Four discovery surfaces | 5.1 | Shared listing/reference model | Navigation/entry point tests; one shared directory source |
| AP-19 In-app notifications, optional push | 6 | Delivery channels and capability state | Browser capability/permission tests; in-app fallback tests |
| AP-20 Publishing moderation and audit | 5.1; 7 | Publisher, report, audit history | Role authorization and change-history tests |
| AP-21 Draft removal, completed history, retention | 4.3; 7 | Parent/child deletion and retention | OQ-01/OQ-02; deletion does not cancel external booking |
| AP-22 Privacy and privileged access | 7 | Ownership/RLS and access audit | OQ-03/OQ-08/OQ-18; negative cross-user and admin audit tests |
| AP-23 Missing locations remain; unknown feasibility | 4.1; 8.3 | Location snapshot/provenance | OQ-09; no fabricated ID/distance; later coordinate update reassessment |
| AP-24 Multiple establishments per owner | 7 | Owner-to-establishment one-to-many | OQ-17; separately reviewed migration and row-preservation evidence |
| AP-25 Conflict alternatives and four feasibility states | 8.2–8.4 | Assessment result and proposal | OQ-14/OQ-19; conflict scenarios, no automatic commitment changes |
| AP-26 Itinerary deletion and reservation data | 4.3; 7 | Parent deletion/history and audit | OQ-01/OQ-02; warning/confirmation, cascade/retention, no external cancel |

## 15. Readiness and next task

**Policy baseline:** complete. All 26 approved decisions are captured and traced to functional requirements, contract areas, dependencies, and acceptance evidence.

**Implementation readiness:** partial. The policies are sufficiently clear to begin detailed contract/schema and security design, but not to implement production persistence or event-aware optimization safely. Required prerequisites include a complete deployed-schema/RLS inventory, draft/event ownership and version strategy, retention/deletion choices, time/location provenance contracts, and a researched fixed-event scheduling adapter that preserves MO-GA's existing objectives.

**Recommended next task:** Task 09B-E — Reservation/Event Technical Contract and Persistence/RLS Specification. It should resolve the open technical decisions that block the data contract, compare the deployed schema against proposed additive structures, define parent/child authorization and versioned atomic promotion, and provide testable timing/feasibility cases. It must remain design-only until the owner separately authorizes implementation and any migration work.

No application implementation, migration, SQL execution, Supabase access, or production data/object modification is part of this baseline.
