#!/usr/bin/env bash
# Local CI for cmux-team. No network, no GitHub Actions.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SKILL_DIR="skills/cmux-team"
fail=0
err(){ printf 'FAIL: %s\n' "$*" >&2; fail=1; }
ok(){ printf 'ok:   %s\n' "$*"; }

# 1. SKILL.md frontmatter
if [ -f "$SKILL_DIR/SKILL.md" ] && head -1 "$SKILL_DIR/SKILL.md" | grep -q '^---$'; then
  fm="$(awk 'NR==1{next} /^---$/{exit} {print}' "$SKILL_DIR/SKILL.md")"
  printf '%s\n' "$fm" | grep -q '^name:[[:space:]]*cmux-team[[:space:]]*$' || err "SKILL.md frontmatter: name must be cmux-team"
  printf '%s\n' "$fm" | grep -Eq '^description:[[:space:]]*.{40,}' || err "SKILL.md frontmatter: description missing or too short"
  ok "SKILL.md frontmatter"
else err "$SKILL_DIR/SKILL.md missing or has no YAML frontmatter"; fi

# 1b. Frontmatter must be VALID YAML. `npx skills add` parses it; an unquoted scalar
# containing ": " makes the parser see a mapping -> "No skills found" (silent install failure).
if command -v python3 >/dev/null 2>&1 && [ -f "$SKILL_DIR/SKILL.md" ]; then
  python3 - "$SKILL_DIR/SKILL.md" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
m = re.match(r'^---\n(.*?)\n---\n', src, re.S)
if not m:
    sys.exit(1)
fm = m.group(1)
try:
    import yaml
except ImportError:  # no pyyaml: cheap guard for the exact footgun above
    for line in fm.split('\n'):
        key, sep, val = line.partition(':')
        val = val.strip()
        if sep and val and val[0] not in '"\'' and ': ' in val:
            sys.exit(1)
    sys.exit(0)
try:
    d = yaml.safe_load(fm)
except Exception:
    sys.exit(1)
sys.exit(0 if isinstance(d, dict) and d.get('name') and d.get('description') else 1)
PY
  if [ $? -eq 0 ]; then ok "SKILL.md frontmatter parses as YAML (installable)"
  else err "SKILL.md frontmatter is not valid YAML — 'npx skills add' reports 'No skills found'. Quote the description or remove ': ' from it."; fi
fi

# 2. No placeholders
if grep -RInE 'TODO|TBD|FIXME|lorem ipsum|\bXXX\b|implement later' \
     "$SKILL_DIR/SKILL.md" README.md "$SKILL_DIR/references" "$SKILL_DIR/assets" docs/index.html 2>/dev/null; then
  err "placeholder tokens found (see above)"
else ok "no placeholders"; fi

# 3. Referenced files exist
for f in "$SKILL_DIR/references/staffing-heuristics.md" "$SKILL_DIR/references/cmux-verbs.snapshot.md" \
         "$SKILL_DIR/references/cmux-docs.snapshot.md" "$SKILL_DIR/references/orchestration-recipe.md" \
         "$SKILL_DIR/assets/example-plan.md"; do
  [ -f "$f" ] && ok "exists: $f" || err "missing referenced file: $f"
done

# 4. Snapshot provenance + staleness
CUR_VER="$(cmux version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
for s in "$SKILL_DIR/references/cmux-verbs.snapshot.md" "$SKILL_DIR/references/cmux-docs.snapshot.md" \
         "$SKILL_DIR/references/orchestration-recipe.md"; do
  [ -f "$s" ] || continue
  grep -q 'Captured-From:' "$s" || err "$s: missing Captured-From provenance"
  grep -q 'Captured-cmux-version:' "$s" || err "$s: missing Captured-cmux-version provenance"
  if [ -n "$CUR_VER" ]; then
    SNAP_VER="$(grep -oE 'Captured-cmux-version:[^0-9]*[0-9]+\.[0-9]+\.[0-9]+' "$s" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
    if [ -n "$SNAP_VER" ] && [ "$SNAP_VER" != "$CUR_VER" ]; then
      err "$s stale: snapshot cmux $SNAP_VER != installed cmux $CUR_VER (run scripts/sync-cmux-refs.sh)"
    else ok "$s fresh (cmux ${SNAP_VER:-?})"; fi
  fi
