# Obelisk Framework

_A contract-driven, phase-separated collaboration protocol for stateless AI work on long-lived systems._

---

## Why Obelisk Exists

> **AI does not fail because it is weak — it fails because long-term use is unmanaged.**

As projects grow:

- Conversations accumulate stale assumptions
- Sessions reset and models switch
- Critical knowledge is lost
- AI-generated changes silently break working systems
- It becomes unclear what changed — and why

Over time, AI-assisted development becomes **unpredictable and difficult to trust**.

Obelisk externalizes truth, intent, and history into explicit files so correctness does not depend on chat memory.

---

## Design Philosophy

### The Core Problems

**Context Window Trap**

- Chat history grows indefinitely, increasing costs and noise
- Knowledge lives only in conversation, creating vendor/model lock-in
- Context limits eventually force abandoning all accumulated understanding
- Only code remains — stripped of decisions, rationale, and constraints

**Rushed Execution**

- Models default to immediate implementation without understanding
- Critical questions go unasked; alternatives unexplored
- Technical decisions lock in before proper evaluation

**Silent Corruption**

- Code drifts from original intent across dozens of small changes
- AI "fixes" introduce unintended modifications to stable code
- Subtle bugs accumulate unnoticed over time
- After long breaks, mental context evaporates — work becomes archaeology

### Why Obelisk Works

**Stateless Collaboration**  
Files replace chat as the source of truth. Switch models freely, resume after months, pay only for current work.

**Intent Before Execution**  
Mandatory discovery forces understanding before implementation. Scope, risks, and alternatives are explicit before code changes.

**Validated Evolution**  
Contracts define boundaries. Review validates every change against frozen intent. Drift and corruption are detected, not discovered later.

> **The failure mode isn't bad code — it's lost knowledge and silent corruption.**

Current tools optimize for immediate productivity at the cost of long-term sustainability.  
Obelisk inverts this: upfront structure for durable correctness.

---

## What Obelisk Is

Obelisk is a structured collaboration framework that makes AI-assisted development:

- **Safe**
- **Repeatable**
- **Recoverable**

It enforces strict separation between:

- **Truth** — what must always hold (contracts)
- **Intent** — what is being attempted (frozen task)
- **Execution** — how it is implemented (plan and code)
- **History** — what changed and why (logs)

> **Contracts define truth. Tasks freeze intent. Plans constrain execution.  
> History records decisions. Summaries enable work. Archives preserve everything.**

**Obelisk is model-independent.** Any phase may be executed by different models.

**It does not prevent failure. It prevents silent damage.**  
Mistakes are expected; corruption is not.

---

## Designed For

Long-lived systems where:

- Correctness matters more than raw velocity
- Breaking changes damage trust or operations
- AI is used continuously in production

It intentionally trades early friction for long-term stability.

**Not Designed For:**

- Throwaway prototypes
- Maximum-speed experimentation
- Replacing manual testing
- Guaranteeing zero bugs

---

## Core Properties

- Files are the source of truth — chat history is not
- Sessions are stateless — models are interchangeable
- Intent is frozen before execution
- All mutations flow through tasks
- Recovery matters more than perfection
- Friction is proportional to risk

Higher layers constrain lower ones. Lower layers must never redefine higher ones.

---

## Commands

|Command|Purpose|
|---|---|
|`/init-project`|Initialize a project|
|`/define-task [description]`|Define and freeze a task|
|`/run-task`|Run task from current phase to the end|
|`/ask`|Query project knowledge|
|`/help`|Show available commands|

---

## Workflow Overview

> _Discovery clarifies intent → Freeze stabilizes it → Planning constrains execution → Review validates reality._

### Project Initialization (Once)

Structured discovery defines system identity, boundaries, and invariants before implementation begins.

**Why this exists:**  
AI models default to producing solutions even when requirements are unclear. When intent is underspecified, the model fills gaps by guessing. Skipping discovery allows ambiguity to harden into architecture and code.

**Outcome:** A durable foundation that survives session resets and model switches.

_Initialization may be minimal for existing or experimental projects._

---

### Task Loop (Repeats)

Each task runs as an isolated, stateless cycle.

```
task → plan → implement → review → archive
```

Execution resumes from the current phase if interrupted.

---

#### Hotfix (Shortcut)

Used only when:

- Change is single and obvious
- No invariants are affected
- Fully reversible
- Diff explains itself

Examples: typos, formatting, simple renames.

Hotfixes bypass planning but are always recorded.

---

#### 1 — Create Task (`/define-task`)

**Freeze intent before execution.**

Without freezing:

- Gaps are filled by guessing
- Edge cases are missed
- Architectural impact is ignored
- Intent drifts during implementation

**Outcome:** A single approved task definition stored in files.

---

#### 2 — Run Task (`/run-task`)

Execute the frozen task within contract boundaries.

**Phases:**

**Planning & Implementation**  
Analyze code, create initial plan, implement without expanding scope.

**Review, Archive & Cleanup**  
Validate goal, success criteria, and contract preservation. Archive artifacts and reset workspace.

The system evolves with explicit authority and full traceability.

---

## System Structure

```
/obelisk/
├── contracts/
│   ├── contracts-log.md        # Canonical, append-only contracts
│   └── contracts-summary.md    # AI-generated, derived view
├── history/
│   ├── history-log.md          # Canonical, append-only history
│   └── history-summary.md      # AI-generated, derived view
├── workspace/                  # Ephemeral execution state
├── archive/
│   ├── completed/              # Approved tasks
│   ├── rejected/               # Rejected tasks
│   └── aborted/                # Aborted tasks
├── guidelines/
│   └── ai-engineering.md       # Execution constraints
├── internal/                   # Framework internals
└── README.md
```

---

## Authority & Knowledge Model

Obelisk separates authoritative records from derived views.

### Canonical Logs (Authoritative)

**Contracts Log** — append-only record of invariants  
**History Log** — append-only record of decisions

These define project truth.

---

### Derived Summaries (Disposable)

**Contracts Summary** — operational projection of active contracts  
**History Summary** — compact project timeline

Summaries are regenerated from canonical logs and never override them.

---

### Tasks — Frozen Intent

`workspace/active-task.md`

- Created during `/define-task`
- Immutable once frozen
- Exists only while active, then archived

**Authority:** Below contracts, above plans and code.

---

### Execution Constraints

`guidelines/ai-engineering.md`

Defines how planning and implementation must behave.  
Cannot override contracts or frozen task intent.

---

## Authority Hierarchy (Highest → Lowest)

1. Contracts Log
2. Active Task
3. AI Engineering Rules
4. History Log
5. Derived Summaries
6. Chat History

Higher authority defines intent.  
Lower authority may not redefine higher authority.

---

## Single Mutation Path

All changes to code, contracts, and history flow through tasks.

- No hidden updates
- Complete audit trail by default
- Tasks become the project's version history

Derived summaries introduce no authority.

---

## Scope of This File

This README provides **orientation only**.

It does **not**:

- Define project-specific rules
- Override contracts, tasks, or execution rules
- Participate in authority resolution

Conceptually, Obelisk defines a **collaboration protocol**.  
This repository provides a reference implementation of that protocol.