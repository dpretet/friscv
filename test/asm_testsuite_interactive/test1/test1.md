# Test 6: Interactive testing of the UART

This testcase test the UART in an interactive way. The testbench embedds
an UART VPI, connected to the core's UART port to communicate. The VPI
opens a TCP socket accessible from telnet or socat for instance, allowing
to send and receive data to the processor. The ASM program will do multiple
attempts to read and write to the UART by starting first with read request,
blocking the APB until the module answers can read a value from the VPI.
Read request are followed by write requets to send back data to the
application.
