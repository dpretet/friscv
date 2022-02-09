// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module friscv_registers

    #(
        // Architecture selection:
        // 32 or 64 bits support
        parameter XLEN = 32,
        // Reduced RV32 arch
        parameter RV32E = 0,
        parameter SYNC_READ = 0,
        // Number of extension supported in processing unit
        parameter NB_ALU_UNIT = 2
    )(
        // clock and resets
        input  wire                             aclk,
        input  wire                             aresetn,
        input  wire                             srst,
        `ifdef FRISCV_SIM
        output logic                            error,
        `endif
        // Control interface
        input  wire  [5                   -1:0] ctrl_rs1_addr,
        output logic [XLEN                -1:0] ctrl_rs1_val,
        input  wire  [5                   -1:0] ctrl_rs2_addr,
        output logic [XLEN                -1:0] ctrl_rs2_val,
        input  wire                             ctrl_rd_wr,
        input  wire  [5                   -1:0] ctrl_rd_addr,
        input  wire  [XLEN                -1:0] ctrl_rd_val,
        // Processing interface
        input  wire  [NB_ALU_UNIT*5       -1:0] proc_rs1_addr,
        output logic [NB_ALU_UNIT*XLEN    -1:0] proc_rs1_val,
        input  wire  [NB_ALU_UNIT*5       -1:0] proc_rs2_addr,
        output logic [NB_ALU_UNIT*XLEN    -1:0] proc_rs2_val,
        input  wire  [NB_ALU_UNIT         -1:0] proc_rd_wr,
        input  wire  [NB_ALU_UNIT*5       -1:0] proc_rd_addr,
        input  wire  [NB_ALU_UNIT*XLEN    -1:0] proc_rd_val,
        input  wire  [NB_ALU_UNIT*XLEN/8  -1:0] proc_rd_strb,
        // CSR interface
        input  wire  [5                   -1:0] csr_rs1_addr,
        output logic [XLEN                -1:0] csr_rs1_val,
        input  wire                             csr_rd_wr,
        input  wire  [5                   -1:0] csr_rd_addr,
        input  wire  [XLEN                -1:0] csr_rd_val
    );

    // E extension limiting the register number to 16
    localparam REGNUM = (RV32E) ? 16 : 32;

    // ISA registers 0-31
    logic [XLEN-1:0] regs [REGNUM-1:0];


    generate

    genvar i;
    integer u, s;

    for (i=0; i<REGNUM; i++) begin: RegisterFFD

        logic [XLEN-1:0] _reg;

        // Registers content saving
        always @ (posedge aclk or negedge aresetn) begin
            if (aresetn == 1'b0) begin
                _reg <= {XLEN{1'b0}};
            end else if (srst) begin
                _reg <= {XLEN{1'b0}};
            end else begin
                // register 0 is always 0, can't be overwritten
                if (i==0) _reg <= {XLEN{1'b0}};
                else _reg <= regs[i];
            end
        end

        // registers' write circuit
        always @ (*) begin: RegisterWrite

            regs[i] = _reg;

            if (i!=0) begin

                // Access from central controller
                if (ctrl_rd_wr && ctrl_rd_addr==i) begin
                    regs[i] = ctrl_rd_val;

                // Access from CSR manager
                end else if (csr_rd_wr && csr_rd_addr==i) begin
                    regs[i] = csr_rd_val;

                // Access from data memory controller
                end else if (|proc_rd_wr) begin
                    for (u=0;u<NB_ALU_UNIT;u=u+1) begin
                        if (proc_rd_wr[u] && proc_rd_addr[u*5+:5]==i) begin
                            for (s=0;s<(XLEN/8);s=s+1) begin
                                if (proc_rd_strb[u*XLEN/8+s]) begin
                                    regs[i][s*8+:8] = proc_rd_val[u*XLEN+s*8+:8];
                                end
                            end
                        end
                    end
                end
            end
        end

    end
    endgenerate

    generate

    if (SYNC_READ==0) begin: COMB_READ

        assign ctrl_rs1_val = regs[ctrl_rs1_addr];
        assign ctrl_rs2_val = regs[ctrl_rs2_addr];
        assign csr_rs1_val = regs[csr_rs1_addr];

        for (genvar u=0;u<NB_ALU_UNIT;u=u+1) begin: PROCESSING_COMB_REG_IFS
            assign proc_rs1_val[u*XLEN+:XLEN] = regs[proc_rs1_addr[u*5+:5]];
            assign proc_rs2_val[u*XLEN+:XLEN] = regs[proc_rs2_addr[u*5+:5]];
        end

    end else begin: SYNCHRO_READ

        always @ (negedge aclk or negedge aresetn) begin
            if (aresetn == 1'b0) begin
                ctrl_rs1_val <= {XLEN{1'b0}};
                ctrl_rs2_val <= {XLEN{1'b0}};
                csr_rs1_val <= {XLEN{1'b0}};
                for (u=0;u<NB_ALU_UNIT;u=u+1) begin: PROCESING_ARESETN_REG_IFS
                    proc_rs1_val[u*XLEN+:XLEN] <= {XLEN{1'b0}};
                    proc_rs2_val[u*XLEN+:XLEN] <= {XLEN{1'b0}};
                end
            end else if (srst) begin
                ctrl_rs1_val <= {XLEN{1'b0}};
                ctrl_rs2_val <= {XLEN{1'b0}};
                csr_rs1_val <= {XLEN{1'b0}};
                for (u=0;u<NB_ALU_UNIT;u=u+1) begin: PROCESING_SRST_REG_IFS
                    proc_rs1_val[u*XLEN+:XLEN] <= {XLEN{1'b0}};
                    proc_rs2_val[u*XLEN+:XLEN] <= {XLEN{1'b0}};
                end
            end else begin
                ctrl_rs1_val <= regs[ctrl_rs1_addr];
                ctrl_rs2_val <= regs[ctrl_rs2_addr];
                csr_rs1_val <= regs[csr_rs1_addr];
                for (u=0;u<NB_ALU_UNIT;u=u+1) begin: PROCESING_SYNC_REG_IFS
                    proc_rs1_val[u*XLEN+:XLEN] <= regs[proc_rs1_addr[u*5+:5]];
                    proc_rs2_val[u*XLEN+:XLEN] <= regs[proc_rs2_addr[u*5+:5]];
                end
            end
        end

    end
    endgenerate

    `ifdef FRISCV_SIM

    logic [XLEN-1:0] x0;
    logic [XLEN-1:0] x1;
    logic [XLEN-1:0] x2;
    logic [XLEN-1:0] x3;
    logic [XLEN-1:0] x4;
    logic [XLEN-1:0] x5;
    logic [XLEN-1:0] x6;
    logic [XLEN-1:0] x7;
    logic [XLEN-1:0] x8;
    logic [XLEN-1:0] x9;
    logic [XLEN-1:0] x10;
    logic [XLEN-1:0] x11;
    logic [XLEN-1:0] x12;
    logic [XLEN-1:0] x13;
    logic [XLEN-1:0] x14;
    logic [XLEN-1:0] x15;
    logic [XLEN-1:0] x16;
    logic [XLEN-1:0] x17;
    logic [XLEN-1:0] x18;
    logic [XLEN-1:0] x19;
    logic [XLEN-1:0] x20;
    logic [XLEN-1:0] x21;
    logic [XLEN-1:0] x22;
    logic [XLEN-1:0] x23;
    logic [XLEN-1:0] x24;
    logic [XLEN-1:0] x25;
    logic [XLEN-1:0] x26;
    logic [XLEN-1:0] x27;
    logic [XLEN-1:0] x28;
    logic [XLEN-1:0] x29;
    logic [XLEN-1:0] x30;
    logic [XLEN-1:0] x31;

    assign x0  = regs[ 0];
    assign x1  = regs[ 1];
    assign x2  = regs[ 2];
    assign x3  = regs[ 3];
    assign x4  = regs[ 4];
    assign x5  = regs[ 5];
    assign x6  = regs[ 6];
    assign x7  = regs[ 7];
    assign x8  = regs[ 8];
    assign x9  = regs[ 9];
    assign x10 = regs[10];
    assign x11 = regs[11];
    assign x12 = regs[12];
    assign x13 = regs[13];
    assign x14 = regs[14];
    assign x15 = regs[15];
    assign x16 = regs[16];
    assign x17 = regs[17];
    assign x18 = regs[18];
    assign x19 = regs[19];
    assign x20 = regs[20];
    assign x21 = regs[21];
    assign x22 = regs[22];
    assign x23 = regs[23];
    assign x24 = regs[24];
    assign x25 = regs[25];
    assign x26 = regs[26];
    assign x27 = regs[27];
    assign x28 = regs[28];
    assign x29 = regs[29];
    assign x30 = regs[30];
    assign x31 = regs[31];

    `endif

    `ifdef FRISCV_SIM
    assign error = (regs[31]>0) ? 1'b1 :1'b0;
    `endif

endmodule

`resetall
