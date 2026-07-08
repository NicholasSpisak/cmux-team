<!--
Captured-From: live `cmux --help` + `cmux <verb> --help` + executed socket calls on a real cmux surface.
Captured-cmux-version: cmux 0.64.17 (97) [9ed29d81a]
Captured-Date: 2026-07-08
EVERY sequence below was executed against a live cmux socket and its real output pasted
in. Re-verify with scripts/smoke.sh whenever cmux changes, then bump the version above.
-->

# cmux orchestration recipe — how the LEAD bootstraps & runs its team

## 0. The layout you are building

Two panes. Not one pane per worker — that tiles into confetti the moment you have four
of them. Workers are **tabs in one pane**, so the human clicks a name and sees that
worker's entire scrollback, full height.

```
window                                  ← one OS window, shared with the human
├── workspace "Human"                   ← the human's. NEVER touch it.
└── workspace "team:<slug>"             ← the LEAD's own workspace
    ├── pane (left)  ── surface "lead"        ← the lead's terminal
    │                └─ surface "roster.md"   ← live markdown panel: roster + status
    └── pane (right) ── surface "anchor-a"    ← one TAB per worker
                     ├─ surface "anchor-b"
                     ├─ surface "offers"
                     └─ surface "verifier"
```

- **window > workspace > pane > surface.** A *surface* is a tab inside a pane.
- **Panels** are surfaces seen through `list-panels` / `focus-panel` / `send-panel`.
  `cmux markdown open <path>` makes a live-reload markdown panel.
- The human's three jobs — *what is the team doing*, *what is one worker doing*, *is it
  finished* — map to: the roster panel + status board, clicking a worker tab, and the
  status icons going green.

Real `cmux tree` from this layout:

```
window window:1 [current]
└── workspace workspace:17 "team:demo"
    ├── pane pane:42 [focused]
    │   ├── surface surface:44 [terminal] "lead"
    │   └── surface surface:48 [markdown] "roster.md" [selected]
    └── pane pane:43
        ├── surface surface:45 [terminal] "anchor-a" tty=ttys018
        ├── surface surface:46 [terminal] "anchor-b" tty=ttys019
        └── surface surface:47 [terminal] "offers" [selected] tty=ttys020
```

## 1. Four rules that make or break every sequence

### Rule 1 — Never `$(...)`-capture a cmux ref. Parse it.
Each verb prints a *different* `OK` line. Verified:

```
cmux new-workspace …  →  OK workspace:8
cmux new-split down …  →  OK surface:18 workspace:8            # no pane ref!
cmux new-pane …        →  OK surface:17 pane:17 workspace:8
cmux new-surface …     →  OK surface:20 pane:17 workspace:8
cmux markdown open …   →  OK surface=surface:48 pane=pane:44 path=…
```

`NEW=$(cmux new-split down)` yields the literal string `OK surface:18 workspace:8`,
and every later `--surface "$NEW"` then dies with
`Error: Invalid surface handle: OK surface:18 workspace:8`. Always extract:

```bash
# Pull a typed ref out of any cmux OK line, regardless of field order or count.
cref() { printf '%s' "$1" | grep -oE "$2:[0-9]+" | head -1; }
```

### Rule 2 — `rename-tab` is workspace-scoped. Pass `--workspace`.
`send`, `send-key`, and `read-screen` resolve a bare `surface:N` globally.
`rename-tab` / `tab-action` resolve the tab **inside `$CMUX_WORKSPACE_ID`**. Verified:

```
cmux rename-tab --surface surface:17 "anchor-a"                    → Error: not_found: Tab not found
cmux rename-tab --workspace workspace:8 --surface surface:17 "anchor-a"
                                                                    → OK action=rename tab=tab:17 workspace=workspace:8
```

### Rule 3 — Quote model aliases. Set cwd with a flag, not `cd`.
`--command` and `cmux send` hand their string to an **interactive shell** to re-parse.
zsh globs `[1m]`:

```
% claude --model opus[1m] …    → zsh: no matches found: opus[1m]
% claude --model "opus[1m]" …  → boots
```

Give a worker its worktree with `new-surface --working-directory <path>` rather than
prefixing `cd …` onto the boot line. Fewer quotes, and the tab's title/cwd are right
even before the agent starts.

