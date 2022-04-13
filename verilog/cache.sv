/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  cache.sv                                            //
//                                                                     //
//  Description :  Non-blocking N-way set associative cache.           // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module cache (
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
