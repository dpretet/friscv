// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#include <stdio.h>
#include <string.h>
#include "pool_arena.h"

// -----------------------------------------------------------------------------------------------
// Local declarations
// -----------------------------------------------------------------------------------------------

// The basic data structure describing a free space arena element
struct blk {
    // Size of the data payload
    unsigned int size;
    // Pointer to the previous block. 0 means not assigned
    struct blk * prv;
    // Pointer to the next block. 0 means not assigned
    struct blk * nxt;
};

typedef struct blk blk_t;

// Size of a memory element, 32 or 64 bits
const static unsigned int reg_size = sizeof(void *);
const static unsigned int log2_reg_size = (reg_size == 4) ? 2 : 3;
// Size of a block header: size, previous & next block addresses
const static unsigned int header_size = 3 * reg_size;

// Current free space manipulated by the arena
static blk_t * current;
// temporary struct used when forking/merging blocks
static blk_t * tmp_blk;
// Used to store the original block address before parsing the free space blocks
static void * tmp_pt;
static void * pool_addr;

// Used to track arena status during usage and check if no leaks occur
static unsigned int pool_size;
static int nb_alloc_blk;
static int nb_free_blk;
static unsigned int alloc_space;
static unsigned int free_space;

/*
 * Internal functions
 */

// Find free space when freeing
static inline void * get_loc_to_free(void * addr);
// Find free space when allocating
static inline void * get_loc_to_place(void * addr, unsigned int place);


// -----------------------------------------------------------------------------------------------
// Called by the environment to setup the arena start address To call once when
// the system boots up or when creating a new pool arena.
//
// Arguments:
//  - addr: address of the arena's first byte
//  - size: size in byte available for the arena
// Returns:
//  - -1 if size is too small to contain at least 1 byte, otherwise 0
// -----------------------------------------------------------------------------------------------
int pool_init(void * addr, unsigned int size) {

	#ifdef POOL_ARENA_DEBUG
	printf("------------------------------------------------------------------------\n");
    printf("Pool Init\n");
	printf("------------------------------------------------------------------------\n");
	#endif

	// addr is not a valid memory address
	if (addr == NULL) {
		return -1;
	}

	// size is too small, can't even store a header
    if (size <= header_size) {
        return -1;
	}

    tmp_blk = 0;
    tmp_pt = 0;

	pool_addr = addr;
	pool_size = size;
    nb_alloc_blk = 0;
	alloc_space = 0;
    nb_free_blk = 1;
    free_space = size - reg_size;

    current = (blk_t *)addr;
    current->size = free_space;
    current->prv = NULL;
    current->nxt = NULL;

    #ifdef POOL_ARENA_DEBUG
    printf("Architecture/Library Setup:\n");
    printf("  - register size: %d bytes\n", reg_size);
    printf("  - header size: %d bytes\n", header_size);
    printf("  - pool size: %d bytes\n", size);
    printf("\n");

    printf("Init pool arena:\n");
    printf("  - addr: %p\n", addr);
    printf("  - size: %d\n", current->size);
    printf("  - prv: %p\n", (void *)current->prv);
    printf("  - nxt: %p\n", (void *)current->nxt);
    printf("\n");
    #endif

    #ifdef POOL_ARENA_DEBUG
	printf("------------------------------------------------------------------------\n");
    #endif

    return 0;
}


// -----------------------------------------------------------------------------------------------
// To round up a size to the next multiple of 32 or 64 bits size
//
// Argument:
//  - size: the number of bytes the block needs to own
// Returns:
//  - the number of bytes rounds up to the architcture width
// -----------------------------------------------------------------------------------------------
static inline int round_up(unsigned int * x) {

	if (reg_size == 4)
		return (0 == (*x & 0x3)) ? *x : ((*x + 4) & ~3u);
	else
		return (0 == (*x & 0x7)) ? *x : ((*x + 8) & ~7u);

    /* return ((*x + 7) >> log2_reg_size) << log2_reg_size; */
}


