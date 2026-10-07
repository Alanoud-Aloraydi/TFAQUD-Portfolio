flowchart TD
    USER["Patient / Care Manager / Care Assistant"]

    subgraph CAREOS["TFAQUD Care OS"]
        APP["Flutter mobile app"]
        API["Flask REST API"]
        OCR["Local OCR"]
        DB[("PostgreSQL database")]
        
        APP -->|"HTTPS request, REST/JSON"| API
        API -->|"JSON response"| APP
        API -->|"SQL query"| DB
        DB -->|"Query result"| API
        
        APP -->|"Pass medicine image"| OCR
        OCR -->|"Extracted raw text"| APP
    end

    PRAYERAPI["Prayer times API"]
    FCM["Firebase Cloud Messaging"]

    USER -->|"Uses application & scans medicine"| APP
    API -->|"Patient city"| PRAYERAPI
    PRAYERAPI -->|"Prayer times"| API
    API -->|"Trigger reminder"| FCM
    FCM -->|"Push notification"| APP
