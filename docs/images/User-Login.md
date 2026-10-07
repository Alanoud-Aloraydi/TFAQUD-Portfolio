sequenceDiagram
    actor User
    participant App as Flutter App
    participant API as Flask REST API
    participant Auth as AuthService
    participant DB as PostgreSQL
    participant SMS as SMS/OTP Service

    User->>App: Enter phone number
    App->>API: POST /send-otp
    API->>Auth: Generate OTP
    Auth->>DB: Store OTP and phone number
    Auth->>SMS: Send OTP
    SMS-->>User: Verification code

    User->>App: Enter verification code
    App->>API: POST /verify-otp
    API->>Auth: Verify OTP
    Auth->>DB: Check OTP
    DB-->>Auth: OTP result
    Auth-->>API: Authentication result
    API-->>App: Login response + user role
    App-->>User: Display appropriate dashboard
