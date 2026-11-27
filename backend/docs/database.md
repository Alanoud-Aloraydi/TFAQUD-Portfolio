# The database

PostgreSQL 16 holds everything the server keeps. There are 31 tables.
The SQLAlchemy models in `app/models` describe them, and they match the
migrated database exactly (the same columns, checks, indexes and comments).

## The tables

Every id is a `uuid`. Every time is a `timestamp with time zone`. A day is
a `date` in the patient's own time zone (`care_circle.time_zone`).

### Accounts and sign-in (`app/models/account.py`, `photo.py`)

| Table | One row is |
|---|---|
| `account` | A person, known by one phone number. The names, birth date, city and avatar come from onboarding. `app_mode` is `detailed` or `simplified`, and once set it never changes. |
| `account_photo` | The account's own photo, as a cropped PNG. |
| `account_session` | One sign-in: the hash of its refresh token, and the phone's OneSignal subscription. It ends when it is signed out (`revoked_at`). |
| `otp_request` | A request for a sign-in code to a phone number. The code itself is never stored. |
| `otp_send` | One SMS sent for a request, with its state. |

### Circles (`app/models/circle.py`, `circle_request.py`, `medical.py`)

| Table | One row is |
|---|---|
| `care_circle` | A circle, which is one patient. A patient with an account is that account (`account_id`); a patient without one keeps their own names here. It also holds the zone, the place, the blood type and whether conditions and allergies were answered. |
| `care_circle_manager` | An account that manages a circle, and what it may edit there. |
| `care_circle_photo` | The photo of a patient without an account. |
| `care_circle_invitation` | An invitation to manage a circle, sent to a phone number. |
| `care_circle_request` | A request to make a circle for a patient who has an account. The patient's acceptance is their consent. |
| `patient_condition` | One chronic condition of the patient. |
| `patient_allergy` | One allergy of the patient (a medicine or a food). |
| `emergency_contact` | One emergency contact of the patient. |

### Medicines (`app/models/medication.py`, `medication_dose.py`)

| Table | One row is |
|---|---|
| `medication_plan` | A medicine of the patient. Stopping it sets `stopped_at`. |
| `medication_plan_version` | One version of a medicine. A version never changes: an edit makes a new version from a day on. |
| `medication_plan_photo` | The photo of a medicine. |
| `medication_schedule` | One dose time of a version: weekly, monthly, or every few days. |
| `medication_schedule_day` | A weekday of a weekly dose time (1 Monday to 7 Sunday). |
| `medication_schedule_month_day` | A day of the month of a monthly dose time. |
| `medication_dose_record` | What was done with one dose: taken or skipped. |
| `medication_extra_dose` | A dose taken outside the dose times («سجّل جرعة الآن»). |

The doses themselves are never stored: they are worked out from the
schedules. Only what was done with them is a row.

### Measurements (`app/models/measurement.py`, `measurement_reading.py`)

| Table | One row is |
|---|---|
| `measurement_plan` | A glucose or blood pressure plan of the patient. |
| `measurement_plan_version` | One version of a plan, from a day on. |
| `measurement_plan_weekday` | A weekday of a version. |
| `measurement_plan_time` | A reading time of a version. |
| `measurement_reading` | One reading, or one reading time skipped. A reading can also be taken outside a plan. |

A reading is judged by fixed normal ranges (`app/measurements/ranges.py`).
No table keeps a target.

### Appointments (`app/models/appointment.py`)

| Table | One row is |
|---|---|
| `appointment` | A visit, with its kind, day, time and place, and its status: `scheduled`, `completed` or `cancelled`. |
| `appointment_companion` | A member who goes with the patient to a visit. |
| `appointment_visit` | The visit paper of an attended visit: its summary, recommendations, follow-up and voice note. |

### Reminders (`app/models/notification.py`)

| Table | One row is |
|---|---|
| `notification_log` | A push that the scheduled scan sent, so that it never goes twice. |
| `task_snooze` | A task put off with «ذكّرني لاحقًا», and when to remind again. |

## Rules the database keeps

The checks keep each row valid: formats, lists of codes, lengths and
ranges. Triggers keep the rules that span tables: for example, a circle
always has a manager, a detailed patient manages their own circle, and the
versions of a medicine follow each other without a gap. These rules hold
even when the server has a bug.

## How long rows are kept

The scheduled scan (`purge_old_rows` in `app/push/scheduled.py`) deletes,
for good, the rows that nothing reads any more:

| Rows | Deleted after |
|---|---|
| Sign-in code requests, with their sends | 30 days |
| Notification claims (`notification_log`) | 14 days |
| Sessions that were signed out | 30 days |
| Snoozes whose reminder time and day passed | 2 days |
| Invitations that were declined or cancelled | 30 days (the bell shows 30 days) |
| Requests that were declined, cancelled or superseded | 30 days |
| Dose records and extra doses | 3 months |

An accepted invitation and a completed request stay: they record who joined
a circle and that the patient agreed. Everything else stays until its
circle or its account is deleted.

## Migrations

The tables are made and changed only by migrations (`migrations/versions`).

| Revision | What it does |
|---|---|
| `0070` | The whole database in one step (`0070_schema.sql`). It replaces the first 70 migrations, so a database made before it is already at 0070. |
| `0071` | Removes what nothing read: the old `measurement_target` table, the four old target columns of plan versions and readings, and `task_snooze.snoozed_at`. |
| `0072` | Removes `care_circle.latitude` and `longitude`: the weather follows the account's own city, whose centre the server reads from the city list (`app.cities`). |

A new change is a new migration that comes after the last one. Never edit a
migration that already ran on the server.

A local database made before revision 0070 existed, at an older revision,
cannot be upgraded. Delete it and make it again:
`docker compose down -v`, then `docker compose up`.
