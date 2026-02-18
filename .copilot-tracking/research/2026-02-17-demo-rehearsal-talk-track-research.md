<!-- markdownlint-disable-file -->
# Task Research: Demo Rehearsal, App Build & Talk Track

Build the actual OPS Program Approval application now that infrastructure is deployed. Create a minute-by-minute talk track for the 120-minute Developer Day 2026 demo with a cliffhanger at the 70-minute lunch break.

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
  * Tags v0.0.1 through v0.2.0 exist; next will be v0.3.0
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

Epic 1797 "OPS Program Approval System" [Agentic AI]

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

React + TypeScript + Vite. Ontario Design System CSS-only. i18next for EN/FR. react-router for navigation. WCAG 2.2 Level AA. Functional components with hooks.

## Key Discoveries

### Narrative Arc: The Cliffhanger Strategy

The most compelling cliffhanger at 70 minutes is: **the citizen can submit a form, the data reaches the database, but nobody can review it yet.** The audience sees a working submission but the "approval" side is empty. They return from lunch wanting to see the Ministry portal come alive, the review happen, and finally the live field-addition that proves end-to-end agility.

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

### Phase 4: Frontend Scaffolding + Citizen Portal (v0.6.0) — Stories: 1818, 1821, 1824, 1822, 1823, 1825

| Step | File | Description | Story |
|------|------|-------------|-------|
| 1 | `frontend/package.json` + Vite config | React project setup | AB#1818 |
| 2 | `frontend/public/locales/en/translation.json` | English translations | AB#1824 |
| 3 | `frontend/public/locales/fr/translation.json` | French translations | AB#1824 |
| 4 | `frontend/src/i18n.ts` | i18next configuration | AB#1824 |
| 5 | `frontend/src/components/layout/Header.tsx` | Ontario header | AB#1821 |
| 6 | `frontend/src/components/layout/Footer.tsx` | Ontario footer | AB#1821 |
| 7 | `frontend/src/components/layout/Layout.tsx` | Page layout wrapper | AB#1821 |
| 8 | `frontend/src/components/common/LanguageToggle.tsx` | EN/FR toggle | AB#1824 |
| 9 | `frontend/src/pages/SubmitProgram.tsx` | Submission form | AB#1822 |
| 10 | `frontend/src/pages/SubmitConfirmation.tsx` | Confirmation page | AB#1823 |
| 11 | `frontend/src/pages/SearchPrograms.tsx` | Search/list page | AB#1825 |
| 12 | `frontend/src/services/api.ts` | API service layer | — |
| 13 | `frontend/src/App.tsx` | Router setup | — |

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

### PART 1: "Building From Zero" (Minutes 0–70)

---

#### Opening: "The Problem" (Minutes 0–5)

**[SLIDE: Ontario government logo + "Developer Day 2026"]**

> "Good morning everyone. I'm [name], and today we're going to do something that would normally take a team of developers several weeks. We're going to build a complete government application — from an empty repository to a working, bilingual, accessible web app — in two hours. Live. Using GitHub Copilot as our AI pair programmer."

**[SWITCH TO: VS Code with empty repo]**

> "This is our starting point. We have documentation, infrastructure deployed in Azure, and 35 user stories in Azure DevOps. But zero application code. No database schema. No API. No UI. Let's change that."

**Key beat:** Show the empty `backend/`, `frontend/`, `database/` directories with only `.gitkeep` files.

---

#### Act 1: "The Architect" — Planning & Context (Minutes 5–15)

**[VS Code: Show copilot-instructions.md]**

> "Before we write a single line of code, let's talk about what makes Copilot truly powerful: context. We've given Copilot custom instructions that encode our coding standards, our tech stack, our accessibility requirements, and even our Ontario Design System conventions."

**Demo actions:**
- (min 5) Open `copilot-instructions.md` — walk through the key sections
- (min 7) Open `java.instructions.md` — show path-specific instructions concept
- (min 8) Open `react.instructions.md` — highlight WCAG 2.2 rules baked in
- (min 9) Open `docs/architecture.md` — show the Mermaid diagram
- (min 10) Open `docs/data-dictionary.md` — show ER diagram and tables
- (min 12) Switch to Azure DevOps — show Epic 1797 with 8 Features, 35 User Stories
- (min 13) Open ADO board — show the "Database Layer" feature, pick up Story 1813

