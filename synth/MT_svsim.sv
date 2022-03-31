`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module MT_svsim #(
    parameter    C_DP_NUM           =      2     ,     
    parameter    C_MT_ENTRY_NUM     =      32   , 
    parameter    C_CDB_NUM          =      2         ,
    parameter    C_TAG_IDX_WIDTH    =      $clog2(64)
) (
    input        logic              clk_i       ,         
    input        logic              rst_i       ,         
    input        logic              rollback_i  ,    

    input        CDB                [C_CDB_NUM-1:0]      cdb_i           ,
    input        DP_MT_READ         [C_DP_NUM-1:0]       dp_mt_read_i    ,
    input        DP_MT_WRITE        [C_DP_NUM-1:0]       dp_mt_write_i   ,
    input        AMT_ENTRY          [C_MT_ENTRY_NUM-1:0] amt_i           ,
    output       MT_DP              [C_DP_NUM-1:0]       mt_dp_o
); 
   
    

  MT MT( {>>{ clk_i }}, {>>{ rst_i }}, {>>{ rollback_i }}, {>>{ cdb_i }}, 
        {>>{ dp_mt_read_i }}, {>>{ dp_mt_write_i }}, {>>{ amt_i }}, 
        {>>{ mt_dp_o }} );
endmodule
`endif
