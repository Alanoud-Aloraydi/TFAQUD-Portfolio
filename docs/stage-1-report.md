# Stage 1 Report

## 1. Team Formation Overview

### 1.1 Initial Meeting & Team Members

The team held its first meeting remotely via WhatsApp on September 8, 2026, with all three members present. The meeting focused on introducing team members and discussing their backgrounds, skills, and interests.

| Team Member | Background, Skills & Interests |
|---|---|
| Alanoud Aloraydi | Information Technology and Cybersecurity; experience in full-stack and backend development, with an interest in application development. |
| Leen Algraawi | Artificial Intelligence; skills in Flask and databases, with an interest in backend development and learning Flutter. |
| Lama Alzahrani | Bioinformatics; skills in Python, Flask, REST APIs, and UI/UX fundamentals, with an interest in software development. |

### 1.2 Initial Roles

Initial roles were assigned through voting for a one-month period, with all members participating in project tasks.

| Role | Member | Proposed Responsibilities |
|---|---|---|
| Team Lead | Alanoud | Coordinate task assignments, lead technical discussions, and ensure work integration. |
| Project Manager | Lama | Organize meetings, track progress and deadlines, and identify obstacles. |
| Team Members | All Members | Participate in development, documentation, reviews, and decision-making. |

### 1.3 Team Norms & Collaboration

- **Communication:** WhatsApp for messaging and Discord for remote meetings.
- **Meetings:** In-person meetings every Tuesday for at least three hours, along with 15-minute stand-up meetings to track progress.
- **Collaboration:** Use GitHub to share project files and distribute tasks fairly based on skills and required effort.
- **Decision-Making:** Make decisions by consensus and discuss different perspectives to reach mutual agreement.
- **Commitment:** Notify the team in advance and provide a reason when unable to participate.

The team has not yet finalized its task management tool and is considering Trello and Jira.

## 2. Ideas Explored
 
Over a two-week period, the team explored six directions across different domains before settling on the final concept.
 
### 2.1 Medication Management App
A mobile app focused on managing medications for a single patient.
 
*Outcome:* Rather than being rejected, this idea was the starting point for the team's selected concept. It was expanded into **TFAQUD**, broadening the scope beyond medication tracking to include appointments, therapy sessions, health measurements, and multi-caregiver coordination (see Section 3).
 
### 2.2 Microbiome-Based Biofouling Prediction for Desalination Plants
An app to help desalination plants predict biofouling risk — going beyond simple risk prediction by using metagenomics data to identify the microbes and genetic traits associated with biofilm formation, then explaining why the risk had increased.
 
*Reason for Rejection:* On closer analysis, the underlying computation turned out to be too simple — the output could be derived with basic calculations, leaving little room for a substantial application to be built around it.
 