Worker prompt paths must be **absolute**. A worker's cwd is a fresh git worktree, which
does not contain the untracked `.cmux-team/` kit; a relative
`--append-system-prompt-file .cmux-team/…` resolves to nothing there.

### Rule 4 — Workers NEVER type into the lead's terminal.
Three workers reporting at once corrupt each other's keystrokes. Verified — three
concurrent `cmux send` calls into one surface produced:

```
% echo REPORT:w1echo REPORT:w2echo REPORT:w3
```

Report through the two race-free channels in §4 instead.

### Rule 5 — Shell variables DO NOT survive between the lead's tool calls.
The lead is an agent. Each `Bash` tool call it makes is a **fresh shell**: `$WS`,
`$WPANE`, `$SURF_*` are all empty in the next block. A recipe that assumes otherwise
silently spawns surfaces with an empty `--pane`, renames the wrong tab, and drops workers.
Persist every ref to a file and re-source it at the top of every block (§2).

Also avoid `eval "$(… python3 -c '…')"` in emitted shell — the nested quoting gets eaten
as it passes through the agent, the tool call, and the interactive shell. Parse cmux's
JSON with `sed`/`grep`. No quotes to lose.

## 2. Locate self — and persist it

`cmux identify --json` emits a `caller` block, then a `focused` block. Take the first.
Write a `lib.sh` that every later block sources. **This is the fix for Rule 5.**

```bash
KIT="$PWD/.cmux-team/__SLUG__"; RUN="$KIT/run"; mkdir -p "$RUN"
: > "$RUN/journal.ndjson"; : > "$RUN/refs.env"

cat > "$RUN/lib.sh" <<'LIB'
# Sourced at the top of EVERY spawn block. Re-establishes refs in a fresh shell.
cref()   { printf '%s' "$1" | grep -oE "$2:[0-9]+" | head -1; }
savref() { printf '%s=%s\n' "$1" "$2" >> "$TEAM_RUN/refs.env"; }
[ -f "$TEAM_RUN/refs.env" ] && . "$TEAM_RUN/refs.env"
LIB

export TEAM_RUN="$RUN"
. "$RUN/lib.sh"

ID=$(cmux identify --json)
CALLER=$(printf '%s' "$ID" | sed -n '/"caller"/,/}/p')   # first block only
savref WS        "$(cref "$CALLER" workspace)"
savref LEAD_PANE "$(cref "$CALLER" pane)"
savref LEAD_SURF "$(cref "$CALLER" surface)"
savref KIT       "$KIT"
. "$RUN/refs.env"

cmux rename-tab --workspace "$WS" --surface "$LEAD_SURF" "lead"
```

Every subsequent block starts with exactly these two lines:

```bash
export TEAM_RUN="$PWD/.cmux-team/__SLUG__/run"; . "$TEAM_RUN/lib.sh"
```

and ends by `savref`-ing anything the next block needs (`WPANE`, `SURF_<ROLE>`, …).

`CMUX_WORKSPACE_ID` / `CMUX_SURFACE_ID` are auto-set in cmux terminals and are the
default `--workspace` / `--surface` for every command — but they are UUIDs, and they tell
you nothing about the *worker* surfaces you created. Persist your own refs.

## 3. Build the layout, then spawn workers into it

Create the workers pane **once**, in its own block, and persist its ref.

```bash
export TEAM_RUN="$PWD/.cmux-team/__SLUG__/run"; . "$TEAM_RUN/lib.sh"

OUT=$(cmux new-pane --workspace "$WS" --direction right --focus false)
savref WPANE      "$(cref "$OUT" pane)"
savref FIRST_SURF "$(cref "$OUT" surface)"   # reuse for worker #1 — do not orphan it
```

Then one block per roster row (`__ROLE__`, `__MODEL__`, `__WORKTREE__`, `__BRANCH__`).
Every block re-sources `lib.sh`, so it works in a fresh shell (Rule 5).