// -----------------------------------------------------------------------------------------------
// Allocates in the arena a buffer of _size_ bytes. Memory blocked reserved in memory are always
// boundary aligned with the hw architecture, so 4 bytes for 32 bits architecture, or 8 bytes
// for 64 bits architecture.
//
// Argument:
//  - size: the number of bytes the block needs to own
// Returns:
//  - the address of the buffer's first byte, otherwise -1 if failed
// -----------------------------------------------------------------------------------------------
void * pool_malloc(unsigned int size) {

	#ifdef POOL_ARENA_DEBUG
	printf("------------------------------------------------------------------------\n");
    printf("Pool Alloc\n");
	printf("------------------------------------------------------------------------\n");
	#endif

    void * loc;
    void * free_loc;
    void * prv_pt;
    void * nxt_pt;
    unsigned int _size;
    unsigned int new_size;

	if (size == 0) {
		#ifdef POOL_ARENA_DEBUG
        printf("ERROR: Can't allocate a zero-byte block\n");
		#endif
        return NULL;
	}

	// A block must be at least 3 registers wide to be able to release
	// it in free(). A free block must be composed by some size, prv
	// and nxt fields at minimum
	if (size<(2*reg_size))
		_size = 2*reg_size /* prv/nxt*/ + reg_size /* size register */;
    // Round up the size up to the arch width. Ensure the size is at minimum a register size and
    // a multiple of that register. So if use 64 bits arch, a 4 bytes allocation is round up
    // to 8 bytes, and 28 bytes is round up to 32 bytes, ...
	else
		_size = round_up(&size) + reg_size /* size register */;

	// Grab a place for our new shinny chunk
	loc = get_loc_to_place(current, _size);
	free_loc = loc;

	if (loc == NULL) {
		#ifdef POOL_ARENA_DEBUG
		printf("ERROR: Can't find a enough space to store a new block\n");
		printf("  - requested free space: %d\n", size);
		printf("  - current free space: %d\n", free_space);
		#endif
		return NULL;
	}

	#ifdef POOL_ARENA_DEBUG
	printf("  - allocated addr: %p\n", loc);
	printf("  - size requested: %d\n", _size);
	printf("  - current free block: %p\n", (void *)current);
	#endif

    // Update monitoring
	// ----------------
	nb_alloc_blk += 1;
	if (size<(2*reg_size))
		alloc_space += 2*reg_size;
	else
		alloc_space += round_up(&size);
	free_space -= _size;

	// Update free block
	// -----------------

	// Save metadata
	tmp_blk = (blk_t *)free_loc;
    nxt_pt = tmp_blk->nxt;
    prv_pt = tmp_blk->prv;
    // Adjust free space  block address and update its metadata
    new_size = tmp_blk->size - _size;
    free_loc = (char *)free_loc + _size;
    tmp_blk = (blk_t *)free_loc;
	tmp_blk->size = new_size;
    tmp_blk->prv = prv_pt;
    tmp_blk->nxt = nxt_pt;

	#ifdef POOL_ARENA_DEBUG
    printf("  - new free space address: %p\n", free_loc);
	printf("  - new free space size: %d\n", tmp_blk->size);
	#endif

    // Update previous block to link current
    if (prv_pt) {
        tmp_blk = prv_pt;
        tmp_blk->nxt = free_loc;
    }

    tmp_blk = (blk_t *)free_loc;
    // Update next block to link current, only if exists
    if (nxt_pt) {
        tmp_blk = nxt_pt;
        tmp_blk->prv = free_loc;
    }

	// Move the head pointer of the free space linked list
	current = free_loc;

	// Setup data block
	// ----------------

	// Set the new chunk's size
	tmp_blk = (blk_t *)loc;
	if (size<(2*reg_size))
		tmp_blk->size = reg_size*2;
	else
		tmp_blk->size = round_up(&size);
    // Payload's address the application can use
    loc = (char *)loc + reg_size;
    #ifdef POOL_ARENA_DEBUG
	printf("------------------------------------------------------------------------\n");
    #endif

    return loc;
}


// memory allocation + clear
void * pool_calloc(unsigned int size) {

	#ifdef POOL_ARENA_DEBUG
	printf("------------------------------------------------------------------------\n");
    printf("Pool Calloc\n");
	printf("------------------------------------------------------------------------\n");
	#endif
	void * ptr = pool_malloc(size);

	if (ptr == NULL) {
		#ifdef POOL_ARENA_DEBUG
		printf("ERROR: Failed to allocate the chunk\n");
		printf("  - current free space: %d\n", free_space);
		#endif
		return NULL;
	}

	memset(ptr, 0, size);

	return ptr;
}

