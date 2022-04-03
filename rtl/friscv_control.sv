// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

///////////////////////////////////////////////////////////////////////////////
// Central controller of the processor, fetching instruction and driving
// the processing (ALU & data controller) and CSR manager.
///////////////////////////////////////////////////////////////////////////////

module friscv_control

    #(
        // Instruction length (always 32, whatever the architecture)
        parameter ILEN = 32,
        // Registers width, 32 bits for RV32i
        parameter XLEN = 32,
        // Reduced RV32 arch
        parameter RV32E = 0,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = ILEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = XLEN,
        // Fast jump mode tracks the register usage and avoid wait state in control unit
        parameter FAST_JUMP = 0,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,
        // Primary address to boot to load the firmware
        parameter BOOT_ADDR = 0
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        output logic [5             -1:0] traps,
        `ifdef FRISCV_SIM
        output logic [XLEN          -1:0] pc_val,
        `endif
        // Flush control
        output logic                      flush_req,
        input  wire                       flush_ack,
        // instruction memory interface
        output logic                      arvalid,
        input  wire                       arready,
        output logic [AXI_ADDR_W    -1:0] araddr,
        output logic [3             -1:0] arprot,
        output logic [AXI_ID_W      -1:0] arid,
        input  wire                       rvalid,
        output logic                      rready,
        input  wire  [AXI_ID_W      -1:0] rid,
        input  wire  [2             -1:0] rresp,
        input  wire  [AXI_DATA_W    -1:0] rdata,
        // interface to activate the processing
        output logic                      proc_valid,
        input  wire                       proc_ready,
        output logic [`INST_BUS_W   -1:0] proc_instbus,
        input  wire  [4             -1:0] proc_fenceinfo,
        input  wire  [2             -1:0] proc_exceptions,
        input  wire                       proc_busy,
        // interface to activate teh CSR management
        output logic                      csr_en,
        input  wire                       csr_ready,
        output logic [`INST_BUS_W   -1:0] csr_instbus,
        // register source 1 query interface
        output logic [5             -1:0] ctrl_rs1_addr,
        input  wire  [XLEN          -1:0] ctrl_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] ctrl_rs2_addr,
        input  wire  [XLEN          -1:0] ctrl_rs2_val,
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
        output logic                      mtval_wr,
        output logic [XLEN          -1:0] mtval,
        // CSR shared bus
        input  wire  [`CSR_SB_W     -1:0] csr_sb
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
    logic             dec_error;

    // Control fsm
    typedef enum logic[3:0] {
        BOOT = 0,
        FETCH = 1,
        RELOAD = 2,
        FENCE = 3,
        FENCE_I = 4,
        WFI = 5,
        EBREAK = 6
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
    logic                   lui_auipc;
    // Two flags used intot the FSM to stall the process and control
    // the instruction storage
    logic                   cant_jump;
    logic                   cant_process;
    logic                   cant_lui_auipc;
    logic                   cant_sys;
    logic                   regs_rsvd;
    // FIFO signals
    logic [ILEN       -1:0] instruction;
    logic                   flush_fifo;
    logic                   push_inst;
    logic                   fifo_full;
    logic                   pull_inst;
    logic                   fifo_empty;
    logic [XLEN       -1:0] mtvec;

    logic [XLEN       -1:0] sb_mepc;
    logic [XLEN       -1:0] sb_mtvec;
    logic [XLEN       -1:0] sb_mstatus;

    logic [XLEN       -1:0] mstatus_for_mret;
    logic [XLEN       -1:0] mstatus_for_trap;
    logic                   csr_ro_wr;
    logic                   inst_addr_misaligned;
    logic [XLEN       -1:0] mcause_code;
    logic [XLEN       -1:0] mtval_info;
    logic                   load_misaligned;
    logic                   store_misaligned;
    logic                   wfi_not_allowed;
    logic                   trap_occuring;
    logic                   sync_trap_occuring;
    logic                   async_trap_occuring;

    logic [2         -1:0] priv_mode;

    // Logger setup
    `ifdef USE_SVL
    `include "svlogger.sv"
    svlogger log;
    initial log = new("ControlUnit",
                      `CONTROL_VERBOSITY,
                      `CONTROL_ROUTE);
    `endif


    /////////////////////////////////////////////////////////////////
    // Used to print instruction during execution, relies on SVLogger
    /////////////////////////////////////////////////////////////////

    task print_instruction;
        `ifdef USE_SVL
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
        `endif
    endtask

    /////////////////////////////////////////////////////////////////////
    // Get a description of a synchronous exception when handling a trap
    /////////////////////////////////////////////////////////////////////
    function automatic string get_mcause_desc(input integer cause);
        if (cause==1) get_mcause_desc = "Read-only CSR write access";
        if (cause==0) get_mcause_desc = "Instruction address misaligned";
        if (cause==4) get_mcause_desc = "LOAD address misaligned";
        if (cause==6) get_mcause_desc = "STORE address misaligned";
        if (cause==2) get_mcause_desc = "Instruction decoding error";
    endfunction


    /////////////////////////////////////////////////////////////////////
    // Print function used when the FSM is handling a trap
    /////////////////////////////////////////////////////////////////////
    task print_mcause(
        input string           msg,
        input logic [XLEN-1:0] cause
    );
        `ifdef USE_SVL
        string cause_str;
        $sformat(cause_str, "%x", cause);
        log.warning({msg,
                     cause_str,
                     " (",
                     get_mcause_desc(cause),
                     ")"
                   });
        `endif
    endtask


    //////////////////////////////////////////////////////////////////////
    // Return next ID during program counter increment during address jump
    //////////////////////////////////////////////////////////////////////
    function automatic logic [AXI_ID_W-1:0] next_id(
        input logic  [AXI_ID_W-1:0] id
    );
        if (id==OSTDREQ_NUM-1) next_id = {AXI_ID_W{1'b0}};
        else next_id = id + 1'b1;
    endfunction


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

    assign pull_inst = (~cant_jump && ~cant_process && ~cant_lui_auipc && ~cant_sys &&
                        ~fifo_empty && (cfsm==FETCH) && ~trap_occuring) ? 1'b1 : 1'b0;

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
    //   - sys: ECALL (0) / EBREAK (1) / CSR (2) / MRET (3) / SRET (4) / WFI (5)
    //   - processing: all others
    //
    // Processing is handled by ALU & Memfy, responsible of data memory access,
    // registers management and arithmetic/logic operations
    //
    // CSR is handled by a dedicated module
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
        .dec_error   (dec_error),
        .pred        (pred),
        .succ        (succ)
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction sourcing Stage: put in shape the instruction bus passed to
    // the processing module and the CSR
    //
    ///////////////////////////////////////////////////////////////////////////

    assign proc_valid = ~fifo_empty & processing & (cfsm==FETCH) & csr_ready;

    assign csr_en = ~fifo_empty && sys[`IS_CSR] & (cfsm==FETCH) & ~proc_busy;

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

    // Increment counter by 4 because we index bytes
    assign pc_plus4 = pc_reg + ILEN/8;

    // AUIPC: Add Upper Immediate into Program Counter
    assign pc_auipc = $signed(pc_reg) + $signed({imm20,12'b0});

    // JAL: current program counter + offset
    assign pc_jal = $signed(pc_reg) + $signed({{11{imm20[19]}}, imm20, 1'b0});

    // JALR: program counter equals  rs1 + offset
    assign pc_jalr = $signed(ctrl_rs1_val) + $signed({{20{imm12[11]}}, imm12});

    // For all branching instruction
    assign pc_branching =  $signed(pc_reg) + $signed({{19{imm12[11]}}, imm12, 1'b0});

    // Program counter switching logic
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

    // Activate branching only if valid FUNCT3 received
    assign goto_branch = ((funct3 == `BEQ  && beq)  ||
                          (funct3 == `BNE  && bne)  ||
                          (funct3 == `BLT  && blt)  ||
                          (funct3 == `BGE  && bge)  ||
                          (funct3 == `BLTU && bltu) ||
                          (funct3 == `BGEU && bgeu)) ? 1'b1 : 1'b0;


    ///////////////////////////////////////////////////////////////////////////
    //
    // Control flow: the FSM updating the program counter, managing the
    // incoming instructions, the CSR & processing unit and all traps
    //
    ///////////////////////////////////////////////////////////////////////////

    assign pc_val = pc_reg;

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cfsm <= BOOT;
            arvalid <= 1'b0;
            araddr <= {AXI_ADDR_W{1'b0}};
            pc_reg <= {(XLEN){1'b0}};
            pc_jal_saved <= {(XLEN){1'b0}};
            pc_auipc_saved <= {(XLEN){1'b0}};
            traps <= 5'b0;
            flush_fifo <= 1'b0;
            arid <= {AXI_ID_W{1'b0}};
            flush_req <= 1'b0;
            mepc_wr <= 1'b0;
            mepc <= {XLEN{1'b0}};
            mstatus_wr <= 1'b0;
            mstatus <= {XLEN{1'b0}};
            mcause_wr <= 1'b0;
            mcause <= {XLEN{1'b0}};
            mtval_wr <= 1'b0;
            mtval <= {XLEN{1'b0}};
            priv_mode <= 2'b11;
        end else if (srst == 1'b1) begin
            cfsm <= BOOT;
            arvalid <= 1'b0;
            araddr <= {AXI_ADDR_W{1'b0}};
            pc_reg <= {(XLEN){1'b0}};
            pc_jal_saved <= {(XLEN){1'b0}};
            pc_auipc_saved <= {(XLEN){1'b0}};
            traps <= 5'b0;
            flush_fifo <= 1'b0;
            arid <= {AXI_ID_W{1'b0}};
            flush_req <= 1'b0;
            mepc_wr <= 1'b0;
            mepc <= {XLEN{1'b0}};
            mstatus_wr <= 1'b0;
            mstatus <= {XLEN{1'b0}};
            mcause_wr <= 1'b0;
            mcause <= {XLEN{1'b0}};
            mtval_wr <= 1'b0;
            mtval <= {XLEN{1'b0}};
            priv_mode <= 2'b11;
        end else begin

            case (cfsm)

                ///////////////////////////////////////////////////////////////
                // Start to boot the RAM after reset.
                ///////////////////////////////////////////////////////////////
                default: begin

                    // Load boot address
                    arvalid <= 1'b1;
                    araddr <= BOOT_ADDR;
                    pc_reg <= BOOT_ADDR;
                    // Machine-mode by default after a reset
                    priv_mode <= 2'b11;

                    if (arready) begin
                        `ifdef USE_SVL
                        log.info("IDLE -> Boot the processor");
                        `endif
                        cfsm <= FETCH;
                    end
                end

                ///////////////////////////////////////////////////////////////
                // Fetch instructions from the cache (or the memory)
                ///////////////////////////////////////////////////////////////
                FETCH: begin

                    mepc_wr <= 1'b0;
                    mstatus_wr <= 1'b0;
                    mcause_wr <= 1'b0;
                    mtval_wr <= 1'b0;

                    ///////////////////////////////////////////////////////////
                    // Manages read outstanding requests to fetch
                    // new instruction from memory:
                    //
                    //   - if fifo is filled with instruction, need a jump or
                    //   manage a trap, stop the addr issuer and load the
                    //   right branch
                    //
                    if (~fifo_empty &&
                        (jump_branch || sys[`IS_ECALL] || sys[`IS_MRET] ||
                         fence[`IS_FENCEI] || trap_occuring) &&
                        ~cant_jump) begin

                        // ECALL / Trap handling
                        if (sys[`IS_ECALL] || trap_occuring) araddr <= mtvec;
                        // MRET
                        else if (sys[`IS_MRET]) araddr <= sb_mepc;
                        // All other jumps
                        else araddr <= pc;
                    //
                    //   - else continue to simply increment by ILEN
                    //
                    end else if (arready) begin
                        araddr <= araddr + ILEN/8;
                    end
                    ///////////////////////////////////////////////////////////

                    ///////////////////////////////////////////////////////////
                    // Manages the PC vs the different instructions to execute
                    if (~fifo_empty) begin

                        // Need to branch/process but ALU/memfy/CSR didn't finish
                        // to execute last instruction, so store PCs.
                        if (cant_jump || cant_process || cant_lui_auipc || cant_sys) begin
                            pc_jal_saved <= pc_plus4;
                            pc_auipc_saved <= pc_reg;
                        end

                        // Move to the trap handling when received an
                        // interrupt, a wrong instruction, ...
                        if (trap_occuring) begin

                            `ifdef USE_SVL
                            print_mcause("Handling a trap -> MCAUSE=0x", mcause_code);
                            print_instruction;
                            `endif
                            traps[3] <= 1'b1;
                            flush_fifo <= 1'b1;
                            arvalid <= 1'b0;
                            arid <= next_id(arid);
                            pc_reg <= mtvec;
                            mepc_wr <= 1'b1;
                            mepc <= pc_reg;
                            mcause_wr <= 1'b1;
                            mcause <= mcause_code;
                            mtval_wr <= 1'b1;
                            mtval <= mtval_info;
                            mstatus_wr <= 1'b1;
                            mstatus <= mstatus_for_trap;
                            cfsm <= RELOAD;
                        end

                        // Needs to jump or branch thus stop the pipeline
                        // and reload new instructions
                        else if (jal | jalr | branching) begin

                            if (~cant_jump) begin
                                `ifdef USE_SVL
                                print_instruction;
                                `endif
                                pc_reg <= pc;
                            end

                            if (jump_branch & ~cant_jump) begin
                                `ifdef USE_SVL
                                if (jal | jalr) log.info("Jumping");
                                else log.info("Branching");
                                `endif
                            end

                            if (jump_branch && ~cant_jump) begin
                                flush_fifo <= 1'b1;
                                arvalid <= 1'b0;
                                arid <= next_id(arid);
                                cfsm <= RELOAD;
                            end

                        // Any sys instruction:
                        // - ECALL (0) / EBREAK (1) / CSR (2) / MRET (3) / SRET (4) / WFI (5)
                        end else if (|sys || |fence) begin

                            // Reach an ECALL instruction, jump to trap handler
                            if (sys[`IS_ECALL] && ~proc_busy && csr_ready) begin

                                `ifdef USE_SVL
                                print_instruction;
                                log.info("ECALL -> Jump to trap handler");
                                `endif
                                traps[0] <= 1'b1;
                                flush_fifo <= 1'b1;
                                arvalid <= 1'b0;
                                arid <= next_id(arid);
                                pc_reg <= mtvec;
                                mepc_wr <= 1'b1;
                                mepc <= pc_reg;
                                mtval_wr <= 1'b1;
                                mtval <= mtval_info;
                                cfsm <= RELOAD;

                            // Reach an EBREAK instruction, need to stall the core
                            end else if (sys[`IS_EBREAK]) begin

                                `ifdef USE_SVL
                                print_instruction;
                                log.info("EBREAK -> Stop the processor");
                                `endif
                                flush_fifo <= 1'b1;
                                traps[1] <= 1'b1;
                                cfsm <= EBREAK;

                            // Reach a MRET instruction, jump to exception return
                            end else if (sys[`IS_MRET] && ~proc_busy && csr_ready) begin

                                `ifdef USE_SVL
                                print_instruction;
                                log.info("MRET -> Machine Return");
                                `endif
                                flush_fifo <= 1'b1;
                                traps[2] <= 1'b1;
                                arvalid <= 1'b0;
                                arid <= next_id(arid);
                                pc_reg <= sb_mepc;
                                mstatus_wr <= 1'b1;
                                mstatus <= mstatus_for_mret;
                                cfsm <= RELOAD;

                            // Reach a FENCE.i instruction, need to flush the cache
                            // the instruction pipeline
                            end else if (fence[`IS_FENCEI]) begin

                                `ifdef USE_SVL
                                print_instruction;
                                log.info("FENCE.i -> Start iCache flushing");
                                `endif
                                flush_fifo <= 1'b1;
                                pc_reg <= pc;
                                arvalid <= 1'b0;
                                arid <= next_id(arid);
                                pc_reg <= pc;
                                cfsm <= FENCE_I;

                            // Reach an ECALL instruction, jump to trap handler
                            end else if (sys[`IS_WFI] && ~proc_busy && csr_ready) begin

                                `ifdef USE_SVL
                                print_instruction;
                                log.info("WFI -> Stall and wait for interrupt");
                                `endif
                                traps[0] <= 1'b1;
                                flush_fifo <= 1'b1;
                                arvalid <= 1'b0;
                                pc_reg <= mtvec;
                                mepc_wr <= 1'b1;
                                mepc <= pc_reg;
                                mtval_wr <= 1'b1;
                                mtval <= mtval_info;
                                cfsm <= WFI;

                            // CSR instructions
                            end else if (sys[`IS_CSR] && ~cant_sys) begin

                                `ifdef USE_SVL
                                print_instruction;
                                `endif
                                pc_reg <= pc;

                            // FENCE instruction (not supported)
                            end else if (~proc_busy && csr_ready) begin

                                `ifdef USE_SVL
                                print_instruction;
                                `endif
                                pc_reg <= pc;
                            end

                        // LUI and AUIPC execution, done in this module
                        end else if (lui_auipc && ~cant_lui_auipc) begin

                            `ifdef USE_SVL
                            print_instruction;
                            `endif
                            pc_reg <= pc;

                        // All other instructions
                        end else if (processing) begin

                            if (~cant_process) begin
                                `ifdef USE_SVL
                                print_instruction;
                                `endif
                                pc_reg <= pc;
                            end
                        end
                    end
                    ///////////////////////////////////////////////////////////
                end


                ///////////////////////////////////////////////////////////////
                // Stop operations to reload new oustanding requests. Used to
                // reboot the cache and continue to fetch the addresses from
                // a new origin
                ///////////////////////////////////////////////////////////////
                RELOAD: begin
                    traps <= 5'b0;
                    mepc_wr <= 1'b0;
                    mstatus_wr <= 1'b0;
                    mcause_wr <= 1'b0;
                    mtval_wr <= 1'b0;
                    arvalid <= 1'b1;
                    flush_fifo <= 1'b0;
                    cfsm <= FETCH;
                end


                ///////////////////////////////////////////////////////////////
                // Launch a cache flush, REQ starts the flush and kept
                // high as long ACK is not asserted.
                ///////////////////////////////////////////////////////////////
                FENCE_I: begin
                    flush_req <= 1'b1;
                    if (flush_ack) begin
                        `ifdef USE_SVL
                        log.info("FENCE.i execution done");
                        `endif
                        flush_req <= 1'b0;
                        flush_fifo <= 1'b0;
                        arvalid <= 1'b1;
                        cfsm <= FETCH;
                    end
                end


                ///////////////////////////////////////////////////////////////
                // Wait for Interrupt (software, timer, external)
                ///////////////////////////////////////////////////////////////
                WFI: begin
                    if (csr_sb[`MSIP] || csr_sb[`MTIP] || csr_sb[`MEIP]) begin
                        `ifdef USE_SVL
                        log.info("WFI -> received an interrupt");
                        `endif
                        arvalid <= 1'b1;
                        mepc_wr <= 1'b1;
                        mepc <= pc_reg;
                        mcause_wr <= 1'b1;
                        mcause <= mcause_code;
                        mtval_wr <= 1'b1;
                        mtval <= mtval_info;
                        cfsm <= FETCH;
                    end
                end


                ///////////////////////////////////////////////////////////////
                // EBREAK completely stops the processor and wait for a reboot
                ///////////////////////////////////////////////////////////////
                EBREAK: begin
                    traps <= 5'b0;
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

    // LUI and AUIPC are executed internally, not in processing
    assign lui_auipc = lui | auipc;

    assign cant_jump = (jal | jalr | branching) && (proc_busy || ~csr_ready);

    assign cant_process = processing & (~proc_ready || ~csr_ready);

    assign cant_lui_auipc = lui_auipc & (proc_busy || ~csr_ready);

    assign cant_sys = |sys & (proc_busy || ~csr_ready);


    ///////////////////////////////////////////////////////////////////////////
    //
    // ISA registers write stage
    //
    ///////////////////////////////////////////////////////////////////////////

    // register source 1 & 2 read
    assign ctrl_rs1_addr = rs1;
    assign ctrl_rs2_addr = rs2;

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            ctrl_rd_wr <= 1'b0;
            ctrl_rd_addr <= 5'b0;
            ctrl_rd_val <= {XLEN{1'b0}};
        end else if (srst) begin
            ctrl_rd_wr <= 1'b0;
            ctrl_rd_addr <= 5'b0;
            ctrl_rd_val <= {XLEN{1'b0}};
        end else begin
            ctrl_rd_wr <=  (cfsm!=FETCH)                                ? 1'b0 :
                           (pull_inst && (auipc || jal || jalr || lui)) ? 1'b1 :
                                                                          1'b0 ;
            ctrl_rd_addr <= rd;

            ctrl_rd_val <= ((jal || jalr) && ~pull_inst) ? pc_jal_saved :
                           ((jal || jalr) && pull_inst)  ? pc_plus4 :
                           (lui)                         ? {imm20, 12'b0} :
                           (auipc && ~pull_inst)         ? pc_auipc_saved :
                           (auipc && pull_inst)          ? pc_auipc :
                                                           pc;
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    //
    // Prepare CSR registers content to use or modify
    //
    ///////////////////////////////////////////////////////////////////////////

    // MSTATUS CSR to write when executing MRET
    assign mstatus_for_mret = {sb_mstatus[XLEN-1:12],  // WPRI
                               priv_mode,              // MPP
                               sb_mstatus[10:9],       // WPRI
                               1'b0,                   // SPP
                               1'b0,                   // MPIE
                               sb_mstatus[6],          // WPRI
                               1'b0,                   // SPIE
                               1'b0,                   // UPIE
                               sb_mstatus[7],          // MIE
                               sb_mstatus[2],          // WPRI
                               1'b0,                   // SIE
                               1'b0};                  // UIE

    // MSTATUS CSR when handling a trap
    assign mstatus_for_trap = {sb_mstatus[XLEN-1:12],  // WPRI
                               priv_mode,              // MPP
                               sb_mstatus[10:9],       // WPRI
                               1'b0,                   // SPP
                               sb_mstatus[3],          // MPIE
                               sb_mstatus[6],          // WPRI
                               1'b0,                   // SPIE
                               1'b0,                   // UPIE
                               1'b0,                   // MIE
                               sb_mstatus[2],          // WPRI
                               1'b0,                   // SIE
                               1'b0};                  // UIE

    // MTVEC computation:
    assign mtvec = (async_trap_occuring && sb_mtvec[1:0]!=2'b0) ?
                        // Vectored mode
                        {sb_mtvec[XLEN-1:2], 2'b0} + (mcause_code << 2) :
                        // Direct mode
                        {sb_mtvec[XLEN-1:2], 2'b0} ;


    ///////////////////////////////////////////////////////////////////////////
    // Mcause CSR management, indicating to software the trap in
    // machine-mode
    ///////////////////////////////////////////////////////////////////////////

    // The instruction tries to modify a read-only register
    assign csr_ro_wr = (csr[11:10]==2'b11 &&
                           // only rs1=x0 and these opcodes can be legal, else
                           // it modifies the targeted CSR
                           ((rs1!=5'b0 &&
                               (funct3==`CSRRS || funct3==`CSRRC ||
                               funct3==`CSRRSI || funct3==`CSRRCI)) &&
                           // Any RW opcode is illegal
                           (funct3==`CSRRW && funct3==`CSRRWI))
                       ) ? 1'b1 : 1'b0;

    // PC is not aligned with XLEN boundary
    assign inst_addr_misaligned = (pc[1:0]!=2'b0) ? jump_branch : 1'b0;

    // TODO: Support correctly TW with prividge mode
    // When TW=1, if WFI is executed in any less-privileged mode, and it
    // does not complete within an implementation-specific, bounded time
    // limit, the WFI instruction causes an illegal instruction exception
    assign wfi_not_allowed = 1'b0;
    // assign wfi_not_allowed = (sys[`IS_WFI] && sb_mstatus[21]) ? 1'b1 : 1'b0;

    assign load_misaligned = proc_exceptions[`LD_MA];
    assign store_misaligned = proc_exceptions[`ST_MA];

    ///////////////////////////////////////////////////////////////////////////
    //
    // Asynchronous exceptions code:
    // ---------------------------
    //
    // Exception Code  |   Description
    // ----------------|------------------------------------------
    // 0               |   User software interrupt
    // 1               |   Supervisor software interrupt
    // 2               |   Reserved for future standard use
    // 3               |   Machine software interrupt
    // -----------------------------------------------------------
    // 4               |   User timer interrupt
    // 5               |   Supervisor timer interrupt
    // 6               |   Reserved for future standard use
    // 7               |   Machine timer interrupt
    // -----------------------------------------------------------
    // 8               |   User external interrupt
    // 9               |   Supervisor external interrupt
    // 10              |   Reserved for future standard use
    // 11              |   Machine external interrupt
    // -----------------------------------------------------------
    // 12-15           |   Reserved for future standard use
    // ≥16             |   Reserved for platform use
    // -----------------------------------------------------------
    //
    // Synchronous exception priority in decreasing priority order:
    // -----------------------------------------------------------
    //
    // Priority  |  Exception Code  |   Description
    // ----------|------------------|------------------------------------------
    // Highest   |  3               |   Instruction address breakpoint
    // ------------------------------------------------------------------------
    //           |  12              |   Instruction page fault
    // ------------------------------------------------------------------------
    //           |  1               |   Instruction access fault
    // ------------------------------------------------------------------------
    //           |  2               |   Illegal instruction
    //           |  0               |   Instruction address misaligned
    //           |  8,9,11          |   Environment call (U/S/M modes)
    //           |  3               |   Environment break
    //           |  3               |   Load/Store/AMO address breakpoint
    // ------------------------------------------------------------------------
    //           |  6               |   Store/AMO address misaligned
    //           |  4               |   Load address misaligned
    // ------------------------------------------------------------------------
    //           |  15              |   Store/AMO page fault
    //           |  13              |   Load page fault
    // ------------------------------------------------------------------------
    // Lowest    |  7               |   Store/AMO access fault
    //           |  5               |   Load access fault
    // ------------------------------------------------------------------------
    //
    ///////////////////////////////////////////////////////////////////////////

    // MCAUSE switching logic based on above listed priorities
    assign mcause_code = // aync exceptions have highest priority
                         (csr_sb[`MSIP])        ? {1'b1, {XLEN-5{1'b0}}, 4'h3} :
                         (csr_sb[`MTIP])        ? {1'b1, {XLEN-5{1'b0}}, 4'h7} :
                         (csr_sb[`MEIP])        ? {1'b1, {XLEN-5{1'b0}}, 4'hB} :
                         // then follow sync exceptions
                         (inst_addr_misaligned) ? {XLEN{1'b0}} :
                         (csr_ro_wr)            ? {{XLEN-4{1'b0}}, 4'h1} :
                         (dec_error)            ? {{XLEN-4{1'b0}}, 4'h2} :
                         (sys[`IS_ECALL])       ? {{XLEN-4{1'b0}}, 4'hB} :
                         (sys[`IS_EBREAK])      ? {{XLEN-4{1'b0}}, 4'h3} :
                         (store_misaligned)     ? {{XLEN-4{1'b0}}, 4'h6} :
                         (load_misaligned)      ? {{XLEN-4{1'b0}}, 4'h4} :
                                                  {XLEN{1'b0}};

    // MTVAL: exception-specific information
    assign mtval_info = (dec_error)            ? instruction :
                        (wfi_not_allowed)      ? instruction :
                        (inst_addr_misaligned) ? pc_reg      :
                        (sys[`IS_ECALL])       ? pc_reg      :
                        (sys[`IS_EBREAK])      ? pc_reg      :
                                                 {XLEN{1'b0}};

    // Trigger the trap handling execution in main FSM

    assign async_trap_occuring = sb_mstatus[3] & (
                                   csr_sb[`MSIP] |
                                   csr_sb[`MTIP] |
                                   csr_sb[`MEIP] );

    assign sync_trap_occuring = csr_ro_wr |
                                inst_addr_misaligned |
                                load_misaligned |
                                store_misaligned |
                                dec_error;

    assign trap_occuring = async_trap_occuring | sync_trap_occuring;

endmodule

`resetall
