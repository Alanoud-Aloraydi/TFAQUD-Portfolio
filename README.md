# TFAQUD | تفقُّد

A mobile application for iOS and Android that helps patients and caregivers organize care through shared care circles. Each circle supports one patient, while a user can participate in multiple circles to manage care for more than one patient.

Developed as a Holberton School Graduation Portfolio Project.

## Overview

Ongoing care requires the organization of medications, medical appointments, therapy sessions, and health measurements. Coordination becomes more demanding when one caregiver supports several patients or multiple caregivers share responsibility for one patient.

TFAQUD brings these activities into a care plan for each patient, with daily tasks, defined responsibilities, reminders, and follow-up of missed tasks. The application supports Arabic and provides **Detailed Mode** for care management and **Simplified Mode** for patients who need assistance with daily follow-up.

## Target Users

TFAQUD primarily serves:

- **Caregivers supporting multiple patients:** Organize each patient's care within a separate circle and access their care circles through one account.
- **Groups sharing responsibility for one patient:** Coordinate responsibilities, share care information, and track task completion.

The application also supports self-managing patients, patients who need a simplified interface, and viewers who follow care without modifying information.

Within each circle, care managers organize the care plan and membership, care assistants carry out tasks, and viewers access information according to their permissions.

## Planned MVP Features

- **Care Circles:** Create a circle for each patient, participate in multiple circles, invite members, assign roles, and coordinate responsibilities.
- **Medication Management:** Organize doses and schedules, track supplies, and retain medication history, with photo-assisted information entry using OCR.
- **Appointments and Measurements:** Schedule medical visits, therapy sessions, and blood glucose and blood pressure measurements.
- **Reminders and Follow-Up:** Notify the responsible person and escalate missed tasks according to a configured recipient order.
- **Care Record:** Review recorded care information and export it as a PDF for future reference or doctor visits.
- **Medical Profile and Emergency Card:** Maintain essential patient information and emergency contacts.

## Planned Technologies and Services

- **Core Technologies:** Flutter, Python, Flask REST API, and PostgreSQL.
- **Supporting Services:** Local OCR, Firebase Cloud Messaging, an SMS gateway, and the Aladhan prayer-times API.
- **Development and Deployment Tools:** Git, GitHub, Docker, and GitHub Actions.

## Documentation

- [Stage 1 — Team Formation and Idea Development](docs/stage-1-report.md)
- [Stage 2 — Project Charter](docs/project-charter.md)
- [Stage 3 — Technical Documentation](docs/stage-3-technical-documentation.md)
- [Application Mockups — Figma](https://www.figma.com/design/Ojd0XVQSuC39YoJoiRyhou/Tafaqud-Care-OS?node-id=0-1)

## Planned Delivery

The Minimum Viable Product (MVP) is scheduled for delivery on **November 21, 2026**.

## Team

| Member | Role |
| --- | --- |
| Alanoud Aloraydi | Team Lead and Developer |
| Lama Alzahrani | Project Manager and Developer |
| Leen Algraawi | Backend QA Engineer and Developer |

All team members contribute to development, documentation, reviews, and project decisions.
