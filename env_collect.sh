#!/usr/bin/env bash
set -euo pipefail
OUT="env_info.txt"
{
  echo "=== date ==="
  date
  echo
  echo "=== uname -a ==="
  uname -a
  echo
  echo "=== lsb_release (if available) ==="
  lsb_release -a 2>/dev/null || true
  echo
  echo "=== clang --version ==="
  clang --version 2>/dev/null || true
  echo
  echo "=== gcc --version ==="
  gcc --version 2>/dev/null || true
  echo
  echo "=== ldd --version ==="
  ldd --version 2>/dev/null || true
  echo
  echo "=== pkg-config --modversion (libc) ==="
  pkg-config --modversion glibc 2>/dev/null || true
} > "$OUT"
echo "Wrote $OUT"
