// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "friscv_h.sv"

module friscv_m_ext

    #(
		// Number of integer registers (RV32I = 32, RV32E = 16)
        parameter NB_INT_REG        = 32,
        // Architecture selection
        parameter XLEN  = 32
    )(
        // clock & reset
        input  wire                       aclk,
        input  wire                       aresetn,
        input  wire                       srst,
        // ALU instruction bus
        input  wire                       m_valid,
        output logic                      m_ready,
        input  wire  [`INST_BUS_W   -1:0] m_instbus,
		output logic [NB_INT_REG    -1:0] m_regs_sts,
		output logic                      div_pending,
        // register source 1 query interface
        output logic [5             -1:0] m_rs1_addr,
        input  wire  [XLEN          -1:0] m_rs1_val,
        // register source 2 for query interface
        output logic [5             -1:0] m_rs2_addr,
        input  wire  [XLEN          -1:0] m_rs2_val,
        // register estination for query interface
        output logic                      m_rd_wr,
        output logic [5             -1:0] m_rd_addr,
        output logic [XLEN          -1:0] m_rd_val,
        output logic [XLEN/8        -1:0] m_rd_strb
    );

    ///////////////////////////////////////////////////////////////////////////
    //
    // Parameters and variables declaration
    //
    ///////////////////////////////////////////////////////////////////////////

    logic [`OPCODE_W   -1:0] opcode;
    logic [`FUNCT3_W   -1:0] funct3;
    logic [`FUNCT3_W   -1:0] funct3_r;
    logic [`FUNCT7_W   -1:0] funct7;
    logic [`RS1_W      -1:0] rs1;
    logic [`RS2_W      -1:0] rs2;
    logic [`RD_W       -1:0] rd;
    logic [`RD_W       -1:0] rd_r;

    logic [2*XLEN      -1:0] mul;
    logic [2*XLEN      -1:0] mulw;
    logic [2*XLEN      -1:0] mul32;
    logic [2*XLEN      -1:0] mul64;
    logic                    rs1_sign;
    logic                    rs2_sign;

    logic [XLEN        -1:0] quot;
    logic [XLEN        -1:0] quotu;
    logic [XLEN        -1:0] rem;
    logic [XLEN        -2:0] remu;
    logic                    rd_wr_div;
    logic                    m_valid_div;
    logic                    signed_div;

	localparam MAX_OR   = 1;
    localparam MAX_OR_W = $clog2(MAX_OR) + 1;

	logic [MAX_OR_W    -1:0] regs_or[NB_INT_REG-1:0];


    ///////////////////////////////////////////////////////////////////////////
    //
    // Instruction bus fields
    //
    ///////////////////////////////////////////////////////////////////////////

    assign opcode = m_instbus[`OPCODE +: `OPCODE_W];
    assign funct3 = m_instbus[`FUNCT3 +: `FUNCT3_W];
    assign funct7 = m_instbus[`FUNCT7 +: `FUNCT7_W];
    assign rs1    = m_instbus[`RS1    +: `RS1_W   ];
    assign rs2    = m_instbus[`RS2    +: `RS2_W   ];
    assign rd     = m_instbus[`RD     +: `RD_W    ];

	////////////////////////////////////////////////////////////////////////
	// Track which integer registers is used by an outstanding request
	////////////////////////////////////////////////////////////////////////

    always @ (posedge aclk or negedge aresetn) begin

		if (!aresetn) regs_or[0] <= '0;
		else          regs_or[0] <= '0;

		for (int i=1;i<NB_INT_REG;i++) begin
			if (!aresetn) begin
				regs_or[i] <= '0;
			end else begin
				if ((m_valid && m_ready && rd == i[4:0]) &&
				   !(m_rd_wr && m_rd_addr==i[4:0]))
			   begin
						regs_or[i] <= regs_or[i] + 1;

				end else if (!(m_valid && m_ready && rd == i[4:0]) &&
							  (m_rd_wr && m_rd_addr==i[4:0]))
				begin
						regs_or[i] <= regs_or[i] - 1;
				end
			end
		end
	end

	for (genvar i=0;i<NB_INT_REG;i++) begin
		assign m_regs_sts[i] = regs_or[i] == '0;
	end


    ///////////////////////////////////////////////////////////////////////////
    //
    // Multiply / divide operations
    //
    ///////////////////////////////////////////////////////////////////////////


    assign rs1_sign = m_rs1_val[31] & (funct3!=`MULHU);
    assign rs2_sign = m_rs2_val[31] & (funct3==`MUL || funct3==`MULH);
    assign mul = $signed({rs1_sign,m_rs1_val}) * $signed({rs2_sign, m_rs2_val});

    assign mul32 = (funct3==`MUL) ? mul[0 +:32] :
                                    mul[32+:32] ;


    // 32 bits division
    assign quotu = {XLEN{1'b0}};
    assign remu = {XLEN{1'b0}};

    generate

    if (XLEN==64) begin: l_MULDIV64_GEN

        // 64 bits multiplication instruction
        assign mulw = $signed(m_rs1_val[0+:32]) * $signed(m_rs2_val[0+:32]);

        assign mul64 = {{32{mulw[31]}},mulw[31:0]};

    end else begin: l_NO_MULDIV64_GEN

        assign mul64 = {XLEN{1'b0}};

    end
    endgenerate


    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            funct3_r <= {`FUNCT3_W{1'b0}};
            rd_r <= 5'b0;
        end else if (srst) begin
            funct3_r <= {`FUNCT3_W{1'b0}};
            rd_r <= 5'b0;
        end else begin
            if (m_valid & m_ready) begin
                funct3_r <= funct3;
                rd_r <= rd;
            end
        end
    end

    assign m_valid_div = m_valid & funct3[2];
    assign signed_div = (funct3==`DIV) | (funct3==`REM);

    friscv_div 
    #(
        .WIDTH (XLEN)
    )
    div32
    (
        .aclk        	(aclk),
        .aresetn     	(aresetn),
        .srst        	(srst),
		.div_pending 	(div_pending), 
        .i_valid     	(m_valid_div),
        .i_ready     	(m_ready),
        .signed_div  	(signed_div),
        .divd        	(m_rs1_val),
        .divs        	(m_rs2_val),
        .o_valid     	(rd_wr_div),
        .o_ready     	(1'b1),
        .zero_div    	(),
        .quot        	(quot),
        .rem         	(rem)
    );


    ///////////////////////////////////////////////////////////////////////////
    //
    // ISA Registers interface
    //
    ///////////////////////////////////////////////////////////////////////////

    assign m_rs1_addr = rs1;

    assign m_rs2_addr = rs2;

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            m_rd_wr <= 1'b0;
            m_rd_addr <= 5'b0;
        end else if (srst) begin
            m_rd_wr <= 1'b0;
            m_rd_addr <= 5'b0;
        end else begin
            m_rd_wr <= (m_valid & !funct3[2]) | rd_wr_div;
            m_rd_addr <= (rd_wr_div) ? rd_r : rd;
        end
    end

    assign m_rd_strb = {XLEN/8{1'b1}};

    generate

    if (XLEN==64) begin: l_MULDIV64_SUPPORT
        always @ (posedge aclk or negedge aresetn) begin
            if (aresetn == 1'b0) begin
                m_rd_val <= {XLEN{1'b0}};
            end else if (srst) begin
                m_rd_val <= {XLEN{1'b0}};
            end else begin
                m_rd_val <= (rd_wr_div && (funct3_r==`DIV || funct3_r==`DIVU)) ? quot :
                            (rd_wr_div && (funct3_r==`REM || funct3_r==`REMU)) ? rem :
                            (opcode==`MULDIVW)                                 ? mul64 : 
                                                                                 mul32 ;
            end
        end

    end else begin: l_NO_MULDIV64_SUPPORT

        always @ (posedge aclk or negedge aresetn) begin
            if (aresetn == 1'b0) begin
                m_rd_val <= {XLEN{1'b0}};
            end else if (srst) begin
                m_rd_val <= {XLEN{1'b0}};
            end else begin
                m_rd_val <= (rd_wr_div && (funct3_r==`DIV || funct3_r==`DIVU)) ? quot :
                            (rd_wr_div && (funct3_r==`REM || funct3_r==`REMU)) ? rem :
                                                                                 mul32;
            end
       end
    end
    endgenerate

endmodule

`resetall
