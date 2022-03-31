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

module alu #( 
    parameter   C_CYCLE              =   `ALU_CYCLE              ,
    parameter   C_COUNTER_LEN        =   $clog2(C_CYCLE)    
)(
    input logic              clk_i,
    input logic              rst_i,
    input IB_FU              ib_fu_i,
    output FU_IB             fu_ib_o,
    output FU_BC             fu_bc_o,
    input  BC_FU             bc_fu_i
);
    logic                       started;
    logic [C_COUNTER_LEN-1:0]   counter;
    logic [`XLEN-1:0]           rd_value;
    IB_FU                       ib_fu;

	logic [`XLEN-1:0] opa_mux_out, opb_mux_out;

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

    always_ff @(posedge clk_i) begin
        if(rst_i | bc_fu_i.broadcasted) begin
            started <= 1'b0;
            fu_ib_o.ready <= 1'b1;
            fu_bc_o.valid <= 1'b0;
        end
        else if(fu_ib_o.ready & !started) begin
            started <= 1'b1;
            counter <= 0;
            ib_fu <= ib_fu_i;
            fu_ib_o.ready <= 1'b0;
        end
        else if(started && (counter < C_CYCLE)) begin
            counter <= counter + 1;
        end
        else begin
            fu_bc_o.valid <= 1'b1;
            fu_bc_o.pc <= ib_fu.is_inst.pc;
            fu_bc_o.write_reg <= 1'b1;
            fu_bc_o.rd_value <= rd_value;
            fu_bc_o.tag <= ib_fu.is_inst.tag;
            fu_bc_o.br_inst <= 1'b0;
            fu_bc_o.br_result <= 1'b0;
            fu_bc_o.br_target <= 'b0;
            fu_bc_o.thread_idx <= ib_fu.is_inst.thread_idx;
            fu_bc_o.rob_idx <= ib_fu.is_inst.rob_idx;
        end
    end
endmodule // alu




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
            // ALU_ADD:      result = opa + opb;
            // ALU_SUB:      result = opa - opb;
            // ALU_AND:      result = opa & opb;
            // ALU_SLT:      result = signed_opa < signed_opb;
            // ALU_SLTU:     result = opa < opb;
            // ALU_OR:       result = opa | opb;
            // ALU_XOR:      result = opa ^ opb;
            // ALU_SRL:      result = opa >> opb[4:0];
            // ALU_SLL:      result = opa << opb[4:0];
            // ALU_SRA:      result = signed_opa >>> opb[4:0]; // arithmetic from logical shift
            ALU_MUL:      result = signed_mul[`XLEN-1:0];
            ALU_MULH:     result = signed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHSU:   result = mixed_mul[2*`XLEN-1:`XLEN];
            ALU_MULHU:    result = unsigned_mul[2*`XLEN-1:`XLEN];

            default:      result = `XLEN'hfacebeec;  // here to prevent latches
        endcase
    end
endmodule // mult_comb


module mult #( 
    parameter   C_CYCLE              =   `MULT_CYCLE              ,
    parameter   C_COUNTER_LEN        =   $clog2(C_CYCLE)    
)(
    input logic              clk_i,
    input logic              rst_i,
    input IB_FU              ib_fu_i,
    output FU_IB             fu_ib_o,
    output FU_BC             fu_bc_o,
    input  BC_FU             bc_fu_i
);
    logic                       started;
    logic [C_COUNTER_LEN-1:0]   counter;
    logic [`XLEN-1:0]           rd_value;
    IB_FU                       ib_fu;

	logic [`XLEN-1:0] opa_mux_out, opb_mux_out;

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

    mult_comb mult_comb_module(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(ib_fu.is_inst.alu_func),
        .result(rd_value)
    );

    always_ff @(posedge clk_i) begin
        if(rst_i | bc_fu_i.broadcasted) begin
            started <= 1'b0;
            fu_ib_o.ready <= 1'b1;
            fu_bc_o.valid <= 1'b0;
        end
        else if(fu_ib_o.ready & !started) begin
            started <= 1'b1;
            counter <= 0;
            ib_fu <= ib_fu_i;
            fu_ib_o.ready <= 1'b0;
        end
        else if(started && (counter < C_CYCLE)) begin
            counter <= counter + 1;
        end
        else begin
            fu_bc_o.valid <= 1'b1;
            fu_bc_o.pc <= ib_fu.is_inst.pc;
            fu_bc_o.write_reg <= 1'b1;
            fu_bc_o.rd_value <= rd_value;
            fu_bc_o.tag <= ib_fu.is_inst.tag;
            fu_bc_o.br_inst <= 1'b0;
            fu_bc_o.br_result <= 1'b0;
            fu_bc_o.br_target <= 'b0;
            fu_bc_o.thread_idx <= ib_fu.is_inst.thread_idx;
            fu_bc_o.rob_idx <= ib_fu.is_inst.rob_idx;
        end
    end

