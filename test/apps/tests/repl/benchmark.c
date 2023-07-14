// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdlib.h>
#include <stdint.h>
#include "chacha20.h"
#include "xoshiro128plusplus.h"
#include "pool_arena.h"
#include "tty.h"

// -----------------------------------------------------------------------------------------------
// Benchmarks global variables
// -----------------------------------------------------------------------------------------------

int chacha20_bench(int max_iterations);
int matrix_bench(int max_iterations);
int printf_bench(int max_iterations);
int xoshi_bench(int max_iterations);
int pool_arena_bench(int max_iterations);

struct perf {
	int active_start;
	int active_end;
	int sleep_start;
	int sleep_end;
	int stall_start;
	int stall_end;
};

struct meter {
    int cycle_start;
    int cycle_end;
    int instret_start;
    int instret_end;
    int cycles;
    int instret;
	struct perf instreq_perf;
	struct perf instcpl_perf;
	struct perf proc_perf;
};

struct meter bench;
struct meter chacha20;
struct meter matrix;
struct meter print;
struct meter xoshi;
struct meter arena;

#define ARENA_SIZE 1024
#define MAX_CHUNK  8

// -----------------------------------------------------------------------------------------------
// Chacha20 global variables
// -----------------------------------------------------------------------------------------------

uint32_t key[32] = {
    0x00,0x01,0x02,0x03,
    0x04,0x05,0x06,0x07,
    0x08,0x09,0x0a,0x0b,
    0x0c,0x0d,0x0e,0x0f,
    0x10,0x11,0x12,0x13,
    0x14,0x15,0x16,0x17,
    0x18,0x19,0x1a,0x1b,
    0x1c,0x1d,0x1e,0x1f
};

uint32_t nonce[12]= {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x4a,0x00,0x00,0x00,0x00};

const int text_length = 114;

char text[128] = {
    0x4c,0x61,0x64,0x69,0x65,0x73,0x20,0x61,0x6e,0x64,0x20,0x47,0x65,0x6e,0x74,0x6c,
    0x65,0x6d,0x65,0x6e,0x20,0x6f,0x66,0x20,0x74,0x68,0x65,0x20,0x63,0x6c,0x61,0x73,
    0x73,0x20,0x6f,0x66,0x20,0x27,0x39,0x39,0x3a,0x20,0x49,0x66,0x20,0x49,0x20,0x63,
    0x6f,0x75,0x6c,0x64,0x20,0x6f,0x66,0x66,0x65,0x72,0x20,0x79,0x6f,0x75,0x20,0x6f,
    0x6e,0x6c,0x79,0x20,0x6f,0x6e,0x65,0x20,0x74,0x69,0x70,0x20,0x66,0x6f,0x72,0x20,
    0x74,0x68,0x65,0x20,0x66,0x75,0x74,0x75,0x72,0x65,0x2c,0x20,0x73,0x75,0x6e,0x73,
    0x63,0x72,0x65,0x65,0x6e,0x20,0x77,0x6f,0x75,0x6c,0x64,0x20,0x62,0x65,0x20,0x69,
    0x74,0x2e,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
};

char ciphertext[128] = {
    0x6e,0x2e,0x35,0x9a,0x25,0x68,0xf9,0x80,0x41,0xba,0x07,0x28,0xdd,0x0d,0x69,0x81,
    0xe9,0x7e,0x7a,0xec,0x1d,0x43,0x60,0xc2,0x0a,0x27,0xaf,0xcc,0xfd,0x9f,0xae,0x0b,
    0xf9,0x1b,0x65,0xc5,0x52,0x47,0x33,0xab,0x8f,0x59,0x3d,0xab,0xcd,0x62,0xb3,0x57,
    0x16,0x39,0xd6,0x24,0xe6,0x51,0x52,0xab,0x8f,0x53,0x0c,0x35,0x9f,0x08,0x61,0xd8,
    0x07,0xca,0x0d,0xbf,0x50,0x0d,0x6a,0x61,0x56,0xa3,0x8e,0x08,0x8a,0x22,0xb6,0x5e,
    0x52,0xbc,0x51,0x4d,0x16,0xcc,0xf8,0x06,0x81,0x8c,0xe9,0x1a,0xb7,0x79,0x37,0x36,
    0x5a,0xf9,0x0b,0xbf,0x74,0xa3,0x5b,0xe6,0xb4,0x0b,0x8e,0xed,0xf2,0x78,0x5e,0x42,
    0x87,0x4d,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
};

// -----------------------------------------------------------------------------------------------
// Matrix global variables
// -----------------------------------------------------------------------------------------------

int mtxa[3][3] = {{1,1,1}, {1,1,1}, {1,1,1}};
int mtxb[3][3] = {{2,2,2}, {2,2,2}, {2,2,2}};
int mtxc[3][3] = {{3,3,3}, {3,3,3}, {3,3,3}};
int mtxd[3][3] = {{4,4,4}, {4,4,4}, {4,4,4}};

