// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef FRISCV_CONTROL_H
`define FRISCV_CONTROL_H

//////////////////////////////////////////////////////////////////
// Logger setup
//////////////////////////////////////////////////////////////////

`ifdef USE_SVL

`include "svlogger.sv"

`ifndef LOGGER
`define LOGGER

    `ifndef CONTROL_VERBOSITY
        `define CONTROL_VERBOSITY `SVL_VERBOSE_DEBUG
        `define CONTROL_ROUTE `SVL_ROUTE_ALL
    `endif

`endif


//////////////////////////////////////////////////////////////////
// Tasks
//////////////////////////////////////////////////////////////////

function automatic string get_inst_desc(
    input string            instruction,
    input string            pc,
    input logic [7    -1:0] opcode,
    input logic [3    -1:0] funct3,
    input logic [7    -1:0] funct7,
    input logic [5    -1:0] rs1,
    input logic [5    -1:0] rs2,
    input logic [5    -1:0] rd,
    input logic [12   -1:0] imm12,
    input logic [20   -1:0] imm20,
    input logic [12   -1:0] csr
);

    string text = "UNKNOWN";
    string temp;

    if (opcode==`LUI) begin
        text = "LUI / U-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Imm20: %x", imm20);
        text = {temp, " / ", text};
    end
    if (opcode==`AUIPC) begin
        text = "AUIPC / U-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Imm20: %x", imm20);
        text = {temp, " / ", text};
    end
    if (opcode==`JALR) begin
        text = "JALR / I-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`LOAD) begin
        text = "LOAD / I-type";
        $sformat(temp, "rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`I_ARITH) begin
        text = "ARITH / I-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`FENCEX) begin
        if (funct3==`FENCE) text = "FENCE / I-type";
        else text = "FENCE.i / I-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`SYS) begin
        if (csr==12'h0 && funct3==3'b0) text = "ECALL - I-type";
        else if (csr==12'h1 && funct3==3'b0) text = "EBREAK - I-type";
        else if (funct3==3'b000 && csr==12'h105) text = "WFI - I-type";
        else if (funct3==3'b000 && csr==12'h102) text = "SRET - I-type";
        else if (funct3==3'b000 && csr==12'h302) text = "MRET - I-type";
        else text = "CSR / I-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        if (funct3==3'b0 && (csr==12'h0 || csr==12'h1)) begin
            $sformat(temp, "Imm12: %x", csr);
        end else begin
            $sformat(temp, "Csr: %x", csr);
        end
        text = {temp, " / ", text};
    end
    if (opcode==`JAL) begin
        text = "JAL / J-type";
        $sformat(temp, "rd: %x ", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Imm20: %x", imm20);
        text = {temp, " / ", text};
    end
    if (opcode==`BRANCH) begin
        text = "BRANCH / B-type";
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Rs2: %x", rs2);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`STORE) begin
        text = "STORE / S-type";
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Rs2: %x", rs2);
        text = {temp, " / ", text};
        $sformat(temp, "Imm12: %x", imm12);
        text = {temp, " / ", text};
    end
    if (opcode==`R_ARITH) begin
        if (funct7==7'b0000001) text = "MULDIV / R-type";
        else text = "ARITH / R-type";
        $sformat(temp, "Rd: %x", rd);
        text = {temp, " / ", text};
        $sformat(temp, "Funct3: %x", funct3);
        text = {temp, " / ", text};
        $sformat(temp, "Rs1: %x", rs1);
        text = {temp, " / ", text};
        $sformat(temp, "Rs2: %x", rs2);
        text = {temp, " / ", text};
        $sformat(temp, "Funct7: %x", funct7);
        text = {temp, " / ", text};
    end

    get_inst_desc = {"PC=", pc, " - ", instruction, " / ", text};

endfunction

`endif
`endif
