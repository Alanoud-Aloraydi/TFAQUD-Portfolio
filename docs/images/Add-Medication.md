sequenceDiagram
    autonumber
    actor U as Patient / Care Manager
    participant App as Flutter App
    participant API as Flask REST API
    participant MedService as MedicationService
    participant DB as PostgreSQL
    participant FCM as Firebase Cloud Messaging

    U->>App: Take photo of medication package
    App->>App: Extract medication name using OCR

    alt Name not detected
        App-->>U: Ask to retake the photo
    else Name detected
        App-->>U: Show extracted name
        U->>App: Review name, enter dose, meal relation and time slots
        App->>API: POST /patients/{id}/medications
        API->>MedService: createMedication(data)
        MedService->>DB: Insert medication
        DB-->>MedService: Medication saved
        MedService->>DB: Insert tasks and ReminderEvents
        DB-->>MedService: Tasks and reminders created
        MedService->>DB: Insert ActivityLog
        DB-->>MedService: Activity recorded
        MedService->>FCM: Notify other CircleMembers
        MedService-->>API: Medication created
        API-->>App:  Created
        App-->>U: Display added medication
        
    end
