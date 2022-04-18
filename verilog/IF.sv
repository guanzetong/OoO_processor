// if_stage.v (the actual hardware before the IF/ Pipeline)
/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  if_stage.sv                                         //
//                                                                     //
//  Description :  Fetch stage of the pipeline;                        // 
//                 Contains all relevant modules that                  //
//                 will be aid in the fetch process.                   //
//                 At a high level, reads a N-wide amount of           // 
//                 instructions per thread and inserts into some       //
//                 queue, computes next PC location, and               //
//                 sends them down the pipeline (To be processed       //
//                 in the dispatch / decode stage).                    //                                        
//                                                                     //
//                 Initially, we will be assuming not-taken.           //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


//! Note to self: logic is only used for bits (not struct data types) -> Those internally may have logic types (logic is basically its own type).
`include "sys_defs.svh"
`define DEBUG


`define INST_PER_BLOCK ( `CACHE_BLOCK_SIZE / `XLEN_BYTES ) // gives number of instructions / block

module IF # (
    parameter   C_DP_NUM                = `DP_NUM           ,
    parameter   C_DP_NUM_WIDTH          = `DP_NUM_WIDTH     ,
    parameter   C_THREAD_NUM            = `THREAD_NUM       ,            
    parameter   C_THREAD_IDX_WIDTH      = `THREAD_IDX_WIDTH ,
    parameter   C_IF_NUM                = `IF_NUM           ,           // Used to detail the instructions that can be fetched per cycle.
    parameter   C_FIQ_NUM                = `FIQ_NUM                       // Number of instructions that can exist in the instruction buffer at once.
) (
    input   logic                               clk_i               ,           // system clock
    input   logic                               rst_i               ,           // System Reset
    input   logic  [C_THREAD_NUM-1:0]           pc_en_i             ,           // Used to control whether or not to use SMT or not.
    input   logic  [C_THREAD_NUM-1:0][`XLEN-1:0]rst_pc_i            ,
    input   BR_MIS                              br_mis_i            ,           // mis-predict  signal

    input   MEM_OUT                             ic_if_i             ,           // Data coming back from insruction memory. 
    input   DP_FIQ                              dp_fiq_i            ,           // Dispatch telling how many instructions were taken out.
    output  MEM_IN                              if_ic_o             ,           // Address sent to Intruction memory (to be feteched)
    output  FIQ_DP                              fiq_dp_o                        // Output data packet from IFgoing to DP (this is the instruction, PC, PC+1, and whether to care about if (if valid)
    `ifdef DEBUG
                                                                    ,
    // For testing ( _t is to notate signal is only used in debugging )

    // Next State wires
    output CONTEXT [C_THREAD_NUM-1:0]          n_thread_data_o_t    ,           // Verify how the wire is like.
    output logic   [C_THREAD_IDX_WIDTH-1:0]    thread_idx_disp_o_t  ,

    // State Register wires
    output CONTEXT [C_THREAD_NUM-1:0]          thread_data_o_t      ,           
    output logic   [C_THREAD_IDX_WIDTH-1:0]    thread_to_ft_o_t
    `endif
);
// ====================================================================
// Signal Declarations Start
// ====================================================================
    CONTEXT [C_THREAD_NUM-1:0]                       thread_data         ;
    logic   [C_THREAD_IDX_WIDTH-1:0]                 thread_to_ft        ;   // Current thread in which supposed to fetch from cache.

// ====================================================================
// Wires Declarations Start
// ====================================================================
    CONTEXT [C_THREAD_NUM-1:0]                       n_thread_data       ; 
    logic   [C_THREAD_IDX_WIDTH-1:0]                 thread_idx_disp     ;  // Counter which is used to chose between which thread to dispatch (driven by register in module FIQ_Out).
    logic   [C_THREAD_NUM-1:0]                       pc_en               ;

    // From dispatch logic.
    logic   [C_THREAD_NUM-1:0][C_DP_NUM_WIDTH-1:0]   inst_num_sel        ;  // Number of instructions fetched / thread (need to pop from buffer)

    // Feed into insert queue logic
    // INST    [C_THREAD_NUM-1:0][`IF_NUM-1:0]          data_fted           ;
    // logic   [C_THREAD_NUM-1:0][`IF_NUM_WIDTH-1:0]    num_fted            ; // Instructions valid
    // INST    [C_THREAD_NUM-1:0][C_IF_NUM-1:0]         data_fted           ;  // Data fetched. -> Changed to accomodate for interface

