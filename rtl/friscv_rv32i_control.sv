`timescale 1 ns / 1 ps
`default_nettype none

module friscv_rv32i_control

    #(
        parameter             ADDRW     = 16,
        parameter [ADDRW-1:0] BOOT_ADDR = {ADDRW{1'b0}},
        parameter             XLEN      = 32
    )(
        // clock & reset
        input  wire              aclk,
        input  wire              aresetn,
        input  wire              srst,
        // instruction memory interface
        output logic             inst_en,
        output logic [ADDRW-1:0] inst_addr,
        input  wire  [XLEN -1:0] inst_rdata,
        input  wire              inst_ready,
        // interface to activate the ALU processing
        output logic             alu_en,
        input  wire              alu_ready,
        output logic [7    -1:0] opcode,
        output logic [3    -1:0] funct3,
        output logic [7    -1:0] funct7,
        output logic [5    -1:0] rs1,
        output logic [5    -1:0] rs2,
        output logic [5    -1:0] rd,
        output logic [5    -1:0] zimm,
        output logic [12   -1:0] imm12,
        output logic [20   -1:0] imm20,
        output logic [12   -1:0] csr,
        output logic [5    -1:0] shamt,
        // register source 1 query interface
        output logic [5    -1:0] regs_rs1_addr,
        input  wire  [XLEN -1:0] regs_rs1_val,
        // register source 2 for query interface
        output logic [5    -1:0] regs_rs2_addr,
        input  wire  [XLEN -1:0] regs_rs2_val
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameter and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    // program counter, expressed in bytes
    logic [ADDRW+2-1:0] pc;
    // flags of the instruction decoder to drive the control unit
    logic               jumping;
    logic               branching;
    logic               system;
    logic               processing;
    // flag raised when receiving an unsupported/undefined instruction
    logic               inst_error;
    // csr instructions
    logic [4      -1:0] pred;
    logic [4      -1:0] succ;

    logic [XLEN   -1:0] instruction;
    logic [XLEN   -1:0] inst_store;

    // control fsm
    typedef enum logic[3:0] {
        BOOT = 0,
        RUN = 1,
        HALT = 2,
        ERROR = 3
    } pc_fsm;

    pc_fsm cfsm;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Decodes instruction which will trigger the control and data flows.
    //
    // The instruction set is divided in 4 parts:
    //
    //   - jumping
    //   - branching
    //   - system
    //   - processing
    //
    // The first three sets are handlded in control (this module) and dedicated
    // to instruction memory parsing thru the pc (program counter) and software
    // interaction (for instance `ecall` or `break` instructions).
    //
    // Processing is handled by ALU, responsible of data memory access,
    // registers management and arithmetic/logic operations.
    //
    ///////////////////////////////////////////////////////////////////////////

    // TODO:
    // This circuit stores the instruction received if ALU is required for
    // processing and not available. Stores the incoming instruction and
    // drives the ALU according its state.
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            inst_store <= {XLEN{1'b1}};
        end else if (srst == 1'b1) begin
            inst_store <= {XLEN{1'b1}};
        end else begin

        end
    end

    friscv_rv32i_decoder
    #(
        .XLEN   (XLEN)
    )
    decoder
    (
        .instruction (inst_rdata),
        .opcode      (opcode    ),
        .funct3      (funct3    ),
        .funct7      (funct7    ),
        .rs1         (rs1       ),
        .rs2         (rs2       ),
        .rd          (rd        ),
        .zimm        (zimm      ),
        .imm12       (imm12     ),
        .imm20       (imm20     ),
        .csr         (csr       ),
        .shamt       (shamt     ),
        .jumping     (jumping   ),
        .branching   (branching ),
        .system      (system    ),
        .processing  (processing),
        .inst_error  (inst_error),
        .pred        (pred      ),
        .succ        (succ      )
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control flow FSM
    //
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            cfsm <= BOOT;
            inst_en <= 1'b0;
            pc <= {(ADDRW+2){1'b0}};
        end if (srst == 1'b1) begin
            cfsm <= BOOT;
            inst_en <= 1'b0;
            pc <= {(ADDRW+2){1'b0}};
        end else begin

            case (cfsm)

                // start to boot the RAM after reset
                default: begin
                    pc <= {BOOT_ADDR,2'b0};
                    inst_en <= 1'b1;
                    cfsm <= BOOT;
                end

                // Run the core
                RUN: begin
                    if (inst_ready && alu_ready) begin
                        if (inst_error) begin
                            cfsm <= ERROR;
                        end else if (processing) begin
                            pc <= pc + {{(ADDRW+2-3){1'b0}},3'b100};
                        end
                    end
                end

                // HALT because the instruction is long to execute or RAM
                // didn't yet return the completion
                HALT: begin

                end

                // ERROR reached when:
                // - received an undefined/unsupported instruction
                ERROR: begin
                    $finish();
                end

            endcase

        end
    end

    assign alu_en = 1'b0;

    // select only MSB because RAM is addressed by word
    assign inst_addr = pc[2+:ADDRW];

    // register source 1 & 2 read
    assign regs_rs1_addr = rs1;
    assign regs_rs2_addr = rs2;

endmodule

`resetall
