# Brain Dump Triage

Defines how Discovery Loop step 2 turns a raw, unstructured brain dump into
the spec scaffold, before any gap-filling questions get asked in step 3.

---

## What this handles

Raw brain dumps are rarely clean. Expect:

- Non-linear ordering — ideas about features, users, and constraints
  interleaved randomly.
- Restatements — the same point made more than once, sometimes with added
  or changed detail.
- Contradictions — different parts of the dump imply different intent for
  the same area.
- Mixed specificity — some areas described in detail, others mentioned in
  passing or not at all.
- Tangents — asides that aren't part of defining the project.

---

## Process

1. **Segment into idea units.** Break the dump into atomic statements — one
   idea per unit — regardless of how it was originally phrased. Preserve
   the original wording rather than paraphrasing yet; this step is
   splitting, not editing.
2. **Sort into scaffold categories.** Assign each idea unit to one of:
   problem, users, features, flows, data/content model, requirements,
   constraints. If a unit doesn't fit cleanly, it goes to **Unsorted** —
   never force-fit it just to clear the bucket.
3. **Merge true restatements.** When two or more idea units in the same
   category clearly describe the same thing, merge them into one. If a
   later unit adds new detail or contradicts an earlier one, don't silently
   treat the newer one as authoritative — keep both and flag it.
4. **Flag conflicts.** Any category containing idea units that can't both
   be true becomes a numbered open question, not a judgment call made on
   the user's behalf.
5. **Flag empty categories.** A scaffold category with zero idea units
   after sorting is a gap, not an assumption to fill in quietly.
6. **Keep unsorted items visible.** Don't discard anything that didn't fit
   a category — list it for the user to call as in-scope, out-of-scope, or
   noise.

---

## Output: the triage doc

Same seven headings as the scaffold, plus two more:

- Problem
- Users
- Features
- Flows
- Data/content model
- Requirements
- Constraints
- Unsorted / Unclear
- Open Questions — every conflict, empty category, and unsorted item that
  needs a scope call

The Open Questions list is the literal input to Discovery Loop step 3's
batched gap-filling questions — nothing in it gets resolved here.

---

## Re-running mid-Discovery

If more brain-dump content arrives after a triage doc already exists (a
follow-up dump, not the first one), run the same procedure on the new
material and diff it against what's already sorted — new idea units either
confirm, extend, or conflict with existing entries. Conflicts get flagged
the same way as in a first pass, never silently overwritten.

---

## Who runs this

Orchestrator runs it directly for most dumps. For long or unusually tangled
ones, dispatch a **Discovery agent** (see Agent Roles) with this file as
its instructions — same procedure either way, so the output is always the
same shape going into `spec.md`.

---

## Lifecycle

The triage doc is a working artifact, not a permanent one. Once `spec.md`
is drafted from it and locked (Discovery Loop step 5), the triage doc can
be discarded or kept in `planning/` as a record — not required either way.
