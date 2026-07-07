# Worked example

**Invocation:** `/cmux-team "add rate limiting to the POST /orders endpoint"`

**Deliverable (roster):**

| Role | Model | Thinking | × | Job |
|---|---|---|---|---|
| Lead | `claude-opus-4-8` | high | 1 | Decompose, judge on rubric, synthesize, verify |
| Implementer A | `claude-opus-4-8` | high | 1 | Build in worktree ../ord-a; blind to B |
| Implementer B | `codex · gpt-5-codex` | high | 1 | Build in worktree ../ord-b; diverse 2nd approach |
| Reviewer | `claude-sonnet-5` | medium | 1 | Edge-case tests; verify the synthesis |

**Deliverable (launch prompt):**

```
/cmux "OBJECTIVE: Add rate limiting to POST /orders.

ROSTER (4):
• LEAD — claude-opus-4-8 · thinking=high. Decompose, delegate, judge builds on
  the rubric, synthesize best-of-both, verify.
• IMPLEMENTER-A — claude-opus-4-8 · thinking=high. Worktree ../ord-a, branch
  ord/a. Blind to B.
• IMPLEMENTER-B — codex gpt-5-codex · reasoning=high. Worktree ../ord-b, branch
  ord/b. Blind to A.
• REVIEWER — claude-sonnet-5 · thinking=medium. Edge-case tests (burst, clock
  skew, distributed); verify the synthesis.

PROTOCOL: A,B build isolated → LEAD scores blind to provenance → synthesize →
  REVIEWER verifies → tests pass → present to human.
RUBRIC: correctness · edge cases · readability · coverage · blast radius · idiomatic fit.
CONSTRAINTS: worktree per implementer; --focus false; no merge without human approval."
```

cmux-team stops here. Nothing is running — review the plan, tweak the roster,
then run the prompt yourself.