// ====================================================================
// Wires Assignments / Combinational Logic Start
// ====================================================================

`ifdef DEBUG
    assign n_thread_data_o_t    = n_thread_data;
    assign thread_idx_disp_o_t  = thread_idx_disp;
    assign thread_data_o_t      = thread_data;
    assign thread_to_ft_o_t     = thread_to_ft;
`endif

    // Logic for PC
    always_comb
    begin   
        for ( int n = 0; n < C_THREAD_NUM; ++n )
        begin
            // We should only enable this pc if 1) enabled globally
            // And is the thread currently fetching.
            // WHY? So the fetch module can control where a block is inserted into the multiple thread queues.
            pc_en[ n ] = pc_en_i[ n ] && ( n == thread_to_ft );
        end
    end

    // Explict for inst_num_sel
    always_comb
    begin
        for ( int n = 0; n < C_THREAD_NUM; ++n )	
        begin	
            inst_num_sel[ n ] = 'd0;   // All zero for now (for both threads).	
        end
        inst_num_sel[ thread_idx_disp ] = dp_fiq_i.dp_num;        // How many to take out (we only expect one thread to be dispatchable per cycle)
    end // always_comb

    next_state_thread_context next_state_thread_logic [C_THREAD_NUM-1:0] (
        .ic_if_i          ( ic_if_i                 ),  // Signals that change the insert part of queue
        .inst_num_sel_i   ( inst_num_sel            ),  // Signals dealing with what is being taken out (by instruction chooser)!
        .br_mis_valid_i   ( br_mis_i.valid          ),  // Need to split BR_MIS seperately to allow to be fed in seperately
        .br_mis_pc_i      ( br_mis_i.br_target      ),
        .pc_en_i          ( pc_en                   ),
        .curr_context_i   ( thread_data             ),   
        .n_context_o      ( n_thread_data           )   // The final result (should be a wire kind of struct)
    );

