erDiagram

    USERS {
        int id PK
        string phone_number UK
        string display_name
        int birth_year
        string city
        string language
        datetime created_at
    }

    PATIENTS {
        int id PK
        int user_id FK
        string name
        int birth_year
        string city
        string photo_url
        string phone_number
    }

    MEDICAL_PROFILES {
        int id PK
        int patient_id FK
        string blood_type
        text allergies
        text chronic_conditions
        text doctors
    }

    CARE_GROUPS {
        int id PK
        int patient_id FK
        string status
        datetime created_at
        datetime archived_at
    }

    CARE_GROUP_MEMBERS {
        int id PK
        int care_group_id FK
        int user_id FK
        string role
        string relation_to_patient
        string status
        datetime joined_at
        datetime last_used_at
    }

    MEDICATIONS {
        int id PK
        int care_group_id FK
        string scientific_name
        string strength
        string dose_amount
        string meal_relation
        int duration_days
        text instructions
        string photo_url
        int pills_in_box
        int low_stock_at
        string status
    }

    MEDICATION_CHANGES {
        int id PK
        int medication_id FK
        string previous_dose
        string new_dose
        string ordered_by
        text reason
        date effective_from
        int made_by FK
        datetime made_at
    }

    APPOINTMENTS {
        int id PK
        int care_group_id FK
        string type
        datetime starts_at
        string place
        text preparation
        string status
        int companion_id FK
    }

    HEALTH_MEASUREMENTS {
        int id PK
        int care_group_id FK
        string type
        float primary_value
        float secondary_value
        int pulse
        string unit
        string context
        datetime measured_at
        int recorded_by FK
    }

    TASKS {
        int id PK
        int care_group_id FK
        int medication_id FK
        int appointment_id FK
        string type
        string title
        datetime due_at
        string planned_dose
        string status
        datetime completed_at
        int completed_by FK
        datetime postponed_until
        text note
    }

    TASK_ASSIGNMENTS {
        int id PK
        int task_id FK
        int assigned_to FK
        string status
        text note
        datetime created_at
        datetime responded_at
    }

    VISITS {
        int id PK
        int appointment_id FK
        date visit_date
        string status
        text notes
        string voice_note_url
        datetime saved_at
        int saved_by FK
    }

    NOTIFICATIONS {
        int id PK
        int user_id FK
        int task_id FK
        string type
        string channel
        datetime scheduled_at
        datetime delivered_at
        datetime opened_at
        string status
    }

    USERS ||--o| PATIENTS : "has patient profile"
    PATIENTS ||--|| MEDICAL_PROFILES : "has"
    PATIENTS ||--o{ CARE_GROUPS : "belongs to"
    CARE_GROUPS ||--|{ CARE_GROUP_MEMBERS : "contains"
    USERS ||--o{ CARE_GROUP_MEMBERS : "joins"

    CARE_GROUPS ||--o{ MEDICATIONS : "manages"
    MEDICATIONS ||--o{ MEDICATION_CHANGES : "has history"
    CARE_GROUP_MEMBERS ||--o{ MEDICATION_CHANGES : "records"

    CARE_GROUPS ||--o{ APPOINTMENTS : "schedules"
    CARE_GROUP_MEMBERS o|--o{ APPOINTMENTS : "accompanies"

    CARE_GROUPS ||--o{ HEALTH_MEASUREMENTS : "stores"
    CARE_GROUP_MEMBERS ||--o{ HEALTH_MEASUREMENTS : "records"

    CARE_GROUPS ||--o{ TASKS : "contains"
    MEDICATIONS o|--o{ TASKS : "relates to"
    APPOINTMENTS o|--o{ TASKS : "relates to"
    TASKS ||--o{ TASK_ASSIGNMENTS : "has assignments"
    CARE_GROUP_MEMBERS ||--o{ TASK_ASSIGNMENTS : "receives"

    APPOINTMENTS ||--o{ VISITS : "documents"
    CARE_GROUP_MEMBERS o|--o{ VISITS : "saves"

    USERS ||--o{ NOTIFICATIONS : "receives"
    TASKS o|--o{ NOTIFICATIONS : "triggers"
