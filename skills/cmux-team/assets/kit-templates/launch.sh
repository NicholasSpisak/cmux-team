#!/usr/bin/env bash
# Launcher for the cmux team — objective: __OBJECTIVE__
# Review .cmux-team/__SLUG__/ before running. This opens cmux (cold-starting the
# app if needed) and boots the LEAD, which then spawns the worker panes itself.
set -euo pipefail
cmux new-workspace --name "team:__SLUG__" --cwd "$(pwd)" \
  --command 'claude --dangerously-skip-permissions --model __LEAD_MODEL__ --append-system-prompt-file .cmux-team/__SLUG__/lead.md "Bootstrap your team now, per your system prompt."'
