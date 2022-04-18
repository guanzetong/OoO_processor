/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pipeline_s_smt.sv                                   //
//                                                                     //
//  Description :  N-way SS SMT pipline                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////
`define DEBUG

module pipeline_ss_smt (
  // Testing
`ifdef DEBUG
    //      Instruction Cache
    output  MSHR_ENTRY      [`MSHR_ENTRY_NUM-1:0]                       imshr_array_mon_o   ,
    output  CACHE_MEM_ENTRY [`ICACHE_SET_NUM-1:0][`ICACHE_SASS-1:0]     icache_array_mon_o  ,
    output  MEM_IN                                                      if_ic_o_t           ,   // Expose fetch to cache interface to the testbench.
    output  MEM_OUT                                                     ic_if_o_t           , 
    //      Fetch
    output logic            [`THREAD_IDX_WIDTH-1:0]                     thread_idx_disp_o_t ,
    output logic            [`THREAD_IDX_WIDTH-1:0]                     thread_to_ft_o_t    ,    
    output CONTEXT          [`THREAD_NUM-1:0]                           thread_data_o_t     ,
    output CONTEXT          [`THREAD_NUM-1:0]                           n_thread_data_o_t   ,
    //      Dispatch
    output  DP_RS                                                       dp_rs_mon_o         ,   // From Dispatcher to RS
    output  DP_MT       [`THREAD_NUM-1:0][`DP_NUM-1:0]                  dp_mt_mon_o         ,
    output  MT_DP       [`THREAD_NUM-1:0][`DP_NUM-1:0]                  mt_dp_mon_o         ,
    //      Issue
    output  RS_IB                                                       rs_ib_mon_o         ,   // From RS to IB
    //      Execute
    output  IB_FU       [`FU_NUM-1:0]                                   ib_fu_mon_o         ,   // From IB to FU
    //      Complete
    output  FU_BC                                                       fu_bc_mon_o         ,   // From FU to BC
    output  CDB         [`CDB_NUM-1:0]                                  cdb_mon_o           ,   // CDB
    //      Retire
    output  ROB_AMT     [`THREAD_NUM-1:0][`RT_NUM-1:0]                  rob_amt_mon_o       ,   // From ROB to AMT
    output  ROB_FL      [`THREAD_NUM-1:0]                               rob_fl_mon_o        ,   // From ROB to FL
    output  BR_MIS                                                      br_mis_mon_o        ,   // Branch Misprediction
    //      Contents
    output  ROB_ENTRY   [`THREAD_NUM-1:0][`ROB_ENTRY_NUM-1:0]           rob_mon_o           ,   // ROB contents monitor
    output  RS_ENTRY    [`RS_ENTRY_NUM-1:0]                             rs_mon_o            ,   // RS contents monitor
    output  logic       [$clog2(`RS_ENTRY_NUM)-1:0]                     rs_cod_mon_o        ,
    output  MT_ENTRY    [`THREAD_NUM-1:0][`ARCH_REG_NUM-1:0]            mt_mon_o            ,   // Map Table contents monitor
    output  FL_ENTRY    [`FL_ENTRY_NUM-1:0]                             fl_mon_o            ,   // Freelist monitor
    output  IS_INST     [`ALU_Q_SIZE  -1:0]                             ALU_queue_mon_o     ,   // IB queue monitor
    output  IS_INST     [`MULT_Q_SIZE -1:0]                             MULT_queue_mon_o    ,   // IB queue monitor
    output  IS_INST     [`BR_Q_SIZE   -1:0]                             BR_queue_mon_o      ,   // IB queue monitor
    output  IS_INST     [`LOAD_Q_SIZE -1:0]                             LOAD_queue_mon_o    ,   // IB queue monitor
    output  IS_INST     [`STORE_Q_SIZE-1:0]                             STORE_queue_mon_o   ,   // IB queue monitor
    output  logic       [`ALU_Q_SIZE  -1:0]                             ALU_valid_mon_o     ,   // IB queue monitor
    output  logic       [`MULT_Q_SIZE -1:0]                             MULT_valid_mon_o    ,   // IB queue monitor
    output  logic       [`BR_Q_SIZE   -1:0]                             BR_valid_mon_o      ,   // IB queue monitor
    output  logic       [`LOAD_Q_SIZE -1:0]                             LOAD_valid_mon_o    ,   // IB queue monitor
    output  logic       [`STORE_Q_SIZE-1:0]                             STORE_valid_mon_o   ,   // IB queue monitor
    output  logic       [`ALU_IDX_WIDTH  -1:0]                          ALU_head_mon_o      ,   // IB queue pointer monitor
    output  logic       [`ALU_IDX_WIDTH  -1:0]                          ALU_tail_mon_o      ,   // IB queue pointer monitor
    output  logic       [`MULT_IDX_WIDTH -1:0]                          MULT_head_mon_o     ,   // IB queue pointer monitor
    output  logic       [`MULT_IDX_WIDTH -1:0]                          MULT_tail_mon_o     ,   // IB queue pointer monitor
    output  logic       [`BR_IDX_WIDTH   -1:0]                          BR_head_mon_o       ,   // IB queue pointer monitor
    output  logic       [`BR_IDX_WIDTH   -1:0]                          BR_tail_mon_o       ,   // IB queue pointer monitor
    output  logic       [`LOAD_IDX_WIDTH -1:0]                          LOAD_head_mon_o     ,   // IB queue pointer monitor
    output  logic       [`LOAD_IDX_WIDTH -1:0]                          LOAD_tail_mon_o     ,   // IB queue pointer monitor
    output  logic       [`STORE_IDX_WIDTH-1:0]                          STORE_head_mon_o    ,   // IB queue pointer monitor
    output  logic       [`STORE_IDX_WIDTH-1:0]                          STORE_tail_mon_o    ,   // IB queue pointer monitor
    output  LSQ_ENTRY   [`THREAD_NUM-1:0][`LSQ_ENTRY_NUM-1:0]           lsq_array_mon_o     ,   // LSQ monitor
    output  logic       [`THREAD_NUM-1:0][`LSQ_IDX_WIDTH-1:0]           lsq_head_mon_o      ,   // LSQ pointer monitor
    output  logic       [`THREAD_NUM-1:0][`LSQ_IDX_WIDTH-1:0]           lsq_tail_mon_o      ,   // LSQ pointer monitor
    output  MSHR_ENTRY      [`MSHR_ENTRY_NUM-1:0]                       dmshr_array_mon_o   ,   