> "Notice something important: we haven't told Copilot what to build yet, but we've taught it *how* to build. The instructions, the architecture docs, the data dictionary — that's the developer's judgement encoded as context. Copilot is powerful, but it's the developer who sets the direction."

**Key beat:** Pause on the ADO board. "These 35 stories are our roadmap. Let's start with the foundation: the database."

---

#### Act 2: "The DBA" — Database Migrations (Minutes 15–28)

**[Pull ADO Story 1813: Create program_type lookup table]**

> "Every application starts with data. Let's create our database — and let's see how Copilot handles SQL when it understands our conventions."

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

**Audience engagement point (min 28):**
> "Four SQL files. All bilingual. All with proper constraints. All following our naming conventions. Copilot didn't just write SQL — it wrote *our team's* SQL because we gave it our standards. How long would this take to hand-write and get through code review? A day? Copilot did it in 12 minutes."

---

#### Act 3: "The Backend Developer" — Spring Boot API (Minutes 28–50)

**[Pull ADO Story 1815: Create Spring Boot project scaffolding]**

> "Now we need an API that speaks to this database. Java 21. Spring Boot. Let's go."

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
- (min 44) Add GET /api/programs (Story 1816) and GET /api/programs/{id} (Story 1819) — inline completions
- (min 46) Add PUT /api/programs/{id}/review (Story 1820) — show ReviewRequest DTO
- (min 48) **Live test:** Submit, list, get by ID, review — all working via curl
- (min 49) Commit: `feat(api): implement all CRUD endpoints AB#1817 AB#1816 AB#1819 AB#1820`
- (min 50) **Tag v0.5.0** — "Backend API complete"

**Audience engagement point (min 50):**
> "We have a fully functional REST API. Four endpoints. Validation. Error handling. Database persistence. JPA entities mapped to our schema. All in 22 minutes. And notice — every time I opened a Java file, Copilot already knew to use constructor injection, ProblemDetail errors, and ResponseEntity because of our path-specific instructions. That's the power of custom instructions."

---

#### Act 4: "The Frontend Developer" — Citizen Portal (Minutes 50–70)

**[Pull Story 1818: Create React project with Ontario Design System]**

> "Now the part the audience can see. Let's build the citizen-facing portal — and let's make it bilingual and accessible from the very first component."

**Demo actions:**
- (min 50) Create React + TypeScript + Vite project: `npm create vite@latest . -- --template react-ts`
- (min 51) Install dependencies: `npm install @ongov/ontario-design-system-global-styles react-router-dom i18next react-i18next axios`
- (min 52) Create `i18n.ts` — Copilot generates full i18next config with language detection
- (min 53) Create `public/locales/en/translation.json` — show keys for all UI strings
- (min 54) Create `public/locales/fr/translation.json` — Copilot generates French translations
- (min 55) Create `Header.tsx` — Ontario Design System header with official branding
- (min 56) Create `Footer.tsx` — Ontario footer with required links
- (min 57) Create `Layout.tsx` — wraps all pages in Ontario header/footer
- (min 58) Create `LanguageToggle.tsx` — EN/FR button that updates lang attribute (WCAG 3.1.1)

**[Pull Story 1822: Build program submission form]**

- (min 59) Create `SubmitProgram.tsx` — the form
- (min 60) **KEY DEMO MOMENT:** Show Copilot generating the form with Ontario CSS classes, aria-labels, error identification (WCAG 3.3.1), autocomplete attributes — all from react.instructions.md
- (min 62) Create `api.ts` service — connects to backend
- (min 63) Create `SubmitConfirmation.tsx` (Story 1823)
- (min 64) Create `SearchPrograms.tsx` (Story 1825) — list/search page
- (min 65) Create `App.tsx` with react-router routes
- (min 66) **LIVE DEMO:** Open browser → navigate to form → fill in program → submit → see confirmation
- (min 67) **LIVE DEMO (continued):** Switch language to French → show entire UI in French → submit another program
- (min 68) **LIVE DEMO (continued):** Check database — show both submissions persisted in Azure SQL
- (min 69) Commit: `feat(ui): add citizen portal with Ontario DS and bilingual support AB#1818 AB#1821 AB#1822 AB#1823 AB#1824 AB#1825`

---

### 🔥 THE CLIFFHANGER (Minute 70)

**[Browser showing: citizen portal with submissions list. Switch to Ministry Portal route — BLANK PAGE.]**