// Move a block to a new place
void * pool_realloc(void * addr, unsigned int size) {

	#ifdef POOL_ARENA_DEBUG
	printf("------------------------------------------------------------------------\n");
    printf("Pool Realloc\n");
	printf("------------------------------------------------------------------------\n");
	#endif

	void * ptr = pool_malloc(size);

	if (ptr == NULL) {
		#ifdef POOL_ARENA_DEBUG
		printf("ERROR: Failed to allocate the chunk\n");
		printf("  - requested free space: %d\n", size);
		printf("  - current free space: %d\n", free_space);
		#endif
		return NULL;
	}

	memcpy(ptr, addr, size);
	pool_free(addr);

	return ptr;
}

// Search for a free space to place a new block
static inline void * get_loc_to_place(void * current, unsigned int size) {

	blk_t * parse = current;
	blk_t * org = current;

	// Current block is wide enough
	if (org->size >= size && parse->size-size > header_size)
		return current;

	// If not, parse the prv blocks to find a place
	parse = current;
	parse = parse->prv;
	while (parse != NULL) {
		if (parse->size >= size && parse->size-size > header_size)
			return (void *)parse;
		parse = parse->prv;
	}

	// If not, parse the nxt blocks to find a place
	parse = current;
	parse = parse->nxt;
	while (parse != NULL) {
		if (parse->size >= size && parse->size-size > header_size)
			return (void *)parse;
		parse = parse->nxt;
	}

	// No space found, give up and stop the allocation
	#ifdef POOL_ARENA_DEBUG
	printf("ERROR: Failed to allocate the chunk\n");
	#endif

	return NULL;
}


// -----------------------------------------------------------------------------------------------
// Parses the free blocks to find the place to set the one under release
// Useful to update the linked list correctly and fast its parsing.
//
// Follows the different cases to handle:
//
// ┌───────┬────────────────────────────────────────────┐
// │Block 0│          ~~~~~~~~ Free ~~~~~~~~~           │
// └───────┴────────────────────────────────────────────┘
// ┌────────────────────────────────────────────┬───────┐
// │          ~~~~~~~~ Free ~~~~~~~~~           │Block 0│
// └────────────────────────────────────────────┴───────┘
// ┌───────────────┬───────┬───────────────────────────┐
// │ ~~~ Free ~~~  │Block 0│  ~~~~~~~~ Free ~~~~~~~~   │
// └───────────────┴───────┴───────────────────────────┘
// ┌───────┬────────────────────────────────────┬───────┐
// │Block 0│      ~~~~~~~~ Free ~~~~~~~~~       │Block 1│
// └───────┴────────────────────────────────────┴───────┘
// ┌───────┬───────┬────────────────────┬───────┬────────┬───────┬───────┐
// │Block 0│Block 1│   ~~~ Free ~~~     │Block 2│~ Free ~│Block 3│Block 4│
// └───────┴───────┴────────────────────┴───────┴────────┴───────┴───────┘
// ┌────────┬───────┬───────┬────────────────────┬───────┬────────┐
// │~ Free ~│Block 0│Block 1│   ~~~ Free ~~~     │Block 2│~ Free ~│
// └────────┴───────┴───────┴────────────────────┴───────┴────────┘
//
// Argument:
//  - addr: pointer to an address to release
// Returns:
//  - a pointer to the location where to place the block to release. The place to use can be on the
//    left or on the right of address passed. If no place found, returns NULL
//
// -----------------------------------------------------------------------------------------------
static inline void * get_loc_to_free(void * addr) {

	// In case the free block is monolithic, just return its address
	if (current->prv == NULL && current->nxt == NULL) {
		#ifdef POOL_ARENA_DEBUG
		printf("  - no prv or nxt pointers\n");
		#endif
		return (void *)(current);
	}

    // The current block of free space manipulated by the library
    tmp_pt = (blk_t *)(current);
    tmp_blk = tmp_pt;

	// Location found to place the bloc under release
    void * loc = NULL;

    // The list is ordered by address, so we can divide the parsing to select
    // directly the right direction
    if (addr < tmp_pt) {
        while (1) {
			loc = (blk_t *)(tmp_blk);
			// No more free space on smaller address range, so when
			// can place this block on left of the current tmp / current free space
			if (tmp_blk->prv == NULL) {
				break;
			}
			// Next free block has a smaller address, so we are place
			// between two blocks: free.prv < data block < tmp / currrent free space
			else if (addr > (void *)tmp_blk->prv) {
				break;
			}
			tmp_blk = tmp_blk->prv;
        }
    } else {
        while (1) {
			loc = (blk_t *)(tmp_blk);
			// No more free space on higher address range, so when
			// can place this block on right of the current tmp / current free space
			if (tmp_blk->nxt == NULL) {
				break;
			}
			// Next free block has a higher address, so we are place
			// between two blocks: free.prv < data block < tmp / currrent free space
			else if (addr < (void *)tmp_blk->nxt) {
				break;
			}
			tmp_blk = tmp_blk->nxt;
        }
    }

    return loc;
}


