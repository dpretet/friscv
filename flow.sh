#!/usr/bin/env bash

# -e: exit if one command fails
# -u: treat unset variable as an error
# -f: disable filename expansion upon seeing *, ?, ...
# -o pipefail: causes a pipeline to fail if any command fails
set -e -o pipefail

# Current script path; doesn't support symlink
FRISCV_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ret=0

# Bash color codes
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
# Reset
NC='\033[0m'

function printerror {
    echo -e "${Red}ERROR: ${1}${NC}"
}

function printwarning {
    echo -e "${Yellow}WARNING: ${1}${NC}"
}

function printinfo {
    echo -e "${Blue}INFO: ${1}${NC}"
}

function printsuccess {
    echo -e "${Green}SUCCESS: ${1}${NC}"
}

help() {
    echo -e "${Blue}"
    echo ""
    echo "NAME"
    echo ""
    echo "      FRISCV Flow"
    echo ""
    echo "SYNOPSIS"
    echo ""
    echo "      ./flow.sh -h"
    echo ""
    echo "      ./flow.sh help"
    echo ""
    echo "      ./flow.sh syn"
    echo ""
    echo "      ./flow.sh sim"
    echo ""
    echo "DESCRIPTION"
    echo ""
    echo "      This flow handles the different operations available"
    echo ""
    echo "      ./flow.sh help|-h"
    echo ""
    echo "      Print the help menu"
    echo ""
    echo "      ./flow.sh syn"
    echo ""
    echo "      Launch the synthesis script relying on Yosys"
    echo ""
    echo "      ./flow.sh sim"
    echo ""
    echo "      Launch all available testsuites"
    echo ""
    echo -e "${NC}"
}

main() {

    echo ""
    printinfo "Start FRISCV Flow"

    # If no argument provided, preint help and exit
    if [[ $# -eq 0 ]]; then
        help
        exit 1
    fi

    # Print help
    if [[ $1 == "-h" || $1 == "help" ]]; then

        help
        exit 0
    fi


    if [[ $1 == "lint" ]]; then

        set +e

        printinfo "Start Verilator linting"
        verilator --lint-only +1800-2017ext+sv \
            -Wall -Wpedantic \
            -Wno-VARHIDDEN \
            -Wno-PINCONNECTEMPTY \
            -I./rtl\
            -I./dep/svlogger\
            ./rtl/friscv_h.sv\
            ./rtl/friscv_rv32i_core.sv\
            ./rtl/friscv_control.sv\
            ./rtl/friscv_decoder.sv\
            ./rtl/friscv_pipeline.sv\
            ./rtl/friscv_alu.sv\
            ./rtl/friscv_processing.sv\
            ./rtl/friscv_memfy.sv\
            ./rtl/friscv_registers.sv\
            ./rtl/friscv_m_ext.sv\
            ./rtl/friscv_csr.sv\
            ./rtl/friscv_scfifo.sv\
            ./rtl/friscv_ram.sv\
            ./rtl/friscv_rambe.sv\
            ./rtl/friscv_dcache.sv\
            ./rtl/friscv_icache.sv\
            ./rtl/friscv_cache_fetcher.sv\
            ./rtl/friscv_cache_pusher.sv\
            ./rtl/friscv_cache_blocks.sv\
            ./rtl/friscv_cache_memctrl.sv\
            ./rtl/friscv_axi_or_tracker.sv\
            --top-module friscv_rv32i_core

        set -e
    fi

    if [[ $1 == "sim" ]]; then

        source script/setup.sh

        if [[ ! $(type iverilog) ]]; then
            printerror "Icarus-Verilog is not installed"
            exit 1
        fi
        if [[ ! $(type verilator) ]]; then
            printerror "Verilator is not installed"
            exit 1
        fi

        if [[ -z "$2" ]]; then
            printerror "Plese specify a testsuite to run:"
            echo "  - wba-testsuite"
            echo "  - riscv-testsuite"
            echo "  - c-testsuite"
        fi

        if [ "$2" == "wba-testsuite" ]; then
            echo ""
            printinfo "Start WBA Simulation flow"
            cd "${FRISCV_DIR}/test/wba_testsuite"

            ./run.sh --simulator verilator --tb CORE --nocompile 1
            ./run.sh --simulator verilator --tb PLATFORM --nocompile 1
            ./run.sh --simulator icarus --tb CORE --nocompile 1
            ./run.sh --simulator icarus --tb PLATFORM --nocompile 1
        fi

        if [ "$2" == "riscv-testsuite" ]; then
            echo ""
            printinfo "Start RISCV Compliance flow"
            cd "${FRISCV_DIR}/test/riscv-tests"

            ./run.sh --simulator verilator --tb CORE --nocompile 1
            ./run.sh --simulator verilator --tb PLATFORM --nocompile 1
            ./run.sh --simulator icarus --tb CORE --nocompile 1
            ./run.sh --simulator icarus --tb PLATFORM --nocompile 1
        fi

        if [ "$2" == "c-testsuite" ]; then
            echo ""
            printinfo "Start C Simulation flow"
            cd "${FRISCV_DIR}/test/c_testsuite"

            ./run.sh --simulator verilator --tb CORE --nocompile 1
            ./run.sh --simulator verilator --tb PLATFORM --nocompile 1
            ./run.sh --simulator icarus --tb CORE --nocompile 1
            ./run.sh --simulator icarus --tb PLATFORM --nocompile 1
        fi

        exit 0
    fi

    if [[ $1 == "syn" ]]; then
        printinfo "Start synthesis flow"
        cd "$FRISCV_DIR/syn"
        ./syn_asic.sh
        return $?
    fi
}

main "$@"
