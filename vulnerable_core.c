// vulnerable_core.c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void vulnerable_function(char* input) {
    char buffer[16];
    strcpy(buffer, input);  // Buffer overflow vulnerability
    printf("Buffer: %s\n", buffer);
}