`endif

    input   logic                                                       clk_i               ,   // Clock
    input   logic                                                       rst_i               ,   // Reset

    // Memory Interface
    output  MEM_IN                                                      proc2mem_o          ,   // From Processor to Memory
    input   MEM_OUT                                                     mem2proc_i          ,   // From Memory to Processor

    // Pipeline Control Signals
    input   logic                                                       exception_i         ,   // External exception
    input   logic           [`THREAD_NUM-1:0]                           pc_en_i             ,   // Used to control SMT (turn off a hart if necessary)
    input   logic           [`THREAD_NUM-1:0][`XLEN-1:0]                rst_pc_i            ,

    // Must-have Monitor Signals for testbench
    output  logic       [`THREAD_NUM-1:0][`RT_NUM-1:0][`XLEN-1:0]       rt_pc_o             ,   // PC of retired instructions
    output  logic       [`THREAD_NUM-1:0][`RT_NUM-1:0]                  rt_valid_o          ,   // Retire valid
    output  logic       [`THREAD_NUM-1:0][`RT_NUM-1:0]                  rt_wfi_o            ,   // WFI
    output  logic       [`THREAD_NUM-1:0][`ROB_IDX_WIDTH-1:0]           rob_head_mon_o      ,   // ROB head pointer
    output  logic       [`THREAD_NUM-1:0][`ROB_IDX_WIDTH-1:0]           rob_tail_mon_o      ,   // ROB tail pointer
    output  AMT_ENTRY   [`THREAD_NUM-1:0][`ARCH_REG_NUM-1:0]            amt_mon_o           ,   // Arch Map Table contents monitor
    output  logic       [`PHY_REG_NUM-1:0] [`XLEN-1:0]                  prf_mon_o           ,   // Physical Register File monitor
    output  CACHE_MEM_ENTRY [`DCACHE_SET_NUM-1:0][`DCACHE_SASS-1:0]     dcache_array_mon_o  
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
    // From IF
    MEM_IN                                                  if_ic           ;	
    MEM_OUT                                                 ic_if           ;
    FIQ_DP                                                  fiq_dp          ;

    // From DP
    DP_ROB      [`THREAD_NUM-1:0]                           dp_rob          ;
    DP_MT       [`THREAD_NUM-1:0][`DP_NUM-1:0]              dp_mt           ;
    DP_RS                                                   dp_rs           ;
    DP_FL                                                   dp_fl           ;
    DP_LSQ      [`THREAD_NUM-1:0]                           dp_lsq          ;
    DP_FIQ                                                  dp_fiq          ;

    // From ROB
    ROB_DP      [`THREAD_NUM-1:0]                           rob_dp          ;
    ROB_AMT     [`THREAD_NUM-1:0][`RT_NUM-1:0]              rob_amt         ;
    ROB_FL      [`THREAD_NUM-1:0]                           rob_fl          ;
    ROB_LSQ     [`THREAD_NUM-1:0]                           rob_lsq         ;

    // From RS
    RS_DP                                                   rs_dp           ;
    RS_PRF      [`IS_NUM-1:0]                               rs_prf          ;
    RS_IB       [`IS_NUM-1:0]                               rs_ib           ;
    BR_MIS                                                  br_mis          ;

    // From FL
    FL_DP                                                   fl_dp           ;

    // From IB
    IB_RS                                                   ib_rs           ;
    IB_FU       [`FU_NUM-1:0]                               ib_fu           ;

    // From BC
    BC_FU       [`FU_NUM-1:0]                               bc_fu           ;
    BC_PRF      [`CDB_NUM-1:0]                              bc_prf          ;
    CDB         [`CDB_NUM-1:0]                              cdb             ;

    // From FU
    FU_IB       [`FU_NUM-1:0]                               fu_ib           ;
    FU_BC       [`FU_NUM-1:0]                               fu_bc           ;
    FU_LSQ      [`LSQ_IN_NUM-1:0]                           fu_lsq          ;
    BC_FU       [`LSQ_OUT_NUM-1:0]                          bc_lsq          ;

    // From PRF
    PRF_RS      [`IS_NUM-1:0]                               prf_rs          ;

    // From MT
    AMT_ENTRY   [`THREAD_NUM-1:0][`ARCH_REG_NUM-1:0]        amt             ;
    MT_DP       [`THREAD_NUM-1:0][`DP_NUM-1:0]              mt_dp           ;

    // From LSQ
    LSQ_DP      [`THREAD_NUM-1:0]                           lsq_dp          ;
    FU_BC       [`LSQ_OUT_NUM-1:0]                          lsq_bc          ;
    MEM_IN      [`THREAD_NUM-1:0]                           lsq_mem         ;
    MEM_IN                                                  proc2dcache     ;

    // From DCache
    logic       [`THREAD_NUM-1:0]                           dcache_grant    ;
    MEM_OUT                                                 dcache2proc     ;
    MEM_IN                                                  dcache2mem      ;

    // From ICache
    MEM_IN                                                  icache2mem      ;

    // From Memory
    MEM_IN      [2-1:0]                                     req2mem         ;
    logic       [2-1:0]                                     memory_grant    ;

    logic       [`THREAD_NUM-1:0]                           wfi_flag        ;
    logic       [`THREAD_NUM-1:0]                           wfi_retire      ;
    logic       [`THREAD_NUM-1:0]                           dp_en           ;

    genvar thread_idx;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================

