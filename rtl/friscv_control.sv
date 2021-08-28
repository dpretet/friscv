// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "svlogger.sv"
`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
// Central controller of the processor, fetching instruction and driving
// the ALU, the data memory controller and CSR manager
///////////////////////////////////////////////////////////////////////////////

module friscv_control

    #(
        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // Registers width, 32 bits for RV32i. [CAN'T BE CHANGED]
        parameter XLEN = 32,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = ILEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = XLEN,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,
        // Primary address to boot to load the firmware [0:2**ADDRW-1]
        parameter BOOT_ADDR = 0
    )(
        // clock & reset
        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,
        output logic [4             -1:0] traps,
        // Flush control
        output logic                      flush_req,
        input  logic                      flush_ack,
        // instruction memory interface
        output logic                      arvalid,
        input  logic                      arready,
        output logic [AXI_ADDR_W    -1:0] araddr,
        output logic [3             -1:0] arprot,
        output logic [AXI_ID_W      -1:0] arid,
        input  logic                      rvalid,
        output logic                      rready,
        input  logic [AXI_ID_W      -1:0] rid,
        input  logic [2             -1:0] rresp,
        input  logic [AXI_DATA_W    -1:0] rdata,
        // interface to activate the processing
        output logic                      proc_en,
        input  logic                      proc_ready,
        input  logic                      proc_empty,
        input  logic [4             -1:0] proc_fenceinfo,
        output logic [`INST_BUS_W   -1:0] proc_instbus,
        // interface to activate teh CSR management
        output logic                      csr_en,
        input  logic                      csr_ready,
        output logic [`INST_BUS_W   -1:0] csr_instbus,
        // register source 1 query interface
        output logic [5             -1:0] ctrl_rs1_addr,
        input  logic [XLEN          -1:0] ctrl_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] ctrl_rs2_addr,
        input  logic [XLEN          -1:0] ctrl_rs2_val,
        // register destination for write
        output logic                      ctrl_rd_wr,
        output logic [5             -1:0] ctrl_rd_addr,
        output logic [XLEN          -1:0] ctrl_rd_val,
        // CSR registers
        output logic                      mepc_wr,
        output logic [XLEN          -1:0] mepc,
        output logic                      mstatus_wr,
        output logic [XLEN          -1:0] mstatus,
        output logic                      mcause_wr,
        output logic [XLEN          -1:0] mcause,
        // CSR shared bus
        input  logic [`CSR_SB_W     -1:0] csr_sb
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    // Decoded instructions
    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`FUNCT7_W   -1:0] funct7;
    logic [`RS1_W      -1:0] rs1;
    logic [`RS2_W      -1:0] rs2;
    logic [`RD_W       -1:0] rd;
    logic [`ZIMM_W     -1:0] zimm;
    logic [`IMM12_W    -1:0] imm12;
    logic [`IMM20_W    -1:0] imm20;
    logic [`CSR_W      -1:0] csr;
    logic [`SHAMT_W    -1:0] shamt;
    logic [`PRED_W     -1:0] pred;
    logic [`SUCC_W     -1:0] succ;

    // Flags of the instruction decoder to drive the control unit
    logic             lui;
    logic             auipc;
    logic             jal;
    logic             jalr;
    logic             branching;
    logic             processing;
    logic [2    -1:0] fence;
    logic [6    -1:0] sys;

    // Flag raised when receiving an unsupported/undefined instruction
    logic inst_error;

    // Control fsm
    typedef enum logic[3:0] {
        BOOT = 0,
        FETCH = 1,
        RELOAD = 2,
        FENCE = 3,
        FENCE_I = 4,
        EBREAK = 5
    } pc_fsm;

    pc_fsm cfsm;

    // All program counter for the different instructions
    logic        [XLEN-1:0] pc_plus4;
    logic signed [XLEN-1:0] pc_auipc;
    logic signed [XLEN-1:0] pc_jal;
    logic signed [XLEN-1:0] pc_jalr;
    logic signed [XLEN-1:0] pc_branching;
    logic        [XLEN-1:0] pc;
    logic        [XLEN-1:0] pc_reg;
    logic        [XLEN-1:0] pc_jal_saved;
    logic        [XLEN-1:0] pc_auipc_saved;
    // Extra decoding used during branching
    logic                   beq;
    logic                   bne;
    logic                   blt;
    logic                   bge;
    logic                   bltu;
    logic                   bgeu;
    logic                   goto_branch;
    logic                   jump_branch;
    // Two flags used intot the FSM to stall the process and control
    // the instruction storage
    logic                   cant_branch_now;
    logic                   cant_process_now;
    // FIFO signals
    logic [ILEN       -1:0] instruction;
    logic                   flush_fifo;
    logic                   push_inst;
    logic                   fifo_full;
    logic                   pull_inst;
    logic                   fifo_empty;

    logic [XLEN       -1:0] sb_mepc;
    logic [XLEN       -1:0] sb_mtvec;
    logic [XLEN       -1:0] sb_mstatus;

    logic [XLEN       -1:0] mstatus_for_mret;

    // Logger setup
    svlogger log;
    initial log = new("ControlUnit",
                      `CONTROL_VERBOSITY,
                      `CONTROL_ROUTE);


    /////////////////////////////////////////////////////////////////
    // Used to print instruction during execution, relies on SVLogger
    /////////////////////////////////////////////////////////////////

    task print_instruction(
        input logic [XLEN -1:0] instruction,
        input logic [XLEN -1:0] pc,
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
        string inst_str;
        string pc_str;
        $sformat(inst_str, "%x", instruction);
        $sformat(pc_str, "%x", pc);
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


    ///////////////////////////////////////////////////////////////////////////
    // CSR Shared bus extraction
    ///////////////////////////////////////////////////////////////////////////
        
    assign sb_mtvec = csr_sb[`MTVEC+:XLEN];
    assign sb_mstatus = csr_sb[`MSTATUS+:XLEN];
    assign sb_mepc = csr_sb[`MEPC+:XLEN];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Load/Buffer Stage, a SC-FIFO storing the incoming instructions.
    // This FIFO is controlled by the FSM issuing read request and can be
    // flushed in case branching or jumping is required.
    //
    ///////////////////////////////////////////////////////////////////////////

    assign push_inst = rvalid & (arid == rid);
    assign rready = ~fifo_full;

    friscv_scfifo
    #(
        .PASS_THRU  (0),
        .ADDR_WIDTH ($clog2(OSTDREQ_NUM)),
        .DATA_WIDTH (AXI_DATA_W)
    )
    inst_fifo
    (
        .aclk     (aclk),
        .aresetn  (aresetn),
        .srst     (srst),
        .flush    (flush_fifo),
        .data_in  (rdata),
        .push     (push_inst),
        .full     (fifo_full),
        .data_out (instruction),
        .pull     (pull_inst),
        .empty    (fifo_empty)
    );

    assign pull_inst = (csr_ready && ~cant_branch_now && ~cant_process_now &&
                        cfsm==FETCH && ~fifo_empty) ? 1'b1 : 1'b0;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Decode instruction stage:
    //
    // Will trigger the control and data flows. The instruction set is divided
    // in several parts:
    //
    //   - jumping
    //   - branching
    //   - lui
    //   - auipc
    //   - jal
    //   - jalr
    //   - fence: FENCE (0) / FENCE.I (1)
    //   - sys: CSR (0) / ECALL (1) / EBREAK (2)
    //          MRET (4) / SRET (5) / WFI (6)
    //   - processing: alll others
    //
    // Processing is handled by ALU & Memfy, responsible of data memory access,
    // registers management and arithmetic/logic operations.
    //
    // All the other flags are handled in this module.
    //
    ///////////////////////////////////////////////////////////////////////////


    friscv_decoder
    #(
        .XLEN   (XLEN)
    )
    decoder
    (
        .instruction (instruction),
        .opcode      (opcode),
        .funct3      (funct3),
        .funct7      (funct7),
        .rs1         (rs1),
        .rs2         (rs2),
        .rd          (rd),
        .zimm        (zimm),
        .imm12       (imm12),
        .imm20       (imm20),
        .csr         (csr),
        .shamt       (shamt),
        .fence       (fence),
        .lui         (lui),
        .auipc       (auipc),
        .jal         (jal),
        .jalr        (jalr),
        .branching   (branching),
        .sys         (sys),
        .processing  (processing),
        .inst_error  (inst_error),
        .pred        (pred),
        .succ        (succ)
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction sourcing Stage: put in shape the instruction bus passed to
    // the processing module and the CSR
    //
    ///////////////////////////////////////////////////////////////////////////

    // TODO: Needs csr_ready checking ?
    assign proc_en = ~fifo_empty & processing & (cfsm==FETCH) & csr_ready;

    assign csr_en = ~fifo_empty && sys[`IS_CSR] & (cfsm==FETCH);

    assign proc_instbus[`OPCODE +: `OPCODE_W] = opcode;
    assign proc_instbus[`FUNCT3 +: `FUNCT3_W] = funct3;
    assign proc_instbus[`FUNCT7 +: `FUNCT7_W] = funct7;
    assign proc_instbus[`RS1    +: `RS1_W   ] = rs1   ;
    assign proc_instbus[`RS2    +: `RS2_W   ] = rs2   ;
    assign proc_instbus[`RD     +: `RD_W    ] = rd    ;
    assign proc_instbus[`ZIMM   +: `ZIMM_W  ] = zimm  ;
    assign proc_instbus[`IMM12  +: `IMM12_W ] = imm12 ;
    assign proc_instbus[`IMM20  +: `IMM20_W ] = imm20 ;
    assign proc_instbus[`CSR    +: `CSR_W   ] = csr   ;
    assign proc_instbus[`SHAMT  +: `SHAMT_W ] = shamt ;

    assign csr_instbus = proc_instbus;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Program counter computation
    //
    ///////////////////////////////////////////////////////////////////////////

    // increment counter by 4 because we index bytes
    assign pc_plus4 = pc_reg + {{(XLEN-3){1'b0}},3'b100};

    // AUIPC: Add Upper Immediate into Program Counter
    assign pc_auipc = $signed(pc_reg) + $signed({imm20,12'b0});

    // JAL: current program counter + offset
    assign pc_jal = $signed(pc_reg) + $signed({{11{imm20[19]}}, imm20, 1'b0});

    // JALR: program counter equals  rs1 + offset
    assign pc_jalr = $signed(ctrl_rs1_val) + $signed({{20{imm12[11]}}, imm12});

    // For all branching instruction
    assign pc_branching =  $signed(pc_reg) + $signed({{19{imm12[11]}}, imm12, 1'b0});

    // program counter switching logic
    assign pc = (cfsm==BOOT)                ? pc_reg :
                // FENCE (0) or FENCE.I (1)
                (|fence)                    ? pc_plus4 :
                // System calls
                (|sys)                      ? pc_plus4 :
                // Load immediate
                (lui)                       ? pc_plus4 :
                // Add upper immediate in PC
                (auipc)                     ? pc_plus4 :
                // Jumps
                (jal)                       ? pc_jal :
                (jalr)                      ? {pc_jalr[31:1],1'b0} :
                // branching and comparaison is true
                (branching && goto_branch)  ? pc_branching :
                // branching and comparaison is false
                (branching && ~goto_branch) ? pc_plus4 :
                // arithmetic processing
                (processing)                ? pc_plus4 :
                                              pc_reg;

    ///////////////////////////////////////////////////////////////////////////
    //
    // Branching flags
    //
    ///////////////////////////////////////////////////////////////////////////

    // BEQ: branch if equal
    assign beq = ($signed(ctrl_rs1_val) == $signed(ctrl_rs2_val)) ? 1'b1 : 1'b0;

    // BNE: branch if not equal
    assign bne = ($signed(ctrl_rs1_val) != $signed(ctrl_rs2_val)) ? 1'b1 : 1'b0;

    // BLT: branch if less
    assign blt = ($signed(ctrl_rs1_val) < $signed(ctrl_rs2_val)) ? 1'b1 : 1'b0;

    // BGE: branch if greater
    assign bge = ($signed(ctrl_rs1_val) >= $signed(ctrl_rs2_val)) ? 1'b1 : 1'b0;

    // BLTU: branch if less (unsigned)
    assign bltu = (ctrl_rs1_val < ctrl_rs2_val) ? 1'b1 : 1'b0;

    // BGE: branch if greater (unsigned)
    assign bgeu = (ctrl_rs1_val >= ctrl_rs2_val) ? 1'b1 : 1'b0;

    // activate branching only if valid FUNCT3 received
    assign goto_branch = ((funct3 == `BEQ  && beq)  ||
                          (funct3 == `BNE  && bne)  ||
                          (funct3 == `BLT  && blt)  ||
                          (funct3 == `BGE  && bge)  ||
                          (funct3 == `BLTU && bltu) ||
                          (funct3 == `BGEU && bgeu)) ? 1'b1 : 1'b0;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control flow FSM: the FSM updating the program counter, managing the
    // incoming instructions and the processing unit
    //
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cfsm <= BOOT;
            arvalid <= 1'b0;
            araddr <= {AXI_ADDR_W{1'b0}};
            pc_reg <= {(XLEN){1'b0}};
            pc_jal_saved <= {(XLEN){1'b0}};
            pc_auipc_saved <= {(XLEN){1'b0}};
            traps <= 4'b0;
            flush_fifo <= 1'b0;
            arid <= {AXI_ID_W{1'b0}};
            flush_req <= 1'b0;
            mepc_wr <= 1'b0;
            mepc <= {XLEN{1'b0}};
            mstatus_wr <= 1'b0;
            mstatus <= {XLEN{1'b0}};
            mcause_wr <= 1'b0;
            mcause <= {XLEN{1'b0}};
        end else if (srst == 1'b1) begin
            cfsm <= BOOT;
            arvalid <= 1'b0;
            araddr <= {AXI_ADDR_W{1'b0}};
            pc_reg <= {(XLEN){1'b0}};
            pc_jal_saved <= {(XLEN){1'b0}};
            pc_auipc_saved <= {(XLEN){1'b0}};
            traps <= 4'b0;
            flush_fifo <= 1'b0;
            arid <= {AXI_ID_W{1'b0}};
            flush_req <= 1'b0;
            mepc_wr <= 1'b0;
            mepc <= {XLEN{1'b0}};
            mstatus_wr <= 1'b0;
            mstatus <= {XLEN{1'b0}};
            mcause_wr <= 1'b0;
            mcause <= {XLEN{1'b0}};
        end else begin

            case (cfsm)

                // Start to boot the RAM after reset.
                default: begin

                    arvalid <= 1'b1;
                    araddr <= BOOT_ADDR;
                    pc_reg <= BOOT_ADDR;

                    if (arready) begin
                        log.info("Boot the processor");
                        cfsm <= FETCH;
                    end
                end

                // Fetch instructions from the cache (or the memory)
                FETCH: begin

                    // Manages read outstanding requests to fetch
                    // new instruction from memory:
                    //
                    //   - if fifo is filled with instruction, need a jump
                    //     and can branch and CSR are ready, stop the addr
                    //     issuer and load it with correct address to use
                    //
                    if (~fifo_empty && 
                        (jump_branch || sys[`IS_ECALL] || sys[`IS_MRET] || fence[`IS_FENCEI]) &&
                        ~cant_branch_now && csr_ready) begin
                        // ECALL
                        if (sys[`IS_ECALL]) araddr <= sb_mtvec;
                        else if (sys[`IS_MRET]) araddr <= sb_mepc;
                        // All other jumps
                        else araddr <= pc;
                    //
                    //   - else continue to simply increment by instruction width
                    //   TODO: don't continue to increment if need to jump?
                    //
                    end else if (arready) begin
                        araddr <= araddr + ILEN/8;
                    end

                    // Manages the PC vs the different instructions to execute
                    if (~fifo_empty) begin

                        // Stop the execution when an supported instruction or
                        // a decoding error has been issued
                        if (inst_error) begin
                            log.error("Decoding error, received an unsupported instruction");
                            print_instruction(instruction, pc_reg, opcode, funct3,
                                              funct7, rs1, rs2, rd, imm12, imm20, csr);
                            traps[3] <= 1'b1;
                            flush_fifo <= 1'b1;
                            arvalid <= 1'b0;
                            arid <= arid + 1;
                            pc_reg <= sb_mtvec;
                            mepc_wr <= 1'b1;
                            mepc <= pc_reg;
                            mcause_wr <= 1'b1;
                            mcause <= {{XLEN-2{1'b0}}, 2'h2};
                            cfsm <= RELOAD;
                        end

                        // Needs to jump or branch thus stop the pipeline
                        // and reload new instructions
                        else if (jump_branch && ~cant_branch_now && csr_ready) begin

                            log.info("Execute Jump/Branch");
                            print_instruction(instruction, pc_reg, opcode, funct3,
                                              funct7, rs1, rs2, rd, imm12, imm20, csr);
                            flush_fifo <= 1'b1;
                            arvalid <= 1'b0;
                            arid <= arid + 1;
                            pc_reg <= pc;
                            cfsm <= RELOAD;

                        // Reach an ECALL instruction, jump to trap handler
                        end else if (sys[`IS_ECALL] && ~cant_branch_now && csr_ready) begin

                            log.info("Execute ECALL -> Jump to trap handler");
                            print_instruction(instruction, pc_reg, opcode, funct3,
                                              funct7, rs1, rs2, rd, imm12, imm20, csr);
                            traps[0] <= 1'b1;
                            flush_fifo <= 1'b1;
                            arvalid <= 1'b0;
                            arid <= arid + 1;
                            pc_reg <= sb_mtvec;
                            mepc_wr <= 1'b1;
                            mepc <= pc_reg;
                            cfsm <= RELOAD;

                        // Reach an EBREAK instruction, need to stall the core
                        end else if (sys[`IS_EBREAK]) begin

                            log.info("Execute EBREAK -> Stop the processor");
                            print_instruction(instruction, pc_reg, opcode, funct3,
                                              funct7, rs1, rs2, rd, imm12, imm20, csr);
                            flush_fifo <= 1'b1;
                            traps[1] <= 1'b1;
                            cfsm <= EBREAK;

                        // Reach a MRET instruction, jump to exception return
                        end else if (sys[`IS_MRET] && ~cant_branch_now && csr_ready) begin

                            log.info("Execute MRET -> Return from trap");
                            print_instruction(instruction, pc_reg, opcode, funct3,
                                              funct7, rs1, rs2, rd, imm12, imm20, csr);
                            flush_fifo <= 1'b1;
                            traps[2] <= 1'b1;
                            arvalid <= 1'b0;
                            arid <= arid + 1;
                            pc_reg <= sb_mepc;
                            mstatus_wr <= 1'b1;
                            mstatus <= mstatus_for_mret;
                            cfsm <= RELOAD;

                        // Reach a FENCE.i instruction, need to flush the cache
                        // the instruction pipeline
                        end else if (fence[`IS_FENCEI]) begin

                            log.info("Execute FENCE.i -> Start iCache flushing");
                            print_instruction(instruction, pc_reg, opcode, funct3,
                                              funct7, rs1, rs2, rd, imm12, imm20, csr);
                            flush_fifo <= 1'b1;
                            pc_reg <= pc;
                            arvalid <= 1'b0;
                            arid <= arid + 1;
                            pc_reg <= pc;
                            cfsm <= FENCE_I;
                        end

                        // Need to branch/process but ALU/memfy/CSR didn't finish
                        // to execute last instruction, so store it.
                        else if (~csr_ready || cant_branch_now || cant_process_now) begin

                            pc_jal_saved <= pc_plus4;
                            pc_auipc_saved <= pc_reg;

                        // Process as long instructions are available
                        end else if (csr_ready &&
                                     ~cant_branch_now && ~cant_process_now) begin
                            print_instruction(instruction, pc_reg, opcode, funct3,
                                              funct7, rs1, rs2, rd, imm12, imm20, csr);
                            pc_reg <= pc;
                        end
                    end
                end

                // Stop operations to reload new oustanding requests. Used to
                // reboot the cache and continue to fetch the addresses from
                // a new origin
                RELOAD: begin
                    traps <= 2'b0;
                    mepc_wr <= 1'b0;
                    mstatus_wr <= 1'b0;
                    mcause_wr <= 1'b0;
                    arvalid <= 1'b1;
                    flush_fifo <= 1'b0;
                    cfsm <= FETCH;
                end

                // Launch a cache flush, req starts the flush and is kept
                // high as long ack is not asserted.
                // TODO: ensure the instruction pipeline is empty before
                //       moving back to execution
                FENCE_I: begin
                    flush_req <= 1'b1;
                    if (flush_ack) begin
                        log.info("FENCE.i execution done");
                        flush_req <= 1'b0;
                        flush_fifo <= 1'b0;
                        arvalid <= 1'b1;
                        cfsm <= RELOAD;
                    end
                end

                // EBREAK completly stops the processor and wait for a reboot
                // TODO: Understand how to manage EBREAK when software needs
                EBREAK: begin
                    traps <= 2'b0;
                    arvalid <= 1'b0;
                    flush_fifo <= 1'b0;
                    cfsm <= EBREAK;
                end

            endcase

        end
    end

    // Unused AXI protection capability
    assign arprot = 3'b0;

    // Needs to jump or branch, the request to cache/RAM needs to be restarted
    assign jump_branch = (branching & goto_branch) | jal | jalr;

    // Two flags to stop the processor if ALU/memfy are computing

    assign cant_branch_now = ((jal || jalr || branching) &&
                               ~proc_ready) ? 1'b1 :
                                              1'b0;

    assign cant_process_now = (processing && ~proc_ready) ? 1'b1 : 1'b0;


    ///////////////////////////////////////////////////////////////////////////
    //
    // ISA registers write stage
    //
    ///////////////////////////////////////////////////////////////////////////

    // register source 1 & 2 read
    assign ctrl_rs1_addr = rs1;
    assign ctrl_rs2_addr = rs2;

    // register destination
    assign ctrl_rd_wr =  (cfsm!=FETCH)                                ? 1'b0 :
                         (pull_inst && (auipc || jal || jalr || lui)) ? 1'b1 :
                                                                        1'b0 ;
    assign ctrl_rd_addr = rd;

    assign ctrl_rd_val = ((jal || jalr) && ~pull_inst) ? pc_jal_saved :
                         ((jal || jalr) && pull_inst)  ? pc_plus4 :
                         (lui)                         ? {imm20, 12'b0} :
                         (auipc && ~pull_inst)         ? pc_auipc_saved :
                         (auipc && pull_inst)          ? pc_auipc       :
                                                         pc;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Prepare CSR registers content to store during exceptions and trap
    //
    ///////////////////////////////////////////////////////////////////////////

    // MSTATUS CSR to write when executing MRET
    assign mstatus_for_mret = {sb_mstatus[XLEN-1:12],  // WPRI
                               2'b11,                  // MPP
                               sb_mstatus[10:9],       // WPRI
                               1'b0,                   // SPP
                               1'b1,                   // MPIE
                               sb_mstatus[6],          // WPRI
                               1'b0,                   // SPIE
                               1'b0,                   // UPIE
                               sb_mstatus[7],          // MIE
                               sb_mstatus[2],          // WPRI
                               1'b0,                   // SIE
                               1'b0};                  // UIE

endmodule

`resetall
