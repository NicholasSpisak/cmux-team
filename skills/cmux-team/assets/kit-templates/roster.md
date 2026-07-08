# Launch kit — __OBJECTIVE__

**Pattern:** __PATTERN__ · **Team size:** __COUNT__ · **Slug:** `__SLUG__`

## Roster
__ROSTER_TABLE__

## How to launch
1. Review `lead.md`, each `worker-<role>.md`, and `launch.sh` in this directory.
2. Confirm when `/cmux-team` asks — **it runs the launcher for you**:
   ```bash
   bash .cmux-team/__SLUG__/launch.sh
   ```
3. cmux opens, the LEAD boots and spawns workers, statuses + notifications appear.

Nothing runs until you confirm. `/cmux-team` always asks before spending execution
tokens, and never does the team's work itself.

**If the agent can't launch it:** cmux's socket only answers a trusted caller, so
`cmux ping` must succeed. If it does not, run the command above yourself from a cmux
terminal surface — or start your coding agent inside one — then re-confirm.
