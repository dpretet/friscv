// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include "tty.h"

int echo(int argc, char *argv[]) {

    // Manage options, just echo if invalid
    // -n to avoid printing last new line
    
    // Just exit, we except at least argv[0]
    if (argc==0)
        return 1;

    // Just output a new line
    if (argc==1) {
        print_s("\n");

    // Print one by one the remaining argv
    } else {
        for (int i=1;i<argc;++i) {
            print_s(argv[i]);
            print_s(" ");
        }
    }
    return 0;
}
