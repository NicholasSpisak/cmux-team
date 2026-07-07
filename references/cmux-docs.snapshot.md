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
cmux-testing
cmux-workspace
```
