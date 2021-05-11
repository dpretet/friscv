# Test 1: Sequence LUI / AUIPC / Arithmetic instructions

Injects a set of alternating LUI / AUIPC / Aritmetic instructions
to ensure the control unit correctly handles this kind of situation.

All these instructions are handled in one cycle and shouldn't introduce any
wait cycles between each others.
