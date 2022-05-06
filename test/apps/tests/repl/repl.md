# REPL (Read/Eval/Process/Loop)

Application skeleton to putting in place a full-duplex communication between the core and a console

## BEHAVIOR

The console:

A Verilator simulation faking a real terminal like bash. The console reads from stdin/cin a flow of
character.

A flow of char is considered as a complete command if it contains a carriage return (<CR>).
Once a line is received, the front-end will send character by character through the UART
the line.

A line can be sent only if both TX and RX FIFOs are empty.

A line can't be wider than a certain number of characters, defined with same value on both console
and core. A longest line will lead to an error and will not be transmitted to the core.

If the stdin/cin buffer would contain multiple sequences of comands, meaning multiple <CR>, it will
send them once by one, with respect of the above rules.

The console never initiates a command before having received a prompt and a user command.


The core:

The IP core awakes after a reset sequence, print out a welcome message and forward a prompt. Once
the prompt is received, the core can be considered as ready to process a sequence of characters.

The core considers a sequence as complete and ready to be processed once a carriage return is
received (<CR>).

The core can't received a line bigger than than a certain number of characters, defined with same
value on both console and core. If a line is received without a <CR> before or at the maximum
allowed, the core will drop it and print out to the application an error message.

If the core receives a line with a <CR> before the end of the line, it will stop to process the
line and will print out an error.


## FUTURE

- put in place an upper protocol to indicate the complete sequence of operations has been sent.
