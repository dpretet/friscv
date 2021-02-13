#!/usr/bin/env bash

# -e: exit if one command fails
# -u: treat unset variable as an error
# -f: disable filename expansion upon seeing *, ?, ...
# -o pipefail: causes a pipeline to fail if any command fails
set -e -o pipefail

find . -maxdepth 1 -mindepth 1 -type d -exec make -C {} clean all \; \
                                       -exec ./bin2hex.py {}/{}.v {}.v \;
svutRun -t ./friscv_rv32i_testbench.sv