int c_mult_d[3][3] = {{12,12,12}, {12,12,12}, {12,12,12}};


/*  Benchmark function to measure the performance of the core
 *
 *  Arguments: the name of a specific test (chacha20, matrix ...) or all
 *             if nothing specified, run all the available tests
 *
 *  Returns: 0 on success, otherwise a positive number
 */
int benchmark(int argc, char *argv[]) {

    int nb_iterations = 1;
    int ret=0;

    bench.cycle_start = 0;
    bench.cycle_end = 0;
    bench.instret_start = 0;
    bench.instret_end = 0;
    bench.cycles = 0;
    bench.instret = 0;

    asm volatile("csrr %0, 0xC00" : "=r"(bench.cycle_start));
    asm volatile("csrr %0, 0xC02" : "=r"(bench.instret_start));

    asm volatile("csrr %0, 0xFC0" : "=r"(bench.instreq_perf.active_start));
    asm volatile("csrr %0, 0xFC1" : "=r"(bench.instreq_perf.sleep_start));
    asm volatile("csrr %0, 0xFC2" : "=r"(bench.instreq_perf.stall_start));

    asm volatile("csrr %0, 0xFC3" : "=r"(bench.instcpl_perf.active_start));
    asm volatile("csrr %0, 0xFC4" : "=r"(bench.instcpl_perf.sleep_start));
    asm volatile("csrr %0, 0xFC5" : "=r"(bench.instcpl_perf.stall_start));

    asm volatile("csrr %0, 0xFC6" : "=r"(bench.proc_perf.active_start));
    asm volatile("csrr %0, 0xFC7" : "=r"(bench.proc_perf.sleep_start));
    asm volatile("csrr %0, 0xFC8" : "=r"(bench.proc_perf.stall_start));

    // -----------------------------------------------------------------
    // Execute benchmarks
    // -----------------------------------------------------------------

    if (chacha20_bench(nb_iterations)) {
        ret += 1;
        printf("Chacha20 computation failed\n");
    }

    if (matrix_bench(nb_iterations)) {
        ret += 1;
        printf("Matrix computation failed\n");
    }

    if (printf_bench(nb_iterations)) {
        ret += 1;
        printf("Printf computation failed\n");
    }

    if (xoshi_bench(nb_iterations)) {
        ret += 1;
        printf("Xoshiro128++ computation failed\n");
    }

    if (pool_arena_bench(nb_iterations)) {
        ret += 1;
        printf("Pool Arena computation failed\n");
    }

    asm volatile("csrr %0, 0xC00" : "=r"(bench.cycle_end));
    asm volatile("csrr %0, 0xC02" : "=r"(bench.instret_end));

    asm volatile("csrr %0, 0xFC0" : "=r"(bench.instreq_perf.active_end));
    asm volatile("csrr %0, 0xFC1" : "=r"(bench.instreq_perf.sleep_end));
    asm volatile("csrr %0, 0xFC2" : "=r"(bench.instreq_perf.stall_end));

    asm volatile("csrr %0, 0xFC3" : "=r"(bench.instcpl_perf.active_end));
    asm volatile("csrr %0, 0xFC4" : "=r"(bench.instcpl_perf.sleep_end));
    asm volatile("csrr %0, 0xFC5" : "=r"(bench.instcpl_perf.stall_end));

    asm volatile("csrr %0, 0xFC6" : "=r"(bench.proc_perf.active_end));
    asm volatile("csrr %0, 0xFC7" : "=r"(bench.proc_perf.sleep_end));
    asm volatile("csrr %0, 0xFC8" : "=r"(bench.proc_perf.stall_end));


    bench.cycles = bench.cycle_end - bench.cycle_start;
    bench.instret = bench.instret_end - bench.instret_start;

    // -----------------------------------------------------------------
    // Print statistics
    // -----------------------------------------------------------------

    printf("\nReporting:\n");

	printf("\nGeneral statistics:\n");
    printf("  - Start time: %d\n", bench.cycle_start);
    printf("  - End time: %d\n", bench.cycle_end);
    printf("  - Total elapsed time: %d cycles\n", bench.cycles);
    printf("  - Instret start: %d\n", bench.instret_start);
    printf("  - Instret end: %d\n", bench.instret_end);
    printf("  - Retired instructions: %d\n", bench.instret);

	printf("\nInstruction Bus Request:\n");
	printf("  - active cycles: %d\n", bench.instreq_perf.active_end - bench.instreq_perf.active_start);
	printf("  - sleep cycles: %d\n", bench.instreq_perf.sleep_end - bench.instreq_perf.sleep_start);
	printf("  - stall cycles: %d\n", bench.instreq_perf.stall_end - bench.instreq_perf.stall_start);

	printf("\nInst Bus Completion:\n");
	printf("  - active cycles: %d\n", bench.instcpl_perf.active_end - bench.instcpl_perf.active_start);
	printf("  - sleep cycles: %d\n", bench.instcpl_perf.sleep_end - bench.instcpl_perf.sleep_start);
	printf("  - stall cycles: %d\n", bench.instcpl_perf.stall_end - bench.instcpl_perf.stall_start);

	printf("\nProcessing Bus:\n");
	printf("  - active cycles: %d\n", bench.proc_perf.active_end - bench.proc_perf.active_start);
	printf("  - sleep cycles: %d\n", bench.proc_perf.sleep_end - bench.proc_perf.sleep_start);
	printf("  - stall cycles: %d\n", bench.proc_perf.stall_end - bench.proc_perf.stall_start);

	printf("\nAlgorithms:\n");
    printf("- Chacha20 execution: %d cycles\n", chacha20.cycles);
    printf("- Matrix execution: %d cycles\n", matrix.cycles);
    printf("- Printf execution: %d cycles\n", print.cycles);
    printf("- Xoshiro128++ execution: %d cycles\n", xoshi.cycles);
    printf("- Pool Arena execution: %d cycles\n", arena.cycles);

    if (ret)
        ERROR("Benchmark failed\n");
    else
        SUCCESS("Benchmark finished successfully\n");

    return ret;
}


