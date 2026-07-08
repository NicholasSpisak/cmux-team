# Worked example

**Invocation:** `/cmux-team "add rate limiting to the POST /orders endpoint"`

**Deliverable (roster):**

| Role | Model | Thinking | × | Job |
|---|---|---|---|---|
| Lead | `claude-opus-4-8` | high | 1 | Decompose, judge on rubric, synthesize, verify |
| Implementer A | `claude-opus-4-8` | high | 1 | Build in worktree ../ord-a; blind to B |
| Implementer B | `codex · gpt-5.5` | high | 1 | Build in worktree ../ord-b; diverse 2nd approach |
| Reviewer | `claude-sonnet-5` | medium | 1 | Edge-case tests; verify the synthesis |

**Deliverable (launch kit):** `/cmux-team` writes `.cmux-team/rate-limit-orders/`:

```
.cmux-team/rate-limit-orders/
├─ launch.sh            # the one-line launcher (below)
├─ lead.md             # lead: spawn recipe + protocol + rubric + observability
├─ worker-implementer-a.md
├─ worker-implementer-b.md
├─ worker-reviewer.md
└─ roster.md
```

**Launcher (printed to chat, also saved as launch.sh):**

```bash
bash .cmux-team/rate-limit-orders/launch.sh
# → creates workspace "team:rate-limit-orders" in the current window and boots the LEAD:
#   cmux new-workspace --name "team:rate-limit-orders" --cwd "$REPO_ROOT" --focus true \
#     --command 'claude --dangerously-skip-permissions --model "opus[1m]" \
#       --append-system-prompt-file '\''<abs>/lead.md'\'' "Bootstrap your team now, per your system prompt."'
```

The human keeps their own workspace in the same window; the team gets its own. The LEAD
spawns implementer-a, implementer-b, and reviewer into their own **panes** inside the
team workspace (`cmux new-pane --focus false`), names each pane's surface by role
(`cmux rename-tab --workspace "$WS" --surface "$SURF" <role>`), and boots each with
`cmux send` + `cmux send-key enter`. The model alias stays quoted and the worker prompt
path is absolute. `cmux tree --workspace "$WS"` shows the whole team; statuses
(`set-status`/`set-progress`, scoped to `"$WS"`) and `notify` surface progress live.

cmux-team then asks: **"Launch this team?"** Nothing runs until you say yes. On your
go-ahead it runs the launcher for you (after a `cmux ping` preflight) — you never type
a command. If this shell is not a trusted cmux caller, it hands you the line instead.
Once the team is up, the LEAD owns the work; cmux-team stops.
