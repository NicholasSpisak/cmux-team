#!/usr/bin/env bash
# Regenerate vendored cmux reference snapshots from the live cmux CLI
# and the installed official /cmux skills. Run locally when cmux updates.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REF="$ROOT/skills/cmux-team/references"
mkdir -p "$REF"

# Socket-backed verbs (e.g. `cmux capabilities`) only answer a trusted caller.
# Auto-discover the running app's socket when not already in a cmux surface;
# if the socket still rejects us, the capability capture falls back gracefully.
if [ -z "${CMUX_SOCKET_PATH:-}" ] && [ -r /tmp/cmux-last-socket-path ]; then
  CMUX_SOCKET_PATH="$(cat /tmp/cmux-last-socket-path 2>/dev/null || true)"
  export CMUX_SOCKET_PATH
fi
CAP_FALLBACK="(cmux capabilities unavailable — run this script from inside a cmux terminal surface so the socket accepts the caller)"

VER="$(cmux version 2>/dev/null | head -1 || echo 'cmux (unknown)')"
DATE="$(date +%Y-%m-%d)"

prov(){ printf '<!--\nCaptured-From: %s\nCaptured-cmux-version: %s\nCaptured-Date: %s\nDo not edit by hand; regenerate with scripts/sync-cmux-refs.sh\n-->\n\n' "$1" "$VER" "$DATE"; }

{
  prov "cmux --help ; cmux capabilities"
  echo "# cmux CLI verbs — vendored snapshot"
  echo
  echo '## `cmux --help`'
  echo '```'
  cmux --help 2>&1 || echo "(cmux --help unavailable)"
  echo '```'
  echo
  echo '## `cmux capabilities`'
  echo '```'
  cmux capabilities 2>&1 || echo "$CAP_FALLBACK"
  echo '```'
} > "$REF/cmux-verbs.snapshot.md"

{
  prov "cmux docs (index + topics) ; ls ~/.agents/skills/cmux*"
  echo "# cmux docs — vendored snapshot"
  echo
  echo '## `cmux docs`'
  echo '```'
  cmux docs 2>&1 || echo "(cmux docs unavailable)"
  echo '```'
  for t in api agents browser settings; do
    echo
    echo "## \`cmux docs $t\`"
    echo '```'
    cmux docs "$t" 2>&1 || echo "(unavailable)"
    echo '```'
  done
  echo
  echo '## Installed official /cmux skills on this machine'
  echo '```'
  ls -1 "$HOME/.agents/skills" 2>/dev/null | grep -i '^cmux' || echo "(none found)"
  echo '```'
  echo
  echo '## /cmux-workspace conventions (excerpt from the installed skill)'
  echo
  echo 'These non-disruptive rules are what cmux-team plans against; grounded here so the skill does not restate them from memory.'
  echo '```'
  if [ -f "$HOME/.agents/skills/cmux-workspace/SKILL.md" ]; then
    sed -n '1,60p' "$HOME/.agents/skills/cmux-workspace/SKILL.md"
  else
    echo "(cmux-workspace skill not installed)"
  fi
  echo '```'
} > "$REF/cmux-docs.snapshot.md"

echo "synced references at $VER ($DATE)"