endmodule // mult


//
// BrCond module
//
// Given the instruction code, compute the proper condition for the
// instruction; for branches this condition will indicate whether the
// target is taken.
//
// This module is purely combinational
//
module branch_condition(// Inputs
    input [`XLEN-1:0] rs1,    // Value to check against condition
    input [`XLEN-1:0] rs2,
    input  [2:0] func,  // Specifies which condition to check

    output logic [`XLEN-1:0] result,
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


module branch #( 
    parameter   C_CYCLE              =   `BR_CYCLE              ,
    parameter   C_COUNTER_LEN        =   $clog2(C_CYCLE)    
)(
    input logic              clk_i,
    input logic              rst_i,
    input IB_FU              ib_fu_i,
    output FU_IB             fu_ib_o,
    output FU_BC             fu_bc_o,
    input  BC_FU             bc_fu_i
);
    logic                       started;
    logic [C_COUNTER_LEN-1:0]  counter;
    logic                       br_result;
    logic [`XLEN-1:0]           br_target;
    IB_FU                       ib_fu;
    logic                       brcond_result;

	logic [`XLEN-1:0] opa_mux_out, opb_mux_out;

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
        .result(br_target)
    );
     //
     // instantiate the branch condition tester
     //
    branch_condition branch_condition_module (// Inputs
        .rs1(ib_fu.is_inst.rs1_value), 
        .rs2(ib_fu.is_inst.rs2_value),
        .func(ib_fu.is_inst.inst.b.funct3), // inst bits to determine check

        // Output
        .cond(brcond_result)
    );
     // ultimate "take branch" signal:
     //	unconditional, or conditional and the condition is true
    assign br_result = ib_fu.is_inst.uncond_br
                                  | (ib_fu.is_inst.cond_br & brcond_result);
    always_ff @(posedge clk_i) begin
        if(rst_i | bc_fu_i.broadcasted) begin
            started <= 1'b0;
            fu_ib_o.ready <= 1'b1;
            fu_bc_o.valid <= 1'b0;
        end
        else if(fu_ib_o.ready & !started) begin
            started <= 1'b1;
            counter <= 0;
            ib_fu <= ib_fu_i;
            fu_ib_o.ready <= 1'b0;
        end
        else if(started && (counter < C_CYCLE)) begin
            counter <= counter + 1;
        end
        else begin
            fu_bc_o.valid <= 1'b1;
            fu_bc_o.pc <= ib_fu.is_inst.pc;
            fu_bc_o.write_reg <= 1'b0;
            fu_bc_o.tag <= ib_fu.is_inst.tag;
            fu_bc_o.br_inst <= 1'b1;
            fu_bc_o.br_result <= br_result;
            fu_bc_o.br_target <= br_target;
            fu_bc_o.thread_idx <= ib_fu.is_inst.thread_idx;
            fu_bc_o.rob_idx <= ib_fu.is_inst.rob_idx;
        end
    end

    assign  fu_bc_o.rd_value    =   'b0;
endmodule // branch


// module load #( 
//     parameter   C_CYCLE              =   `ALU_CYCLE              ,
//     parameter   C_COUNTER_LEN        =   $clog2(C_CYCLE)    
// )(
//     input  logic             clk_i,
//     input  logic             rst_i,
//     input  IB_FU             ib_fu_i,
//     output FU_IB             fu_ib_o,
//     output FU_BC             fu_bc_o,
//     input  BC_FU             bc_fu_i,

//     output logic [1:0]       proc2Dmem_command_o,
//     output MEM_SIZE          proc2Dmem_size_o,
//     output logic [`XLEN-1:0] proc2Dmem_addr_o,      // Address sent to data-memory
//     output logic             proc2Dmem_request_o,
//     input  logic             proc2Dmem_recieved_i,
//     input  logic [`XLEN-1:0] Dmem2proc_data_i,
//     input                    Dmem2proc_request_i,
//     output                   Dmem2proc_recieved_o

