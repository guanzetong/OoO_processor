/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mshr_entry_ctrl.sv                                  //
//                                                                     //
//  Description :  Finite State Machine to derive the state of a       //
//                 MSHR entry.                                         // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mshr_entry_ctrl #(
    parameter   C_MSHR_ENTRY_NUM    =   `MSHR_ENTRY_NUM             ,
    parameter   C_CACHE_BLOCK_SIZE  =   `CACHE_BLOCK_SIZE           ,
    localparam  C_MSHR_IDX_WIDTH    =   $clog2(C_MSHR_ENTRY_NUM)
) (
    input   logic                           clk_i               ,   //  Clock
    input   logic                           rst_i               ,   //  Reset
    //  MSHR contents
    input   logic   [C_MSHR_IDX_WIDTH-1:0]  mshr_entry_idx_i    ,   //  MSHR entry index
    output  MSHR_ENTRY                      mshr_entry_o        ,   //  MSHR entry contents
    //  Processor Interface
    input   MEM_IN                          proc_i              ,   //  Interface input
    output  MEM_OUT                         proc_o              ,   //  Interface output
    //  cache_mem Interface
    input   logic                           cache_mem_grant_i   ,   //  Indicate if the cache_mem Interface is granted to this entry
    input   CACHE_MEM_CTRL                  cache_mem_ctrl_i    ,   //  Interface input
    output  CACHE_CTRL_MEM                  mshr_cache_mem_o    ,   //  Interface output
    //  Memory Interface
    input   logic                           memory_grant_i      ,   //  Indicate if the Memory Interface is granted to this entry
    input   MEM_OUT                         mem_i               ,   //  Interface input
    output  MEM_IN                          mshr_memory_o       ,
    //  MSHR array global control         
    input   logic                           mshr_hit_i          ,   //  Indicate if there is a match of miss address in MSHR
    input   logic                           mshr_hit_idx_i      ,   //  The index of entry whose req_addr matches the address from processor
    input   logic                           dp_sel_i            ,   //  Dispatch select
    input   logic   [C_MSHR_ENTRY_NUM-1:0]  cp_sel_i                //  Complete select of the older miss to the same address
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
    MSHR_ENTRY                          mshr_entry          ;
    MSHR_ENTRY                          next_mshr_entry     ;

    logic   [`CACHE_BLOCK_SIZE*8-1:0]   wr_data             ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// FSM and MSHR entry update
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mshr_entry.state        <=  `SD ST_IDLE     ;
            mshr_entry.cmd          <=  `SD BUS_NONE    ;
            mshr_entry.req_addr     <=  `SD 'b0         ;
            mshr_entry.req_size     <=  `SD BYTE        ;
            mshr_entry.evict_addr   <=  `SD 'b0         ;
            mshr_entry.data         <=  `SD 'b0         ;
            mshr_entry.link_idx     <=  `SD 'd0         ;
            mshr_entry.mem_tag      <=  `SD 'd0         ;
        end else begin
            mshr_entry              <=  `SD next_mshr_entry;
        end
    end

    always_comb begin
        next_mshr_entry.state       =   mshr_entry.state        ;
        next_mshr_entry.cmd         =   mshr_entry.cmd          ;
        next_mshr_entry.req_addr    =   mshr_entry.req_addr     ;
        next_mshr_entry.req_size    =   mshr_entry.req_size     ;
        next_mshr_entry.evict_addr  =   mshr_entry.evict_addr   ;
        next_mshr_entry.data        =   mshr_entry.data         ;
        next_mshr_entry.link_idx    =   mshr_entry.link_idx     ;
        next_mshr_entry.linked      =   mshr_entry.linked       ;
        next_mshr_entry.mem_tag     =   mshr_entry.mem_tag      ;
        case (mshr_entry.state)
            ST_IDLE     :   begin
                // IF   there is a valid transaction on Processor Interface
                // AND  the cache_mem Interface is granted to this entry
                // AND  it is a miss
                // AND  the entry is selected to hold the new miss
                if ((proc_i.command != BUS_NONE) && (cache_mem_grant_i == 1'b1)
                && (cache_mem_ctrl_i.req_hit == 1'b0) && (dp_sel_i == 1'b1)) begin
                    // IF   there is an older transaction to the same addreess
                    // ->   Wait for the completion of older miss to the same address
                    if (mshr_hit_i) begin
                        next_mshr_entry.state   =   ST_DEPEND   ;
                    // ELSE
                    // ->   Read from Memory
                    end else begin
                        next_mshr_entry.state   =   ST_RD_MEM   ;
                    end
                    next_mshr_entry.cmd         =   proc_i.command  ;
                    next_mshr_entry.req_addr    =   proc_i.addr     ;
                    next_mshr_entry.req_size    =   proc_i.size     ;
                    next_mshr_entry.data        =   proc_i.data     ;
                    next_mshr_entry.link_idx    =   mshr_hit_idx    ;
                end
            end
            ST_DEPEND   :   begin
                // IF   the older transaction the entry is linked to completed
                // ->   Update the cache data
                if (cp_sel_i[mshr_entry.link_idx] == 1'b1) begin
                    next_mshr_entry.state       =   ST_UPDATE   ;
                    next_mshr_entry.link_idx    =   'd0         ;
                end
            end
            ST_RD_MEM   :   begin
                // IF   the read transaction is confirmed by Memory Interface
                // ->   Wait for the data to return from Memory
                if ((memory_grant_i == 1'b1) && (mem_i.response != 'd0)) begin
                    next_mshr_entry.state       =   ST_WAIT_MEM     ;
                    next_mshr_entry.mem_tag     =   mem_i.response  ;
                end
            end
            ST_WAIT_MEM :   begin
                // IF   the data is returned from the Memory
                // ->   Update the cache data
                if (mem_i.tag == mshr_entry.mem_tag) begin
                    next_mshr_entry.state   =   ST_UPDATE   ;
                    next_mshr_entry.data    =   mem_i.data  ;
                    if (mshr_entry.cmd == BUS_STORE) begin
                        case (mshr_entry.req_size)
                            BYTE    :   next_mshr_entry.data[mshr_entry.req_addr[2:0] +:  8]    =   mshr_entry.data[ 7:0]   ;
                            HALF    :   next_mshr_entry.data[mshr_entry.req_addr[2:0] +: 16]    =   mshr_entry.data[15:0]   ;
                            WORD    :   next_mshr_entry.data[mshr_entry.req_addr[2:0] +: 32]    =   mshr_entry.data[31:0]   ;
                            DOUBLE  :   next_mshr_entry.data                                    =   mshr_entry.data         ;
                            default :   next_mshr_entry.data                                    =   mshr_entry.data         ;
                        endcase
                    end
                end
            end
            ST_UPDATE   :   begin
                // IF   the req interface is granted to this entry
                if (cache_mem_grant_i == 1'b1) begin
                    // IF   a dirty block is evicted
                    // ->   Write back the evicted block
                    if (cache_mem_ctrl_i.evict_dirty == 1'b1) begin
                        next_mshr_entry.state       =   ST_EVICT;
                        next_mshr_entry.evict_addr  =   cache_mem_ctrl_i.evict_addr;
                        next_mshr_entry.data        =   cache_mem_ctrl_i.evict_data;
                    // ELSE
                    // ->   Miss Handling Completed
                    end else begin
                        next_mshr_entry.state       =   ST_IDLE     ;
                        next_mshr_entry.cmd         =   BUS_NONE    ;
                        next_mshr_entry.req_addr    =   'b0         ;
                        next_mshr_entry.req_size    =   BYTE        ;
                        next_mshr_entry.evict_addr  =   'b0         ;
                        next_mshr_entry.data        =   'b0         ;
                        next_mshr_entry.link_idx    =   'd0         ;
                        next_mshr_entry.mem_tag     =   'd0         ;
                    end
                end
            end
            ST_EVICT    :   begin
                // IF   the write back transaction to Memory is confirmed
                // ->   Miss Handling Completed
                if ((memory_grant_i == 1'b1) && (mem_i.response != 'd0)) begin
                    next_mshr_entry.state       =   ST_IDLE     ;
                    next_mshr_entry.cmd         =   BUS_NONE    ;
                    next_mshr_entry.req_addr    =   'b0         ;
                    next_mshr_entry.req_size    =   BYTE        ;
                    next_mshr_entry.evict_addr  =   'b0         ;
                    next_mshr_entry.data        =   'b0         ;
                    next_mshr_entry.link_idx    =   'd0         ;
                    next_mshr_entry.mem_tag     =   'd0         ;
                end
            end
            default     :   begin
                next_mshr_entry.state   =   ST_IDLE ;
            end
        endcase

        if (next_mshr_entry.state == ST_IDLE) begin
            next_mshr_entry.linked  =   1'b0;
        end else if ((mshr_hit_i == 1'b1) && (mshr_hit_idx_i == mshr_entry_idx_i)) begin
            next_mshr_entry.linked  =   1'b1;
        end
    end

// --------------------------------------------------------------------
// 
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
