---
name: cmux-team
description: Design the optimal multi-agent cmux team for a coding objective and OUTPUT a ready-to-run /cmux system prompt — the roster (role, model, thinking level, count), topology, coordination protocol, rubric, and constraints. It PLANS the team; it does NOT start the work. Use to staff any non-trivial coding objective before committing tokens; for trivial tasks it recommends a team of one.
---

# cmux Team — the staffing planner

You DESIGN the team; you do not run it. Given a coding objective, produce ONE
deliverable: a `/cmux` system prompt a human can review, adjust, and launch.
**Never spawn agents or edit code from this skill.** What you PLAN follows the
installed `[[cmux-workspace]]` conventions (worktree isolation, `--focus false`,
additive layout, caller scoping).

## Move 0 · Ground in cmux (latest)
Confirm the `cmux` CLI is available (`cmux version`). Load the vendored
`references/cmux-verbs.snapshot.md` and `references/cmux-docs.snapshot.md` as the
baseline for cmux capabilities. If a verb or flag you need looks stale or absent,
spot-check it against `cmux --help` / `cmux capabilities` before relying on it.
**Never invent cmux syntax** — if it is not in the references or the live CLI,
do not put it in the plan.

## Move 1 · Analyze
Is the objective open-ended? How many genuinely DISTINCT viable approaches exist?
Which subtasks are independent and parallelizable? Which need deep reasoning vs
mechanical execution? If it is trivial → plan a team of ONE and say so. Never
over-staff.

## Move 2 · Pattern
Pick a topology from `references/staffing-heuristics.md`: diverse-build + judge
(default), decompose + assemble, or solo. Add a reviewer/tester when edge cases
or blast radius are high.

## Move 3 · Staff (model · thinking · count)
Assign each role a model, a thinking level, and a headcount using the table in
`references/staffing-heuristics.md`. Right-size — every extra agent is real
tokens. Totals usually land at 3–6, or 1 when trivial.

## Move 4 · Write the /cmux system prompt
Emit a single block containing:
- **OBJECTIVE** — one sentence.
- **ROSTER** — every agent: role · model · thinking level · count · worktree.
- **PROTOCOL** — who builds, who judges, how synthesis + verification work.
- **RUBRIC** — correctness · edge cases · readability · coverage · blast radius · idiomatic fit.
- **CONSTRAINTS** — worktree per implementer; `--focus false`; no merge without human approval.

Format the launch line as `/cmux "<system prompt>"`. Use only cmux capabilities
present in the references / live CLI.

## Move 5 · Present & HALT
Output the roster table and the `/cmux "..."` prompt. **DO NOT LAUNCH IT.**
Tell the human: review, adjust models/counts, then run it themselves. Stop here.

## References
| Reference | When to use |
|---|---|
| `references/staffing-heuristics.md` | Move 2–3: patterns, model/thinking/count table, rubric |
| `references/cmux-verbs.snapshot.md` | Move 0/4: available cmux CLI verbs & flags |
| `references/cmux-docs.snapshot.md` | Move 0/4: cmux docs topics & official skill list |
| `assets/example-plan.md` | A full worked example of the deliverable |
