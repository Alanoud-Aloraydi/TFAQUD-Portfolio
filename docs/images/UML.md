classDiagram
    direction TB

    class User {
        -UID id
        -String phoneNumber
        -String displayName
        -Integer birthYear
        -String city
        -String language
        -DateTime createdAt
        +authenticate()
        +updateProfile()
        +deleteAccount()
    }

    class Patient {
        -UID id
        -String name
        -Integer birthYear
        -String city
        -String photoUrl
        -String phoneNumber
        +getCareGroup()
        +manageMedication()
        +manageAppointment()
        +recordMeasurement()
        +completeTask()
        +viewReports()
    }

    class CareManager {
        -UID id
        -UID careGroupId
        -String relationToPatient
        +inviteMember()
        +removeMember()
        +updatePermissions()
        +assignTask()
        +manageMedication()
        +manageAppointment()
        +createVisitSheet()
    }

    class CareAssistant {
        -UID id
        -UID careGroupId
        -String relationToPatient
        +viewPatientData()
        +viewTasks()
        +completeAssignedTask()
        +viewAppointments()
    }

    class CareGroup {
        -UID id
        -UID patientId
        -String status
        -DateTime createdAt
        -DateTime archivedAt
        +addMember()
        +removeMember()
        +inviteMember()
        +archive()
        +reopen()
    }

    class CareGroupMember {
        -UID id
        -UID careGroupId
        -UID userId
        -String role
        -String relationToPatient
        -String status
        -DateTime joinedAt
        +updatePermissions()
        +changeRole()
        +leaveGroup()
        +checkPermission()
    }

    class Medication {
        -UID id
        -UID careGroupId
        -String scientificName
        -String strength
        -Real doseAmount
        -String mealRelation
        -Integer durationDays
        -String instructions
        -String photoUrl
        -Integer pillsInBox
        -Integer lowStockAt
        +create()
        +update()
        +stop()
        +addMedicationBox()
        +deductDose()
        +checkStock()
    }

    class MedicationChange {
        -UID id
        -UID medicationId
        -Real previousDose
        -Real newDose
        -String orderedBy
        -String reason
        -DateTime effectiveFrom
        -UID madeBy
        +recordChange()
        +viewHistory()
    }

    class Appointment {
        -UID id
        -UID careGroupId
        -String type
        -DateTime startsAt
        -String place
        -String preparation
        -String status
        +create()
        +update()
        +reschedule()
        +cancel()
        +assignCompanion()
    }

    class HealthMeasurement {
        -UID id
        -UID careGroupId
        -String type
        -Real primaryValue
        -Real secondaryValue
        -Integer pulse
        -String unit
        -DateTime measuredAt
        -UID recordedBy
        +record()
        +update()
        +getHistory()
        +checkTargetRange()
    }

    class Task {
        -UID id
        -UID careGroupId
        -UID carePlanItemId
        -String type
        -String title
        -DateTime dueAt
        -Real plannedDose
        -String status
        -DateTime completedAt
        -UID completedBy
        +create()
        +complete()
        +postpone()
        +markMissed()
        +updateRecord()
    }

    class TaskAssignment {
        -UID id
        -UID taskId
        -UID assignedTo
        -String status
        -String note
        -DateTime createdAt
        -DateTime respondedAt
        +assign()
        +accept()
        +decline()
        +reassign()
    }

    class Visit {
        -UID id
        -UID appointmentId
        -Date visitDate
        -String status
        -String notes
        -String voiceNoteUrl
        -DateTime savedAt
        -UID savedBy
        +create()
        +update()
        +save()
        +addNextAppointment()
    }

    class MedicalProfile {
        -UID id
        -UID patientId
        -String bloodType
        -String allergies
        -String chronicConditions
        -String doctors
        +create()
        +update()
        +view()
    }

    class Notification {
        -UID id
        -UID userId
        -UID taskId
        -String type
        -String channel
        -DateTime scheduledAt
        -DateTime deliveredAt
        -String status
        +schedule()
        +send()
        +open()
        +respond()
    }

    class AuthService {
        +sendOTP()
        +verifyOTP()
        +login()
        +logout()
    }

    class UserService {
        +createUser()
        +updateUser()
        +getUser()
        +deleteUser()
    }

    class CareCoordinationService {
        +createCareGroup()
        +addMember()
        +removeMember()
        +updatePermissions()
        +assignTask()
    }

    class MedicationService {
        +createMedication()
        +updateMedication()
        +stopMedication()
        +recordMedicationChange()
        +checkMedicationStock()
    }

    class AppointmentService {
        +createAppointment()
        +updateAppointment()
        +rescheduleAppointment()
        +cancelAppointment()
        +assignCompanion()
    }

    class MeasurementService {
        +recordMeasurement()
        +updateMeasurement()
        +getMeasurementHistory()
        +checkTargetRange()
    }

    class TaskService {
        +createTask()
        +assignTask()
        +completeTask()
        +postponeTask()
        +markTaskMissed()
    }

    class VisitService {
        +createVisit()
        +updateVisit()
        +saveVisit()
        +createVisitSheet()
    }

    class NotificationService {
        +scheduleNotification()
        +sendNotification()
        +sendReminder()
    }

    class MedicationAPIService {
        +identifyMedication()
        +getMedicationInformation()
        +getMedicationImage()
    }

    class PrayerTimesAPIService {
        +getPrayerTimes()
        +getTimesByCity()
    }


    %% User roles
    User <|-- Patient
    User <|-- CareManager
    User <|-- CareAssistant

    %% Care Group and Members
    CareGroup "1" --> "1" Patient : has patient
    CareGroup "1" *-- "1..*" CareGroupMember : contains
    User "1" --> "0..*" CareGroupMember : has membership
    Patient "1" --> "1" CareGroupMember : is patient member

    %% Patient medical profile
    Patient "1" *-- "1" MedicalProfile : has

    %% Medications
    CareGroup "1" --> "0..*" Medication : manages
    Medication "1" *-- "0..*" MedicationChange : has history
    CareGroupMember "1" --> "0..*" MedicationChange : records

    %% Appointments and visits
    CareGroup "1" --> "0..*" Appointment : schedules
    CareGroupMember "0..1" --> "0..*" Appointment : accompanies
    Appointment "1" *-- "0..*" Visit : documents
    CareGroupMember "1" --> "0..*" Visit : saves

    %% Health measurements
    CareGroup "1" --> "0..*" HealthMeasurement : records
    CareGroupMember "1" --> "0..*" HealthMeasurement : records

    %% Tasks
    CareGroup "1" --> "0..*" Task : contains
    Medication "0..1" --> "0..*" Task : generates
    Appointment "0..1" --> "0..*" Task : generates
    Task "1" *-- "0..*" TaskAssignment : has assignments
    CareGroupMember "1" --> "0..*" TaskAssignment : receives

    %% Notifications
    User "1" --> "0..*" Notification : receives
    Task "0..1" --> "0..*" Notification : triggers

    %% Services
    AuthService ..> User : authenticates
    UserService ..> User : manages

    CareCoordinationService ..> CareGroup : manages
    CareCoordinationService ..> CareGroupMember : manages

    MedicationService ..> Medication : manages
    MedicationService ..> MedicationChange : records

    AppointmentService ..> Appointment : manages

    MeasurementService ..> HealthMeasurement : manages

    TaskService ..> Task : manages
    TaskService ..> TaskAssignment : manages

    VisitService ..> Visit : manages
    VisitService ..> Appointment : updates

    NotificationService ..> Notification : sends
    NotificationService ..> Task : sends reminders

    MedicationAPIService ..> Medication : provides information
    PrayerTimesAPIService ..> Patient : uses patient city

    %% User interactions with services
    Patient ..> MedicationService : calls
    Patient ..> AppointmentService : calls
    Patient ..> MeasurementService : calls
    Patient ..> TaskService : calls
    Patient ..> VisitService : calls

    CareManager ..> CareCoordinationService : calls
    CareManager ..> MedicationService : calls
    CareManager ..> AppointmentService : calls
    CareManager ..> MeasurementService : calls
    CareManager ..> TaskService : calls
    CareManager ..> VisitService : calls

    CareAssistant ..> TaskService : calls
    CareAssistant ..> AppointmentService : views