// --------------------------------------------------------------------
// Module name  :   IC
// Description  :   Instruction Cache
// --------------------------------------------------------------------
    icache IC (
`ifdef DEBUG
        .mshr_array_mon_o   (imshr_array_mon_o  ),
        .cache_array_mon_o  (icache_array_mon_o ),
`endif
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .proc2cache_i       (if_ic              ),
        .cache2proc_o       (ic_if              ),
        .memory_enable_i    (memory_grant[1]    ),  
        .cache2mem_o        (icache2mem         ),
        .mem2cache_i        (mem2proc_i         )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   IF
// Description  :   Instruction fetch
// --------------------------------------------------------------------
    IF IF_inst (
    `ifdef DEBUG
    // Everything here isn't required for functionalities
    // Next State wires
        .n_thread_data_o_t    ( n_thread_data_o_t    ),           // Verify how the wire is like.
        .thread_idx_disp_o_t  ( thread_idx_disp_o_t  ),
    // State Register wires
        .thread_data_o_t      ( thread_data_o_t      ),          // Expose print to testbench
        .thread_to_ft_o_t     ( thread_to_ft_o_t     ),
    `endif
        .clk_i      (clk_i      ),
        .rst_i      (rst_i      ),
        .pc_en_i    (pc_en_i    ),
        .rst_pc_i   (rst_pc_i   ),
        .br_mis_i   (br_mis     ),
        .ic_if_i    (ic_if      ),
        .dp_fiq_i   (dp_fiq     ),

        .if_ic_o    (if_ic      ),
        .fiq_dp_o   (fiq_dp     )
    );
// --------------------------------------------------------------------
// --------------------------------------------------------------------
// Module name  :   DP_lsq
// Description  :   Dispatcher that support LSQ and SMT
// --------------------------------------------------------------------
    DP_lsq DP_lsq_inst (
        .dp_en_i        (dp_en              ),
        .rob_dp_i       (rob_dp             ),
        .dp_rob_o       (dp_rob             ),
        .mt_dp_i        (mt_dp              ),
        .dp_mt_o        (dp_mt              ),
        .fl_dp_i        (fl_dp              ),
        .dp_fl_o        (dp_fl              ),
        .fiq_dp_i       (fiq_dp             ),
        .dp_fiq_o       (dp_fiq             ),
        .rs_dp_i        (rs_dp              ),
        .dp_rs_o        (dp_rs              ),
        .dp_lsq_o       (dp_lsq             ),
        .lsq_dp_i       (lsq_dp             )
    );

// --------------------------------------------------------------------
// Module name  :   FL_smt
// Description  :   Freelist
// --------------------------------------------------------------------
    FL_smt FL_smt_inst (
    `ifdef DEBUG
        .fl_mon_o       (fl_mon_o       ),
    `endif
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .br_mis_i       (br_mis         ),
        .dp_fl_i        (dp_fl          ),
        .rob_fl_i       (rob_fl         ),
        .fl_dp_o        (fl_dp          ),
        .exception_i    (exception_i    )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   ROB_thread_0
// Description  :   Reorder Buffer
// --------------------------------------------------------------------
    generate
        for(thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++)begin
            ROB ROB_inst (
                //ROB testing
            `ifdef DEBUG
                .rob_mon_o          (rob_mon_o[thread_idx]              ),
                .rob_head_mon_o     (rob_head_mon_o[thread_idx]         ),
                .rob_tail_mon_o     (rob_tail_mon_o[thread_idx]         ),
            `endif
                .clk_i              (clk_i                              ),
                .rst_i              (rst_i                              ),
                .rob_dp_o           (rob_dp[thread_idx]                 ),
                .dp_rob_i           (dp_rob[thread_idx]                 ),
                .cdb_i              (cdb                                ),
                .rob_amt_o          (rob_amt[thread_idx]                ),
                .rob_fl_o           (rob_fl [thread_idx]                ),
                .exception_i        (exception_i                        ),
                .thread_idx_i       (thread_idx[`THREAD_IDX_WIDTH-1:0]  ),
                .br_mis_valid_o     (br_mis.valid[thread_idx]           ),
                .br_target_o        (br_mis.br_target[thread_idx]       ),
                .rob_lsq_o          (rob_lsq[thread_idx]                ),
                .rt_pc_o            (rt_pc_o[thread_idx]                ),
                .rt_valid_o         (rt_valid_o[thread_idx]             ),
                .rt_wfi_o           (rt_wfi_o[thread_idx]               )
            );
        end// for threads
    endgenerate
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   MT_SS
// Description  :   Map Table
// --------------------------------------------------------------------
    generate
        for(thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++)begin
            MT_SS MT_inst (
                 // MT Testing
            `ifdef DEBUG
                .mt_mon_o       (mt_mon_o[thread_idx]                       ),
            `endif
                .clk_i          (clk_i                                      ),
                .rst_i          (rst_i                                      ),
                .rollback_i     (exception_i || br_mis.valid[thread_idx]    ),
                .cdb_i          (cdb                                        ),
                .dp_mt_i        (dp_mt[thread_idx]                          ),
                .amt_i          (amt[thread_idx]                            ),
                .thread_idx_i   (thread_idx[`THREAD_IDX_WIDTH-1:0]          ),
                .mt_dp_o        (mt_dp[thread_idx]                          )
            );
        end
    endgenerate
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   AMT_thread_0
// Description  :   Arch. Map Table
// --------------------------------------------------------------------
    generate
        for(thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++)begin
            AMT AMT_inst (
                .clk_i          (clk_i                                      ),
                .rst_i          (rst_i                                      ),
                .rollback_i     (exception_i || br_mis.valid[thread_idx]    ),
                .thread_idx_i   (thread_idx[`THREAD_IDX_WIDTH-1:0]          ),
                .rob_amt_i      (rob_amt[thread_idx]                        ),
                .amt_o          (amt[thread_idx]                            )
            );
        end
    endgenerate
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   LSQ
// Description  :   Unified Load/Store Queue
// --------------------------------------------------------------------
    generate
        for(thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++)begin
            LSQ LSQ_inst (
            `ifdef DEBUG
                .lsq_array_mon_o    (lsq_array_mon_o[thread_idx]                ),
                .lsq_head_mon_o     (lsq_head_mon_o[thread_idx]                 ),
                .lsq_tail_mon_o     (lsq_tail_mon_o[thread_idx]                 ),
            `endif
                .clk_i              (clk_i                                      ),
                .rst_i              (rst_i                                      ),
                .thread_idx_i       (thread_idx[`THREAD_IDX_WIDTH-1:0]          ),
                .rob_lsq_i          (rob_lsq[thread_idx]                        ),
                .lsq_dp_o           (lsq_dp[thread_idx]                         ),
                .dp_lsq_i           (dp_lsq[thread_idx]                         ),
                .fu_lsq_i           (fu_lsq                                     ),
                .bc_lsq_i           (bc_lsq[thread_idx*`LOAD_NUM+:`LOAD_NUM]    ),
                .lsq_bc_o           (lsq_bc[thread_idx*`LOAD_NUM+:`LOAD_NUM]    ),
                .mem_enable_i       (dcache_grant[thread_idx]                   ),
                .mem_lsq_i          (dcache2proc                                ),
                .lsq_mem_o          (lsq_mem[thread_idx]                        ),
                .br_mis_i           (br_mis                                     )
            );
        end
    endgenerate
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   RS
// Description  :   Reservation Station
// --------------------------------------------------------------------
    RS RS_inst (
        //RS testing
    `ifdef DEBUG
        .rs_mon_o       (rs_mon_o       ),
        .rs_cod_mon_o   (rs_cod_mon_o   ),
    `endif
        // testing end
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
// Module name  :   IB
// Description  :   Issue Buffer
// --------------------------------------------------------------------
    IB IB_inst (
        //IB testing    
    `ifdef DEBUG
        .ALU_queue_mon_o    (ALU_queue_mon_o    ),
        .MULT_queue_mon_o   (MULT_queue_mon_o   ),
        .BR_queue_mon_o     (BR_queue_mon_o     ),
        .LOAD_queue_mon_o   (LOAD_queue_mon_o   ),
        .STORE_queue_mon_o  (STORE_queue_mon_o  ),
        .ALU_valid_mon_o    (ALU_valid_mon_o    ),
        .MULT_valid_mon_o   (MULT_valid_mon_o   ),
        .BR_valid_mon_o     (BR_valid_mon_o     ),
        .LOAD_valid_mon_o   (LOAD_valid_mon_o   ),
        .STORE_valid_mon_o  (STORE_valid_mon_o  ),
        .ALU_head_mon_o     (ALU_head_mon_o     ),
        .ALU_tail_mon_o     (ALU_tail_mon_o     ),
        .MULT_head_mon_o    (MULT_head_mon_o    ),
        .MULT_tail_mon_o    (MULT_tail_mon_o    ),
        .BR_head_mon_o      (BR_head_mon_o      ),
        .BR_tail_mon_o      (BR_tail_mon_o      ),
        .LOAD_head_mon_o    (LOAD_head_mon_o    ),
        .LOAD_tail_mon_o    (LOAD_tail_mon_o    ),
        .STORE_head_mon_o   (STORE_head_mon_o   ),
        .STORE_tail_mon_o   (STORE_tail_mon_o   ),
    `endif
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .ib_rs_o            (ib_rs              ),
        .rs_ib_i            (rs_ib              ),
        .fu_ib_i            (fu_ib              ),
        .ib_fu_o            (ib_fu              ),
        .br_mis_i           (br_mis             ),
        .exception_i        (exception_i        )
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
        .bc_prf_i       (bc_prf         ),
        .prf_mon_o      (prf_mon_o      )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   FU
// Description  :   Functional Units
// --------------------------------------------------------------------
    FU FU_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .ib_fu_i        (ib_fu          ),
        .fu_ib_o        (fu_ib          ),
        .fu_bc_o        (fu_bc          ),
        .bc_fu_i        (bc_fu          ),
        .fu_lsq_o       (fu_lsq         ),
        .lsq_bc_i       (lsq_bc         ),
        .bc_lsq_o       (bc_lsq         ),
        .br_mis_i       (br_mis         ),
        .exception_i    (exception_i    )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   BC
// Description  :   Broadcaster
// --------------------------------------------------------------------
    BC BC_inst (
        .clk_i          (clk_i      ),
        .rst_i          (rst_i      ),
        .fu_bc_i        (fu_bc      ),
        .bc_fu_o        (bc_fu      ),
        .bc_prf_o       (bc_prf     ),
        .cdb_o          (cdb        )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   DC_SW
// Description  :   D-Cache Interface arbitration
// --------------------------------------------------------------------
    dcache_switch DC_SW_inst (
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .lsq_mem_i          (lsq_mem            ),
        .dcache_lsq_i       (dcache2proc        ),
        .dcache_grant_o     (dcache_grant       ),
        .lsq_dcache_o       (proc2dcache        )
    );

// --------------------------------------------------------------------
// Module name  :   DC
// Description  :   D-Cache
// --------------------------------------------------------------------
    dcache DC_inst (
    `ifdef DEBUG
        .mshr_array_mon_o   (dmshr_array_mon_o  ),
        .cache_array_mon_o  (dcache_array_mon_o ),
    `endif
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .proc2cache_i       (proc2dcache        ),
        .cache2proc_o       (dcache2proc        ),
        .memory_enable_i    (memory_grant[0]    ),
        .cache2mem_o        (dcache2mem         ),
        .mem2cache_i        (mem2proc_i         )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   MEM_SW
// Description  :   Memory Interface Switch
// --------------------------------------------------------------------
    mem_switch MEM_SW_inst (
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .req2mem_i          (req2mem            ),
        .mem2switch_i       (mem2proc_i         ),
        .memory_grant_o     (memory_grant       ),
        .switch2mem_o       (proc2mem_o         )   // What is actually sent to the memory
    );
// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

    assign  req2mem[0]  =   dcache2mem  ;
    assign  req2mem[1]  =   icache2mem  ;

    always_ff @(posedge clk_i) begin
        if (rst_i || exception_i) begin
            wfi_flag    <=  `SD 2'b0;
        end else begin
            for (int unsigned th_idx = 0; th_idx < `THREAD_NUM; th_idx++) begin
                if (wfi_retire[th_idx] == 1'b1) begin
                    wfi_flag[th_idx]    <=  `SD 1'b1;
                end
            end
        end        
    end

    always_comb begin
        for (int unsigned th_idx = 0; th_idx < `THREAD_NUM; th_idx++) begin
            wfi_retire[th_idx]  =   1'b0;
            for (int unsigned rt_idx = 0; rt_idx < `RT_NUM; rt_idx++) begin
                if ((rt_valid_o[th_idx][rt_idx] == 1'b1) 
                && (rt_wfi_o[th_idx][rt_idx] == 1'b1)) begin
                    wfi_retire[th_idx]  =   1'b1;
                end
            end
        end
    end

    assign  dp_en   =   ~(wfi_retire | wfi_flag);

    // Testing
`ifdef DEBUG
    //      Fetch
    assign  if_ic_o_t       =   if_ic       ;
    assign  ic_if_o_t       =   ic_if       ;
    //      Dispatch
    assign  dp_rs_mon_o     =   dp_rs       ;
    always_comb begin
        for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++)begin
            dp_mt_mon_o[thread_idx]     =   dp_mt[thread_idx]       ;
            mt_dp_mon_o[thread_idx]     =   mt_dp[thread_idx]       ;
            amt_mon_o[thread_idx]       =   amt[thread_idx]         ; 
        end
    end
    //      Issue
    assign  rs_ib_mon_o     =   rs_ib       ;
    //      Execute
    assign  ib_fu_mon_o     =   ib_fu       ;
    //      Complete
    assign  fu_bc_mon_o     =   fu_bc       ;
    assign  cdb_mon_o       =   cdb         ;
    //      Retire
    assign  br_mis_mon_o    =   br_mis      ;
    always_comb begin
        for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++)begin
            rob_amt_mon_o[thread_idx]   =   rob_amt[thread_idx]     ;
            rob_fl_mon_o [thread_idx]   =   rob_fl [thread_idx]     ;
        end
    end

`endif

// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule