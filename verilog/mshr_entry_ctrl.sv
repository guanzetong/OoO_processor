/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mshr_entry_ctrl.sv                                  //
//                                                                     //
//  Description :  Finite State Machine to derive the state of a       //
//                 MSHR entry.                                         // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mshr_entry_ctrl #(
    parameter   C_XLEN              =   `XLEN                       ,
    parameter   C_MSHR_ENTRY_NUM    =   `MSHR_ENTRY_NUM             ,
    parameter   C_CACHE_BLOCK_SIZE  =   `CACHE_BLOCK_SIZE           ,
    parameter   C_MSHR_IDX_WIDTH    =   $clog2(C_MSHR_ENTRY_NUM)
) (
    input   logic                                                       clk_i               ,   //  Clock
    input   logic                                                       rst_i               ,   //  Reset
    //  MSHR contents
    input   logic   [C_MSHR_IDX_WIDTH-1:0]                              mshr_entry_idx_i    ,   //  MSHR entry index
    output  MSHR_ENTRY                                                  mshr_entry_o        ,   //  MSHR entry contents
    //  Processor Interface
    input   logic                                                       proc_grant_i        ,
    input   MEM_IN                                                      proc2cache_i        ,   //  Interface input
    output  MEM_OUT                                                     mshr_proc_o         ,   //  Interface output
    //  cache_mem Interface
    input   logic                                                       cache_mem_grant_i   ,   //  Indicate if the cache_mem Interface is granted to this entry
    input   CACHE_MEM_CTRL                                              cache_mem_ctrl_i    ,   //  Interface input
    output  CACHE_CTRL_MEM                                              mshr_cache_mem_o    ,   //  Interface output
    //  Memory Interface
    input   logic                                                       memory_grant_i      ,   //  Indicate if the Memory Interface is granted to this entry
    input   MEM_OUT                                                     mem2cache_i         ,   //  Interface input
    output  MEM_IN                                                      mshr_memory_o       ,
    //  Hit Detection        
    input   logic                                                       mshr_hit_i          ,   //  Indicate if there is a match of miss address in MSHR
    input   logic   [C_MSHR_IDX_WIDTH-1:0]                              mshr_hit_idx_i      ,   //  The index of entry whose req_addr matches the address from processor
    input   logic                                                       evict_hit_i         ,   //  Indicate if there is a match of evict address in MSHR
    input   logic   [C_MSHR_IDX_WIDTH-1:0]                              evict_hit_idx_i     ,   //  The index of entry whose evict_addr matches the address from processor
    //  Dispatch
    input   logic                                                       dp_sel_i            ,   //  Dispatch select
    //  Complete
    output  logic                                                       mshr_cp_flag_o      ,   //  Complete flag of this entry
    output  logic   [C_CACHE_BLOCK_SIZE*8-1:0]                          mshr_cp_data_o      ,   //  The data written to cache_mem by this entry
    input   logic   [C_MSHR_ENTRY_NUM-1:0]                              cp_flag_i           ,   //  Complete flags of each entries
    input   logic   [C_MSHR_ENTRY_NUM-1:0][C_CACHE_BLOCK_SIZE*8-1:0]    cp_data_i               //  The data written to cache by each entry
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_CACHE_OFFSET_WIDTH    =   $clog2(C_CACHE_BLOCK_SIZE);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    MSHR_ENTRY                          mshr_entry          ;
    MSHR_ENTRY                          next_mshr_entry     ;

    logic                               next_mshr_cp_flag   ;
    logic   [C_CACHE_BLOCK_SIZE*8-1:0]  next_mshr_cp_data   ;

    logic   [C_CACHE_OFFSET_WIDTH-1:0]  input_data_offset   ;
    logic   [C_CACHE_OFFSET_WIDTH-1:0]  output_data_offset  ;
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
            mshr_entry.req_data     <=  `SD 'b0         ;
            mshr_entry.req_size     <=  `SD BYTE        ;
            mshr_entry.evict_addr   <=  `SD 'b0         ;
            mshr_entry.evict_data   <=  `SD 'b0         ;
            mshr_entry.evict_dirty  <=  `SD 1'b0        ;
            mshr_entry.link_idx     <=  `SD 'd0         ;
            mshr_entry.linked       <=  `SD 1'b0        ;
            mshr_entry.mem_tag      <=  `SD 'd0         ;
            mshr_cp_flag_o          <=  `SD 1'b0        ;
            mshr_cp_data_o          <=  `SD 'b0         ;
        end else begin
            mshr_entry              <=  `SD next_mshr_entry     ;
            mshr_cp_flag_o          <=  `SD next_mshr_cp_flag   ;
            mshr_cp_data_o          <=  `SD next_mshr_cp_data   ;
        end
    end

    always_comb begin
        next_mshr_entry.state       =   mshr_entry.state        ;
        next_mshr_entry.cmd         =   mshr_entry.cmd          ;
        next_mshr_entry.req_addr    =   mshr_entry.req_addr     ;
        next_mshr_entry.req_data    =   mshr_entry.req_data     ;
        next_mshr_entry.req_size    =   mshr_entry.req_size     ;
        next_mshr_entry.evict_addr  =   mshr_entry.evict_addr   ;
        next_mshr_entry.evict_data  =   mshr_entry.evict_data   ;
        next_mshr_entry.evict_dirty =   mshr_entry.evict_dirty  ;
        next_mshr_entry.link_idx    =   mshr_entry.link_idx     ;
        next_mshr_entry.linked      =   mshr_entry.linked       ;
        next_mshr_entry.mem_tag     =   mshr_entry.mem_tag      ;
        next_mshr_cp_flag           =   mshr_cp_flag_o          ;
        next_mshr_cp_data           =   mshr_cp_data_o          ;
        input_data_offset           =   'b0                     ;
        case (mshr_entry.state)
            ST_IDLE     :   begin
                // IF   there is a valid transaction on Processor Interface
                // AND  the Processor Interface is granted to this entry
                // AND  the cache_mem Interface is granted to this entry
                // AND  it is a miss
                // AND  the entry is selected to hold the new miss
                if ((proc2cache_i.command != BUS_NONE) && (dp_sel_i == 1'b1)
                && (proc_grant_i == 1'b1)) begin
                    // IF   there is an older in-flight transaction to the same addreess
                    // ->   Wait for the completion of older miss to the same address
                    if (mshr_hit_i && (cp_flag_i[mshr_hit_idx_i] == 1'b0)) begin
                        next_mshr_entry.state       =   ST_WAIT_DEPEND          ;
                        next_mshr_entry.link_idx    =   mshr_hit_idx_i          ;
                        next_mshr_entry.cmd         =   proc2cache_i.command    ;
                        next_mshr_entry.req_addr    =   proc2cache_i.addr       ;
                        next_mshr_entry.req_size    =   proc2cache_i.size       ;
                        if (proc2cache_i.command == BUS_STORE) begin
                            next_mshr_entry.req_data    =   proc2cache_i.data   ;
                        end
                    // IF   there is an older in-flight transaction that is in the middle of evicting the data block
                    // ->   Wait for the completion of write-back to memory
                    end else if (evict_hit_i && (cp_flag_i[evict_hit_idx_i] == 1'b0)) begin
                        next_mshr_entry.state       =   ST_WAIT_EVICT           ;
                        next_mshr_entry.link_idx    =   evict_hit_idx_i         ;
                        next_mshr_entry.cmd         =   proc2cache_i.command    ;
                        next_mshr_entry.req_addr    =   proc2cache_i.addr       ;
                        next_mshr_entry.req_size    =   proc2cache_i.size       ;
                        if (proc2cache_i.command == BUS_STORE) begin
                            next_mshr_entry.req_data    =   proc2cache_i.data   ;
                        end
                    // IF   it is a miss, and no dependency to older in-flight transactions.
                    // ->   Start miss handling
                    end else if ((cache_mem_ctrl_i.req_hit == 1'b0) && (cache_mem_grant_i == 1'b1)) begin
                        next_mshr_entry.state       =   ST_RD_MEM               ;
                        next_mshr_entry.link_idx    =   'd0                     ;
                        next_mshr_entry.cmd         =   proc2cache_i.command    ;
                        next_mshr_entry.req_addr    =   proc2cache_i.addr       ;
                        next_mshr_entry.req_size    =   proc2cache_i.size       ;
                        if (proc2cache_i.command == BUS_STORE) begin
                            next_mshr_entry.req_data    =   proc2cache_i.data   ;
                        end
                    end
                end
                next_mshr_cp_flag   =   1'b0    ;
                next_mshr_cp_data   =   'b0     ;
            end
            ST_WAIT_DEPEND  :   begin
                // IF   the older transaction that the entry is linked to completed
                // ->   Update the cache data
                if (cp_flag_i[mshr_entry.link_idx] == 1'b1) begin
                    next_mshr_entry.state       =   ST_UPDATE   ;
                    next_mshr_entry.link_idx    =   'd0         ;
                    next_mshr_entry.req_data    =   cp_data_i[mshr_entry.link_idx];
                    if (mshr_entry.cmd == BUS_STORE) begin
                        case (mshr_entry.req_size)
                            BYTE    :   begin
                                input_data_offset   =   mshr_entry.req_addr[2:0];
                                next_mshr_entry.req_data[input_data_offset +:  8] =   mshr_entry.req_data[ 7:0]   ;
                            end
                            HALF    :   begin
                                input_data_offset   =   {mshr_entry.req_addr[2:1], 1'b0};
                                next_mshr_entry.req_data[input_data_offset +: 16] =   mshr_entry.req_data[15:0]   ;
                            end
                            WORD    :   begin
                                input_data_offset   =   {mshr_entry.req_addr[2], 2'b0};
                                next_mshr_entry.req_data[input_data_offset +: 32] =   mshr_entry.req_data[31:0]   ;
                            end
                            DOUBLE  :   begin
                                next_mshr_entry.req_data    =   mshr_entry.req_data ;
                            end
                            default :   begin
                                next_mshr_entry.req_data    =   mshr_entry.req_data ;
                            end
                        endcase
                    end
                end
            end
            ST_WAIT_EVICT   : begin
                // IF   the older transaction that evicts the cache block completed
                // ->   Read from Memory
                if (cp_flag_i[mshr_entry.link_idx] == 1'b1) begin
                    next_mshr_entry.state       =   ST_RD_MEM   ;
                    next_mshr_entry.link_idx    =   'd0         ;
                end
            end
            ST_RD_MEM   :   begin
                // IF   the read transaction is confirmed by Memory Interface
                // ->   Wait for the data to return from Memory
                if ((memory_grant_i == 1'b1) && (mem2cache_i.response != 'd0)) begin
                    next_mshr_entry.state       =   ST_WAIT_MEM             ;
                    next_mshr_entry.mem_tag     =   mem2cache_i.response    ;
                end
            end
            ST_WAIT_MEM :   begin
                // IF   the data is returned from the Memory
                // ->   Update the cache data
                if (mem2cache_i.tag == mshr_entry.mem_tag) begin
                    next_mshr_entry.state       =   ST_UPDATE           ;
                    next_mshr_entry.req_data    =   mem2cache_i.data    ;
                    if (mshr_entry.cmd == BUS_STORE) begin
                        case (mshr_entry.req_size)
                            BYTE    :   begin
                                input_data_offset   =   mshr_entry.req_addr[2:0];
                                next_mshr_entry.req_data[input_data_offset +:  8] =   mshr_entry.req_data[ 7:0]   ;
                            end
                            HALF    :   begin
                                input_data_offset   =   {mshr_entry.req_addr[2:1], 1'b0};
                                next_mshr_entry.req_data[input_data_offset +: 16] =   mshr_entry.req_data[15:0]   ;
                            end
                            WORD    :   begin
                                input_data_offset   =   {mshr_entry.req_addr[2], 2'b0};
                                next_mshr_entry.req_data[input_data_offset +: 32] =   mshr_entry.req_data[31:0]   ;
                            end
                            DOUBLE  :   begin
                                next_mshr_entry.req_data    =   mshr_entry.req_data ;
                            end
                            default :   begin
                                next_mshr_entry.req_data    =   mshr_entry.req_data ;
                            end
                        endcase
                    end
                end
            end
            ST_UPDATE   :   begin
                // IF   the req interface is granted to this entry
                if (cache_mem_grant_i == 1'b1) begin
                    // IF   it is a load miss
                    // ->   Output data to processor
                    if (mshr_entry.cmd == BUS_LOAD) begin
                        next_mshr_entry.state       =   ST_OUTPUT;
                        next_mshr_entry.evict_addr  =   cache_mem_ctrl_i.evict_addr ;
                        next_mshr_entry.evict_data  =   cache_mem_ctrl_i.evict_data ;
                        next_mshr_entry.evict_dirty =   cache_mem_ctrl_i.evict_dirty;
                    // IF   a dirty block is evicted
                    // ->   Write back the evicted block
                    end else if (cache_mem_ctrl_i.evict_dirty == 1'b1) begin
                        next_mshr_entry.state       =   ST_EVICT;
                        next_mshr_entry.evict_addr  =   cache_mem_ctrl_i.evict_addr ;
                        next_mshr_entry.evict_data  =   cache_mem_ctrl_i.evict_data ;
                        next_mshr_entry.evict_dirty =   cache_mem_ctrl_i.evict_dirty;
                    // ELSE
                    // ->   Miss Handling Completed
                    end else begin
                        next_mshr_entry.state       =   ST_IDLE             ;
                        next_mshr_entry.cmd         =   BUS_NONE            ;
                        next_mshr_entry.req_addr    =   'b0                 ;
                        next_mshr_entry.req_data    =   'b0                 ;
                        next_mshr_entry.req_size    =   BYTE                ;
                        next_mshr_entry.evict_addr  =   'b0                 ;
                        next_mshr_entry.evict_data  =   'b0                 ;
                        next_mshr_entry.evict_dirty =   1'b0                ;
                        next_mshr_entry.link_idx    =   'd0                 ;
                        next_mshr_entry.mem_tag     =   'd0                 ;
                        next_mshr_cp_flag           =   1'b1                ;
                        next_mshr_cp_data           =   mshr_entry.req_data ;
                    end
                end
            end
            ST_OUTPUT   :   begin
                // IF   the Processor Interface is granted to this entry
                if (proc_grant_i == 1'b1) begin
                    // IF   the evicted block is dirty
                    // ->   Write back the evicted block
                    if (mshr_entry.evict_dirty == 1'b1) begin
                        next_mshr_entry.state       =   ST_EVICT;
                    // ELSE
                    // ->   Miss Handling Completed
                    end else begin
                        next_mshr_entry.state       =   ST_IDLE             ;
                        next_mshr_entry.cmd         =   BUS_NONE            ;
                        next_mshr_entry.req_addr    =   'b0                 ;
                        next_mshr_entry.req_data    =   'b0                 ;
                        next_mshr_entry.req_size    =   BYTE                ;
                        next_mshr_entry.evict_addr  =   'b0                 ;
                        next_mshr_entry.evict_data  =   'b0                 ;
                        next_mshr_entry.evict_dirty =   1'b0                ;
                        next_mshr_entry.link_idx    =   'd0                 ;
                        next_mshr_entry.mem_tag     =   'd0                 ;
                        next_mshr_cp_flag           =   1'b1                ;
                        next_mshr_cp_data           =   mshr_entry.req_data ;
                    end
                end
            end
            ST_EVICT    :   begin
                // IF   the write back transaction to Memory is confirmed
                // ->   Miss Handling Completed
                if ((memory_grant_i == 1'b1) && (mem2cache_i.response != 'd0)) begin
                    next_mshr_entry.state       =   ST_IDLE             ;
                    next_mshr_entry.cmd         =   BUS_NONE            ;
                    next_mshr_entry.req_addr    =   'b0                 ;
                    next_mshr_entry.req_data    =   'b0                 ;
                    next_mshr_entry.req_size    =   BYTE                ;
                    next_mshr_entry.evict_addr  =   'b0                 ;
                    next_mshr_entry.evict_data  =   'b0                 ;
                    next_mshr_entry.evict_dirty =   1'b0                ;
                    next_mshr_entry.link_idx    =   'd0                 ;
                    next_mshr_entry.mem_tag     =   'd0                 ;
                    next_mshr_cp_flag           =   1'b1                ;
                    next_mshr_cp_data           =   mshr_entry.req_data ;
                end
            end
            default     :   begin
                next_mshr_entry.state       =   ST_IDLE     ;
                next_mshr_entry.cmd         =   BUS_NONE    ;
                next_mshr_entry.req_addr    =   'b0         ;
                next_mshr_entry.req_data    =   'b0         ;
                next_mshr_entry.req_size    =   BYTE        ;
                next_mshr_entry.evict_addr  =   'b0         ;
                next_mshr_entry.evict_data  =   'b0         ;
                next_mshr_entry.evict_dirty =   1'b0        ;
                next_mshr_entry.link_idx    =   'd0         ;
                next_mshr_entry.mem_tag     =   'd0         ;
                next_mshr_cp_flag           =   1'b0        ;
                next_mshr_cp_data           =   'd0         ;
            end
        endcase

        if (next_mshr_entry.state == ST_IDLE) begin
            next_mshr_entry.linked  =   1'b0;
        end else if ((mshr_hit_i == 1'b1) && (mshr_hit_idx_i == mshr_entry_idx_i)) begin
            next_mshr_entry.linked  =   1'b1;
        end
    end

// --------------------------------------------------------------------
// MSHR entry output
// --------------------------------------------------------------------
    assign  mshr_entry_o    =   mshr_entry  ;
// --------------------------------------------------------------------
// Processor Interface
// --------------------------------------------------------------------
    always_comb begin
        mshr_proc_o.response    =   'd0 ;
        mshr_proc_o.data        =   'b0 ;
        mshr_proc_o.tag         =   'd0 ;
        case (mshr_entry.state)
            ST_IDLE     :   begin
                // IF   the processor request is allocated to this entry
                if ((proc2cache_i.command != BUS_NONE) && (dp_sel_i == 1'b1)) begin
                    // IF   The Processor Interface is granted to this entry
                    // AND  there is a dependency to older in-flight transaction
                    // ->   Confirm the request
                    if (((mshr_hit_i && (cp_flag_i[mshr_hit_idx_i] == 1'b0))
                    || (evict_hit_i && (cp_flag_i[evict_hit_idx_i] == 1'b0)))) begin
                        mshr_proc_o.response    =   mshr_entry_idx_i;
                    // IF   The Processor Interface is granted to this entry
                    // AND  The cache_mem Interface is granted to this entry
                    // ->   Confirm the request 
                    end else if (cache_mem_grant_i == 1'b1) begin
                        mshr_proc_o.response    =   mshr_entry_idx_i;
                        // IF   it is a load hit
                        // ->   Output data and tag
                        if (cache_mem_ctrl_i.req_hit == 1'b1 && proc2cache_i.command == BUS_LOAD) begin
                            mshr_proc_o.tag     =   mshr_entry_idx_i;
                            case (proc2cache_i.size)
                                BYTE    :   mshr_proc_o.data    =   {56'b0,cache_mem_ctrl_i.req_data_out[proc2cache_i.addr[2:0]+: 8]};
                                HALF    :   mshr_proc_o.data    =   {48'b0,cache_mem_ctrl_i.req_data_out[proc2cache_i.addr[2:0]+:16]};
                                WORD    :   mshr_proc_o.data    =   {32'b0,cache_mem_ctrl_i.req_data_out[proc2cache_i.addr[2:0]+:32]};
                                DOUBLE  :   mshr_proc_o.data    =   cache_mem_ctrl_i.req_data_out;
                                default :   mshr_proc_o.data    =   cache_mem_ctrl_i.req_data_out;
                            endcase
                        end
                    end
                end
            end
            ST_OUTPUT   :   begin
                mshr_proc_o.response    =   'd0                 ;
                mshr_proc_o.tag         =   mshr_entry_idx_i    ;
                case (mshr_entry.req_size)
                    BYTE    :   begin
                        output_data_offset  =   mshr_entry.req_addr[2:0];
                        mshr_proc_o.data    =   {56'b0,mshr_entry.req_data[output_data_offset +: 8]};
                    end
                    HALF    :   begin
                        output_data_offset  =   {mshr_entry.req_addr[2:1], 1'b0};
                        mshr_proc_o.data    =   {48'b0,mshr_entry.req_data[output_data_offset +:16]};
                    end
                    WORD    :   begin
                        output_data_offset  =   {mshr_entry.req_addr[2], 2'b0};
                        mshr_proc_o.data    =   {32'b0,mshr_entry.req_data[output_data_offset +:32]};
                    end
                    DOUBLE  :   begin
                        mshr_proc_o.data    =   mshr_entry.req_data;
                    end
                    default :   begin
                        mshr_proc_o.data    =   mshr_entry.req_data;
                    end
                endcase
            end
        endcase
    end

// --------------------------------------------------------------------
// cache_mem Interface
// --------------------------------------------------------------------
    always_comb begin
        mshr_cache_mem_o.req_cmd        =   REQ_NONE;
        mshr_cache_mem_o.req_addr       =   'b0     ;
        mshr_cache_mem_o.req_data_in    =   'b0     ;
        case (mshr_entry.state)
            ST_IDLE:    begin
                // IF   the processor request is allocated to this entry
                if (dp_sel_i == 1'b1) begin
                    case (proc2cache_i.command)
                        BUS_LOAD    :   begin
                            mshr_cache_mem_o.req_cmd        =   REQ_LOAD                        ;
                            mshr_cache_mem_o.req_addr       =   proc2cache_i.addr               ;
                            mshr_cache_mem_o.req_data_in    =   cache_mem_ctrl_i.req_data_out   ;
                        end
                        BUS_STORE   :   begin
                            mshr_cache_mem_o.req_cmd        =   REQ_STORE                       ;
                            mshr_cache_mem_o.req_addr       =   proc2cache_i.addr               ;
                            mshr_cache_mem_o.req_data_in    =   cache_mem_ctrl_i.req_data_out   ;
                            case (proc2cache_i.size)
                                BYTE    :   mshr_cache_mem_o.req_data_in[proc2cache_i.addr[2:0] +:  8]  =   proc2cache_i.data[ 7:0] ;
                                HALF    :   mshr_cache_mem_o.req_data_in[proc2cache_i.addr[2:0] +: 16]  =   proc2cache_i.data[15:0] ;
                                WORD    :   mshr_cache_mem_o.req_data_in[proc2cache_i.addr[2:0] +: 32]  =   proc2cache_i.data[31:0] ;
                                DOUBLE  :   mshr_cache_mem_o.req_data_in                                =   proc2cache_i.data       ;
                            endcase
                        end    
                    endcase
                end
            end
            ST_UPDATE:  begin
                if (mshr_entry.cmd == BUS_LOAD) begin
                    mshr_cache_mem_o.req_cmd    =   REQ_LOAD_MISS       ;
                end else begin
                    mshr_cache_mem_o.req_cmd    =   REQ_STORE_MISS      ;
                end
                mshr_cache_mem_o.req_addr       =   mshr_entry.req_addr ;
                mshr_cache_mem_o.req_data_in    =   mshr_entry.req_data ;
            end
        endcase
    end

// --------------------------------------------------------------------
// Memory Interface
// --------------------------------------------------------------------
    always_comb begin
        mshr_memory_o.addr      =   {mshr_entry.req_addr[C_XLEN-1:C_CACHE_OFFSET_WIDTH], {C_CACHE_OFFSET_WIDTH{1'b0}}};
        mshr_memory_o.size      =   DOUBLE              ;
        mshr_memory_o.command   =   BUS_NONE            ;
        mshr_memory_o.data      =   'd0 ;
        case (mshr_entry.state)
            ST_RD_MEM   :   begin
                mshr_memory_o.data      =   'd0 ;
                mshr_memory_o.addr      =   {mshr_entry.req_addr[C_XLEN-1:C_CACHE_OFFSET_WIDTH], {C_CACHE_OFFSET_WIDTH{1'b0}}};
                mshr_memory_o.command   =   BUS_LOAD;
            end
            ST_EVICT    :   begin
                mshr_memory_o.data      =   mshr_entry.evict_data;
                mshr_memory_o.addr      =   {mshr_entry.evict_addr[C_XLEN-1:C_CACHE_OFFSET_WIDTH], {C_CACHE_OFFSET_WIDTH{1'b0}}};
                mshr_memory_o.command   =   BUS_STORE;
            end
        endcase
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
