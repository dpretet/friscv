# Test 2: Sequence of LOAD/STORE/ARITHMETIC instructions

Injects a set of alternating LUI / AUIPC / Aritmetic instructions
to ensure the control unit correctly handles this kind of situation.

While aritmetic instructions are completed in one cycle, LOAD and STORE
can span over several cycles. This test will ensure incoming instructions
between them will not be lost and so the control unit properly manages
this situation.
