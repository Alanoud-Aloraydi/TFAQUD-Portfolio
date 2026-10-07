sequenceDiagram
    actor User as Patient / Care Manager
    participant App as Flutter App
    participant API as Flask REST API
    participant MedService as MedicationService
    participant DB as PostgreSQL

    User->>App: Take medication photo
    App->>App: Extract medication name using OCR
    App->>API: POST /medications with medication data
    API->>MedService: createMedication(data)
    MedService->>DB: Insert medication record
    DB-->>MedService: Medication saved
    MedService-->>API: Medication created
    API-->>App: Success response
    App-->>User: Display added medication
