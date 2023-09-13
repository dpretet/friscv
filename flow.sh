#!/usr/bin/env bash

# -e: exit if one command fails
# -u: treat unset variable as an error
# -f: disable filename expansion upon seeing *, ?, ...
# -o pipefail: causes a pipeline to fail if any command fails
set -e -o pipefail

# Current script path; doesn't support symlink
FRISCV_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# Bash color codes
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
Blue='\033[0;34m'
# Reset
NC='\033[0m'

TB="all"
SIMULATOR="all"

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
    echo "      List all available testsuites and options"
    echo ""
    echo "      ./flow.sh sim wba-testsuite core icarus"
    echo ""
    echo "      Run a specific testsuite using a particular testbench and simulator"
    echo ""
    echo -e "${NC}"
}


run_sims() {
    # Run all simulation specified for CI run
    # rm -f rtl.md5 force to rebuild the testbench and the sources

    if [[ $1 == "core" ]] || [[ $1 == "all" ]]; then
        if [[ $2 == "icarus" ]] || [[ $2 == "all" ]]; then
            rm -f rtl.md5 && ./run.sh --simulator icarus --tb core --nocompile 1 --timeout 100000
        fi
        if [[ $2 == "verilator" ]] || [[ $2 == "all" ]]; then
            rm -f rtl.md5 && ./run.sh --simulator verilator --tb core --nocompile 1 --timeout 100000
        fi
    fi
    if [[ $1 == "platform" ]] || [[ $1 == "all" ]]; then
        if [[ $2 == "icarus" ]] || [[ $2 == "all" ]]; then
            rm -f rtl.md5 && ./run.sh --simulator icarus --tb platform --nocompile 1 --timeout 100000
        fi
        if [[ $2 == "verilator" ]] || [[ $2 == "all" ]]; then
            rm -f rtl.md5 && ./run.sh --simulator verilator --tb platform --nocompile 1 --timeout 100000
        fi
    fi
}


print_testsuites() {

    printerror "Plese specify a testsuite to run:"
    echo "  - wba-testsuite"
    echo "  - riscv-testsuite"
    echo "  - c-testsuite"
    echo "  - sv-testsuite"
    echo "  - all"
    echo ""

    printerror "Other options:"
    echo "  - core or platform (default both)"
    echo "  - icarus or verilator (default both)"

    exit 1
}


check_setup() {

    source script/setup.sh

    if [[ ! $(type iverilog) ]]; then
        printerror "Icarus-Verilog is not installed"
        exit 1
    fi
    if [[ ! $(type verilator) ]]; then
        printerror "Verilator is not installed"
        exit 1
    fi
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
            -Wno-PINMISSING \
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
            ./rtl/friscv_cache_block_fetcher.sv\
            ./rtl/friscv_cache_io_fetcher.sv\
            ./rtl/friscv_cache_ooo_mgt.sv\
            ./rtl/friscv_cache_pusher.sv\
            ./rtl/friscv_cache_blocks.sv\
            ./rtl/friscv_cache_memctrl.sv\
            ./rtl/friscv_axi_or_tracker.sv\
            --top-module friscv_rv32i_core 2> lint.log

        set -e

        ec=$(grep -c "%Error:" lint.log)

        if [[ $ec -gt 1 ]]; then
            printerror "Lint failed, check ./lint.log for further details"
            exit 1
        else
            printsuccess "Lint ran successfully"
            exit 0
        fi

    fi

    if [[ $1 == "sim" ]]; then

        check_setup

        [[ -z "$2" ]] && print_testsuites
        [[ -n $3 ]] && TB="$3"
        [[ -n $4 ]] && SIMULATOR="$4"

        if [ "$2" == "wba-testsuite" ] || [ "$2" == "all" ]; then
            echo ""
            printinfo "Start WBA Simulation flow"
            cd "${FRISCV_DIR}/test/wba_testsuite"
            run_sims "$TB" "$SIMULATOR"
        fi

        if [ "$2" == "riscv-testsuite" ] || [ "$2" == "all" ]; then
            echo ""
            printinfo "Start RISCV Compliance flow"
            cd "${FRISCV_DIR}/test/riscv-tests"
            run_sims "$TB" "$SIMULATOR"
        fi

        if [ "$2" == "c-testsuite" ] || [ "$2" == "all" ]; then
            echo ""
            printinfo "Start C Simulation flow"
            cd "${FRISCV_DIR}/test/c_testsuite"
            run_sims "$TB" "$SIMULATOR"
        fi

        if [ "$2" == "priv_sec-testsuite" ] || [ "$2" == "all" ]; then
            echo ""
            printinfo "Start Privilege/Security Simulation flow"
            cd "${FRISCV_DIR}/test/priv_sec_testsuite"
            run_sims "$TB" "$SIMULATOR"
        fi

        if [ "$2" == "sv-testsuite" ] || [ "$2" == "all" ]; then
            echo ""
            printinfo "Start SV Simulation flow"
            cd "${FRISCV_DIR}/test/sv"
            ./run.sh -c
            ./run.sh -m 10000 --timeout 100000 --tb "icache_testbench.sv"
            ./run.sh -c
            ./run.sh -m 10000 --timeout 100000 --tb "dcache_testbench.sv"
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
