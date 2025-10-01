#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

// Simple vulnerable function with buffer overflow
void process_input(const uint8_t *data, size_t size) {
    char buffer[16];

    // Vulnerable: no bounds checking!
    memcpy(buffer, data, size);

    printf("Processed: %s\n", buffer);
}

// Fuzzing harness
int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    if (size == 0) {
        return 0;
    }

    process_input(data, size);

    return 0;
}
