# Meta-Approach: Multi-Agent Project Orchestration

---

## Context

Pure-idea-stage project — any domain (app, tool, content, research,
internal process). User wants to lock **the development process** before
diving into the work itself. Goal: run a multi-agent orchestration model
where I (Claude, the orchestrator) architect and dispatch work, sub-agents
handle research / docs / building / testing / fixing in parallel, and
downtime is near-zero via aggressive blocker triage.

This plan covers **process only** — not the project's actual content or
spec. Discovery and spec-writing happen *inside* this process once it kicks
off. The orchestration model itself is the thing being run; useful patterns
get distilled into reusable skills continuously (see § Verification &
Continuous Distillation), not just once at the end.

---

## Phases

| # | Phase | Output | Gate |
|---|-------|--------|------|
| 1 | **Discovery** | `spec.md` (A-Z scope) | Spec lock (user sign-off) |
| 2 | **Architecture & Approach** | `decisions.md` ADRs; chosen approach/stack | Approach pick (user sign-off) |
| 3 | **Workstream Carving** | `workstreams.md` with parallel tracks + deps | None (orchestrator decision) |
| 4 | **Build + Test + Review loop** | Output + test reports per milestone | Only on milestone failure |
| 5 | **Integration & Ship** | Working deliverable | Pre-ship review (user sign-off) |
| 6 | **Skill distillation (continuous)** | Skill updates, captured incrementally as patterns prove out | Self-triggering — see § Verification & Continuous Distillation |

**Gate rule:** user-approval gates only at *major decisions* (rows above
marked "user sign-off"). Everything else runs autonomous with orchestrator
authority.

---

## Discovery Loop (Phase 1 — most important)

1. **User brain-dumps** the idea freely (any order, any depth).
2. **Orchestrator structures** the dump into a spec scaffold: problem →
   users → features → flows → data/content model → requirements →
   constraints (see `BRAINDUMP_TRIAGE.md` for the sorting/conflict-flagging
   process).
3. **Orchestrator asks targeted gap-filling questions**, batched a few at a
   time, with detailed option descriptions on demand.
4. **Iterate** structure + Q&A loops until *every* detail is locked — no
   ambiguity left for a sub-agent to misinterpret.
5. Exit criterion: spec is executable by an unaware agent without
   follow-up questions.

Discovery may take many turns. That's intentional.

---

## Agent Roles

| Role | Job | Spawned by |
|------|-----|-----------|
| **Orchestrator (me)** | Architect, dispatch, triage blockers, gate decisions, talk to user, run distillation checks | — |
| **Discovery agent** | Structure dumps + draft spec sections (used sparingly; user-direct mostly) | Orchestrator |
| **Research agent** | Investigate blockers, approach choices, tooling; return ADR-style doc | Orchestrator |
| **Builder agent** | Implement one workstream (code, content, whatever the project is) | Orchestrator |
| **Reviewer agent** | Dedicated per workstream, gates quality before merge | Orchestrator |
| **Tester agent** | Owns functionality test docs + execution + report (see Testing Protocol) | Orchestrator |
| **Documenter agent** | Keeps `spec.md` / `blockers.md` / `workstreams.md` current; drafts or updates skill files when a distillation trigger fires (see § Verification & Continuous Distillation) | Orchestrator |

Every dispatch to any of these roles is built from **`AGENT_DISPATCH_TEMPLATES.md`** — a fixed skeleton per role, including which files each agent owns, may append to, or must not touch, filled in rather than re-derived each time.

---

## Orchestrator Delegation Rules (Non-Negotiable)

The orchestrator coordinates. It does not implement. This is the single most
important discipline in the methodology — violations bog down the primary
process, lose parallelism, and waste context window on implementation details.

### What the orchestrator MAY do directly:
- Read files for planning/triage/context
- Git operations (status, log, diff, commit)
- Edit orchestration files (planning/, .claude/, MEMORY, CLAUDE.md, settings)
- Run status checks (ls, curl health endpoints, SSH connectivity)
- Dispatch and manage agents
- Communicate with the user

