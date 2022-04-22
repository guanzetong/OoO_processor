`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module RS_svsim #(
    parameter   C_RS_ENTRY_NUM  =   16   ,
    parameter   C_DP_NUM        =   2         ,
    parameter   C_IS_NUM        =   2         ,
    parameter   C_CDB_NUM       =   2        ,
    parameter   C_THREAD_NUM    =   2     ,
    localparam  C_RS_IDX_WIDTH  =   $clog2(C_RS_ENTRY_NUM)
) (
     
        input   logic                               clk_i           ,       input   logic                               rst_i           ,       output  RS_DP                               rs_dp_o         ,
    input   DP_RS                               dp_rs_i         ,
    input   CDB         [C_CDB_NUM-1:0]         cdb_i           ,
    output  RS_IB       [C_IS_NUM-1:0]          rs_ib_o         ,
    input   IB_RS                               ib_rs_i         ,
    output  RS_PRF      [C_IS_NUM-1:0]          rs_prf_o        ,
    input   PRF_RS      [C_IS_NUM-1:0]          prf_rs_i        ,
    input   BR_MIS                              br_mis_i        ,
    input   logic                               exception_i     
);

    

  RS RS( {>>{ clk_i }}, {>>{ rst_i }}, {>>{ rs_dp_o }}, {>>{ dp_rs_i }}, 
        {>>{ cdb_i }}, {>>{ rs_ib_o }}, {>>{ ib_rs_i }}, {>>{ rs_prf_o }}, 
        {>>{ prf_rs_i }}, {>>{ br_mis_i }}, {>>{ exception_i }} );
endmodule
`endif