> "So here's where we stand. A citizen can visit our portal, fill out a bilingual, accessible form, and submit a program request. The data flows through our REST API and into Azure SQL. We can search programs. We can view them in English or French."

**[Pause. Click on 'Ministry Review' nav link. Empty page.]**

> "But there's a problem."

**[Dramatic pause.]**

> "Nobody can approve anything. The ministry side of this application... doesn't exist yet. We have submissions piling up in the database with no way to review them. No way to approve. No way to reject. No way to notify the citizen of a decision."

**[Show the ADO board — 3 user stories under 'Ministry Portal' all in 'New' state.]**

> "We have three stories sitting here. Build the review dashboard. Build the detail page. Implement the approve/reject workflow. Plus unit tests, accessibility audits, CI/CD, and — if we're feeling ambitious — a live field addition from database to UI."

**[Close laptop lid halfway / step back from screen]**

> "We built the citizen half of this application in 70 minutes. From nothing. Can we finish the other half in 50 minutes after lunch? Let's find out. Enjoy your break — we'll pick up right where we left off."

**Tag v0.6.0** — "Citizen portal complete, ministry portal pending"

---

### PART 2: "Closing the Loop" (Minutes 70–120)

---

#### Recap (Minutes 70–72)

**[Open VS Code, browser side-by-side]**

> "Welcome back. Let's recap where we are. We have a working citizen portal, four API endpoints, and a SQL database with real data. What we don't have is the ministry review side. Let's fix that."

**Demo actions:**
- (min 71) Quickly show the submitted programs in the database
- (min 72) Show the 3 remaining Ministry Portal stories on the ADO board

---

#### Act 5: "Completing the Story" — Ministry Portal (Minutes 72–85)

**[Pull Story 1826: Build program review dashboard]**

> "The ministry employee needs to see all submissions in one place. Let's build that dashboard."

**Demo actions:**
- (min 72) Create `ReviewDashboard.tsx` — table/list of all programs with status badges
- (min 74) **Live:** Browse to Ministry Review — show list of submitted programs
- (min 75) Create `ReviewDetail.tsx` (Story 1827) — show program details with citizen info
- (min 78) Create `ReviewForm.tsx` (Story 1829) — approve/reject buttons, comment field
- (min 80) **Live:** Navigate to a submitted program → review it → approve it with a comment
- (min 81) **KEY MOMENT:** Show the program status changed from SUBMITTED to APPROVED in the citizen's search view
- (min 82) **Live:** Reject a second program with comments → show status update
- (min 83) Commit: `feat(ui): add ministry review portal with approve/reject AB#1826 AB#1827 AB#1829`
- (min 84) **Tag v0.7.0** — "Ministry portal complete"

**Audience engagement point (min 85):**
> "Thirteen minutes. We went from a blank ministry page to a working review workflow. The citizen submits, the ministry reviews, the status updates in real time. This is a complete approval system — built from scratch — and we're at 85 minutes."

---

#### Act 6: "The QA Engineer" — Testing (Minutes 85–98)

**[Pull Story 1828: Write unit tests for backend API]**

> "Code that works is great. Code that's tested is better. Let's see Copilot write tests."

**Demo actions:**
- (min 85) Create `ProgramControllerTest.java` — @WebMvcTest with Mockito
- (min 87) Show Copilot generating test cases for POST (valid, invalid), GET (list, by ID, not found), PUT (approve, reject)
- (min 89) **Run tests live:** `mvn test` — show all green
- (min 90) Create `SubmitProgram.test.tsx` (Story 1831) — React Testing Library
- (min 92) Create `accessibility.test.tsx` (Story 1830) — jest-axe testing
- (min 93) **Run tests live:** `npm test` — show all passing including a11y
- (min 94) Commit: `test: add backend and frontend unit tests AB#1828 AB#1831 AB#1830`
- (min 95) **Tag v0.8.0** — "Tests passing"

**Audience engagement point (min 95):**
> "Copilot wrote tests that catch real bugs. The accessibility tests automatically verify WCAG compliance — aria labels, form associations, heading hierarchy. That's not just testing; that's building quality into the development process."

**[Pull Story 1833: Verify bilingual content completeness]**

- (min 96) Quick check: compare en/fr translation files for completeness
- (min 97) Show any missing keys, Copilot suggests the French translations
- (min 98) Commit: `fix(i18n): complete bilingual content verification AB#1833`

---

#### Act 7: "The DevOps Engineer" — CI/CD Polish (Minutes 98–103)

