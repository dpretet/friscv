// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdlib.h>
#include "clint.h"
#include "irq.h"
#include "tty.h"
#include "system.h"

int sleep(int argc, char * argv[]) {

    // Hardcoded to 1000, need to handle looow values,
    // which let to receive a trap before the wfi intructions
    int sleep_time = 1000;

    // Just sleep 100 cycles
    if (argc==0) {
        print_s("Will sleep 1000 cycles");
    }

    // Just output a new line
    if (argc>=1) {
        sleep_time = atoi(argv[1]);
    }

    irq_on();
    clint_set_mtime(0, 0);
    clint_set_mtimecmp(1000, 0);
    mtip_irq_on();
    wfi();
    mtip_irq_off();
    INFO("Slept!\n");
    return 0;
}
