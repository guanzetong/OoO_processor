/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  LSQ.sv                                              //
//                                                                     //
//  Description :  Unified Load/Store Queue                            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module LSQ #(
    parameter   C_THREAD_NUM        =   `THREAD_NUM                 ,
    parameter   C_DP_NUM            =   `DP_NUM                     ,
    parameter   C_RT_NUM            =   `RT_NUM                     ,
    parameter   C_LSQ_ENTRY_NUM     =   `LSQ_ENTRY_NUM              ,
    parameter   C_LOAD_NUM          =   `LOAD_NUM                   ,
    parameter   C_STORE_NUM         =   `STORE_NUM                  ,
    parameter   C_ROB_IDX_WIDTH     =   `ROB_IDX_WIDTH              ,
    parameter   C_TAG_IDX_WIDTH     =   `TAG_IDX_WIDTH              ,
    parameter   C_DP_NUM_WIDTH      =   $clog2(C_DP_NUM+1)          ,
    parameter   C_LSQ_IN_NUM        =   C_LOAD_NUM + C_STORE_NUM    ,
    parameter   C_LSQ_IDX_WIDTH     =   $clog2(C_LSQ_ENTRY_NUM)     ,
    parameter   C_THREAD_IDX_WIDTH  =   $clog2(C_THREAD_NUM)        

) (
    // For testing
    output  LSQ_ENTRY   [C_LSQ_ENTRY_NUM-1:0]   lsq_array_mon_o ,
    // Clock and Reset
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    // Thread
    input   logic   [C_THREAD_IDX_WIDTH-1:0]    thread_idx_i    ,   //  Entry index of this entry
    // ROB
    input   ROB_LSQ                             rob_lsq_i       ,
    // Dispatcher
    output  LSQ_DP                              lsq_dp_o        ,
    input   DP_LSQ                              dp_lsq_i        ,
    // FU
    input   FU_LSQ  [C_LSQ_IN_NUM-1:0]          fu_lsq_i        ,
    // BC
    input   BC_FU                               bc_lsq_i        ,
    output  FU_BC    [C_LOAD_NUM-1:0]           lsq_bc_o        ,
    // MEM
    input   MEM_OUT                             mem_lsq_i       ,
    output  MEM_IN                              lsq_mem_o       
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    LSQ_ENTRY   [C_LSQ_ENTRY_NUM-1:0]       lsq_array       ;
    logic       [C_LSQ_IDX_WIDTH-1:0]       head            ;
    logic       [C_LSQ_IDX_WIDTH-1:0]       tail            ;
    logic       [C_LSQ_ENTRY_NUM-1:0]       dp_sel          ;
    logic       [C_LSQ_ENTRY_NUM-1:0]       rt_sel          ;
    FU_BC       [C_LSQ_ENTRY_NUM-1:0]       lsq_entry_bc    ;
    BC_FU       [C_LSQ_ENTRY_NUM-1:0]       bc_lsq_entry    ;
    MEM_IN      [C_LSQ_ENTRY_NUM-1:0]       lsq_entry_mem   ;
    logic       [C_LSQ_ENTRY_NUM-1:0]       mem_grant       ;

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   LSQ_entry_ctrl
// Description  :   LSQ entry controller
// --------------------------------------------------------------------
    genvar entry_idx;
    generate
        for (entry_idx = 0; entry_idx < C_LSQ_ENTRY_NUM; entry_idx++) begin
            LSQ_entry_ctrl LSQ_entry_ctrl_inst (
                .clk_i              (clk_i                      ),
                .rst_i              (rst_i                      ),
                .lsq_idx_i          (entry_idx                  ),
                .thread_idx_i       (thread_idx_i               ),
                .lsq_array_i        (lsq_array                  ),
                .head_i             (head                       ),
                .tail_i             (tail                       ),
                .dp_sel_i           (dp_sel[entry_idx]          ),
                .rt_sel_i           (rt_sel[entry_idx]          ),
                .dp_lsq_i           (dp_lsq_i                   ),
                .fu_lsq_i           (fu_lsq_i                   ),
                .lsq_entry_mem_o    (lsq_entry_mem              ),
                .mem_lsq_i          (mem_lsq_i                  ),
                .mem_grant_i        (mem_grant[entry_idx]       ),
                .lsq_entry_bc_o     (lsq_entry_bc[entry_idx]    ),
                .bc_lsq_entry_i     (bc_lsq_i                   ),
                .rob_lsq_i          (rob_lsq_i                  ),
                .lsq_entry_o        (lsq_array[entry_idx]       )
            );
        end
    endgenerate

// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   LSQ_global_ctrl
// Description  :   LSQ global controller
//                  1. head and tail pointer movement
//                  2. Dispatch and Retire entry select 
// --------------------------------------------------------------------
    LSQ_global_ctrl LSQ_global_ctrl_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .dp_lsq_i       (dp_lsq_i       ),
        .lsq_array_i    (lsq_array      ),
        .head_o         (head           ),
        .tail_o         (tail           ),
        .dp_sel_o       (dp_sel         ),
        .rt_sel_o       (rt_sel         ),
        .lsq_dp_o       (lsq_dp_o       )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   LSQ_memory_switch
// Description  :   LSQ to memory interface arbitration and routing
// --------------------------------------------------------------------
    LSQ_memory_switch LSQ_memory_switch_inst (
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .lsq_entry_mem_i    (lsq_entry_mem      ),
        .mem_lsq_i          (mem_lsq_i          ),
        .memory_grant_o     (memory_grant_o     ),
        .lsq_mem_o          (lsq_mem_o          )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   LSQ_bc_switch
// Description  :   LSQ to Broadcaster interface arbitration and routing
// --------------------------------------------------------------------
    LSQ_bc_switch LSQ_bc_switch_inst (
        .clk_i              (clk_i          ),
        .rst_i              (rst_i          ),
        .lsq_entry_bc_i     (lsq_entry_bc   ),
        .bc_lsq_i           (bc_lsq_i       ),
        .lsq_bc_o           (lsq_bc_o       ),
        .bc_lsq_entry_o     (bc_lsq_entry   )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// For Testing
// --------------------------------------------------------------------
    assign  lsq_array_mon_o =   lsq_array   ;

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