// -----------------------------------------------------------------------------------------------
// Releases a block and make it available again for future use.
//
// Arguments:
//  - addr: the address of the data block
// Returns:
//  - 0 if block has been found (and so was a block), anything otherwise if failed
// -----------------------------------------------------------------------------------------------
int pool_free(void * addr) {

	#ifdef POOL_ARENA_DEBUG
	printf("------------------------------------------------------------------------\n");
    printf("Pool Free\n");
	printf("------------------------------------------------------------------------\n");
	#endif

	#ifdef POOL_ARENA_DEBUG
	printf("  - current free block: %p\n", (void *)current);
	printf("  - addr to free: %p\n", addr);
	#endif

    // Get block info
    void * blk_pt = (char *)addr - reg_size;
    blk_t * blk = blk_pt;
	blk->prv = NULL;
	blk->nxt  = NULL;

    // Update pool arena statistics
	#ifdef POOL_ARENA_DEBUG
	printf("  - size to free: %d\n", blk->size);
	#endif
	nb_alloc_blk -= 1;
	alloc_space -= blk->size;
	nb_free_blk += 1;
    free_space += blk->size;

	// Free space zone to connect or merge with the block to release. Multiple
	// free blocks are suitable to connect, this get_loc() ensuring we'll parse
	// fastly the linked list and also avoid fragmentation.
    void * free_pt = get_loc_to_free(blk_pt);
    blk_t * free_blk = (blk_t *)free_pt;

	#ifdef POOL_ARENA_DEBUG
	printf("  - blk_pt: %p\n", (void *)blk_pt);
	printf("  - free_pt: %p\n", (void *)free_pt);
	#endif

	// 1. Connect the block into the free space linked list
	if (blk_pt<free_pt) {
		blk->nxt = free_pt;
		if (free_blk->prv != NULL) {
			blk->prv = free_blk->prv;
			tmp_blk = (blk_t *)blk->prv;
			tmp_blk->nxt = blk_pt;
		}
		free_blk->prv = blk_pt;
	} else {

		blk->prv = free_pt;
		if (free_blk->nxt != NULL) {
			blk->nxt = free_blk->nxt;
			tmp_blk = (blk_t *)blk->nxt;
			tmp_blk->prv = blk_pt;
		}
		free_blk->nxt = blk_pt;
	}

	// Region is used to check if the block to release is adjacent to a free space
	void * region;

    // 2. Try to merge with next block if exists
    if (blk->nxt != NULL) {

		#ifdef POOL_ARENA_DEBUG
		printf("  - Update nxt\n");
		printf("  - %p\n", (void *)blk->nxt);
		#endif

        region = (char *)blk_pt + blk->size + reg_size;
        // if next block is contiguous the one to free, merge them
        if (region == blk->nxt) {
            // extend block size with nxt size
            tmp_blk = (blk_t *)blk->nxt;
            blk->size += tmp_blk->size + reg_size;
			blk->nxt = tmp_blk->nxt;
			// link nxt->nxt block with the new block
			if (blk->nxt != NULL) {
				tmp_blk = (blk_t *)tmp_blk->nxt;
				tmp_blk->prv = blk_pt;
			}
			// Update pool's statistics
			nb_free_blk -= 1;
			free_space += reg_size;
        }
    }

    // 3. Try to merge with previous block if exists
    if (blk->prv != NULL) {

		#ifdef POOL_ARENA_DEBUG
		printf("  - Update prv\n");
		printf("  - %p\n", (void *)blk->prv);
		#endif

        tmp_blk = (blk_t *)blk->prv;
        region = (char *)blk->prv + tmp_blk->size + reg_size;
        // if previous block is contiguous the one to free, merge them
        if (region==blk_pt) {
            // Update previous block by extending its size with blk (to free)
            tmp_blk->size += reg_size + blk->size;
            // Link blk-1 and blk+1 together
            tmp_blk->nxt = blk->nxt;
            // Current block's prv becomes the new current block
            blk = (blk_t *)blk->prv;
			// Change nxt block to point to our new suppa block
			if (blk->nxt != NULL) {
				tmp_blk = (blk_t *)blk->nxt;
				tmp_blk->prv = (void *)blk;
			}
			// Update pool's statistics
			nb_free_blk -= 1;
			free_space += reg_size;
        }
    }

	// move the head pointer the free space linked list
	current = blk;

	#ifdef POOL_ARENA_DEBUG
	printf("------------------------------------------------------------------------\n");
	#endif

    return 0;
}

