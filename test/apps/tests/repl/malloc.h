// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

#ifndef ___MALLOC
#define ___MALLOC

#include "pool_arena.h"

#define malloc pool_malloc
#define calloc pool_calloc
#define realloc pool_realloc
#define free pool_free

#endif // ___MALLOC

