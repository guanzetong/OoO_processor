//////////////////////////////////////////////////////////////////////////
//                                                                      //
//   Modulename :  FU.sv                                                //
//                                                                      //
//  Description :  functional unit (FU) module of the pipeline;         //
//                 given the instruction command code CMD, select the   //
//                 proper input A and B for the FU, compute the result, // 
//                 and compute the condition for branches, and pass all //
//                 the results down the pipeline. WCR                   // 
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////
`ifndef __FU_MODULE_V__
`define __FU_MODULE_V__

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  alu_comb                                            //
//                                                                     //
//  Description :  ALU Combinational Logic                             //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module alu_comb(
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    ALU_FUNC     func,

    output logic [`XLEN-1:0] result
);
    wire signed [`XLEN-1:0] signed_opa, signed_opb;
    assign signed_opa = opa;
    assign signed_opb = opb;

    always_comb begin
        case (func)
            ALU_ADD:      result = opa + opb;
            ALU_SUB:      result = opa - opb;
            ALU_AND:      result = opa & opb;
            ALU_SLT:      result = signed_opa < signed_opb;
            ALU_SLTU:     result = opa < opb;
            ALU_OR:       result = opa | opb;
            ALU_XOR:      result = opa ^ opb;
            ALU_SRL:      result = opa >> opb[4:0];
            ALU_SLL:      result = opa << opb[4:0];
            ALU_SRA:      result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
            default:      result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
    end
