/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  icache_mem.sv                                       //
//                                                                     //
//  Description :  cache memory array manipulation                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module icache_mem #(
    parameter   C_XLEN                  =   `XLEN                       ,
    parameter   C_CACHE_SIZE            =   `CACHE_SIZE                 ,
    parameter   C_CACHE_BLOCK_SIZE      =   `CACHE_BLOCK_SIZE           ,
    parameter   C_CACHE_SASS            =   `ICACHE_SASS                ,
    parameter   C_CACHE_OFFSET_WIDTH    =   $clog2(C_CACHE_BLOCK_SIZE)  ,
    parameter   C_CACHE_SET_NUM         =   (C_CACHE_SIZE / C_CACHE_BLOCK_SIZE / C_CACHE_SASS),
    parameter   C_CACHE_IDX_WIDTH       =   $clog2(C_CACHE_SET_NUM)     ,
    parameter   C_CACHE_TAG_WIDTH       =   (C_XLEN - C_CACHE_IDX_WIDTH - C_CACHE_OFFSET_WIDTH)
) (
    // For Testing
    output  CACHE_MEM_ENTRY [C_CACHE_SET_NUM-1:0][C_CACHE_SASS-1:0] cache_array_mon_o   ,

    input   logic               clk_i               ,   //  Clock
    input   logic               rst_i               ,   //  Reset
    input   CACHE_CTRL_MEM      cache_ctrl_mem_i    ,   //  cache control signal
    output  CACHE_MEM_CTRL      cache_mem_ctrl_o        //  cache mem signal
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_USE_HISTORY_WIDTH =   ((C_CACHE_SASS * (C_CACHE_SASS - 1)) >> 1);
    localparam  C_WAY_IDX_WIDTH     =   $clog2(C_CACHE_SASS);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // Cache memory array
    CACHE_MEM_ENTRY [C_CACHE_SET_NUM-1:0][C_CACHE_SASS-1:0] cache_array         ;   // data array and control array
    CACHE_MEM_ENTRY [C_CACHE_SET_NUM-1:0][C_CACHE_SASS-1:0] next_cache_array    ;   // next state data array and control array

    logic   [C_CACHE_OFFSET_WIDTH-1:0]                      mem_blk_offset      ;
    logic   [C_CACHE_IDX_WIDTH   -1:0]                      mem_idx             ;
    logic   [C_CACHE_TAG_WIDTH   -1:0]                      mem_tag             ;

    // Least-Recently-Used
    logic   [C_CACHE_SET_NUM-1:0][C_USE_HISTORY_WIDTH-1:0]  use_history         ;   // Current LRU matrix
    logic   [C_CACHE_SET_NUM-1:0][C_USE_HISTORY_WIDTH-1:0]  next_use_history    ;   // Next LRU matrix
    logic   [C_CACHE_SET_NUM-1:0][C_CACHE_SASS-1:0]         next_lru            ;   // Next one-hot LRU signal within a set
    logic   [C_CACHE_SET_NUM-1:0][C_CACHE_SASS-1:0]         access              ;   // access specific way in a set

    // Empty way selector
    logic   [C_CACHE_SET_NUM-1:0]                           empty_way_valid     ;   // Indicate whether there is a empty way in a set
    logic   [C_CACHE_SET_NUM-1:0][C_WAY_IDX_WIDTH-1:0]      empty_way_idx       ;   // The way index of one of the empty ways in a set
// ====================================================================
// Signal Declarations End
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
        for (i = 0; i < C_CACHE_SET_NUM; i++) begin 
            icache_LRU_update LRU_update_inst(
                .use_history        (use_history[i]         ),
                .access             (access[i]              ),
                .next_use_history   (next_use_history[i]    ),
                .next_lru           (next_lru[i]            )
            );
        end
    endgenerate
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Extract address tag/block offset/set_idx
// --------------------------------------------------------------------
    assign  mem_tag         =   cache_ctrl_mem_i.req_addr[(C_XLEN-1):(C_CACHE_IDX_WIDTH+C_CACHE_OFFSET_WIDTH)];
    assign  mem_idx         =   cache_ctrl_mem_i.req_addr[(C_CACHE_IDX_WIDTH+C_CACHE_OFFSET_WIDTH-1):C_CACHE_OFFSET_WIDTH];
    assign  mem_blk_offset  =   cache_ctrl_mem_i.req_addr[C_CACHE_OFFSET_WIDTH-1:0];

// --------------------------------------------------------------------
// Find an empty entry in set
// --------------------------------------------------------------------
    always_comb begin
        empty_way_valid =   1'b0    ;
        empty_way_idx   =   'd0     ;
        for (int unsigned set_idx = 0; set_idx < C_CACHE_SET_NUM; set_idx++) begin
            for (int unsigned way_idx = 0; way_idx < C_CACHE_SASS; way_idx++) begin
                if (cache_array[set_idx][way_idx].valid == 1'b0) begin
                    empty_way_valid[set_idx]    =   1'b1    ;
                    empty_way_idx[set_idx]      =   way_idx ;
                end
            end
        end
    end

// --------------------------------------------------------------------
// Request Interface logic
// --------------------------------------------------------------------
    always_comb begin 
        next_cache_array    =   cache_array ;
        cache_mem_ctrl_o    =   'd0         ;
        access              =   'b0         ;
        case(cache_ctrl_mem_i.req_cmd)
            // IF   cach_ctrl requests a load
            REQ_LOAD: begin
                // IF   the tag of the cache block in mapped set matches the requested tag
                // ->   a load hit is confirmed, output the block data and update LRU bits
                for (int way_idx = 0; way_idx < C_CACHE_SASS; way_idx++) begin 
                    if (cache_array[mem_idx][way_idx].valid ==  1'b1 
                    && cache_array[mem_idx][way_idx].tag == mem_tag) begin 
                        cache_mem_ctrl_o.req_hit        =   1'b1                                ;
                        cache_mem_ctrl_o.req_data_out   =   cache_array[mem_idx][way_idx].data  ;
                        access[mem_idx][way_idx]        =   1'b1                                ; 
                    end
                end
            end
            // IF   cach_ctrl request a store, check for hit and update LRU/dirty bits, request interface output data in the data array.
            REQ_STORE: begin
                // IF   the tag of the cache block in mapped set matches the requested tag
                // ->   a store hit is confirmed, output the current block data, update LRU bits, 
                //      write the new data and asserts the dirty bit.
                for (int way_idx = 0; way_idx < C_CACHE_SASS; way_idx++) begin 
                    if (cache_array[mem_idx][way_idx].valid ==  1'b1 
                    && cache_array[mem_idx][way_idx].tag == mem_tag) begin 
                        cache_mem_ctrl_o.req_hit                    =   1'b1                                ;
                        cache_mem_ctrl_o.req_data_out               =   cache_array[mem_idx][way_idx].data  ;
                        next_cache_array[mem_idx][way_idx].data     =   cache_ctrl_mem_i.req_data_in        ;
                        next_cache_array[mem_idx][way_idx].dirty    =   1'b1                                ;
                        access[mem_idx][way_idx]                    =   1'b1                                ;
                    end
                end
            end
            // IF   cach_ctrl requests a miss handling for load miss
            REQ_LOAD_MISS: begin
                // IF   the tag of the cache block in mapped set matches the requested tag
                //      (meaning there is a previous miss handling that place the block in cache)
                // ->   output the data in the hit block, update the LRU bits
                for (int way_idx = 0; way_idx < C_CACHE_SASS; way_idx++) begin 
                    if (cache_array[mem_idx][way_idx].valid ==  1'b1 
                    && cache_array[mem_idx][way_idx].tag == mem_tag) begin 
                        cache_mem_ctrl_o.req_hit        =   1'b1                                ;
                        cache_mem_ctrl_o.req_data_out   =   cache_array[mem_idx][way_idx].data  ;
                        access[mem_idx][way_idx]        =   1'b1                                ;
                    end
                end

                // IF   the block is still a miss
                //      Meaning there is no previous miss handling to this address
                if (cache_mem_ctrl_o.req_hit == 1'b0) begin
                    // IF   there is a empty way in the mapped set
                    // ->   Write the data into the way
                    if (empty_way_valid[mem_idx] == 1'b1) begin
                        next_cache_array[mem_idx][empty_way_idx[mem_idx]].valid =   1'b1;
                        next_cache_array[mem_idx][empty_way_idx[mem_idx]].data  =   cache_ctrl_mem_i.req_data_in;
                        next_cache_array[mem_idx][empty_way_idx[mem_idx]].tag   =   mem_tag;
                        next_cache_array[mem_idx][empty_way_idx[mem_idx]].dirty =   1'b1;
                        access[mem_idx][empty_way_idx[mem_idx]]                 =   1'b1;
                    // ELSE there is no empty way in the mapped set
                    end else begin
                        for (int way_idx = 0; way_idx < C_CACHE_SASS; way_idx++) begin 
                            // Pick the Least-Recently-Used way to evict
                            if (cache_array[mem_idx][way_idx].lru == 1'b1) begin
                                // Output its current data to the cache_ctrl
                                cache_mem_ctrl_o.evict_dirty                =   1'b1;
                                cache_mem_ctrl_o.evict_data                 =   cache_array[mem_idx][way_idx].data;
                                cache_mem_ctrl_o.evict_addr                 =   {cache_array[mem_idx][way_idx].tag, mem_idx, {C_CACHE_OFFSET_WIDTH{1'b0}}};
                                // Write the new data from cache_ctrl into the way
                                next_cache_array[mem_idx][way_idx].valid    =   1'b1;
                                next_cache_array[mem_idx][way_idx].data     =   cache_ctrl_mem_i.req_data_in;
                                next_cache_array[mem_idx][way_idx].tag      =   mem_tag;
                                next_cache_array[mem_idx][way_idx].dirty    =   1'b0;
                            end
                        end
                    end
                end
            end
            // IF   cach_ctrl requests a miss handling for store miss
            REQ_STORE_MISS: begin     
                // IF   the tag of the cache block in mapped set matches the requested tag
                //      (meaning there is a previous miss handling that place the block in cache)
                // ->   output the data in the hit block, update the LRU bits
                for (int way_idx = 0; way_idx < C_CACHE_SASS; way_idx++) begin 
                    if (cache_array[mem_idx][way_idx].valid ==  1'b1 
                    && cache_array[mem_idx][way_idx].tag == mem_tag) begin  
                        cache_mem_ctrl_o.req_hit                =   1'b1                                ;
                        cache_mem_ctrl_o.req_data_out           =   cache_array[mem_idx][way_idx].data  ;
                        next_cache_array[mem_idx][way_idx].data =   cache_ctrl_mem_i.req_data_in        ;
                        access[mem_idx][way_idx]                =   1'b1                                ;
                    end
                end

                // IF   the block is still a miss
                //      Meaning there is no previous miss handling to this address
                if (cache_mem_ctrl_o.req_hit == 1'b0) begin
                    // IF   there is a empty way in the mapped set
                    // ->   Write the data into the way
                    if (empty_way_valid[mem_idx] == 1'b1) begin
                        next_cache_array[mem_idx][empty_way_idx[mem_idx]].valid =   1'b1;
                        next_cache_array[mem_idx][empty_way_idx[mem_idx]].data  =   cache_ctrl_mem_i.req_data_in;
                        next_cache_array[mem_idx][empty_way_idx[mem_idx]].tag   =   mem_tag;
                        next_cache_array[mem_idx][empty_way_idx[mem_idx]].dirty =   1'b1;
                        access[mem_idx][empty_way_idx[mem_idx]]                 =   1'b1;
                    // ELSE there is no empty way in the mapped set
                    end else begin
                        for (int way_idx = 0; way_idx < C_CACHE_SASS; way_idx++) begin 
                            // Pick the Least-Recently-Used way to evict
                            if (cache_array[mem_idx][way_idx].lru == 1'b1) begin
                                // Output its current data to the cache_ctrl
                                cache_mem_ctrl_o.evict_dirty                =   1'b1;
                                cache_mem_ctrl_o.evict_data                 =   cache_array[mem_idx][way_idx].data;
                                cache_mem_ctrl_o.evict_addr                 =   {cache_array[mem_idx][way_idx].tag, mem_idx, {C_CACHE_OFFSET_WIDTH{1'b0}}};
                                // Write the new data from cache_ctrl into the way
                                next_cache_array[mem_idx][way_idx].valid    =   1'b1;
                                next_cache_array[mem_idx][way_idx].data     =   cache_ctrl_mem_i.req_data_in;
                                next_cache_array[mem_idx][way_idx].tag      =   mem_tag;
                                next_cache_array[mem_idx][way_idx].dirty    =   1'b0;
                            end
                        end
                    end
                end
            end
        endcase

        // Next LRU bits
        for (int unsigned set_idx = 0; set_idx < C_CACHE_SET_NUM; set_idx++) begin
            for (int unsigned way_idx = 0; way_idx < C_CACHE_SASS; way_idx++) begin
                next_cache_array[set_idx][way_idx].lru  =   next_lru[set_idx][way_idx];
            end
        end
    end

    // Update the cache memory
    always_ff @(posedge clk_i) begin    // initialize the data array and control array.  
        if (rst_i) begin 
            cache_array <= `SD 'b0;
        end else begin 
            cache_array <= `SD next_cache_array;
        end 
    end

// --------------------------------------------------------------------
// Use history updates
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        // Reset
        // The timelapse from the most recent use
        // 0 < 1 < ... < (C_CACHE_SASS-1) (LRU)
        if (rst_i) begin 
            use_history <=  `SD 'b0;
        // Update use history
        end else begin 
            use_history <=  `SD next_use_history;
        end
    end

    assign  cache_array_mon_o   =   cache_array ;

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule