// harness.c
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>   // <-- needed for memcpy

// declare the vulnerable function from vulnerable.c
void vulnerable_function(char* input);

int LLVMFuzzerTestOneInput(const uint8_t *Data, size_t Size) {
    // Create a nul-terminated buffer for the vulnerable API
    char *buf = (char*)malloc(Size + 1);
    if (!buf) return 0;
    memcpy(buf, Data, Size);
    buf[Size] = '\0';
    vulnerable_function(buf);
    free(buf);
    return 0;
}
