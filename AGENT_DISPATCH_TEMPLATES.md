# Agent Dispatch Templates

> Companion to OPERATING_MANUAL.md. Implements the two optimizations chosen
> after researching the token-cost question:
>
> - **(A) Curate context, don't compress phrasing.** Point each sub-agent at
>   specific files instead of pasting whole documents, and scope every
>   dispatch to exactly one workstream. This is where the actual token cost
>   lives — volume, not wording density.
> - **(D) Reuse a fixed skeleton instead of re-deriving prompt structure each
>   time.** The boilerplate (role, ownership, blocker/collision rules, report
>   format) never changes; only the blanks do.
>
> Deliberately **not** doing: compressing the TASK field itself into
> telegraphic or rigid-schema form. Research on structured-format
> instructions found measurable reasoning-accuracy loss when judgment-heavy
> content gets forced into a strict schema — and the actual task description
> is exactly the part of a dispatch where the sub-agent has to reason, not
> just look something up. Everything *except* the TASK field below is safe to
> keep label-terse; TASK stays full sentences.

---

## Dispatch-First Principle

Before taking any action that isn't reading/planning/git/status-checking,
ask: "Should this be an agent?" The answer is almost always yes.

**Decision tree:**
1. Is this a source code edit? → AGENT
2. Is this a build/test/install command? → AGENT
3. Is this research requiring >3 queries? → AGENT
4. Could this take >2 minutes? → AGENT
5. Is this orchestration housekeeping? → DO IT YOURSELF

When in doubt, dispatch. The cost of over-delegating (slightly more agent
overhead) is far lower than the cost of under-delegating (bogged-down
orchestrator, lost parallelism, bloated context window).

**Permission scoping for agents:** Agents may need Edit/Write/Bash
permissions that the orchestrator's hooks would warn on. This is expected —
the delegation check hook targets the orchestrator process, not sub-agents.
If agents are blocked by permissions, note this in the session summary for
future configuration.

---

## How to use this

1. Copy the skeleton for the role you're dispatching.
2. Fill every `{blank}`. Don't add prose around the skeleton's own
   structure — the structure *is* the optimization.
3. In **READ**, list specific files (line ranges where you can). Never
   "read the whole planning/ folder." If a file isn't load-bearing for this
   exact task, leave it out — that's the scope-curation discipline, applied
   per dispatch, not just at the project level.
4. **TASK** is the one field written in full natural sentences. It's where
   the agent reasons, not where it looks things up.

---

## Generic skeleton

```
ROLE: {discovery | research | builder | reviewer | tester | documenter}
WORKSTREAM: {id from workstreams.md}

READ (pointers only, not pasted content):
- {path} — {why this file, <10 words}
- {path} — {why}

YOU OWN: {paths/globs this agent may create or freely edit}
YOU MAY APPEND TO: {shared files — append-only, see collision protocol}
DO NOT TOUCH: {paths owned by other concurrent workstreams}

TASK:
{Plain-language paragraph: what to do, why, and any edge cases or judgment
calls this agent will hit. Full sentences — this is the part that benefits
from clarity, not brevity.}

DONE WHEN:
- {criterion}
- {criterion}

ON COLLISION: pull latest before your final commit. Shared files are
append-only — never delete or rewrite another agent's additions. If
something's already there when you go to commit, rebase onto it; don't
treat it as an incident.

ON BLOCKER: file it in blockers.md ({id, summary, context, attempted,
owner_agent, status}). Hard blocker (needs user judgment, access, or
money) → flag it in your report instead of guessing or stalling.

REPORT BACK: Running / Blockers / Next, 1-3 lines, per OPERATING_MANUAL.md
§ Orchestrator Status Reporting.
```

---

## Role-specific notes

### Research agent
- **READ** points at the specific blocker or open question only — not the
  full spec.
- **TASK** ends with a named output path (e.g. `planning/<topic>-research.md`),
  not just "write a doc."
- **DONE WHEN** always includes that alternatives considered and rejected are
  documented, not just the pick — that's what makes it usable as an ADR
  source later.

### Builder agent
- **YOU OWN** should match the workstream's file list in `workstreams.md`
  verbatim — copy it, don't re-derive it from the task description.
- **TASK** names the milestone this workstream serves, so the agent knows
  what "done" means in product terms, not just file-completion terms.

### Reviewer agent
- **READ** is the one section that's deliberately broad — a reviewer needs
  to see what actually changed, so point at the diff/commits in scope rather
  than a curated subset.
- **YOU OWN** is empty. Reviewers are read-only; they produce a report, not
  code.
- **DONE WHEN** is always "report filed with severity-tagged findings,"
  never "issue fixed."

### Tester agent
- **TASK** references the functionality-test-doc this run executes (per
  Testing Protocol) — link it, don't restate its contents.
- **REPORT BACK** uses the test-doc's own report shape (PASS/FAIL per case),
  not the generic Running/Blockers/Next line.

### Documenter agent
- State explicitly whether this dispatch is routine upkeep (keeping
  spec/blockers/workstreams current), a **distillation pass** (drafting
  candidates), or a **promotion review** (see OPERATING_MANUAL.md §
  Verification & Continuous Distillation) — each has different DONE WHEN
  criteria.
- Distillation dispatch: **READ** = the delta since the last distillation
  pass only, not full project history. **YOU OWN** = `skills-candidates/`
  only — never the shared skills repo. **DONE WHEN** = "candidate drafted
  in skills-candidates/, an existing candidate updated, or explicitly
  logged as project-specific and skipped" — one of those three, not
  silence.
- Promotion-review dispatch (project wrap, or on request): **READ** =
  `skills-candidates/` + `process-journal.md`. **TASK** = write a short
  report per candidate — what it captures, where it got used, any signal it
  generalizes — for the user to decide on. **DONE WHEN** = "report
  delivered"; the documenter agent never copies a candidate into the shared
  repo itself, the user picks first.

### Discovery agent
- Used sparingly. **TASK** is almost always "structure this raw dump into a
  spec section." The raw dump itself is the one thing worth pasting in full
  rather than pointing at — it's new content, not yet living in any file.
