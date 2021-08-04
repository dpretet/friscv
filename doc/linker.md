# The GNU Linker

From [GNU linker documentation](https://www.eecs.umich.edu/courses/eecs373/readings/Linker.pdf)

## Overview

ld combines a number of object and archive files, relocates their data and ties
up symbol references. Usually the last step in compiling a program is to run
ld.  ld accepts Linker Command Language files written in a superset of AT&T’s
Link Editor Command Language syntax.

## Invocation

To link a file hello.c:

```bash
ld -o output /lib/crt0.o hello.o -lc
```

This tells ld to produce a file called output as the result of linking the file
/lib/crt0.o with hello.o and the library libc.a.

crt0 stands for "C runtime". It is a set of execution startup routines linked
into a C program that performs any initialization work required before calling
the program's main function.

## Linker Scrips

Every link is controlled by a linker script. This script is written in the
linker command language.

The main purpose of the linker script is to describe how the sections in the
input files should be mapped into the output file, and to control the memory
layout of the output file. Most linker scripts do nothing more than this.

The linker always uses a linker script. If you do not supply one yourself, the
linker will use a default script that is compiled into the linker executable.
You can use the ‘--verbose’ command line option to display the default linker
script.

You may supply your own linker script by using the ‘-T’ command line option.
When you do this, your linker script will replace the default linker script.

## Basic Linker Script Concepts

The linker combines input files into a single output file. The output file and
each input file are in a special data format known as an object file format.
Each file is called an object file. The output file is often called an
executable. Each object file has, among other things, a list of sections.

Each section in an object file has a name and a size. Most sections also have
an associated block of data, known as the section contents. A section may be
marked as loadable, which mean that the contents should be loaded into memory
when the output file is run. A section with no contents may be allocatable,
which means that an area in memory should be set aside, but nothing in
particular should be loaded there (in some cases this memory must be zeroed
out). A section which is neither loadable nor allocatable typically contains
some sort of debugging information.

Every loadable or allocatable output section has two addresses. The first is
the VMA, or virtual memory address. This is the address the section will have
when the output file is run. The second is the LMA, or load memory address.
This is the address at which the section will be loaded. In most cases the two
addresses will be the same.


You can see the sections in an object file by using the objdump program with
the ‘-h’ option.

Every object file also has a list of symbols, known as the symbol table. A
symbol may be defined or undefined. Each symbol has a name, and each defined
symbol has an address, among other information.

You can see the symbols in an object file by using the nm program, or by using
the objdump program with the ‘-t’ option.


##  Linker Script Format

Linker scripts are text files.

You write a linker script as a series of commands. Each command is either a
keyword, possibly followed by arguments, or an assignment to a symbol. You may
separate commands using semicolons. Whitespace is generally ignored.

Strings such as file or format names can normally be entered directly. If the
file name contains a character such as a comma which would otherwise serve to
separate file names, you may put the file name in double quotes. There is no
way to use a double quote character in a file name.  You may include comments
in linker scripts just as in C, delimited by ‘/*’ and ‘*/’. As in C, comments
are syntactically equivalent to whitespace.

## Simple Linker Script Example

Many linker scripts are fairly simple.

The simplest possible linker script has just one command: ‘SECTIONS’. You use
the ‘SECTIONS’ command to describe the memory layout of the output file. The
‘SECTIONS’ command is a powerful command. Here we will describe a simple use of
it. Let’s assume your program consists only of code, initialized data, and
uninitialized data. These will be in the ‘.text’, ‘.data’, and ‘.bss’ sections,
respectively.

For this example, let’s say that the code should be loaded at address 0x10000,
and that the data should start at address 0x8000000. Here is a linker script
which will do that:

```ld
SECTIONS
{
        . = 0x10000;
        .text : { *(.text) }    /* code section */
        . = 0x8000000;
        .data : { *(.data) }    /* initialized data section */
        .bss : { *(.bss) }      /* uninitialized data section */
}
```

You write the ‘SECTIONS’ command as the keyword ‘SECTIONS’, followed by a
series of symbol assignments and output section descriptions enclosed in curly
braces.  The first line inside the ‘SECTIONS’ command of the above example sets
the value of the special symbol ‘.’, which is the location counter. If you do
not specify the address of an output section in some other way (other ways are
described later), the address is set from the current value of the location
counter. The location counter is then incremented by the size of the output
section. At the start of the ‘SECTIONS’ command, the location counter has the
value ‘0’.

The second line defines an output section, ‘.text’. The colon is required
syntax which may be ignored for now. Within the curly braces after the output
section name, you list the names of the input sections which should be placed
into this output section. The ‘*’ is a wildcard which matches any file name.
The expression ‘*(.text)’ means all ‘.text’ input sections in all input files.
Since the location counter is ‘0x10000’ when the output section ‘.text’ is
defined, the linker will set the address of the ‘.text’ section in the output
file to be ‘0x10000’.

The remaining lines define the ‘.data’ and ‘.bss’ sections in the output file.
The linker will place the ‘.data’ output section at address ‘0x8000000’. After
the linker places the ‘.data’ output section, the value of the location counter
will be ‘0x8000000’ plus the size of the ‘.data’ output section. The effect is
that the linker will place the ‘.bss’ output section immediately after the
‘.data’ output section in memory.

The linker will ensure that each output section has the required alignment, by
increasing the location counter if necessary.


##  Simple Linker Script Commands

### Setting the Entry Point

The first instruction to execute in a program is called the entry point. You
can use the ENTRY linker script command to set the entry point. The argument is
a symbol name:

```ld
ENTRY(symbol )
```

There are several ways to set the entry point. The linker will set the entry point by trying
each of the following methods in order, and stopping when one of them succeeds:
- the ‘-e’ entry command-line option;
- the ENTRY(symbol) command in a linker script;
- the value of the symbol start, if defined;
- the address of the first byte of the ‘.text’ section, if present;
- The address 0.

### Commands Dealing with Files


INCLUDE filename

Include the linker script filename at this point.

INPUT(file, file, ...)
INPUT(file file ...)

The INPUT command directs the linker to include the named files in the link, as
though they were named on the command line.


GROUP(file, file, ...)
GROUP(file file ...)

The GROUP command is like INPUT, except that the named files should all be
archives, and they are searched repeatedly until no new undefined references
are created

AS_NEEDED(file, file, ...)
AS_NEEDED(file file ...)

This construct can appear only inside of the INPUT or GROUP commands, among
other filenames. The files listed will be handled as if they appear directly in
the INPUT or GROUP commands, with the exception of ELF shared libraries, that
will be added only when they are actually needed.

OUTPUT(filename )

The OUTPUT command names the output file. Using OUTPUT(filename) in the linker
script is exactly like using ‘-o filename’ on the command line

SEARCH_DIR(path )

The SEARCH_DIR command adds path to the list of paths where ld looks for
archive libraries. Using SEARCH_DIR(path) is exactly like using ‘-L path’ on
the command line

STARTUP(filename )

The STARTUP command is just like the INPUT command, except that filename will
become the first input file to be linked, as though it were specified first on
the command line. This may be useful when using a system in which the entry
point is always the start of the first file.

### Assign alias names to memory regions

REGION_ALIAS(alias, region)

This function creates an alias name alias for the memory region region. This
allows a flexible mapping of output sections to memory regions.

## Assigning Values to Symbols

### Simple Assignments

You may assign to a symbol using any of the C assignment operators:

```ld
symbol = expression ;
symbol += expression ;
symbol -= expression ;
symbol *= expression ;
symbol /= expression ;
symbol <<= expression ;
symbol >>= expression ;
symbol &= expression ;
symbol |= expression ;
```

The first case will define symbol to the value of expression. In the other
cases, symbol must already be defined, and the value will be adjusted
accordingly.

The special symbol name ‘.’ indicates the location counter.

The semicolon after expression is required.


## SECTIONS Command

The SECTIONS command tells the linker how to map input sections into output
sections, and how to place the output sections in memory.
The format of the SECTIONS command is:

```ld
SECTIONS {
    sections-command
    sections-command
    ...
}
```

Each sections-command may of be one of the following:
- an ENTRY command
- a symbol assignment
- an output section description
- an overlay description

### Output Section Description

The full description of an output section looks like this:

```ld
section [address] [(type)] :
    [AT(lma)]
    [ALIGN(section_align)]
    [SUBALIGN(subsection_align)]
    [constraint]
    {
        output-section-command
        output-section-command
        ...

    } [>region] [AT>lma_region] [:phdr :phdr ...] [=fillexp]
```

Most output sections do not use most of the optional section attributes. The
whitespace around section is required, so that the section name is unambiguous.
The colon and the curly braces are also required. The line breaks and other
white space are optional.

Each output-section-command may be one of the following:
- a symbol assignment
- an input section description
- data values to include directly
- a special output section keyword

###  Output Section Address

The address is an expression for the VMA (the virtual memory address) of the
output section. If you do not provide address, the linker will set it based on
region if present, or otherwise based on the current value of the location
counter.  If you provide address, the address of the output section will be set
to precisely that. If you provide neither address nor region, then the address
of the output section will be set to the current value of the location counter
aligned to the alignment requirements of the output section. The alignment
requirement of the output section is the strictest alignment of any input
section contained within the output section.


For example:

```ld
      .text . : { *(.text) }
```

and

```ld
    .text : { *(.text) }
```

are subtly different. The first will set the address of the ‘.text’ output
section to the current value of the location counter. The second will set it to
the current value of the location counter aligned to the strictest alignment of
a ‘.text’ input section.

The address may be an arbitrary expression; For example, if you want to align
the section on a 0x10 byte boundary, so that the lowest four bits of the
section address are zero, you could do something like this:

```ld
      .text ALIGN(0x10) : { *(.text) }
```

This works because ALIGN returns the current location counter aligned upward to
the spec- ified value.  Specifying address for a section will change the value
of the location counter, provided that the section is non-empty.