### 2.3 E-Commerce Store Ratings Platform
A platform aggregating online stores, with ratings submitted only by customers who had actually received the service. Accounts would require identity verification linked to Nafath (Saudi Arabia's national digital identity platform) to prevent fake reviews.
 
*Reason for Rejection:* Government-backed platforms already address this space (e.g., "Mawthoq" and similar trusted-registry apps), making the idea largely redundant.
 
### 2.4 School–Parent Communication Platform
A platform enabling communication between schools and parents, covering student check-out notifications and attendance/absence management.
 
*Reason for Rejection:* The team did not explore the idea in enough depth and had not clearly defined its scope or boundaries.
 
### 2.5 Repair Worker Booking App
Similar to on-demand hourly home-cleaning apps, but for home repair workers (electricians, plumbers, etc.), with advance booking and the ability to select a specific, previously-used worker.
 
*Reason for Rejection:* An existing app was found to match the idea very closely, so it was automatically excluded.
 
### 2.6 Event Planning Aggregator
An app combining all the components needed for planning an event — available halls, catering, photography, decor/booths, and similar services — in one place.
 
*Reason for Rejection:* A previous team had already pursued the exact same idea, making it a duplicate concept.
 
### 2.7 Evaluation Summary
 
**Evaluation Criteria**
 
| Criterion | What it measures |
|---|---|
| Feasibility | Can the team realistically build this with the skills, time, and tools available (including tech that needs to be learned, like Flutter)? |
| Potential Impact | How significant and well-evidenced is the problem, and how meaningfully does the idea solve it? |
| Technical Alignment | How well does the required tech stack match the team's existing skills (backend, REST APIs, databases, Flask) vs. what needs to be learned from scratch? |
| Scalability | Room to grow beyond the MVP — additional features, broader user base, future integrations. |
 
Each idea is scored 1 (weak) to 5 (strong) per criterion.
 
**Scoring Matrix**
 
| Idea | Feasibility | Potential Impact | Technical Alignment | Scalability | Total /20 | Rank |
|---|---|---|---|---|---|---|
| TFAQUD (Medication/Care Management) | 5 | 5 | 4 | 4 | 18 | 1 |
| Event Planning Aggregator | 3 | 3 | 3 | 2 | 11 | 2 (tie) |
| School–Parent Communication | 3 | 3 | 3 | 2 | 11 | 2 (tie) |
| Repair Worker Booking | 4 | 2 | 3 | 2 | 11 | 2 (tie) |
| E-Commerce Store Ratings | 3 | 2 | 3 | 2 | 10 | 5 |
| Microbiome / Biofouling Prediction | 2 | 3 | 2 | 2 | 9 | 6 |
 
**Risks & Constraints per Idea**
 
| Idea | Key Risks / Constraints |
|---|---|
| TFAQUD | Learning curve for Flutter and mobile deployment; designing a clear multi-caregiver permission system without confusing users; handling sensitive health data responsibly; device-integration APIs uncertain (kept out of MVP scope). |
| Microbiome / Biofouling Prediction | Requires specialized domain knowledge (metagenomics) the team doesn't currently have; access to real desalination-plant data is uncertain; core computation too simple to sustain a full MVP. |
| E-Commerce Store Ratings | Depends on Nafath integration, which may involve approval/access hurdles; direct overlap with existing government-backed trust platforms weakens differentiation. |
| School–Parent Communication | Scope was never clearly bounded; would likely require partnerships with actual schools to pilot, which is outside the team's control. |
| Repair Worker Booking | A closely matching app already exists in the market, making differentiation very difficult; discovered late in exploration. |
| Event Planning Aggregator | A previous cohort/team pursued an identical concept — duplication risk for academic originality; also a crowded market of existing event-planning apps. |
 
TFAQUD comes out clearly on top across all four criteria, which lines up with why it was selected — an evidence-backed problem, a feasible scope, and a stack the team already partially knows.
## 3. Selected MVP Concept

### 3.1 Selected Idea

**Project Name: TFAQUD | تفقُّد**

The team selected TFAQUD, a mobile application designed to organize healthcare for a single patient, whether the patient manages their own care or a primary caregiver is responsible for it.

The application brings medication management, medical appointments, therapy sessions, and health measurements together in one place. It also provides reminders, care activity documentation, and the ability for multiple caregivers to share responsibilities.

### 3.2 Reasons for Selection

The team selected TFAQUD for the following reasons:

- **Technical Feasibility:** The idea aligns with the team's existing skills in backend development, REST APIs, and databases, while providing an opportunity to learn Flutter for mobile development.
- **Value Proposition:** The application combines multiple aspects of healthcare management in one place and supports coordination among caregivers.
- **Alignment with Team Goals:** The project allows the team to apply software development skills and gain experience in mobile development and system integration.

### 3.3 Problem Statement

Patients who require continuous healthcare and their caregivers face challenges in organizing medications, appointments, health measurements, and caregiving responsibilities.

These challenges become more complex when multiple caregivers are involved in managing a patient's care.

TFAQUD aims to address these challenges by providing a centralized platform for organizing and tracking healthcare information and coordinating caregiving responsibilities.

### 3.4 Target Audience

The primary target audience is caregiving groups consisting of two or more caregivers who share responsibility for a single patient requiring regular medication, medical appointments, and health measurements.

The application also supports independent patients who can manage their own care.

### 3.5 Key Features

The MVP will include the following core features:

1. **Application Modes:** Detailed Mode for healthcare management and Light Mode for patients who need assistance with follow-up.
2. **Medication Management:** Record medications, dosages, instructions, and medication history, with reminders and dose tracking.
3. **Appointment Management:** Organize medical appointments and therapy sessions, with scheduled reminders.
4. **Health Measurements:** Schedule measurements, manually record results, and display measurement history and charts.
5. **Care Coordination:** Invite caregivers, manage permissions, assign responsibilities, and document care activities.
6. **Statistics and Reports:** Display information to help users monitor medication management and health measurements.

Integration with medical devices is excluded from the initial MVP scope.

### 3.6 Expected Outcomes

The project aims to:

- Provide a centralized place for managing a single patient's healthcare information.
- Simplify the organization and tracking of medications, appointments, and health measurements.
- Support responsibility coordination and information sharing among caregivers.
- Help patients and caregivers track care activities through reminders and documentation.
- Maintain organized records of care activities and health measurements for future reference.

### 3.7 Challenges and Opportunities

**Challenges:**

- Learning Flutter for mobile application development.
- Implementing API integration.
- Working with Docker and deploying the application.

**Opportunities:**

- Future integration with medical devices to automatically import health measurements, subject to API availability and user consent.
