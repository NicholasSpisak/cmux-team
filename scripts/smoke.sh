#!/usr/bin/env bash
# Live smoke test for the cmux-team orchestration recipe.
#
# Exercises the EXACT sequence a generated lead.md runs — workspace, ONE workers pane,
# one named tab per worker, roster panel docked into the lead pane, boot-by-send,
# journal + wait-for reporting — against a real cmux socket, using fake agents instead
# of real ones (no tokens spent).
#
# This exists because scripts/check.sh only proves the templates *parse*. It green-lit
# four defects that made every launched team unusable:
#   1. `VAR=$(cmux new-pane …)` captured "OK surface:N pane:N workspace:N", not a ref.
#   2. `rename-tab --surface` needs --workspace; without it: "not_found: Tab not found".
#   3. Bare `--model opus[1m]` → zsh globs it → "no matches found".
#   4. One pane per worker tiled into confetti; concurrent worker->lead `cmux send`
#      interleaved keystrokes ("echo REPORT:w1echo REPORT:w2").
# All four are regression-guarded below.
#
# Usage: bash scripts/smoke.sh          (requires a trusted cmux caller: `cmux ping`)
#        SMOKE_KEEP=1 bash scripts/smoke.sh   (leave the workspace up for inspection)
set -uo pipefail

fail=0
err(){ printf 'FAIL: %s\n' "$*" >&2; fail=1; }
ok(){ printf 'ok:   %s\n' "$*"; }

command -v cmux >/dev/null 2>&1 || { echo "SKIP: cmux CLI not on PATH"; exit 0; }
if ! cmux ping >/dev/null 2>&1; then
  echo "SKIP: not a trusted cmux caller (run from inside a cmux terminal surface)"
  exit 0
fi

cref() { printf '%s' "$1" | grep -oE "$2:[0-9]+" | head -1; }

