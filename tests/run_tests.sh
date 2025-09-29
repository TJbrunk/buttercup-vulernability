#!/usr/bin/env bash
set -euo pipefail

# Basic smoke test that should NOT crash
# Exit non-zero on failure so the patcher can detect regressions.

BIN="./vuln_bin"
if [ ! -x "$BIN" ]; then
  echo "vuln_bin not found, attempting to build..."
  ./build.sh
fi

# Safe input (shorter than buffer). Should exit 0 and print Buffer.
"$BIN" "hello" > /dev/null 2>&1 || {
  echo "smoke test failed: vuln_bin crashed or returned non-zero" >&2
  exit 1
}

echo "smoke test passed"
exit 0