```bash
export TEAM_RUN="$PWD/.cmux-team/__SLUG__/run"; . "$TEAM_RUN/lib.sh"
git worktree add "../__WORKTREE__" -b "__BRANCH__" 2>/dev/null || true

# Worker #1 claims $FIRST_SURF; workers #2..N get a new TAB in the same pane.
if [ -n "${FIRST_SURF:-}" ]; then
  SURF="$FIRST_SURF"
  savref FIRST_SURF ""                       # consumed — later blocks see it empty
  cmux send --surface "$SURF" "cd '$PWD/../__WORKTREE__'"; cmux send-key --surface "$SURF" enter
else
  OUT=$(cmux new-surface --workspace "$WS" --pane "$WPANE" --type terminal \
        --working-directory "$PWD/../__WORKTREE__" --focus false)
  SURF=$(cref "$OUT" surface)
fi
savref SURF___ROLE_UPPER__ "$SURF"

cmux rename-tab --workspace "$WS" --surface "$SURF" "__ROLE__"
cmux set-status "__ROLE__" "booting" --workspace "$WS" --icon circle --color '#6b7280' --priority 1

# Boot. Alias quoted (Rule 3); kit path absolute; role + refs exported so the worker
# can report home (§4) without guessing anything.
cmux send --surface "$SURF" "export CMUX_TEAM_ROLE=__ROLE__ CMUX_TEAM_WS=$WS CMUX_TEAM_RUN='$TEAM_RUN' && claude --dangerously-skip-permissions --model \"__MODEL__\" --append-system-prompt-file '$KIT/worker-__ROLE__.md'"
cmux send-key --surface "$SURF" enter

# Codex variant — codex has no system-prompt-file flag; the role prompt is positional,
# and --dangerously-bypass-approvals-and-sandbox is its autonomy flag:
#   cmux send --surface "$SURF" "export CMUX_TEAM_ROLE=__ROLE__ CMUX_TEAM_WS=$WS CMUX_TEAM_RUN='$TEAM_RUN' && codex --model \"__MODEL__\" --dangerously-bypass-approvals-and-sandbox \"\$(cat '$KIT/worker-__ROLE__.md')\""
#   cmux send-key --surface "$SURF" enter
```

`savref` is what makes `$SURF_<ROLE>` available to the delegation and judging blocks that
run in later, unrelated shells. Never rely on a variable set in a previous block.

Finally, dock the roster as a live panel in the **lead's** pane. `markdown` has no
`--workspace` flag — it opens a new pane in the caller's workspace — so move it:

```bash
OUT=$(cmux markdown open "$KIT/roster.md" --focus false)
MD=$(cref "$OUT" surface)
cmux move-surface --surface "$MD" --workspace "$WS" --pane "$LEAD_PANE" --focus false
```

Confirm before delegating: `cmux tree --workspace "$WS"` must show exactly two panes —
the lead pane with `lead` + `roster.md`, and the workers pane with one tab per role.

## 4. Reporting protocol — how a worker reports home

Two channels, both race-free (Rule 4). Every worker's system prompt tells it to use them.

**Channel A — the journal (content).** One line, appended atomically. Short single-line
`>>` appends never interleave; verified with five concurrent writers → five clean lines.

```bash
# run by the WORKER, on every state change
printf '{"role":"%s","state":"%s","note":"%s"}\n' "$CMUX_TEAM_ROLE" done "4 files, gates green" \
  >> "$CMUX_TEAM_RUN/journal.ndjson"
```

**Channel B — the signal (wake-up).** `cmux wait-for` is a real cross-process
synchronization token. Verified: lead blocked, worker signalled, lead woke in 2s.

```bash
# WORKER, when finished:
cmux set-status "$CMUX_TEAM_ROLE" "done" --workspace "$CMUX_TEAM_WS" --icon checkmark --color '#16a34a' --priority 3
cmux wait-for -S "done:$CMUX_TEAM_ROLE"
cmux notify --title "$CMUX_TEAM_ROLE → DONE"

# LEAD, to block on one worker (default timeout 30s — always pass --timeout):
cmux wait-for "done:anchor-a" --timeout 3600

# LEAD, to see everything at once:
cat "$RUN/journal.ndjson"
cmux list-status --workspace "$WS"
```

