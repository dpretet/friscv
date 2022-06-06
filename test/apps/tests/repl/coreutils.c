// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <string.h>
#include "tty.h"

///////////////////////////////////////////////////////////////////////////////
// Used to extract from a string the arguments of a functions
//
// Arguments:
//
//   - istring: the command to parse and extract
//
// Returns:
//   - argv: the arguments extracted, assuming thy are space separated
//  -  the number of arguments extracted
//
///////////////////////////////////////////////////////////////////////////////
int get_args(char istring[], char *argv[]) {

    int i = 0;
    const char *delimeter = " ";
    char *saveptr1;

    argv[0] = strtok_r(istring, delimeter, &saveptr1);

    do {
        i+=1;
        argv[i] =  strtok_r(NULL, delimeter, &saveptr1);
    } while(argv[i] != NULL);

    return i;
}