// );
//     logic                       started;
//     logic [C_COUNTER_LEN-1:0]  counter;
//     logic [`XLEN-1:0]           rd_value;
//     IB_FU                       ib_fu;

//     // Determine the command that must be sent to mem
//     assign proc2Dmem_command_o =
//                             (ib_fu.is_inst.rd_mem & ib_fu.valid) ? BUS_LOAD :
//                             BUS_NONE;

//     assign proc2Dmem_size_o = MEM_SIZE'(ib_fu.is_inst.mem_size[1:0]);	//only the 2 LSB to determine the size;
//     //
//     // ALU opA mux
//     //
//     always_comb begin
//         opa_mux_out = `XLEN'hdeadfbac;
//         case (ib_fu.is_inst.opa_select)
//             OPA_IS_RS1:  opa_mux_out = ib_fu.is_inst.rs1_value;
//             OPA_IS_NPC:  opa_mux_out = ib_fu.is_inst.npc;
//             OPA_IS_PC:   opa_mux_out = ib_fu.is_inst.pc;
//             OPA_IS_ZERO: opa_mux_out = 0;
//         endcase
//     end
//      //
//      // ALU opB mux
//      //
//     always_comb begin
//         // Default value, Set only because the case isnt full.  If you see this
//         // value on the output of the mux you have an invalid opb_select
//         opb_mux_out = `XLEN'hfacefeed;
//         case (ib_fu.is_inst.opb_select)
//             OPB_IS_RS2:   opb_mux_out = ib_fu.is_inst.rs2_value;
//             OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(ib_fu.is_inst.inst);
//             OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(ib_fu.is_inst.inst);
//             OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(ib_fu.is_inst.inst);
//             OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(ib_fu.is_inst.inst);
//             OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(ib_fu.is_inst.inst);
//         endcase 
//     end

//     alu_comb alu_comb_module(
//         .opa(opa_mux_out),
//         .opb(opb_mux_out),
//         .func(ib_fu.is_inst.alu_func),
//         .result(proc2Dmem_addr_o)
//     );

//     always_comb begin
//         if (ib_fu.is_inst.rd_mem) begin
//             if (~ib_fu.is_inst.mem_size[2]) begin //is this an signed/unsigned load?
//                 if (ib_fu.is_inst.mem_size[1:0] == 2'b0)
//                     rd_value = {{(`XLEN-8){Dmem2proc_data[7]}}, Dmem2proc_data[7:0]};
//                 else if  (ib_fu.is_inst.mem_size[1:0] == 2'b01) 
//                     rd_value = {{(`XLEN-16){Dmem2proc_data[15]}}, Dmem2proc_data[15:0]};
//                 else rd_value = Dmem2proc_data;
//             end else begin
//                 if (ib_fu.is_inst.mem_size[1:0] == 2'b0)
//                     rd_value = {{(`XLEN-8){1'b0}}, Dmem2proc_data[7:0]};
//                 else if  (ib_fu.is_inst.mem_size[1:0] == 2'b01)
//                     rd_value = {{(`XLEN-16){1'b0}}, Dmem2proc_data[15:0]};
//                 else rd_value = Dmem2proc_data;
//             end
//         end
//     end
//     //if we are in 32 bit mode, then we should never load a double word sized data
//     assert property (@(negedge clock) (`XLEN == 32) && ib_fu.is_inst.rd_mem |-> proc2Dmem_size != DOUBLE);

//     always_ff @(posedge clk_i) begin
//         if(rst_i | bc_fu_i.broadcasted) begin
//             started <= 1'b0;
//             fu_ib_o.ready <= 1'b1;
//             fu_bc_o.valid <= 1'b0;
//             proc2Dmem_request_o <= 1'b0;
//             Dmem2proc_recieved_o <= 1'b0;
//         end
//         else begin
//             if(fu_ib_o.ready & !started) begin
//                 started <= 1'b1;
//                 counter <= 0;
//                 ib_fu <= ib_fu_i;
//                 fu_ib_o.ready <= 1'b0;
//             end
//             if(started ) begin
//                 counter <= counter + 1;
//             end
//             if(started & (counter == C_CYCLE)) begin
//                 proc2Dmem_request_o <= 1'b1;
//             end
//             else if(started & proc2Dmem_recieved_i) begin
//                 proc2Dmem_request_o <= 1'b0;
//             end
//             if(started & Dmem2proc_request_i) begin
//                 fu_bc_o.valid <= 1'b1;
//                 fu_bc_o.pc <= ib_fu.is_inst.pc;
//                 fu_bc_o.write_reg <= 1'b1;
//                 fu_bc_o.rd_value <= rd_value;
//                 fu_bc_o.tag <= ib_fu.is_inst.tag;
//                 fu_bc_o.br_inst <= 1'b0;
//                 fu_bc_o.br_result <= 1'b0;
//                 fu_bc_o.thread_idx <= ib_fu.is_inst.thread_idx;
//                 fu_bc_o.rob_idx <= ib_fu.is_inst.rob_idx;
//                 Dmem2proc_recieved_o <= 1'b1;
//             end
//         end
//     end
// endmodule // module load