TMP="$(mktemp -d)"; RUN="$TMP/run"; mkdir -p "$RUN"; : > "$RUN/journal.ndjson"
ROLES="alpha beta gamma"
WS=""
cleanup() {
  if [ -n "$WS" ] && [ "${SMOKE_KEEP:-0}" != "1" ]; then
    for r in $ROLES; do cmux clear-status "$r" --workspace "$WS" >/dev/null 2>&1 || true; done
    cmux clear-progress --workspace "$WS" >/dev/null 2>&1 || true
    cmux close-workspace --workspace "$WS" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT
export CMUX_QUIET=1

# --- 0. cref must handle every documented OK shape (pure unit guard, no socket) ------
[ "$(cref 'OK workspace:8' workspace)" = "workspace:8" ] || err "cref: new-workspace shape"
[ "$(cref 'OK surface:18 workspace:8' surface)" = "surface:18" ] || err "cref: new-split shape"
[ "$(cref 'OK surface:17 pane:17 workspace:8' pane)" = "pane:17" ] || err "cref: new-pane pane"
[ "$(cref 'OK surface=surface:48 pane=pane:44 path=/x' pane)" = "pane:44" ] || err "cref: markdown shape"
[ "$fail" -eq 0 ] && ok "cref parses every cmux OK-line shape"

# --- 1. team workspace, alongside the human's, in the current window ----------------
WS=$(cref "$(cmux new-workspace --name 'smoke:cmux-team' --cwd "$TMP" --focus false 2>&1)" workspace)
[ -n "$WS" ] || { err "new-workspace gave no workspace ref"; exit 1; }
LEAD_PANE=$(cmux list-panes --workspace "$WS" 2>/dev/null | head -1 | grep -oE 'pane:[0-9]+')
LEAD_SURF=$(cmux list-panels --workspace "$WS" 2>/dev/null | head -1 | grep -oE 'surface:[0-9]+')
cmux rename-tab --workspace "$WS" --surface "$LEAD_SURF" "lead" >/dev/null 2>&1
ok "team workspace $WS (lead pane=$LEAD_PANE); human's workspace untouched"

# Regression guard #1: a raw OK line must never be accepted as a handle.
if cmux rename-tab --workspace "$WS" --surface "OK surface:1 workspace:1" "x" >/dev/null 2>&1; then
  err "raw OK line accepted as a surface handle — cref guard is meaningless"
else ok "raw OK line rejected as a handle (why cref exists)"; fi

# --- 2. ONE workers pane; first surface is worker #1, the rest are TABS -------------
sleep 1
OUT=$(cmux new-pane --workspace "$WS" --direction right --focus false 2>&1)
WPANE=$(cref "$OUT" pane); FIRST_SURF=$(cref "$OUT" surface)
[ -n "$WPANE" ] && [ -n "$FIRST_SURF" ] || err "new-pane did not yield both refs: $OUT"

declare -a SURFS=()
for role in $ROLES; do
  if [ -n "${FIRST_SURF:-}" ]; then SURF="$FIRST_SURF"; FIRST_SURF=""
  else
    mkdir -p "$TMP/wt-$role"
    SURF=$(cref "$(cmux new-surface --workspace "$WS" --pane "$WPANE" --type terminal \
             --working-directory "$TMP/wt-$role" --focus false 2>&1)" surface)
  fi
  [ -n "$SURF" ] || { err "no surface for $role"; continue; }
  # Regression guard #2: rename-tab MUST be workspace-scoped.
  cmux rename-tab --workspace "$WS" --surface "$SURF" "$role" >/dev/null 2>&1 \
    || err "rename-tab --workspace --surface failed for $role (recipe Rule 2)"
  SURFS+=("$role:$SURF")
  sleep 0.4
done
ok "one workers pane ($WPANE) with tabs: $(printf '%s ' "${SURFS[@]}")"

# --- 3. the layout is 2 panes, N tabs — not N panes ---------------------------------
NPANES=$(cmux list-panes --workspace "$WS" 2>/dev/null | grep -cE 'pane:[0-9]+')
NTABS=$(cmux list-pane-surfaces --workspace "$WS" --pane "$WPANE" 2>/dev/null | grep -cE 'surface:[0-9]+')
[ "$NPANES" = "2" ] || err "expected exactly 2 panes (lead + workers), got $NPANES"
[ "$NTABS" = "3" ] || err "expected 3 worker tabs in one pane, got $NTABS"
[ "$NPANES" = "2" ] && [ "$NTABS" = "3" ] && ok "layout: 2 panes, $NTABS worker tabs (no confetti)"

# --- 4. boot fake agents: real worker-lib, quoted bracket alias, exported reporting env
# The fake worker is a sourced shell lib, not an LLM: it defines the same report() the
# generated worker.md defines, so the whole lifecycle below exercises the real contract.
cat > "$RUN/worker-lib.sh" <<'WLIB'
report() {  # report <state> <note>
  printf '{"role":"%s","state":"%s","note":"%s"}\n' "$CMUX_TEAM_ROLE" "$1" "$2" >> "$CMUX_TEAM_RUN/journal.ndjson"
  case "$1" in
    ready)   cmux set-status "$CMUX_TEAM_ROLE" ready   --workspace "$CMUX_TEAM_WS" --icon circle --color '#6b7280' --priority 1 ;;
    working) cmux set-status "$CMUX_TEAM_ROLE" working --workspace "$CMUX_TEAM_WS" --icon play.circle --color '#2563eb' --priority 2 ;;
    done)    cmux set-status "$CMUX_TEAM_ROLE" done    --workspace "$CMUX_TEAM_WS" --icon checkmark --color '#16a34a' --priority 3 ;;
    blocked) cmux set-status "$CMUX_TEAM_ROLE" blocked --workspace "$CMUX_TEAM_WS" --icon exclamationmark --color '#dc2626' --priority 4 ;;
  esac
  case "$1" in
    ready)   cmux wait-for -S "ready:$CMUX_TEAM_ROLE" ;;
    done)    cmux wait-for -S "done:$CMUX_TEAM_ROLE" ;;
    blocked) cmux wait-for -S "blocked:$CMUX_TEAM_ROLE"; cmux wait-for -S "done:$CMUX_TEAM_ROLE" ;;
  esac
}
# What the LEAD "delegates" to. Stands in for the agent doing its task.
do_task() { report working "started"; report working "2/2 steps"; report done "gates green"; printf 'DONE:%s\n' "$CMUX_TEAM_ROLE"; }
WLIB

