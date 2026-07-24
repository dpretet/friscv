// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef FRISCV_CONTROL_H
`define FRISCV_CONTROL_H

    /////////////////////////////////////////////////////////////////
    // Used to print instruction during execution, relies on SVLogger
    /////////////////////////////////////////////////////////////////

    task print_instruction;
        string inst_str;
        string pc_str;
        $sformat(inst_str, "%x", instruction);
        $sformat(pc_str, "%x", pc_reg);
        log.debug(get_inst_desc(
                    inst_str,
                    pc_str,
                    opcode,
                    funct3,
                    funct7,
                    rs1,
                    rs2,
                    rd,
                    imm12,
                    imm20,
                    csr));
    endtask


    /////////////////////////////////////////////////////////////////////
    // Get a description of a synchronous exception when handling a trap
    /////////////////////////////////////////////////////////////////////
    function automatic string get_mcause_desc(input integer cause);
        // Synchronous Trap
             if (cause=='h1)  get_mcause_desc = "Read-only CSR write access";
        else if (cause=='h0)  get_mcause_desc = "Instruction address misaligned";
        else if (cause=='h4)  get_mcause_desc = "LOAD address misaligned";
        else if (cause=='h6)  get_mcause_desc = "STORE address misaligned";
        else if (cause=='h10) get_mcause_desc = "Instruction decoding error";
        else if (cause=='h8)  get_mcause_desc = "Environment call (U-mode)";
        else if (cause=='hB)  get_mcause_desc = "Environment call (M-mode)";
        else if (cause=='h2)  get_mcause_desc = "Illegal instruction";
        // Asynchronous Trap
        else if (cause=='h80000003) get_mcause_desc = "Machine Software Interrupt";
        else if (cause=='h80000007) get_mcause_desc = "Machine Timer Interrupt";
        else if (cause=='h8000000B) get_mcause_desc = "Machine External Interrupt";
        // All other unknown interrupts
        else get_mcause_desc = "Unknown Trap Cause";
    endfunction


    /////////////////////////////////////////////////////////////////////
    // Print function used when the FSM is handling a trap
    /////////////////////////////////////////////////////////////////////

    task print_mcause(
        input string           msg,
        input logic [XLEN-1:0] cause
    );
        string cause_str;
        $sformat(cause_str, "%x", cause);
        log.warning({msg,
                     cause_str,
                     " (",
                     get_mcause_desc(cause),
                     ")"
                   });
    endtask


    //////////////////////////////////////////////////////////////////////
    // Get a readable instruction description for logging
    //////////////////////////////////////////////////////////////////////
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