// module store #( 
//     parameter   C_CYCLE              =   `ALU_CYCLE              ,
//     parameter   C_COUNTER_LEN        =   $clog2(C_CYCLE)    
// )(
//     input  logic             clk_i,
//     input  logic             rst_i,
//     input  IB_FU             ib_fu_i,
//     output FU_IB             fu_ib_o,
//     output FU_BC             fu_bc_o,
//     input  BC_FU             bc_fu_i,

//     output logic [1:0]       proc2Dmem_command_o,
//     output logic [`XLEN-1:0] proc2Dmem_data_o,      // Data sent to data-memory
//     output MEM_SIZE          proc2Dmem_size_o,
//     output logic [`XLEN-1:0] proc2Dmem_addr_o,      // Address sent to data-memory
//     output logic             proc2Dmem_request_o,
//     input  logic             proc2Dmem_recieved_i
// );
//     logic                       started;
//     logic [C_COUNTER_LEN-1:0]  counter;
//     IB_FU                       ib_fu;
//     // Determine the command that must be sent to mem
//     assign proc2Dmem_command =
//                             (ib_fu.is_inst.wr_mem & ib_fu.valid) ? BUS_STORE :
//                             BUS_NONE;

//     assign proc2Dmem_size_o = MEM_SIZE'(ib_fu.is_inst.mem_size[1:0]);	//only the 2 LSB to determine the size;
//     // The memory address is calculated by the ALU
//     assign proc2Dmem_data_o = ib_fu.is_inst.rs2_value;
//     //
//     // ALU opA mux
//     //
//     always_comb begin
//         opa_mux_out = `XLEN'hdeadfbac;
//         case (ib_fu.is_inst.opa_select)
//             OPA_IS_RS1:  opa_mux_out = ib_fu.is_inst.rs1_value;
//             OPA_IS_NPC:  opa_mux_out = ib_fu.is_inst.npc;
//             OPA_IS_PC:   opa_mux_out = ib_fu.is_inst.pc;
//             OPA_IS_ZERO: opa_mux_out = 0;
//         endcase
//     end
//      //
//      // ALU opB mux
//      //
//     always_comb begin
//         // Default value, Set only because the case isnt full.  If you see this
//         // value on the output of the mux you have an invalid opb_select
//         opb_mux_out = `XLEN'hfacefeed;
//         case (ib_fu.is_inst.opb_select)
//             OPB_IS_RS2:   opb_mux_out = ib_fu.is_inst.rs2_value;
//             OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(ib_fu.is_inst.inst);
//             OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(ib_fu.is_inst.inst);
//             OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(ib_fu.is_inst.inst);
//             OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(ib_fu.is_inst.inst);
//             OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(ib_fu.is_inst.inst);
//         endcase 
//     end

//     alu_comb alu_comb_module(
//         .opa(opa_mux_out),
//         .opb(opb_mux_out),
//         .func(ib_fu.is_inst.alu_func),
//         .result(proc2Dmem_addr_o)
//     );