endmodule // alu_comb

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  alu                                                 //
//                                                                     //
//  Description :  ALU Unit                                            //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module alu #( 
    parameter   C_CYCLE         =   `ALU_CYCLE  ,
    parameter   C_THREAD_NUM    =   `THREAD_NUM 
)(
    input   logic       clk_i       ,
    input   logic       rst_i       ,
    input   IB_FU       ib_fu_i     ,
    output  FU_IB       fu_ib_o     ,
    output  FU_BC       fu_bc_o     ,
    input   BC_FU       bc_fu_i     ,
    input   BR_MIS      br_mis_i    ,
    input   logic       exception_i 
);

    logic   [`XLEN-1:0]         rd_value        ;
    IB_FU                       ib_fu           ;
    logic   [C_CYCLE-1:0]       valid_sh        ;
    logic                       ex_start        ;
    logic                       ex_end          ;
    logic                       squash          ;

	logic   [`XLEN-1:0]         opa_mux_out, opb_mux_out;

    //
    // Latch valid instruction
    //
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ib_fu   <=  `SD 'b0;
        end else if (ex_start) begin
            ib_fu   <=  `SD ib_fu_i;
        end else begin
            ib_fu   <=  `SD ib_fu;
        end
    end

    //
    // ALU opA mux
    //
    always_comb begin
        opa_mux_out = `XLEN'hdeadfbac;
        case (ib_fu.is_inst.opa_select)
            OPA_IS_RS1:  opa_mux_out = ib_fu.is_inst.rs1_value;
            OPA_IS_NPC:  opa_mux_out = ib_fu.is_inst.npc;
            OPA_IS_PC:   opa_mux_out = ib_fu.is_inst.pc;
            OPA_IS_ZERO: opa_mux_out = 0;
        endcase
    end

    //
    // ALU opB mux
    //
    always_comb begin
        // Default value, Set only because the case isnt full.  If you see this
        // value on the output of the mux you have an invalid opb_select
        opb_mux_out = `XLEN'hfacefeed;
        case (ib_fu.is_inst.opb_select)
            OPB_IS_RS2:   opb_mux_out = ib_fu.is_inst.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(ib_fu.is_inst.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(ib_fu.is_inst.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(ib_fu.is_inst.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(ib_fu.is_inst.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(ib_fu.is_inst.inst);
        endcase 
    end

    alu_comb alu_comb_module(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(ib_fu.is_inst.alu_func),
        .result(rd_value)
    );

    assign  ex_start    =   ib_fu_i.valid && fu_ib_o.ready;
    assign  ex_end      =   fu_bc_o.valid && bc_fu_i.broadcasted;

    // Output valid shift register
    always_ff @(posedge clk_i) begin
        // System reset
        if (rst_i) begin
            valid_sh    <=  `SD 'b0;
        // Squash
        end else if (exception_i) begin
            valid_sh    <=  `SD 'b0;
        // Stall if result is valid but broadcaster is not ready, i.e. CDB structural hazard
        end else if (fu_bc_o.valid && (!bc_fu_i.broadcasted)) begin
            valid_sh    <=  `SD valid_sh;
        // Shift
        end else begin
            if (C_CYCLE == 1) begin
                valid_sh    <=  `SD ex_start;
            end else if (squash) begin
                valid_sh    <=  `SD {{(C_CYCLE-1){1'b0}}, ex_start};
            end else begin
                valid_sh    <=  `SD {valid_sh[C_CYCLE-2:0], ex_start};
            end
        end
    end

    // Input ready
    always_comb begin
        fu_ib_o.ready   =   1'b0;
        if (valid_sh == 'b0) begin
            fu_ib_o.ready   =   1'b1;
        end else if (ex_end) begin
            fu_ib_o.ready   =   1'b1;
        end
    end

    // Output to Broadcaster
    always_comb begin
        fu_bc_o.valid       =   valid_sh[C_CYCLE-1] && (!squash);
        fu_bc_o.pc          =   ib_fu.is_inst.pc                ;
        fu_bc_o.write_reg   =   1'b1                            ;
        fu_bc_o.rd_value    =   rd_value                        ;
        fu_bc_o.tag         =   ib_fu.is_inst.tag               ;
        fu_bc_o.br_inst     =   1'b0                            ;
        fu_bc_o.br_result   =   1'b0                            ;
        fu_bc_o.br_target   =   'b0                             ;
        fu_bc_o.thread_idx  =   ib_fu.is_inst.thread_idx        ;
        fu_bc_o.rob_idx     =   ib_fu.is_inst.rob_idx           ;
    end

    always_comb begin
        squash   =   1'b0;
        if (br_mis_i.valid[ib_fu.is_inst.thread_idx] == 1'b1) begin
            squash   =   1'b1; 
        end
    end

endmodule // alu

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mult_comb                                           //
//                                                                     //
//  Description :  Multiplier Combinational Logic                      //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module mult_comb(
    input [`XLEN-1:0] opa,
    input [`XLEN-1:0] opb,
    ALU_FUNC     func,

    output logic [`XLEN-1:0] result
);
    wire signed [`XLEN-1:0] signed_opa, signed_opb;
    wire signed [2*`XLEN-1:0] signed_mul, mixed_mul;
    wire        [2*`XLEN-1:0] unsigned_mul;
    assign signed_opa = opa;
    assign signed_opb = opb;
    assign signed_mul = signed_opa * signed_opb;
    assign unsigned_mul = opa * opb;
    assign mixed_mul = signed_opa * opb;

    always_comb begin
        case (func)
            ALU_MUL:      result = signed_mul[`XLEN-1:0];
            ALU_MULH:     result = signed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHSU:   result = mixed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHU:    result = unsigned_mul[2*`XLEN-1:`XLEN];
            default:      result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
    end
endmodule // mult_comb

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mult                                                //
//                                                                     //
//  Description :  Multiplier Unit                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module mult #( 
    parameter   C_CYCLE         =   `MULT_CYCLE ,
    parameter   C_THREAD_NUM    =   `THREAD_NUM 
)(
    input   logic       clk_i       ,
    input   logic       rst_i       ,
    input   IB_FU       ib_fu_i     ,
    output  FU_IB       fu_ib_o     ,
    output  FU_BC       fu_bc_o     ,
    input   BC_FU       bc_fu_i     ,
    input   BR_MIS      br_mis_i    ,
    input   logic       exception_i 
);
    logic   [`XLEN-1:0]     rd_value        ;
    IB_FU                   ib_fu           ;
    logic   [C_CYCLE-1:0]   valid_sh        ;
    logic                   ex_start        ;
    logic                   ex_end          ;
    logic                   squash          ;

	logic   [`XLEN-1:0]     opa_mux_out, opb_mux_out;

    //
    // Latch valid instruction
    //
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ib_fu   <=  `SD 'b0;
        end else if (ex_start) begin
            ib_fu   <=  `SD ib_fu_i;
        end else begin
            ib_fu   <=  `SD ib_fu;
        end
    end

    //
    // MULT opA mux
    //
    always_comb begin
        opa_mux_out = `XLEN'hdeadfbac;
        case (ib_fu.is_inst.opa_select)
            OPA_IS_RS1:  opa_mux_out = ib_fu.is_inst.rs1_value;
            OPA_IS_NPC:  opa_mux_out = ib_fu.is_inst.npc;
            OPA_IS_PC:   opa_mux_out = ib_fu.is_inst.pc;
            OPA_IS_ZERO: opa_mux_out = 0;
        endcase
    end

    //
    // MULT opB mux
    //
    always_comb begin
        // Default value, Set only because the case isnt full.  If you see this
        // value on the output of the mux you have an invalid opb_select
        opb_mux_out = `XLEN'hfacefeed;
        case (ib_fu.is_inst.opb_select)
            OPB_IS_RS2:   opb_mux_out = ib_fu.is_inst.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(ib_fu.is_inst.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(ib_fu.is_inst.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(ib_fu.is_inst.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(ib_fu.is_inst.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(ib_fu.is_inst.inst);
        endcase 
    end

    //
    // Combinatorial Multiplier
    //
    mult_comb mult_comb_module(
        .opa    ( opa_mux_out               ),
        .opb    ( opb_mux_out               ),
        .func   ( ib_fu.is_inst.alu_func    ),
        .result ( rd_value                  )
    );

    assign  ex_start    =   ib_fu_i.valid && fu_ib_o.ready;
    assign  ex_end      =   fu_bc_o.valid && bc_fu_i.broadcasted;

    // Output valid shift register
    always_ff @(posedge clk_i) begin
        // System reset
        if (rst_i) begin
            valid_sh    <=  `SD 'b0;
        // Squash
        end else if (exception_i) begin
            valid_sh    <=  `SD 'b0;
        // Stall if result is valid but broadcaster is not ready, i.e. CDB structural hazard
        end else if (fu_bc_o.valid && (!bc_fu_i.broadcasted)) begin
            valid_sh    <=  `SD valid_sh;
        // Shift
        end else begin
            if (C_CYCLE == 1) begin
                valid_sh    <=  `SD ex_start;
            end else if (squash) begin
                valid_sh    <=  `SD {{(C_CYCLE-1){1'b0}}, ex_start};
            end else begin
                valid_sh    <=  `SD {valid_sh[C_CYCLE-2:0], ex_start};
            end
        end
    end

    // Input ready
    always_comb begin
        fu_ib_o.ready   =   1'b0;
        if (valid_sh == 'b0) begin
            fu_ib_o.ready   =   1'b1;
        end else if (ex_end) begin
            fu_ib_o.ready   =   1'b1;
        end
    end

    // Output to Broadcaster
    always_comb begin
        fu_bc_o.valid       =   valid_sh[C_CYCLE-1] && (!squash);
        fu_bc_o.pc          =   ib_fu.is_inst.pc                ;
        fu_bc_o.write_reg   =   1'b1                            ;
        fu_bc_o.rd_value    =   rd_value                        ;
        fu_bc_o.tag         =   ib_fu.is_inst.tag               ;
        fu_bc_o.br_inst     =   1'b0                            ;
        fu_bc_o.br_result   =   1'b0                            ;
        fu_bc_o.br_target   =   'b0                             ;
        fu_bc_o.thread_idx  =   ib_fu.is_inst.thread_idx        ;
        fu_bc_o.rob_idx     =   ib_fu.is_inst.rob_idx           ;
    end

    always_comb begin
        squash   =   1'b0;
        if (br_mis_i.valid[ib_fu.is_inst.thread_idx] == 1'b1) begin
            squash   =   1'b1; 
        end
    end

endmodule // mult


/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  branch_condition                                    //
//                                                                     //
//  Description :  Given the instruction code, compute the proper      //
//                 condition for the instruction; for branches this    //
//                 condition will indicate whether the target is taken.//
//                 This module is purely combinational.                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module branch_condition(// Inputs
    input [`XLEN-1:0] rs1,    // Value to check against condition
    input [`XLEN-1:0] rs2,
    input  [2:0] func,  // Specifies which condition to check

    output logic cond    // 0/1 condition result (False/True)
);

    logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
    assign signed_rs1 = rs1;
    assign signed_rs2 = rs2;
    always_comb begin
        cond = 0;
        case (func)
            3'b000: cond = signed_rs1 == signed_rs2;  // BEQ
            3'b001: cond = signed_rs1 != signed_rs2;  // BNE
            3'b100: cond = signed_rs1 < signed_rs2;   // BLT
            3'b101: cond = signed_rs1 >= signed_rs2;  // BGE
            3'b110: cond = rs1 < rs2;                 // BLTU
            3'b111: cond = rs1 >= rs2;                // BGEU
        endcase
    end
    
endmodule // branch_condition

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  branch                                              //
//                                                                     //
//  Description :  Branch Unit                                         //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module branch #( 
    parameter   C_CYCLE         =   `BR_CYCLE   ,
    parameter   C_THREAD_NUM    =   `THREAD_NUM 
)(
    input   logic       clk_i       ,
    input   logic       rst_i       ,
    input   IB_FU       ib_fu_i     ,
    output  FU_IB       fu_ib_o     ,
    output  FU_BC       fu_bc_o     ,
    input   BC_FU       bc_fu_i     ,
    input   BR_MIS      br_mis_i    ,
    input   logic       exception_i 
);

    logic   [`XLEN-1:0]     rd_value        ;
    IB_FU                   ib_fu           ;
    logic   [C_CYCLE-1:0]   valid_sh        ;
    logic                   ex_start        ;
    logic                   ex_end          ;
    logic                   squash          ;

    logic                   br_result       ;
    logic   [`XLEN-1:0]     br_target       ;
    logic                   brcond_result   ;

	logic   [`XLEN-1:0]     opa_mux_out, opb_mux_out;

    //
    // Latch valid instruction
    //
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ib_fu   <=  `SD 'b0;
        end else if (ex_start) begin
            ib_fu   <=  `SD ib_fu_i;
        end else begin
            ib_fu   <=  `SD ib_fu;
        end
    end

    //
    // ALU opA mux
    //
    always_comb begin
        opa_mux_out = `XLEN'hdeadfbac;
        case (ib_fu.is_inst.opa_select)
            OPA_IS_RS1:  opa_mux_out = ib_fu.is_inst.rs1_value;
            OPA_IS_NPC:  opa_mux_out = ib_fu.is_inst.npc;
            OPA_IS_PC:   opa_mux_out = ib_fu.is_inst.pc;
            OPA_IS_ZERO: opa_mux_out = 0;
        endcase
    end

    //
    // ALU opB mux
    //
    always_comb begin
        // Default value, Set only because the case isnt full.  If you see this
        // value on the output of the mux you have an invalid opb_select
        opb_mux_out = `XLEN'hfacefeed;
        case (ib_fu.is_inst.opb_select)
            OPB_IS_RS2:   opb_mux_out = ib_fu.is_inst.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(ib_fu.is_inst.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(ib_fu.is_inst.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(ib_fu.is_inst.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(ib_fu.is_inst.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(ib_fu.is_inst.inst);
        endcase 
    end

    alu_comb alu_comb_module(
        .opa    (opa_mux_out            ),
        .opb    (opb_mux_out            ),
        .func   (ib_fu.is_inst.alu_func ),
        .result (br_target              )
    );

    //
    // instantiate the branch condition tester
    //
    branch_condition branch_condition_module (// Inputs
        .rs1    (ib_fu.is_inst.rs1_value        ), 
        .rs2    (ib_fu.is_inst.rs2_value        ),
        .func   (ib_fu.is_inst.inst.b.funct3    ), // inst bits to determine check

        // Output
        .cond   (brcond_result                  )
    );

    // ultimate "take branch" signal:
    //	unconditional, or conditional and the condition is true
    assign br_result    =   ib_fu.is_inst.uncond_br
                        | (ib_fu.is_inst.cond_br & brcond_result);

    assign  ex_start    =   ib_fu_i.valid && fu_ib_o.ready;
    assign  ex_end      =   fu_bc_o.valid && bc_fu_i.broadcasted;

    // Output valid shift register
    always_ff @(posedge clk_i) begin
        // System reset
        if (rst_i) begin
            valid_sh    <=  `SD 'b0;
        end else if (squash || exception_i) begin
            valid_sh    <=  `SD 'b0;
        // Stall if result is valid but broadcaster is not ready, i.e. CDB structural hazard
        end else if (fu_bc_o.valid && (!bc_fu_i.broadcasted)) begin
            valid_sh    <=  `SD valid_sh;
        // Shift
        end else begin
            if (C_CYCLE == 1) begin
                valid_sh    <=  `SD ex_start;
            end else begin
                valid_sh    <=  `SD {valid_sh[C_CYCLE-2:0], ex_start};
            end
        end
    end

    // Input ready
    always_comb begin
        fu_ib_o.ready   =   1'b0;
        if (valid_sh == 'b0) begin
            fu_ib_o.ready   =   1'b1;
        end else if (ex_end) begin
            fu_ib_o.ready   =   1'b1;
        end
    end

    // Output to Broadcaster
    always_comb begin
        fu_bc_o.valid       =   valid_sh[C_CYCLE-1] && (!squash);
        fu_bc_o.pc          =   ib_fu.is_inst.pc                ;
        fu_bc_o.write_reg   =   ib_fu.is_inst.uncond_br         ;
        fu_bc_o.rd_value    =   ib_fu.is_inst.npc               ;
        fu_bc_o.tag         =   ib_fu.is_inst.tag               ;
        fu_bc_o.br_inst     =   1'b1                            ;
        fu_bc_o.br_result   =   br_result                       ;
        fu_bc_o.br_target   =   br_target                       ;
        fu_bc_o.thread_idx  =   ib_fu.is_inst.thread_idx        ;
        fu_bc_o.rob_idx     =   ib_fu.is_inst.rob_idx           ;
    end

    always_comb begin
        squash   =   1'b0;
        if (br_mis_i.valid[ib_fu.is_inst.thread_idx] == 1'b1) begin
            squash   =   1'b1; 
        end
    end
    
endmodule // branch

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  load                                                //
//                                                                     //
//  Description :  load Unit                                           //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module load #( 
    parameter   C_CYCLE         =   `ALU_CYCLE  ,
    parameter   C_THREAD_NUM    =   `THREAD_NUM 
)(
    input   logic       clk_i       ,
    input   logic       rst_i       ,
    input   IB_FU       ib_fu_i     ,
    output  FU_IB       fu_ib_o     ,
    output  FU_LSQ      fu_lsq_o    ,
    input   BR_MIS      br_mis_i    ,
    input   logic       exception_i 
);

    logic   [`XLEN-1:0]         load_addr       ;
    IB_FU                       ib_fu           ;
    logic   [C_CYCLE-1:0]       valid_sh        ;
    logic                       ex_start        ;
    logic                       ex_end          ;
    logic                       squash          ;

	logic   [`XLEN-1:0]         opa_mux_out, opb_mux_out;

    //
    // Latch valid instruction
    //
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ib_fu   <=  `SD 'b0;
        end else if (ex_start) begin
            ib_fu   <=  `SD ib_fu_i;
        end else begin
            ib_fu   <=  `SD ib_fu;
        end
    end

    //
    // ALU opA mux
    //
    always_comb begin
        opa_mux_out = `XLEN'hdeadfbac;
        case (ib_fu.is_inst.opa_select)
            OPA_IS_RS1:  opa_mux_out = ib_fu.is_inst.rs1_value;
            OPA_IS_NPC:  opa_mux_out = ib_fu.is_inst.npc;
            OPA_IS_PC:   opa_mux_out = ib_fu.is_inst.pc;
            OPA_IS_ZERO: opa_mux_out = 0;
        endcase
    end

    //
    // ALU opB mux
    //
    always_comb begin
        // Default value, Set only because the case isnt full.  If you see this
        // value on the output of the mux you have an invalid opb_select
        opb_mux_out = `XLEN'hfacefeed;
        case (ib_fu.is_inst.opb_select)
            OPB_IS_RS2:   opb_mux_out = ib_fu.is_inst.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(ib_fu.is_inst.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(ib_fu.is_inst.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(ib_fu.is_inst.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(ib_fu.is_inst.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(ib_fu.is_inst.inst);
        endcase 
    end

    alu_comb alu_comb_module(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(ib_fu.is_inst.alu_func),
        .result(load_addr)
    );

    assign  ex_start    =   ib_fu_i.valid && fu_ib_o.ready;
    assign  ex_end      =   valid_sh[C_CYCLE-1];

    // Output valid shift register
    always_ff @(posedge clk_i) begin
        // System reset
        if (rst_i) begin
            valid_sh    <=  `SD 'b0;
        // Squash
        end else if (exception_i) begin
            valid_sh    <=  `SD 'b0;
        // Shift
        end else begin
            if (C_CYCLE == 1) begin
                valid_sh    <=  `SD ex_start;
            end else if (squash) begin
                valid_sh    <=  `SD {{(C_CYCLE-1){1'b0}}, ex_start};
            end else begin
                valid_sh    <=  `SD {valid_sh[C_CYCLE-2:0], ex_start};
            end
        end
    end

    // Output to LSQ
    always_comb begin
        fu_lsq_o.valid      =   ex_end && (!squash)         ;
        fu_lsq_o.addr       =   load_addr                   ;
        fu_lsq_o.data       =   'd0                         ;
        fu_lsq_o.rob_idx    =   ib_fu.is_inst.rob_idx       ;
        fu_lsq_o.thread_idx =   ib_fu.is_inst.thread_idx    ;
    end

    // Input ready
    always_comb begin
        fu_ib_o.ready   =   1'b0;
        if (valid_sh == 'b0) begin
            fu_ib_o.ready   =   1'b1;
        end else if (ex_end) begin
            fu_ib_o.ready   =   1'b1;
        end
    end

    always_comb begin
        squash   =   1'b0;
        if (br_mis_i.valid[ib_fu.is_inst.thread_idx] == 1'b1) begin
            squash   =   1'b1; 
        end
    end

endmodule // alu

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  store                                               //
//                                                                     //
//  Description :  Store Unit                                          //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module store #( 
    parameter   C_CYCLE         =   `ALU_CYCLE  ,
    parameter   C_THREAD_NUM    =   `THREAD_NUM 
)(
    input   logic       clk_i       ,
    input   logic       rst_i       ,
    input   IB_FU       ib_fu_i     ,
    output  FU_IB       fu_ib_o     ,
    output  FU_BC       fu_bc_o     ,
    input   BC_FU       bc_fu_i     ,
    output  FU_LSQ      fu_lsq_o    ,
    input   BR_MIS      br_mis_i    ,
    input   logic       exception_i 
);

    logic   [`XLEN-1:0]         store_addr        ;
    IB_FU                       ib_fu           ;
    logic   [C_CYCLE-1:0]       valid_sh        ;
    logic                       ex_start        ;
    logic                       ex_end          ;
    logic                       squash          ;

	logic   [`XLEN-1:0]         opa_mux_out, opb_mux_out;

    //
    // Latch valid instruction
    //
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            ib_fu   <=  `SD 'b0;
        end else if (ex_start) begin
            ib_fu   <=  `SD ib_fu_i;
        end else begin
            ib_fu   <=  `SD ib_fu;
        end
    end

    //
    // ALU opA mux
    //
    always_comb begin
        opa_mux_out = `XLEN'hdeadfbac;
        case (ib_fu.is_inst.opa_select)
            OPA_IS_RS1:  opa_mux_out = ib_fu.is_inst.rs1_value;
            OPA_IS_NPC:  opa_mux_out = ib_fu.is_inst.npc;
            OPA_IS_PC:   opa_mux_out = ib_fu.is_inst.pc;
            OPA_IS_ZERO: opa_mux_out = 0;
        endcase
    end

    //
    // ALU opB mux
    //
    always_comb begin
        // Default value, Set only because the case isnt full.  If you see this
        // value on the output of the mux you have an invalid opb_select
        opb_mux_out = `XLEN'hfacefeed;
        case (ib_fu.is_inst.opb_select)
            OPB_IS_RS2:   opb_mux_out = ib_fu.is_inst.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(ib_fu.is_inst.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(ib_fu.is_inst.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(ib_fu.is_inst.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(ib_fu.is_inst.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(ib_fu.is_inst.inst);
        endcase 
    end

    alu_comb alu_comb_module(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(ib_fu.is_inst.alu_func),
        .result(store_addr)
    );

    assign  ex_start    =   ib_fu_i.valid && fu_ib_o.ready;
    assign  ex_end      =   fu_bc_o.valid && bc_fu_i.broadcasted;

    // Output valid shift register
    always_ff @(posedge clk_i) begin
        // System reset
        if (rst_i) begin
            valid_sh    <=  `SD 'b0;
        // Squash
        end else if (exception_i) begin
            valid_sh    <=  `SD 'b0;
        // Stall if result is valid but broadcaster is not ready, i.e. CDB structural hazard
        end else if (fu_bc_o.valid && (!bc_fu_i.broadcasted)) begin
            valid_sh    <=  `SD valid_sh;
        // Shift
        end else begin
            if (C_CYCLE == 1) begin
                valid_sh    <=  `SD ex_start;
            end else if (squash) begin
                valid_sh    <=  `SD {{(C_CYCLE-1){1'b0}}, ex_start};
            end else begin
                valid_sh    <=  `SD {valid_sh[C_CYCLE-2:0], ex_start};
            end
        end
    end

    // Input ready
    always_comb begin
        fu_ib_o.ready   =   1'b0;
        if (valid_sh == 'b0) begin
            fu_ib_o.ready   =   1'b1;
        end else if (ex_end) begin
            fu_ib_o.ready   =   1'b1;
        end
    end

    // Output to Broadcaster
    always_comb begin
        fu_bc_o.valid       =   valid_sh[C_CYCLE-1] && (!squash);
        fu_bc_o.pc          =   ib_fu.is_inst.pc                ;
        fu_bc_o.write_reg   =   1'b1                            ;
        fu_bc_o.rd_value    =   'b0                             ;
        fu_bc_o.tag         =   ib_fu.is_inst.tag               ;
        fu_bc_o.br_inst     =   1'b0                            ;
        fu_bc_o.br_result   =   1'b0                            ;
        fu_bc_o.br_target   =   'b0                             ;
        fu_bc_o.thread_idx  =   ib_fu.is_inst.thread_idx        ;
        fu_bc_o.rob_idx     =   ib_fu.is_inst.rob_idx           ;
    end

    // Output to LSQ
    always_comb begin
        fu_lsq_o.valid      =   fu_bc_o.valid               ;
        fu_lsq_o.addr       =   store_addr                  ;
        fu_lsq_o.data       =   ib_fu.is_inst.rs2_value     ;
        fu_lsq_o.rob_idx    =   ib_fu.is_inst.rob_idx       ;
        fu_lsq_o.thread_idx =   ib_fu.is_inst.thread_idx    ;
    end

    always_comb begin
        squash   =   1'b0;
        if (br_mis_i.valid[ib_fu.is_inst.thread_idx] == 1'b1) begin
            squash   =   1'b1; 
        end
    end

endmodule // alu

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  FU.sv                                               //
//                                                                     //
//  Description :  Function Unit. Process the instructions from IB in  //
//                 ALU, MULT, BR, LOAD and STORE unit according to     //
//                 their type. Send the result to BC.                  //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module FU #( 
    parameter   C_ALU_NUM           =   `ALU_NUM                ,
    parameter   C_MULT_NUM          =   `MULT_NUM               ,
    parameter   C_BR_NUM            =   `BR_NUM                 ,
    parameter   C_LOAD_NUM          =   `LOAD_NUM               ,
    parameter   C_STORE_NUM         =   `STORE_NUM              ,
    parameter   C_THREAD_NUM        =   `THREAD_NUM             ,
    parameter   C_FU_NUM            =   C_ALU_NUM + C_MULT_NUM + C_BR_NUM + C_LOAD_NUM + C_STORE_NUM,
    parameter   C_LSQ_IN_NUM        =   C_LOAD_NUM + C_STORE_NUM  ,
    parameter   C_LSQ_OUT_NUM       =   C_THREAD_NUM * C_LOAD_NUM
)(
    input   logic                               clk_i           ,   // Clock
    input   logic                               rst_i           ,   // Reset
    input   IB_FU   [C_FU_NUM-1:0]              ib_fu_i         ,
    output  FU_IB   [C_FU_NUM-1:0]              fu_ib_o         ,
    output  FU_BC   [C_FU_NUM-1:0]              fu_bc_o         ,
    input   BC_FU   [C_FU_NUM-1:0]              bc_fu_i         ,
    output  FU_LSQ  [C_LSQ_IN_NUM-1:0]          fu_lsq_o        ,
    input   FU_BC   [C_LSQ_OUT_NUM-1:0]         lsq_bc_i        ,
    output  BC_FU   [C_LSQ_OUT_NUM-1:0]         bc_lsq_o        ,
    input   BR_MIS                              br_mis_i        ,
    input   logic                               exception_i     
);
// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_ALU_BASE          =   0                           ;
    localparam  C_MULT_BASE         =   C_ALU_BASE + C_ALU_NUM      ;
    localparam  C_BR_BASE           =   C_MULT_BASE + C_MULT_NUM    ;
    localparam  C_STORE_BASE        =   C_BR_BASE + C_BR_NUM        ;
    localparam  C_LOAD_BASE         =   C_STORE_BASE + C_STORE_NUM  ;

    localparam  C_LSQ_STORE_BASE    =   0                               ;
    localparam  C_LSQ_LOAD_BASE     =   C_LSQ_STORE_BASE + C_STORE_NUM  ;

    genvar  idx ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================
    generate
        for (idx = 0; idx < C_ALU_NUM; idx++) begin
            alu alu_unit (
                .clk_i          (clk_i                      ),
                .rst_i          (rst_i                      ),
                .ib_fu_i        (ib_fu_i[C_ALU_BASE+idx]    ),
                .fu_ib_o        (fu_ib_o[C_ALU_BASE+idx]    ),
                .fu_bc_o        (fu_bc_o[C_ALU_BASE+idx]    ),
                .bc_fu_i        (bc_fu_i[C_ALU_BASE+idx]    ),
                .br_mis_i       (br_mis_i                   ),
                .exception_i    (exception_i                )
            );
        end
    endgenerate

    generate
        for (idx = 0; idx < C_MULT_NUM; idx++) begin
            mult mult_unit (
                .clk_i          (clk_i                      ),
                .rst_i          (rst_i                      ),
                .ib_fu_i        (ib_fu_i[C_MULT_BASE+idx]   ),
                .fu_ib_o        (fu_ib_o[C_MULT_BASE+idx]   ),
                .fu_bc_o        (fu_bc_o[C_MULT_BASE+idx]   ),
                .bc_fu_i        (bc_fu_i[C_MULT_BASE+idx]   ),
                .br_mis_i       (br_mis_i                   ),
                .exception_i    (exception_i                )
            );
        end
    endgenerate

    generate
        for (idx = 0; idx < C_BR_NUM; idx++) begin
            branch branch_unit (
                .clk_i          (clk_i                  ),
                .rst_i          (rst_i                  ),
                .ib_fu_i        (ib_fu_i[C_BR_BASE+idx] ),
                .fu_ib_o        (fu_ib_o[C_BR_BASE+idx] ),
                .fu_bc_o        (fu_bc_o[C_BR_BASE+idx] ),
                .bc_fu_i        (bc_fu_i[C_BR_BASE+idx] ),
                .br_mis_i       (br_mis_i               ),
                .exception_i    (exception_i            )
            );
        end
    endgenerate

    generate
        for (idx = 0; idx < C_STORE_NUM; idx++) begin
            store store_unit (
                .clk_i          (clk_i                          ),
                .rst_i          (rst_i                          ),
                .ib_fu_i        (ib_fu_i[C_STORE_BASE+idx]      ),
                .fu_ib_o        (fu_ib_o[C_STORE_BASE+idx]      ),
                .fu_bc_o        (fu_bc_o[C_STORE_BASE+idx]      ),
                .bc_fu_i        (bc_fu_i[C_STORE_BASE+idx]      ),
                .fu_lsq_o       (fu_lsq_o[C_LSQ_STORE_BASE+idx] ),
                .br_mis_i       (br_mis_i                       ),
                .exception_i    (exception_i                    )
            );
        end
    endgenerate

    generate
        for (idx = 0; idx < C_LOAD_NUM; idx++) begin
            load load_unit (
                .clk_i          (clk_i                          ),
                .rst_i          (rst_i                          ),
                .ib_fu_i        (ib_fu_i[C_LOAD_BASE+idx]       ),
                .fu_ib_o        (fu_ib_o[C_LOAD_BASE+idx]       ),
                .fu_lsq_o       (fu_lsq_o[C_LSQ_LOAD_BASE+idx]  ),
                .br_mis_i       (br_mis_i                       ),
                .exception_i    (exception_i                    )
            );

            assign  fu_bc_o[C_LOAD_BASE+idx]    =   lsq_bc_i[idx]           ;
            assign  bc_lsq_o[idx]               =   bc_fu_i[C_LOAD_BASE+idx];
        end
    endgenerate

endmodule // module fu_module
`endif // __FU_MODULE_V__
