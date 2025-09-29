#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-bugpkg}"
PKGDIR="bug_package_${NAME}"
mkdir -p "$PKGDIR"

# required content (adjust as needed)
cp -v build.sh metadata.json "$PKGDIR/" 2>/dev/null || true
cp -v vulnerable_core.c vulnerable_main.c harness.c "$PKGDIR/" 2>/dev/null || true

# copy crashes if present
for c in crash-* crash-*.* crash-demo; do
  [ -f "$c" ] || continue
  cp -v "$c" "$PKGDIR/" || true
done

# build instrumented binaries if not present
if [ ! -x "./vuln_bin" ] && [ -x "./build.sh" ]; then
  ./build.sh
fi

cp -v vuln_bin fuzzer "$PKGDIR/" 2>/dev/null || true

# copy reproduce script and tests
cp -v reproduce.sh "$PKGDIR/" 2>/dev/null || true
if [ -d tests ]; then
  mkdir -p "$PKGDIR/tests"
  cp -rv tests/* "$PKGDIR/tests/" 2>/dev/null || true
fi

# collect env info
./env_collect.sh
cp -v env_info.txt "$PKGDIR/" 2>/dev/null || true

# run reproduce for each crash file to capture logs
for c in "$PKGDIR"/crash-*; do
  [ -f "$c" ] || continue
  ./reproduce.sh "$c" || true
  mv -v repro_output "$PKGDIR/repro_$(basename "$c")" || true
done

tar -czvf "${PKGDIR}.tar.gz" "$PKGDIR"
echo "Created ${PKGDIR}.tar.gz"
