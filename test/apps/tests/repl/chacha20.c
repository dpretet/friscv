// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdint.h>

#define rotl32(x, n) \
    (x << n) | (x >> (32 - n))

void chacha20_quarter(uint32_t *a, uint32_t *b, uint32_t *c, uint32_t *d) {

    *a += *b;
    *d ^= *a;
    *d = rotl32(*d, 16);

    *c += *d;
    *b ^= *c;
    *b = rotl32(*b, 12);

    *a += *b;
    *d ^= *a;
    *d = rotl32(*d, 8);

    *c += *d;
    *b ^= *c;
    *b = rotl32(*b, 7);
}

void chacha20_inner_block(uint32_t * state) {
    chacha20_quarter((state+0),(state+4),(state+8),(state+12));
    chacha20_quarter((state+1),(state+5),(state+9),(state+13));
    chacha20_quarter((state+2),(state+6),(state+10),(state+14));
    chacha20_quarter((state+3),(state+7),(state+11),(state+15));
    chacha20_quarter((state+0),(state+5),(state+10),(state+15));
    chacha20_quarter((state+1),(state+6),(state+11),(state+12));
    chacha20_quarter((state+2),(state+7),(state+8),(state+13));
    chacha20_quarter((state+3),(state+4),(state+9),(state+14));
}

uint32_t reverse_to_dword(uint32_t * data) {

    uint32_t temp = 0;
    temp = *(data+3) << 24;
    temp = temp | (*(data+2) << 16);
    temp = temp | (*(data+1) << 8);
    temp = temp | *(data);
    return temp;
};

void chacha20_block(uint32_t * key, uint32_t * counter, uint32_t * nonce, uint32_t * state) {

    uint32_t working_state[16];
    const uint32_t constant[4] = {0x61707865, 0x3320646e, 0x79622d32, 0x6b206574};

    state[0] = constant[0];
    state[1] = constant[1];
    state[2] = constant[2];
    state[3] = constant[3];

    state[4] = reverse_to_dword(key+0);
    state[5] = reverse_to_dword(key+4);
    state[6] = reverse_to_dword(key+8);
    state[7] = reverse_to_dword(key+12);
    state[8] = reverse_to_dword(key+16);
    state[9] = reverse_to_dword(key+20);
    state[10] = reverse_to_dword(key+24);
    state[11] = reverse_to_dword(key+28);

    state[12] = *counter;

    state[13] = reverse_to_dword(nonce+0);
    state[14] = reverse_to_dword(nonce+4);
    state[15] = reverse_to_dword(nonce+8);

    for (int i=0;i<16;i++) {
        working_state[i] = state[i];
    }

    for (int i=0;i<10;i++) {
        chacha20_inner_block(working_state);
    }

    for (int i=0;i<16;i++) {
        state[i] += working_state[i];
    }
};

void chacha20_serialize(uint32_t * block, char * serial) {

    for (int i=0;i<16;i++) {
        serial[i*4+0] = (block[i] & 0xFF);
        serial[i*4+1] = ((block[i] >> 8) & 0xFF);
        serial[i*4+2] = ((block[i] >> 16) & 0xFF);
        serial[i*4+3] = ((block[i] >> 24) & 0xFF);
    }

}
