// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include "printf.h"

int echo(int argc, char * argv[]) {

    // Just exit, we except at least argv[0]
    if (argc==0) {
        _print("No argument here\n");
        return 1;
    }

    // Just output a new line
    if (argc==1) {
        return 0;
    }

    // Print one by one the remaining argv
    for (int i=1;i<argc;++i) {
        _print("%s ", argv[i]);
    }

    return 0;
}
