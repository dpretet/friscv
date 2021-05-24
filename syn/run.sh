#!/usr/bin/env bash

# -e: exit if one command fails
# -o pipefail: causes a pipeline to fail if any command fails
set -e -o pipefail

design="./friscv_rv32i.ys"

if [[ ! -f "./vsclib013.lib" ]]; then
    echo "INFO: Download library for synthesis"
    wget http://www.vlsitechnology.org/synopsys/vsclib013.lib
fi

# Check if a design is specified
if [[ -n $1 ]]; then
    echo "INFO: will start $1 synthesis"
    design="$1"
fi

echo "INFO: Start synthesis flow"
yosys -V
cmd="yosys $design"

if eval "$cmd"; then
    echo "ERROR: Synthesis failed"
    exit 1
fi

exit 0
