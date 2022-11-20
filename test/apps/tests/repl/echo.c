// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include "tty.h"

int echo(int argc, char * argv[]) {

    // Just exit, we except at least argv[0]
    if (argc==0) {
        print_s("No argument here");
        return 1;
    }

    // Just output a new line
    if (argc==1) {
        print_s("Just one argument here");
        print_s("\n");
        return 0;
    }

    // Print one by one the remaining argv
    for (int i=1;i<argc;++i) {
        print_s(argv[i]);
        print_s(" ");
    }

    return 0;
}
