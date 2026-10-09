# Stage 3: Technical Documentation

## Table of Contents

1. [User Stories and Mockups](#1-user-stories-and-mockups)
2. [System Architecture](#2-system-architecture)
3. [Components, Classes, and Database Design](#3-components-classes-and-database-design)
4. [High-Level Sequence Diagrams](#4-high-level-sequence-diagrams)
5. [API Specifications](#5-api-specifications)
6. [SCM and QA Plans](#6-scm-and-qa-plans)
7. [Technical Justifications](#7-technical-justifications)

## 1. User Stories and Mockups

### 1.1 Prioritized User Stories

The TFAQUD MVP serves five user types. A **self-managing patient** manages their own care and has manager permissions in their care circle. A **simplified-mode patient** follows care tasks through a simplified interface. A **care manager** manages another patient’s care circle and care plan. A **care assistant** carries out tasks assigned to them. A **viewer** can view care information but cannot modify it.

The stories are prioritized using MoSCoW: **Must Have** items are essential to the MVP’s core care workflow; **Should Have** items are important but not essential to that workflow; and **Could Have** items are desirable additions that may be implemented if time allows.

#### Must Have

| ID | User Story |
|---|---|
| US-01 | As a **self-managing patient**, I want to create a care circle for myself, so that I can manage my care and invite others to participate. |
| US-02 | As a **care manager**, I want to create a care circle for a patient and select the patient’s app mode, so that I can set up the circle to suit the patient’s needs. |
| US-03 | As a **patient with a phone**, I want to approve or decline a request to create a care circle for me, so that I can control whether my care information is shared. |
| US-04 | As a **care manager or self-managing patient**, I want to invite people to a care circle and assign each person a role, so that they can participate with clearly defined responsibilities and permissions. |
| US-05 | As an **invitee**, I want to review the role offered to me and accept or decline the invitation, so that I can decide whether to join the care circle. |
| US-06 | As a **care manager or self-managing patient**, I want to add medications and specify their doses, duration, and schedules, so that medication tasks can be organized in the care plan. |
| US-07 | As a **care manager or self-managing patient**, I want to add required measurements and specify their types, schedules, and target ranges, so that readings can be tracked as part of the care plan. |
| US-08 | As a **care manager or self-managing patient**, I want to add a patient’s appointments and their details, so that visits and related tasks can be organized. |
| US-09 | As a **care manager or self-managing patient**, I want to assign a person responsible for each care task, so that responsibility for completing the task is clear. |
| US-10 | As a **care assistant**, I want to review tasks assigned to me and accept or decline them, so that I can indicate which tasks I can undertake. |
| US-11 | As an **authorized care-circle member**, I want to view care tasks and record completed tasks, so that the patient’s care record reflects what was actually done. |
| US-12 | As a **patient using Simplified Mode**, I want to view my daily tasks and record my responses to medication and measurement tasks, so that I can participate in my care easily. |
| US-13 | As a **person responsible for a care task**, I want to receive a reminder when the task is due, so that I can remember to complete it. |
| US-14 | As a **care manager or self-managing patient**, I want to follow up on missed tasks and escalate notifications according to the configured recipient order, so that uncompleted tasks receive appropriate follow-up. |
| US-15 | As a **viewer**, I want to view the care plan, completed tasks, and recorded measurements, so that I can follow the patient’s care. |

#### Should Have

| ID | User Story |
|---|---|
| US-16 | As a **care manager or self-managing patient**, I want to track medication supplies and estimate when they will run out, so that I can arrange a refill before the supply is depleted. |
| US-17 | As a **care manager or self-managing patient**, I want to change a medication dose or discontinue a medication while retaining its previous dose and the date and reason for the change, so that the medication history remains accurate. |
| US-18 | As a **care manager**, I want to add and update the patient’s medical-profile information and emergency contacts, so that current information is available to care-circle members. |
| US-19 | As a **patient**, I want to view my emergency card, including my medical information, current medications, and emergency contacts, so that I can access essential information when needed. |
| US-20 | As a **care manager or self-managing patient**, I want to export the patient’s complete care record, including current and previous medications and all recorded measurements without a date-range limit, so that I can keep and share a complete copy when needed. |

#### Could Have

| ID | User Story |
|---|---|
| US-21 | As the **care assistant accompanying a patient to an appointment**, I want to record visit notes and attach an image of the medical report, so that visit information is retained in the care record. |
| US-22 | As a **patient using Simplified Mode**, I want to record a measurement outside its scheduled time, so that I can add a reading taken when needed. |
| US-23 | As a **care-circle member with assigned tasks**, I want to temporarily hand over my tasks to another member when I am unavailable, so that care follow-up can continue during my absence. |
| US-24 | As a **user**, I want to access help and support, so that I can seek assistance when I encounter a problem using the application. |

### 1.2 Main Screen Mockups

[View the main screen mockups in Figma](https://www.figma.com/design/Ojd0XVQSuC39YoJoiRyhou/Tafaqud-Care-OS?node-id=0-1&t=EkiVLBVRuXTGD5P6-1)

## 2. System Architecture

```mermaid
flowchart TD
    USER["Patient / Manager / Performer / Viewer"]

    subgraph CAREOS["TFAQUD Care OS"]
        APP["Flutter mobile app"]
        OCR["Local OCR"]
        API["Flask REST API<br/>OTP login<br/>Circles and permissions<br/>Medications and tasks<br/>Reminders and escalation"]
        DB[("PostgreSQL database")]

        APP -->|"Pass medicine image"| OCR
        OCR -->|"Extracted raw text"| APP
       
        APP -->|"HTTPS request, REST/JSON"| API
        API -->|"JSON response"| APP
        API -->|"SQL query"| DB
        DB -->|"Query result"| API
    end

    SMS["SMS gateway"]
    PRAYERAPI["Prayer times API"]
    FCM["Firebase Cloud Messaging"]

    USER -->|"Uses application & scans medicine"| APP
    API -->|"OTP code"| SMS
    SMS -->|"OTP message"| USER
    API -->|"Patient city"| PRAYERAPI
    PRAYERAPI -->|"Prayer times"| API
    API -->|"Trigger reminder"| FCM
    FCM -->|"Push notification"| APP
```
## 3. Components, Classes, and Database Design

### 3.1 Front-End Components and Interactions
The front end is a Flutter mobile app. All data goes through the Flask REST API, and the actions shown on each screen depend on the member's role in the selected circle (`Manager`, `Performer`, `Viewer` or `Patient`).

### Main Components
 
| Component | Responsibility | Interacts with |
|---|---|---|
| Welcome and login | Collects the phone number and the OTP code, shows the countdown, resend, edit number and wrong-code message | Flask REST API (OTP login), which sends the code through the SMS gateway |
| Circle setup | Creates a circle for a patient, or joins an existing circle with an invitation code | Flask REST API (circles and permissions) |
| Simplified mode (Patient) | Shows the patient's next medicine by prayer time, and lets the patient confirm or skip a dose,and shows the appointment, enter a measurement or ask for help | Flask REST API (medications and tasks), reminder notifications |
| Help and emergency | Calls a circle member or emergency, and shows the medical card | Flask REST API (circle members) |
| Today (Detailed mode) | Shows the day's tasks per patient, records a dose and lists what needs attention | Flask REST API (tasks, reminders and escalation) |
| Task assignment | Offers a task to a circle member, who accepts or declines | Flask REST API (tasks), push notifications to the member |
| Plan | Shows the care plan and lets the Manager change or stop a medicine | Flask REST API (medications and care plan) |
| Add (+) | Adds a medicine, a measurement or an appointment to the plan | Local OCR (reads the medicine photo), Flask REST API |
| Log | Shows the history and shares the one-page visit sheet (PDF) | Flask REST API |
| Circle | Manages members and roles, invitations and the medical file | Flask REST API (circles and permissions) |
| Account | Shows the user's circles, notification settings, language and logout | Flask REST API |
| Device layer | Asks for system permissions, shows reminders and shares files | Firebase Cloud Messaging (push notifications) |

### Interaction Flowchart
 
```mermaid
flowchart TD
    W["Welcome"] --> PH["Phone number"]
    PH --> OTP["Enter code"]
    OTP -->|"Registered user"| TODAY
    OTP -->|"New user"| CHOICE{"How will you use TFAQUD?"}
 
    CHOICE -->|"I care for another person"| WHO["Who will you care for"]
    CHOICE -->|"I manage my own care"| WHO
    CHOICE -->|"I have an invitation"| INV["Enter invitation code"]
 
    WHO --> MED["Medical info"]
    MED -->|"Caring for another person"| MODE["Patient mode choice"]
    MED -->|"Own care"| TODAY
    MODE --> TODAY
    INV --> CARD["Invitation card"]
    CARD --> TODAY
 
    subgraph TABS["Main tabs"]
        TODAY["Today"]
        PLAN["Plan"]
        ADD["Add (+)"]
        LOG["History"]
        CIRCLE["Circle"]
    end
 
    TODAY --> ATT["Needs attention"]
    TODAY --> REC["Record dose"]
    ATT --> ASSIGN["Who brings it"]
    ASSIGN -.->|"Members listed from"| CIRCLE
    ASSIGN -->|"Sent to the chosen member"| ACC["Accept or decline"]
 
    PLAN --> MD["Medication details"]
    MD --> CD["Change dose"]
    PLAN --> APD["Appointment details"]
    APD --> VN["Visit notes"]
 
    ADD --> WHAT{"What to add?"}
    WHAT -->|"Medicine"| SCAN["Scan medicine"]
    SCAN --> CONF["Confirm what we read"]
    CONF --> WT["When to take"]
    WT --> RESP["Who is responsible and what if missed"]
    RESP --> PLAN
    WHAT -->|"Measurement"| AM["Add measurement"]
    AM --> PLAN
    WHAT -->|"Appointment"| AA["Add appointment"]
    AA --> PLAN
 
    LOG --> VS["Visit sheet (PDF)"]
 
    CIRCLE --> IC["Invite to circle"]
    CIRCLE --> MF["Medical file"]
    CIRCLE --> PS["Patient's phone settings"]
```
 
### 3.2 Back-End Classes

| Backend Class | Responsibility | Key methods |
|---|---|---|
| `User` | A person with an account, identified by phone number | `deleteAccount()` |
| `OtpChallenge` | A login code sent to a phone number | `verify(code)` |
| `OtpAttemptLimit` | Counts failed code attempts per phone or per device and locks them | `recordFailure()`, `isLocked(at)` |
| `Circle` | The root of the model: one circle cares for one patient | `hasManager()`, `delete(by)`, `removeMember(member, replacement)`, `exportCareRecord()`, `nextEscalationRecipient(after)` |
| `CircleMember` | A user's membership in a circle, with the role in that circle | `canManage()`, `canRecord(task)`, `isThePatient()` |
| `CircleRequest` | A request to create a circle for a patient, approved or declined by the patient | `approve(by)`, `decline(by)` |
| `Invitation` | An invitation to join a circle with a role | `accept(by)` |
| `Patient` | The person the circle cares for | `fullName()` |
| `MedicalProfile` | The patient's medical file |  |
| `EmergencyContact` | A contact person in the medical file |  |
| `CarePlanItem` (abstract) | An item in the circle's plan | `isActive(on)` |
| `ScheduledItem` (abstract) | A plan item that repeats on days and times | `occurrencesOn(day, location)` |
| `Medication` | A medicine in the plan with its dose and stock | `effectiveDose(at)`, `changeDose(by, dose, from)`, `addStock(by, quantity)`, `remainingStock()`, `estimatedRunOutAt(at)`, `coversTreatment(at)` |
| `MedicationChange` | A record of a dose change or a stop |  |
| `StockAddition` | A record of stock added to a medicine |  |
| `MeasurementPlan` | A scheduled measurement (blood glucose or blood pressure) with its target range | `isOutsideRange(reading)` |
| `Appointment` | A medical appointment |  |
| `AppointmentOccurrence` | One date of an appointment |  |
| `Task` | One thing to do at a time, generated from a plan item | `record(by, dose, at, actionId, expectedVersion)` |
| `TaskAssignment` | An offer of a task to a member, who accepts or declines | `accept()`, `decline()` |
| `Measurement` | A recorded reading |  |
| `Escalation` | Moves to the next recipient when a task is missed | `notifyNext()`, `respond(by)` |
| `Notification` | A message sent to a member | `respond()` |
| `AttentionItem` | An item that needs a member's attention | `resolve(by)` |
| `PatientLocation` (dataType) | The patient's location |  |
| `MedicationQuantity` (dataType) | An amount of a medicine with its unit |  |
| `TargetRange` (dataType) | The target range of a measurement |  |
| `EmergencyCard` (dataType) | Built from the current records, not stored |  |


```mermaid
classDiagram
    direction TB
 
    
    class User {
        -UID id
        -String phoneNumber
        -String firstName
        -String lastName
        -String displayName
        +deleteAccount()
    }
 
    class Device {
        -UID id
        -String installationId
        -Platform platform
        -String pushToken
    }
 
    class OtpChallenge {
        -UID id
        -String phoneNumber
        -String codeHash
        -DateTime validUntil
        +verify()
    }
 
    class OtpAttemptLimit {
        -AttemptScope scope
        -String key
        -Integer failedAttempts
        -DateTime lockedUntil
        +recordFailure()
        +isLocked()
    }
 
    
    class Circle {
        -UID id
        -AppMode patientMode
        -CircleStatus status
        -List~CircleMember~ escalationRecipients
        -Integer escalationStepMin = 20
        +hasManager()
        +delete()
        +removeMember()
        +exportCareRecord()
        +nextEscalationRecipient()
    }
 
    class CircleMember {
        -UID id
        -Role role
        +canManage()
        +canRecord()
        +isThePatient()
    }
 
    class CircleRequest {
        -UID id
        -String patientPhone
        -String patientFirstName
        -String patientLastName
        -AppMode requestedMode
        -RequestStatus status
        -DateTime expiresAt
        +approve()
        +decline()
    }
 
    class Invitation {
        -UID id
        -String invitedPhone
        -InvitableRole role
        -InvitationStatus status
        +accept()
    }
 
    class Patient {
        -UID id
        -String firstName
        -String lastName
        -Integer birthYear
        -String phoneNumber
        -PatientLocation location
        +fullName()
    }
 
    class PatientLocation {
        <<dataType>>
        -String city
        -Real latitude
        -Real longitude
        -String timeZoneId
        -LocationSource source
        -DateTime updatedAt
    }
 
    class MedicalProfile {
        -String bloodType
        -List~String~ allergies
        -List~String~ chronicConditions
    }
 
    class EmergencyContact {
        -UID id
        -String fullName
        -String phoneNumber
        -String relationToPatient
    }
 
    class EmergencyCard {
        <<dataType>>
        -String patientFullName
        -String bloodType
        -List~String~ allergies
        -List~String~ chronicConditions
        -List~EmergencyContact~ contacts
        -List~String~ currentMedicationAndDose
    }
 
    
    class CarePlanItem {
        <<abstract>>
        -UID id
        -String title
        -Date startsOn
        -Date endsOn
        -ItemStatus status
        +isActive()
    }
 
    class ScheduledItem {
        <<abstract>>
        -List~Time~ times
        -List~DayOfWeek~ daysOfWeek
        -Integer maxLatenessMin
        +occurrencesOn()
    }
 
    class Medication {
        -MedicationQuantity baseDose
        -String strength
        -MedicationQuantity lowStockAt
        +effectiveDose()
        +changeDose()
        +addStock()
        +remainingStock()
        +estimatedRunOutAt()
        +coversTreatment()
    }
 
    class MedicationQuantity {
        <<dataType>>
        -Real value
        -String unit
    }
 
    class MedicationChange {
        -UID id
        -ChangeKind kind
        -MedicationQuantity newDose
        -DateTime effectiveFrom
        -String orderedBy
        -String reason
    }
 
    class StockAddition {
        -UID id
        -MedicationQuantity quantity
        -Date addedOn
    }
 
    class MeasurementPlan {
        -MeasurementType type
        -TargetRange range
        +isOutsideRange()
    }
 
    class TargetRange {
        <<dataType>>
        -Real minimum
        -Real maximum
        -Real secondaryMinimum
        -Real secondaryMaximum
    }
 
    class Appointment {
        -AppointmentKind kind
        -String place
    }
 
    class AppointmentOccurrence {
        -UID id
        -DateTime startsAt
        -AppointmentStatus status
    }
 
    
    class Task {
        -UID id
        -DateTime dueAt
        -Prayer prayerPeriod
        -MedicationQuantity plannedDose
        -MedicationQuantity doseTaken
        -TaskStatus status
        -DateTime recordedAt
        -UID clientActionId
        -Integer version
        -TaskOutcome outcome
        +record()
    }
 
    class TaskAssignment {
        -UID id
        -AssignmentStatus status
        -DateTime respondBy
        +accept()
        +decline()
    }
 
    class Measurement {
        -UID id
        -MeasurementType type
        -Real primaryValue
        -Real secondaryValue
        -String unit
        -DateTime measuredAt
        -UID clientActionId
        -TargetRange rangeAtRecording
    }
 
    
    class Escalation {
        -UID id
        -EscalationStatus status
        -Integer step
        -DateTime nextStepAt
        +notifyNext()
        +respond()
    }
 
    class Notification {
        -UID id
        -NotificationStatus status
        +respond()
    }
 
    class AttentionItem {
        -UID id
        -AttentionStatus status
        +resolve()
    }
 
    
    User "0..1" --> "0..*" Device : current installations
    OtpChallenge "0..*" --> "1" Device : requested from
    OtpChallenge ..> OtpAttemptLimit : checks device and phone limits
 
    
    Circle "1" *-- "1" Patient : cares for
    Patient "0..1" --> "0..1" User : patient account
    User "1" --> "0..*" CircleMember : joins as
    Circle "1" *-- "1..*" CircleMember : members
    CircleRequest "0..*" --> "1" User : created by
    CircleRequest "0..*" --> "0..1" User : patient approval
    CircleRequest "0..1" --> "0..1" Circle : creates if approved
    Circle "1" *-- "0..*" Invitation : invitations
    Invitation "0..1" --> "0..1" CircleMember : becomes
 
    Patient "1" *-- "1" MedicalProfile : medical file
    MedicalProfile "1" *-- "0..*" EmergencyContact : contacts
    Circle ..> EmergencyCard : builds from current records
 
    
    Circle "1" *-- "0..*" CarePlanItem : plan
    CarePlanItem <|-- ScheduledItem
    ScheduledItem <|-- Medication
    ScheduledItem <|-- MeasurementPlan
    CarePlanItem <|-- Appointment
    Appointment "1" *-- "0..*" AppointmentOccurrence : dates
    Medication "1" *-- "0..*" MedicationChange : dose history
    Medication "1" *-- "0..*" StockAddition : stock added
    AppointmentOccurrence "0..1" --> "0..1" Task : appointment task
 
    
    Circle "1" *-- "0..*" Task : tasks
    CarePlanItem "0..1" --> "0..*" Task : generates
    Task "0..*" --> "1" CircleMember : primary responsible
    Task "1" *-- "0..*" TaskAssignment : assignment history
    TaskAssignment "0..*" --> "0..1" CircleMember : offered to
    Circle "1" *-- "0..*" Measurement : readings
    Measurement "0..*" --> "0..1" MeasurementPlan : follows
    Measurement "0..1" --> "0..1" Task : fulfils
 
    Circle "1" *-- "0..*" Escalation : escalations
    Escalation "0..*" --> "0..1" Task : missed task
    Circle "1" *-- "0..*" Notification : notifications
    Escalation "0..1" --> "0..*" Notification : sends
    Notification "0..*" --> "1" CircleMember : recipient
    Notification "0..*" --> "0..1" Task : task reminder
    Circle "1" *-- "0..*" AttentionItem : needs attention
    AttentionItem "0..*" --> "0..1" Task : about
```

### 3.3 Entity Relationship Diagram
```mermaid
erDiagram
    USERS {
        uuid id PK
        string phone_number UK
        string first_name
        string last_name
        string display_name
    }
    DEVICES {
        uuid id PK
        uuid user_id FK
        string installation_id UK
        string platform
        string push_token
    }
    OTP_CHALLENGES {
        uuid id PK
        uuid device_id FK
        string phone_number
        string code_hash
        datetime valid_until
    }
    OTP_ATTEMPT_LIMITS {
        uuid id PK
        string scope
        string limit_key
        int failed_attempts
        datetime locked_until
    }
    CIRCLES {
        uuid id PK
        string patient_mode
        string status
        int escalation_step_min
    }
    PATIENTS {
        uuid id PK
        uuid circle_id FK, UK
        uuid user_id FK, UK
        string first_name
        string last_name
        int birth_year
        string phone_number
        string city
        decimal latitude
        decimal longitude
        string time_zone_id
        string location_source
        datetime location_updated_at
    }
    CIRCLE_MEMBERS {
        uuid id PK
        uuid circle_id FK
        uuid user_id FK
        string role
    }
    ESCALATION_RECIPIENTS {
        uuid id PK
        uuid circle_id FK
        uuid circle_member_id FK
        int position
    }
    CIRCLE_REQUESTS {
        uuid id PK
        uuid created_by_user_id FK
        uuid patient_user_id FK
        uuid circle_id FK, UK
        string patient_phone
        string patient_first_name
        string patient_last_name
        string requested_mode
        string status
        datetime expires_at
    }
    INVITATIONS {
        uuid id PK
        uuid circle_id FK
        uuid circle_member_id FK, UK
        string invited_phone
        string role
        string status
    }
    MEDICAL_PROFILES {
        uuid id PK
        uuid patient_id FK, UK
        string blood_type
        json allergies
        json chronic_conditions
    }
    EMERGENCY_CONTACTS {
        uuid id PK
        uuid medical_profile_id FK
        string full_name
        string phone_number
        string relation_to_patient
    }
    CARE_PLAN_ITEMS {
        uuid id PK
        uuid circle_id FK
        string item_type
        string title
        date starts_on
        date ends_on
        string status
    }
    SCHEDULED_ITEMS {
        uuid care_plan_item_id PK, FK
        json times
        json days_of_week
        int max_lateness_min
    }
    MEDICATIONS {
        uuid care_plan_item_id PK, FK
        decimal base_dose_value
        string base_dose_unit
        string strength
        decimal low_stock_value
        string low_stock_unit
    }
    MEASUREMENT_PLANS {
        uuid care_plan_item_id PK, FK
        string type
        decimal range_min
        decimal range_max
        decimal secondary_min
        decimal secondary_max
    }
    APPOINTMENTS {
        uuid care_plan_item_id PK, FK
        string kind
        string place
    }
    APPOINTMENT_OCCURRENCES {
        uuid id PK
        uuid appointment_id FK
        datetime starts_at
        string status
    }
    MEDICATION_CHANGES {
        uuid id PK
        uuid medication_id FK
        string kind
        decimal new_dose_value
        string new_dose_unit
        datetime effective_from
        string ordered_by
        string reason
    }
    STOCK_ADDITIONS {
        uuid id PK
        uuid medication_id FK
        decimal quantity_value
        string quantity_unit
        date added_on
    }
    TASKS {
        uuid id PK
        uuid circle_id FK
        uuid care_plan_item_id FK
        uuid appointment_occurrence_id FK, UK
        uuid primary_responsible_id FK
        datetime due_at
        string prayer_period
        decimal planned_dose_value
        string planned_dose_unit
        decimal dose_taken_value
        string dose_taken_unit
        string status
        datetime recorded_at
        uuid client_action_id
        int version
        string outcome
    }
    TASK_ASSIGNMENTS {
        uuid id PK
        uuid task_id FK
        uuid offered_to_member_id FK
        string status
        datetime respond_by
    }
    MEASUREMENTS {
        uuid id PK
        uuid circle_id FK
        uuid measurement_plan_id FK
        uuid task_id FK, UK
        string type
        decimal primary_value
        decimal secondary_value
        string unit
        datetime measured_at
        uuid client_action_id
        json range_at_recording
    }
    ESCALATIONS {
        uuid id PK
        uuid circle_id FK
        uuid task_id FK
        string status
        int step
        datetime next_step_at
    }
    NOTIFICATIONS {
        uuid id PK
        uuid circle_id FK
        uuid escalation_id FK
        uuid recipient_member_id FK
        uuid task_id FK
        string status
    }
    ATTENTION_ITEMS {
        uuid id PK
        uuid circle_id FK
        uuid task_id FK
        string status
    }

    USERS |o--o{ DEVICES : "signs in on"
    DEVICES ||--o{ OTP_CHALLENGES : "requested from"
    USERS |o--o| PATIENTS : "patient account"
    CIRCLES ||--|| PATIENTS : "cares for"
    CIRCLES ||--|{ CIRCLE_MEMBERS : "has members"
    USERS ||--o{ CIRCLE_MEMBERS : "joins as"
    CIRCLES ||--o{ ESCALATION_RECIPIENTS : "orders"
    CIRCLE_MEMBERS ||--o{ ESCALATION_RECIPIENTS : "ranked as"
    USERS ||--o{ CIRCLE_REQUESTS : "creates"
    USERS |o--o{ CIRCLE_REQUESTS : "approves"
    CIRCLES |o--o| CIRCLE_REQUESTS : "created from"
    CIRCLES ||--o{ INVITATIONS : "invites"
    CIRCLE_MEMBERS |o--o| INVITATIONS : "becomes"

    PATIENTS ||--|| MEDICAL_PROFILES : "medical file"
    MEDICAL_PROFILES ||--o{ EMERGENCY_CONTACTS : "contacts"

    CIRCLES ||--o{ CARE_PLAN_ITEMS : "plan"
    CARE_PLAN_ITEMS ||--o| SCHEDULED_ITEMS : "is a"
    SCHEDULED_ITEMS ||--o| MEDICATIONS : "is a"
    SCHEDULED_ITEMS ||--o| MEASUREMENT_PLANS : "is a"
    CARE_PLAN_ITEMS ||--o| APPOINTMENTS : "is a"
    APPOINTMENTS ||--o{ APPOINTMENT_OCCURRENCES : "dates"
    MEDICATIONS ||--o{ MEDICATION_CHANGES : "dose history"
    MEDICATIONS ||--o{ STOCK_ADDITIONS : "stock added"

    CIRCLES ||--o{ TASKS : "tasks"
    CARE_PLAN_ITEMS |o--o{ TASKS : "generates"
    APPOINTMENT_OCCURRENCES |o--o| TASKS : "appointment task"
    CIRCLE_MEMBERS ||--o{ TASKS : "primary responsible"
    TASKS ||--o{ TASK_ASSIGNMENTS : "assignment history"
    CIRCLE_MEMBERS |o--o{ TASK_ASSIGNMENTS : "offered to"

    CIRCLES ||--o{ MEASUREMENTS : "readings"
    MEASUREMENT_PLANS |o--o{ MEASUREMENTS : "follows"
    TASKS |o--o| MEASUREMENTS : "fulfils"

    CIRCLES ||--o{ ESCALATIONS : "escalations"
    TASKS |o--o{ ESCALATIONS : "missed task"
    CIRCLES ||--o{ NOTIFICATIONS : "notifications"
    ESCALATIONS |o--o{ NOTIFICATIONS : "sends"
    CIRCLE_MEMBERS ||--o{ NOTIFICATIONS : "recipient"
    TASKS |o--o{ NOTIFICATIONS : "task reminder"
    CIRCLES ||--o{ ATTENTION_ITEMS : "needs attention"
    TASKS |o--o{ ATTENTION_ITEMS : "about"
```

## 4. High-Level Sequence Diagrams

### 4.1 User Login

The user signs in with a one-time code sent by SMS. The API checks the attempt limits for the phone and the device, sends the code, verifies it, then registers the device and returns a session token.

```mermaid
sequenceDiagram
    autonumber
    actor U as User
    participant App as Flutter App
    participant API as Flask REST API
    participant DB as PostgreSQL
    participant SMS as SMS gateway

    U->>App: Enter phone number
    App->>API: POST /auth/otp/request (phone, installationId)
    API->>DB: Load attempt limits (phone and device)
    DB-->>API: Limits
    alt Phone or device is locked
        API-->>App: 429 Too many attempts (lockedUntil)
        App-->>U: Show try again later
    else Allowed
        API->>DB: Save OTP challenge (code hash, validUntil)
        API->>SMS: Send OTP code to phone
        SMS-->>U: OTP message
        API-->>App: 200 Challenge created
        App-->>U: Ask for the code
        U->>App: Enter the code
        App->>API: POST /auth/otp/verify (challengeId, code, installationId, platform, pushToken)
        API->>DB: Load challenge and attempt limits
        DB-->>API: Challenge and limits
        API->>API: Check lock status, expiry and code
        alt Wrong code, expired code or locked
            API->>DB: Record failure (phone and device)
            API-->>App: 401 Invalid code (or 429 if now locked)
            App-->>U: Show error
        else Correct code
            API->>DB: Find or create user by phone number
            API->>DB: Register or update device (installationId, platform, pushToken)
            DB-->>API: User and device
            API-->>App: 200 Session token and user
            App-->>U: Login completed
        end
    end
```

### 4.2 Add Medication

The patient or manager photographs the medication package and the app reads the name on the device (OCR). After the user completes the details, the API checks that the circle member is allowed to manage the care plan, then saves the medication and today's tasks in one transaction.

```mermaid
sequenceDiagram
    autonumber
    actor U as Patient / Manager
    participant App as Flutter App
    participant API as Flask REST API
    participant DB as PostgreSQL

    U->>App: Take photo of medication package
    App->>App: Extract medication name using OCR
    alt Name not detected
        App-->>U: Ask to retake the photo
    else Name detected
        App-->>U: Show extracted name
        U->>App: Review name, enter dose, days, times and start date
        App->>API: POST /circles/{id}/medications
        API->>DB: Load circle member
        DB-->>API: Member role
        API->>API: member.canManage()

        alt Not permitted
            API-->>App: 403 Forbidden
            App-->>U: Show permission error
        else Permitted

            API->>DB: Insert care plan item and medication
            DB-->>API: Medication saved
            API->>DB: Insert today's tasks
            DB-->>API: Tasks created
            API-->>App: 201 Created (medication)
            App-->>U: Display added medication

        end
    end
```


## 5. API Specifications

### 5.1 External APIs

[List the external APIs used by the MVP, their purposes,
and the reasons for choosing them.
If none are used, state that explicitly.]

### 5.2 Internal API Endpoints

[For each endpoint, specify:
- URL path.
- HTTP method.
- Input format: JSON, query parameters, or other applicable format.
- Output format, including the response structure.]

## 6. SCM and QA Plans

### 6.1 Source Control Management

[Specify:
- Version control tool.
- Branching strategy.
- Commit practices.
- Pull request process.
- Code review and merge process.]

### 6.2 Quality Assurance

[Specify:
- Testing types and what they cover.
- Testing tools.
- Manual testing of critical user flows, where applicable.]

### 6.3 Deployment Pipeline

[Describe the planned deployment pipeline for staging
and production environments.]

## 7. Technical Justifications

[Explain the reasons for the selected technologies and designs.
Connect each decision to functional requirements,
non-functional requirements, constraints,
or expert recommendations.
Include source links where a justification relies on a reference.]
