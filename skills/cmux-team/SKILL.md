---
name: cmux-team
description: "Design the optimal multi-agent cmux team for a coding objective, generate a launch kit — a one-line cmux launcher plus lead and worker system-prompt files — then, once you confirm, launch it: cmux opens and the lead boots an observable team of agents in named panes (roster — role, model, thinking level, count — plus topology, coordination protocol, rubric, and constraints). It always asks before spending execution tokens, and never does the team's work itself. Use to staff any non-trivial coding objective; for trivial tasks it recommends a team of one."
---

# cmux Team — the staffing planner & launcher

You STAFF the team, then launch it on the human's go-ahead. Given a coding objective,
produce a reviewable, executable **launch kit** under `.cmux-team/<slug>/` — a one-line
launcher plus lead + worker prompts — present the roster, and **ask before launching**.
On confirmation you run the launcher yourself so the human never types a command.

**You never do the team's work.** You do not implement, edit code, or merge. After the
launcher runs, the LEAD agent owns delegation, judging, and synthesis — you stop.
What you plan follows the installed `[[cmux-workspace]]` conventions (worktree isolation,
`--focus false`, additive layout, caller scoping).

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

## Move 4 · Generate the launch kit
Create `.cmux-team/<slug>/` (slug = dash-case of the objective) by substituting
the roster into the templates in `assets/kit-templates/`:
- **`launch.sh`** — the one-line `cmux new-workspace --command 'claude … --append-system-prompt-file .cmux-team/<slug>/lead.md …'` launcher. `__LEAD_MODEL__` = the lead's model from `references/staffing-heuristics.md` (use `opus[1m]` for the opus lead).
- **`lead.md`** — the lead system prompt: fill `__SPAWN_STEPS__` with one spawn block per worker (from `references/orchestration-recipe.md` §1), `__ROSTER_TABLE__`, and the pattern/count. It already embeds the handshake protocol, observability wiring, and rubric.
- **`worker-<role>.md`** — one per teammate from `worker.md`, with `__TASK__`, `__MODEL__`, `__THINKING__`, and the worktree/branch for implementers.
- **`roster.md`** — the human-readable roster + launch instructions.

Substitute EVERY `__TOKEN__`. Use only cmux verbs present in
`references/orchestration-recipe.md` / the live CLI. Tell the operator to add
`.cmux-team/` to their repo's ignore rules; do not edit their `.gitignore` yourself.

## Move 5 · Confirm, then launch
Print the roster table and where the kit lives (`.cmux-team/<slug>/`). Then **ask the
human to confirm**: *"Launch this team? Review the roster / kit first; reply yes to
launch."* Planning is cheap, execution is where cost lives — never skip this gate.

**Do NOT launch until the human says yes. Never launch on your own initiative.**

Once they confirm, YOU run the launcher — the human should not have to type a command:

```bash
cmux ping                       # preflight: is this shell a trusted cmux caller?
bash .cmux-team/<slug>/launch.sh
```

**Preflight matters.** cmux's socket only answers a trusted caller. `cmux ping` exits
non-zero (`Failed to write to socket (Broken pipe)`) when it is not — typically because
the agent is running *outside* a cmux terminal surface. Check the exit code, not the text.

- **`cmux ping` succeeds** → run `bash .cmux-team/<slug>/launch.sh`. cmux opens the
  `team:<slug>` workspace, the lead boots and spawns each worker into its own named pane.
  Then report what came up and stop; the lead drives the work from there.
- **`cmux ping` fails** → do NOT retry blindly. Explain that this shell is not a trusted
  cmux caller, print the one-line launcher for the human to run themselves, and offer the
  two fixes: run the coding agent from **inside a cmux terminal surface** (so
  `CMUX_WORKSPACE_ID`/`CMUX_SURFACE_ID` are inherited), or set a socket password
  (`CMUX_SOCKET_PASSWORD`, or `socketPassword` in `~/.config/cmux/cmux.json`).

**Never merge, and never do the team's work yourself.** After launching, the lead owns
delegation, judging, and synthesis; you stop.

**Non-disruptive note.** Launching a visible team workspace is the operator's explicit
ask, so `launch.sh` opts into focus for the top-level team workspace. Every worker split
still passes `--focus false` and layout stays additive — never `select-workspace` or
`focus-pane` speculatively (see `[[cmux-workspace]]`).

## References
| Reference | When to use |
|---|---|
| `references/staffing-heuristics.md` | Move 2–3: patterns, model/thinking/count table, rubric |
| `references/cmux-verbs.snapshot.md` | Move 0/4: available cmux CLI verbs & flags |
| `references/cmux-docs.snapshot.md` | Move 0/4: cmux docs topics & official skill list |
| `assets/example-plan.md` | A full worked example of the deliverable |
| `references/orchestration-recipe.md` | Move 4: verified cmux spawn/coordinate/observe sequences the lead runs |
| `assets/kit-templates/` | Move 4: lead / worker / launch.sh / roster templates to fill in |
