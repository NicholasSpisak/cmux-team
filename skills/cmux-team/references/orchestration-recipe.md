<!--
Captured-From: cmux --help (verbs) + live-CLI verification per spec §8
Captured-cmux-version: cmux 0.64.17 (97) [9ed29d81a]
Captured-Date: 2026-07-07
Hand-authored recipe grounded in cmux-verbs.snapshot.md; re-verify against the
live CLI (spec §8) whenever this goes stale, then bump the version above.
-->

# cmux orchestration recipe — how the LEAD bootstraps & runs its team

Every verb below appears in `cmux-verbs.snapshot.md`. Never add a verb/flag that
does not. All refs (`surface:N`, `pane:N`) come from `cmux identify --json` /
`cmux list-panes --json`; never hardcode them.

## 0. Locate self
```bash
cmux identify --json           # own workspace + surface refs
# CMUX_WORKSPACE_ID / CMUX_SURFACE_ID are auto-set in cmux terminals and are the
# default --workspace / --surface for every command.
```

## 1. Spawn one worker (repeat per roster row)
```bash
# Implementers get an isolated worktree; reviewers/scaffolders usually do not.
git worktree add "../__WORKTREE__" -b "__BRANCH__" 2>/dev/null || true

# Additive split; do NOT steal focus.
NEW=$(cmux new-split down --focus false)          # capture the new surface ref
cmux rename-tab --surface "$NEW" "__ROLE__"       # name the pane by role

# Boot the agent into that surface (send-boot = full control of model+prompt):
cmux send --surface "$NEW" 'claude --model __MODEL__ --append-system-prompt-file .cmux-team/__SLUG__/worker-__ROLE__.md'
cmux send-key --surface "$NEW" enter
# Codex worker variant:
#   cmux send --surface "$NEW" 'codex --model gpt-5-codex --append-system-prompt-file .cmux-team/__SLUG__/worker-__ROLE__.md'
#   cmux send-key --surface "$NEW" enter
```

## 2. Handshake protocol
- Each worker prints `ready:<role>` once booted, then waits.
- Lead delegates: `cmux send --surface "$NEW" '<task>'` then `cmux send-key --surface "$NEW" enter`.
- Worker prints `DONE:<role>` on success, or `BLOCKED:<role> <reason>` if stuck.
- Lead observes: `cmux read-screen --surface "$NEW" --lines 40` (poll) and/or
  `cmux events --name agent.hook` (push).

## 3. Observability wiring (call on every transition)
```bash
cmux set-status "__ROLE__" "ready"    --icon circle       --color '#6b7280' --priority 1
cmux set-status "__ROLE__" "working"  --icon play.circle   --color '#2563eb' --priority 2
cmux set-status "__ROLE__" "done"     --icon checkmark     --color '#16a34a' --priority 3
cmux set-status "__ROLE__" "blocked"  --icon exclamationmark --color '#dc2626' --priority 4
cmux set-progress 0.6 --label "__ROLE__: building"
cmux notify --title "__ROLE__ → DONE" --body "task complete"
```

## 4. Judge → synthesize → verify → teardown
- Score builds blind to provenance on the rubric (below), synthesize best-of, verify.
- Present results to the human. **No merge without human approval.**
- On teardown: `cmux clear-status "__ROLE__"` and `cmux clear-progress` per worker.

## Rubric (lead scores blind)
correctness · edge cases · readability · test coverage · blast radius · idiomatic fit.