### What the orchestrator MUST delegate to agents:
- Any source code edit (even "trivial" ones — they're never trivial)
- Any build/install/compile command (npm, python, dotnet, cargo, etc.)
- Any test execution
- Any multi-step implementation task
- Any research requiring more than 3 search queries

### Enforcement:
- PreToolUse hook on Edit|Write|Bash warns when delegation boundary is crossed
- If you catch yourself about to edit a source file: STOP. Dispatch an agent.
- If a "quick fix" would take you 2 minutes directly, it would take an agent
  3 minutes — but it keeps your context window clean and your parallelism
  intact. Always delegate.

### Lessons learned:
- Monitor/watchdog agents must be READ-ONLY. A monitoring agent that took
  corrective action (killing "stuck" GPU jobs) interfered with a fix agent's
  active test runs and killed the entire ComfyUI process.
- Agents editing the same file concurrently causes conflicts. Use the
  Shared-File Collision Protocol, but also minimize shared file edits by
  scoping agent ownership tightly.
- When multiple agents need to modify the same integration point (e.g.,
  a bootstrap file, a UI builder), serialize those edits or designate
  one integration agent that runs after the parallel builders finish.

---

## Parallel Budget

- **No concurrent-agent cap.** Dispatch as many sub-agents as the work
  warrants. The Shared-File Collision Protocol below is the safety net
  regardless of how many agents are running.
- All work types (research / doc / build / test / fix) parallelizable as
  load allows — not segregated by phase.
- Sub-agents don't spawn sub-sub-agents at the current tier.
- Operational ceiling lives at the harness layer (whatever caps concurrent
  agents in your runtime). No project-level throttle beyond that.

### Shared-File Collision Protocol

Parallel agents will sometimes touch the same file even with reasonable
planning. When that happens:

- **Shared files are append-only by convention.** An agent should never
  delete or rewrite another agent's additions to a file it doesn't fully
  own, even if its own change touches the same file.
- **Pull latest before the final commit.** Every parallel agent re-checks
  the current state of any shared file immediately before committing, not
  just at dispatch time.
- **First to finish commits clean.** Whichever agent completes first
  commits its work as-is. Any agent that finishes later rebases onto that
  merged state before making its own commit, so both contributions land
  without either being silently dropped.
- **A collision discovered this way is expected, not an incident.** It
  doesn't require pausing the wave, re-planning, or escalating to the user —
  it's the designed recovery path. Log it briefly in `process-journal.md` so
  the pattern is visible later, but don't treat it as a blocker.
- Pre-declaring file ownership in dispatch prompts (the YOU OWN / YOU MAY
  APPEND TO / DO NOT TOUCH fields in `AGENT_DISPATCH_TEMPLATES.md`) reduces
  how often this path gets exercised but isn't required for it to work.

---

## Blocker Protocol

1. Any blocker (technical, content, design) gets filed in `blockers.md`
   with: `id`, `summary`, `context`, `attempted`, `owner-agent`, `status`.
2. Orchestrator spawns a **research agent** scoped to that blocker. Output:
   solution doc appended to the blocker entry.
3. After research is documented, orchestrator spawns (or reassigns) a
   **builder agent** to apply the solution.
4. **Other tracks keep moving** during the research+fix loop — never block
   the whole pipeline on one issue.
5. **Hard blockers** (need user judgment, external access, accounts, money)
   get surfaced by orchestrator to user — batched if multiple are pending.
   Other agents keep working in parallel.
6. Always ask the user more questions when scope is unclear — never guess
   silently.

---

## Testing Protocol

- **Cadence:** test after each **milestone**, where milestone = one
  user-facing capability complete end-to-end.
- **Flow:**
  1. Builder agent writes a **functionality test doc** describing what
     should work for the milestone.
  2. Tester agent executes the doc against the running deliverable, writes a
     **report doc** (pass/fail per case, evidence).
  3. Reviewer agent reads the report → green-light or kick back to builder
     with specific failures.
- **Test framework: TBD per project.** Phase 2 spawns a research agent
  comparing the viable options for this project's actual stack and feature
  mix (e.g. for mobile: Maestro vs Detox vs native; for web: Playwright vs
  Cypress; for non-software work: whatever the equivalent verification step
  is). Decision lands in `decisions.md` as an ADR.

---

## Repo & Version Control

**Step 0 — runs before Phase 1 Discovery, not after:**

1. **Name gate.** A project name is a prerequisite for repo creation, not a
   nice-to-have. If the user's request already states one, use it. If not,
   ask "What should we call this project?" and wait for an answer — do not
   create a repo against a placeholder or folder name.
2. **Prerequisite check.** Verify `gh auth status` and `git` are available.
   Missing → hard blocker, surfaced to the user, not silently worked around.
3. **Create private repo, then scaffold.** `git init`; `gh repo create
   <name> --private --source=. --remote=origin`. Then: copy in
   `OPERATING_MANUAL.md` + `AGENT_DISPATCH_TEMPLATES.md` +
   `BRAINDUMP_TRIAGE.md`, create
   `planning/{spec,blockers,workstreams,decisions,process-journal,skill-opportunities}.md`,
   create an empty `skills-candidates/` (see § Verification & Continuous
   Distillation — this is where Phase 6 drafts land, not the shared skills
   repo). Commit, push.
4. **Then** proceed to Phase 1 Discovery.

- Agents work on local branches; reviewer agent gates merges to local
  `main`, which is also the remote `main` from step 3 onward.
- This repo is project-scoped and self-contained — it is not where shared,
  cross-project skills live. See § Verification & Continuous Distillation
  for that split.

---

## Artifact Locations

| Artifact | Location | Purpose |
|---|---|---|
| `spec.md` | `<project-repo>/planning/spec.md` → moves to `/docs` at build-start | A-Z scope |
| `blockers.md` | `<project-repo>/planning/blockers.md` | Open + resolved blockers w/ research + fix notes |
| `workstreams.md` | `<project-repo>/planning/workstreams.md` | Parallel tracks: owner agent, state, deps |
| `decisions.md` | `<project-repo>/planning/decisions.md` | ADRs for major calls |
| `skill-opportunities.md` | `<project-repo>/planning/skill-opportunities.md` | Friction tracking — unplanned returns, corrections, automation gaps |
| `skills-candidates/` | `<project-repo>/skills-candidates/` | Phase 6 drafts, local to this project — not yet promoted anywhere |
| Per-phase orchestrator plans | `~/.claude/plans/` | This file + future phase plan files |
| Durable preferences | `~/.claude/projects/<project-slug>/memory/` | Cross-project methodology preferences |
| Shared skills repo | separate repo, not `<project-repo>` | Curated landing zone — only receives skills promoted after the project-wrap review, never a live mirror of `skills-candidates/` |

(A dedicated per-project memory dir is created once the project name/path
is known; until then, a default methodology memory dir holds cross-project
entries.)

---

## Orchestrator Status Reporting

Each user-facing turn during the build phase reports, in 1–3 lines:

- **Running:** which sub-agents are active right now.
- **Blockers:** hard blockers needing user input (if any).
- **Next:** what dispatches when current agent(s) finish.

Keeps the user oriented without flooding them.

---

## Verification & Continuous Distillation (Phase 6)

Phase 6 runs continuously, triggered by the conditions below rather than by
a project reaching an end point.

**Trigger conditions (any one fires a distillation pass):**

- A milestone just closed (see checklist below).
- A blocker's resolution, once filed in `blockers.md`, reads like it would
  recur on a different project — not specific to this one.
- The user explicitly asks for it.
- N consecutive milestones have shipped with no distillation pass at all —
  a backstop so it can't be silently skipped indefinitely. Pick an N that
  fits the project's pace; small personal projects might use N=1.

**Milestone-close checklist (runs at every milestone, not just the first):**

- Did blockers resolve without stalling the pipeline?
- Did the test loop catch real issues vs noise?
- Was orchestrator load manageable at the current fan-out level?
- Did anything in this milestone's `blockers.md` / `decisions.md` /
  `process-journal.md` entries generalize beyond this specific project?
- Any new or escalated skill opportunities this milestone? (Check
  `skill-opportunities.md` — any YELLOW+ items need to be surfaced.)

Adjust the model before scaling further if something didn't work. Document
the tweak in `decisions.md`.

**Distillation pass (mechanical, not memory-dependent):**

Read `decisions.md` + `blockers.md` + `process-journal.md` since the *last*
distillation pass — the delta, not the whole history. For each candidate
lesson:

- If it matches an existing skill, append to or update it.
- If it matches an existing skill *already promoted to the shared skills
  repo*, note the proposed update in `skills-candidates/` rather than
  editing the shared repo directly — promotion is a separate step, below.
- If it's net-new and reusable, draft it as a candidate skill in
  `skills-candidates/` immediately, while the reasoning is still explicit in
  the source artifacts — not reconstructed later from a compressed summary.
  This is a draft, not a promotion: it lives only in this project's repo
  until the wrap-time review below.
- If it's genuinely project-specific, leave it in `process-journal.md` and
  move on. Not every lesson needs to become a skill.

**Skill Promotion (project wrap, or on request — separate from the above):**

The shared skills repo is not a live mirror of `skills-candidates/` and
nothing is promoted automatically. At project wrap (or whenever the user
wants to check in), this is a deliberate review:

1. Documenter agent reads `skills-candidates/` + `process-journal.md` and
   writes a short report: what each candidate captures, where it actually
   got used within this project, and any signal that it would generalize
   beyond this one codebase or domain.
2. User reviews the report and picks which candidates are worth keeping —
   "what worked, what didn't" is a judgment call, not a checklist.
3. Selected candidates get copied into the separate shared skills repo.
   Rejected or project-specific ones stay in this repo's
   `skills-candidates/` as a record, but never get copied out.

---

## Skill Opportunity Tracking (Continuous)

The primary goal of early workflows is automation. Every friction point —
every unplanned return to the user, every repeated correction — is a signal
that a workflow needs a skill, a better skill, or a different agent strategy.
This section defines how to detect, flag, escalate, and act on those signals.

### What gets tracked

Track any event where the orchestrator **returns to the user outside of a
designed gate** (spec sign-off, approach pick, pre-ship review). These are
**unplanned returns** — they indicate the orchestrator or its agents lacked
the knowledge or authority to proceed autonomously.

Planned gates (Phase 1 spec lock, Phase 2 approach pick, Phase 5 pre-ship)
are NOT flagged. They are working as designed.

**Trackable events:**
- User corrects an agent's output or approach
- User provides information that should have been known or discoverable
- Orchestrator asks user for judgment on something that could be codified
- Agent fails at a task and orchestrator escalates instead of resolving
- Same type of blocker recurs across milestones or projects
- A manual multi-step process is performed more than once

### Severity escalation

Severity is per **topic**, not per instance. The topic is the underlying
workflow gap, not the surface-level correction.

| Strike | Severity | Label | Meaning |
|--------|----------|-------|---------|
| 1 | Noted | `⚪ NOTED` | Logged in `skill-opportunities.md`. First signal — might be a one-off. |
| 2 | Yellow | `🟡 YELLOW` | Pattern confirmed. Escalate in next status report to user. |
| 3 | Red | `🔴 RED` | Active problem. Dispatch documenter agent to draft a candidate skill immediately. |
| 4 | Black | `⚫ BLACK` | Systemic gap. Halt related work until skill/automation is in place — continuing without it wastes more time than pausing to fix it. |

Severity only goes UP, never down. A topic that hits yellow stays yellow
even if the next milestone doesn't trigger it — the pattern was already
confirmed.

### Logging format — `skill-opportunities.md`

Every flagged event gets an entry in `planning/skill-opportunities.md`:

```
### SO-{NNN}: {short title}
- **Severity:** ⚪ NOTED | 🟡 YELLOW | 🔴 RED | ⚫ BLACK
- **Strike count:** {N}
- **Category:** {prompt-engineering | infrastructure | agent-scoping | workflow-gap | domain-knowledge | tooling}
- **Trigger:** {what happened — the unplanned return or correction}
- **Context:** {what the orchestrator/agent was trying to do}
- **Resolution:** {how it was resolved this time}
- **Skill gap:** {what knowledge or automation would have prevented this}
- **Candidate skill:** {path to skills-candidates/ draft, if dispatched}
- **History:**
  - {date}: Strike 1 — {brief description}
  - {date}: Strike 2 — {brief description, severity escalated to YELLOW}
```

### When to act

| Event | Action |
|-------|--------|
| Strike 1 (NOTED) | Log in `skill-opportunities.md`. Mention in session summary. |
| Strike 2 (YELLOW) | Update severity. Surface to user in next status report: "This has come up twice — worth skilling?" |
| Strike 3 (RED) | Update severity. **Immediately dispatch a documenter agent** to draft a candidate skill in `skills-candidates/`. Don't wait for milestone boundary. |
| Strike 4 (BLACK) | Update severity. **Pause related workstreams.** Surface to user: "This gap is costing more time than fixing it. Recommending we build the skill/automation now before continuing." |

### Orchestrator obligations

1. **After every unplanned user return:** Before resuming work, check
   whether this event matches an existing topic in `skill-opportunities.md`.
   If yes, increment strike count and escalate severity. If no, create a
   new entry at NOTED.

2. **At every status report:** Include a one-liner for any YELLOW+ items:
   "Skill opportunity SO-003 (prompt angle control) at YELLOW — 2 strikes."

3. **At session end:** Review `skill-opportunities.md` as part of session
   data capture. Any NOTED items that were resolved permanently (e.g., a
   one-time config fix) can be closed. Items that remain open carry into
   the next session.

4. **At milestone boundary:** The milestone-close checklist (see
   § Verification & Continuous Distillation) now includes: "Any new or
   escalated skill opportunities this milestone?"

### Relationship to distillation

Skill opportunity tracking feeds into Phase 6 distillation but operates
independently:

- **Skill opportunities** are forward-looking: "we need a skill for X."
- **Distillation** is backward-looking: "we learned Y, does it generalize?"
- A RED/BLACK skill opportunity that gets a candidate skill drafted goes
  through the same promotion review as any other `skills-candidates/` entry.
- A skill opportunity resolved by an existing skill update (rather than a
  new candidate) just gets closed with a note pointing to the updated skill.

---

## Self-Documentation Mandate

These artifacts must capture enough detail that a distilled skill can
reproduce the methodology, not just its output:

- `decisions.md` — every ADR, including *why* the path was chosen and *what
  alternatives were rejected*, not just outcomes. Durable preferences also
  get a memory entry.
- `blockers.md` — full lifecycle of each blocker: filing, research notes,
  chosen solution, implementation outcome, retrospective tag (was-it-truly-
  a-blocker / could-it-have-been-prevented).
- `workstreams.md` — actual parallelism levels hit per phase, conflicts
  encountered, re-dispatch events.
- `process-journal.md` — short orchestrator notes per session: what was
  dispatched, what came back, what surprised us, and any flagged
  distillation candidates pending their next trigger.
- `skill-opportunities.md` — friction log: every unplanned user return,
  repeated correction, or manual process, severity-tracked from NOTED
  through BLACK. The primary early-workflow automation radar.

---

## Session Data Capture

Every orchestrator session generates valuable data that should be captured
for future skill building. At session end (or when pausing a project):

1. **Harvest session transcript** — Claude Code stores transcripts at
   `~/.claude/projects/<project-slug>/<session-id>.jsonl`. These contain
   the full conversation including all agent dispatches and results.

2. **Extract lessons learned** — Before closing, review:
   - What processes were repeated and could be automated?
   - What corrections did the user make? (These become feedback memories)
   - What worked surprisingly well? (These become skill candidates)
   - What failed and how was it resolved? (These become gotchas/pitfalls)

3. **Update skills immediately** — Don't defer skill updates to "later."
   If a pattern proved itself during this session, update the relevant
   skill file NOW while the context is fresh. Stale learnings are lost
   learnings.

4. **Log session summary** — Append to `planning/process-journal.md`:
   - Session date
   - Agents dispatched (count and types)
   - Blockers hit and how resolved
   - Skills updated or candidates created
   - User corrections (what was rejected/approved)

5. **Capture agent permission patterns** — If agents were blocked by
   permission denials, note which tools they needed and for what purpose.
   This informs future permission configuration and agent scoping.

---

## Critical Files Created Now vs Later

**Now (this plan file only — plan mode):**
- `~/.claude/plans/<plan-name>.md` ← this doc

**At Phase 1 kickoff (after the user starts dumping):**
- `~/Documents/<project>/planning/spec.md`
- `~/Documents/<project>/planning/blockers.md`
- `~/Documents/<project>/planning/workstreams.md`
- `~/Documents/<project>/planning/decisions.md`
- Project-specific memory dir under `~/.claude/projects/<slug>/memory/`

**At build kickoff:** version control initialized inside
`~/Documents/<project>/`, planning docs move into `/docs`.

---

## What This Plan Is NOT

- Not the project's actual spec — that emerges in Phase 1.
- Not an approach/stack pick — that emerges in Phase 2.
- Not a timeline — work is event-driven, not date-driven.
