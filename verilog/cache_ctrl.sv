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
    input   MEM_IN              proc_i              ,
    output  MEM_OUT             proc_o              ,
    // Memory Interface
    output  MEM_IN              mem_o               ,
    input   MEM_OUT             mem_i               ,
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
    MSHR_ENTRY      [C_MSHR_ENTRY_NUM-1:0]      mshr_array              ;
    MSHR_ENTRY      [C_MSHR_ENTRY_NUM-1:0]      next_mshr_array         ;
    logic           [C_MSHR_ENTRY_NUM-1:0]      dp_sel                  ;
    logic                                       dp_idx_valid            ;
    logic           [C_MSHR_IDX_WIDTH-1:0]      dp_idx                  ;
    logic           [C_MSHR_ENTRY_NUM-1:0]      cp_sel                  ;
    MEM_OUT         [C_MSHR_ENTRY_NUM-1:0]      mem_out                 ;
    MEM_IN          [C_MSHR_ENTRY_NUM-1:0]      mem_in                  ;
    logic                                       mshr_hit                ;
    logic           [C_MSHR_IDX_WIDTH-1:0]      mshr_hit_idx            ;

    // Memory Interface Arbitration
    MEM_IN          [C_MSHR_ENTRY_NUM-1:0]      mshr_memory             ;
    logic           [C_MSHR_ENTRY_NUM-1:0]      memory_grant            ;

    // CACHE_CTRL_MEM Interface Arbitration
    CACHE_CTRL_MEM  [C_MSHR_ENTRY_NUM-1:0]      mshr_cache_mem          ;
    logic           [C_MSHR_ENTRY_NUM-1:0]      cache_mem_grant         ;

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
    genvar  i   ;
    generate
        for (i = 0; i < C_MSHR_ENTRY_NUM; i++) begin
            mshr_fsm mshr_fsm_inst (
                .cstate_i           (mshr_array[i].state            ),
                .nstate_o           (next_mshr_array[i].state       ),
                .bus_cmd_i          (proc_i.command                 ),
                .cache_mem_grant_i  (cache_mem_grant[i]             ),
                .memory_grant_i     (memory_grant[i]                ),
                .cache_mem_hit_i    (cache_mem_ctrl_i.req_hit       ),
                .mshr_hit_i         (mshr_hit                       ),
                .dp_sel_i           (dp_sel[i]                      ),
                .cp_sel_i           (cp_sel[mshr_array[i].link_idx] ),
                .mem_response_i     (mem_i.response                 ),
                .mem_tag_i          (mem_i.tag                      ),
                .entry_tag_i        (mshr_array[i].tag              ),
                .evict_dirty_i      (cache_mem_ctrl_i.evict_dirty   )
            );
        end
    endgenerate
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
        .memory_grant_o (memory_grant   ),
        .mem_o          (mem_o          )
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

// --------------------------------------------------------------------
// MSHR State update
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        for (int unsigned entry_idx = 0; entry_idx < C_MSHR_ENTRY_NUM; entry_idx++) begin
            if (rst_i) begin
                mshr_array[i].state <=  `SD ST_IDLE;
            end else begin
                mshr_array[i].state <=  `SD next_mshr_array[i].state;
            end
        end
    end

// --------------------------------------------------------------------
// MSHR hit detection
// --------------------------------------------------------------------
    always_comb begin
        mshr_hit        =   1'b0;
        mshr_hit_idx    =   'd0;
        if (proc_i.command != BUS_NONE) begin
            for (int unsigned entry_idx = 0; entry_idx < C_MSHR_ENTRY_NUM; entry_idx++) begin
                // IF   the entry content is valid
                // AND  the address from processor matches the address of current entry
                // AND  current entry is the least older miss to this address
                // ->   MSHR hit is detected
                if ((mshr_array[entry_idx].cmd != BUS_NONE)
                &&  (mshr_array[entry_idx].req_addr[C_XLEN-1:C_CACHE_OFFSET_WIDTH] == proc_i.addr[C_XLEN-1:C_CACHE_OFFSET_WIDTH])
                &&  (mshr_array[entry_idx].linked == 1'b0)) begin
                    mshr_hit        =   1'b1;
                    mshr_hit_idx    =   entry_idx;
                end
            end
        end
    end

// --------------------------------------------------------------------
// MSHR dispatch select
// --------------------------------------------------------------------
    always_comb begin
        // Scan through the empty entry, and select the one with smallest index
        dp_idx          =   'd0;
        dp_idx_valid    =   1'b0;
        for (int unsigned entry_idx = C_MSHR_ENTRY_NUM - 1; entry_idx > 0; entry_idx--) begin
            if (mshr_array[entry_idx].cmd == BUS_NONE) begin
                dp_idx          =   entry_idx;
                dp_idx_valid    =   1'b1;
            end
        end

        // Generate per-entry dp_sel
        dp_sel  =   'b0;
        if (dp_idx_valid) begin
            dp_sel  =   {{(C_MSHR_ENTRY_NUM-1){1'b0}}, 1'b1} << dp_idx;
        end
    end

// --------------------------------------------------------------------
// MSHR complete select
// --------------------------------------------------------------------
    always_comb begin
        cp_sel  =   'b0;
        for (int unsigned entry_idx = 0; entry_idx < C_MSHR_ENTRY_NUM; entry_idx++) begin
            // Assert when the miss handling is completed
            // by observing the FSM transition.
            if ((mshr_array[entry_idx].state != ST_IDLE)
            &&  (next_mshr_array[entry_idx].state == ST_IDLE)) begin
                cp_sel[entry_idx]   =   1'b1;
            end
        end
    end

// --------------------------------------------------------------------
// MSHR entry update
// --------------------------------------------------------------------
    always_comb begin


    end


// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
