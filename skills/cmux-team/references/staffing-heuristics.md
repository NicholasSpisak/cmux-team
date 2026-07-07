# Staffing heuristics

The single source of truth for **which model, which thinking level, how many** —
read by `cmux-team` Move 3. Update model IDs here when they change; nowhere else.

## Default role → model · thinking · count

| Role | Default model | Thinking | Count logic | Why |
|---|---|---|---|---|
| Lead / judge / architect | `claude-opus-4-8` | high–xhigh | always 1 | Deepest reasoning; owns judging + synthesis |
| Primary implementer | `claude-opus-4-8` | high | 1 | Most robust code on hard, ambiguous problems |
| Diverse implementer | `codex · gpt-5-codex` | high | 1 (max 2) | Different model family → genuinely different approach |
| Reviewer / tester | `claude-sonnet-5` | medium | +1 if verify-heavy | Strong & cheaper; verification needn't be Opus |
| Scaffolder / mechanic | `claude-haiku-4-5` | low | +1 per independent chore | Fast & cheap; mechanical work needs no deep think |

**Totals:** 3–6 agents for most real tasks; **1** for trivial ones.

## Thinking-level guidance

- `xhigh`/`high` — architecture, judging, synthesis, ambiguous design decisions.
- `medium` — review, test authoring, well-scoped implementation.
- `low` — scaffolding, renames, mechanical edits, boilerplate.

Reasoning budget is a dial, not a default: raise it where a decision is hard,
lower it where the work is mechanical. This is most of the cost/quality control
available.

## Team patterns

1. **Diverse-build + judge (default).** 2 implementers of different model
   families build the same task in isolation; 1 lead judges both on the rubric
   and synthesizes the best of each; +1 reviewer when edge cases or blast radius
   are high. Use when the task is open-ended and quality matters.
2. **Decompose + assemble.** 1 lead + N implementers, one per independent
   subtask, each in its own worktree; lead integrates and verifies. Use when the
   objective splits cleanly into parallel parts.
3. **Solo.** 1 agent, no team. Use for well-specified, mechanical, or tiny tasks
   where a second build would only re-derive the same diff.

## Count formula

```
agents = 1 (lead)
       + (# genuinely distinct viable approaches, 2 default, max 3)  # implementers
       + (1 if edge-case/blast-radius heavy else 0)                  # reviewer
       + (1 per independent mechanical chore)                        # scaffolders
```
If the objective is trivial: `agents = 1` and say "just solo it."

## Rubric (used by the lead when judging)

correctness · edge cases · readability · test coverage · blast radius · idiomatic fit.
Score blind to which model produced which build.