The worker also prints `ready:<role>` / `DONE:<role>` / `BLOCKED:<role> <reason>` on its
own screen, so the human clicking that tab sees the same story. The lead can always fall
back to `cmux read-screen --surface "$SURF" --lines 40`.

## 5. Observe the whole team at once

```bash
cmux tree --workspace "$WS"                          # panes + named tabs
cmux list-panes --workspace "$WS"                    # pane refs + surface counts
cmux list-pane-surfaces --workspace "$WS" --pane "$WPANE"   # the worker tab strip
cmux list-status --workspace "$WS"                   # the status board
cat "$RUN/journal.ndjson"                            # what each worker reported
cmux events --name agent.hook                        # push events
```

## 6. Observability wiring (call on every transition)

All status/progress verbs are workspace-scoped — pass `--workspace "$WS"` so the
human's workspace stays clean.

```bash
cmux set-status "__ROLE__" "booting" --workspace "$WS" --icon circle          --color '#6b7280' --priority 1
cmux set-status "__ROLE__" "working" --workspace "$WS" --icon play.circle      --color '#2563eb' --priority 2
cmux set-status "__ROLE__" "done"    --workspace "$WS" --icon checkmark        --color '#16a34a' --priority 3
cmux set-status "__ROLE__" "blocked" --workspace "$WS" --icon exclamationmark  --color '#dc2626' --priority 4
cmux set-progress 0.6 --label "wave 1: 3/4 done" --workspace "$WS"
```

## 7. Judge → synthesize → verify → teardown

- Score builds blind to provenance on the rubric (below), synthesize best-of, verify.
- Present results to the human. **No merge without human approval.**
- Teardown: `cmux clear-status "__ROLE__" --workspace "$WS"` per worker, then
  `cmux clear-progress --workspace "$WS"`. Leave the panes up so the human can read them.

## 8. The lead does not rewrite its own orders

The kit under `.cmux-team/<slug>/` — `roster.md`, `lead.md`, every `worker-*.md`, the
briefs — is the **human's** artifact. It is the reviewed plan. The lead may write only
inside `run/` (`journal.ndjson`, `refs.env`, `lib.sh`, scratch).

If the plan looks wrong — a worker is redundant, a worktree already holds finished work,
a role has nothing to do — **do not cut the role and edit the roster to match.** Say so,
in your report, and let the human decide. A lead that silently reduces a 5-worker team to
3 and rewrites the roster to describe what it did has destroyed the reviewer's ability to
tell "plan" from "outcome". Observed in the wild; hence this section.

Likewise: never commit, merge, or `git rm` outside a worker's own worktree without the
human saying so. Finding uncommitted work in the tree is a thing to *report*, not to
resolve on your own initiative.

## Rubric (lead scores blind)
correctness · edge cases · readability · test coverage · blast radius · idiomatic fit.

## Verb reference — what actually resolves what

| Verb | Ref it accepts | Workspace-scoped? | Prints |
|---|---|---|---|
| `new-workspace` | — | creates one in the current window | `OK workspace:N` |
| `new-pane` | `--workspace` | yes | `OK surface:N pane:N workspace:N` |
| `new-surface` | `--pane`, `--working-directory` | yes | `OK surface:N pane:N workspace:N` |
| `new-split` | `--workspace`/`--surface` | yes | `OK surface:N workspace:N` (**no pane**) |
| `move-surface` | `--surface` → `--pane` | `--workspace` | `OK surface=… pane=… workspace=…` |
| `rename-tab` | `--surface`/`--tab` | **yes — pass `--workspace`** | `OK action=rename tab=tab:N …` |
| `send` / `send-key` | `--surface` | no (global refs) | `OK surface:N workspace:N` |
| `read-screen` | `--surface` | no (global refs) | screen contents |
| `wait-for [-S]` | — | no (global token) | `OK` |
| `set-status` / `set-progress` | — | `--workspace` | `OK` |
| `markdown open` | — | **caller's workspace; no flag** | `OK surface=… pane=… path=…` |
| `tree` / `list-panes` / `list-panels` / `list-status` | `--workspace` | yes | human-readable map |
| `close-workspace` | `--workspace` | yes | `OK workspace:N` |

Never add a verb or flag that is not in this table or in the live `cmux --help`.
