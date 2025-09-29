#!/usr/bin/env bash
set -euo pipefail

# Build libFuzzer harness (fuzzer) combining harness.c + vulnerable_core.c
clang -g -O1 -fsanitize=fuzzer,address,undefined -fno-omit-frame-pointer \
  harness.c vulnerable_core.c -o buttercup-demo

# Build standalone instrumented binary (vuln_bin) that accepts argv[1]
clang -g -O1 -fsanitize=address,undefined -fno-omit-frame-pointer \
  vulnerable_main.c vulnerable_core.c -o vuln_bin

echo "Built ./buttercup-demo and ./vuln_bin"