#!/usr/bin/env bash
# Builds native assets before the full test run, retrying the sqlite3 download.
#
# sqlite3's build hook fetches a prebuilt library from GitHub releases and
# hashes whatever comes back. When GitHub answers 429 or 5xx, the error page
# is reported as a hash mismatch and the whole job fails. The hash check is
# left in place: a real mismatch still fails after the retries. The built
# result is cached in .dart_tool, so the tests that follow don't download.
set -uo pipefail

log="${RUNNER_TEMP:-/tmp}/warm-native-assets.log"
for wait in 30 60 120 240 0; do
  flutter test test/bastion_bot_rules_test.dart > "$log" 2>&1
  status=$?
  if ! grep -q 'Building native assets failed' "$log"; then
    # Any other result, pass or fail, is for the real test run to report.
    echo "Native assets ready (quick test exit code $status)"
    exit 0
  fi
  grep -E 'Hash of downloaded file|Building assets for package' "$log" | sort -u
  if [ "$wait" -gt 0 ]; then
    echo "Native asset build failed; retrying in ${wait}s"
    sleep "$wait"
  fi
done
echo "::error::Native assets still could not be built after 5 attempts"
exit 1
