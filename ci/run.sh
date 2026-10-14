#!/usr/bin/env bash
# Run a command; on failure, publish the end of its output as a GitHub annotation
# (readable through the API even when the raw job log is not).
log="$(mktemp)"
set -o pipefail
"$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if [ "$status" -ne 0 ]; then
  msg="$(grep -v '^\s*$' "$log" | tail -n 120 | sed -e 's/%/%25/g' -e 's/\r//g' | awk '{printf "%s%%0A", $0}')"
  echo "::error title=$(basename "$1") failed::${msg}"
fi
exit "$status"