for entry in "${SURFS[@]}"; do
  role="${entry%%:*}"; surf="${entry#*:}"
  cmux send --surface "$surf" "export CMUX_TEAM_ROLE=$role CMUX_TEAM_WS=$WS CMUX_TEAM_RUN='$RUN' && . '$RUN/worker-lib.sh' && printf 'MODEL=%s\\n' \"opus[1m]\" && printf 'ready:%s\\n' \"\$CMUX_TEAM_ROLE\" && report ready booted" >/dev/null 2>&1
  cmux send-key --surface "$surf" enter >/dev/null 2>&1
done

FIRST_SURF_REF="${SURFS[0]#*:}"
SCREEN=""
for _ in $(seq 1 30); do
  sleep 0.5; SCREEN=$(cmux read-screen --surface "$FIRST_SURF_REF" --lines 20 2>&1)
  printf '%s' "$SCREEN" | grep -q 'ready:alpha' && break
done
printf '%s' "$SCREEN" | grep -q 'no matches found' && err "zsh globbed the model alias (recipe Rule 3)"
printf '%s' "$SCREEN" | grep -q 'MODEL=opus\[1m\]' \
  && ok "model alias 'opus[1m]' survived the pane's shell verbatim" \
  || err "model alias did not reach the pane intact"

# --- 4b. LIFECYCLE: every worker signals ready: and the lead's wait returns ----------
# The bug this guards: workers signalled only done:, the lead waited on ready:, and the
# team deadlocked at 0% with three healthy agents idle.
for role in $ROLES; do
  cmux wait-for "ready:$role" --timeout 60 >/dev/null 2>&1 \
    || err "lead blocked on ready:$role — worker never signalled (deadlock)"
done
ok "lifecycle: lead's wait-for ready: returned for every worker"

# --- 4c. LIFECYCLE: delegate -> working -> done -> lead wakes ------------------------
for entry in "${SURFS[@]}"; do
  surf="${entry#*:}"
  cmux send --surface "$surf" 'do_task' >/dev/null 2>&1     # this is what delegation IS
  cmux send-key --surface "$surf" enter >/dev/null 2>&1
done
for role in $ROLES; do
  cmux wait-for "done:$role" --timeout 90 >/dev/null 2>&1 \
    || err "lead never woke on done:$role after delegating"
done
ok "lifecycle: delegate -> worker done: -> lead woke, for all $(printf '%s' "$ROLES" | wc -w | tr -d ' ') workers"

# The journal is the human's record of what each worker did. Assert the full arc.
for role in $ROLES; do
  for state in ready working done; do
    grep -q "\"role\":\"$role\",\"state\":\"$state\"" "$RUN/journal.ndjson" \
      || err "journal missing $role -> $state"
  done
done
ok "journal records ready->working->done for every worker"
python3 - "$RUN/journal.ndjson" <<'PY' || err "journal is not valid NDJSON"
import json,sys
for line in open(sys.argv[1]):
    if line.strip(): json.loads(line)
PY
ok "journal is valid NDJSON end to end"

# --- 5. roster panel docks into the LEAD pane (markdown has no --workspace flag) -----
printf '# Roster\n\nsmoke\n' > "$TMP/roster.md"
MD=$(cref "$(cmux markdown open "$TMP/roster.md" --focus false 2>&1)" surface)
if [ -n "$MD" ]; then
  cmux move-surface --surface "$MD" --workspace "$WS" --pane "$LEAD_PANE" --focus false >/dev/null 2>&1
  sleep 1
  cmux list-pane-surfaces --workspace "$WS" --pane "$LEAD_PANE" 2>/dev/null | grep -q 'roster.md' \
    && ok "roster.md panel docked into the lead pane" \
    || err "roster.md panel did not land in the lead pane"
else err "markdown open returned no surface"; fi

# --- 6. reporting: concurrent journal appends never interleave (regression guard #4) --
: > "$RUN/concurrency.ndjson"
for role in $ROLES; do
  ( printf '{"role":"%s","state":"done","note":"gates green"}\n' "$role" >> "$RUN/concurrency.ndjson" ) &