done

# 5. Docs SEO/self-containment sanity
D=docs/index.html
if [ -f "$D" ]; then
  [ "$(grep -o '<h1' "$D" | wc -l | tr -d ' ')" = "1" ] || err "$D: must have exactly one <h1>"
  grep -q '<title>' "$D" || err "$D: missing <title>"
  grep -qi '<meta[^>]*name="description"' "$D" || err "$D: missing meta description"
  grep -qi 'rel="canonical"' "$D" || err "$D: missing canonical link"
  grep -q 'skool.com/aioperatoracademy/about' "$D" || err "$D: missing AOA CTA link"
  if grep -qiE '<link[^>]+rel="?stylesheet"?[^>]+href="https?://' "$D" \
     || grep -qiE '<script[^>]+src="https?://' "$D" \
     || grep -qiE '<link[^>]+href="https?://[^"]*fonts' "$D" \
     || grep -qiE '@import[[:space:]]+url\((["'\'']?)https?://' "$D"; then
    err "$D: references an external asset host (must be self-contained)"
  else ok "$D self-contained + SEO tags present"; fi
  [ -f docs/.nojekyll ] || err "missing docs/.nojekyll"
else err "missing docs/index.html"; fi

# 6. No GitHub Actions
if [ -d .github/workflows ]; then err ".github/workflows present (local CI only)"; else ok "no .github/workflows"; fi

