// vulnerable_main.c
#include <stdlib.h>

// forward declaration
void vulnerable_function(char* input);

int main(int argc, char* argv[]) {
    if (argc > 1) {
        vulnerable_function(argv[1]);
    }
    return 0;
}