// ====================================================================
// Sequential Logic Start
// ====================================================================
    always_ff @( posedge clk_i )
    begin
        for ( int n = 0; n < C_THREAD_NUM; n++ )
        begin
            if ( rst_i )
            begin
                thread_data[ n ].PC_reg     <= `SD rst_pc_i[ n ];
                thread_data[ n ].inst_buff  <= `SD 'd0;
                thread_data[ n ].avail_size <= `SD C_FIQ_NUM;
                thread_data[ n ].hd_ptr     <= `SD 'd0;
                thread_data[ n ].tail_ptr   <= `SD 'd0;
            end
            else if ( br_mis_i.valid[n] ) // need to clear queue
            begin
                thread_data[ n ].PC_reg         <= `SD br_mis_i.br_target[ n ];
                thread_data[ n ].inst_buff  <= `SD 'd0;
                thread_data[ n ].avail_size     <= `SD C_FIQ_NUM;
                thread_data[ n ].hd_ptr         <= `SD 'd0;        
                thread_data[ n ].tail_ptr       <= `SD 'd0;        
                //! The setting of the pc is already handled in the next_pc logic
            end else if (  pc_en_i[ n ] )
            begin
                thread_data[ n ] <= `SD n_thread_data[ n ];  // transition to next state (pc included)
            end // else
            else begin
                thread_data[ n ] <= `SD thread_data[ n ];
            end
        end // for
    end // always_ff

    // Sequential Counter for Fetching (Does a Round Robin Approach for getting)
    //! Potential issue here is if only one thread is running 
    // (might actually only fetch once every other cycle) -> Thus this needs to be accounted for.
    always_ff @ ( posedge clk_i )
    begin
        if ( rst_i ) begin
            thread_to_ft <= `SD 'd0;
        end else if ( br_mis_i.valid[ thread_to_ft ] == 1'b1 || !pc_en_i[ thread_to_ft + 1 ] ) begin // Maintain same index
            thread_to_ft <= `SD thread_to_ft; // Try again next cycle.
        end else begin // Otherwise go to next thread.
            thread_to_ft <= `SD thread_to_ft + 1;
        end
    end

// ====================================================================
// Sequential Logic End
// ====================================================================


// ====================================================================
// Output Logic Start
// ====================================================================

    // Output logic to the outside Interfaces (IC_out -> signals meant for the IC, FIQ_out -> signals for dispatcher(DP))
    output_logic_IC IC_out
    ( 
        .context_i      ( thread_data  ), 
        .thread_to_ft_i ( thread_to_ft ),
        .if_ic_o        ( if_ic_o      ) 
    );
    output_FIQ  FIQ_out( 
        .clk_i              ( clk_i            ),
        .rst_i              ( rst_i            ),
        .threads_i          ( thread_data      ), 
        .br_mis_i           ( br_mis_i         ),
        .thread_idx_disp_o  ( thread_idx_disp  ),
        .fiq_dp_o           ( fiq_dp_o         )
        );

// ====================================================================
// Output Logic Start
// ====================================================================
    
endmodule : IF

// Top-level module for next state of thread context.
module next_state_thread_context # (
    parameter   C_THREAD_NUM            = `THREAD_NUM       ,
    parameter   C_IF_NUM                = `IF_NUM           ,
    parameter   C_IF_NUM_WIDTH          = `IF_NUM_WIDTH     ,
    parameter   C_DP_NUM_WIDTH          = `DP_NUM_WIDTH     
) (
    input  MEM_OUT                                  ic_if_i                ,   // Signals that change the insert part of queue (Now will consist of the block received from mem_out)
    input  logic    [C_DP_NUM_WIDTH-1:0]            inst_num_sel_i         ,   // Signals dealing with what is being taken out (by instruction chooser)!
    input  logic                                    br_mis_valid_i         ,   // Is there a miss signal for this thread?
    input  logic    [`XLEN-1:0]                     br_mis_pc_i            ,   // The target pc (if br_mis_valid_i is asserted)
    input  logic                                    pc_en_i                ,
    input  CONTEXT                                  curr_context_i         ,   // The current state of the thread context 
    output CONTEXT                                  n_context_o            // The final result (should be a wire kind of struct)
);

// ====================================================================
// Wires Declarations Start
// ====================================================================
    logic [C_IF_NUM_WIDTH-1:0] inst_to_insert_i; // We need to cap the insertions since the fetch may grab more instructions than can fit.
    wire logic [C_IF_NUM_WIDTH-1:0] inst_num_to_ft;

// ====================================================================
// Wires Declarations End
// ====================================================================

