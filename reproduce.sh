#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <crash-file>" >&2
  exit 2
fi

CRASH="$1"
BINARY="./vuln_bin"
FUZZER="./fuzzer"
OUTDIR="repro_output"
mkdir -p "$OUTDIR"

export ASAN_OPTIONS="abort_on_error=1:detect_leaks=0:symbolize=1"
export UBSAN_OPTIONS="print_stacktrace=1"
export LSAN_OPTIONS="verbosity=0"

# Ensure the instrumented binaries exist; try to build if missing.
if [ ! -x "$BINARY" ] || [ ! -x "$FUZZER" ]; then
  if [ -x "./build.sh" ]; then
    echo "Building instrumented binaries with ./build.sh"
    ./build.sh
  fi
fi

echo "=== Reproducing with vuln_bin (argv) ===" | tee "$OUTDIR/run.log"
set +e
# pass crash content as argv[1]
"$BINARY" "$(cat "$CRASH")" > "$OUTDIR/stdout.txt" 2> "$OUTDIR/stderr.txt"
RC=$?
set -e
echo "vuln_bin_exit_code=$RC" | tee -a "$OUTDIR/run.log"

# If no sanitizer output found, try libFuzzer-built fuzzer with crash as arg
if ! grep -q -E "AddressSanitizer|UndefinedBehaviorSanitizer|runtime error" "$OUTDIR/stderr.txt" 2>/dev/null; then
  if [ -x "$FUZZER" ]; then
    echo "No sanitizer output from vuln_bin; trying fuzzer with crash as arg" | tee -a "$OUTDIR/run.log"
    set +e
    "$FUZZER" "$CRASH" >> "$OUTDIR/stdout.txt" 2>> "$OUTDIR/stderr.txt"
    RC2=$?
    set -e
    echo "fuzzer_arg_exit_code=$RC2" | tee -a "$OUTDIR/run.log"
  fi
fi

# Also try piping to stdin for harnesses that read stdin
if ! grep -q -E "AddressSanitizer|UndefinedBehaviorSanitizer|runtime error" "$OUTDIR/stderr.txt" 2>/dev/null; then
  if [ -x "$FUZZER" ]; then
    echo "No sanitizer output yet; trying fuzzer with stdin" | tee -a "$OUTDIR/run.log"
    set +e
    "$FUZZER" < "$CRASH" >> "$OUTDIR/stdout.txt" 2>> "$OUTDIR/stderr.txt"
    RC3=$?
    set -e
    echo "fuzzer_stdin_exit_code=$RC3" | tee -a "$OUTDIR/run.log"
  fi
fi

# Save sanitizer output
cp -v "$OUTDIR/stderr.txt" "$OUTDIR/sanitizer.log" || true

# Try symbolizing addresses (best-effort)
if command -v llvm-symbolizer >/dev/null 2>&1 && [ -f "$OUTDIR/sanitizer.log" ]; then
  echo "Attempting llvm-symbolizer..." | tee -a "$OUTDIR/run.log"
  llvm-symbolizer -e "$BINARY" < "$OUTDIR/sanitizer.log" > "$OUTDIR/sanitizer_symbolized.log" 2>&1 || true
fi

# Try gdb backtrace (best-effort)
if command -v gdb >/dev/null 2>&1 && [ -x "$BINARY" ]; then
  echo "Attempting gdb batch backtrace..." | tee -a "$OUTDIR/run.log"
  ARGVAL="$(cat "$CRASH")"
  set +e
  gdb -batch --args "$BINARY" "$ARGVAL" -ex "run" -ex "thread apply all bt full" > "$OUTDIR/gdb_bt.txt" 2>&1 || true
  set -e
fi

echo "Reproducer finished. Outputs in: $OUTDIR"
