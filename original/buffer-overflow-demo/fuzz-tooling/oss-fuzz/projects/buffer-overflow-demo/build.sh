#!/bin/bash -eu

# Build script for OSS-Fuzz
cd $SRC

# Compile the fuzzer
$CC $CFLAGS $LIB_FUZZING_ENGINE vulnerable.c -o $OUT/fuzzer