// ====================================================================
// Wires Assignments / Combinational Logic Start
// ====================================================================

    // Insert the min of the two registers (if pc_en is false, don't push into it.).

    // Use the Number of instructions per block... (currently 2 but the macro isn't working so need to make a literal)
    assign inst_num_to_ft   =  2 - ( curr_context_i.PC_reg[`CACHE_OFFSET_WIDTH-1:0] >> $clog2( `XLEN_BYTES ) ); // Discard the 2 LSBs.

    // Limits the number of insertions to fit to the size of the fetch buffer.
    always_comb
    begin
        inst_to_insert_i = 'd0;
        if ( pc_en_i == 1'b1 && ic_if_i.response != 0 ) begin
            inst_to_insert_i = ( inst_num_to_ft > curr_context_i.avail_size ) ?
                                curr_context_i.avail_size : inst_num_to_ft;
        end
    end // always_comb
    
    // Additional logic for accounting for what is able to insert was added
    // because fetches no longer is providing fine-grain control for the amount.
    // We want to essentially grab a block size (8 bytes )for the time being.

// ====================================================================
// Wires Assignments / Combinational Logic End
// ====================================================================

// ====================================================================
// Combinational Module Instantiations Start
// ====================================================================

// --------------------------------------------------------------------
// Module name  :   next_state_insert_queue
// Description  :   Next state logic for inserting N instructions into 
//                  the instruction buffer.
// --------------------------------------------------------------------
    next_state_insert_queue insert_comb_logic (
        .ic_if_i        ( ic_if_i               ),
        .inst_num_i     ( inst_to_insert_i      ),
        .curr_context_i ( curr_context_i        ),
        .n_fetch_buff_o ( n_context_o.inst_buff ),
        .n_tail_ptr_o   ( n_context_o.tail_ptr  )
    );

// --------------------------------------------------------------------
// Module name  :   next_state_pop_queue
// Description  :   Next state logic for popping instructions dispatched
// --------------------------------------------------------------------
    next_state_pop_queue pop_comb_logic (
        .thread_i       ( curr_context_i        ),
        .inst_num_sel_i ( inst_num_sel_i        ),
        .n_hd_ptr_o     ( n_context_o.hd_ptr    )
    );

// --------------------------------------------------------------------
// Module name  :   next_pc_logic
// Description  :   Next state logic for updating PC.
// --------------------------------------------------------------------
    next_pc_logic pc_comb_logic (
        .thread_i       ( curr_context_i        ),
        .inst_num_i     ( inst_to_insert_i      ),
        .br_mis_v_i     ( br_mis_valid_i        ),
        .br_mis_pc_i    ( br_mis_pc_i           ), // Branch target
        .pc_en_i        ( pc_en_i               ),
        .next_PC_o      ( n_context_o.PC_reg    )
    );
// ====================================================================
// Combinational Module Instantiations End
// ====================================================================

// ====================================================================
// Miscellaneous combinational logic Start
// ====================================================================
    always_comb begin 
        // Update the avail_size to reflect how empty it'll be based on the next state logic.
        n_context_o.avail_size           = curr_context_i.avail_size - inst_to_insert_i + inst_num_sel_i; // avail_size should shrink (as well as grow due to taking out)
    end // always_comb

// ====================================================================
// Verification Start
// ====================================================================
/*
    verify verify_insertion
    (
        .curr_context_i ( curr_context_i   ),
        .inst_num_i     ( inst_to_insert_i ),
        .inst_num_sel_i ( inst_num_sel_i   )
    );
*/
// ====================================================================
// Verification End
// ====================================================================
endmodule:next_state_thread_context

// A per-thread queue structure
// Here we want to use head / tail pointers to insert into the queue.
// This describes an approach in which all instructions are muxed each entry in curr_context_i.inst_buff and
// based on the tail pointer (and the index of the entry), describe a selector logic that allows to choose a
// particular instruction to be inserted.
//! The reason why I choose to seperate the insert from the popping is, most foremost, for simplicity.
//! It allows for the logic to only rely on the insert while using another module to do the pop logic.
module next_state_insert_queue ( 
    input  MEM_OUT                          ic_if_i         , // Signals coming from the instruction cache.
    input  logic    [`IF_NUM_WIDTH-1:0]     inst_num_i      , // Number of valid instructions being inserted
    input  CONTEXT                          curr_context_i  , // State of the current thread context.
    output FIQ_ENTRY[`FIQ_NUM-1:0]          n_fetch_buff_o  , // Next-state signals modified
    output logic    [`FIQ_IDX_WIDTH:0]      n_tail_ptr_o
);
// ====================================================================
// Wires Declarations Start
// ====================================================================
    logic [`FIQ_NUM-1:0]                     insert_window  ;              // Specify the entries can be inserted after tail as a bit array.
    logic [`IF_NUM-1:0][`FIQ_IDX_WIDTH-1:0]  idx_array      ;              // Valid indices used.
    logic                                   cache_hit       ;
    INST  [2-1:0]     data_as_inst   ;              // Aids in the indexing for me.
    logic [2-1:0]     inst_in_off_idx;              // Used to insert in after the offset.
// ====================================================================
// Wires Declarations End 
// ====================================================================
// ====================================================================
// Combinational Logic Start
// ====================================================================
    // Gets a bit array used to help modify the write section of queue.
    get_valid_bit_window comb_insert_window
    ( 
        .start_idx_i    ( curr_context_i.tail_ptr ), 
        .window_num_i   ( inst_num_i              ),
        .bit_arr_o      ( insert_window           ) 
    );

    // If the response == the tag
    assign cache_hit        = ic_if_i.response == ic_if_i.tag && ic_if_i.tag != 0; // if both are zero, then still isn't cache hit.
    assign data_as_inst     = ic_if_i.data;     // helps with indexing
    assign inst_in_off_idx  = curr_context_i.PC_reg[`CACHE_OFFSET_WIDTH-1:0] >> $clog2(`XLEN_BYTES); // Gives the offset to start inserting in the block from
// ====================================================================
// Define how the thread_buff for the next state should be configured 
// (pushing in elements after the tail)
// ====================================================================

    // Creates an index array used to find which fetch instruction choose
    // to insert into a writeable entry. The choosing of the width results in
    // overflowing and hence wrap arounds. This should handle non two's powers inserts 
    // Which may be necessary to maintain cache block alignment.
    always_comb
    begin
        for ( int offset = 0; offset < `IF_NUM; ++offset )
        begin
            if ( curr_context_i.tail_ptr[`FIQ_IDX_WIDTH-1:0] + offset < `FIQ_NUM ) 
                idx_array[ offset ] = curr_context_i.tail_ptr[`FIQ_IDX_WIDTH-1:0] + offset;
            else // Wrap around
                idx_array[ offset ] = curr_context_i.tail_ptr[`FIQ_IDX_WIDTH-1:0] + offset - `FIQ_NUM;
        end
    end // always_comb

    // Inputs all parts of inst_i as a possible index and chooses between them depending on whether
    // This particular index also corresponds.
    always_comb
    begin
        // Invariants (recall that x means unknown)
        /*
        assert( ^inst_num_i === 1'bx || ^curr_context_i.avail_size === 1'bx ||
            inst_num_i <= curr_context_i.avail_size ) // It must be the case that the instructions coming in
                                                        // mustn't exceed the available number of spaces.
            else $display( "Expected number of instructions(%d) being inserted to be LTEQ to curr available size(%d)", inst_num_i, curr_context_i.avail_size );
        invarients = 0; // Clear everything
        */

        for ( int idx = 0; idx < `FIQ_NUM; ++idx )
        begin
            if ( insert_window[ idx ] ) // If this index corresponds to a writeable entry.
            begin
                // Use an encoder like logic which will choose which instruction to actually insert (aka just a mux).
                // invarients[ idx ] = 1'b0;
                for ( int inst_i_idx = 0; inst_i_idx < `IF_NUM; inst_i_idx++ ) // Needs to range to a constant (inst_num_i b/f -> this is not synthesizable since it doesn't make sense to compare a variable number of indices)
                begin
                    // We can mask to force a wrap around
                    if ( idx_array[ inst_i_idx ] == idx ) // Assumes that can wrap around 
                    begin
                        //assert( invarients[ idx ] != 1'b1 ) else $display( "Idx: %0d, maps to more than one entry(incorrect!)\n(insert_window[ idx ] == %b", idx, insert_window[ idx ] ); // Essentially ensure that only maps once.
                        n_fetch_buff_o[ idx ].inst          = ( cache_hit ) ? data_as_inst[ inst_in_off_idx + inst_i_idx ] : 'd0; // Make sure we have an invalid instruction // Make sure we have an invalid instruction.
                        n_fetch_buff_o[ idx ].pc            = curr_context_i.PC_reg + ( inst_i_idx << 2 );
                        n_fetch_buff_o[ idx ].mem_tag       = ( cache_hit ) ? 'd0 : ic_if_i.response;   // Keep track for transaction since data isn't ready.
                        n_fetch_buff_o[ idx ].br_predict    = 1'b0;
                        // $display( "(Entry: %0d)PC at inst_i_idx: %0d -> PC: %0d", idx, inst_i_idx, n_fetch_buff_o[idx].pc );
                        // invarients[ idx ] = 1'b1;
                    end
                end // for
                //assert( !insert_window[ idx ] || invarients[ idx ] == 1'b1 ) else $display( "Idx: %0d, maps to no entry(incorrect!)\n(insert_window[ idx ] == %b)", idx, insert_window[ idx ] ); // Essentially ensure that maps to one entry.
            end 
            else // maintain the current value (may still be updated ouside)-> Via popping.
            begin
               n_fetch_buff_o[ idx ]  = curr_context_i.inst_buff[ idx ]; // To prevent latches.
            end // else

            // Also consider for the responses coming from the cache.
            if ( ic_if_i.tag != 'd0 && curr_context_i.inst_buff[ idx ].mem_tag == ic_if_i.tag ) // Then we need to check every entry to update it.
            begin
                // This memory is for us!
                // Index into the right bits to receive.
                // $display( "Inserting indx: %0d",  curr_context_i.inst_buff[ idx ].pc[`CACHE_OFFSET_WIDTH-1:0] >> $clog2( `XLEN_BYTES ) );
                // $display( "Intruction: %0h", data_as_inst[ 
                //                         curr_context_i.inst_buff[ idx ].pc[`CACHE_OFFSET_WIDTH-1:0] >> $clog2( `XLEN_BYTES ) 
                //                         ] );
                n_fetch_buff_o[ idx ].inst = data_as_inst[ 
                                        curr_context_i.inst_buff[ idx ].pc[`CACHE_OFFSET_WIDTH-1:0] >> $clog2( `XLEN_BYTES ) 
                                        ];
                n_fetch_buff_o[ idx ].mem_tag = 'd0;    // This instruction is no long er pending.   
            end
        end // for

        n_tail_ptr_o   = curr_context_i.tail_ptr + inst_num_i;
    end // always_comb

// ====================================================================
// Combinational Logic End
// ====================================================================
endmodule:next_state_insert_queue 

// Simply updates the head pointer, incrementing by amount extracted.
module next_state_pop_queue ( 
    input   CONTEXT                                   thread_i        ,
    input   logic [`DP_NUM_WIDTH-1:0]                 inst_num_sel_i  ,
    output  logic [`FIQ_IDX_WIDTH:0]                   n_hd_ptr_o     
);
    assign n_hd_ptr_o = thread_i.hd_ptr + inst_num_sel_i;
endmodule:next_state_pop_queue 

module next_pc_logic ( 
    input  CONTEXT                                  thread_i         ,
    input  logic [`IF_NUM_WIDTH-1:0]                inst_num_i       , // number of instructions to be inserted.
    input  logic                                    br_mis_v_i       ,
    input  logic [`XLEN-1:0]                        br_mis_pc_i      ,
    input  logic                                    pc_en_i          , // Disable pc when can't proceed.
    output logic [`XLEN-1:0]                        next_PC_o          
);
    always_comb
    begin
        if ( br_mis_v_i ) begin
            // $display( "Branch mispredict! Br_target: %h", br_mis_pc_i );
            next_PC_o = br_mis_pc_i;
        end else if ( pc_en_i ) begin
            // We need to increment the PC by 4 times the inst_fetched 
            // (since RISC is byte-addressable memory)
            next_PC_o = thread_i.PC_reg + ( inst_num_i << 2 ); //! Also stays then same if no instructions was inserted.
        end else begin
            next_PC_o = thread_i.PC_reg;
        end
    end // always_comb
endmodule:next_pc_logic 

// Gets a bit array that specifies the window of entires that may be inserted (e.g. after the tail pointer).
// E.g  [0, 0, T(1), 1, 1, IE(0) ].
module get_valid_bit_window # (
    parameter C_IDX_WIDTH   =   `FIQ_IDX_WIDTH                ,    // Used to specify the index width for the number we are expanding from
    parameter C_NUM_WIDTH   =   `IF_NUM_WIDTH                ,
    parameter C_NUM         =   `FIQ_NUM                           // Used to specify the width of the bit array we are expanding the ones to.
)(  
    input  logic [C_IDX_WIDTH:0]          start_idx_i        ,    // start index (extra bit to detect wrap arounds).
    input  logic [C_NUM_WIDTH-1:0]        window_num_i       ,    // How long is the window?
    output logic [C_NUM-1:0]              bit_arr_o               // Resulting array.
);

// ====================================================================
// Wires Declarations Start
// ====================================================================

    logic [C_IDX_WIDTH:0]           window_idx_end          ;            // Specifies the index in which the window ends
    logic                           wrap_around             ;            // Does the bit window wrap around?

    always_comb
    begin
        // Invariants (^window_num_i does a bitwise xor. Thus don't check condition when to_insert_num_i is X ).
        // assert ( ^window_num_i === 1'bx || window_num_i <= C_NUM ) 
        //     else $display( "Expected LTEQ: %d, Got: %d", C_NUM, window_num_i  ); // Is the amount that will be inserted within the maximum?

        // Applies various conditionals depending on whether a loop around occured.
        // E.g. if none, we can conclude that it's valid iff T <= idx < IE. [0, 0, T(1), 1, 1, IE(0) ].
        //      o.w. T <= idx || idx < IE. [IE(0), 0, T(1), 1, 1, 1 ] 
        //      -> only when T <= idx (IE is zero so no idx exists that's less than it).
        window_idx_end  = start_idx_i + window_num_i; // AKA IE (insert end).
        wrap_around     = start_idx_i[C_IDX_WIDTH] ^ window_idx_end[C_IDX_WIDTH]; // If differs, did indeed.
        for ( int n = 0; n < C_NUM; n++ ) begin
            // tail_idx[C_NUM_IDX_WIDTH-1:0] <= n bc tail_idx is inclusive!
            if ( wrap_around ) 
                bit_arr_o[ n ] = ( start_idx_i[C_IDX_WIDTH-1:0] <= n || n < window_idx_end[C_IDX_WIDTH-1:0] );
            else // No wrap around (duh)
                bit_arr_o[ n ] = ( start_idx_i[C_IDX_WIDTH-1:0] <= n && n < window_idx_end[C_IDX_WIDTH-1:0] );
        end // for
    end // always_comb

endmodule:get_valid_bit_window 

module output_logic_IC #(
    parameter C_THREAD_NUM  = `THREAD_NUM                       ,
    parameter C_IF_NUM      = `IF_NUM                           ,
    parameter C_THREAD_IDX  = `THREAD_IDX_WIDTH
)(
    input   CONTEXT [C_THREAD_NUM-1:0]          context_i        ,
    input   logic   [C_THREAD_IDX-1:0]          thread_to_ft_i   ,        // Current thread in which supposed to fetch from cache.
    output  MEM_IN                              if_ic_o         
);
    assign if_ic_o.addr     = { context_i[ thread_to_ft_i ].PC_reg[`XLEN-1:3], 3'b0 }; 
    assign if_ic_o.size     = DOUBLE;   // Always a double (aka block size)
    assign if_ic_o.command  = context_i[ thread_to_ft_i ].avail_size > 0 ? BUS_LOAD : BUS_NONE; // Don't request anything if full.
    assign if_ic_o.data     = 'd0;        // Make sure that there's no x's.
endmodule:output_logic_IC

// Wires up based on the pointers provided
// Use the unif_q_i to create an interface for DP to utilize.
module output_FIQ # (
    parameter C_DP_NUM              = `DP_NUM          ,
    parameter C_DP_IDX_WIDTH        = `DP_NUM_WIDTH    ,
    parameter C_FIQ_NUM             = `FIQ_NUM         ,
    parameter C_FIQ_IDX_WIDTH       = `FIQ_IDX_WIDTH   ,
    parameter C_FIQ_NUM_WIDTH       = `FIQ_NUM_WIDTH   , // Recall this is $clog2( `FIQ_NUM + 1 )
    parameter C_THREAD_NUM          = `THREAD_NUM      ,             
    parameter C_THREAD_IDX_WIDTH    = `THREAD_IDX_WIDTH          
)(
    input   logic                                        clk_i               ,
    input   logic                                        rst_i               ,
    input   CONTEXT [C_THREAD_NUM-1:0]                   threads_i           ,    // Used to get instructions out of buff
    input   BR_MIS                                       br_mis_i            ,
    output  [C_THREAD_IDX_WIDTH-1:0]                     thread_idx_disp_o   ,    // How to update the counter.
    output  FIQ_DP                                       fiq_dp_o
);
// ====================================================================
// Wires Declarations Start
// ====================================================================
    logic   [C_DP_NUM-1:0][C_FIQ_IDX_WIDTH-1:0]  indices         ;
    logic   [C_THREAD_IDX_WIDTH-1:0]            thread_counter   ;   // Counter which is used to chose between which thread to dispatch.
    logic   [C_THREAD_IDX_WIDTH-1:0]            thread_idx       ;
    CONTEXT                                     thread_of        ;   // Thread in which FIQ obtains from.

    assign thread_idx_disp_o = thread_idx;           // Drive outside of interface

    // Create an index which is utilized as a selector for the subsequent combinational logic.
    always_comb
    begin
        // Determine the next thread to choose from
        if ( br_mis_i.valid[ thread_counter ] || threads_i[ thread_counter ].avail_size == C_FIQ_NUM ) // If branch mispredict, or queue is empty
        begin
            thread_idx = thread_counter + 1; // Choose the next thread instead
        end // if
        else 
        begin
            thread_idx = thread_counter;     // Choose this thread instead.
        end
        // Should fall through
        thread_of  = threads_i[ thread_idx ];

        // Populate with indices (we will use this in the following)
        for ( int n = 0; n < C_DP_NUM; ++n )
        begin
            indices[ n ] = ( thread_of.hd_ptr + n < C_FIQ_NUM ) ? 
                            thread_of.hd_ptr + n : 
                            thread_of.hd_ptr + n - C_FIQ_NUM; // Else wrap around
        end // for
    end // always_comb

    // Sequential Logic for thread_counter
    always_ff @ (posedge clk_i )
    begin
        if ( rst_i ) begin
            thread_counter <= 'SD 0; // Start at zero again.
        end else begin
            thread_counter <= `SD thread_idx + 1;  // Point to the next thread.
        end
    end

    // Mux every entry and use the index to select the proper instruction.
    always_comb
    begin
        if ( br_mis_i.valid[ thread_idx ] )
            fiq_dp_o.avail_num = 'd0;
        else if (C_DP_NUM < ( C_FIQ_NUM - thread_of.avail_size ))
            fiq_dp_o.avail_num = C_DP_NUM;  // Put a ceiling on entries
        else
            fiq_dp_o.avail_num = C_FIQ_NUM  - thread_of.avail_size;

        // Mux entries into a wire queue.
        for ( int n = 0; n < C_DP_NUM; ++n )
        begin
            fiq_dp_o.inst[ n ]       = thread_of.inst_buff[ indices[ n ] ].inst;
            fiq_dp_o.thread_idx[ n ] = thread_idx;
            fiq_dp_o.pc[ n ]         = thread_of.inst_buff[ indices[ n ] ].pc;
            // Always not-taken for now.
            fiq_dp_o.br_predict[ n ] = thread_of.inst_buff[ indices[ n ] ].br_predict;    
        end // for  
    end // always_comb

endmodule:output_FIQ