# 7. Launch-kit templates
KIT="$SKILL_DIR/assets/kit-templates"
ALLOWED_TOKENS='__SLUG__ __OBJECTIVE__ __LEAD_MODEL__ __LEAD_THINKING__ __ROLE__ __MODEL__ __THINKING__ __BRANCH__ __WORKTREE__ __TASK__ __ROSTER_TABLE__ __SPAWN_STEPS__ __WORKER_LIST__ __PATTERN__ __COUNT__'
if [ -d "$KIT" ]; then
  for tmpl in "$KIT/lead.md" "$KIT/worker.md" "$KIT/launch.sh" "$KIT/roster.md"; do
    if [ ! -f "$tmpl" ]; then err "missing kit template: $tmpl"; continue; fi
    while IFS= read -r tok; do
      case " $ALLOWED_TOKENS " in
        *" $tok "*) : ;;
        *) err "$tmpl: unknown template token $tok (not in ALLOWED_TOKENS)";;
      esac
    done < <(grep -oE '__[A-Z_]+__' "$tmpl" | sort -u)
  done
  if bash -n "$KIT/launch.sh" 2>/dev/null; then ok "kit launch.sh parses"; else err "kit launch.sh: bash -n failed"; fi

  # 7b. Emitted shell must QUOTE every model alias. Bracketed aliases (opus[1m]) are
  # globbed by zsh when bare: "zsh: no matches found: opus[1m]". bash passes them
  # through, so this bug is invisible on bash and fatal on the common macOS default.
  # An alias starts with a word char; `--model …` in prose is not a command.
  if grep -RInE -- '--model [A-Za-z0-9_]' "$KIT" "$SKILL_DIR/assets/example-plan.md" 2>/dev/null | grep -q .; then
    grep -RInE -- '--model [A-Za-z0-9_]' "$KIT" "$SKILL_DIR/assets/example-plan.md" 2>/dev/null
    err "unquoted --model alias in emitted shell (must be --model \"<alias>\")"
  else ok "all emitted --model aliases are quoted"; fi

  # 7c. A $(...) capture of a cmux new-* verb is fine ONLY if it is then parsed. Each
  # verb prints a different OK line ("OK surface:18 workspace:8" vs "OK surface:17
  # pane:17 workspace:8"), so the raw string is never a valid handle. Require a
  # cref()/grep -oE within 4 lines of the capture.
  unparsed=0
  while IFS= read -r f; do
    awk -v file="$f" '
      /^[[:space:]]*[A-Za-z_]+=\$\(cmux[[:space:]]+(new-pane|new-split|new-workspace|new-surface)/ {
        cap = NR; capline = $0
      }
      cap && NR > cap && NR <= cap + 10 && (/cref/ || /grep -oE/) { cap = 0 }
      cap && NR == cap + 10 { printf "%s:%d: %s\n", file, cap, capline; cap = 0 }
      END { if (cap) printf "%s:%d: %s\n", file, cap, capline }
    ' "$f"
  done < <(find "$KIT" -type f) | grep . && unparsed=1
  if [ "$unparsed" -eq 1 ]; then
    err "cmux new-* captured but never parsed — extract the ref with cref()"
  else ok "every cmux ref capture is parsed, never used raw"; fi

  # 7d. rename-tab resolves the tab inside \$CMUX_WORKSPACE_ID; it needs --workspace.
  if grep -RIn 'cmux rename-tab' "$KIT" "$SKILL_DIR/references/orchestration-recipe.md" 2>/dev/null \
       | grep -v -- '--workspace' | grep -v 'not_found' | grep -v '^\s*#' | grep -q .; then
    err "cmux rename-tab without --workspace (resolves inside \$CMUX_WORKSPACE_ID)"
  else ok "every rename-tab is workspace-scoped"; fi

  # 7e. Layout: exactly ONE workers pane. One `new-pane` per worker tiles into confetti;
  # workers must be TABS (`new-surface --pane`) inside a single pane.
  np=$(grep 'cmux new-pane' "$KIT/lead.md" 2>/dev/null | grep -vcE '^[[:space:]]*#' || echo 0)
  if [ "$np" -gt 1 ]; then
    err "lead.md calls new-pane $np times — workers must be tabs (new-surface --pane) in ONE pane"
  else ok "lead.md creates exactly one workers pane"; fi

  # 7f. Rule 4: a worker must never type into the lead's surface (keystrokes interleave).
  # It reports via the journal + `cmux wait-for -S`.
  if grep -qE 'cmux send .*(LEAD_SURF|lead.s surface)' "$KIT/worker.md" 2>/dev/null; then
    err "worker.md sends into the lead's surface — concurrent workers corrupt keystrokes"
  elif ! grep -q 'cmux wait-for -S "ready:' "$KIT/worker.md" 2>/dev/null; then
    err "worker.md never signals ready: — the lead blocks before delegating (team stalls)"
  elif ! grep -q 'cmux wait-for -S "done:' "$KIT/worker.md" 2>/dev/null; then
    err "worker.md never signals done: — the lead would never be woken"
  else ok "workers signal ready:+done: via wait-for, never type at the lead"; fi

  # 7f2. The tokens the lead waits on must be the tokens the worker signals.
  for tok in ready done; do
    grep -q "wait-for \"$tok:" "$KIT/lead.md" 2>/dev/null || err "lead.md never waits on $tok:"
    grep -q "wait-for -S \"$tok:" "$KIT/worker.md" 2>/dev/null || err "worker.md never signals $tok:"
  done
  ok "lead's wait tokens match the worker's signal tokens"

  # 7g. `cmux wait-for` defaults to a 30s timeout; a lead that omits --timeout will
  # give up on any real task.
  if grep -E 'cmux wait-for "' "$KIT/lead.md" 2>/dev/null | grep -qv -- '--timeout'; then
    err "lead.md waits without --timeout (cmux wait-for defaults to 30s)"
  else ok "every lead wait-for passes --timeout"; fi

  # 7h. Rule 5: the lead's Bash calls are fresh shells. Refs must be persisted+re-sourced,
  # and the bootstrap must not use `eval "$(… python3 …)"` (nested quotes get eaten).
  if grep -q 'eval "\$(' "$KIT/lead.md" 2>/dev/null; then
    err "lead.md uses eval \"\$(...)\" — nested quoting is eaten in transit; parse with sed/grep"
  elif ! grep -q 'savref' "$KIT/lead.md" 2>/dev/null || ! grep -q 'lib.sh' "$KIT/lead.md" 2>/dev/null; then
    err "lead.md does not persist refs via lib.sh/savref — shell vars die between Bash calls (Rule 5)"
  else ok "lead.md persists refs across fresh shells (no eval/python)"; fi

  # 7i. The lead must be told not to rewrite the human's plan.
  if grep -qi 'do not rewrite your own orders\|not rewrite its own orders' "$KIT/lead.md" 2>/dev/null; then
    ok "lead.md forbids self-editing the kit"
  else err "lead.md must forbid editing roster.md/worker-*.md (it will otherwise 'fix' the plan)"; fi

  # 7j. `claude --append-system-prompt-file X` with NO positional prompt opens an
  # interactive session and idles forever — a system prompt does not make the agent take a
  # turn. Verified A/B. Every claude boot line must pass a positional prompt after the file.
  if grep -h 'append-system-prompt-file' "$KIT/lead.md" "$SKILL_DIR/references/orchestration-recipe.md" 2>/dev/null \
       | grep -v '^[[:space:]]*#' | grep 'cmux send' | grep -qv 'md.[[:space:]]*\\\?"Boot'; then
    err "a claude boot line has no positional prompt — the worker will idle, never taking a turn"
  else ok "every claude worker boot passes a positional prompt"; fi

  # 7k. Model aliases must come from staffing-heuristics (the single source of truth).
  # Scan BOTH emitted shell (`--model "X"`) and prose/roster tables (`codex · X`) — a stale
  # alias in the worked example is copied verbatim by the next run that pattern-matches it.
  SH="$SKILL_DIR/references/staffing-heuristics.md"
  while IFS= read -r alias; do
    [ -n "$alias" ] || continue
    grep -qF -- "\`$alias\`" "$SH" || err "model alias '$alias' is not listed in staffing-heuristics.md"
  done < <( { grep -rhoE -- '--model \\?"[^"\\]+' "$KIT" "$SKILL_DIR/references" | sed -E 's/.*"//'
              grep -rhoE -- 'codex · [A-Za-z0-9._-]+' "$SKILL_DIR" docs 2>/dev/null | sed -E 's/^codex · //'
            } | sort -u | grep -v '__' )
  ok "every model alias (shell + roster tables) is declared in staffing-heuristics.md"

  # 7l. An alias the CLI rejects must never be presented as usable. `gpt-5-codex` 400s on a
  # ChatGPT-account Codex; it may appear ONLY on a line documenting that failure.
  if grep -rn 'gpt-5-codex' "$SKILL_DIR" docs README.md 2>/dev/null \
       | grep -vi 'not supported\|rejected' | grep -q .; then
    grep -rn 'gpt-5-codex' "$SKILL_DIR" docs README.md 2>/dev/null | grep -vi 'not supported\|rejected'
    err "'gpt-5-codex' presented as a usable alias (it 400s on a ChatGPT-account Codex)"
  else ok "no rejected alias presented as usable"; fi

  ok "kit templates checked"
else err "missing $KIT"; fi

# 8. Live orchestration smoke test (skips cleanly when not a trusted cmux caller).
if [ "${SKIP_SMOKE:-0}" = "1" ]; then
  ok "smoke test skipped (SKIP_SMOKE=1)"
elif bash scripts/smoke.sh; then
  ok "live cmux orchestration smoke test"
else
  err "scripts/smoke.sh failed — the recipe does not work against this cmux"
fi

if [ "$fail" -ne 0 ]; then printf '\ncheck.sh: FAILURES\n'; exit 1; fi
printf '\ncheck.sh: all checks passed\n'