//     always_ff @(posedge clk_i) begin
//         if(rst_i | bc_fu_i.broadcasted) begin
//             started <= 1'b0;
//             fu_ib_o.ready <= 1'b1;
//             fu_bc_o.valid <= 1'b0;
//             proc2Dmem_request_o <= 1'b0;
//         end
//         else begin
//             if(fu_ib_o.ready & !started) begin
//                 started <= 1'b1;
//                 counter <= 0;
//                 ib_fu <= ib_fu_i;
//                 fu_ib_o.ready <= 1'b0;
//             end
//             if(started ) begin
//                 counter <= counter + 1;
//             end
//             if(started & (counter == C_CYCLE)) begin
//                 proc2Dmem_request_o <= 1'b1;
//             end
//             else if(started & proc2Dmem_recieved_i) begin
//                 fu_bc_o.valid <= 1'b1;
//                 fu_bc_o.pc <= ib_fu.is_inst.pc;
//                 fu_bc_o.write_reg <= 1'b0;
//                 fu_bc_o.tag <= ib_fu.is_inst.tag;
//                 fu_bc_o.br_inst <= 1'b0;
//                 fu_bc_o.br_result <= 1'b0;
//                 fu_bc_o.thread_idx <= ib_fu.is_inst.thread_idx;
//                 fu_bc_o.rob_idx <= ib_fu.is_inst.rob_idx;
//                 proc2Dmem_request_o <= 1'b0;
//             end
//         end
//     end
// endmodule // module store

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
    parameter   C_FU_NUM             =   `FU_NUM                 ,
    parameter   C_ALU_NUM            =   `ALU_NUM                ,
    parameter   C_MULT_NUM           =   `MULT_NUM               ,
    parameter   C_BR_NUM             =   `BR_NUM                 ,
    parameter   C_LOAD_NUM           =   `LOAD_NUM               ,
    parameter   C_STORE_NUM          =   `STORE_NUM              
)(
    input   logic                            clk_i               ,   // Clock
    input   logic                            rst_i               ,   // Reset
    input   IB_FU [C_FU_NUM-1:0]             ib_fu_i             ,
    output  FU_IB [C_FU_NUM-1:0]             fu_ib_o             ,
    output  FU_BC [C_FU_NUM-1:0]             fu_bc_o             ,
    input   BC_FU [C_FU_NUM-1:0]             bc_fu_i             

    // output logic [C_STORE_NUM+C_LOAD_NUM-1:0][1:0]       proc2Dmem_command_o,
    // output logic [C_STORE_NUM-1:0][`XLEN-1:0]            proc2Dmem_data_o,      // Data sent to data-memory
    // output MEM_SIZE [C_STORE_NUM+C_LOAD_NUM-1:0]         proc2Dmem_size_o,
    // output logic [C_STORE_NUM+C_LOAD_NUM-1:0][`XLEN-1:0] proc2Dmem_addr_o,      // Address sent to data-memory
    // output logic [C_STORE_NUM+C_LOAD_NUM-1:0]            proc2Dmem_request_o,
    // input  logic [C_STORE_NUM+C_LOAD_NUM-1:0]            proc2Dmem_recieved_i,
    // input  logic [C_LOAD_NUM-1:0][`XLEN-1:0]             Dmem2proc_data_i,
    // input        [C_LOAD_NUM-1:0]                        Dmem2proc_request_i,
    // output       [C_LOAD_NUM-1:0]                        Dmem2proc_recieved_o
);
// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_ALU_BASE      =   0                           ;
    localparam  C_MULT_BASE     =   C_ALU_BASE + C_ALU_NUM      ;
    localparam  C_BR_BASE       =   C_MULT_BASE + C_MULT_NUM    ;
    localparam  C_LOAD_BASE     =   C_BR_BASE + C_BR_NUM        ;
    localparam  C_STORE_BASE    =   C_LOAD_BASE + C_LOAD_NUM    ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================
    alu alu_unit [C_ALU_NUM-1:0] (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .ib_fu_i(ib_fu_i[C_ALU_BASE+C_ALU_NUM-1:C_ALU_BASE]),
        .fu_ib_o(fu_ib_o[C_ALU_BASE+C_ALU_NUM-1:C_ALU_BASE]),
        .fu_bc_o(fu_bc_o[C_ALU_BASE+C_ALU_NUM-1:C_ALU_BASE]),
        .bc_fu_i(bc_fu_i[C_ALU_BASE+C_ALU_NUM-1:C_ALU_BASE])
    );

    mult mult_unit [C_MULT_NUM-1:0](
        .clk_i(clk_i),
        .rst_i(rst_i),
        .ib_fu_i(ib_fu_i[C_MULT_BASE+C_MULT_NUM-1:C_MULT_BASE]),
        .fu_ib_o(fu_ib_o[C_MULT_BASE+C_MULT_NUM-1:C_MULT_BASE]),
        .fu_bc_o(fu_bc_o[C_MULT_BASE+C_MULT_NUM-1:C_MULT_BASE]),
        .bc_fu_i(bc_fu_i[C_MULT_BASE+C_MULT_NUM-1:C_MULT_BASE])
    );

    branch branch_unit [C_BR_NUM-1:0](
        .clk_i(clk_i),
        .rst_i(rst_i),
        .ib_fu_i(ib_fu_i[C_BR_BASE+C_BR_NUM-1:C_BR_BASE]),
        .fu_ib_o(fu_ib_o[C_BR_BASE+C_BR_NUM-1:C_BR_BASE]),
        .fu_bc_o(fu_bc_o[C_BR_BASE+C_BR_NUM-1:C_BR_BASE]),
        .bc_fu_i(bc_fu_i[C_BR_BASE+C_BR_NUM-1:C_BR_BASE])
    );

    // load load_unit [C_LOAD_NUM-1:0](
    //     .clk_i(clk_i),
    //     .rst_i(rst_i),
    //     .ib_fu_i(ib_fu_i[C_LOAD_BASE+C_LOAD_NUM-1:C_LOAD_BASE]),
    //     .fu_ib_o(fu_ib_o[C_LOAD_BASE+C_LOAD_NUM-1:C_LOAD_BASE]),
    //     .fu_bc_o(fu_bc_o[C_LOAD_BASE+C_LOAD_NUM-1:C_LOAD_BASE]),
    //     .bc_fu_i(bc_fu_i[C_LOAD_BASE+C_LOAD_NUM-1:C_LOAD_BASE]),

    //     .proc2Dmem_command_o(proc2Dmem_command_o[C_LOAD_NUM-1:0]),
    //     .proc2Dmem_size_o(proc2Dmem_size_o[C_LOAD_NUM-1:0]),
    //     .proc2Dmem_addr_o(proc2Dmem_addr_o[C_LOAD_NUM-1:0]),
    //     .proc2Dmem_request_o(proc2Dmem_request_o[C_LOAD_NUM-1:0]),
    //     .proc2Dmem_recieved_i(proc2Dmem_recieved_i[C_LOAD_NUM-1:0]),
    //     .Dmem2proc_data_i(Dmem2proc_data_i[C_LOAD_NUM-1:0]),
    //     .Dmem2proc_request_i(Dmem2proc_request_i[C_LOAD_NUM-1:0]),
    //     .Dmem2proc_recieved_o(Dmem2proc_recieved_o[C_LOAD_NUM-1:0])
    // );

    // store store_unit [C_STORE_NUM-1:0](
    //     .clk_i(clk_i),
    //     .rst_i(rst_i),
    //     .ib_fu_i(ib_fu_i[C_STORE_BASE+C_STORE_NUM-1:C_STORE_BASE]),
    //     .fu_ib_o(fu_ib_o[C_STORE_BASE+C_STORE_NUM-1:C_STORE_BASE]),
    //     .fu_bc_o(fu_bc_o[C_STORE_BASE+C_STORE_NUM-1:C_STORE_BASE]),
    //     .bc_fu_i(bc_fu_i[C_STORE_BASE+C_STORE_NUM-1:C_STORE_BASE]),

    //     .proc2Dmem_command_o(proc2Dmem_command_o[C_STORE_NUM+C_LOAD_NUM-1:C_LOAD_NUM]),
    //     .proc2Dmem_data_o(proc2Dmem_data_o[C_STORE_NUM-1:0]),
    //     .proc2Dmem_size_o(proc2Dmem_size_o[C_STORE_NUM+C_LOAD_NUM-1:C_LOAD_NUM]),
    //     .proc2Dmem_addr_o(proc2Dmem_addr_o[C_STORE_NUM+C_LOAD_NUM-1:C_LOAD_NUM]),
    //     .proc2Dmem_request_o(proc2Dmem_request_o[C_STORE_NUM+C_LOAD_NUM-1:C_LOAD_NUM]),
    //     .proc2Dmem_recieved_i(proc2Dmem_recieved_i[C_STORE_NUM+C_LOAD_NUM-1:C_LOAD_NUM])
    // );

    always_comb begin
        for (int unsigned fu_idx = C_LOAD_BASE; fu_idx < C_FU_NUM; fu_idx++) begin
            fu_ib_o[fu_idx].ready   =   1'b1;
            fu_bc_o[fu_idx]         =   'b0;
        end
    end


endmodule // module fu_module
`endif // __FU_MODULE_V__
