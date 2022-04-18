module IF_IC_tb( );


    MEM_IN                              proc2mem    ;
    MEM_OUT                             mem2proc    ;
    MEM_IN                              if_ic;
    MEM_OUT                             ic_if;
    DP_FIQ                              dp_fiq;     
    FIQ_DP                              fiq_dp;
    logic                               clk_i;
    logic                               rst_i;
    BR_MIS                              br_mis;

    initial begin
        clk_i   = 0;
        forever begin
            #(`VERILOG_CLOCK_PERIOD/2.0) clk_i   =   ~clk_i;
        end
    end // initial

    // Instantiate the Data Memory
    mem memory (
        // Inputs
        .clk               ( clk_i           ),
        .proc2mem_command  ( if_ic.command   ),
        .proc2mem_addr     ( if_ic.addr      ),
        .proc2mem_data     ( if_ic.data      ),
`ifndef CACHE_MODE
        .proc2mem_size     ( if_ic.size      ),
`endif

        // Outputs (to processor)
        .mem2proc_response ( ic_if.response  ),
        .mem2proc_data     ( ic_if.data      ),
        .mem2proc_tag      ( ic_if.tag       )
    );


    // icache IC (
    //     .mshr_array_mon_o   (/*imshr_array_mon_o*/  ),
    //     .cache_array_mon_o  (/*icache_array_mon_o*/ ),
    //     .clk_i              (clk_i              ),
    //     .rst_i              (rst_i              ),
    //     .proc2cache_i       (if_ic              ),
    //     .cache2proc_o       (ic_if              ),
    //     .memory_enable_i    ( 1'b1              ),
    //     .cache2mem_o        (proc2mem           ),
    //     .mem2cache_i        (mem2proc           )
    // ); 


    logic   [`THREAD_IDX_WIDTH-1:0] thrd_idx_disp;
    CONTEXT [`THREAD_NUM-1:0]       thrd_data;
    logic   [`THREAD_IDX_WIDTH-1:0] thrd_to_ft;
    IF dut (
        .clk_i     ( clk_i           ),           // system clock           
        .rst_i     ( rst_i           ),           // System reset
        .pc_en_i   ( 2'b11           ),           // Always enabled for this test.
        .rst_pc_i  ( 64'b0           ),
        .br_mis_i  ( br_mis          ),           // mis-predict  signal -> Never valid

        .ic_if_i   ( ic_if           ),           // Data coming back from insruction memory. 
        .dp_fiq_i  ( dp_fiq          ),           // Dispatch telling how many instructions were taken out.
        .if_ic_o   ( if_ic           ),           // Address sent to Intruction memory (to be feteched)
        .fiq_dp_o  ( fiq_dp          ),           // Output data packet from IFgoing to DP (this is the instruction, PC, PC+1, and whether to care about if (if valid)
        .thread_idx_disp_o_t( thrd_idx_disp ),
        .thread_data_o_t( thrd_data  ),           
        .thread_to_ft_o_t( thrd_to_ft )
    );

    initial
    begin
        @(posedge clk_i);
        @(posedge clk_i); // Give some time to initialize system?
        $readmemh("program.mem", memory.unified_memory);
        // $readmemh( "program.mem", memory.unified_memory );
        $display( "Here's the first stuff: %h", memory.unified_memory[ 0 ] );

        br_mis = 0;
        dp_fiq.dp_num = 0;
        @( negedge clk_i );
        $display( "Here's the first stuff: %h", memory.unified_memory[ 0 ] );
        rst_i = 1'b1;

        @( negedge clk_i  );
        rst_i = 1'b0;
        $display( "Starting simulation" );
        for ( int n = 0; n < 10000; ++n )
        begin
            @( negedge clk_i );
            $display( "Time: %4.0f", $time );
            if ( fiq_dp.avail_num > 0 )
                dp_fiq.dp_num = 1; // Just automatically dispatch one.
            else
                dp_fiq.dp_num = 0;

            if ( n % 100 == 0 )
            begin
                // Force a branch mispredict
                $display( "Test branch mispredict." );
                br_mis.valid[ 0 ] = 1'b1;
                br_mis.br_target[ 0 ] = 4;
            end
            else if ( n % 200 == 0 )
            begin
                br_mis.valid[ 1 ] = 1'b1;
                br_mis.br_target[ 1 ] = 4;
            end
            else
            begin
                for ( int n = 0; n < `THREAD_NUM; ++n )
                begin
                    br_mis.br_target[ n ] = 32'b0;
                    br_mis.valid[ n ] = 0;
                end
            end // else
            @( negedge clk_i ); `SD;
            print_IF( 2'b11, if_ic, ic_if, thrd_idx_disp, thrd_to_ft, thrd_data, br_mis );
        end // for

        $finish;
    end
endmodule:IF_IC_tb



function void print_IF (
    logic       [`THREAD_NUM-1:0]       pc_en           ,
    MEM_IN                              if_ic           ,
    MEM_OUT                             ic_if           ,
    logic       [`THREAD_IDX_WIDTH-1:0] thread_idx_disp ,
    logic       [`THREAD_IDX_WIDTH-1:0] thread_to_ft    ,
    CONTEXT     [`THREAD_NUM-1:0]       thread_data     ,
    BR_MIS                              br_mis          
);
    int valid_entries;
    int ptr;
    $display( "T=%0t IF Contents", $time );    // %d displays uses fixed width to accomodate largest possible value
    $display( "Instruction Buffers\n" );
    for ( int thrd_idx = 0; thrd_idx < `THREAD_NUM; ++thrd_idx )
    begin
                                                                // %0d displays the minimum width.
        $display( "Thread %0d, pc_en:%0d, br_mis_valid: %0b, br_mis_target:%0d", thrd_idx, pc_en[ thrd_idx ], br_mis.valid[ thrd_idx ], br_mis.br_target[ thrd_idx ] ); // Thread idx
        $display( "head=%0d, tail=%0d, Avail_size:%0d, PC_reg:%0d", thread_data[ thrd_idx ].hd_ptr[`FIQ_IDX_WIDTH-1:0], 
                                                        thread_data[ thrd_idx ].tail_ptr[`FIQ_IDX_WIDTH-1:0], 
                                                        thread_data[ thrd_idx ].avail_size,
                                                        thread_data[ thrd_idx ].PC_reg );
        // Calulate the number of entries in the fetch buffer.
        if ( thread_data[ thrd_idx ].hd_ptr[`FIQ_IDX_WIDTH-1:0] < thread_data[ thrd_idx ].tail_ptr[`FIQ_IDX_WIDTH-1:0] ) begin
            valid_entries = thread_data[ thrd_idx ].tail_ptr[`FIQ_IDX_WIDTH-1:0] - thread_data[ thrd_idx ].hd_ptr[`FIQ_IDX_WIDTH-1:0];
        end else if ( thread_data[ thrd_idx ].hd_ptr[`FIQ_IDX_WIDTH-1:0] != thread_data[ thrd_idx ].tail_ptr[`FIQ_IDX_WIDTH-1:0] ) begin
            valid_entries = `FIQ_NUM - thread_data[ thrd_idx ].hd_ptr[`FIQ_IDX_WIDTH-1:0] + thread_data[ thrd_idx ].tail_ptr[`FIQ_IDX_WIDTH-1:0];
        end else if ( !( thread_data[ thrd_idx ].hd_ptr[`FIQ_IDX_WIDTH-1:0] ^ thread_data[ thrd_idx ].tail_ptr[`FIQ_IDX_WIDTH-1:0] ) ) begin  // Need to check if full or not
            valid_entries = `FIQ_NUM;
        end else begin
            valid_entries = 0;
        end // else
        /*
        if ( valid_entries != `FIQ_NUM - thread_data[ thrd_idx ].avail_size ) begin
            $display( "Size doesn't match! (aborting)" );
            $finish;
        end // if
        */
        $display("Index\t|PC\t|Inst\t|Mem_tag\t|br_predict");
        for ( logic [`FIQ_NUM_WIDTH-1:0] entry = 0; entry < `FIQ_NUM; ++entry )
        begin
            $display( "%d\t|%h\t|%h\t|%d|\t%d", entry, 
                                    thread_data[ thrd_idx ].inst_buff[entry].pc, 
                                    thread_data[ thrd_idx ].inst_buff[entry].inst,
                                    thread_data[ thrd_idx ].inst_buff[entry].mem_tag,
                                    thread_data[ thrd_idx ].inst_buff[entry].br_predict );
        end // for
    end // for  
    $display( "Thread_idx_disp: %0d", thread_idx_disp );
    $display( "Thread_idx_ft: %0d", thread_to_ft );
    

    // print out IF_IC and IC_IF 
    $display( "IF_IC(MEM_IN)" );
    $display("T=%0t addr=%0d, data=%0d, size=%0d, command=%0d\n",	
            $time           , 	
            if_ic.addr      ,	
            if_ic.data      ,	
            if_ic.size      ,	
            if_ic.command   
            );
    

    $display( "IC_IF(MEM_OUT)" );
    $display("T=%0t response=%0d, data=%0h, tag=%0d\n",	
            $time           , 	
            ic_if.response  ,	
            ic_if.data      ,	
            ic_if.tag       	
            );
endfunction:print_IF