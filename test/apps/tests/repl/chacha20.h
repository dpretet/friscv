// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#ifndef CHACHA20_INCLUDE
#define CHACHA20_INCLUDE

#include <stdint.h>

void chacha20_quarter(uint32_t *a, uint32_t *b, uint32_t *c, uint32_t *d);

void chacha20_inner_block(uint32_t * state);

uint32_t reverse_to_dword(uint32_t * data);

void chacha20_block(uint32_t * key, uint32_t * counter, uint32_t * nonce,  uint32_t * state);

void chacha20_serialize(uint32_t * block, char * serial);

#endif

