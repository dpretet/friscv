# Test 5: CSRs: Throttle execution by acessing the ISA CSRs

This testcase executes memory and arithmetic instructions break up
by CSR accesses. CSR instructions require several cycles to complete,
thus could lead to failure in control unit.
