/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  cache_ctrl.sv                                       //
//                                                                     //
//  Description :  cache_ctrl                                          // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module cache_ctrl #(
    parameter   C_XLEN              =   `XLEN               ,
    parameter   C_CACHE_SIZE        =   `CACHE_SIZE         ,
    parameter   C_CACHE_BLOCK_SIZE  =   `CACHE_BLOCK_SIZE   ,
    parameter   C_CACHE_SASS        =   `CACHE_SASS         ,
    parameter   C_MSHR_ENTRY_NUM    =   `MSHR_ENTRY_NUM     
) (
    input   logic               clk_i               ,   //  Clock
    input   logic               rst_i               ,   //  Reset
    // Processor Interface
    input   MEM_IN              proc2cache_i        ,
    output  MEM_OUT             cache2proc_o        ,
    // Memory Interface
    output  MEM_IN              cache2mem_o         ,
    input   MEM_OUT             mem2cache_i         ,
    // Cache-memory Interface
    output  CACHE_CTRL_MEM      cache_ctrl_mem_o    ,  
    input   CACHE_MEM_CTRL      cache_mem_ctrl_i    
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_CACHE_OFFSET_WIDTH    =   $clog2(C_CACHE_BLOCK_SIZE);
    localparam  C_CACHE_IDX_WIDTH       =   $clog2(C_CACHE_SIZE / C_CACHE_BLOCK_SIZE / C_CACHE_SASS);
    localparam  C_CACHE_TAG_WIDTH       =   C_XLEN - C_CACHE_IDX_WIDTH - C_CACHE_OFFSET_WIDTH;
    localparam  C_MSHR_IDX_WIDTH        =   $clog2(C_MSHR_ENTRY_NUM);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // MSHR array
    MSHR_ENTRY      [C_MSHR_ENTRY_NUM-1:0]                              mshr_array              ;

    // Dispatch
    logic           [C_MSHR_ENTRY_NUM-1:0]                              dp_sel                  ;
    
    // Complete
    logic           [C_MSHR_ENTRY_NUM-1:0]                              cp_flag                 ;
    logic           [C_MSHR_ENTRY_NUM-1:0][C_CACHE_BLOCK_SIZE*8-1:0]    cp_data                 ;
    // Dependency Detection
    logic                                                               mshr_hit                ;
    logic           [C_MSHR_IDX_WIDTH-1:0]                              mshr_hit_idx            ;
    logic                                                               evict_hit               ;
    logic           [C_MSHR_IDX_WIDTH-1:0]                              evict_hit_idx           ;

    // Processor Interface Arbitration
    MEM_OUT         [C_MSHR_ENTRY_NUM-1:0]                              mshr_proc               ;
    logic           [C_MSHR_ENTRY_NUM-1:0]                              proc_grant              ;

    // Memory Interface Arbitration
    MEM_IN          [C_MSHR_ENTRY_NUM-1:0]                              mshr_memory             ;
    logic           [C_MSHR_ENTRY_NUM-1:0]                              memory_grant            ;

    // cache_mem Interface Arbitration
    CACHE_CTRL_MEM  [C_MSHR_ENTRY_NUM-1:0]                              mshr_cache_mem          ;
    logic           [C_MSHR_ENTRY_NUM-1:0]                              cache_mem_grant         ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   mshr_fsm
// Description  :   FSM for each entry
// --------------------------------------------------------------------
    genvar  entry_idx   ;
    generate
        for (entry_idx = 1; entry_idx < C_MSHR_ENTRY_NUM; entry_idx++) begin
            mshr_entry_ctrl mshr_entry_ctrl_inst (
                .clk_i              (clk_i                              ),
                .rst_i              (rst_i                              ),
                .mshr_entry_idx_i   (entry_idx[C_MSHR_IDX_WIDTH-1:0]    ),
                .mshr_entry_o       (mshr_array[entry_idx]              ),
                .proc_grant_i       (proc_grant[entry_idx]              ),
                .proc2cache_i       (proc2cache_i                       ),
                .mshr_proc_o        (mshr_proc[entry_idx]               ),
                .cache_mem_grant_i  (cache_mem_grant[entry_idx]         ),
                .cache_mem_ctrl_i   (cache_mem_ctrl_i                   ),
                .mshr_cache_mem_o   (mshr_cache_mem[entry_idx]          ),
                .memory_grant_i     (memory_grant[entry_idx]            ),
                .mem2cache_i        (mem2cache_i                        ),
                .mshr_memory_o      (mshr_memory[entry_idx]             ),
                .mshr_hit_i         (mshr_hit                           ),
                .mshr_hit_idx_i     (mshr_hit_idx                       ),
                .evict_hit_i        (evict_hit                          ),
                .evict_hit_idx_i    (evict_hit_idx                      ),
                .dp_sel_i           (dp_sel[entry_idx]                  ),
                .mshr_cp_flag_o     (cp_flag[entry_idx]                 ),
                .mshr_cp_data_o     (cp_data[entry_idx]                 ),
                .cp_flag_i          (cp_flag                            ),
                .cp_data_i          (cp_data                            )
            );
        end
    endgenerate
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mshr_dispatch_selector
// Description  :   Select a empty MSHR entry for the new request
//                  from processor
// --------------------------------------------------------------------
    mshr_dispatch_selector mshr_dispatch_selector_inst (
        .mshr_array_i   (mshr_array ),
        .dp_sel_o       (dp_sel     )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mshr_hit_detector
// Description  :   Compare the address from pocessor with the req_addr
//                  of the valid MSHR entries.
// --------------------------------------------------------------------
    mshr_hit_detector mshr_hit_detector_inst (
        .proc2cache_i       (proc2cache_i   ),
        .mshr_array_i       (mshr_array     ),
        .mshr_hit_o         (mshr_hit       ),
        .mshr_hit_idx_o     (mshr_hit_idx   )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   evict_hit_detector
// Description  :   Compare the address from pocessor with the req_addr
//                  of the valid MSHR entries.
// --------------------------------------------------------------------
    evict_hit_detector evict_hit_detector_inst (
        .proc2cache_i       (proc2cache_i   ),
        .mshr_array_i       (mshr_array     ),
        .evict_hit_o        (evict_hit      ),
        .evict_hit_idx_o    (evict_hit_idx  )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mshr_proc_switch
// Description  :   Schedule the access of MSHR entries to 
//                  Processor Interface.
// --------------------------------------------------------------------
    mshr_proc_switch mshr_proc_switch_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .mshr_proc_i    (mshr_proc      ),
        .proc_grant_o   (proc_grant     ),
        .cache2proc_o   (cache2proc_o   )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mshr_memory_switch
// Description  :   Schedule the access of MSHR entries to 
//                  Memory Interface.
// --------------------------------------------------------------------
    mshr_memory_switch mshr_memory_switch_inst (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .mshr_memory_i  (mshr_memory    ),
        .mem2cache_i    (mem2cache_i    ),
        .memory_grant_o (memory_grant   ),
        .cache2mem_o    (cache2mem_o    )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   mshr_cache_mem_switch
// Description  :   Schedule the access of MSHR entries to
//                  the interface between cache_ctrl and cache_mem.
// --------------------------------------------------------------------
    mshr_cache_mem_switch mshr_cache_mem_switch_inst (
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .mshr_cache_mem_i   (mshr_cache_mem     ),
        .cache_mem_grant_o  (cache_mem_grant    ),
        .cache_ctrl_mem_o   (cache_ctrl_mem_o   )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    always_comb begin
        mshr_array[0]       =   'd0 ;
        mshr_memory[0]      =   'd0 ;
        mshr_proc[0]        =   'd0 ;
        mshr_cache_mem[0]   =   'd0 ;
        cp_data[0]          =   'b0 ;
        cp_flag[0]          =   1'b0;
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
