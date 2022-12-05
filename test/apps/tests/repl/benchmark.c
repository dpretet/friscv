// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include "chacha20.h"
#include <stdint.h>
#include "tty.h"

// -----------------------------------------------------------------------------------------------
// Benchmarks global variables
// -----------------------------------------------------------------------------------------------

int chacha20_bench(int max_iterations);
int matrix_bench(int max_iterations);
int printf_bench(int max_iterations);

int chacha20_exe_time;
int matrix_exe_time = 0;
int printf_exe_time = 0;

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

    int ret=0;
    int bench_start, bench_end;
    chacha20_exe_time = 0;
    matrix_exe_time = 0;
    printf_exe_time = 0;

    asm volatile("csrr %0, 0xC00" : "=r"(bench_start));

    if (chacha20_bench(1))
        printf("Chacha20 computation failed\n");

    if (matrix_bench(1))
        printf("Matrix computation failed\n");

    if (printf_bench(1))
        printf("Printf computation failed\n");

    asm volatile("csrr %0, 0xC00" : "=r"(bench_end));

    printf("Start time: %x\n", bench_start);
    printf("End time: %x\n", bench_end);
    printf("Total elapsed time: %x cycles\n", bench_end-bench_start);

    if (chacha20_exe_time)
        printf("Chacha20 execution: %x cycles\n", chacha20_exe_time);

    if (matrix_exe_time)
        printf("Matrix execution: %x cycles\n", matrix_exe_time);

    if (printf_exe_time)
        printf("Printf execution: %x cycles\n", printf_exe_time);

    if (ret)
        ERROR("Benchmark failed\n");
    else
        SUCCESS("Benchmark finished successfully\n");

    return 0;
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
    int start = 0;
    int end = 0;

    asm volatile("csrr %0, 0xC00" : "=r"(start));

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

    asm volatile("csrr %0, 0xC00" : "=r"(end));

    chacha20_exe_time = end - start;

    return ret;
}

int matrix_bench(int max_iterations) {

    int ret = 0;
    int nb_loop=0;
    int start = 0;
    int end = 0;

    int matrix[3][3];

    asm volatile("csrr %0, 0xC00" : "=r"(start));

    while (nb_loop<max_iterations) {

        // a + b = x
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                matrix[i][j] = mtxa[i][j] + mtxb[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (matrix[i][j] != mtxc[i][j])
                    ret += 1;

        // b - a = a
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                matrix[i][j] = mtxb[i][j] - mtxa[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (matrix[i][j] != mtxa[i][j])
                    ret += 1;

        // c * d = mtx
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                matrix[i][j] = mtxc[i][j] * mtxd[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (matrix[i][j] != c_mult_d[i][j])
                    ret += 1;
        // a * b = b
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                matrix[i][j] = mtxa[i][j] * mtxb[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (matrix[i][j] != mtxb[i][j])
                    ret += 1;

        // a * c = c
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                matrix[i][j] = mtxa[i][j] * mtxc[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (matrix[i][j] != mtxc[i][j])
                    ret += 1;

        // a * d = d
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                matrix[i][j] = mtxa[i][j] * mtxd[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (matrix[i][j] != mtxd[i][j])
                    ret += 1;

        // d / 2 = b
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                matrix[i][j] = mtxd[i][j] / 2;

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (matrix[i][j] != mtxb[i][j])
                    ret += 1;

        //  c / a = c
        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                matrix[i][j] = mtxc[i][j] / mtxa[i][j];

        for (int i=0;i<3;i++)
            for (int j=0;j<3;j++)
                if (matrix[i][j] != mtxc[i][j])
                    ret += 1;

        nb_loop += 1;
    }

    asm volatile("csrr %0, 0xC00" : "=r"(end));

    matrix_exe_time = end - start;

    return ret;
}

int printf_bench(int max_iterations) {

    int nb_loop;
    int ret = 0;
    int start = 0;
    int end = 0;

    asm volatile("csrr %0, 0xC00" : "=r"(start));

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

    asm volatile("csrr %0, 0xC00" : "=r"(end));

    printf_exe_time = end - start;

    return ret;
}