done; wait
LINES=$(grep -c '"state":"done"' "$RUN/concurrency.ndjson")
[ "$LINES" = "3" ] || err "journal: expected 3 clean lines, got $LINES"
grep -q '}{' "$RUN/concurrency.ndjson" && err "journal lines interleaved"
[ "$LINES" = "3" ] && ok "journal: 3 concurrent appends, none interleaved"

# --- 7. wait-for LATCHES: signalling before the waiter arrives is safe ----------------
# Why it matters: a fast worker may signal done: before the lead starts waiting.
cmux wait-for -S "smoke:latch" >/dev/null 2>&1
if cmux wait-for "smoke:latch" --timeout 5 >/dev/null 2>&1; then
  ok "wait-for latches (signal-before-wait does not race)"
else err "wait-for does not latch — a fast worker's signal would be lost"; fi

# --- 8. status board reflects the finished team, then teardown clears it -------------
BOARD=$(cmux list-status --workspace "$WS" 2>&1)
for role in $ROLES; do
  printf '%s' "$BOARD" | grep -q "$role=done" || err "status board missing $role=done after lifecycle"
done
ok "status board scoped to $WS shows every worker done"

for role in $ROLES; do cmux clear-status "$role" --workspace "$WS" >/dev/null 2>&1; done
cmux clear-progress --workspace "$WS" >/dev/null 2>&1
BOARD=$(cmux list-status --workspace "$WS" 2>&1)
LEFT=0
for role in $ROLES; do printf '%s' "$BOARD" | grep -q "$role=" && LEFT=1; done
[ "$LEFT" = "0" ] && ok "teardown: clear-status removed every worker from the board" \
                  || err "teardown left stale statuses: $BOARD"

# --- 8b. Rule 5: refs must survive a FRESH shell (the lead's next Bash tool call) ----
# Each spawn block runs in its own shell. Simulate that: write refs in one `bash -c`,
# read them in another. This is the regression guard for the bug where the lead lost
# $WPANE between blocks, spawned surfaces with an empty --pane, and dropped two workers.
cat > "$RUN/lib.sh" <<'LIB'
cref()   { printf '%s' "$1" | grep -oE "$2:[0-9]+" | head -1; }
savref() { printf '%s=%s\n' "$1" "$2" >> "$TEAM_RUN/refs.env"; }
[ -f "$TEAM_RUN/refs.env" ] && . "$TEAM_RUN/refs.env"
LIB
: > "$RUN/refs.env"
bash -c "export TEAM_RUN='$RUN'; . \"\$TEAM_RUN/lib.sh\"; savref WS '$WS'; savref WPANE '$WPANE'"
GOT=$(bash -c "export TEAM_RUN='$RUN'; . \"\$TEAM_RUN/lib.sh\"; printf '%s %s' \"\$WS\" \"\$WPANE\"")
[ "$GOT" = "$WS $WPANE" ] \
  && ok "refs survive a fresh shell via lib.sh (Rule 5)" \
  || err "refs lost across shells: got '$GOT', want '$WS $WPANE'"

# The quote-free identify parse must yield the caller's refs, not the focused block's.
ID=$(cmux identify --json 2>&1)
CALLER=$(printf '%s' "$ID" | sed -n '/"caller"/,/}/p')
[ -n "$(cref "$CALLER" workspace)" ] && [ -n "$(cref "$CALLER" pane)" ] \
  && ok "identify --json parses with sed/grep (no eval, no python)" \
  || err "identify parse yielded no refs"

# --- 9. tree renders the promised shape ---------------------------------------------
TREE=$(cmux tree --workspace "$WS" 2>&1)
for role in $ROLES; do
  printf '%s' "$TREE" | grep -q "\"$role\"" || err "cmux tree missing named tab: $role"
done
printf '%s' "$TREE" | grep -q '"lead"' || err "cmux tree missing the lead tab"
printf '%s' "$TREE" | grep -q '"roster.md"' || err "cmux tree missing the roster panel"
[ "$fail" -eq 0 ] && ok "cmux tree shows lead + roster panel + every named worker tab"

if [ "$fail" -ne 0 ]; then printf '\nsmoke.sh: FAILURES\n'; exit 1; fi
printf '\nsmoke.sh: all checks passed\n'
