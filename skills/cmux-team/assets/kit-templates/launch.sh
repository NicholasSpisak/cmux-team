#!/usr/bin/env bash
# Launcher for the cmux team — objective: __OBJECTIVE__
# Review .cmux-team/__SLUG__/ before running.
#
# Creates a NEW workspace ("team:__SLUG__") in the CURRENT window, alongside the
# human's own workspace, and boots the LEAD into it. The lead then spawns one pane
# per worker inside that workspace. The human's workspace is never touched.
#
# Two quoting rules are load-bearing here (see references/orchestration-recipe.md):
#   1. --command is re-parsed by the pane's interactive shell, so the model alias
#      MUST stay quoted or zsh globs [1m] → "no matches found: opus[1m]".
#   2. The lead prompt path must be absolute — the lead's cwd is the repo root, but
#      workers `cd` into worktrees that do not contain the untracked .cmux-team/ kit.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$KIT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

command -v cmux >/dev/null 2>&1 || { echo "error: cmux CLI not found on PATH" >&2; exit 1; }
cmux ping >/dev/null 2>&1 || {
  echo "error: this shell is not a trusted cmux caller (cmux ping failed)." >&2
  echo "       Run from inside a cmux terminal surface, or set CMUX_SOCKET_PASSWORD." >&2
  exit 1
}

# Focus the new team workspace by default (a visible team is the point). Export
# CMUX_TEAM_FOCUS=false to launch it in the background and keep your own workspace.
FOCUS="${CMUX_TEAM_FOCUS:-true}"

OUT=$(cmux new-workspace \
  --name "team:__SLUG__" \
  --cwd "$REPO_ROOT" \
  --focus "$FOCUS" \
  --command 'claude --dangerously-skip-permissions --model "__LEAD_MODEL__" --append-system-prompt-file '"'$KIT_DIR/lead.md'"' "Bootstrap your team now, per your system prompt."')

# cmux prints `OK workspace:N` — parse the ref, never use the whole line as a handle.
WS=$(printf '%s' "$OUT" | grep -oE 'workspace:[0-9]+' | head -1)
echo "team workspace: ${WS:-$OUT}"
echo "watch it with:  cmux tree --workspace ${WS:-<ref>}"
