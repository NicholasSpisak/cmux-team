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
  ok "kit templates checked"
else err "missing $KIT"; fi

if [ "$fail" -ne 0 ]; then printf '\ncheck.sh: FAILURES\n'; exit 1; fi
printf '\ncheck.sh: all checks passed\n'
