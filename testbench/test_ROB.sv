/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  test_ROB.sv                                         //
//                                                                     //
//  Description :  Test ROB MODULE of the pipeline;                    // 
//                 Reorders out of order instructions                  //
//                 and update state (as if) in the archiectural        //
//                 order.                                              //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

/*
1. Dispatch, fill all entries
2. Complete,
3. Retire, empty all entries,
4. Dispatch, Complete some, retire some
*/

module testbench;
    logic                           clk_i               ;
    logic                           rst_i               ;
    ROB_DP  [`DP_NUM-1:0]           rob_dp_o            ;
    DP_ROB  [`DP_NUM-1:0]           dp_rob_i            ;
    ROB_RS  [`DP_NUM-1:0]           rob_rs_o            ;
    CDB     [`CDB_NUM-1:0]          cdb_i               ;
    ROB_AMT [`RT_NUM-1:0]           rob_amt_o           ;
    ROB_FL  [`RT_NUM-1:0]           rob_fl_o            ;
    logic                           exception_i         ;




    ROB dut (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rob_dp_o       (rob_dp_o       ),
        .dp_rob_i       (dp_rob_i       ),
        .rob_rs_o       (rob_rs_o       ),
        .cdb_i          (cdb_i          ),
        .rob_amt_o      (rob_amt_o      ),
        .rob_fl_o       (rob_fl_o       ),
        .exception_i    (exception_i    )
    );

    task randomize_dispatch();
        
    endtask

    // 
    task dispatch(
        input   dp_en,
        input   arch_reg,
        input   tag,
        input   tag_old,
        input   br_predict
    );
        @(negedge clk_i);
        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            dp_rob_i[idx].dp_en         =   dp_en       ;
            dp_rob_i[idx].arch_reg      =   arch_reg    ;
            dp_rob_i[idx].tag           =   tag         ;
            dp_rob_i[idx].tag_old       =   tag_old     ;
            dp_rob_i[idx].br_predict    =   br_predict  ;
        end
    endtask //automatic

endmodule
