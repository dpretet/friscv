#!/usr/bin/env python3
# coding: utf-8

# distributed under the mit license
# https://opensource.org/licenses/mit-license.php

import sys
import argparse


def get_symbols(symfile):
    """
    Grab from the exported symbols the one for function

    Args:
        - file exported from nm utility
    Returns:
        - a dict = {key = symbol address : value = symbole name,
                          ...
                   }
    """

    symbols = {}

    for line in symfile:
        if " T " in line:
            line = line.strip()
            elems = line.split(" ")
            symbols[elems[0]] = elems[2]

    return symbols


def build_trace(trace, symbols):
    """
    Return a list of string ready to dump, the original trace with symbol associated to the
    address of the line
    """

    otrace = []

    for line in trace:
        if not ',' in line:
            continue
        addr = line.strip().split(',')[1]
        line = line.strip() + ','
        if addr in symbols:
            line += symbols[addr]
        otrace.append(line)

    return otrace


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Produce a CPU trace from a dump of the core\'s control stage and the exported symbols with nm utility')
    parser.add_argument("--itrace", help="Input csv trace, each line containing the time then the address to jump")
    parser.add_argument("--symbols", help="Symbol list exported with nm (nm my_elf > my_symbols)")
    parser.add_argument("--otrace", help="csv trace, same than itrace with a third argument being the symbol associated to the address")
    parser.add_argument("--verbose", help="Print intermediate processing state")

    args = parser.parse_args()

    symbols = {}

    with open(args.symbols, "r", encoding="UTF-8") as f:
        symfile = f.readlines()

    symbols = get_symbols(symfile)

    if args.verbose:
        print(symbols)

    with open(args.itrace, "r", encoding="UTF-8") as f:
        trace = f.readlines()

    otrace = build_trace(trace, symbols)

    with open(args.otrace, "w", encoding="UTF-8") as f:
        for line in otrace:
            f.write(line)
            f.write("\n")

    sys.exit(0)
