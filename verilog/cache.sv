/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  cache.sv                                            //
//                                                                     //
//  Description :  Non-blocking N-way set associative cache.           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module cache #(
    parameter   C_CACHE_SIZE            =   `CACHE_SIZE         ,
    parameter   C_CACHE_BLOCK_SIZE      =   `CACHE_BLOCK_SIZE   ,
    parameter   C_CACHE_SASS            =   `CACHE_SASS         ,
    parameter   C_CACHE_SET_NUM         =   (C_CACHE_SIZE / C_CACHE_BLOCK_SIZE / C_CACHE_SASS),
    parameter   C_MSHR_ENTRY_NUM        =   `MSHR_ENTRY_NUM
) (
    // For Testing
    output  MSHR_ENTRY      [C_MSHR_ENTRY_NUM-1:0]                  mshr_array_mon_o    ,
    output  CACHE_MEM_ENTRY [C_CACHE_SET_NUM-1:0][C_CACHE_SASS-1:0] cache_array_mon_o   ,

    input   logic               clk_i               ,   //  Clock
    input   logic               rst_i               ,   //  Reset
    // Processor Interface
    input   MEM_IN              proc2cache_i              ,
    output  MEM_OUT             cache2proc_o              ,
    // Memory Interface
    output  MEM_IN              cache2mem_o               ,
    input   MEM_OUT             mem2cache_i               
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    CACHE_CTRL_MEM      cache_ctrl_mem          ;
    CACHE_MEM_CTRL      cache_mem_ctrl          ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   cache_ctrl
// Description  :   Non-blocking cache controller
// --------------------------------------------------------------------
    cache_ctrl cache_ctrl_inst (
        .mshr_array_mon_o   (mshr_array_mon_o   ),
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .proc2cache_i       (proc2cache_i       ),
        .cache2proc_o       (cache2proc_o       ),
        .cache2mem_o        (cache2mem_o        ),
        .mem2cache_i        (mem2cache_i        ),
        .cache_ctrl_mem_o   (cache_ctrl_mem     ),
        .cache_mem_ctrl_i   (cache_mem_ctrl     )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   cache_mem
// Description  :   Cache memory
// --------------------------------------------------------------------
    cache_mem cache_mem_inst (
        .cache_array_mon_o  (cache_array_mon_o  ),
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .cache_ctrl_mem_i   (cache_ctrl_mem     ),
        .cache_mem_ctrl_o   (cache_mem_ctrl     )
    );
// --------------------------------------------------------------------
// ====================================================================
// Module Instantiations End
// ====================================================================

endmodule
