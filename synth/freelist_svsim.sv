`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module freelist_svsim #(
	parameter C_FL_ENTRY_NUM = 64 - 32,
    parameter C_FL_IDX = $clog2(64 - 32),
    parameter C_DP_NUM = 2,
	parameter C_RT_NUM = 2,
    parameter C_ARCH_REG_NUM = 32,
    parameter C_PHY_REG_NUM = 64,
	parameter C_PHY_IDX = $clog2(64)
) (
	input logic clk_i,
	input logic rst_i,
	input logic rollback_i,

	input DP_FL dp_fl_i,
    input ROB_FL rob_fl_i,
	input ROB_VFL    vfl_i,

     
	output FL_ENTRY   [C_FL_ENTRY_NUM-1:0]   fl_entry, next_fl_entry,
	output logic   [C_FL_IDX-1:0]                 		fl_rollback_idx,
	output logic   [C_FL_IDX-1:0]                 		head, next_head,
	output logic   [C_FL_IDX-1:0]                 		tail, next_tail,
	output logic   [C_DP_NUM-1:0] [C_FL_IDX-1:0] 	fl_idx,   	

    output FL_DP fl_dp_o
);



	 

    

  freelist freelist( {>>{ clk_i }}, {>>{ rst_i }}, {>>{ rollback_i }}, 
        {>>{ dp_fl_i }}, {>>{ rob_fl_i }}, {>>{ vfl_i }}, {>>{ fl_entry }}, 
        {>>{ next_fl_entry }}, {>>{ fl_rollback_idx }}, {>>{ head }}, 
        {>>{ next_head }}, {>>{ tail }}, {>>{ next_tail }}, {>>{ fl_idx }}, 
        {>>{ fl_dp_o }} );
endmodule
`endif
