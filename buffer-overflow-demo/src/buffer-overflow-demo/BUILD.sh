#!/bin/bash
set -e

# Compile with AddressSanitizer
clang -g -O1 -fsanitize=address,fuzzer vulnerable.c -o fuzzer

echo "Build complete: fuzzer"
