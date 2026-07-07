<!--
Captured-From: cmux docs (index + topics) ; ls ~/.agents/skills/cmux*
Captured-cmux-version: cmux 0.64.17 (97) [9ed29d81a]
Captured-Date: 2026-07-07
Do not edit by hand; regenerate with scripts/sync-cmux-refs.sh
-->

# cmux docs — vendored snapshot

## `cmux docs`
```
cmux docs

Topics:
  settings   cmux-owned settings, cmux.json locations, schema, and reload flow.
  shortcuts  cmux-owned keyboard shortcuts and two-step chord syntax.
  api        CLI/socket API, handle model, windows, workspaces, panes, and surfaces.
  browser    Browser panel automation commands and snapshot-driven web interaction.
  agents     Agent hook integrations, Feed approvals, notifications, and session restore.
  dock       Custom right-sidebar terminal controls from .cmux/dock.json or ~/.config/cmux/dock.json.
  sidebars   Vibe-code a custom sidebar: a runtime-interpreted SwiftUI-style file in ~/.config/cmux/sidebars/ (beta).

Run `cmux docs <topic>` for URLs, raw resources, and next commands.
```

## `cmux docs api`
```
api: CLI/socket API, handle model, windows, workspaces, panes, and surfaces.

Web:
  https://cmux.com/docs/api

Raw resources:
  CLI contract: https://raw.githubusercontent.com/manaflow-ai/cmux/main/docs/cli-contract.md
  cmux skill: https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux/SKILL.md

Fetch:
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/docs/cli-contract.md
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux/SKILL.md

Useful commands:
  cmux identify --json
  cmux tree --all
```

## `cmux docs agents`
```
agents: Agent hook integrations, Feed approvals, notifications, and session restore.

Web:
  https://cmux.com/docs/agent-integrations/oh-my-codex

Raw resources:
  agent hook docs: https://raw.githubusercontent.com/manaflow-ai/cmux/main/docs/agent-hooks.md
  feed docs: https://raw.githubusercontent.com/manaflow-ai/cmux/main/docs/feed.md
  notifications docs: https://raw.githubusercontent.com/manaflow-ai/cmux/main/docs/notifications.md

Fetch:
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/docs/agent-hooks.md
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/docs/feed.md
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/docs/notifications.md

Useful commands:
  cmux hooks setup
  cmux hooks setup <agent>
  cmux hooks hermes-agent install
  cmux hooks hermes-agent uninstall
  cmux hooks <agent> uninstall
```

## `cmux docs browser`
```
browser: Browser panel automation commands and snapshot-driven web interaction.

Web:
  https://cmux.com/docs/browser-automation

Raw resources:
  browser skill: https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-browser/SKILL.md
  browser commands: https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-browser/references/commands.md

Fetch:
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-browser/SKILL.md
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux-browser/references/commands.md

Useful commands:
  cmux browser --help
  cmux browser snapshot
```

## `cmux docs settings`
```
settings: cmux-owned settings, cmux.json locations, schema, and reload flow.

Web:
  https://cmux.com/docs/configuration#cmux-json

Raw resources:
  settings schema: https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json
  cmux skill: https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux/SKILL.md

Fetch:
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux/SKILL.md

Useful commands:
  cmux settings path
  cmux settings cmux-json
  cmux config doctor
  cmux reload-config

Config files:
  primary: ~/.config/cmux/cmux.json
  legacy config: ~/.config/cmux/settings.json
  legacy app support: ~/Library/Application Support/com.cmuxterm.app/settings.json

Related (not cmux-owned, but cmux reads it for terminal behavior):
  ~/.config/ghostty/config
  Use this for terminal transparency (background-opacity), blur, font, theme, etc.

Before editing cmux.json:
  Back up any existing cmux.json file to a timestamped .bak copy so the user can revert.

Reload after editing cmux.json or Ghostty config:
  cmux reload-config   (reloads BOTH and refreshes terminals; no app restart needed)
```

## Installed official /cmux skills on this machine
```
cmux
cmux-architecture
cmux-backend
cmux-billing
cmux-browser
cmux-custom-sidebar
cmux-customization
cmux-debugging
cmux-dev-workflow
cmux-diagnostics
cmux-ghostty
cmux-keyboard-shortcuts
cmux-localization
cmux-markdown
cmux-release
cmux-settings
cmux-shared-behavior
cmux-socket-policy
cmux-team
cmux-testing
cmux-workspace
```

## /cmux-workspace conventions (excerpt from the installed skill)

These non-disruptive rules are what cmux-team plans against; grounded here so the skill does not restate them from memory.
```
---
name: cmux-workspace
description: "Work inside the current cmux workspace and terminal. Use for cmux workspace, current workspace, caller surface, panes, surfaces, socket targeting, and non-interfering cmux automation."
---

# cmux Workspace

Use this skill when a task should be scoped to the cmux workspace that invoked the agent. A workspace is the sidebar tab-like unit in cmux. It contains split panes, and each pane contains one or more surfaces. A surface is the terminal or browser session the user interacts with.

## Default Rule

Scope actions to the current caller workspace unless the user explicitly asks for another workspace, another window, or global state.

Do not assume the visually focused cmux workspace is the right target. An agent can be running in one workspace while the user is looking at another. Prefer the caller environment first:

```bash
printf 'workspace=%s\nsurface=%s\nsocket=%s\n' \
  "${CMUX_WORKSPACE_ID:-}" \
  "${CMUX_SURFACE_ID:-}" \
  "${CMUX_SOCKET_PATH:-}"
cmux identify --json
```

Use `CMUX_WORKSPACE_ID` as the default workspace anchor and `CMUX_SURFACE_ID` as the default caller terminal/surface anchor. If those are missing, use `cmux identify --json` and be explicit that you are using the currently focused cmux context.

## Non-Disruptive Automation

The user may be visually focused on a different workspace, window, or app while an agent works in the caller workspace. Treat layout and focus as separate concerns. Never call focus-changing verbs speculatively.

Never call these without an explicit user ask:

- `select-workspace` switches the visible sidebar tab.
- `focus-pane` / `focus-panel` yanks pane or surface focus.
- `tab-action` with focus-changing actions.

These are user-affecting actions, like clicks. The rule applies even inside the caller's own workspace, since the user may be looking elsewhere.

Build layout additively, in one shot. Prefer commands that create a new pane already populated with the right surface:

```bash
# pane and content in one call, no follow-up needed
cmux new-pane --workspace "${CMUX_WORKSPACE_ID}" --type browser --direction right --url "http://127.0.0.1:8765"
cmux new-pane --workspace "${CMUX_WORKSPACE_ID}" --type terminal --direction down
```

Avoid create-then-move-then-focus chains. If a layout command rejects a valid `surface:` or `pane:` ref, do not work around it by focusing. Report the bug to the user and stop.

Pass `--focus false` whenever the verb supports it. `move-surface --focus false` preserves the user's current attention. Other commands may grow the same flag over time (https://github.com/manaflow-ai/cmux/issues/1418, https://github.com/manaflow-ai/cmux/issues/2820).

## Right-Side Helper Pane

When opening auxiliary output for the current task (preview apps, TUIs, logs, one-off shells, browser checks), keep the workspace organized by reusing a helper pane to the right of the caller terminal.

First inspect the caller context and panes:

```bash
cmux identify --json
cmux list-panes --workspace "${CMUX_WORKSPACE_ID:-}" --json
cmux list-pane-surfaces --workspace "${CMUX_WORKSPACE_ID:-}" --json
```
```
