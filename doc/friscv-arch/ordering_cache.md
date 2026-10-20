## Future Enhancement: Ordering

Rework AXI support for ID management and cache

MPU:
- support cachability of a region
- support sharability of a region
- IO & memory of a region (replace old implementation)

Memfy
- Manage multiple requests with a LUT (see memfy_opt branch)
- Should be able to manage completion reodering (possible enhancement)

dCache
- the cache should be able to manage different IDs and don't substitute all the time them. Better
  performance. Reordering should be done only on different IDs.
- Use WRAP mode for read request, INCR for write request

Better ID management Cortex-M7 ID Usage example:

Read IDs:
- ID O: Normal Non-Cacheable, Device and Strongly-ordered reads
- ID 2: Data cache linefills from linefill buffer 0
- ID 3: Data cache linefills from linefill buffer 1
- ID 4: Any instruction fetch

Write IDs:
- ID O: Normal non-cacheable memory and all store-exclusive transactions
- ID 1: Stores to Normal cacheable memory
- ID 2: Writes to Device or Strongly-ordered memory
- ID 3: Evictions to Normal cacheable Write-Back memory
