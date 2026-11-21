# TFAQUD | تفقُّد

TFAQUD is an Arabic mobile application for coordinating care within a shared care circle. Each circle serves one patient. Caregivers and self-managing patients use Detailed Mode. Patients who need help with follow-up use Simplified Mode.

Developed as a Holberton School Graduation Portfolio Project.

## MVP Features

- **Care Circles:** Phone sign-in, patient consent, caregiver invitations, membership permissions, and circle switching.
- **Care Plans:** Medication schedules and dose history, blood pressure and glucose plans, and appointments with optional companions.
- **Daily Care:** Task responses, on-demand readings, reminders, and follow-up through Needs Attention.
- **Medical Information:** Patient profile, read-only Emergency Card, Care Record PDF, and visit sheets with a voice note.

## Technology and Delivery

| Area | Implementation |
|---|---|
| Mobile | Flutter and Dart for iOS and Android |
| Back End | Flask REST API, SQLAlchemy, PostgreSQL, and Alembic |
| Services | Authentica for SMS, Aladhan for prayer times, and OneSignal for remote push through FCM on Android and APNs on iOS |
| Development | Docker Compose, Git, GitHub Actions, and Jira |
| Beta | Flask and PostgreSQL on Render. iOS tester builds are uploaded to TestFlight. The Android AAB is available from CI. |

[API health](https://tfaqud-api.onrender.com/api/v1/health) · [Privacy policy](https://tfaqud-api.onrender.com/privacy)

## Development

| Path | Contents |
|---|---|
| `app/` | Flutter application, widget tests, and device smoke tests |
| `backend/` | Flask API, PostgreSQL migrations, unit tests, and integration tests |
| `docs/` | Holberton portfolio documents |

See the [mobile setup](app/README.md) and [back-end setup](backend/README.md). Integrate work on `development` and merge to `main` through a pull request. The App and Backend checks are required on `main`. [GitHub Actions](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions)

## Documentation

- [Stage 1 — Team Formation and Idea Development](docs/stage-1-report.md)
- [Stage 2 — Project Charter](docs/project-charter.md)
- [Stage 3 — Technical Documentation](docs/stage-3-technical-documentation.md)
- [Stage 4 — MVP Development and Execution](docs/stage-4-mvp-development-and-execution.md)
- [Figma mockups](https://www.figma.com/design/Ojd0XVQSuC39YoJoiRyhou/Tafaqud-Care-OS?node-id=0-1)

## Current Team

| Member | Role |
|---|---|
| Alanoud Aloraydi | Team Lead and Project Manager |
| Leen Algraawi | Source Control Manager |

Both team members share development and QA.