> "Let's make sure all of this is protected by our pipeline."

**Demo actions:**
- (min 98) Show existing `ci.yml` — highlight that backend-ci and frontend-ci jobs now have actual code to build
- (min 99) Push to trigger CI — show it building Maven + npm in parallel
- (min 100) Quick show of Dependabot config (Story 1837) and secret scanning (Story 1839)
- (min 101) Mention the deploy-infra.yml we already have for infrastructure
- (min 102) Commit any CI tweaks: `ci: verify pipeline runs with application code AB#1835 AB#1834`
- (min 103) **Tag v0.9.0** — "CI verified"

---

#### Act 8: "The Full Stack Change" — Live Field Addition (Minutes 103–115)

**[Pull Story 1838: Add Program Budget field to submission form]**

> "Here's the moment of truth. A stakeholder just walked into our office and said: 'We need a budget field on the submission form.' In a traditional development process, that change touches the database, the API, the frontend, and all the tests. Let's see how fast Copilot can help us make that change, end-to-end."

**Demo actions:**
- (min 103) Create `V005__add_program_budget.sql` — `ALTER TABLE program ADD program_budget DECIMAL(18,2) NULL`
- (min 104) Update `Program.java` entity — add `programBudget` field
- (min 105) Update `ProgramRequest.java` and `ProgramResponse.java` DTOs
- (min 106) Update `ProgramService.java` to map the budget field
- (min 107) Update `SubmitProgram.tsx` — add Ontario DS currency input field
- (min 108) Update `ReviewDetail.tsx` — show budget in review
- (min 109) Update `en/translation.json` and `fr/translation.json` — add budget labels
- (min 110) Update `ProgramControllerTest.java` — add budget to test data
- (min 111) Update `SubmitProgram.test.tsx` — test budget field rendering and accessibility
- (min 112) **Run all tests:** Backend + frontend — all green
- (min 113) **Live:** Submit a program with budget → review it → see budget displayed
- (min 114) Commit: `feat: add program budget field end-to-end Fixes AB#1838 Fixes AB#1840`
- (min 115) **Tag v1.0.0** — "Application complete"

**Audience engagement point (min 115):**
> "Twelve minutes. Database to UI. A field addition that normally triggers meetings, estimates, and a sprint worth of work. Copilot understood the change because it has context across the entire stack — the data dictionary, the JPA entity patterns, the Ontario Design System form conventions, the bilingual requirements. It's not just autocomplete. It's a team member who has read every file in your repo."

---

#### Closing: "What We Built" (Minutes 115–120)

**[SLIDE: Architecture diagram from docs/architecture.md]**

> "Let's step back and look at what we accomplished in two hours."

**[Walk through the completed components:]**

> "Four database tables with bilingual support. A Java Spring Boot API with four endpoints, validation, and error handling. A React frontend with the Ontario Design System — bilingual, accessible, WCAG 2.2 compliant. A Ministry review portal with approve/reject workflows. Unit tests with accessibility verification. A CI pipeline that builds and tests everything. And a live field addition from database to UI in 12 minutes."

**[Show ADO board — all stories moved to Done]**

> "Every piece of code traced back to a user story. Every commit linked to Azure DevOps. That's not just fast development — it's traceable, auditable, government-ready development."

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

> "GitHub Copilot didn't replace any developer in this room. It amplified every developer role we demonstrated — DBA, backend, frontend, QA, DevOps. The instructions we wrote before the demo? Those are your team's standards, encoded as context. That's how you make AI work for government."

> "Thank you. Questions?"

---

## Tagged Commit Checkpoints

These tags allow fast-forward recovery. If any phase runs long, skip to the next tag.

| Tag | Minute | Milestone | Recovery Note |
|-----|--------|-----------|---------------|
| v0.3.0 | 27 | Database schema complete | Can seed data manually if Flyway fails |
| v0.4.0 | 40 | Backend scaffolding | Skip to v0.5.0 if short on time |
| v0.5.0 | 50 | Backend API complete | Can demo API with curl |
| v0.6.0 | 70 | Citizen portal (LUNCH) | **Cliffhanger tag** — this is the lunch break state |
| v0.7.0 | 84 | Ministry portal | Core demo complete at this point |
| v0.8.0 | 95 | Tests passing | Can skip if very tight on time |
| v0.9.0 | 103 | CI verified | Quick pass, low risk |
| v1.0.0 | 115 | Full app + live change | Final state |

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
