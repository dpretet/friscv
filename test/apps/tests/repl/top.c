// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#include "printf.h"

struct perf {
	int active;
	int sleep;
	int stall;
};

void top(void) {

	int cycles;
	int instret;

	struct perf instreq;
	struct perf instcpl;
	struct perf proc;

    asm volatile("csrr %0, 0xC00" : "=r"(cycles));
    asm volatile("csrr %0, 0xC02" : "=r"(instret));

    asm volatile("csrr %0, 0xFC0" : "=r"(instreq.active));
    asm volatile("csrr %0, 0xFC1" : "=r"(instreq.sleep));
    asm volatile("csrr %0, 0xFC2" : "=r"(instreq.stall));

    asm volatile("csrr %0, 0xFC3" : "=r"(instcpl.active));
    asm volatile("csrr %0, 0xFC4" : "=r"(instcpl.sleep));
    asm volatile("csrr %0, 0xFC5" : "=r"(instcpl.stall));

    asm volatile("csrr %0, 0xFC6" : "=r"(proc.active));
    asm volatile("csrr %0, 0xFC7" : "=r"(proc.sleep));
    asm volatile("csrr %0, 0xFC8" : "=r"(proc.stall));

	printf("\nStatistics:\n");
    printf("  - Total elapsed time: %d cycles\n", cycles);
    printf("  - Retired instructions: %d\n", instret);

	printf("\nInstruction Bus Request:\n");
	printf("  - active cycles: %d\n", instreq.active);
	printf("  - sleep cycles: %d\n", instreq.sleep);
	printf("  - stall cycles: %d\n", instreq.stall);

	printf("\nInst Bus Completion:\n");
	printf("  - active cycles: %d\n", instcpl.active);
	printf("  - sleep cycles: %d\n", instcpl.sleep);
	printf("  - stall cycles: %d\n", instcpl.stall);

	printf("\nProcessing Bus:\n");
	printf("  - active cycles: %d\n", proc.active);
	printf("  - sleep cycles: %d\n", proc.sleep);
	printf("  - stall cycles: %d\n", proc.stall);
}