/* Execute Chacha20 on test vector proposed by the specification
 *
 * Arguments:
 *      max_iterations: number of repetitions to execute
 * Returns:
 *      the number of error detected between the reference and the computed data
 */
int chacha20_bench(int max_iterations) {

    uint32_t block1[16];
    uint32_t block2[16];
    uint32_t block_counter;
    char serial[64];
    int ret = 0;
    int nb_loop=0;
    char data[128];

    chacha20.cycle_start = 0;
    chacha20.cycle_end = 0;
    chacha20.cycles = 0;

    asm volatile("csrr %0, 0xC00" : "=r"(chacha20.cycle_start));

    while (nb_loop<max_iterations) {

        block_counter = 0x1;

        chacha20_block(key, &block_counter, nonce, block1);
        chacha20_serialize(block1, serial);

        for (int i=0;i<64;i++) {
            data[i] = text[i] ^ serial[i];
        }

        block_counter = 0x2;
        chacha20_block(key, &block_counter, nonce, block2);
        chacha20_serialize(block2, serial);

        for (int i=64;i<128;i++) {
            data[i] = text[i] ^ serial[i-64];
        }

        for (int i=0;i<text_length;i++) {
            if (data[i]!=ciphertext[i])
                ret += 1;
        }
        nb_loop += 1;
    }

    asm volatile("csrr %0, 0xC00" : "=r"(chacha20.cycle_end));

    chacha20.cycles = chacha20.cycle_end - chacha20.cycle_start;

    return ret;
}

