/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  cache_mem.sv                                        //
//                                                                     //
//  Description :  cache memory array manipulation                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module cache_mem #(
    parameter   C_CACHE_SIZE           =   `CACHE_SIZE   ,
    parameter   C_CACHE_BLOCK_SIZE     =   `CACHE_BLOCK_SIZE,
    parameter   C_CACHE_SET_ASS        =   `CACHE_SET_ASS,
    parameter   C_CACHE_OFFSET_WIDTH   =   `CACHE_OFFSET_WIDTH,
    parameter   C_CACHE_IDX_WIDTH      =   `CACHE_IDX_WIDTH,
    parameter   C_CACHE_TAG_WIDTH      =   `CACHE_TAG_WIDTH,
    parameter   C_CACHE_SET_NUM        =   (`CACHE_SIZE / `CACHE_BLOCK_SIZE / `CACHE_SET_ASS),
    parameter   C_CACHE_WAY_NUM        =   `CACHE_SET_ASS,
    parameter   C_LRU_ARRAY_WIDTH      =   ((`CACHE_SET_ASS * (`CACHE_SET_ASS - 1)) >> 1)
) (
    input   logic               clk_i           ,   //  Clock
    input   logic               rst_i           ,   //  Reset
    input   CACHE_CTRL_MEM      ctrl_mem_i      ,   //  cache control signal
    output  CACHE_MEM_CTRL      mem_ctrl_o          //  cache mem signal
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
CACHE_MEM_ARRAY [C_CACHE_SET_NUM-1:0][C_CACHE_SET_ASS-1:0]   cache_array ;
CACHE_MEM_ARRAY [C_CACHE_SET_NUM-1:0][C_CACHE_SET_ASS-1:0]   next_cache_array ;

logic [C_LRU_ARRAY_WIDTH -1 : 0]                             curr_history;
logic [C_LRU_ARRAY_WIDTH -1 : 0]                             next_history;

logic [C_CACHE_WAY_NUM -1 : 0]                               LRU;
logic [C_CACHE_WAY_NUM -1 : 0]                               access;

logic                                                        full;
logic [C_CACHE_SET_ASS-1 : 0]                                miss_empty_idx;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Check for empty entry in cache_mem
// ====================================================================
function automatic logic set_full;
    input CACHE_MEM_ARRAY [C_CACHE_SET_NUM-1:0][C_CACHE_SET_ASS-1:0]    cache_array;
    input logic [C_CACHE_IDX_WIDTH-1:0]                                 set_idx;
    begin 
        set_full = 1'b1;
        for (int array_idx = 0; array_idx < C_CACHE_SET_ASS; array_idx++) begin 
            set_full = cache_array[set_idx][array_idx].valid & set_full;
        end
    end 
endfunction 
// ====================================================================
// select the empty entry idx in cache_mem
// ====================================================================
function automatic logic [C_CACHE_SET_ASS-1:0] empty_idx;
    input CACHE_MEM_ARRAY [C_CACHE_SET_NUM-1:0][C_CACHE_SET_ASS-1:0]    cache_array;
    input logic [C_CACHE_IDX_WIDTH-1:0]                                 set_idx;
    logic empty = 1'b1;
    begin 
        for (int array_idx = 0; array_idx < C_CACHE_SET_ASS; array_idx++) begin 
            empty = cache_array[set_idx][array_idx].valid & empty;
            if (empty == 1'b0) begin 
                empty_idx = array_idx;
                break;
            end
        end
    end 
endfunction 
// ====================================================================
// LRU update logic
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   LRU update
// Description  :   update LRU one-hot signal through a 
//                  transitional matrix
// --------------------------------------------------------------------
genvar i;
generate
    for (i = 0; i < C_CACHE_SET_ASS; i++) begin 
        LRU_update LRU(
            .curr_history(curr_history),
            .access(access),
            .update_array(next_history),
            .LRU_new(LRU)
        );
        

    end
endgenerate
        always_ff @(posedge clk_i) begin
            if (rst_i) begin 
                curr_history <= `SD 'd0;
            end else begin 
                curr_history <= `SD next_history;
            end
        end
// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// Extract address tag/block offset/set_idx
// ====================================================================
assign mem_tag          =   ctrl_mem_i.req_addr[`XLEN-1 : C_CACHE_IDX_WIDTH + C_CACHE_OFFSET_WIDTH];
assign mem_idx          =   ctrl_mem_i.req_addr[C_CACHE_IDX_WIDTH+C_CACHE_OFFSET_WIDTH-1 : C_CACHE_OFFSET_WIDTH];
assign mem_blk_offset   =   ctrl_mem_i.req_addr[C_CACHE_OFFSET_WIDTH-1 : 0];

// ====================================================================
// Request Interface logic
// ====================================================================
always_comb begin 
    next_cache_array    =   cache_array;
    mem_ctrl_o.req_hit  =   1'b0;
    access              =   'b0;
    if (ctrl_mem_i.req_cmd == REQ_NONE) begin 
        mem_ctrl_o = 'd0;
    end else if (ctrl_mem_i.req_cmd == REQ_LOAD) begin
        for (int way_idx = 0; way_idx < C_CACHE_SET_ASS; way_idx++) begin 
            if (cache_array[mem_idx][way_idx].tag == mem_tag) begin 
                mem_ctrl_o.req_hit      = 1'b1;
                mem_ctrl_o.req_data_out = next_cache_array[mem_idx][way_idx].data;
                access[way_idx]         = 1'b1;

                for (int lru_idx = 0; lru_idx < C_CACHE_SET_ASS; lru_idx++) begin 
                    if (LRU[lru_idx] == 1'b1) begin 
                        next_cache_array[mem_idx][lru_idx].lru = 1'b1;
                    end 
                end   
            end
        end
    end else if (ctrl_mem_i.req_cmd == REQ_STORE) begin
        for (int way_idx = 0; way_idx < C_CACHE_SET_ASS; way_idx++) begin 
            if (cache_array[mem_idx][way_idx].tag == mem_tag) begin 
                mem_ctrl_o.req_hit          = 1'b1;
                mem_ctrl_o.req_data_out     = next_cache_array[mem_idx][way_idx].data;
                next_cache_array[mem_idx][way_idx].dirty = 1'b1;
                access[way_idx]             = 1'b1;

                for (int lru_idx = 0; lru_idx < C_CACHE_SET_ASS; lru_idx++) begin 
                    if (LRU[lru_idx] == 1'b1) begin 
                        next_cache_array[mem_idx][lru_idx].lru = 1'b1;
                    end 
                end   

            end
        end
    end else if (ctrl_mem_i.req_cmd == REQ_MISS) begin 
        for (int way_idx = 0; way_idx < C_CACHE_SET_ASS; way_idx++) begin 
            if (cache_array[mem_idx][way_idx].tag == mem_tag) begin 
                mem_ctrl_o.req_hit      = 1'b1;
                mem_ctrl_o.req_data_out = next_cache_array[mem_idx][way_idx].data;
                next_cache_array[mem_idx][way_idx].dirty = 1'b1;
                access[way_idx]         = 1'b1;

                for (int lru_idx = 0; lru_idx < C_CACHE_SET_ASS; lru_idx++) begin 
                    if (LRU[lru_idx] == 1'b1) begin 
                        next_cache_array[mem_idx][lru_idx].lru = 1'b1;
                    end 
                end
            end 
        end
        full = set_full(next_cache_array, mem_idx); 
        miss_empty_idx = empty_idx(next_cache_array, mem_idx);
        if (!full) begin
            next_cache_array[mem_idx][miss_empty_idx].valid = 1'b1;
            next_cache_array[mem_idx][miss_empty_idx].data  = ctrl_mem_i.req_data_in;
            next_cache_array[mem_idx][miss_empty_idx].tag   = mem_tag;
            next_cache_array[mem_idx][miss_empty_idx].dirty = 1'b1;
            access[miss_empty_idx] = 1'b1;
            for (int lru_idx = 0; lru_idx < C_CACHE_SET_ASS; lru_idx++) begin 
                if (LRU[lru_idx] == 1'b1) begin 
                    next_cache_array[mem_idx][lru_idx].lru = 1'b1;
                end 
            end
        end else begin
            for (int way_idx = 0; way_idx < C_CACHE_SET_ASS; way_idx++) begin 
                if (cache_array[mem_idx][way_idx].lru == 1'b1) begin
                    mem_ctrl_o.evict_dirty  = 1'b1;
                    mem_ctrl_o.evict_data   = next_cache_array[mem_idx][way_idx].data;
                    mem_ctrl_o.evict_addr   = {next_cache_array[mem_idx][way_idx].tag, mem_idx, mem_blk_offset};
                end
            end
        end
    end
end


always_ff @(posedge clk_i) begin : blockName
    if (rst_i) begin 
        cache_array <= `SD 'b0;
    end else begin 
        cache_array <= `SD next_cache_array;
    end 
end
// ====================================================================
// RTL Logic Start
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



module LRU_update #(
    parameter C_CACHE_WAY_NUM           =   `CACHE_SET_ASS,
    parameter C_LRU_ARRAY_WIDTH = ((`CACHE_SET_ASS * (`CACHE_SET_ASS - 1)) >> 1)
) (
    input logic [C_LRU_ARRAY_WIDTH -1 :0] curr_history,
    input logic [C_CACHE_WAY_NUM - 1 : 0] access,
    output logic [C_LRU_ARRAY_WIDTH -1 :0] update_array,
    // output logic [C_CACHE_WAY_NUM - 1 : 0] LRU_curr;
    output logic [C_CACHE_WAY_NUM - 1 : 0] LRU_new
);
    logic [C_CACHE_WAY_NUM-1:0]         expand      [0:C_CACHE_WAY_NUM-1];
    logic [C_CACHE_WAY_NUM - 1 : 0]     LRU_curr;
    always_comb begin : LRU_update
        logic offset = 0;
        integer i,j;

        for (int i = 0; i < C_CACHE_WAY_NUM; i = i + 1) begin
            expand[i][i] = 1'b1;

            for (j = i + 1; j < C_CACHE_WAY_NUM; j = j + 1) begin
                expand[i][j] = curr_history[offset+j-i-1];
            end
            for (j = 0; j < i; j = j + 1) begin
                expand[i][j] = !expand[j][i];
            end

            offset = offset + C_CACHE_WAY_NUM - i - 1;
        end 


        for (i = 0; i < C_CACHE_WAY_NUM; i = i + 1) begin
            LRU_curr[i] = &expand[i];
        end

        for (i = 0; i < C_CACHE_WAY_NUM; i = i + 1) begin
            if (access[i]) begin
                for (j = 0; j < C_CACHE_WAY_NUM; j = j + 1) begin
                    if (i != j) begin
                        expand[i][j] = 1'b0;
                    end
                end

                for (j = 0; j < C_CACHE_WAY_NUM; j = j + 1) begin
                    if (i != j) begin
                        expand[j][i] = 1'b1;
                    end
                end
            end
        end
        offset = 0;
        for (i = 0; i < C_CACHE_WAY_NUM; i = i + 1) begin
            for (j = i + 1; j < C_CACHE_WAY_NUM; j = j + 1) begin
                update_array[offset+j-i-1] = expand[i][j];
            end
            offset = offset + C_CACHE_WAY_NUM - i - 1;
        end

        for (i = 0; i < C_CACHE_WAY_NUM; i = i + 1) begin
            LRU_new[i] = &expand[i];
        end
    end
    
endmodule