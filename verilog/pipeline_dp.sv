/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pipeline_dp.sv                                      //
//                                                                     //
//  Description :  Integrate Dispatcher, RS, ROB, PRF, IB              // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module pipeline_dp #(
    parameter   C_PARAM     =   0                   //  A place holder. Delete it.
) (
    input   logic                       clk_i       ,   //  Clock
    input   logic                       rst_i       ,   //  Reset
    input   FIQ_DP                      fiq_dp      ,
    output  DP_FIQ                      dp_fiq      ,
    input   CDB                         cdb         ,
    output  ROB_AMT [C_RT_NUM-1:0]      rob_amt     ,
    output  ROB_FL                      rob_fl      ,
    input   FU_IB   [C_FU_NUM-1:0]      fu_ib       ,
    output  IB_FU   [C_FU_NUM-1:0]      ib_fu       ,
    input   BC_PRF                      bc_prf      ,
    output  BR_MIS                      br_mis      ,
    input   logic                       exception_i
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    ROB_DP                      rob_dp      ;
    DP_ROB                      dp_rob      ;
    MT_DP   [`DP_NUM-1:0]       mt_dp       ;
    DP_MT   [`DP_NUM-1:0]       dp_mt       ;
    FL_DP                       fl_dp       ;
    DP_FL                       dp_fl       ;
    // FIQ_DP                      fiq_dp      ;
    // DP_FIQ                      dp_fiq      ;
    RS_DP                       rs_dp       ;
    DP_RS                       dp_rs       ;
    // CDB                         cdb         ;
    RS_IB   [`IS_NUM-1:0]       rs_ib       ;
    IB_RS                       ib_rs       ;
    RS_PRF  [`IS_NUM-1:0]       rs_prf      ;
    PRF_RS  [`IS_NUM-1:0]       prf_rs      ;
    BR_MIS                      br_mis      ;
    // ROB_AMT [C_RT_NUM-1:0]      rob_amt     ;
    // ROB_FL                      rob_fl      ;
    // FU_IB   [C_FU_NUM-1:0]      fu_ib       ;
    // IB_FU   [C_FU_NUM-1:0]      ib_fu       ;
    // BC_PRF                      bc_prf      ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   DP
// Description  :   Dispatcher
// --------------------------------------------------------------------
    DP DP_inst (
        .rob_dp_i       (rob_dp         ),
        .dp_rob_o       (dp_rob         ),
        .mt_dp_i        (mt_dp          ),
        .dp_mt_o        (dp_mt          ),
        .fl_dp_i        (fl_dp          ),
        .dp_fl_o        (dp_fl          ),
        .fiq_dp_i       (fiq_dp         ),
        .dp_fiq_o       (dp_fiq         ),
        .rs_dp_i        (rs_dp          ),
        .dp_rs_o        (dp_rs          )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   RS
// Description  :   Reservation Station
// --------------------------------------------------------------------
    RS RS_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rs_dp_o        (rs_dp          ),
        .dp_rs_i        (dp_rs          ),
        .cdb_i          (cdb            ),
        .rs_ib_o        (rs_ib          ),
        .ib_rs_i        (ib_rs          ),
        .rs_prf_o       (rs_prf         ),
        .prf_rs_i       (prf_rs         ),
        .br_mis_i       (br_mis         ),
        .exception_i    (exception_i    )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   ROB
// Description  :   Reorder Buffer
// --------------------------------------------------------------------
    ROB ROB_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rob_dp_o       (rob_dp         ),
        .dp_rob_i       (dp_rob         ),
        .cdb_i          (cdb            ),
        .rob_amt_o      (rob_amt        ),
        .rob_fl_o       (rob_fl         ),
        .exception_i    (exception_i    ),
        .br_mis_o       (br_mis         )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   IB
// Description  :   Issue Buffer
// --------------------------------------------------------------------
    IB IB_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .ib_rs_o        (ib_rs          ),
        .rs_ib_i        (rs_ib          ),
        .fu_ib_i        (fu_ib          ),
        .ib_fu_o        (ib_fu          ),
        .br_mis_i       (br_mis         ),
        .exception_i    (exception_i    )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   PRF
// Description  :   Physical Register File
// --------------------------------------------------------------------
    PRF PRF_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rs_prf_i       (rs_prf         ),
        .prf_rs_o       (prf_rs         ),
        .bc_prf_i       (bc_prf         )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule