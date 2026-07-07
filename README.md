# cmux-team

**A planner skill that designs your multi-agent [cmux](https://cmux.com) team.**
Give it a coding objective; it returns one thing — a ready-to-run
`/cmux "<system prompt>"` naming every agent's **role**, **model**, **thinking
level**, and **count** — then stops. You review the plan and launch it. It never
starts the work itself.

📄 **Docs & guide:** https://nicholasspisak.github.io/cmux-team/
🎓 **Learn to operate AI agent teams:** [AI Operator Academy](https://www.skool.com/aioperatoracademy/about)

## Why

"Spinning up agents" quietly makes four decisions you should make on purpose:
which model per role, how hard each should think, how many agents, and whether
you even need a team. `cmux-team` makes those decisions explicit as a reviewable
spec — a human gate before any tokens are spent.

## Prerequisites

- The [cmux](https://cmux.com/docs/getting-started) app + CLI, with the official
  `/cmux` skills installed (`cmux docs` should work).
- A coding agent (Claude Code, Codex, etc.).

## Install

```bash
npx skills add NicholasSpisak/cmux-team
```

This installs the skill into each detected agent's skills directory (via the
[Vercel skills](https://github.com/vercel-labs/skills) ecosystem).

## Use

```
/cmux-team "add rate limiting to the POST /orders endpoint"
```

You get a roster + a `/cmux` system prompt. Review it, adjust models/counts, then
run it yourself. See [`skills/cmux-team/assets/example-plan.md`](skills/cmux-team/assets/example-plan.md).

## How it stays current

cmux specifics are vendored in [`skills/cmux-team/references/`](skills/cmux-team/references/) as snapshots with a
provenance header (source + captured `cmux version` + date). Refresh them after a
cmux update:

```bash
./scripts/sync-cmux-refs.sh
```

Run it **from inside a cmux terminal surface**. The `cmux --help` and `cmux docs`
captures work anywhere, but `cmux capabilities` is socket-backed and only answers
a trusted caller — outside a cmux surface it records a graceful "unavailable"
note instead. The script auto-discovers the running app's socket from
`/tmp/cmux-last-socket-path` when it can.

## Contributing

No CI runs in the cloud — **there are no GitHub Actions**. Everything is checked
locally before you push:

```bash
./scripts/check.sh        # must exit 0 before committing
```

`check.sh` validates the skill frontmatter, absence of placeholders, that every
referenced file exists, snapshot provenance + staleness (snapshot `cmux version`
must match your installed one), docs SEO + self-containment, and that no
`.github/workflows/` directory exists. If the staleness check fails, run
`./scripts/sync-cmux-refs.sh` (from a cmux surface) and commit the refreshed
snapshots. Keep model IDs in `skills/cmux-team/references/staffing-heuristics.md`
— that is their single source of truth.

## License

[MIT](LICENSE) © Nicholas Spisak