int matrix_bench(int max_iterations) {

    int ret = 0;
    int nb_loop=0;
    matrix.cycle_start = 0;
    matrix.cycle_end = 0;
    matrix.cycles = 0;

    int mtx[3][3];

    asm volatile("csrr %0, 0xC00" : "=r"(matrix.cycle_start));

    while (nb_loop<max_iterations) {

        // a + b = x
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                mtx[i][j] = mtxa[i][j] + mtxb[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (mtx[i][j] != mtxc[i][j])
                    ret += 1;

        // b - a = a
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                mtx[i][j] = mtxb[i][j] - mtxa[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (mtx[i][j] != mtxa[i][j])
                    ret += 1;

        // c * d = mtx
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                mtx[i][j] = mtxc[i][j] * mtxd[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (mtx[i][j] != c_mult_d[i][j])
                    ret += 1;
        // a * b = b
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                mtx[i][j] = mtxa[i][j] * mtxb[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (mtx[i][j] != mtxb[i][j])
                    ret += 1;

        // a * c = c
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                mtx[i][j] = mtxa[i][j] * mtxc[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (mtx[i][j] != mtxc[i][j])
                    ret += 1;

        // a * d = d
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                mtx[i][j] = mtxa[i][j] * mtxd[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (mtx[i][j] != mtxd[i][j])
                    ret += 1;

        // d / 2 = b
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                mtx[i][j] = mtxd[i][j] / 2;

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (mtx[i][j] != mtxb[i][j])
                    ret += 1;

        //  c / a = c
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                mtx[i][j] = mtxc[i][j] / mtxa[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (mtx[i][j] != mtxc[i][j])
                    ret += 1;

        nb_loop += 1;
    }

    asm volatile("csrr %0, 0xC00" : "=r"(matrix.cycle_end));

    matrix.cycles = matrix.cycle_end - matrix.cycle_start;

    return ret;
}

int printf_bench(int max_iterations) {

    int nb_loop;
    int ret = 0;
    print.cycle_start = 0;
    print.cycle_end = 0;
    print.cycles = 0;

    asm volatile("csrr %0, 0xC00" : "=r"(print.cycle_start));

    printf("\nPrintf debug information:\n");

    while (nb_loop<max_iterations) {

        ret += printf("Single digit integer:\n");
        ret += printf("Zero: %d\n", 0);
        ret += printf("One: %d\n", 1);
        ret += printf("Minus five: %d\n", -5);
        ret += printf("Multi digit integers:\n");
        ret += printf("%d\n", 47);
        ret += printf("%d\n", -234);
        ret += printf("%d\n", 234);
        ret += printf("%d\n", 9876);
        ret += printf("%d\n", 2147483647);
        ret += printf("Integer in hexadecimal: %x\n", 0xFDC0ACBD);
        ret += printf("A char: %c\n", 'X');
        ret += printf("Line mixing char and int:\n");
        ret += printf("int: %d char: %c\n", 9, 'Y');
        ret += printf("Empty new line:\n");
        ret += printf("\n");
        ret += printf("A string: %s\n", "I am a string");
        ret += printf("Multi strings printed in a line:\n");
        ret += printf("String: %s\nString: %s\n", "a first", "the second");
        ret += printf("Another multi string, bullets, using new line and tabulation:\n");
        ret += printf("\t- abc\n");
        ret += printf("\t- def\n");
        ret += printf("Unsupported formatting, leaved as is:\n");
        ret += printf("%f\n", 'z');
        ret += printf("%o\n", 'z');
        ret += printf("Escaped backslash or lonely percent symbol\n");
        ret += printf("\\ % \n");
        nb_loop += 1;
    }

    asm volatile("csrr %0, 0xC00" : "=r"(print.cycle_end));

    print.cycles = print.cycle_end - print.cycle_start;

    return ret;
}


// xoshiro128++ algorithm used to generate random number for 32 bits architecture
// Run over 1024 iterations
int xoshi_bench(int max_iterations) {

    int nb_loop;
    int ret = 0;
    xoshi.cycle_start = 0;
    xoshi.cycle_end = 0;
    xoshi.cycles = 0;

    asm volatile("csrr %0, 0xC00" : "=r"(xoshi.cycle_start));

    for (int i=0; i<1024;i++)
        xoshiro128plusplus();

    asm volatile("csrr %0, 0xC00" : "=r"(xoshi.cycle_end));

    xoshi.cycles = xoshi.cycle_end - xoshi.cycle_start;

    return ret;
}

int pool_arena_bench(int max_iterations) {

	char pool[ARENA_SIZE];
	int p=0;
	void * pts[MAX_CHUNK];
	unsigned int chunk_size = 1;
	char * array;

    arena.cycle_start = 0;
    arena.cycle_end = 0;
    arena.cycles = 0;

    asm volatile("csrr %0, 0xC00" : "=r"(arena.cycle_start));

	// Erase first the pool memory zone
	for (int i=0;i<ARENA_SIZE;i++)
		pool[i] = '\0';
	// Create a pool arena in memory
	pool_init(&pool, ARENA_SIZE);
	/* printf("Pool arena: %p\n", &pool); */

	while (chunk_size < ARENA_SIZE) {
		// Erase pointers
		for (int i=0;i<16;i++) {
			pts[i] = NULL;
		}
		// Allocate as much blocks as possible and stop at first fail
		/* printf("Allocate chunks\n"); */
		p = 0;
		while (p<MAX_CHUNK) {
			pts[p] = pool_malloc(chunk_size);
			if (pts[p] == NULL)
				break;
			printf("%p\n", pts[p]);
			p++;
		}


		// Init the chunks with data
		for (int i=0;i<16;i++) {
			if (pts[i] != NULL) {
				array = pts[i];
				for (int j=0;j<chunk_size;j++)
					array[j] = i;
			}
		}
		// Check back data
		for (int i=0;i<16;i++) {
			if (pts[i] != NULL) {
				array = pts[i];
				for (int j=0;j<chunk_size;j++)
					if (array[j] != i) {
						printf("ERROR: pool arena failed during data check\n");
						return 1;
					}
			}
		}
		// Free the pointers
		/* printf("Free chunks\n"); */
		p = 0;
		while (p<MAX_CHUNK) {
			if (pts[p] != NULL)
				pool_free(pts[p]);
			else
				break;
			p++;
		}

		pool_check();
		chunk_size += 1;
	}

    asm volatile("csrr %0, 0xC00" : "=r"(arena.cycle_end));

    arena.cycles = arena.cycle_end - arena.cycle_start;


	return 0;
}
