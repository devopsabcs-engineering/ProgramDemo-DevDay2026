<!-- markdownlint-disable-file -->
# Task Research: Demo Rehearsal, App Build & Talk Track

Build the actual **CIVIC** (Citizens' Ideas for a Vibrant and Inclusive Community) application now that infrastructure is deployed. Create a minute-by-minute talk track for the 120-minute Developer Day 2026 demo with a cliffhanger at the 70-minute lunch break. Presenters: **Hammad Aslam** (MC, sets stage, engages audience) and **Emmanuel** (on keyboard, live coding demo).

## Task Implementation Requests

* Build the full application (database migrations, Java backend, React frontend) by following ADO user stories
* Create a detailed minute-by-minute talk track for the 120-minute demo
* Design a narrative cliffhanger at the 70-minute mark (lunch break)
* Sequence the build order to maximize demo impact and audience engagement

## Scope and Success Criteria

* Scope: Complete application build plan, talk track script, tagged commit strategy, and implementation sequencing. Excludes Azure Durable Functions orchestration code, Logic Apps connector wiring, and AI Foundry integration (those are stretch goals or post-demo).
* Assumptions:
  * Azure resources are deployed and verified (App Service Plan, 2 App Services, SQL Server/DB, Storage Account, Function App, Logic App)
  * ADO Epic 1797 with 8 Features and 35 User Stories exists, all in "New" state
  * Tags v0.0.1 through v0.2.1 exist; next will be v0.3.0
  * Tag v0.2.1 is the demo rehearsal starting point (talk track, infra deployed, zero app code)
  * The demo audience is Ontario Public Sector IT leadership and developers
  * Lunch break happens at the 70-minute mark
* Success Criteria:
  * Minute-by-minute talk track covering all 120 minutes
  * A compelling cliffhanger at minute 70 that makes the audience eager to return
  * Ordered implementation plan mapping each build step to ADO user stories
  * Tagged commit checkpoints for fast-forward recovery

## Outline

1. Current State Assessment
2. Implementation Build Order
3. Minute-by-Minute Talk Track (Part 1: Pre-Lunch, 70 min)
4. The Cliffhanger
5. Minute-by-Minute Talk Track (Part 2: Post-Lunch, 50 min)
6. Tagged Commit Checkpoints
7. ADO User Story Sequencing
8. Risk Mitigation

## Research Executed

### Current Repository State

Application code status:

| Component | Status | Location |
|-----------|--------|----------|
| Infrastructure (Bicep) | **COMPLETE** | `infra/` — 6 modules, deployed to Azure |
| CI/CD Workflows | **COMPLETE** | `.github/workflows/ci.yml`, `deploy-infra.yml` |
| Documentation | **COMPLETE** | `docs/architecture.md`, `data-dictionary.md`, `design-document.md` |
| Copilot Instructions | **COMPLETE** | 5 instruction files + `copilot-instructions.md` |
| Database Migrations | **NOT STARTED** | `database/migrations/.gitkeep` only |
| Backend (Java/Spring Boot) | **NOT STARTED** | `backend/.gitkeep` only |
| Frontend (React/TypeScript) | **NOT STARTED** | `frontend/.gitkeep` only |
| Unit Tests | **NOT STARTED** | No test files exist |

### ADO Work Item Hierarchy

Epic 1797 "CIVIC — Citizens' Ideas for a Vibrant and Inclusive Community" [Agentic AI]

| Feature ID | Feature Title | User Stories | Story IDs |
|------------|--------------|--------------|-----------|
| 1801 | Infrastructure Setup | 5 | 1806, 1807, 1808, 1809, 1811 |
| 1798 | Database Layer | 4 | 1810, 1812, 1813, 1814 |
| 1803 | Backend API | 5 | 1815, 1816, 1817, 1819, 1820 |
| 1805 | Citizen Portal | 6 | 1818, 1821, 1822, 1823, 1824, 1825 |
| 1799 | Ministry Portal | 3 | 1826, 1827, 1829 |
| 1802 | Quality Assurance | 5 | 1828, 1830, 1831, 1832, 1833 |
| 1804 | CI/CD Pipeline | 5 | 1834, 1835, 1836, 1837, 1839 |
| 1800 | Live Change Demo | 2 | 1838, 1840 |

### Database Schema (from data-dictionary.md)

3 tables: `program` (11 columns), `program_type` (3 columns, 5 seed rows), `notification` (9 columns). 6 indexes. Flyway-style versioned migrations.

### API Design (from design-document.md)

| Method | Path | Purpose |
|--------|------|---------|
| POST | /api/programs | Submit a new program request |
| GET | /api/programs | List programs (supports ?search= query) |
| GET | /api/programs/{id} | Get program details |
| PUT | /api/programs/{id}/review | Approve or reject a program |

RFC 7807 ProblemDetail error format. Spring Data JPA. @Valid annotations. ResponseEntity with proper HTTP status codes.

### Frontend Design (from design-document.md)

React + TypeScript + Vite. Ontario Design System component library (`@ongov/ontario-design-system-component-library`) for React components. i18next for EN/FR. react-router for navigation. WCAG 2.2 Level AA. Functional components with hooks.

**Design-First Workflow:** Figma wireframes → Copilot generates React code → Ontario Design System components applied automatically.

**Ontario Design System Developer Docs:** https://designsystem.ontario.ca/docs/documentation/develop/for-developers.html

## Key Discoveries

### Narrative Arc: The Cliffhanger Strategy

The most compelling cliffhanger at 70 minutes is: **the citizen can submit a CIVIC form, the data reaches the database, but nobody can review it yet.** The audience sees a working submission but the Ministry review side is empty. They return from lunch wanting to see the Ministry portal come alive, the review happen, and finally the live field-addition that proves end-to-end agility.

This maps perfectly to the natural build order:
- Minutes 0-70 (Part 1): Database + Backend API + Citizen Portal → citizen submits, data persists, **but no ministry review exists**
- Minutes 70-120 (Part 2): Ministry Portal + QA + DevOps + Live Change → the story completes

### Build Order Rationale

The build order follows data flow direction (database → API → UI) which:
1. Creates visible, testable progress at every step
2. Enables running API tests with curl/Postman before the frontend exists
3. Allows the frontend to call a real API immediately when built
4. Places the cliffhanger at the natural "half-built" inflection point

## Implementation Build Order

### Phase 1: Database (v0.3.0) — Stories: 1812, 1813, 1814, 1810

| Step | File | Description | Story |
|------|------|-------------|-------|
| 1 | `database/migrations/V001__create_program_type_table.sql` | Create program_type lookup table | AB#1813 |
| 2 | `database/migrations/V002__create_program_table.sql` | Create program table with FK | AB#1812 |
| 3 | `database/migrations/V003__create_notification_table.sql` | Create notification table with FK | AB#1810 |
| 4 | `database/migrations/V004__seed_program_types.sql` | Seed 5 program types (EN/FR) | AB#1814 |

### Phase 2: Backend Scaffolding (v0.4.0) — Story: 1815

| Step | File | Description |
|------|------|-------------|
| 1 | `backend/pom.xml` | Spring Boot 3.x, Java 21, dependencies |
| 2 | `backend/src/main/java/.../ProgramDemoApplication.java` | Main entry point |
| 3 | `backend/src/main/resources/application.yml` | Database config, Flyway, server config |
| 4 | `backend/src/main/java/.../model/Program.java` | JPA entity |
| 5 | `backend/src/main/java/.../model/ProgramType.java` | JPA entity |
| 6 | `backend/src/main/java/.../model/ProgramStatus.java` | Enum |
| 7 | `backend/src/main/java/.../dto/ProgramRequest.java` | Request DTO |
| 8 | `backend/src/main/java/.../dto/ProgramResponse.java` | Response DTO |
| 9 | `backend/src/main/java/.../repository/ProgramRepository.java` | Spring Data JPA repo |
| 10 | `backend/src/main/java/.../repository/ProgramTypeRepository.java` | Spring Data JPA repo |
| 11 | `backend/src/main/java/.../config/CorsConfig.java` | CORS configuration |
| 12 | `backend/src/main/java/.../exception/GlobalExceptionHandler.java` | @ControllerAdvice |

### Phase 3: Backend API Endpoints (v0.5.0) — Stories: 1817, 1816, 1819, 1820

| Step | File | Description | Story |
|------|------|-------------|-------|
| 1 | `backend/.../service/ProgramService.java` | Business logic layer | — |
| 2 | `backend/.../controller/ProgramController.java` (POST) | Submit endpoint | AB#1817 |
| 3 | `backend/.../controller/ProgramController.java` (GET list) | List/search endpoint | AB#1816 |
| 4 | `backend/.../controller/ProgramController.java` (GET {id}) | Detail endpoint | AB#1819 |
| 5 | `backend/.../dto/ReviewRequest.java` | Review DTO | AB#1820 |
| 6 | `backend/.../controller/ProgramController.java` (PUT review) | Review endpoint | AB#1820 |

### Phase 4: Figma Design + Frontend Scaffolding + Citizen Portal (v0.6.0) — Stories: 1818, 1821, 1824, 1822, 1823, 1825

**Design-First Approach:** Create Figma wireframes, then generate React code using Ontario Design System components.

**Ontario Design System Reference:** https://designsystem.ontario.ca/docs/documentation/develop/for-developers.html

| Step | Tool/File | Description | Story |
|------|-----------|-------------|-------|
| 1 | **Figma** | Create wireframe: Program Submission Form (header, form fields, footer) | — |
| 2 | **Figma** | Create wireframe: Confirmation Page (success message, summary) | — |
| 3 | **Figma** | Create wireframe: Search/List Page (search input, results table, status badges) | — |
| 4 | **Ontario DS Docs** | Reference component library installation and available React components | — |
| 5 | `frontend/package.json` + Vite config | React project setup with `@ongov/ontario-design-system-component-library` | AB#1818 |
| 6 | **Copilot + Figma** | Generate `SubmitProgram.tsx` from Figma wireframe using Ontario DS components | AB#1822 |
| 7 | `frontend/public/locales/en/translation.json` | English translations | AB#1824 |
| 8 | `frontend/public/locales/fr/translation.json` | French translations | AB#1824 |
| 9 | `frontend/src/i18n.ts` | i18next configuration | AB#1824 |
| 10 | `frontend/src/components/layout/Header.tsx` | Ontario header using `OntarioHeader` component | AB#1821 |
| 11 | `frontend/src/components/layout/Footer.tsx` | Ontario footer using `OntarioFooter` component | AB#1821 |
| 12 | `frontend/src/components/layout/Layout.tsx` | Page layout wrapper | AB#1821 |
| 13 | `frontend/src/components/common/LanguageToggle.tsx` | EN/FR toggle | AB#1824 |
| 14 | `frontend/src/pages/SubmitConfirmation.tsx` | Confirmation page (from Figma wireframe) | AB#1823 |
| 15 | `frontend/src/pages/SearchPrograms.tsx` | Search/list page (from Figma wireframe) | AB#1825 |
| 16 | `frontend/src/services/api.ts` | API service layer | — |
| 17 | `frontend/src/App.tsx` | Router setup | — |

### Phase 5: Ministry Portal (v0.7.0) — Stories: 1826, 1827, 1829

| Step | File | Description | Story |
|------|------|-------------|-------|
| 1 | `frontend/src/pages/ReviewDashboard.tsx` | Program review list | AB#1826 |
| 2 | `frontend/src/pages/ReviewDetail.tsx` | Program detail + review | AB#1827 |
| 3 | `frontend/src/components/review/ReviewForm.tsx` | Approve/reject form | AB#1829 |

### Phase 6: Quality Assurance (v0.8.0) — Stories: 1828, 1831, 1830, 1833

| Step | File | Description | Story |
|------|------|-------------|-------|
| 1 | `backend/src/test/.../ProgramControllerTest.java` | Controller tests | AB#1828 |
| 2 | `backend/src/test/.../ProgramServiceTest.java` | Service tests | AB#1828 |
| 3 | `frontend/src/__tests__/SubmitProgram.test.tsx` | Form component tests | AB#1831 |
| 4 | `frontend/src/__tests__/accessibility.test.tsx` | jest-axe tests | AB#1830 |

### Phase 7: Live Change (v1.1.0) — Stories: 1838, 1840

Add `program_budget` field end-to-end: migration → entity → DTO → API → form → tests.

---

## Talk Track: Minute-by-Minute Script

### PART 1: "Building From Zero" (Minutes 0–70 | ⏰ 10:30 AM – 11:40 AM)

> **Presenters:** 🎙️ **HAMMAD** — MC, sets context, asks questions, holds audience conversation | 💻 **EMMANUEL** — on keyboard, driving all live coding

---

#### Opening: "The Problem" (Minutes 0–5 | ⏰ 10:30 – 10:35 AM)

**[SLIDE: Ontario government logo + "Developer Day 2026" + CIVIC logo]**

**🎙️ HAMMAD:** > "Good morning everyone. My name is Hammad Aslam, and this is my colleague Emmanuel. Today we're going to do something that would normally take a team of developers several weeks. We're going to build a complete government application — from an empty repository to a working, bilingual, accessible web app — in two hours. Live. Using GitHub Copilot as our AI pair programmer."

**🎙️ HAMMAD:** > "The application we're building is called **CIVIC** — Citizens' Ideas for a Vibrant and Inclusive Community. It's a program submission and approval portal for Ontario citizens and ministry staff. Emmanuel is going to be on the keyboard the whole time. I'll be here setting the stage, asking questions, and making sure we don't lose anyone along the way."

**🎙️ HAMMAD (to EMMANUEL):** "Emmanuel, set the scene. What are we actually starting with here?"

**[EMMANUEL switches to VS Code with empty repo]**

**💻 EMMANUEL:** > "This is our starting point. We have documentation, infrastructure already deployed in Azure, and 35 user stories in Azure DevOps. But zero application code. No database schema. No API. No UI. Let's change that."

**Key beat (EMMANUEL):** Show the empty `backend/`, `frontend/`, `database/` directories with only `.gitkeep` files.

---

#### Act 1: "The Architect" — Planning & Context (Minutes 5–15 | ⏰ 10:35 – 10:45 AM)

**[EMMANUEL opens copilot-instructions.md in VS Code]**

**🎙️ HAMMAD:** > "Before Emmanuel writes a single line of code, I want to show you something that separates a good Copilot user from a great one. It's not the prompts — it's the context. Emmanuel, pull up the custom instructions we put together for this project."

**💻 EMMANUEL:** > "So we've given Copilot custom instructions that encode our coding standards, our tech stack, our accessibility requirements, and even our Ontario Design System conventions. Think of it as onboarding Copilot to your team before it writes a single line."

**Demo actions:**
- (min 5) Open `copilot-instructions.md` — walk through the key sections
- (min 7) Open `java.instructions.md` — show path-specific instructions concept
- (min 8) Open `react.instructions.md` — highlight WCAG 2.2 rules baked in
- (min 9) Open `docs/architecture.md` — show the Mermaid diagram
- (min 10) Open `docs/data-dictionary.md` — show ER diagram and tables
- (min 12) Switch to Azure DevOps — show Epic 1797 with 8 Features, 35 User Stories
- (min 13) Open ADO board — show the "Database Layer" feature, pick up Story 1813

**🎙️ HAMMAD:** > "Notice something important: Emmanuel and his team haven't told Copilot *what* to build yet, but they've taught it *how* to build. The custom instructions, the architecture docs, the data dictionary — that's developer judgement encoded as context. Copilot is powerful, but the developer is still the one setting the direction."

**🎙️ HAMMAD (to EMMANUEL):** "So Emmanuel — we have 35 user stories on the board. Where do we start?"

**💻 EMMANUEL:** > "We start at the foundation. The database."

**Key beat (EMMANUEL):** Pause on the ADO board. Show the "Database Layer" feature and pick up Story 1813.

> ---
> ### 🖥️ CLI SPOTLIGHT — Optional Aside (min 14 | ⏰ ~10:44 AM)
> **[Backup/awareness beat — use if time permits and audience energy is high. Skip if running tight.]**
>
> **🎙️ HAMMAD:** > "Before we dive into the database, I want to flag something for everyone in this room — especially those of you who spend more time in a terminal than in an IDE. GitHub Copilot CLI just went Generally Available last week. And this matters, because Copilot in the IDE is powerful, but it's constrained to whatever files you have open. The CLI is different — it's not limited by IDE context windows, it can work across your entire filesystem, and it lives natively in your terminal workflow. Emmanuel, want to show them what `gh copilot` looks like?"
>
> **💻 EMMANUEL:** > "Sure. We've got the `gh` CLI installed and authenticated. There are two core commands: `gh copilot suggest` — which generates shell commands from natural language — and `gh copilot explain` — which takes any command and tells you exactly what it does."
>
> **Demo (EMMANUEL in terminal):**
> ```bash
> # Ask Copilot to suggest a shell command
> gh copilot suggest "list all Java files in the backend that contain the word Entity"
>
> # Copilot suggests:
> find backend/src -name "*.java" | xargs grep -l "@Entity"
>
> # Then explain a command you didn't write
> gh copilot explain "find backend/src -name '*.java' | xargs grep -l '@Entity'"
> ```
>
> **🎙️ HAMMAD:** > "That explain feature is gold for onboarding. A new developer joins your team, they're looking at a complex shell pipeline from three years ago — they just ask Copilot to explain it. No tribal knowledge required."
>
> **🎙️ HAMMAD:** > "We'll come back to the CLI when we get to our DevOps act — that's where it really shines. For now, Emmanuel's going to keep building in the IDE."
> ---

---

#### Act 2: "The DBA" — Database Migrations (Minutes 15–28 | ⏰ 10:45 – 10:58 AM)

**[EMMANUEL pulls ADO Story 1813 from the board]**

**🎙️ HAMMAD:** > "Every great application starts with its data model. Emmanuel has picked up Story 1813 — creating the program type lookup table. Emmanuel, what does CIVIC actually need to store?"

**💻 EMMANUEL:** > "We need four migration files — program types, the main program table, notifications, and seed data. Let's see how Copilot handles SQL when it has our conventions loaded."

**Demo actions:**
- (min 15) Create branch `feature/1813-program-type-table`
- (min 16) Create `database/migrations/V001__create_program_type_table.sql`
- (min 17) Use Copilot Chat: "Create the program_type table per the data dictionary" — show it reads `data-dictionary.md` and `sql.instructions.md` automatically
- (min 18) Highlight: NVARCHAR for bilingual, IF NOT EXISTS guard, INT PK — all from instructions
- (min 19) **Live curl or sqlcmd:** Run the migration manually or show intent to run via Flyway
- (min 20) Create `V002__create_program_table.sql` (Story 1812) — show Copilot generates FK constraint, indexes, DATETIME2, all conventions
- (min 23) Create `V003__create_notification_table.sql` (Story 1810) — highlight the created_by audit column
- (min 25) Create `V004__seed_program_types.sql` (Story 1814) — show MERGE for idempotency
- (min 26) Commit: `feat(db): add schema migrations and seed data AB#1813 AB#1812 AB#1810 AB#1814`
- (min 27) **Tag v0.3.0** — "Database schema complete"

**Audience engagement point (min 28 | ⏰ 10:58 AM):**

**🎙️ HAMMAD:** > "Four SQL files. All bilingual. All with proper constraints. All following naming conventions."

**🎙️ HAMMAD (to audience):** > "Quick show of hands — how long would it typically take your team to hand-write and get these four migration scripts through code review? A day? More? Emmanuel just did it with Copilot in 12 minutes. And here's the key thing — Copilot didn't just write SQL. It wrote *your team's* SQL, because it had your standards loaded."

**🎙️ HAMMAD (to EMMANUEL):** "What's next? We have a database — but nothing talks to it yet."

---

#### Act 3: "The Backend Developer" — Spring Boot API (Minutes 28–50 | ⏰ 10:58 – 11:20 AM)

**[EMMANUEL pulls ADO Story 1815]**

**🎙️ HAMMAD:** > "Database is done. Now Emmanuel needs something that actually talks to it — and eventually to the user's browser. Emmanuel, what's the plan?"

**💻 EMMANUEL:** > "Java 21. Spring Boot 3. We need an API layer that sits between the database and whatever frontend we build. Let's go."

**Demo actions:**
- (min 28) Create branch `feature/1815-spring-boot-scaffolding`
- (min 29) Use Copilot Chat: "Generate a Spring Boot 3.x project structure for the backend with Java 21, Spring Data JPA, Flyway, Azure SQL, and validation"
- (min 30) Show generated `pom.xml` — highlight dependencies: spring-boot-starter-web, spring-boot-starter-data-jpa, flyway-core, mssql-jdbc, spring-boot-starter-validation
- (min 31) Create `ProgramDemoApplication.java` — Copilot generates @SpringBootApplication
- (min 32) Create `application.yml` — show Flyway auto-migration, datasource config
- (min 33) Create `Program.java` entity — Copilot reads data-dictionary.md, generates all JPA annotations
- (min 34) Create `ProgramType.java` entity
- (min 35) Create `ProgramStatus.java` enum (DRAFT, SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED)
- (min 36) Create DTOs: `ProgramRequest.java`, `ProgramResponse.java` — show @Valid, @NotNull, @Size from java.instructions.md
- (min 37) Create `ProgramRepository.java` and `ProgramTypeRepository.java`
- (min 38) Create `GlobalExceptionHandler.java` — ProblemDetail responses
- (min 39) Create `CorsConfig.java` — restrict to frontend origin
- (min 40) Commit scaffolding: `feat(api): add Spring Boot project scaffolding AB#1815`

**[Pull Story 1817: POST /api/programs]**

- (min 41) Create `ProgramService.java` — business logic
- (min 42) Create `ProgramController.java` with POST endpoint
- (min 43) **Live test:** `curl -X POST http://localhost:8080/api/programs -H "Content-Type: application/json" -d '{"programName":"Test","programDescription":"Test desc","programTypeId":1}'` — show 201 Created

  > ---
  > ### 🖥️ CLI SPOTLIGHT — Backup Option for API Testing (min 43)
  > **[Use this instead of typing the curl command manually — great audience moment if you want to show off suggest live.]**
  >
  > **🎙️ HAMMAD:** > "Emmanuel, you've got an API running. But do you actually remember the curl syntax for a JSON POST off the top of your head?"
  >
  > **💻 EMMANUEL:** > "I don't have to."
  >
  > **Demo (EMMANUEL in terminal):**
  > ```bash
  > gh copilot suggest "send a POST request to localhost:8080/api/programs with a JSON body containing programName, programDescription, and programTypeId"
  > ```
  > *Copilot generates the full curl command, including headers — Emmanuel runs it directly.*
  >
  > **🎙️ HAMMAD:** > "Notice what just happened. Emmanuel didn't Google 'curl POST JSON'. He didn't look at documentation. He described what he wanted in plain English, and Copilot CLI generated the exact command. That's the `gh copilot suggest` feature — and it works for any shell command, any tool, any platform."
  > ---
- (min 44) Add GET /api/programs (Story 1816) and GET /api/programs/{id} (Story 1819) — inline completions
- (min 46) Add PUT /api/programs/{id}/review (Story 1820) — show ReviewRequest DTO
- (min 48) **Live test:** Submit, list, get by ID, review — all working via curl
- (min 49) Commit: `feat(api): implement all CRUD endpoints AB#1817 AB#1816 AB#1819 AB#1820`
- (min 50) **Tag v0.5.0** — "Backend API complete"

**Audience engagement point (min 50 | ⏰ 11:20 AM):**

**💻 EMMANUEL:** > "We have a fully functional REST API. Four endpoints. Validation. Error handling. Database persistence. JPA entities mapped to our schema. All in 22 minutes."

**🎙️ HAMMAD:** > "Emmanuel, I noticed something — you didn't have to tell Copilot to use constructor injection, or ProblemDetail error responses, or ResponseEntity. It just... did it. Why is that?"

**💻 EMMANUEL:** > "Because of our path-specific instructions. Every time Copilot opened a Java file in this project, it already had our team's patterns loaded. That's the power of custom instructions — it's not just autocomplete, it's Copilot operating within your team's playbook."

---

#### Act 4: "The Frontend Developer" — Citizen Portal (Minutes 50–70 | ⏰ 11:20 – 11:40 AM)

**[EMMANUEL pulls Story 1818]**

**🎙️ HAMMAD:** > "Alright. We have a database. We have an API. Now comes the part that citizens of Ontario will actually see and interact with. Emmanuel, before you open VS Code — walk us through how we're going to approach building the CIVIC portal."

**💻 EMMANUEL:** > "We're not jumping straight into React code. We start with design — Figma wireframes — and then use Copilot to generate production-ready components directly from those designs using the official Ontario Design System."

**🎙️ HAMMAD:** > "Design first. I love it. Let's see it."

---

##### Step 1: Design in Figma (Minutes 50–55)

**[SWITCH TO: Figma in browser]**

> "A picture is worth a thousand lines of code. Let's sketch out what our citizen portal should look like."

**Demo actions:**
- (min 50) Open Figma — show a new file or pre-prepared Ontario Design System UI Kit
- (min 51) **Create Program Submission Form wireframe:**
  - Ontario header with official branding and language toggle
  - Form with fields: Program Name, Program Type (dropdown), Description (textarea), Contact Email
  - Submit button styled with Ontario button classes
  - Ontario footer
- (min 53) **Create Confirmation Page wireframe:**
  - Success message with checkmark icon
  - Summary of submitted program details
  - "Submit Another" and "View Programs" navigation links
- (min 54) **Create Search/List Page wireframe:**
  - Search input with Ontario styling
  - Results table with columns: Program Name, Type, Status, Submitted Date
  - Status badges (Draft, Submitted, Approved, Rejected)
- (min 55) **Export/Screenshot:** Save the Figma frames as reference images or copy the Figma share link

**Key beat:**

**🎙️ HAMMAD (to audience):** > "What Emmanuel just did is something fundamentally different from how most development shops work. We have a visual contract — the stakeholder can see exactly what CIVIC will look like before a single line of React exists. And critically, we can hand that design directly to Copilot. Emmanuel, show them how."

---

##### Step 2: Reference Ontario Design System Documentation (Minute 55)

**[SWITCH TO: Browser — Ontario Design System Developer Docs]**

**🎙️ HAMMAD:** > "Emmanuel, before you start generating code — tell us about the Ontario Design System. For people in the room who aren't familiar, why does it matter?"

**💻 EMMANUEL:** > "Before we generate code, we need to ground Copilot in the official Ontario Design System. This ensures our React components use the correct classes, patterns, and accessibility standards — not just any generic UI library. CIVIC needs to look and feel like an Ontario government application."

**Demo actions:**
- (min 55) Open https://designsystem.ontario.ca/docs/documentation/develop/for-developers.html
- Show key sections:
  - **Installation:** `npm install @ongov/ontario-design-system-component-library` for React components
  - **CSS-only approach:** `@ongov/ontario-design-system-global-styles` for styled HTML
  - **React components available:** Buttons, Forms, Headers, Footers, Inputs, Hints, Error messages
  - **WCAG 2.2 Level AA compliance** built into all components

> "The Ontario Design System gives us production-ready React components. We'll point Copilot to these docs so it generates code that matches the official patterns."

---

##### Step 3: Generate React from Figma + Ontario DS (Minutes 55–58)

**[SWITCH TO: VS Code]**

> "Now let's have Copilot turn our Figma designs into React code, using the Ontario Design System components."

**Demo actions:**
- (min 55) Create React + TypeScript + Vite project: `npm create vite@latest . -- --template react-ts`
- (min 56) Install Ontario Design System dependencies:
  ```bash
  npm install @ongov/ontario-design-system-component-library @ongov/ontario-design-system-global-styles react-router-dom i18next react-i18next axios
  ```
- (min 56) **Copilot Chat prompt (with Figma screenshot attached or described):**
  > "Based on this Figma wireframe for a government program submission form, generate a React component using the Ontario Design System component library from https://designsystem.ontario.ca/docs/documentation/develop/for-developers.html. Use OntarioHeader, OntarioFooter, OntarioButton, OntarioInput, OntarioTextarea, and OntarioDropdownList components. Ensure WCAG 2.2 Level AA compliance with proper aria-labels and error handling."
- (min 57) Show Copilot generating `SubmitProgram.tsx` with:
  - `import { OntarioButton, OntarioInput, OntarioTextarea } from '@ongov/ontario-design-system-component-library'`
  - Proper form structure matching the Figma wireframe
  - Ontario CSS classes applied automatically
  - Accessibility attributes (aria-describedby, aria-invalid, etc.)

**Key beat:**

**🎙️ HAMMAD:** > "Emmanuel, pause there. I want the room to see what just happened. Copilot didn't write generic React. It looked at the Figma wireframe, referenced the Ontario Design System documentation, and produced components that match Ontario government standards. Design-to-code in under 3 minutes. That's not magic — that's what good context engineering looks like."

---

##### Step 4: Build Supporting Components (Minutes 58–65)

**Demo actions:**
- (min 58) Create `i18n.ts` — Copilot generates full i18next config with language detection
- (min 58) Create `public/locales/en/translation.json` — show keys for all UI strings
- (min 59) Create `public/locales/fr/translation.json` — Copilot generates French translations
- (min 59) Create `Header.tsx` — uses `OntarioHeader` component from Ontario DS
- (min 60) Create `Footer.tsx` — uses `OntarioFooter` component from Ontario DS
- (min 60) Create `Layout.tsx` — wraps all pages in Ontario header/footer
- (min 61) Create `LanguageToggle.tsx` — EN/FR button that updates lang attribute (WCAG 3.1.1)

**[Pull Story 1822: Build program submission form]**

- (min 61) Refine `SubmitProgram.tsx` — the form generated from Figma, add validation
- (min 62) **KEY DEMO MOMENT:** Show Copilot enhancing the form with Ontario DS form validation patterns, aria-labels, error identification (WCAG 3.3.1), autocomplete attributes — all from react.instructions.md + Ontario DS docs
- (min 63) Create `api.ts` service — connects to backend
- (min 63) Create `SubmitConfirmation.tsx` (Story 1823) — based on Figma confirmation wireframe
- (min 64) Create `SearchPrograms.tsx` (Story 1825) — based on Figma list/search wireframe
- (min 65) Create `App.tsx` with react-router routes

---

##### Step 5: Live Demo & Validation (Minutes 65–70)

- (min 65) **LIVE DEMO:** Open browser → navigate to form → compare to Figma wireframe → they match!
- (min 66) Fill in program → submit → see confirmation page (matches Figma)
- (min 67) **LIVE DEMO (continued):** Switch language to French → show entire UI in French → submit another program
- (min 68) **LIVE DEMO (continued):** Check database — show both submissions persisted in Azure SQL
- (min 69) Commit: `feat(ui): add citizen portal with Ontario DS and bilingual support AB#1818 AB#1821 AB#1822 AB#1823 AB#1824 AB#1825`

**Audience engagement point (min 70 | ⏰ 11:38 AM):**

**🎙️ HAMMAD:** > "Emmanuel started with a Figma wireframe. He pointed Copilot at the Ontario Design System documentation. And in 20 minutes, CIVIC has a production-quality React frontend — official Ontario branding, bilingual support, WCAG 2.2 accessibility compliance. Design to deployed code, in one demo session."

---

### 🔥 THE CLIFFHANGER (Minute 70 | ⏰ 11:40 AM — LUNCH BREAK)

**[EMMANUEL has CIVIC citizen portal open in browser, showing the submissions list]**

**[HAMMAD walks to the front of the room]**

**🎙️ HAMMAD:** > "So here's where we stand. A citizen can visit the CIVIC portal, fill out a bilingual, accessible form, and submit a program request. The data flows through Emmanuel's REST API and into Azure SQL. We can search programs. We can view them in English or French."

**[EMMANUEL clicks on 'Ministry Review' nav link. A blank page appears on screen.]**

**🎙️ HAMMAD:** > "But there's a problem."

**[Dramatic pause. Let the blank page sit on screen for 3-4 seconds.]**

**🎙️ HAMMAD:** > "Nobody can approve anything."

**[Another pause.]**

**🎙️ HAMMAD:** > "The Ministry side of CIVIC... doesn't exist yet. We have program submissions piling up in that database with no way to review them. No way to approve. No way to reject. No way to notify the citizen of a decision."

**[EMMANUEL switches to ADO board — 3 user stories under 'Ministry Portal' all in 'New' state]**

**🎙️ HAMMAD:** > "Three stories sitting right here. Build the review dashboard. Build the detail page. Implement the approve/reject workflow. Plus unit tests, accessibility audits, CI/CD, and — if Emmanuel can sustain this pace — a live field addition from database to UI."

**[HAMMAD steps away from screen, looks at audience]**

**🎙️ HAMMAD:** > "We just built the citizen half of CIVIC in 70 minutes. From nothing — no code, no schema, no UI. Can Emmanuel and GitHub Copilot finish the other half in 50 minutes after lunch? Come back and find out."

> *"Enjoy your break. We'll see you back here at 1:00 PM sharp."*

**[EMMANUEL tags v0.6.0]** — "CIVIC citizen portal complete, ministry portal pending"

> ⏰ **LUNCH BREAK — 11:40 AM to 1:00 PM**

---

### PART 2: "Closing the Loop" (Minutes 70–120 | ⏰ RESUMING 1:00 PM)

> **Presenters:** 🎙️ **HAMMAD** — welcomes audience back, holds the narrative thread | 💻 **EMMANUEL** — resumes on keyboard

---

#### Recap (Minutes 70–72 | ⏰ 1:00 – 1:02 PM)

**[HAMMAD at the front. EMMANUEL at keyboard with VS Code and browser side-by-side]**

**🎙️ HAMMAD:** > "Welcome back everyone. I hope you enjoyed lunch — because we have work to do. Let me quickly recap where we left off."

**🎙️ HAMMAD (pointing to screen):** > "CIVIC has a citizen portal. Emmanuel built four REST API endpoints, a SQL database, bilingual support, and WCAG accessibility. But the Ministry review side — the dashboard, the approve/reject workflow — that blank page you saw before lunch? Still blank. Emmanuel, show them."

**Demo actions:**
- (min 71) **EMMANUEL** quickly shows the submitted CIVIC programs in the database — real data from the pre-lunch demo
- (min 72) **EMMANUEL** shows the 3 remaining Ministry Portal stories on the ADO board — all still in 'New'

---

#### Act 5: "Completing the Story" — Ministry Portal (Minutes 72–85 | ⏰ 1:02 – 1:15 PM)

**[EMMANUEL pulls Story 1826 from the board]**

**🎙️ HAMMAD:** > "Emmanuel, let's talk about who actually uses this side of CIVIC. Set the scene for people in the room."

**💻 EMMANUEL:** > "A ministry program officer needs to log in, see all the CIVIC submissions at a glance, click into one, and make a decision — approve or reject, with comments. Let's build that review dashboard."

**🎙️ HAMMAD:** > "Let's do it."

**Demo actions:**
- (min 72) Create `ReviewDashboard.tsx` — table/list of all programs with status badges
- (min 74) **Live:** Browse to Ministry Review — show list of submitted programs
- (min 75) Create `ReviewDetail.tsx` (Story 1827) — show program details with citizen info
- (min 78) Create `ReviewForm.tsx` (Story 1829) — approve/reject buttons, comment field
- (min 80) **Live:** Navigate to a submitted program → review it → approve it with a comment
- (min 81) **KEY MOMENT:** Show the CIVIC program status changed from SUBMITTED to APPROVED in the citizen's search view
- (min 82) **Live:** Reject a second program with comments → show status update
- (min 83) Commit: `feat(ui): add ministry review portal with approve/reject AB#1826 AB#1827 AB#1829`
- (min 84) **Tag v0.7.0** — "Ministry portal complete"

**Audience engagement point (min 85 | ⏰ 1:15 PM):**

**🎙️ HAMMAD:** > "Thirteen minutes. Emmanuel went from a blank Ministry page to a full review workflow."

**🎙️ HAMMAD (to EMMANUEL):** "Emmanuel — walk us through what just happened when you clicked Approve. End to end."

**💻 EMMANUEL:** > "The button hit our PUT endpoint, which called the service layer, updated the program status in Azure SQL to APPROVED, and the citizen's CIVIC search view now reflects that change — in real time."

**🎙️ HAMMAD:** > "The citizen submits. The ministry reviews. The status updates. CIVIC is a complete, working system — built from scratch — and we're only at minute 85."

---

#### Act 6: "The QA Engineer" — Testing (Minutes 85–98 | ⏰ 1:15 – 1:28 PM)

**[EMMANUEL pulls Story 1828]**

**🎙️ HAMMAD:** > "CIVIC works. But working isn't enough for a government application — it needs to be verified and maintainable. Emmanuel, what's the discipline here?"

**💻 EMMANUEL:** > "Code that works is great. Code that's tested is better. And the interesting thing is — Copilot can write the tests too. Let's see it."

**Demo actions:**
- (min 85) Create `ProgramControllerTest.java` — @WebMvcTest with Mockito
- (min 87) Show Copilot generating test cases for POST (valid, invalid), GET (list, by ID, not found), PUT (approve, reject)
- (min 89) **Run tests live:** `mvn test` — show all green
- (min 90) Create `SubmitProgram.test.tsx` (Story 1831) — React Testing Library
- (min 92) Create `accessibility.test.tsx` (Story 1830) — jest-axe testing
- (min 93) **Run tests live:** `npm test` — show all passing including a11y
- (min 94) Commit: `test: add backend and frontend unit tests AB#1828 AB#1831 AB#1830`
- (min 95) **Tag v0.8.0** — "Tests passing"

**Audience engagement point (min 95 | ⏰ 1:25 PM):**

**🎙️ HAMMAD:** > "I want to flag something important. Those accessibility tests Emmanuel just ran — they're not nice-to-have. For a government application, WCAG 2.2 Level AA is a legislative requirement. And Copilot, with the right instructions, bakes that verification into the development workflow automatically."

**🎙️ HAMMAD (to audience):** > "Think about what that means for your teams — every developer, not just your accessibility specialist, shipping accessible, compliant code by default. That's what changes the game."

**[Pull Story 1833: Verify bilingual content completeness]**

- (min 96) Quick check: compare en/fr translation files for completeness
- (min 97) Show any missing keys, Copilot suggests the French translations
- (min 98) Commit: `fix(i18n): complete bilingual content verification AB#1833`

---

#### Act 7: "The DevOps Engineer" — CI/CD Polish (Minutes 98–103 | ⏰ 1:28 – 1:33 PM)

**🎙️ HAMMAD:** > "CIVIC works. It's tested. It's accessible. But here's a question for the DevOps folks in the room — does it *stay* that way? Every commit, every pull request, every change from here on out? Emmanuel, show us the safety net."

**💻 EMMANUEL:** > "Let's make sure all of this is protected by our CI/CD pipeline."

**Demo actions:**
- (min 98) Show existing `ci.yml` — highlight that backend-ci and frontend-ci jobs now have actual code to build
- (min 99) Push to trigger CI — show it building Maven + npm in parallel
- (min 100) Quick show of Dependabot config (Story 1837) and secret scanning (Story 1839)
- (min 101) Mention the deploy-infra.yml we already have for infrastructure
- (min 102) Commit any CI tweaks: `ci: verify pipeline runs with application code AB#1835 AB#1834`
- (min 103) **Tag v0.9.0** — "CI verified"

> ---
> ### 🖥️ CLI SPOTLIGHT — Primary DevOps Showcase (min 99–102 | ⏰ ~1:29 – 1:32 PM)
> **[This is the PRIMARY CLI showcase moment. Highly recommended — replaces or supplements the standard DevOps beat. Budget ~3 minutes. The Fleet feature is the headline here.]**
>
> **🎙️ HAMMAD:** > "This is the moment I've been waiting to show you. Everything we've built today has been in the IDE. But this is where the CLI really changes the game. Emmanuel, drop out of VS Code for a second and go pure terminal."
>
> **[EMMANUEL opens a terminal. No IDE.]**
>
> **💻 EMMANUEL:** > "Copilot CLI isn't constrained by what I have open in VS Code. It has access to the whole filesystem. Watch this."
>
> **Demo actions (EMMANUEL in terminal):**
>
> **Step 1 — Explain the CI pipeline without reading it:**
> ```bash
> gh copilot explain "cat .github/workflows/ci-cd.yml"
> ```
> *Copilot reads the YAML and produces a plain-English summary of every job, trigger, and step.*
>
> **🎙️ HAMMAD:** > "A new developer joins your team tomorrow. They open the CI pipeline and have no idea what it does. Instead of spending an hour deciphering YAML, they run one command and get a complete explanation. That's what `gh copilot explain` does."
>
> **Step 2 — Fleet: codebase-wide analysis from the terminal:**
> ```bash
> gh copilot suggest "search all Java files in backend/src for any method that calls the database without a @Transactional annotation"
> ```
> *Copilot generates a `grep` or `find` pipeline that searches across the entire codebase.*
>
> **🎙️ HAMMAD:** > "This is Fleet thinking. The IDE shows you what's in the open file. The CLI can reason across your entire repo — all your Java files, all your configs, all at once. No tabs, no file switching. It's Copilot operating at the filesystem level."
>
> **Step 3 — Suggest git workflow commands naturally:**
> ```bash
> gh copilot suggest "create a signed commit for all staged changes and push to origin with a conventional commit message for a CI verification fix"
> ```
>
> **🎙️ HAMMAD:** > "For developers who live in the terminal — your DevOps engineers, your platform teams, your CI pipeline builders — this is the Copilot surface that's going to transform their day-to-day. Not the IDE. The terminal."
> ---

---

#### Act 8: "The Full Stack Change" — Live Field Addition (Minutes 103–115 | ⏰ 1:33 – 1:45 PM)

**[EMMANUEL pulls Story 1838]**

**🎙️ HAMMAD (to audience):** > "Hands up if you've ever had a stakeholder walk up to you the week before go-live and say — 'we need just one more field.'"

**[Pause for reaction]**

**🎙️ HAMMAD:** > "Welcome to government. Here's what just happened — a stakeholder has come to us and said: CIVIC needs a budget field on the submission form. In a traditional process, that's a database migration, an API change, a DTO update, a frontend form change, translation files for English and French, and all the tests updated. Separate tickets. Separate PRs. Possibly a whole sprint. Emmanuel — with Copilot — how long does this actually take?"

**💻 EMMANUEL:** > "Let's find out. Live."

**Demo actions:**
- (min 103) Create `V005__add_program_budget.sql` — `ALTER TABLE program ADD program_budget DECIMAL(18,2) NULL`
- (min 104) Update `Program.java` entity — add `programBudget` field
- (min 105) Update `ProgramRequest.java` and `ProgramResponse.java` DTOs
- (min 106) Update `ProgramService.java` to map the budget field
- (min 107) Update `SubmitProgram.tsx` — add Ontario DS currency input field
- (min 108) Update `ReviewDetail.tsx` — show budget in review
- (min 109) Update `en/translation.json` and `fr/translation.json` — add budget labels
- (min 110) Update `ProgramControllerTest.java` — add budget to test data
- (min 123) Update `SubmitProgram.test.tsx` — test budget field rendering and accessibility
- (min 112) **Run all tests:** Backend + frontend — all green

  > ---
  > ### 🖥️ CLI SPOTLIGHT — Backup Option for Test Output Interpretation (min 112)
  > **[Use if a test failure occurs live, or as a bonus beat if time allows. Turns a potential awkward moment into a teaching moment.]**
  >
  > **[If a test fails or the output is complex:]**
  >
  > **🎙️ HAMMAD:** > "Emmanuel, before you scroll through that output — show them what Copilot CLI does with a wall of test results."
  >
  > **Demo (EMMANUEL pipes test output to Copilot):**
  > ```bash
  > # Pipe Maven test output directly to Copilot explain
  > mvn test 2>&1 | gh copilot explain
  >
  > # Or for npm:
  > npm test 2>&1 | gh copilot explain
  > ```
  > *Copilot reads the raw output and explains which tests failed, why, and what the likely fix is — in plain English.*
  >
  > **🎙️ HAMMAD:** > "This is one of my favourite things about the CLI. You can pipe *anything* to Copilot — build logs, Git diffs, test output, error stack traces. It's not constrained to what's in an editor tab. You bring the data; Copilot explains it."
  >
  > **🎙️ HAMMAD (to audience):** > "Think about your junior developers sitting with a red build at 4pm on a Friday. Instead of Googling a stack trace line by line, they pipe the output to Copilot and get a plain-English diagnosis in seconds. That's a real quality-of-life change."
  > ---
- (min 113) **Live:** Submit a CIVIC program with budget → review it in the Ministry portal → see budget displayed in the review detail
- (min 114) Commit: `feat: add program budget field end-to-end Fixes AB#1838 Fixes AB#1840`
- (min 115) **Tag v1.0.0** — "Application complete"

**Audience engagement point (min 115 | ⏰ 1:45 PM):**

**💻 EMMANUEL:** > "Twelve minutes. Database migration, entity, DTO, API, form, translation files, tests. All updated. All green."

**🎙️ HAMMAD:** > "Copilot understood the change because Emmanuel gave it context across the entire stack — the data dictionary, the JPA entity patterns, the Ontario Design System conventions, the bilingual requirements."

**🎙️ HAMMAD (to audience):** > "It's not just autocomplete. It's like a team member who has read every single file in your repository, remembers all of your standards, and never gets tired."

---

#### Closing: "What We Built" (Minutes 115–120 | ⏰ 1:45 – 1:50 PM)

**[SLIDE: Architecture diagram from docs/architecture.md]**

**[HAMMAD and EMMANUEL both at the front]**

**🎙️ HAMMAD:** > "Let's step back and look at what Emmanuel and Copilot just accomplished."

**[Walk through the completed components:]**

**💻 EMMANUEL:** > "Four database migration scripts. A Java Spring Boot API with four endpoints, validation, and error handling. A React frontend — official Ontario Design System, bilingual, WCAG 2.2 compliant. A Ministry review portal with approve/reject workflows. Unit tests including accessibility verification. A CI pipeline. And a live budget field added end-to-end in 12 minutes."

**[EMMANUEL shows ADO board — all stories moved to Done]**

**🎙️ HAMMAD:** > "Every piece of CIVIC code traces back to a user story. Every commit is linked to Azure DevOps. That's not just fast development — it's traceable, auditable, government-ready development. The kind your security teams, your audit functions, and your compliance officers can get behind."

**[Final slide: key numbers]**

| Metric | Value |
|--------|-------|
| Time | ~115 minutes of live coding |
| Database tables | 3 (+1 migration for live change) |
| API endpoints | 4 |
| React pages | 6 |
| Translation keys | ~40+ (EN + FR) |
| Unit tests | 15+ (backend + frontend) |
| ADO stories closed | 28+ |
| Lines of code | ~2000+ |

**🎙️ HAMMAD:** > "GitHub Copilot didn't replace any developer in this room — or any developer on Emmanuel's team. It amplified every single role we demonstrated today: DBA, backend engineer, frontend developer, QA engineer, DevOps. The custom instructions Emmanuel set up before this demo? Those are your team's standards, encoded as context. That's how you make AI work for government — not by throwing it at your codebase, but by teaching it your team's way of working."

**🎙️ HAMMAD:** > "My name is Hammad, this is Emmanuel — and we're happy to take your questions."

**[Both HAMMAD and EMMANUEL available for Q&A | ⏰ 1:50 PM]**

---

## Tagged Commit Checkpoints

These tags allow fast-forward recovery. If any phase runs long, skip to the next tag.

| Tag | Minute | Clock Time | Milestone | Recovery Note |
|-----|--------|------------|-----------|---------------|
| v0.2.1 | 0 | 10:30 AM | Demo rehearsal starting point | Reset to this tag to rehearse demo from scratch |
| v0.3.0 | 27 | 10:57 AM | CIVIC database schema complete | Can seed data manually if Flyway fails |
| v0.4.0 | 40 | 11:10 AM | Backend scaffolding | Skip to v0.5.0 if short on time |
| v0.5.0 | 50 | 11:20 AM | Backend API complete | Can demo API with curl |
| v0.6.0 | 70 | 11:40 AM | CIVIC citizen portal (LUNCH) | **Cliffhanger tag** — this is the lunch break state |
| v0.7.0 | 84 | 1:14 PM | Ministry portal | Core demo complete at this point |
| v0.8.0 | 95 | 1:25 PM | Tests passing | Can skip if very tight on time |
| v0.9.0 | 103 | 1:33 PM | CI verified | Quick pass, low risk |
| v1.0.0 | 115 | 1:45 PM | CIVIC full app + live change | Final state |

**Reset strategy:** To rehearse the demo from scratch, `git checkout v0.2.1` and start from minute 0.

**Fast-forward strategy:** If a phase runs 5+ minutes over, `git stash && git checkout v{next_tag}` and narrate: "In the interest of time, let me jump to where this phase ends up." The audience still sees the result.

## ADO User Story Execution Sequence

Ordered by demo minute, with branch and commit strategy:

| Minute | Stories | Branch | Commit Message |
|--------|---------|--------|----------------|
| 15-27 | 1813, 1812, 1810, 1814 | `feature/1813-database-schema` | `feat(db): add schema migrations and seed data AB#1813 AB#1812 AB#1810 AB#1814` |
| 28-40 | 1815 | `feature/1815-spring-boot-scaffolding` | `feat(api): add Spring Boot project scaffolding AB#1815` |
| 40-50 | 1817, 1816, 1819, 1820 | `feature/1817-api-endpoints` | `feat(api): implement all CRUD endpoints AB#1817 AB#1816 AB#1819 AB#1820` |
| 50-69 | 1818, 1821, 1822, 1823, 1824, 1825 | `feature/1818-citizen-portal` | `feat(ui): add citizen portal with Ontario DS and bilingual support AB#1818 AB#1821 AB#1822 AB#1823 AB#1824 AB#1825` |
| 72-84 | 1826, 1827, 1829 | `feature/1826-ministry-portal` | `feat(ui): add ministry review portal with approve/reject AB#1826 AB#1827 AB#1829` |
| 85-95 | 1828, 1831, 1830, 1833 | `feature/1828-unit-tests` | `test: add backend and frontend unit tests AB#1828 AB#1831 AB#1830 AB#1833` |
| 98-103 | 1834, 1835, 1837, 1839 | `feature/1834-ci-cd-polish` | `ci: verify pipeline runs with application code AB#1835 AB#1834 AB#1837 AB#1839` |
| 103-115 | 1838, 1840 | `feature/1838-budget-field` | `feat: add program budget field end-to-end Fixes AB#1838 Fixes AB#1840` |

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Copilot generates incorrect code live | Audience sees errors | Have tagged checkpoints; narrate: "Let's see Copilot's suggestion and refine it" — errors become teaching moments |
| Azure SQL connection fails | Backend cannot start | Pre-verify connection; have local H2 fallback in application-local.yml |
| NPM install takes too long | Dead time during frontend setup | Pre-cache node_modules; or `npm ci` with a lockfile prepared |
| Maven build takes too long | Dead time during backend setup | Pre-cache ~/.m2; or have a pre-built JAR at the tag checkpoint |
| Ontario Design System CSS doesn't load | UI looks broken | Pre-download CSS; have a fallback local copy |
| Copilot suggestions are slow | Awkward pauses | Fill with narration about what Copilot is analyzing; have backup typed snippets |
| Demo runs over time | Miss closing section | Skip QA tests (min 85-98); fast-forward to live change; close with 5-min wrap-up |
| Internet connectivity drops | All Azure/Copilot features fail | Pre-record a 3-minute video backup of the key moments |

### Potential Next Research

* Azure Durable Functions orchestration code for the approval workflow (not shown live but could be a bonus)
* Logic Apps email connector configuration for real email sending  
* AI Foundry mini model integration for notification summarization
* CD workflow (deploy-infra.yml exists; need app deployment workflow)
