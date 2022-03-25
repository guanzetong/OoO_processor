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

`timescale 1ns/100ps
//
// The ALU
//
// given the command code CMD and proper operands A and B, compute the
// result of the instruction
//
// This module is purely combinational
//
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

module alu(
    input logic              clk_i,
    input logic              alu_start_i,
    input logic              alu_reset_i,
    input FU_PACKET          fu_packet_i,

    output logic             alu_ready_o,
    output logic             alu_valid_o,
    output logic [`XLEN-1:0] alu_result_o
);
    logic alu_started;
    logic [`XLEN-1:0]          alu_result;
    logic [`C_COUNTER_LEN-1:0] counter;
    logic [`XLEN-1:0]          opa_mux_out, opb_mux_out;
    logic                      brcond_result;
    FU_PACKET                  fu_packet;
    //
    // ALU opA mux
    //
    always_comb begin
        opa_mux_out = `XLEN'hdeadfbac;
        case (fu_packet.opa_select)
            OPA_IS_RS1:  opa_mux_out = fu_packet.rs1_value;
            OPA_IS_NPC:  opa_mux_out = fu_packet.NPC;
            OPA_IS_PC:   opa_mux_out = fu_packet.PC;
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
        case (fu_packet.opb_select)
            OPB_IS_RS2:   opb_mux_out = fu_packet.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(fu_packet.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(fu_packet.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(fu_packet.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(fu_packet.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(fu_packet.inst);
        endcase 
    end

    alu_comb alu_comb_module(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(fu_packet.alu_func),
        .result(alu_result)
    );

    always_ff @(posedge clk_i) begin
        if(alu_reset_i) begin
            alu_ready_o <= 1'b1;
            alu_valid_o <= 1'b0;
            alu_started <= 1'b0;
        end
        else if(alu_start_i & !alu_started) begin
            alu_started <= 1'b1;
            alu_ready_o <= 1'b0;
            fu_packet <= fu_packet_i;
            counter <= 0;
        end
        else if(alu_started && (counter < `C_ALU_CYCLE)) begin
            counter <= counter + 1;
        end
        else begin
            alu_valid_o <= 1'b1;
            alu_result_o <= alu_result;
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


module mult(
    input logic              clk_i,
    input logic              mult_start_i,
    input logic              mult_reset_i,
    input FU_PACKET          fu_packet_i,

    output logic             mult_ready_o,
    output logic             mult_valid_o,
    output logic [`XLEN-1:0] mult_result_o
);
    logic mult_started;
    logic [`XLEN-1:0]          mult_result;
    logic [`C_COUNTER_LEN-1:0] counter;
    logic [`XLEN-1:0]          opa_mux_out, opb_mux_out;
    logic                      brcond_result;
    FU_PACKET                  fu_packet;
    //
    // MULT opA mux
    //
    always_comb begin
        opa_mux_out = `XLEN'hdeadfbac;
        case (fu_packet.opa_select)
            OPA_IS_RS1:  opa_mux_out = fu_packet.rs1_value;
            OPA_IS_NPC:  opa_mux_out = fu_packet.NPC;
            OPA_IS_PC:   opa_mux_out = fu_packet.PC;
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
        case (fu_packet.opb_select)
            OPB_IS_RS2:   opb_mux_out = fu_packet.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(fu_packet.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(fu_packet.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(fu_packet.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(fu_packet.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(fu_packet.inst);
        endcase 
    end

    mult_comb mult_comb_module(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(fu_packet.alu_func),
        .result(mult_result)
    );

    always_ff @(posedge clk_i) begin
        if(mult_reset_i) begin
            mult_ready_o <= 1'b1;
            mult_valid_o <= 1'b0;
            mult_started <= 1'b0;
        end
        else if(mult_start_i & !mult_started) begin
            mult_started <= 1'b1;
            mult_ready_o <= 1'b0;
            fu_packet <= fu_packet_i;
            counter <= 0;
        end
        else if(mult_started && (counter < `C_MULT_CYCLE)) begin
            counter <= counter + 1;
        end
        else begin
            mult_valid_o <= 1'b1;
            mult_result_o <= mult_result;
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


module branch(
    input logic              clk_i,
    input logic              branch_start_i,
    input logic              branch_reset_i,
    input FU_PACKET          fu_packet_i,

    output logic             branch_ready_o,
    output logic             branch_valid_o,
    output logic [`XLEN-1:0] branch_result_o,
    output logic             take_branch_o
);
    logic [`XLEN-1:0] branch_result;
    logic take_branch;
    logic branch_started;
    logic [`XLEN-1:0]          branch_result;
    logic [`C_COUNTER_LEN-1:0] counter;
    logic [`XLEN-1:0]          opa_mux_out, opb_mux_out;
    logic                      brcond_result;
    FU_PACKET                  fu_packet;
    //
    // ALU opA mux
    //
    always_comb begin
        opa_mux_out = `XLEN'hdeadfbac;
        case (fu_packet.opa_select)
            OPA_IS_RS1:  opa_mux_out = fu_packet.rs1_value;
            OPA_IS_NPC:  opa_mux_out = fu_packet.NPC;
            OPA_IS_PC:   opa_mux_out = fu_packet.PC;
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
        case (fu_packet.opb_select)
            OPB_IS_RS2:   opb_mux_out = fu_packet.rs2_value;
            OPB_IS_I_IMM: opb_mux_out = `RV32_signext_Iimm(fu_packet.inst);
            OPB_IS_S_IMM: opb_mux_out = `RV32_signext_Simm(fu_packet.inst);
            OPB_IS_B_IMM: opb_mux_out = `RV32_signext_Bimm(fu_packet.inst);
            OPB_IS_U_IMM: opb_mux_out = `RV32_signext_Uimm(fu_packet.inst);
            OPB_IS_J_IMM: opb_mux_out = `RV32_signext_Jimm(fu_packet.inst);
        endcase 
    end

    alu_comb alu_comb_module(
        .opa(opa_mux_out),
        .opb(opb_mux_out),
        .func(fu_packet.alu_func),
        .result(branch_result)
    );
     //
     // instantiate the branch condition tester
     //
    branch_condition branch_condition_module (// Inputs
        .rs1(fu_packet.rs1_value), 
        .rs2(fu_packet.rs2_value),
        .func(fu_packet.inst.b.funct3), // inst bits to determine check

        // Output
        .cond(brcond_result)
    );

     // ultimate "take branch" signal:
     //	unconditional, or conditional and the condition is true
    assign take_branch = fu_packet.uncond_branch
                                  | (fu_packet.cond_branch & brcond_result);


    always_ff @(posedge clk_i) begin
        if(branch_reset_i) begin
            branch_ready_o <= 1'b1;
            branch_valid_o <= 1'b0;
            branch_started <= 1'b0;
        end
        else if(branch_start_i & !branch_started) begin
            branch_started <= 1'b1;
            branch_ready_o <= 1'b0;
            fu_packet <= fu_packet_i;
            counter <= 0;
        end
        else if(branch_started && (counter < `C_BRANCH_CYCLE)) begin
            counter <= counter + 1;
        end
        else begin
            branch_valid_o <= 1'b1;
            branch_result_o <= branch_result;
            take_branch_o <= take_branch;
        end
    end

endmodule // branch


module load(
    input logic              clk_i,
    input logic              load_start_i,
    input logic              load_reset_i,
    input FU_PACKET          fu_packet_i,
    input  [`XLEN-1:0]       Dmem2proc_data_i,
    input                    Dmem2proc_request_i,
    output logic             load_ready_o,
    output logic             load_valid_o,
    output logic [`XLEN-1:0] load_result_o,
    output logic [1:0]       proc2Dmem_command_o,
    output MEM_SIZE          proc2Dmem_size_o,
    output logic [`XLEN-1:0] proc2Dmem_addr_o,      // Address sent to data-memory
    output logic             proc2Dmem_request_o
);
    logic [`XLEN-1:0]        load_result;
    logic                    load_started;
    FU_PACKET                fu_packet;
    logic                    alu_ready;

    // Determine the command that must be sent to mem
    assign proc2Dmem_command_o =
                            (fu_packet.rd_mem & fu_packet.valid) ? BUS_LOAD :
                            BUS_NONE;

    assign proc2Dmem_size_o = MEM_SIZE'(fu_packet.mem_size[1:0]);	//only the 2 LSB to determine the size;
    alu alu_module(
    .clk_i(clk_i),
    .alu_start_i(load_started),
    .alu_reset_i(load_reset_i),
    .fu_packet_i(fu_packet),

    .alu_ready_o(alu_ready),
    .alu_valid_o(proc2Dmem_request_o),
    .alu_result_o(proc2Dmem_addr_o)
    );

    always_comb begin
        load_result = alu_result;
        if (fu_packet.rd_mem) begin
            if (~fu_packet.mem_size[2]) begin //is this an signed/unsigned load?
                if (fu_packet.mem_size[1:0] == 2'b0)
                    load_result = {{(`XLEN-8){Dmem2proc_data[7]}}, Dmem2proc_data[7:0]};
                else if  (fu_packet.mem_size[1:0] == 2'b01) 
                    load_result = {{(`XLEN-16){Dmem2proc_data[15]}}, Dmem2proc_data[15:0]};
                else load_result = Dmem2proc_data;
            end else begin
                if (fu_packet.mem_size[1:0] == 2'b0)
                    load_result = {{(`XLEN-8){1'b0}}, Dmem2proc_data[7:0]};
                else if  (fu_packet.mem_size[1:0] == 2'b01)
                    load_result = {{(`XLEN-16){1'b0}}, Dmem2proc_data[15:0]};
                else load_result = Dmem2proc_data;
            end
        end
    end
    //if we are in 32 bit mode, then we should never load a double word sized data
    assert property (@(negedge clock) (`XLEN == 32) && fu_packet.rd_mem |-> proc2Dmem_size != DOUBLE);

    always_ff @(posedge clk_i) begin
        if(load_reset_i) begin
            load_ready_o <= 1'b1;
            load_valid_o <= 1'b0;
            load_started <= 1'b0;            
        end
        else if(load_start_i & !load_started) begin
            load_started <= 1'b1;
            load_ready_o <= 1'b0;
            fu_packet <= fu_packet_i;
        end
        else if(Dmem2proc_request_i) begin
            load_result_o <= load_result;
            load_valid_o <= 1'b1;
        end
    end
endmodule // module load

module store(
    input logic              clk_i,
    input logic              store_start_i,
    input logic              store_reset_i,
    input FU_PACKET          fu_packet_i,
    output logic             store_ready_o,
    output logic             store_valid_o,
    output logic [1:0]       proc2Dmem_command_o,
    output logic [`XLEN-1:0] proc2Dmem_data_o,      // Data sent to data-memory
    output MEM_SIZE          proc2Dmem_size_o,
    output logic [`XLEN-1:0] proc2Dmem_addr_o,      // Address sent to data-memory
    output logic             proc2Dmem_request_o
);
    logic                    store_started;
    FU_PACKET                fu_packet;
    logic                    alu_ready;
    // Determine the command that must be sent to mem
    assign proc2Dmem_command =
                            (fu_packet.wr_mem & fu_packet.valid) ? BUS_STORE :
                            BUS_NONE;

    assign proc2Dmem_size_o = MEM_SIZE'(fu_packet.mem_size[1:0]);	//only the 2 LSB to determine the size;
    // The memory address is calculated by the ALU
    assign proc2Dmem_data_o = fu_packet.rs2_value;

    alu alu_module(
    .clk_i(clk_i),
    .alu_start_i(store_started),
    .alu_reset_i(store_reset_i),
    .fu_packet_i(fu_packet),

    .alu_ready_o(alu_ready),
    .alu_valid_o(proc2Dmem_request_o),
    .alu_result_o(proc2Dmem_addr_o)
    );
    always_ff @(posedge clk_i) begin
        if(store_reset_i) begin
            store_ready_o <= 1'b1;
            store_valid_o <= 1'b0;
            store_started <= 1'b0;            
        end
        else if(store_start_i & !store_started) begin
            store_started <= 1'b1;
            store_ready_o <= 1'b0;
            fu_packet <= fu_packet_i;
        end
        else if(proc2Dmem_request_o) begin
            store_valid_o <= 1'b1;
        end
    end
endmodule // module store


module FU ( 
    parameter   C_ALU_NUM            =   `ALU_NUM         ,
    parameter   C_MULT_NUM           =   `MULT_NUM        ,
    parameter   C_BRANCH_NUM            =   `BRANCH_NUM         ,
    parameter   C_LOAD_NUM     =   `LOAD_NUM  ,
    parameter   C_STORE_NUM      =   `STORE_NUM   ,
    parameter   C_ALU_CYCLE       =   `ALU_CYCLE    ,
    parameter   C_MULT_CYCLE       =   `MULT_CYCLE    ,
    parameter   C_BRANCH_CYCLE       =   `BRANCH_CYCLE    ,
    parameter   C_COUNTER_LEN       =   `COUNTER_LEN    
)(
    input   logic                            clk_i               ,   // Clock
    input   logic                            rst_i               ,   // Reset
    input   logic [C_ALU_NUM-1:0]            alu_start_i,
    input   logic [C_ALU_NUM-1:0]            alu_reset_i,
    input   FU_PACKET [C_ALU_NUM-1:0]        alu_fu_packet_i,
    output  logic [C_ALU_NUM-1:0]            alu_ready_o,
    output  logic [C_ALU_NUM-1:0]            alu_valid_o,
    output  logic [C_ALU_NUM-1:0][`XLEN-1:0] alu_result_o,

    input   logic [C_MULT_NUM-1:0]            mult_start_i,
    input   logic [C_MULT_NUM-1:0]            mult_reset_i,
    input   FU_PACKET [C_MULT_NUM-1:0]        mult_fu_packet_i,
    output  logic [C_MULT_NUM-1:0]            mult_ready_o,
    output  logic [C_MULT_NUM-1:0]            mult_valid_o,
    output  logic [C_MULT_NUM-1:0][`XLEN-1:0] mult_result_o,

    input   logic [C_BRANCH_NUM-1:0]            branch_start_i,
    input   logic [C_BRANCH_NUM-1:0]            branch_reset_i,
    input   FU_PACKET [C_BRANCH_NUM-1:0]        branch_fu_packet_i,
    output  logic [C_BRANCH_NUM-1:0]            branch_ready_o,
    output  logic [C_BRANCH_NUM-1:0]            branch_valid_o,
    output  logic [C_BRANCH_NUM-1:0][`XLEN-1:0] branch_result_o,
    output  logic [C_BRANCH_NUM-1:0]            take_branch_o,

    input   logic [C_LOAD_NUM-1:0]             load_start_i,
    input   logic [C_LOAD_NUM-1:0]             load_reset_i,
    input   FU_PACKET [C_LOAD_NUM-1:0]         load_fu_packet_i,
    input   logic [C_LOAD_NUM-1:0][`XLEN-1:0]  Dmem2proc_data_i,
    input   logic [C_LOAD_NUM-1:0]             Dmem2proc_request_i,
    output  logic [C_LOAD_NUM-1:0]             load_ready_o,
    output  logic [C_LOAD_NUM-1:0]             load_valid_o,
    output  logic [C_LOAD_NUM-1:0][`XLEN-1:0]  load_result_o,
    output  logic [C_LOAD_NUM-1:0][1:0]        proc2Dmem_command_o,
    output  MEM_SIZE [C_LOAD_NUM-1:0]          proc2Dmem_size_o,
    output  logic [C_LOAD_NUM-1:0][`XLEN-1:0]  proc2Dmem_addr_o,      // Address sent to data-memory
    output  logic [C_LOAD_NUM-1:0]             proc2Dmem_request_o,

    input   logic [C_STORE_NUM-1:0]             store_start_i,
    input   logic [C_STORE_NUM-1:0]             store_reset_i,
    input   FU_PACKET [C_STORE_NUM-1:0]         store_fu_packet_i,
    input   logic [C_STORE_NUM-1:0][`XLEN-1:0]  Dmem2proc_data_i,
    input   logic [C_STORE_NUM-1:0]             Dmem2proc_request_i,
    output  logic [C_STORE_NUM-1:0]             store_ready_o,
    output  logic [C_STORE_NUM-1:0]             store_valid_o,
    output  logic [C_STORE_NUM-1:0][`XLEN-1:0]  store_result_o,
    output  logic [C_STORE_NUM-1:0][1:0]        proc2Dmem_command_o,
    output  MEM_SIZE [C_STORE_NUM-1:0]          proc2Dmem_size_o,
    output  logic [C_STORE_NUM-1:0][`XLEN-1:0]  proc2Dmem_addr_o,      // Address sent to data-memory
    output  logic [C_STORE_NUM-1:0]             proc2Dmem_request_o
);

    alu alu_unit [C_ALU_NUM-1:0] (
        .clk_i(clk_i),
        .alu_start_i(alu_start_i),
        .alu_reset_i(alu_reset_i),
        .alu_fu_packet_i(alu_fu_packet_i),

        .alu_ready_o(alu_ready_o),
        .alu_valid_o(alu_valid_o),
        .alu_result_o(alu_result_o)
    );

    mult mult_unit [C_MULT_NUM-1:0](
        .clk_i(clk_i),
        .mult_start_i(mult_start_i),
        .mult_reset_i(mult_reset_i),
        .mult_fu_packet_i(mult_fu_packet_i),

        .mult_ready_o(mult_ready_o),
        .mult_valid_o(mult_valid_o),
        .mult_result_o(mult_result_o)
    );

    branch branch_unit [C_BRANCH_NUM-1:0](
        .clk_i(clk_i),
        .branch_start_i(branch_start_i),
        .branch_reset_i(branch_reset_i),
        .branch_fu_packet_i(branch_fu_packet_i),

        .branch_ready_o(branch_ready_o),
        .branch_valid_o(branch_valid_o),
        .branch_result_o(branch_result_o),
        .take_branch_o(take_branch_o)
    );

    load load_unit [C_LOAD_NUM-1:0](
        .clk_i(clk_i),
        .load_start_i(load_start_i),
        .load_reset_i(load_reset_i),
        .load_fu_packet_i(load_fu_packet_i),
        .Dmem2proc_data_i(Dmem2proc_data_i),
        .Dmem2proc_request_i(Dmem2proc_request_i),

        .load_ready_o(load_ready_o),
        .load_valid_o(load_valid_o),
        .load_result_o(load_result_o),
        .proc2Dmem_command_o(proc2Dmem_command_o),
        .proc2Dmem_size_o(proc2Dmem_size_o),
        .proc2Dmem_addr_o(proc2Dmem_addr_o),
        .proc2Dmem_request_o(proc2Dmem_request_o)
    );

    store store_unit [C_STORE_NUM-1:0](
        .clk_i(clk_i),
        .store_start_i(store_start_i),
        .store_reset_i(store_reset_i),
        .store_fu_packet_i(store_fu_packet_i),

        .store_ready_o(store_ready_o),
        .store_valid_o(store_valid_o),
        .store_result_o(store_result_o),
        .proc2Dmem_command_o(proc2Dmem_command_o),
        .proc2Dmem_data_o(proc2Dmem_data_o),
        .proc2Dmem_size_o(proc2Dmem_size_o),
        .proc2Dmem_addr_o(proc2Dmem_addr_o),
        .proc2Dmem_request_o(proc2Dmem_request_o)
    );


endmodule // module fu_module
`endif // __FU_MODULE_V__