int pool_check(void) {

	unsigned int alloc = nb_alloc_blk * reg_size + alloc_space;
	unsigned int free = nb_free_blk * reg_size + free_space;
	blk_t * tmp = current;
	int cnt = 0;

	// first rewind the linked list to get the first free space block
	while (tmp->prv != NULL)
		tmp = (blk_t *)tmp->prv;

	while (tmp != NULL) {
		tmp = (blk_t *)tmp->nxt;
		cnt += 1;
	}

	#ifdef POOL_ARENA_DEBUG
	printf("\n");
	printf("------------------------------------------------------------------------\n");
	printf("Pool Check\n");
	printf("------------------------------------------------------------------------\n");
	printf("Arena space: %d\n", pool_size);
	printf("\n");
	printf("Allocated Space\n");
	printf("  - nb alloc space: %d\n", nb_alloc_blk);
	printf("  - alloc space: %d\n", alloc_space);
	printf("  - total alloc space: %d\n", alloc);
	printf("\n");
	printf("Free Space\n");
	printf("  - nb free space: %d\n", nb_free_blk);
	printf("  - counted nb free space: %d\n", cnt);
	printf("  - free space: %d\n", free_space);
	printf("  - total free space: %d\n", free);
	printf("\n");
	printf("Arena vs Computed: %d\n", pool_size - alloc - free);
	printf("------------------------------------------------------------------------\n");
	#endif

	if (pool_size != (alloc + free)) {
		printf("ERROR: Free space size doesn't match\n");
		printf("------------------------------------------------------------------------\n");
		return 1;
	}

	if (cnt != nb_free_blk) {
		printf("ERROR: Free space block count doesn't match\n");
		printf("------------------------------------------------------------------------\n");
		return 1;
	}

	return 0;
}


void pool_log(void) {

	void * end;
	blk_t * tmp = current;

	// first rewind the linked list to get the first free space block
	while (tmp->prv != NULL)
		tmp = (blk_t *)tmp->prv;

	printf("\n");
	printf("------------------------------------------------------------------------\n");
	printf("Pool Arena\n");
	printf("------------------------------------------------------------------------\n");
	end = (char *)pool_addr + pool_size - 1;
	printf("Addr: %p\t", pool_addr);
	printf("End: %p\t", end);
	printf("Size: %d\t", pool_size);
	printf("\n");
	printf("------------------------------------------------------------------------\n");

	printf("Free Space Blocks\n");
	printf("------------------------------------------------------------------------\n");
	// move forward to print one by one the blocks
	while (tmp != NULL) {
		end = (char *)tmp + tmp->size + reg_size - 1;
		printf("Addr: %p\t", (void*)tmp);
		printf("End: %p\t", end);
		printf("Size: %d\t", tmp->size);
		printf("Prv: %p\t", (void*)tmp->prv);
		printf("Nxt: %p\t", (void*)tmp->nxt);
		printf("\n");
		tmp = (blk_t *)tmp->nxt;
	}
	printf("------------------------------------------------------------------------\n");
	printf("\n");
}

// Return the size of chunk located @ address
unsigned int pool_get_size(void * addr) {
    void * blk_pt = (char *)addr - reg_size;
    blk_t * blk = blk_pt;
	return blk->size;
}
