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
        output logic [XLEN                -1:0] x1_ra,
        output logic [XLEN                -1:0] x2_sp,
        output logic [XLEN                -1:0] x3_gp,
        output logic [XLEN                -1:0] x4_tp,
        output logic [XLEN                -1:0] x5_t0,
        output logic [XLEN                -1:0] x6_t1,
        output logic [XLEN                -1:0] x7_t2,
        output logic [XLEN                -1:0] x8_s0_fp,
        output logic [XLEN                -1:0] x9_s1,
        output logic [XLEN                -1:0] x10_a0,
        output logic [XLEN                -1:0] x11_a1,
        output logic [XLEN                -1:0] x12_a2,
        output logic [XLEN                -1:0] x13_a3,
        output logic [XLEN                -1:0] x14_a4,
        output logic [XLEN                -1:0] x15_a5,
        output logic [XLEN                -1:0] x16_a6,
        output logic [XLEN                -1:0] x17_a7,
        output logic [XLEN                -1:0] x18_s2,
        output logic [XLEN                -1:0] x19_s3,
        output logic [XLEN                -1:0] x20_s4,
        output logic [XLEN                -1:0] x21_s5,
        output logic [XLEN                -1:0] x22_s6,
        output logic [XLEN                -1:0] x23_s7,
        output logic [XLEN                -1:0] x24_s8,
        output logic [XLEN                -1:0] x25_s9,
        output logic [XLEN                -1:0] x26_s10,
        output logic [XLEN                -1:0] x27_s11,
        output logic [XLEN                -1:0] x28_t3,
        output logic [XLEN                -1:0] x29_t4,
        output logic [XLEN                -1:0] x30_t5,
        output logic [XLEN                -1:0] x31_t6,
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

    for (i=0; i<REGNUM; i=i+1) begin: RegisterFFD

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

        for (i=0;i<NB_ALU_UNIT;i=i+1) begin: PROCESSING_COMB_REG_IFS
            assign proc_rs1_val[i*XLEN+:XLEN] = regs[proc_rs1_addr[i*5+:5]];
            assign proc_rs2_val[i*XLEN+:XLEN] = regs[proc_rs2_addr[i*5+:5]];
        end

    end else begin: SYNCHRO_READ

        always @ (negedge aclk or negedge aresetn) begin
            if (aresetn == 1'b0) begin
                ctrl_rs1_val <= {XLEN{1'b0}};
                ctrl_rs2_val <= {XLEN{1'b0}};
                csr_rs1_val <= {XLEN{1'b0}};
                for (i=0;i<NB_ALU_UNIT;i=i+1) begin: PROCESING_ARESETN_REG_IFS
                    proc_rs1_val[i*XLEN+:XLEN] <= {XLEN{1'b0}};
                    proc_rs2_val[i*XLEN+:XLEN] <= {XLEN{1'b0}};
                end
            end else if (srst) begin
                ctrl_rs1_val <= {XLEN{1'b0}};
                ctrl_rs2_val <= {XLEN{1'b0}};
                csr_rs1_val <= {XLEN{1'b0}};
                for (i=0;i<NB_ALU_UNIT;i=i+1) begin: PROCESING_SRST_REG_IFS
                    proc_rs1_val[i*XLEN+:XLEN] <= {XLEN{1'b0}};
                    proc_rs2_val[i*XLEN+:XLEN] <= {XLEN{1'b0}};
                end
            end else begin
                ctrl_rs1_val <= regs[ctrl_rs1_addr];
                ctrl_rs2_val <= regs[ctrl_rs2_addr];
                csr_rs1_val <= regs[csr_rs1_addr];
                for (i=0;i<NB_ALU_UNIT;i=i+1) begin: PROCESING_SYNC_REG_IFS
                    proc_rs1_val[i*XLEN+:XLEN] <= regs[proc_rs1_addr[i*5+:5]];
                    proc_rs2_val[i*XLEN+:XLEN] <= regs[proc_rs2_addr[i*5+:5]];
                end
            end
        end

    end
    endgenerate

    assign x1_ra     = regs[1];
    assign x2_sp     = regs[2];
    assign x3_gp     = regs[3];
    assign x4_tp     = regs[4];
    assign x5_t0     = regs[5];
    assign x6_t1     = regs[6];
    assign x7_t2     = regs[7];
    assign x8_s0_fp  = regs[8];
    assign x9_s1     = regs[9];
    assign x10_a0    = regs[10];
    assign x11_a1    = regs[11];
    assign x12_a2    = regs[12];
    assign x13_a3    = regs[13];
    assign x14_a4    = regs[14];
    assign x15_a5    = regs[15];
    assign x16_a6    = regs[16];
    assign x17_a7    = regs[17];
    assign x18_s2    = regs[18];
    assign x19_s3    = regs[19];
    assign x20_s4    = regs[20];
    assign x21_s5    = regs[21];
    assign x22_s6    = regs[22];
    assign x23_s7    = regs[23];
    assign x24_s8    = regs[24];
    assign x25_s9    = regs[25];
    assign x26_s10   = regs[26];
    assign x27_s11   = regs[27];
    assign x28_t3    = regs[28];
    assign x29_t4    = regs[29];
    assign x30_t5    = regs[30];
    assign x31_t6    = regs[31];

endmodule

`resetall
