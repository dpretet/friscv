// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"
`include "friscv_control_h.sv"

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
        // Support hypervisor mode
        parameter HYPERVISOR_MODE = 0,
        // Support supervisor mode
        parameter SUPERVISOR_MODE = 0,
        // Support user mode
        parameter USER_MODE = 0,
        // PMP / PMA supported
        parameter MPU_SUPPORT = 0,
        // Address bus width defined for both control and AXI4 address signals
        parameter AXI_ADDR_W = ILEN,
        // AXI ID width, setup by default to 8 and unused
        parameter AXI_ID_W = 8,
        // Maximum range used when generating an AXI ID
        parameter MAX_ID_RANGE = 8,
        // ID used to identify the dta abus in the infrastructure
        parameter AXI_ID_MASK = 'h10,
        // AXI4 data width, independant of control unit width
        parameter AXI_DATA_W = XLEN,
        // Number of outstanding requests supported
        parameter OSTDREQ_NUM = 4,
        // Primary address to boot to load the firmware
        parameter BOOT_ADDR = 0
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        input  wire                       cache_ready,
        // Debug interface
        output logic [5             -1:0] status,
        output logic [XLEN          -1:0] pc_val,
        // Flush control to clear outstanding request in buffers
        output logic                      flush_reqs,
        // Flush control to execute FENCE.i
        output logic                      flush_blocks,
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
        input  wire  [`PROC_EXP_W   -1:0] proc_exceptions,
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
        // PMP / PMA Check
        output logic [AXI_ADDR_W    -1:0] mpu_addr,
        input  wire  [4             -1:0] mpu_allow,
        // CSR shared bus
        input  wire  [`CSR_SB_W     -1:0] csr_sb,
        output logic [`CTRL_SB_W    -1:0] ctrl_sb
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declarations
    //
    ///////////////////////////////////////////////////////////////////////////

    localparam MAX_ID = AXI_ID_MASK + MAX_ID_RANGE - 1;

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
    logic             inst_dec_error;
    logic             inst_ready;

    // Control fsm
    typedef enum logic[3:0] {
        BOOT    = 0,
        FETCH   = 1,
        RELOAD  = 2,
        FENCE   = 3,
        FENCE_I = 4,
        WFI     = 5,
        EBREAK  = 6
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
    logic                   cant_trap;
    logic                   cant_process;
    logic                   cant_lui_auipc;
    logic                   cant_sys;
    logic                   regs_rsvd;
    // FIFO signals
    logic [ILEN       -1:0] instruction;
    logic                   flush_pipe;
    logic                   push_inst;
    logic                   fifo_full;
    logic                   pull_inst;
    logic                   fifo_empty;
    logic [XLEN       -1:0] mtvec;

    // Shared bus signals
    logic [XLEN       -1:0] sb_mepc;
    logic [XLEN       -1:0] sb_mtvec;
    logic [XLEN       -1:0] sb_mstatus;
    logic                   sb_mie;
    logic                   sb_mtip;
    logic                   sb_msip;
    logic                   sb_meip;
    logic                   mepc_wr;
    logic [XLEN       -1:0] mepc;
    logic                   mstatus_wr;
    logic [XLEN       -1:0] mstatus;
    logic                   mcause_wr;
    logic [XLEN       -1:0] mcause;
    logic                   mtval_wr;
    logic [XLEN       -1:0] mtval;
    logic [64         -1:0] instret;
    logic                   clr_meip;

    logic [XLEN       -1:0] mstatus_for_mret;
    logic [XLEN       -1:0] mstatus_for_trap;
    logic                   csr_ro_wr;
    logic                   inst_addr_misaligned;
    logic [XLEN       -1:0] mcause_code;
    logic [XLEN       -1:0] mtval_info;
    logic                   load_misaligned;
    logic                   store_misaligned;
    logic                   inst_access_fault;
    logic                   illegal_instruction;
    logic                   wfi_tw;
    logic                   trap_occuring;
    logic                   sync_trap_occuring;
    logic                   async_trap_occuring;
    logic                   ecall_umode;
    logic                   ecall_mmode;
    logic [2          -1:0] priv_mode;
    logic                   load_access_fault;
    logic                   store_access_fault;

    logic [`EXP_INST_W-1:0] exp_inst;
    logic [`EXP_ADDR_W-1:0] exp_addr;
    logic [`EXP_PC_W  -1:0] exp_pc;

    // Logger setup
    `ifdef USE_SVL
    `include "svlogger.sv"
    svlogger log;
    initial log = new("ControlUnit",
                      `CONTROL_VERBOSITY,
                      `CONTROL_ROUTE);
    `endif

    `ifdef TRACE_CONTROL
    integer f;
    initial f = $fopen("trace_control.csv","w");
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
    `ifdef USE_SVL
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
        else if (cause=='h80000003)  get_mcause_desc = "Machine Software Interrupt";
        else if (cause=='h80000007)  get_mcause_desc = "Machine Timer Interrupt";
        else if (cause=='h8000000B)  get_mcause_desc = "Machine External Interrupt";
        // All other unknown interrupts
        else get_mcause_desc = "Unknown Trap Cause";
    endfunction
    `endif


    /////////////////////////////////////////////////////////////////////
    // Print function used when the FSM is handling a trap
    /////////////////////////////////////////////////////////////////////
    `ifdef USE_SVL
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
    `endif


    //////////////////////////////////////////////////////////////////////
    // Return next ID for program counter increment during address jump
    //////////////////////////////////////////////////////////////////////
    function automatic logic [AXI_ID_W-1:0] next_id(
        input logic  [AXI_ID_W-1:0] id,
        input logic  [AXI_ID_W-1:0] max_id,
        input logic  [AXI_ID_W-1:0] init_id
    );
        if (id==max_id) next_id = init_id;
        else next_id = id + 1'b1;
    endfunction


    ///////////////////////////////////////////////////////////////////////////
    // CSR Shared bus extraction
    ///////////////////////////////////////////////////////////////////////////

    assign sb_mtvec   = csr_sb[`CSR_SB_MTVEC   +: XLEN];
    assign sb_mstatus = csr_sb[`CSR_SB_MSTATUS +: XLEN];
    assign sb_mepc    = csr_sb[`CSR_SB_MEPC    +: XLEN];
    assign sb_mie     = csr_sb[`CSR_SB_MIE];
    assign sb_meip    = csr_sb[`CSR_SB_MEIP];
    assign sb_mtip    = csr_sb[`CSR_SB_MTIP];
    assign sb_msip    = csr_sb[`CSR_SB_MSIP];

    assign ctrl_sb = {instret, clr_meip, 
                      mtval_wr, mtval,
                      mcause_wr, mcause,
                      mstatus_wr, mstatus,
                      mepc_wr, mepc};


    ///////////////////////////////////////////////////////////////////////////
    // Input stage 
    ///////////////////////////////////////////////////////////////////////////

    assign push_inst = rvalid & (arid == rid);

    generate
    ///////////////////////////////////////////////////////////////////////////
    // Load/Buffer Stage, a SC-FIFO storing the incoming instructions.
    // This FIFO is controlled by the FSM issuing read request and can be
    // flushed in case branching or jumping is required.
    ///////////////////////////////////////////////////////////////////////////
    if (OSTDREQ_NUM > 0) begin: INST_FIFO

        assign rready = !fifo_full;

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
            .flush    (flush_pipe | flush_blocks),
            .data_in  (rdata),
            .push     (push_inst),
            .full     (fifo_full),
            .afull    (),
            .data_out (instruction),
            .pull     (pull_inst),
            .empty    (fifo_empty),
            .aempty   ()
        );

        assign inst_ready = !fifo_empty & !flush_pipe;

    ///////////////////////////////////////////////////////////////////////////
    // No input FIFO, the read data channel feeds directly the controller
    ///////////////////////////////////////////////////////////////////////////
    end else begin : INST_PATH

        assign instruction = rdata;
        assign inst_ready = push_inst;
        assign rready = pull_inst;

        assign fifo_full = 1'b0;
        assign fifo_empty = 1'b0;

    end
    endgenerate

    assign pull_inst = (!cant_jump && !cant_process && !cant_lui_auipc && !cant_sys &&
                        (cfsm==FETCH) && !trap_occuring) ? 1'b1 : 1'b0;

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
    // the processing and the CSR modules
    //
    ///////////////////////////////////////////////////////////////////////////

    assign proc_valid = inst_ready & processing & (cfsm==FETCH) & csr_ready;

    assign csr_en = inst_ready && sys[`IS_CSR] & (cfsm==FETCH) & !proc_busy;

    assign proc_instbus[`OPCODE   +: `OPCODE_W ] = opcode;
    assign proc_instbus[`FUNCT3   +: `FUNCT3_W ] = funct3;
    assign proc_instbus[`FUNCT7   +: `FUNCT7_W ] = funct7;
    assign proc_instbus[`RS1      +: `RS1_W    ] = rs1   ;
    assign proc_instbus[`RS2      +: `RS2_W    ] = rs2   ;
    assign proc_instbus[`RD       +: `RD_W     ] = rd    ;
    assign proc_instbus[`ZIMM     +: `ZIMM_W   ] = zimm  ;
    assign proc_instbus[`IMM12    +: `IMM12_W  ] = imm12 ;
    assign proc_instbus[`IMM20    +: `IMM20_W  ] = imm20 ;
    assign proc_instbus[`CSR      +: `CSR_W    ] = csr   ;
    assign proc_instbus[`SHAMT    +: `SHAMT_W  ] = shamt ;
    assign proc_instbus[`INST     +: `INST_W   ] = instruction;
    assign proc_instbus[`PC       +: `PC_W     ] = pc_reg;

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
    assign pc_branching = $signed(pc_reg) + $signed({{19{imm12[11]}}, imm12, 1'b0});

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

    assign mpu_addr = pc_reg;

    assign flush_reqs = flush_pipe;

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            cfsm <= BOOT;
            arvalid <= 1'b0;
            araddr <= {AXI_ADDR_W{1'b0}};
            pc_reg <= {(XLEN){1'b0}};
            pc_jal_saved <= {(XLEN){1'b0}};
            pc_auipc_saved <= {(XLEN){1'b0}};
            status <= 5'b0;
            arid <= {AXI_ID_W{1'b0}};
            flush_blocks <= 1'b0;
            flush_pipe <= 1'b0;
            priv_mode <= `MMODE;
        end else if (srst == 1'b1) begin
            cfsm <= BOOT;
            arvalid <= 1'b0;
            araddr <= {AXI_ADDR_W{1'b0}};
            pc_reg <= {(XLEN){1'b0}};
            pc_jal_saved <= {(XLEN){1'b0}};
            pc_auipc_saved <= {(XLEN){1'b0}};
            status <= 5'b0;
            arid <= {AXI_ID_W{1'b0}};
            flush_blocks <= 1'b0;
            flush_pipe <= 1'b0;
            priv_mode <= `MMODE;
        end else begin

            case (cfsm)

                ///////////////////////////////////////////////////////////////
                // Start to boot the RAM after reset.
                ///////////////////////////////////////////////////////////////
                default: begin

                    priv_mode <= `MMODE;
                    arid <= AXI_ID_MASK;
                    araddr <= BOOT_ADDR;
                    pc_reg <= BOOT_ADDR;

                    // 2. Once flushed, boot the processor
                    if (cache_ready) begin
                        arvalid <= 1'b1;
                        `ifdef TRACE_CONTROL
                        $fwrite(f, "@ %0t,%x\n", $realtime, BOOT_ADDR);
                        `endif
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

                    ///////////////////////////////////////////////////////////
                    // Manages read outstanding requests to fetch
                    // new instruction from memory:
                    ///////////////////////////////////////////////////////////

                    //
                    //   - ECALL / MRET / JALR / Any branching
                    //
                    if (inst_ready && !proc_busy &&
                        (jump_branch || sys[`IS_ECALL] || sys[`IS_MRET] || trap_occuring))
                    begin

                        // Get a new ID for the new batch
                        arid <= next_id(arid, MAX_ID, AXI_ID_MASK);

                        // ECALL / Trap handling
                        if (sys[`IS_ECALL] || trap_occuring) araddr <= mtvec;
                        // MRET
                        else if (sys[`IS_MRET]) araddr <= sb_mepc;
                        // jalr / branch
                        else araddr <= pc;

                    //
                    // JAL
                    //
                    end else if (inst_ready && jal) begin

                        // Get a new ID for the new batch
                        arid <= next_id(arid, MAX_ID, AXI_ID_MASK);
                        araddr <= pc;

                    //
                    //   - FENCE.i execution
                    //
                    end else if (inst_ready && fence[`IS_FENCEI]) begin
                        // Get a new ID for the new batch
                        arid <= next_id(arid, MAX_ID, AXI_ID_MASK);
                        araddr <= pc;

                    //
                    //   - else continue to simply increment by ILEN
                    //
                    end else if (arready) begin
                        araddr <= araddr + ILEN/8;
                    end
                    ///////////////////////////////////////////////////////////

                    flush_pipe <= 1'b0;

                    ///////////////////////////////////////////////////////////
                    // Manages the PC vs the different instructions to execute
                    if (inst_ready) begin

                        // Need to branch/process but ALU/memfy/CSR didn't finish
                        // to execute last instruction, so store PCs.
                        if (cant_jump || cant_process || cant_lui_auipc || cant_sys) begin
                            pc_jal_saved <= pc_plus4;
                            pc_auipc_saved <= pc_reg;
                        end

                        // Move to the trap handling when received an
                        // interrupt, a wrong instruction, ...
                        if (trap_occuring) begin

                            if (!cant_trap) begin
                                `ifdef USE_SVL
                                print_mcause("Handling a trap -> MCAUSE=0x", mcause_code);
                                print_instruction;
                                `endif
                                status[3] <= 1'b1;
                                flush_pipe <= 1'b1;
                                if (USER_MODE) priv_mode <= `MMODE;
                                pc_reg <= mtvec;
                            end

                        // Needs to jump or branch thus stop the pipeline
                        // and reload new instructions
                        end else if (jalr | branching) begin

                            if (!cant_jump) begin
                                print_instruction;
                                pc_reg <= pc;
                            end

                            if (jump_branch && !cant_jump) begin
                                `ifdef USE_SVL
                                if (jalr) log.info("JALR");
                                else      log.info("Branching");
                                `endif
                            end

                            if (jump_branch && !cant_jump) begin
                                flush_pipe <= 1'b1;
                            end

                        end else if (jal) begin

                            `ifdef USE_SVL
                                log.info("JAL");
                            `endif

                            print_instruction;
                            pc_reg <= pc;
                            flush_pipe <= 1'b1;

                        // Any sys instruction:
                        // - ECALL (0) / EBREAK (1) / CSR (2) / MRET (3) / SRET (4) / WFI (5)
                        end else if (|sys || |fence) begin

                            // Reach an ECALL instruction, jump to trap handler
                            if (sys[`IS_ECALL] && !proc_busy && csr_ready) begin
                                `ifdef USE_SVL
                                print_instruction;
                                log.info("ECALL -> Jump to trap handler");
                                `endif
                                status[0] <= 1'b1;
                                flush_pipe <= 1'b1;
                                pc_reg <= mtvec;
                                if (USER_MODE) priv_mode <= `MMODE;

                            // Reach an EBREAK instruction, need to stall the core
                            end else if (sys[`IS_EBREAK]) begin
                                `ifdef USE_SVL
                                print_instruction;
                                log.info("EBREAK -> Stop the processor");
                                `endif
                                status[1] <= 1'b1;
                                arvalid <= 1'b0;
                                cfsm <= EBREAK;

                            // Reach a MRET instruction, jump to exception return
                            end else if (sys[`IS_MRET] && !proc_busy && csr_ready) begin
                                `ifdef USE_SVL
                                print_instruction;
                                log.info("MRET -> Machine Return");
                                `endif
                                status[2] <= 1'b1;
                                flush_pipe <= 1'b1;
                                pc_reg <= sb_mepc;
                                if (USER_MODE) priv_mode <= `UMODE;

                            // Reach a FENCE.i instruction, need to flush the cache
                            // the instruction pipeline
                            end else if (fence[`IS_FENCEI]) begin
                                `ifdef USE_SVL
                                print_instruction;
                                log.info("FENCE.i -> Start iCache flushing");
                                `endif
                                arvalid <= 1'b0;
                                pc_reg <= pc;
                                cfsm <= FENCE_I;

                            // Reach an WFI, wait for an interrupt
                            // TODO: could miss an interrupt if processing is too long
                            end else if (sys[`IS_WFI] && !proc_busy && csr_ready) begin
                                `ifdef USE_SVL
                                print_instruction;
                                log.info("WFI -> Stall and wait for interrupt");
                                `endif
                                status[4] <= 1'b1;
                                flush_pipe <= 1'b1;
                                pc_reg <= mtvec;
                                arvalid <= 1'b0;
                                cfsm <= WFI;

                            // CSR instructions
                            end else if (sys[`IS_CSR] && !cant_sys) begin
                                print_instruction;
                                flush_pipe <= 1'b0;
                                pc_reg <= pc;

                            // FENCE instruction (not supported)
                            end else if (!proc_busy && csr_ready) begin
                                print_instruction;
                                flush_pipe <= 1'b0;
                                pc_reg <= pc;
                            end

                        // LUI and AUIPC execution, done in this module
                        end else if (lui_auipc && !cant_lui_auipc) begin
                            print_instruction;
                            flush_pipe <= 1'b0;
                            pc_reg <= pc;

                        // All other instructions
                        end else if (processing) begin

                            if (!cant_process) begin
                                print_instruction;
                                flush_pipe <= 1'b0;
                                pc_reg <= pc;
                            end
                        end
                    end
                    ///////////////////////////////////////////////////////////
                end


                ///////////////////////////////////////////////////////////////
                // Launch a cache flush, REQ starts the flush and kept
                // high as long ACK is not asserted.
                ///////////////////////////////////////////////////////////////
                FENCE_I: begin
                    flush_blocks <= 1'b1;
                    if (flush_ack) begin
                        `ifdef USE_SVL
                        log.info("FENCE.i execution done");
                        `endif
                        flush_blocks <= 1'b0;
                        flush_pipe <= 1'b0;
                        arvalid <= 1'b1;
                        cfsm <= FETCH;
                    end
                end


                ///////////////////////////////////////////////////////////////
                // Wait for Interrupt (software, timer, external)
                ///////////////////////////////////////////////////////////////
                WFI: begin
                    if (sb_msip || sb_mtip || sb_meip) begin
                        `ifdef USE_SVL
                        print_mcause("WFI -> MCAUSE=0x", mcause_code);
                        `endif
                        status <= 5'b0;
                        flush_pipe <= 1'b1;
                        if (USER_MODE) priv_mode <= `MMODE;
                        arid <= next_id(arid, MAX_ID, AXI_ID_MASK);
                        araddr <= mtvec;
                        pc_reg <= mtvec;
                        arvalid <= 1'b1;
                        cfsm <= FETCH;
                    end
                end


                ///////////////////////////////////////////////////////////////
                // EBREAK completely stops the processor and wait for a reboot
                ///////////////////////////////////////////////////////////////
                EBREAK: begin
                    cfsm <= EBREAK;
                end

            endcase

        end
    end


    // Trace control when jumping/branching for debug purpose
    always @ (posedge aclk) begin
        if (flush_pipe || (cfsm==WFI && (sb_msip || sb_mtip || sb_meip))) begin
            `ifdef TRACE_CONTROL
            $fwrite(f, "@ %0t,%x\n", $realtime, sb_mepc);
            `endif
        end
    end


    // Manage CSRs updates based on current instruction
    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            mepc_wr <= 1'b0;
            mepc <= {XLEN{1'b0}};
            mstatus_wr <= 1'b0;
            mstatus <= {XLEN{1'b0}};
            mcause_wr <= 1'b0;
            mcause <= {XLEN{1'b0}};
            mtval_wr <= 1'b0;
            mtval <= {XLEN{1'b0}};
            clr_meip <= 1'b0;
        end else if (srst == 1'b1) begin
            mepc_wr <= 1'b0;
            mepc <= {XLEN{1'b0}};
            mstatus_wr <= 1'b0;
            mstatus <= {XLEN{1'b0}};
            mcause_wr <= 1'b0;
            mcause <= {XLEN{1'b0}};
            mtval_wr <= 1'b0;
            mtval <= {XLEN{1'b0}};
            clr_meip <= 1'b0;
        end else begin

            if (cfsm==FETCH) begin

                mepc_wr <= 1'b0;
                mstatus_wr <= 1'b0;
                mcause_wr <= 1'b0;
                mtval_wr <= 1'b0;

                if (inst_ready) begin

                    if (trap_occuring && !cant_trap) begin

                        mepc_wr <= 1'b1;
                        mepc <= pc_reg;
                        mcause_wr <= 1'b1;
                        mcause <= mcause_code;
                        mtval_wr <= 1'b1;
                        mtval <= mtval_info;
                        mstatus_wr <= 1'b1;
                        mstatus <= mstatus_for_trap;
                        clr_meip <= (mcause_code == 'h8000000B);

                    end else if (|sys || |fence) begin

                        clr_meip <= 1'b0;

                        // Reach an ECALL instruction, jump to trap handler
                        if (sys[`IS_ECALL] && !proc_busy && csr_ready) begin

                            mepc_wr <= 1'b1;
                            mepc <= pc_reg;
                            mcause_wr <= 1'b1;
                            mcause <= mcause_code;
                            mtval_wr <= 1'b1;
                            mtval <= mtval_info;
                            mstatus_wr <= 1'b1;
                            mstatus <= mstatus_for_trap;

                        // Reach an EBREAK instruction, need to stall the core
                        end else if (sys[`IS_EBREAK]) begin

                            mcause_wr <= 1'b1;
                            mcause <= mcause_code;

                        // Reach a MRET instruction, jump to exception return
                        end else if (sys[`IS_MRET] && !proc_busy && csr_ready) begin

                            mstatus_wr <= 1'b1;
                            mstatus <= mstatus_for_mret;

                        // Reach an WFI, wait for an interrupt
                        end else if (sys[`IS_WFI] && !proc_busy && csr_ready) begin

                            mepc_wr <= 1'b1;
                            mepc <= pc_plus4;
                            mtval_wr <= 1'b1;
                            mtval <= mtval_info;

                        end
                    end
                end else begin
                    clr_meip <= 1'b0;
                    mepc_wr <= 1'b0;
                    mcause_wr <= 1'b0;
                    mstatus_wr <= 1'b0;
                    mtval_wr <= 1'b0;
                end

            end else if (cfsm==WFI && (sb_msip || sb_mtip || sb_meip)) begin

                mcause_wr <= 1'b1;
                mcause <= mcause_code;
                mtval_wr <= 1'b1;
                mtval <= mtval_info;
                mstatus_wr <= 1'b1;
                mstatus <= mstatus_for_trap;
                clr_meip <= (mcause_code == 'h8000000B);

            end else begin
                mepc_wr <= 1'b0;
                mstatus_wr <= 1'b0;
                mcause_wr <= 1'b0;
                mtval_wr <= 1'b0;
                clr_meip <= 1'b0;
            end
        end
    end

    // Access permissions
    // [0] Unprivileged or privileged
    // [1] Secure or Non-secure
    // [2] Instruction or data
    assign arprot = 3'b100;

    // Needs to jump or branch, the request to cache/RAM needs to be restarted
    assign jump_branch = (branching & goto_branch) | jalr;

    // LUI and AUIPC are executed internally, not in processing
    assign lui_auipc = lui | auipc;

    assign cant_jump = (jalr | branching) && (proc_busy | !csr_ready);

    assign cant_process = processing & (!proc_ready | !csr_ready);

    assign cant_lui_auipc = lui_auipc & (proc_busy | !csr_ready);

    assign cant_sys = |sys & (proc_busy | !csr_ready);

    assign cant_trap = (proc_busy | !csr_ready);


    ///////////////////////////////////////////////////////////////////////////
    //
    // ISA registers write stage
    //
    //(inst_access_fault)    ? exp_pc      :
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
            ctrl_rd_wr <=  (cfsm!=FETCH)                                              ? 1'b0 :
                           (pull_inst && inst_ready && (auipc || jal || jalr || lui)) ? 1'b1 :
                                                                                        1'b0 ;
            ctrl_rd_addr <= rd;

            ctrl_rd_val <= ((jal || jalr) && !pull_inst) ? pc_jal_saved :
                           ((jal || jalr) &&  pull_inst) ? pc_plus4 :
                           (lui)                         ? {imm20, 12'b0} :
                           (auipc && !pull_inst)         ? pc_auipc_saved :
                           (auipc &&  pull_inst)         ? pc_auipc :
                                                           pc;
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    //
    // Prepare CSR registers content to use or modify
    //
    ///////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            instret <= {64{1'b0}};
        end else if (srst) begin
            instret <= {64{1'b0}};
        end else begin
            if (inst_ready && pull_inst)
                instret <= instret + 1;
        end
    end


    // MSTATUS CSR to write when executing MRET
    assign mstatus_for_mret = {sb_mstatus[XLEN-1:23],  // WPRI
                               sb_mstatus[22],         // TSR
                               sb_mstatus[21],         // TW
                               sb_mstatus[20],         // TVM
                               sb_mstatus[19],         // MXR
                               sb_mstatus[18],         // SUM
                               sb_mstatus[17],         // MPRV
                               2'b0,                   // XS
                               sb_mstatus[14:13],      // FS
                               priv_mode,              // MPP
                               sb_mstatus[10:9],       // VS
                               1'b0,                   // SPP
                               1'b0,                   // MPIE
                               1'b0,                   // UBE
                               1'b0,                   // SPIE
                               1'b0,                   // WPRI
                               sb_mstatus[7],          // MIE
                               1'b0,                   // WPRI
                               sb_mstatus[5],          // SIE
                               1'b0};                  // WPRI

    // MSTATUS CSR when handling a trap
    assign mstatus_for_trap = {sb_mstatus[XLEN-1:23],  // WPRI
                               sb_mstatus[22],         // TSR
                               sb_mstatus[21],         // TW
                               sb_mstatus[20],         // TVM
                               sb_mstatus[19],         // MXR
                               sb_mstatus[18],         // SUM
                               sb_mstatus[17],         // MPRV
                               2'b0,                   // XS
                               sb_mstatus[14:13],      // FS
                               priv_mode,              // MPP
                               sb_mstatus[10:9],       // VS
                               1'b0,                   // SPP
                               sb_mstatus[3],          // MPIE
                               1'b0,                   // UBE
                               sb_mstatus[1],          // SPIE
                               1'b0,                   // WPRI
                               1'b0,                   // MIE
                               1'b0,                   // WPRI
                               1'b0,                   // SIE
                               1'b0};                  // WPRI

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

    // TODO: Support correctly TW with privilege mode
    // When TW=0, the WFI instruction may execute in lower privilege modes when not prevented for some
    // other reason. When TW=1, then if WFI is executed in any less-privileged mode, and it does not
    // complete within an implementation-specific, bounded time limit, the WFI instruction causes an
    // illegal instruction exception. An implementation may have WFI always raise an illegal instruction
    // exception in less-privileged modes when TW=1, even if there are pending globally-disabled interrupts
    // when the instruction is executed. TW is read-only 0 when there are no modes less privileged than M.
    assign wfi_tw = 1'b0;

    assign inst_dec_error = dec_error & (cfsm==FETCH) & inst_ready;

    assign inst_access_fault = (!mpu_allow[`PMA_X] | !mpu_allow[`PMA_R]) & (priv_mode == `UMODE);

    assign load_misaligned = proc_exceptions[`LDMA];

    assign store_misaligned = proc_exceptions[`STMA];

    assign load_access_fault = proc_exceptions[`LAF];

    assign store_access_fault = proc_exceptions[`SAF];

    assign exp_pc = proc_exceptions[`EXP_PC +: `EXP_PC_W];

    assign exp_inst = proc_exceptions[`EXP_INST +: `EXP_INST_W];

    assign exp_addr = proc_exceptions[`EXP_ADDR +: `EXP_ADDR_W];

    generate
    if (USER_MODE) begin: UMODE_EXPEC
        assign illegal_instruction = (priv_mode==`MMODE)                 ? '0         :
                                     (sys[`IS_MRET])                     ? inst_ready :
                                     (sys[`IS_CSR] && csr[9:8] != 2'b00) ? inst_ready :
                                                                           '0;
    end else begin : NO_UMODE
        assign illegal_instruction = '0;
    end
    endgenerate

    assign ecall_umode = (sys[`IS_ECALL] && priv_mode==`UMODE);
    assign ecall_mmode = (sys[`IS_ECALL] && priv_mode==`MMODE);

    ///////////////////////////////////////////////////////////////////////////
    //
    // Asynchronous exceptions code:
    // ----------------------------
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
    //           |  1               |   Instruction access fault
    // ------------------------------------------------------------------------
    //           |  2               |   Illegal instruction
    //           |  0               |   Instruction address misaligned
    //           |  8,9,11          |   Environment call from U/S/M modes
    //           |  3               |   Environment break
    //           |  3               |   Load/Store/AMO address breakpoint
    // ------------------------------------------------------------------------
    //           |  5               |   Load access fault
    //           |  7               |   Store access fault
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
                         (sb_msip)              ? {1'b1, {XLEN-5{1'b0}}, 4'h3} :
                         (sb_mtip)              ? {1'b1, {XLEN-5{1'b0}}, 4'h7} :
                         (sb_meip)              ? {1'b1, {XLEN-5{1'b0}}, 4'hB} :
                         // then follow sync exceptions
                         (inst_access_fault)    ? {{XLEN-4{1'b0}}, 4'h1}  :
                         (illegal_instruction)  ? {{XLEN-4{1'b0}}, 4'h2}  :
                         (csr_ro_wr)            ? {{XLEN-4{1'b0}}, 4'h2}  :
                         (inst_addr_misaligned) ? '0                      :
                         (ecall_umode)          ? {{XLEN-4{1'b0}}, 4'h8}  :
                         (ecall_mmode)          ? {{XLEN-4{1'b0}}, 4'hB}  :
                         (sys[`IS_EBREAK])      ? {{XLEN-4{1'b0}}, 4'h3}  :
                         (load_access_fault)    ? {{XLEN-4{1'b0}}, 4'h5}  :
                         (store_access_fault)   ? {{XLEN-4{1'b0}}, 4'h7}  :
                         (load_misaligned)      ? {{XLEN-4{1'b0}}, 4'h4}  :
                         (store_misaligned)     ? {{XLEN-4{1'b0}}, 4'h6}  :
                         (inst_dec_error)       ? {{XLEN-5{1'b0}}, 5'h18} :
                                                  '0;

    // MTVAL: exception-specific information
    assign mtval_info = (inst_access_fault)    ? instruction :
                        (illegal_instruction)  ? instruction :
                        (csr_ro_wr)            ? instruction :
                        (inst_addr_misaligned) ? pc_reg      :
                        (sys[`IS_ECALL])       ? pc_reg      :
                        (sys[`IS_EBREAK])      ? pc_reg      :
                        (load_access_fault)    ? exp_addr    :
                        (store_access_fault)   ? exp_addr    :
                        (load_misaligned)      ? exp_addr    :
                        (store_misaligned )    ? exp_addr    :
                        (inst_dec_error)       ? instruction :
                                                 '0;

    // Trigger the trap handling execution in main FSM

    assign async_trap_occuring = (sb_mtip | sb_msip | sb_meip ) & sb_mie;

    assign sync_trap_occuring = csr_ro_wr            |
                                inst_addr_misaligned |
                                load_misaligned      |
                                illegal_instruction  |
                                store_misaligned     |
                                inst_access_fault    |
                                load_access_fault    |
                                store_access_fault   |
                                inst_dec_error       ;

    assign trap_occuring = async_trap_occuring | sync_trap_occuring;

endmodule

`resetall
