# Buffer Overflow Demo

This is a simple demonstration project with a buffer overflow vulnerability.

## Building

To build the fuzzer:

```bash
./BUILD.sh
```

This will create a `fuzzer` executable compiled with AddressSanitizer and libFuzzer.

## Running

To run the fuzzer:

```bash
./fuzzer
```

To reproduce a crash:

```bash
./fuzzer crash_input.bin
```

## Files

- `vulnerable.c` - Main source file containing the vulnerable `process_input` function
- `BUILD.sh` - Build script for compiling with sanitizers
- `fuzzer` - Compiled fuzzer binary (after build)

## Vulnerability

The `process_input` function contains a stack buffer overflow vulnerability. It uses `memcpy` to copy user-controlled data into a fixed-size 16-byte buffer without checking the size parameter, allowing writes beyond the buffer boundary.
