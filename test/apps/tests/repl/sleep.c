// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#include "clint.h"
#include "irq.h"
#include "tty.h"
#include "system.h"

int sleep(int argc, char * argv[]) {

    irq_on();
    clint_set_mtime(0, 0);
    clint_set_mtimecmp(100, 0);
    mtip_irq_on();
    wfi();
    mtip_irq_off();
    INFO("Slept!\n");
    return 0;
}
