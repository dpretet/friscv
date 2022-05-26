// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#ifndef IRQ_INCLUDE
#define IRQ_INCLUDE

extern void irq_on();
extern void irq_off();
extern void msip_irq_on();
extern void msip_irq_off();
extern void mtip_irq_on();
extern void mtip_irq_off();
extern void meip_irq_on();
extern void meip_irq_off();

#endif // IRQ_INCLUDE
