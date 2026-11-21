# Stage 4: MVP Development and Execution

The TFAQUD v1.0 MVP runs against a shared Render beta. Signed iOS builds were uploaded to TestFlight. CI produced a signed Android AAB.

## 1. Team and Sprint Plan

| Member | Responsibilities |
|---|---|
| Alanoud Aloraydi | Team Lead and Project Manager. Coordinates sprints, Jira, and delivery. |
| Leen Algraawi | Source Control Manager. Coordinates branches, pull request reviews, and merges. |

Alanoud and Leen share development and quality assurance. Jira assignees coordinate follow-up.

| Sprint | Planned Dates | Planned Focus |
|---|---|---|
| 0 — Shared Foundation | October 15–17, 2026 | Flutter, Flask, PostgreSQL migrations, Docker, and CI |
| 1 — Identity | October 18–24, 2026 | OTP, onboarding, consent, medical profile, and Emergency Card |
| 2 — Care Plan | October 25–31, 2026 | Membership, medication, measurements, and appointments |
| 3 — Daily Care | November 1–7, 2026 | Today, task responses, Simplified Mode, and on-demand readings |
| 4 — Follow-up | November 8–14, 2026 | Reminders, Needs Attention, care history, PDF export, and visit sheets |
| 5 — Release | November 15–21, 2026 | Render beta deployment, CI evidence, and mobile tester distribution |

Dates are planned. [Jira](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-100) has the sprint reviews, retrospectives, and all six sprint views.

## 2. Implemented Scope

| Area | Delivered Behavior |
|---|---|
| OTP | Code requests also use IP and installation ID limits. [TFQD-13](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-13) |
| Medication and prayer times | Dose times are fixed. Today groups items by prayer period. [TFQD-42](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-42) |
| Circle navigation | Users switch between individual circles. Today, Plan, and Record show the selected circle. [TFQD-40](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-40) |
| Appointments | Companions are optional and must be eligible circle managers when selected. [TFQD-44](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-44) |
| Needs Attention | The app derives items from care status. Managers can follow up on out-of-target readings. [TFQD-49](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-49) |
| PDF and visit audio | Flutter generates the PDF with an optional dose execution log. PostgreSQL stores one replaceable visit voice note. [TFQD-53](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-53) · [TFQD-67](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-67) |

## 3. Testing and Deployment

| Check | Evidence |
|---|---|
| Back-end CI | 1,095 tests passed, including PostgreSQL integration tests. [Backend job](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions/runs/44923578109/job/136904650262) |
| Flutter CI | 1,277 tests passed on source revision `5a9e3cc`. [App job](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions/runs/44923578109/job/136904649911) |
| Render smoke | `GET /api/v1/health` and `GET /privacy` returned 200. Unauthenticated requests to `/api/v1/home` and `/api/v1/auth/session` returned 401. [API health](https://tfaqud-api.onrender.com/api/v1/health) |
| iOS beta | TestFlight version 1.0.0 builds [466743](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions/runs/44858331585/job/136707511657) and [466572](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions/runs/44841278881/job/136652467635) were uploaded. |
| Android build | CI produced a signed AAB. The Play Console version code and release status are unverified. [Build](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions/runs/44910763319/job/136867085449) |

### Manual Device Testing

Alanoud Aloraydi and Leen Algraawi tested TFAQUD v1.0.0 on their iPhones across several builds, with a final round on the latest v1.0.0 build. Build `466743` is the latest upload documented above.

| Area | Scenarios | Manual Result |
|---|---|---|
| Identity and permissions | Phone OTP, invitations, and access across care circles | Passed · [TFQD-54](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-54) |
| Daily care | Medication, measurements, appointments, and Simplified Mode | An onboarding issue was found during testing and corrected before v1.0.0 · [TFQD-55](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-55) |
| Notifications and records | Reminders, Needs Attention, visit audio, and PDF export | Passed · [TFQD-56](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-56) |
| End-to-end care | Leen managed the care circle in Detailed Mode. Alanoud used the same circle as the patient in Simplified Mode. They exercised care from setup through the patient's response and the manager's review. | Completed on two iPhones · [TFQD-59](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-59) |

**Defect corrected.** An earlier build derived the app mode from the first circle created or joined. Skipping circle setup could force Detailed Mode and prevent the user from joining a circle in Simplified Mode. The v1.0.0 onboarding fix lets the user select their mode and preserves the Simplified Mode invitation flow.

## 4. Sprint Reviews

| Sprint | Outcome | Evidence |
|---|---|---|
| 0 | Flutter, Flask, and PostgreSQL foundations. First app and API commits landed Oct 18. | [Foundation](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/commit/bd7ab50) |
| 1 | OTP and onboarding landed. Circle setup, profile, and Emergency Card followed Oct 26–27. | [Identity](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/commit/dc7f584) · [Medical profile](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/commit/9e1253b) |
| 2 | Medication landed Oct 27. Measurements and appointments followed Nov 3. | [Medication](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/commit/85f73d9) · [Measurements](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/commit/2541327) |
| 3 | Today, circle switching, task responses, and Simplified Mode were implemented. | [Today](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/commit/94c702d) · [Simplified Mode](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/commit/67a12db) |
| 4 | Care history, PDF, visit audio, and reminders were refined. | [Care follow-up](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/commit/a63d0a6) |
| 5 | Render beta is live. CI passed 1,095 back-end and 1,277 Flutter tests. TestFlight builds 466743 and 466572 were uploaded. | [CI](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions/runs/44923578109) · [TestFlight](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions/runs/44858331585/job/136707511657) |

## 5. Sprint Retrospectives

| Sprint | Improvement Identified |
|---|---|
| 0 | Tracking of planned dates and actual merges |
| 1 | Signed-build coverage for OTP and patient consent |
| 2 | Jira traceability for scheduling and companion rules |
| 3 | Cross-account regression coverage for circle isolation and Needs Attention |
| 4 | Device-level verification of PDF export, audio replacement, and push delivery |
| 5 | Test evidence organized by build and platform |

## 6. Submission Links

| Deliverable | Evidence |
|---|---|
| Sprint planning | [TFQD Jira board](https://holbertonstudents-team-f4bzu0ub.atlassian.net/jira/software/projects/TFQD/boards/3/backlog) |
| Sprint reviews | [Sprint Reviews](#4-sprint-reviews) · [Jira record](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-100) |
| Retrospectives | [Sprint Retrospectives](#5-sprint-retrospectives) · [Jira record](https://holbertonstudents-team-f4bzu0ub.atlassian.net/browse/TFQD-100) |
| Source repository | [TFAQUD-Portfolio](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio) |
| Bug tracking | [TFQD bug filter](https://holbertonstudents-team-f4bzu0ub.atlassian.net/issues/?jql=project%20%3D%20TFQD%20AND%20issuetype%20%3D%20Bug) |
| Testing evidence and results | [CI run](https://github.com/Alanoud-Aloraydi/TFAQUD-Portfolio/actions/runs/44923578109) and [manual device testing](#manual-device-testing) |
| Hosted MVP environment | [Render beta API](https://tfaqud-api.onrender.com/api/v1/health) |
