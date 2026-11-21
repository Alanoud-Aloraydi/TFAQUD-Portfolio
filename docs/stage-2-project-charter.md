# Stage 2: Project Charter

## 1. Purpose

TFAQUD is an Arabic iOS and Android application for coordinating medications, appointments, and health measurements through patient care circles. It supports self-managed care and shared care by family caregivers.

## 2. SMART Objectives

The MVP delivery target was November 21, 2026.

| Objective | Acceptance Evidence |
|---|---|
| Manage scheduled care in one application | Create and record a medication, appointment, and BP or glucose task in an authorized circle. |
| Support follow-up of due and missed care | Verify reminder recipients, device permission behavior, and representative follow-up scenarios. |
| Protect patient records across circles | Verify authorized actions and refusal of unauthorized actions for circle managers and patients. |

## 3. Stakeholders and Responsibilities

| Stakeholder | Responsibility |
|---|---|
| Alanoud Aloraydi | Team Lead and Project Manager |
| Leen Algraawi | Source Control Manager |
| Holberton monitors | Academic review and feedback |
| Patients and caregivers | Beta feedback on daily care, coordination, and usability |

Both team members share development and QA.

## 4. Scope

The MVP covers phone authentication, care circles and consent, manager permissions, medication schedules and history, BP and glucose readings, appointments, reminders, follow-up, a read-only Emergency Card, visit notes with optional audio, and Care Record PDF export. Detailed Mode supports care management. Simplified Mode supports patient follow-up.

Deferred scope includes OCR, medication inventory, timed task handover, configurable escalation, medical-device import, electronic health record integration, and web and desktop applications.

## 5. Risks

| Risk | Mitigation |
|---|---|
| Unauthorized access to patient data | Enforce server-side circle permissions and test access across accounts. |
| Incorrect or conflicting care records | Validate inputs, preserve historical data, and test updates to existing plans. |
| Incorrect measurement display | Validate units, timestamps, and target ranges against known values. |
| Duplicate or conflicting updates | Enforce server-side constraints and test concurrent updates. |
| Delayed or missed reminders | Test device permissions, recipients, and follow-up while keeping schedules visible in the app. |
| Loss of care records | Verify database backup and recovery before public release. |
| Difficulty using Simplified Mode | Test the main patient workflows on a supported mobile device. |

## 6. Plan

| Stage | Planned Dates | Output |
|---|---|---|
| Team Formation and Idea Development | September 13–19, 2026 | Team formation and idea selection |
| Project Charter | September 20–26, 2026 | Objectives, scope, roles, and risks |
| Technical Documentation | September 27–October 10, 2026 | Architecture, design, API, and QA plan |
| MVP Development and Execution | October 11–November 21, 2026 | Integrated MVP and beta distribution |
| Project Closure | November 22–December 5, 2026 | Delivery follow-up and final project closure |

MVP dependencies run from authentication and circle permissions to care plans, daily tasks, reminders, records, and final integration testing.

[Jira sprint plan](https://holbertonstudents-team-f4bzu0ub.atlassian.net/jira/software/projects/TFQD/boards/3/backlog) · [Stage 4 delivery status](stage-4-mvp-development-and-execution.md)
