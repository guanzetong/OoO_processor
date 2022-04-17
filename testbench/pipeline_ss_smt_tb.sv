// ====================================================================
// Transaction Object Start
// ====================================================================
// `define SMT_EN
class gen_item; // GEN -> DRV
    rand int    dp_num  ;   // # Dispatch
    rand int    cp_num  ;   // # Complete

    function void print (string msg_tag="");
        $display("T=%0t %s Generator requests #Dispatch=%0d, #Complete=%0d",
                $time, msg_tag, dp_num, cp_num);
    endfunction // print
endclass // gen_item
// ====================================================================
// Transaction Object End
// ====================================================================

// ====================================================================
// Driver Start
// ====================================================================
class driver;
    virtual pipeline_ss_smt_if              vif                     ;
    mailbox                                 drv_mbx                 ;
    event                                   drv_done                ;
    logic   [`THREAD_IDX_WIDTH-1:0]         thread_sel              ;
    logic   [`THREAD_NUM-1:0][`XLEN-1:0]    pc                      ;
    logic   [`XLEN-1:0]                     inst_pc                 ;
    logic   [`XLEN-1:0]                     program_mem_addr        ;
    logic   [64-1:0]                        program_mem_data        ;
    logic   [64-1:0]                        program_mem     [`MEM_64BIT_LINES-1:0];

    task run();
        $display("T=%0t [Driver] starting ...", $time);

        // Control Signals for which thread context can be utilized.

        vif.pc_en_i[ 0 ] = 1'b1;    // Enable PC (and keep it enabled)
`ifdef SMT_EN
        vif.pc_en_i[ 1 ] = 1'b1;    // Enable the other hart.
`else
        vif.pc_en_i[ 1 ] = 1'b0;
`endif
        // @(negedge vif.clk_i); // Already at the zero of clock period
        /* (already done in the top-level test module)
        for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
            vif_.rst_pc_i[thread_idx]  =   thread_idx * 'h100;
        end
        */

        thread_sel  =   0;

        @(negedge vif.clk_i);

        // $display("T=%0t [Driver] Reading program.mem", $time);
        // $readmemh("program.mem", program_mem);


        forever begin
            // gen_item    item;
            // drv_mbx.get(item);


/*
            /////////////////////////////////////////////////////////////////////////
            vif.fiq_dp.avail_num =   `DP_NUM;
            for (int unsigned dp_idx = 0; dp_idx < `DP_NUM; dp_idx++) begin
                vif.fiq_dp.thread_idx[dp_idx] = thread_sel;
            end
            /////////////////////////////////////////////////////////////////////////

            for (int unsigned dp_idx = 0; dp_idx < `DP_NUM; dp_idx++) begin
                inst_pc                 =   pc[thread_sel] + dp_idx * 4;
                program_mem_addr        =   {3'b0, inst_pc[`XLEN-1:3]};
                program_mem_data        =   program_mem[program_mem_addr];
                vif.fiq_dp.pc[dp_idx]   =   inst_pc;
                vif.fiq_dp.inst[dp_idx] =   inst_pc[2] ? program_mem_data[63:32] : program_mem_data[31:0];
            end

            /////////////////////////////////////////////////////////////////////////
            //Move PC
            @(posedge vif.clk_i);
            for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
                if (vif.rst_i) begin
                    pc[thread_idx]  =   thread_idx * 'h100;
                end else if (vif.br_mis_mon_o.valid[thread_idx]) begin
                    pc[thread_idx]  =   vif.br_mis_mon_o.br_target[thread_idx];
                end else if (thread_sel == thread_idx) begin
                    pc[thread_idx]  =   pc[thread_idx] + vif.dp_fiq.dp_num * 4;
                end
            end
            /////////////////////////////////////////////////////////////////////////

            $display("T=%0t [Driver] PC=%0h, dp_num=%0d", $time, pc, vif.dp_fiq.dp_num);

            vif.fiq_dp      =   0;
*/
            @(negedge vif.clk_i);
            vif.exception_i =   0;
            // thread_sel      =   thread_sel + 'd1;
            // ->drv_done;
        end
    endtask // run()

endclass //
// ====================================================================
// Driver End
// ====================================================================

// ====================================================================
// Scoreboard Start
// ====================================================================

// ====================================================================
// Scoreboard End
// ====================================================================

// ====================================================================
// Monitor Start
// ====================================================================
class monitor;
    virtual pipeline_ss_smt_if          vif                             ;
    mailbox                             scb_mbx                         ;
    logic   [`XLEN-1:0]                 wfi_pc      [`THREAD_NUM-1:0]   ;
    int                                 wb_fileno   [`THREAD_NUM-1:0]   ;
    string                              wb_filename                     ;
    logic   [`THREAD_NUM-1:0]           wfi_flag                        ;
    logic                               store_complete_flag             ;

    logic   [32-1:0]                    clk_cnt                         ;
    logic   [32-1:0]                    inst_cnt                        ;

    task run();
        // automatic string thrd_string;
        $display("T=%0t [Monitor] starting ...", $time);

        clk_cnt     =   0;
        inst_cnt    =   0;
    
        // Open writeback.out
        for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
`ifndef SMT_EN
            if (thread_idx == 0) begin
                wb_filename             =   {"writeback.out"};
                wb_fileno[thread_idx]   =   $fopen(wb_filename);
            end else begin
                wb_filename             =   {"writeback_t", (thread_idx + 'd48), ".out"};
                wb_fileno[thread_idx]   =   $fopen(wb_filename);
            end
`else
            wb_filename             =   {"writeback_t", (thread_idx + 'd48), ".out"};
            wb_fileno[thread_idx]   =   $fopen(wb_filename);
`endif
        end

        // Initialize wfi_pc
        for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
            wfi_pc[thread_idx]      =   32'hFFFFFFFF;
            wfi_flag[thread_idx]    =   1'b0        ;
        end
`ifndef SMT_EN
        wfi_flag[1] =   1'b1;
`endif


        forever begin
            @(posedge vif.clk_i);
            clk_cnt++;
            // If the first WFI instruction is dispatched, record its PC
            // wfi_pc is used to compare with the PC retired.
            // Testbench calls $finish if the retired PC match wfi_pc
            for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
                if (wfi_pc[thread_idx] == 32'hFFFFFFFF) begin
                    for (int unsigned dp_idx = 0; dp_idx < `DP_NUM; dp_idx++) begin
                        if (dp_idx < vif.dp_rs_mon_o.dp_num 
                        && vif.dp_rs_mon_o.dec_inst[dp_idx].halt == `TRUE
                        && vif.dp_rs_mon_o.dec_inst[dp_idx].thread_idx == thread_idx) begin
                            wfi_pc[thread_idx]  =   vif.dp_rs_mon_o.dec_inst[dp_idx].pc;
                        end
                    end
                end
            end

            // $display("%0d", vif.fiq_dp.avail_num);

            // print_IF(vif.pc_en_i, vif.if_ic_o_t, vif.ic_if_o_t, vif.thread_idx_disp_o_t, vif.thread_to_ft_o_t, vif.thread_data_o_t );
            // print_icache_mem(vif.icache_array_mon_o);
            // print_imshr(vif.imshr_array_mon_o);
            // print_vfl(vif.vfl_fl_mon_o);


            // print_rob(vif.rob_mon_o, vif.rob_head_mon_o, vif.rob_tail_mon_o);
            // print_rs(vif.rs_mon_o, vif.rs_cod_mon_o);
            // print_mt(vif.mt_mon_o);
            // print_amt(vif.amt_mon_o);
            // print_prf(vif.prf_mon_o);
            // print_ALU_ib(vif.ALU_queue_mon_o, vif.ALU_valid_mon_o, vif.ALU_head_mon_o, vif.ALU_tail_mon_o);
            // print_MULT_ib(vif.MULT_queue_mon_o, vif.MULT_valid_mon_o, vif.MULT_head_mon_o, vif.MULT_tail_mon_o);
            // print_BR_ib(vif.BR_queue_mon_o, vif.BR_valid_mon_o, vif.BR_head_mon_o, vif.BR_tail_mon_o);
            // print_STORE_ib(vif.STORE_queue_mon_o, vif.STORE_valid_mon_o, vif.STORE_head_mon_o, vif.STORE_tail_mon_o);
            // print_fl(vif.fl_mon_o);
            //print_vfl(vif.vfl_fl_mon_o);
            // print_mt_dp(vif.dp_mt_mon_o, vif.mt_dp_mon_o);
            // print_rt(vif.rt_pc_o, vif.rt_valid_o, vif.rob_amt_mon_o, vif.rob_fl_mon_o, vif.prf_mon_o);
            // print_cdb(vif.cdb_mon_o);
            print_lsq(vif.lsq_array_mon_o, vif.lsq_head_mon_o, vif.lsq_tail_mon_o);
            print_dmshr(vif.dmshr_array_mon_o);
            print_dcache_mem(vif.dcache_array_mon_o);

            // Monitor Retire
            for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
                for (int unsigned rt_idx = 0; rt_idx < `RT_NUM; rt_idx++) begin
                // Record write back of every retire to writeback.out
                    if (vif.rt_valid_o[thread_idx][rt_idx]) begin
                        if ((vif.rob_amt_mon_o[thread_idx][rt_idx].arch_reg != `ZERO_REG)
                        && (vif.rob_amt_mon_o[thread_idx][rt_idx].wr_en == 1'b1)) begin
                            $fdisplay(wb_fileno[thread_idx], "PC=%x, REG[%d]=%x",
                                (vif.rt_pc_o[thread_idx][rt_idx] - thread_idx * 'h100),
                                vif.rob_amt_mon_o[thread_idx][rt_idx].arch_reg,
                                vif.prf_mon_o[vif.rob_amt_mon_o[thread_idx][rt_idx].phy_reg]);
                        end else begin
                            $fdisplay(wb_fileno[thread_idx], "PC=%x, ---", 
                            (vif.rt_pc_o[thread_idx][rt_idx] - thread_idx * 'h100));
                        end
                        inst_cnt++;
                    end

                    // Check if the retired PC matches wfi_pc.
                    // If matched, exit.
                    if (vif.rt_valid_o[thread_idx][rt_idx]
                    && vif.rt_pc_o[thread_idx][rt_idx] == wfi_pc[thread_idx]) begin
                        wfi_flag[thread_idx]    =   1'b1;
                        $display("T=%0t [Monitor] WFI instruction retired at PC=%0h, exit thread %0d", $time, wfi_pc[thread_idx], thread_idx);
                    end // if
                end // for
            end // for

            store_complete_flag =   1;
            for (int unsigned idx = 0; idx < `MSHR_ENTRY_NUM; idx++) begin
                if (vif.dmshr_array_mon_o[idx].state != ST_IDLE) begin
                    store_complete_flag =   0;
                end
            end

            if ((&wfi_flag == 1) && (store_complete_flag == 1)) begin
                // print_lsq(vif.lsq_array_mon_o, vif.lsq_head_mon_o, vif.lsq_tail_mon_o);
                // print_dmshr(vif.dmshr_array_mon_o);
                // print_dcache_mem(vif.dcache_array_mon_o);
                $display("All the threads are completed. exit program.");
                $display("@@@ Unified Memory contents hex on left, decimal on right: ");
                show_mem_with_decimal(0,`MEM_64BIT_LINES - 1); 
                $display("@@  %t : System halted\n@@", $realtime);
                $display("@@@ System halted on WFI instruction");
                $display("@@@\n@@");
                show_CPI;
                $fclose(wb_fileno);
                #100 $finish;
            end
        end
    endtask

    task show_mem_with_decimal;
        input [31:0] start_addr;
        input [31:0] end_addr;
        int showing_data;
        logic   [`DCACHE_IDX_WIDTH-1:0]  dcache_idx;
        logic   [`DCACHE_TAG_WIDTH-1:0]  dcache_tag;
        logic                            dcache_hit;
        logic [64-1:0]  dcache_data;
        begin
            $display("@@@");
            showing_data=0;
            for(int k = start_addr; k <= end_addr; k = k +1) begin
                dcache_hit  =   0;
                dcache_idx  =   k[`DCACHE_IDX_WIDTH-1:0];
                dcache_tag  =   k[`DCACHE_IDX_WIDTH+:`DCACHE_TAG_WIDTH];
                // $display("tag = %0h, idx = %0h", dcache_tag, dcache_idx);
                for (int unsigned way_idx = 0; way_idx < `DCACHE_SASS; way_idx++) begin
                    // $display("cache tag = %0h", vif.dcache_array_mon_o[dcache_idx][way_idx].tag);
                    if ((vif.dcache_array_mon_o[dcache_idx][way_idx].valid == 1'b1)
                    && (vif.dcache_array_mon_o[dcache_idx][way_idx].dirty == 1'b1)
                    && (vif.dcache_array_mon_o[dcache_idx][way_idx].tag == dcache_tag)
                    && (vif.dcache_array_mon_o[dcache_idx][way_idx].data != 0)) begin
                        dcache_data =   vif.dcache_array_mon_o[dcache_idx][way_idx].data;
                        dcache_hit  =   1;
                        break;
                    end
                end
                if (dcache_hit) begin
                    $display("@@@ mem[%5d] = %x : %0d", k*8, dcache_data, 
                                                            dcache_data);
                    showing_data=1;
                end else if (vif.unified_memory[k] != 0) begin
                    $display("@@@ mem[%5d] = %x : %0d", k*8, vif.unified_memory[k], 
                                                            vif.unified_memory[k]);
                    showing_data=1;
                end else if(showing_data!=0) begin
                    $display("@@@");
                    showing_data=0;
                end
            end
            $display("@@@");
        end
    endtask  // task show_mem_with_decimal

    task show_CPI;
        real cpi;
        
        begin
            cpi = (clk_cnt + 1.0) / inst_cnt;
            $display("@@  %0d cycles / %0d instrs = %f CPI\n@@",
                      clk_cnt+1, inst_cnt, cpi);
            $display("@@  %4.2f ns total time to execute\n@@\n",
                      clk_cnt*`VERILOG_CLOCK_PERIOD);
        end
    endtask  // task show_clk_count 

    function void print_IF (
        logic       [`THREAD_NUM-1:0]       pc_en           ,
        MEM_IN                              if_ic           ,
        MEM_OUT                             ic_if           ,
        logic       [`THREAD_IDX_WIDTH-1:0] thread_idx_disp ,
        logic       [`THREAD_IDX_WIDTH-1:0] thread_to_ft    ,
        CONTEXT     [`THREAD_NUM-1:0]       thread_data     
    );
        int valid_entries;
        int ptr;
        $display( "T=%0t IF Contents", $time );    // %d displays uses fixed width to accomodate largest possible value
        $display( "Instruction Buffers\n" );
        for ( int thrd_idx = 0; thrd_idx < `THREAD_NUM; ++thrd_idx )
        begin
                                                                    // %0d displays the minimum width.
            $display( "Thread %0d, pc_en:%0d", thrd_idx, pc_en[ thrd_idx ] ); // Thread idx
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

    function void print_rob(
        ROB_ENTRY   [`THREAD_NUM-1:0][`ROB_ENTRY_NUM-1:0]    rob_mon         ,
        logic       [`THREAD_NUM-1:0][`ROB_IDX_WIDTH-1:0]    rob_head_mon    ,
        logic       [`THREAD_NUM-1:0][`ROB_IDX_WIDTH-1:0]    rob_tail_mon
    );
        for(int thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
            $display("T=%0t ROB[%0d] Contents", $time, thread_idx);
            $display("head=%0d, tail=%0d", rob_head_mon[thread_idx], rob_tail_mon[thread_idx]);
            $display("Index\t|valid\t|PC\t|rd\t|told\t|tag\t|br_predict\t|br_result\t|br_target\t|complete");      
            for (int entry_idx = 0; entry_idx < `ROB_ENTRY_NUM; entry_idx++) begin
                $display("%0d\t|%0d\t|%0h\t|%0d\t|%0d\t|%0d\t|%0d\t\t|%0d\t\t|%0d\t\t|%0d",
                entry_idx                                   ,
                rob_mon[thread_idx][entry_idx].valid        ,
                rob_mon[thread_idx][entry_idx].pc           ,
                rob_mon[thread_idx][entry_idx].rd           ,
                rob_mon[thread_idx][entry_idx].tag_old      ,
                rob_mon[thread_idx][entry_idx].tag          ,
                rob_mon[thread_idx][entry_idx].br_predict   ,
                rob_mon[thread_idx][entry_idx].br_result    ,
                rob_mon[thread_idx][entry_idx].br_target    ,
                rob_mon[thread_idx][entry_idx].complete     
                );
            end
        end
    endfunction

    function void print_rs(RS_ENTRY [`RS_ENTRY_NUM-1:0] rs_mon, logic [$clog2(`RS_ENTRY_NUM)-1:0] rs_cod_mon);
        string  op_string   ;
        $display("T=%0t RS Contents", $time);
        $display("RS COD=%0d", rs_cod_mon);
        $display("Index\t|op\t|valid\t|PC\t|tag\t|tag1\t|ready\t|tag2\t|ready\t|rob_idx");
        for (int entry_idx = 0; entry_idx < `RS_ENTRY_NUM; entry_idx++) begin
            if (rs_mon[entry_idx].dec_inst.rd_mem   ) begin
                op_string   =   "LD";
            end else if (rs_mon[entry_idx].dec_inst.wr_mem   ) begin
                op_string   =   "ST";
            end else if (rs_mon[entry_idx].dec_inst.cond_br  ) begin
                op_string   =   "CBR";
            end else if (rs_mon[entry_idx].dec_inst.uncond_br) begin
                op_string   =   "UBR";
            end else if (rs_mon[entry_idx].dec_inst.halt     ) begin
                op_string   =   "WFI";
            end else if (rs_mon[entry_idx].dec_inst.illegal  ) begin
                op_string   =   "ILL";
            end else if (rs_mon[entry_idx].dec_inst.csr_op   ) begin
                op_string   =   "CSR";
            end else if (rs_mon[entry_idx].dec_inst.alu      ) begin
                op_string   =   "ALU";
            end else if (rs_mon[entry_idx].dec_inst.mult     ) begin
                op_string   =   "MUL";
            end else begin
                op_string   =   "-";
            end
            // $display("ALU=%0b, CSR=%0b", rs_mon[entry_idx].dec_inst.alu, rs_mon[entry_idx].dec_inst.csr_op);
            $display("%0d\t|%s\t|%0d\t|%0h\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d",
            entry_idx                               ,
            op_string                               ,
            rs_mon[entry_idx].valid                 ,
            rs_mon[entry_idx].dec_inst.pc           ,
            rs_mon[entry_idx].dec_inst.tag          ,
            rs_mon[entry_idx].dec_inst.tag1         ,
            rs_mon[entry_idx].dec_inst.tag1_ready   ,
            rs_mon[entry_idx].dec_inst.tag2         ,
            rs_mon[entry_idx].dec_inst.tag2_ready   ,
            rs_mon[entry_idx].dec_inst.rob_idx      
            );
        end
    endfunction

    function void print_mt(MT_ENTRY [`THREAD_NUM-1:0][`ARCH_REG_NUM-1:0] mt_mon);
        for(int thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
            $display("T=%0t MT[%0d] Contents", $time, thread_idx);
            $display("arch\t|tag\t|ready\t|arch\t|tag\t|ready\t");
            for (int arch_idx = 0; arch_idx < `ARCH_REG_NUM/2; arch_idx++) begin
                $display("%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t", 
                arch_idx, mt_mon[thread_idx][arch_idx].tag, mt_mon[thread_idx][arch_idx].tag_ready,
                arch_idx+`ARCH_REG_NUM/2, mt_mon[thread_idx][arch_idx+`ARCH_REG_NUM/2].tag, mt_mon[thread_idx][arch_idx+`ARCH_REG_NUM/2].tag_ready);
            end
        end
    endfunction

    function void print_amt(AMT_ENTRY [`THREAD_NUM-1:0][`ARCH_REG_NUM-1:0] amt_mon);
        for(int thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
            $display("T=%0t AMT[%0d] Contents", $time, thread_idx);
            $display("arch\t|tag\t|arch\t|tag\t|arch\t|tag\t|arch\t|tag\t");
            for (int arch_idx = 0; arch_idx < `ARCH_REG_NUM/4; arch_idx++) begin
                $display("%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t", 
                arch_idx, amt_mon[thread_idx][arch_idx].amt_tag,
                arch_idx+`ARCH_REG_NUM/4, amt_mon[thread_idx][arch_idx+`ARCH_REG_NUM/4].amt_tag,
                arch_idx+`ARCH_REG_NUM/2, amt_mon[thread_idx][arch_idx+`ARCH_REG_NUM/2].amt_tag,
                arch_idx+`ARCH_REG_NUM*3/4, amt_mon[thread_idx][arch_idx+`ARCH_REG_NUM*3/4].amt_tag,
                );
            end
        end
    endfunction

    function void print_ALU_ib(
        IS_INST     [`ALU_Q_SIZE-1:0]       ALU_queue_mon   , 
        logic       [`ALU_Q_SIZE-1:0]       ALU_valid_mon   ,
        logic       [`ALU_IDX_WIDTH-1:0]    ALU_head_mon    ,
        logic       [`ALU_IDX_WIDTH-1:0]    ALU_tail_mon    
    );
        $display("T=%0t ALU IB Queue Contents", $time);
        $display("head=%0d, tail=%0d", ALU_head_mon, ALU_tail_mon);
        $display("Index\t|valid\t|PC\t|rs1\t|rs2\t|tag\t|rob_idx\t");
        for (int entry_idx = 0; entry_idx < `ALU_Q_SIZE; entry_idx++) begin
            $display("%0d\t|%0d\t|%0h\t|%0d\t|%0d\t|%0d\t|%0d\t", 
            entry_idx,
            ALU_valid_mon[entry_idx],
            ALU_queue_mon[entry_idx].pc,
            ALU_queue_mon[entry_idx].rs1_value,
            ALU_queue_mon[entry_idx].rs2_value,
            ALU_queue_mon[entry_idx].tag,
            ALU_queue_mon[entry_idx].rob_idx
            );
        end
    endfunction

    function void print_MULT_ib(
        IS_INST     [`MULT_Q_SIZE-1:0]      MULT_queue_mon  ,
        logic       [`MULT_Q_SIZE-1:0]      MULT_valid_mon  ,
        logic       [`MULT_IDX_WIDTH-1:0]   MULT_head_mon   ,
        logic       [`MULT_IDX_WIDTH-1:0]   MULT_tail_mon    
    );
        $display("T=%0t MULT IB Queue Contents", $time);
        $display("head=%0d, tail=%0d", MULT_head_mon, MULT_tail_mon);
        $display("Index\t|valid\t|PC\t|rs1\t|rs2\t|tag\t|rob_idx\t");
        for (int entry_idx = 0; entry_idx < `MULT_Q_SIZE; entry_idx++) begin
            $display("%0d\t|%0d\t|%0h\t|%0d\t|%0d\t|%0d\t|%0d\t", 
            entry_idx,
            MULT_valid_mon[entry_idx],
            MULT_queue_mon[entry_idx].pc,
            MULT_queue_mon[entry_idx].rs1_value,
            MULT_queue_mon[entry_idx].rs2_value,
            MULT_queue_mon[entry_idx].tag,
            MULT_queue_mon[entry_idx].rob_idx
            );
        end
    endfunction

    function void print_BR_ib(
        IS_INST     [`BR_Q_SIZE-1:0]        BR_queue_mon    , 
        logic       [`BR_Q_SIZE-1:0]        BR_valid_mon    ,
        logic       [`BR_IDX_WIDTH-1:0]     BR_head_mon     ,
        logic       [`BR_IDX_WIDTH-1:0]     BR_tail_mon    
    );
        $display("T=%0t BR IB Queue Contents", $time);
        $display("head=%0d, tail=%0d", BR_head_mon, BR_tail_mon);
        $display("Index\t|valid\t|PC\t|rs1\t|rs2\t|tag\t|rob_idx\t");
        for (int entry_idx = 0; entry_idx < `BR_Q_SIZE; entry_idx++) begin
            $display("%0d\t|%0d\t|%0h\t|%0d\t|%0d\t|%0d\t|%0d\t", 
            entry_idx,
            BR_valid_mon[entry_idx],
            BR_queue_mon[entry_idx].pc,
            BR_queue_mon[entry_idx].rs1_value,
            BR_queue_mon[entry_idx].rs2_value,
            BR_queue_mon[entry_idx].tag,
            BR_queue_mon[entry_idx].rob_idx
            );
        end
    endfunction

    function void print_STORE_ib(
        IS_INST     [`STORE_Q_SIZE-1:0]        STORE_queue_mon    , 
        logic       [`STORE_Q_SIZE-1:0]        STORE_valid_mon    ,
        logic       [`STORE_IDX_WIDTH-1:0]     STORE_head_mon     ,
        logic       [`STORE_IDX_WIDTH-1:0]     STORE_tail_mon    
    );
        $display("T=%0t STORE IB Queue Contents", $time);
        $display("head=%0d, tail=%0d", STORE_head_mon, STORE_tail_mon);
        $display("Index\t|valid\t|PC\t|rs1\t|rs2\t|tag\t|rob_idx\t");
        for (int entry_idx = 0; entry_idx < `STORE_Q_SIZE; entry_idx++) begin
            $display("%0d\t|%0d\t|%0h\t|%0d\t|%0d\t|%0d\t|%0d\t", 
            entry_idx,
            STORE_valid_mon[entry_idx],
            STORE_queue_mon[entry_idx].pc,
            STORE_queue_mon[entry_idx].rs1_value,
            STORE_queue_mon[entry_idx].rs2_value,
            STORE_queue_mon[entry_idx].tag,
            STORE_queue_mon[entry_idx].rob_idx
            );
        end
    endfunction

    function void print_prf(logic   [`PHY_REG_NUM-1:0] [`XLEN-1:0] prf_mon_o);
        $display("T=%0t PRF Contents", $time);
        $display("addr\t|data\t\t|addr\t|data\t\t|addr\t|data\t\t|addr\t|data\t\t");
        // $display("%0d", `PHY_REG_NUM/4);
        for (int reg_idx = 0; reg_idx < `PHY_REG_NUM/4; reg_idx++) begin
            $display("%0d\t|%8h\t|%0d\t|%8h\t|%0d\t|%8h\t|%0d\t|%8h\t", 
            reg_idx, prf_mon_o[reg_idx], 
            reg_idx+`PHY_REG_NUM/4, prf_mon_o[reg_idx+`PHY_REG_NUM/4],
            reg_idx+`PHY_REG_NUM/2, prf_mon_o[reg_idx+`PHY_REG_NUM/2],
            reg_idx+`PHY_REG_NUM*3/4, prf_mon_o[reg_idx+`PHY_REG_NUM*3/4]);
        end
    endfunction

    function void print_fl(FL_ENTRY [`FL_ENTRY_NUM-1:0] fl_mon);
        $display("T=%0t FL Contents", $time);
        $display("Index\t|Tag\t|TID\t|valid\t|Index\t|Tag\t|TID\t|valid\t|Index\t|Tag\t|TID\t|valid\t|Index\t|Tag\t|TID\t|valid\t|Index\t|Tag\t|TID\t|valid\t");
        // $display("%0d", `FL_ENTRY_NUM/4);
        for (int fl_idx = 0; fl_idx < `FL_ENTRY_NUM/5; fl_idx++) begin
            $display("%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t", 
            fl_idx, fl_mon[fl_idx].tag, fl_mon[fl_idx].thread_idx, fl_mon[fl_idx].valid,
            fl_idx+`FL_ENTRY_NUM/5, fl_mon[fl_idx+`FL_ENTRY_NUM/5].tag, fl_mon[fl_idx+`FL_ENTRY_NUM/5].thread_idx, fl_mon[fl_idx+`FL_ENTRY_NUM/5].valid,
            fl_idx+`FL_ENTRY_NUM*2/5, fl_mon[fl_idx+`FL_ENTRY_NUM*2/5].tag, fl_mon[fl_idx+`FL_ENTRY_NUM*2/5].thread_idx, fl_mon[fl_idx+`FL_ENTRY_NUM*2/5].valid,
            fl_idx+`FL_ENTRY_NUM*3/5, fl_mon[fl_idx+`FL_ENTRY_NUM*3/5].tag, fl_mon[fl_idx+`FL_ENTRY_NUM*3/5].thread_idx, fl_mon[fl_idx+`FL_ENTRY_NUM*3/5].valid,
            fl_idx+`FL_ENTRY_NUM*4/5, fl_mon[fl_idx+`FL_ENTRY_NUM*4/5].tag, fl_mon[fl_idx+`FL_ENTRY_NUM*4/5].thread_idx, fl_mon[fl_idx+`FL_ENTRY_NUM*3/5].valid);
        end
    endfunction

    // function void print_vfl(FL_ENTRY [`FL_ENTRY_NUM-1:0]  vfl_fl_mon);
    //     $display("T=%0t VFL Contents", $time);
    //     $display("Index\t|Tag\t|Index\t|Tag\t|Index\t|Tag\t|Index\t|Tag\t");
    //     // $display("%0d", `FL_ENTRY_NUM/4);
    //     for (int fl_idx = 0; fl_idx < `FL_ENTRY_NUM/4; fl_idx++) begin
    //         $display("%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t|%0d\t", 
    //         fl_idx, vfl_fl_mon[fl_idx].tag, 
    //         fl_idx+`FL_ENTRY_NUM/4, vfl_fl_mon[fl_idx+`FL_ENTRY_NUM/4].tag,
    //         fl_idx+`FL_ENTRY_NUM/2, vfl_fl_mon[fl_idx+`FL_ENTRY_NUM/2].tag,
    //         fl_idx+`FL_ENTRY_NUM*3/4, vfl_fl_mon[fl_idx+`FL_ENTRY_NUM*3/4].tag);
    //     end
    // endfunction

    function void print_mt_dp(
        DP_MT       [`THREAD_NUM-1:0][`DP_NUM-1:0]   dp_mt_mon   ,
        MT_DP       [`THREAD_NUM-1:0][`DP_NUM-1:0]   mt_dp_mon   
    );
        for(int thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
            $display("thread_idx=%0d", thread_idx);
            for (int dp_idx = 0; dp_idx < `DP_NUM; dp_idx++) begin
                $display("T=%0t DP_MT[%0d] rs1=%0d, rs2=%0d, rd=%0d, tag=%0d, wr_en=%0d, thread_idx=%0d",
                    $time, dp_idx       ,
                    dp_mt_mon[thread_idx][dp_idx].rs1       ,
                    dp_mt_mon[thread_idx][dp_idx].rs2       ,
                    dp_mt_mon[thread_idx][dp_idx].rd        ,
                    dp_mt_mon[thread_idx][dp_idx].tag       ,
                    dp_mt_mon[thread_idx][dp_idx].wr_en     ,
                    dp_mt_mon[thread_idx][dp_idx].thread_idx);

                $display("T=%0t MT_DP[%0d] tag1=%0d, tag1_ready=%0d, tag2=%0d, tag2_ready=%0d, tag_old=%0d",
                    $time, dp_idx       ,
                    mt_dp_mon[thread_idx][dp_idx].tag1      ,
                    mt_dp_mon[thread_idx][dp_idx].tag1_ready,
                    mt_dp_mon[thread_idx][dp_idx].tag2      ,
                    mt_dp_mon[thread_idx][dp_idx].tag2_ready,
                    mt_dp_mon[thread_idx][dp_idx].tag_old   );
                end
            end
    endfunction

    function void print_cdb(CDB [`CDB_NUM-1:0] cdb_mon);
        for (int cp_idx = 0; cp_idx < `CDB_NUM; cp_idx++) begin
            $display("T=%0t CDB[%0d] valid=%0d, pc=%0h, tag=%0d, rob_idx=%0d, thread_idx=%0d, br_result=%0d, br_traget=%0d",
                $time, cp_idx, 
                cdb_mon[cp_idx].valid     ,
                cdb_mon[cp_idx].pc        ,
                cdb_mon[cp_idx].tag       ,
                cdb_mon[cp_idx].rob_idx   ,
                cdb_mon[cp_idx].thread_idx,
                cdb_mon[cp_idx].br_result ,
                cdb_mon[cp_idx].br_target );
        end
    endfunction

    function void print_rt(
        logic   [`RT_NUM-1:0][`XLEN-1:0]        rt_pc           ,
        logic   [`RT_NUM-1:0]                   rt_valid        ,
        ROB_AMT [`THREAD_NUM-1:0][`RT_NUM-1:0]  rob_amt_mon     ,
        ROB_FL  [`THREAD_NUM-1:0]               rob_fl_mon      ,
        logic   [`PHY_REG_NUM-1:0][`XLEN-1:0]   prf_mon         
    );
        for(int thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
            $display("thread_idx=%0d", thread_idx);
            for (int rt_idx = 0; rt_idx < `RT_NUM; rt_idx++) begin
                $display("T=%0t RT[%0d] valid=%0d, pc=%0h, rd=%0d, tag=%0d, told=%0d, rd_value=%0d",
                    $time, rt_idx, 
                    rt_valid[rt_idx]                        ,
                    rt_pc[rt_idx]                           ,
                    rob_amt_mon[thread_idx][rt_idx].arch_reg            ,
                    rob_amt_mon[thread_idx][rt_idx].phy_reg             ,
                    rob_fl_mon[thread_idx].tag_old[rt_idx]              ,
                    prf_mon[rob_amt_mon[thread_idx][rt_idx].phy_reg]
                );
            end
        end
    endfunction

    function automatic string cmd_str_conv(input BUS_COMMAND cmd);
        begin
            case (cmd)
                BUS_NONE    :   cmd_str_conv    =   "BUS_NONE " ;
                BUS_LOAD    :   cmd_str_conv    =   "BUS_LOAD " ;
                BUS_STORE   :   cmd_str_conv    =   "BUS_STORE" ;
                default     :   cmd_str_conv    =   "ERROR    " ;
            endcase
        end
    endfunction

    function automatic string size_str_conv(input MEM_SIZE size);
        begin
            case (size)
                BYTE    :   size_str_conv   =   "BYTE  "    ;
                HALF    :   size_str_conv   =   "HALF  "    ;
                WORD    :   size_str_conv   =   "WORD  "    ;
                DOUBLE  :   size_str_conv   =   "DOUBLE"    ;
                default :   size_str_conv   =   "ERROR "    ;
            endcase
        end
    endfunction

    function automatic string mshr_state_str_conv(input MSHR_STATE state);
        begin
            case (state)
                ST_IDLE         :   mshr_state_str_conv =   "ST_IDLE       ";
                ST_WAIT_DEPEND  :   mshr_state_str_conv =   "ST_WAIT_DEPEND";
                ST_WAIT_EVICT   :   mshr_state_str_conv =   "ST_WAIT_EVICT ";
                ST_RD_MEM       :   mshr_state_str_conv =   "ST_RD_MEM     ";
                ST_WAIT_MEM     :   mshr_state_str_conv =   "ST_WAIT_MEM   ";
                ST_UPDATE       :   mshr_state_str_conv =   "ST_UPDATE     ";
                ST_OUTPUT       :   mshr_state_str_conv =   "ST_OUTPUT     ";
                ST_EVICT        :   mshr_state_str_conv =   "ST_EVICT      ";
                default         :   mshr_state_str_conv =   "ERROR         ";
            endcase
        end
    endfunction

    function automatic string lsq_state_str_conv(input LSQ_STATE state);
        begin
            case (state)
                LSQ_ST_IDLE         :   lsq_state_str_conv =   "ST_IDLE      ";
                LSQ_ST_ADDR         :   lsq_state_str_conv =   "ST_ADDR      ";
                LSQ_ST_DEPEND       :   lsq_state_str_conv =   "ST_DEPEND    ";
                LSQ_ST_RD_MEM       :   lsq_state_str_conv =   "ST_RD_MEM    ";
                LSQ_ST_WAIT_MEM     :   lsq_state_str_conv =   "ST_WAIT_MEM  ";
                LSQ_ST_LOAD_CP      :   lsq_state_str_conv =   "ST_LOAD_CP   ";
                LSQ_ST_ROB_RETIRE   :   lsq_state_str_conv =   "ST_ROB_RETIRE";
                LSQ_ST_WR_MEM       :   lsq_state_str_conv =   "ST_WR_MEM    ";
                LSQ_ST_RETIRE       :   lsq_state_str_conv =   "ST_RETIRE    ";
                default             :   lsq_state_str_conv =   "ERROR        ";
            endcase
        end
    endfunction

    function void print_dmshr(input MSHR_ENTRY [`MSHR_ENTRY_NUM-1:0] dmshr_array_mon);
        string  cmd_str     ;
        string  size_str    ;
        string  state_str   ;
        begin
            $display("T=%0t DCache MSHR Contents", $time);
            $display("index\t|state\t\t|cmd\t\t|req_addr\t|req_data\t\t|req_size\t|evict_addr\t|evict_data\t\t|evict_dirty\t|link_idx\t|linked\t|mem_tag");
            for (int entry_idx = 0; entry_idx < `MSHR_ENTRY_NUM; entry_idx++) begin
                state_str   =   mshr_state_str_conv(dmshr_array_mon[entry_idx].state);
                cmd_str     =   cmd_str_conv(dmshr_array_mon[entry_idx].cmd);
                size_str    =   size_str_conv(dmshr_array_mon[entry_idx].req_size);
                $display("%0d\t|%s\t|%s\t|%8h\t|%16h\t|%s\t\t|%8h\t|%16h\t|%0b\t\t|%0d\t\t|%0b\t|%0d",
                entry_idx, state_str, cmd_str, dmshr_array_mon[entry_idx].req_addr,
                dmshr_array_mon[entry_idx].req_data, size_str, dmshr_array_mon[entry_idx].evict_addr,
                dmshr_array_mon[entry_idx].evict_data, dmshr_array_mon[entry_idx].evict_dirty,
                dmshr_array_mon[entry_idx].link_idx, dmshr_array_mon[entry_idx].linked, 
                dmshr_array_mon[entry_idx].mem_tag
                );
            end
        end
    endfunction

    function void print_dcache_mem(input CACHE_MEM_ENTRY [`DCACHE_SET_NUM-1:0][`DCACHE_SASS-1:0] dcache_array_mon);
        begin
            $display("T=%0t DCache Mem Contents", $time);
            $display("index\t|valid\t|dirty\t|lru\t|tag\t|data\t\t\t|\t|index\t|valid\t|dirty\t|lru\t|tag\t|data\t\t\t|\t|index\t|valid\t|dirty\t|lru\t|tag\t|data\t\t\t|\t|index\t|valid\t|dirty\t|lru\t|tag\t|data\t\t\t|\t");
            for (int set_idx = 0; set_idx < `DCACHE_SET_NUM; set_idx++) begin
                $display("%2h\t|%0b\t|%0b\t|%0b\t|%6h\t|%16h\t|\t|%2h\t|%0b\t|%0b\t|%0b\t|%6h\t|%16h\t|\t|%2h\t|%0b\t|%0b\t|%0b\t|%6h\t|%16h\t|\t|%2h\t|%0b\t|%0b\t|%0b\t|%6h\t|%16h\t|\t|",
                set_idx, dcache_array_mon[set_idx][0].valid, dcache_array_mon[set_idx][0].dirty, dcache_array_mon[set_idx][0].lru,
                dcache_array_mon[set_idx][0].tag, dcache_array_mon[set_idx][0].data,
                set_idx, dcache_array_mon[set_idx][1].valid, dcache_array_mon[set_idx][1].dirty, dcache_array_mon[set_idx][1].lru,
                dcache_array_mon[set_idx][1].tag, dcache_array_mon[set_idx][1].data,
                set_idx, dcache_array_mon[set_idx][2].valid, dcache_array_mon[set_idx][2].dirty, dcache_array_mon[set_idx][2].lru,
                dcache_array_mon[set_idx][2].tag, dcache_array_mon[set_idx][2].data,
                set_idx, dcache_array_mon[set_idx][3].valid, dcache_array_mon[set_idx][3].dirty, dcache_array_mon[set_idx][3].lru,
                dcache_array_mon[set_idx][3].tag, dcache_array_mon[set_idx][3].data);
            end
        end
    endfunction

    function void print_lsq(
        input   LSQ_ENTRY   [`THREAD_NUM-1:0][`LSQ_ENTRY_NUM-1:0]   lsq_array_mon   ,
        input   logic       [`THREAD_NUM-1:0][`LSQ_IDX_WIDTH-1:0]   lsq_head_mon    ,
        input   logic       [`THREAD_NUM-1:0][`LSQ_IDX_WIDTH-1:0]   lsq_tail_mon
        );
        string  cmd_str     ;
        string  size_str    ;
        string  state_str   ;
        begin
            $display("T=%0t LSQ Contents", $time);
            for(int thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
                $display("T=%0t LSQ[%0d] Contents", $time, thread_idx);
                $display("head=%0d, tail=%0d", lsq_head_mon[thread_idx], lsq_tail_mon[thread_idx]);
                $display("Index\t|state\t\t|cmd\t\t|PC\t\t|tag\t|rob\t|size\t|addr\t\t|addrv\t|data\t\t|datav\t|rt\t|mtag\t|");
                for (int entry_idx = 0; entry_idx < `LSQ_ENTRY_NUM; entry_idx++) begin
                    state_str = lsq_state_str_conv(lsq_array_mon[thread_idx][entry_idx].state);
                    cmd_str =   cmd_str_conv(lsq_array_mon[thread_idx][entry_idx].cmd);
                    size_str = size_str_conv(lsq_array_mon[thread_idx][entry_idx].mem_size);
                    $display("%0d\t|%s\t|%s\t|%8h\t|%0d\t|%0d\t|%s\t|%8h\t|%0b\t|%8h\t|%0b\t|%0b\t|%0d",
                    entry_idx                                       ,
                    state_str                                       ,
                    cmd_str                                         ,
                    lsq_array_mon[thread_idx][entry_idx].pc         ,
                    lsq_array_mon[thread_idx][entry_idx].tag        ,
                    lsq_array_mon[thread_idx][entry_idx].rob_idx    ,
                    size_str                                        ,
                    lsq_array_mon[thread_idx][entry_idx].addr       ,
                    lsq_array_mon[thread_idx][entry_idx].addr_valid ,
                    lsq_array_mon[thread_idx][entry_idx].data       ,
                    lsq_array_mon[thread_idx][entry_idx].data_valid ,
                    lsq_array_mon[thread_idx][entry_idx].retire     ,
                    lsq_array_mon[thread_idx][entry_idx].mem_tag
                    );
                end
            end
        end
    endfunction

    function void print_imshr(input MSHR_ENTRY [`MSHR_ENTRY_NUM-1:0] mshr_array_mon);
        string  cmd_str     ;
        string  size_str    ;
        string  state_str   ;
        begin
            $display("T=%0t ICache MSHR Contents", $time);
            $display("index\t|state\t\t|cmd\t\t|req_addr\t|req_data\t\t|req_size\t|evict_addr\t|evict_data\t\t|evict_dirty\t|link_idx\t|linked\t|mem_tag");
            for (int entry_idx = 0; entry_idx < `MSHR_ENTRY_NUM; entry_idx++) begin
                state_str   =   mshr_state_str_conv(mshr_array_mon[entry_idx].state);
                cmd_str     =   cmd_str_conv(mshr_array_mon[entry_idx].cmd);
                size_str    =   size_str_conv(mshr_array_mon[entry_idx].req_size);
                $display("%0d\t|%s\t|%s\t|%8h\t|%16h\t|%s\t\t|%8h\t|%16h\t|%0b\t\t|%0d\t\t|%0b\t|%0d",
                entry_idx, state_str, cmd_str, mshr_array_mon[entry_idx].req_addr,
                mshr_array_mon[entry_idx].req_data, size_str, mshr_array_mon[entry_idx].evict_addr,
                mshr_array_mon[entry_idx].evict_data, mshr_array_mon[entry_idx].evict_dirty,
                mshr_array_mon[entry_idx].link_idx, mshr_array_mon[entry_idx].linked, 
                mshr_array_mon[entry_idx].mem_tag
                );
            end
        end
    endfunction

    function void print_icache_mem(input CACHE_MEM_ENTRY [`ICACHE_SET_NUM-1:0][`ICACHE_SASS-1:0] cache_array_mon);
        begin
            $display("T=%0t ICache Mem Contents", $time);
            $display("index\t|valid\t|dirty\t|lru\t|tag\t|data\t\t\t|\t\t|index\t|valid\t|dirty\t|lru\t|tag\t|data\t");
            for (int set_idx = 0; set_idx < `ICACHE_SET_NUM; set_idx++) begin
                $display("%2h\t|%0b\t|%0b\t|%0b\t|%6h\t|%16h\t|\t\t|%2h\t|%0b\t|%0b\t|%0b\t|%6h\t|%16h\t",
                set_idx, cache_array_mon[set_idx][0].valid, cache_array_mon[set_idx][0].dirty, cache_array_mon[set_idx][0].lru,
                cache_array_mon[set_idx][0].tag, cache_array_mon[set_idx][0].data,
                set_idx, cache_array_mon[set_idx][1].valid, cache_array_mon[set_idx][1].dirty, cache_array_mon[set_idx][1].lru,
                cache_array_mon[set_idx][1].tag, cache_array_mon[set_idx][1].data);
            end
        end
    endfunction

endclass:monitor
// ====================================================================
// Monitor End
// ====================================================================

// ====================================================================
// Generator Start
// ====================================================================
class generator;
    mailbox drv_mbx;
    event   drv_done;
    int     num     =   200;

    task run();
        for (int i = 0; i < num; i++) begin
            gen_item item   =   new;
            item.randomize();
            // $display("T=%0t [Generator] Loop:%0d/%0d create next item",
            //         $time, i+1, num);
            // item.print("[Generator]");
            drv_mbx.put(item);
            @(drv_done);
        end
        $display("T=%0t [Generator] Done generation of %0d items",
                $time, num);
    endtask // run()
endclass
// ====================================================================
// Generator End
// ====================================================================

// ====================================================================
// Environment Start
// ====================================================================
class env;
    driver                            d0          ;   // driver     handle
    monitor                           m0          ;   // monitor    handle
    generator                         g0          ;   // generator  handle
    // scoreboard      s0          ;   // scoreboard handle

    mailbox                           drv_mbx     ;   // Connect generator  <-> driver
    mailbox                           scb_mbx     ;   // Connect monitor    <-> scoreboard
    event                             drv_done    ;   // Indicates when driver is done

    virtual pipeline_ss_smt_if        vif         ;   // Virtual interface handle

    function new();
        d0          =   new         ;
        m0          =   new         ;
        g0          =   new         ;
        // s0          =   new         ;
        
        drv_mbx     =   new()       ;
        scb_mbx     =   new()       ;

        d0.drv_mbx  =   drv_mbx     ;
        g0.drv_mbx  =   drv_mbx     ;
        m0.scb_mbx  =   scb_mbx     ;
        // s0.scb_mbx  =   scb_mbx     ;

        d0.drv_done =   drv_done    ;
        g0.drv_done =   drv_done    ;
    endfunction // new()

    virtual task run();
        d0.vif  =   vif;
        m0.vif  =   vif;

        fork
            d0.run();
            m0.run();
            g0.run();
            // s0.run();
        join_any
    endtask // run()
endclass // env
// ====================================================================
// Environment End
// ====================================================================

// ====================================================================
// Test Start
// ====================================================================
class test;
    env e0;
    function new();
        e0  =   new;
    endfunction // new()

    task run();
        e0.run();
    endtask // run()
endclass // test
// ====================================================================
// Test End
// ====================================================================

// ====================================================================
// Interface Start
// ====================================================================
interface pipeline_ss_smt_if         (input bit clk_i);
    logic                                               rst_i               ;   // Reset
    // FIQ_DP                                              fiq_dp              ;   // From FIQ to DP
    // DP_FIQ                                              dp_fiq              ;   // From DP to FIQ
    logic                                               exception_i         ;   // External exception
    // Memory Interface
    logic                                               memory_enable_i     ;
    MEM_IN                                              proc2mem_o          ;
    MEM_OUT                                             mem2proc_i          ;
    //      Fetch
    logic       [`THREAD_NUM-1:0]                       pc_en_i             ;                               
    logic       [`THREAD_NUM-1:0][`XLEN-1:0]            rst_pc_i            ;
    MEM_IN                                              if_ic_o_t           ;
    MEM_OUT                                             ic_if_o_t           ;
    logic       [`THREAD_IDX_WIDTH-1:0]                 thread_idx_disp_o_t ;
    logic       [`THREAD_IDX_WIDTH-1:0]                 thread_to_ft_o_t    ;   
    CONTEXT     [`THREAD_NUM-1:0]                       thread_data_o_t     ;

    //      Dispatch
    DP_RS                                               dp_rs_mon_o         ;   // From Dispatcher to RS
    DP_MT       [`THREAD_NUM-1:0][`DP_NUM-1:0]          dp_mt_mon_o         ;
    MT_DP       [`THREAD_NUM-1:0][`DP_NUM-1:0]          mt_dp_mon_o         ;
    //      Issue
    RS_IB                                               rs_ib_mon_o         ;   // From RS to IB
    //      Execute
    IB_FU       [`FU_NUM-1:0]                           ib_fu_mon_o         ;   // From IB to FU
    //      Complete
    FU_BC                                               fu_bc_mon_o         ;   // From FU to BC
    CDB         [`CDB_NUM-1:0]                          cdb_mon_o           ;   // CDB
    //      Retire
    logic       [`THREAD_NUM-1:0][`RT_NUM-1:0][`XLEN-1:0]   rt_pc_o         ;   // PC of retired instructions
    logic       [`THREAD_NUM-1:0][`RT_NUM-1:0]              rt_valid_o      ;   // Retire valid
    ROB_AMT     [`THREAD_NUM-1:0][`RT_NUM-1:0]          rob_amt_mon_o       ;   // From ROB to AMT
    ROB_FL      [`THREAD_NUM-1:0]                       rob_fl_mon_o        ;   // From ROB to FL
    //ROB_VFL                                           rob_vfl_mon_o       ;   // From ROB to VFL
    BR_MIS                                              br_mis_mon_o        ;   // Branch Misprediction
    //      Contents
    ROB_ENTRY   [`THREAD_NUM-1:0][`ROB_ENTRY_NUM-1:0]   rob_mon_o           ;   // ROB contents monitor
    logic       [`THREAD_NUM-1:0][`ROB_IDX_WIDTH-1:0]   rob_head_mon_o      ;   // ROB head pointer
    logic       [`THREAD_NUM-1:0][`ROB_IDX_WIDTH-1:0]   rob_tail_mon_o      ;   // ROB tail pointer
    RS_ENTRY    [`RS_ENTRY_NUM-1:0]                     rs_mon_o            ;   // RS contents monitor
    logic       [$clog2(`RS_ENTRY_NUM)-1:0]             rs_cod_mon_o        ;
    MT_ENTRY    [`THREAD_NUM-1:0][`ARCH_REG_NUM-1:0]    mt_mon_o            ;   // Map Table contents monitor
    AMT_ENTRY   [`THREAD_NUM-1:0][`ARCH_REG_NUM-1:0]    amt_mon_o           ;  // Arch Map Table contents monitor
    FL_ENTRY    [`FL_ENTRY_NUM-1:0]                     fl_mon_o            ;   // Freelist contents monitor
    //logic       [`FL_IDX_WIDTH-1:0]                   fl_head_mon_o       ;
    //logic       [`FL_IDX_WIDTH-1:0]                   fl_tail_mon_o       ;
    //FL_ENTRY    [`FL_ENTRY_NUM-1:0]                   vfl_fl_mon_o        ;
    IS_INST     [`ALU_Q_SIZE  -1:0]                     ALU_queue_mon_o     ;   // IB queue monitor
    IS_INST     [`MULT_Q_SIZE -1:0]                     MULT_queue_mon_o    ;   // IB queue monitor
    IS_INST     [`BR_Q_SIZE   -1:0]                     BR_queue_mon_o      ;   // IB queue monitor
    IS_INST     [`LOAD_Q_SIZE -1:0]                     LOAD_queue_mon_o    ;   // IB queue monitor
    IS_INST     [`STORE_Q_SIZE-1:0]                     STORE_queue_mon_o   ;   // IB queue monitor
    logic       [`ALU_Q_SIZE  -1:0]                     ALU_valid_mon_o     ;   // IB queue monitor
    logic       [`MULT_Q_SIZE -1:0]                     MULT_valid_mon_o    ;   // IB queue monitor
    logic       [`BR_Q_SIZE   -1:0]                     BR_valid_mon_o      ;   // IB queue monitor
    logic       [`LOAD_Q_SIZE -1:0]                     LOAD_valid_mon_o    ;   // IB queue monitor
    logic       [`STORE_Q_SIZE-1:0]                     STORE_valid_mon_o   ;   // IB queue monitor
    logic       [`ALU_IDX_WIDTH  -1:0]                  ALU_head_mon_o      ;   // IB queue pointer monitor
    logic       [`ALU_IDX_WIDTH  -1:0]                  ALU_tail_mon_o      ;   // IB queue pointer monitor
    logic       [`MULT_IDX_WIDTH -1:0]                  MULT_head_mon_o     ;   // IB queue pointer monitor
    logic       [`MULT_IDX_WIDTH -1:0]                  MULT_tail_mon_o     ;   // IB queue pointer monitor
    logic       [`BR_IDX_WIDTH   -1:0]                  BR_head_mon_o       ;   // IB queue pointer monitor
    logic       [`BR_IDX_WIDTH   -1:0]                  BR_tail_mon_o       ;   // IB queue pointer monitor
    logic       [`LOAD_IDX_WIDTH -1:0]                  LOAD_head_mon_o     ;   // IB queue pointer monitor
    logic       [`LOAD_IDX_WIDTH -1:0]                  LOAD_tail_mon_o     ;   // IB queue pointer monitor
    logic       [`STORE_IDX_WIDTH-1:0]                  STORE_head_mon_o    ;   // IB queue pointer monitor
    logic       [`STORE_IDX_WIDTH-1:0]                  STORE_tail_mon_o    ;   // IB queue pointer monitor
    logic       [`PHY_REG_NUM-1:0] [`XLEN-1:0]          prf_mon_o           ;   // Physical Register File monitor
    LSQ_ENTRY   [`THREAD_NUM-1:0][`LSQ_ENTRY_NUM-1:0]   lsq_array_mon_o     ;   // LSQ monitor
    logic       [`THREAD_NUM-1:0][`LSQ_IDX_WIDTH-1:0]   lsq_head_mon_o      ;   // LSQ pointer monitor
    logic       [`THREAD_NUM-1:0][`LSQ_IDX_WIDTH-1:0]   lsq_tail_mon_o      ;   // LSQ pointer monitor
    MSHR_ENTRY      [`MSHR_ENTRY_NUM-1:0]                   dmshr_array_mon_o   ;   // DCache MSHR monitor
    CACHE_MEM_ENTRY [`DCACHE_SET_NUM-1:0][`DCACHE_SASS-1:0] dcache_array_mon_o  ;   // DCache Mem monitor
    MSHR_ENTRY      [`MSHR_ENTRY_NUM-1:0]                   imshr_array_mon_o   ;
    CACHE_MEM_ENTRY [`ICACHE_SET_NUM-1:0][`CACHE_SASS-1:0]  icache_array_mon_o  ;
    logic       [63:0]  unified_memory  [`MEM_64BIT_LINES - 1:0];

endinterface // pipeline_dp_if
// ====================================================================
// Interface End
// ====================================================================

// ====================================================================
// Testbench Start
// ====================================================================
module pipeline_ss_smt_tb;

// --------------------------------------------------------------------
// Local Parameters
// --------------------------------------------------------------------
    localparam  C_CLOCK_PERIOD  =   `VERILOG_CLOCK_PERIOD;

// --------------------------------------------------------------------
// Signal Declarations
// --------------------------------------------------------------------
    logic           clk_i       ;

// --------------------------------------------------------------------
// Clock Generation
// --------------------------------------------------------------------
    initial begin
        clk_i   =   0;
        forever begin
            #(C_CLOCK_PERIOD/2.0) clk_i   =   ~clk_i;
        end
    end

// --------------------------------------------------------------------
// Interface Instantiation
// --------------------------------------------------------------------
    pipeline_ss_smt_if         _if(clk_i);

// --------------------------------------------------------------------
// DUT Instantiation
// --------------------------------------------------------------------
    pipeline_ss_smt     dut (
        .clk_i              (   clk_i               ),
        .rst_i              (_if.rst_i              ),

        .proc2mem_o         (_if.proc2mem_o         ),          // Connect memory to cache (vise versa)
        .mem2proc_i         (_if.mem2proc_i         ),

        .exception_i        (_if.exception_i        ),
        .pc_en_i            (_if.pc_en_i            ),
        .rst_pc_i           (_if.rst_pc_i           ),
        .if_ic_o_t          (_if.if_ic_o_t          ),          // Exposes the instruction cache to
        .ic_if_o_t          (_if.ic_if_o_t          ),
`ifdef DEBUG
        .thread_idx_disp_o_t(_if.thread_idx_disp_o_t),
        .thread_to_ft_o_t   (_if.thread_to_ft_o_t   ),
        .thread_data_o_t    (_if.thread_data_o_t    ),
        .n_thread_data_o_t  (                       ),          // DC right now
`endif

        // .fiq_dp             (_if.fiq_dp             ),
        // .dp_fiq             (_if.dp_fiq             ),
        .dp_rs_mon_o        (_if.dp_rs_mon_o        ),
        .dp_mt_mon_o        (_if.dp_mt_mon_o        ),
        .mt_dp_mon_o        (_if.mt_dp_mon_o        ),
        .rs_ib_mon_o        (_if.rs_ib_mon_o        ),
        .ib_fu_mon_o        (_if.ib_fu_mon_o        ),
        .fu_bc_mon_o        (_if.fu_bc_mon_o        ),
        .cdb_mon_o          (_if.cdb_mon_o          ),
        .rt_pc_o            (_if.rt_pc_o            ),
        .rt_valid_o         (_if.rt_valid_o         ),
        .rob_amt_mon_o      (_if.rob_amt_mon_o      ),
        .rob_fl_mon_o       (_if.rob_fl_mon_o       ),
        //.rob_vfl_mon_o      (_if.rob_vfl_mon_o      ),
        .br_mis_mon_o       (_if.br_mis_mon_o       ),
        .rob_mon_o          (_if.rob_mon_o          ),
        .rob_head_mon_o     (_if.rob_head_mon_o     ),
        .rob_tail_mon_o     (_if.rob_tail_mon_o     ),
        .rs_mon_o           (_if.rs_mon_o           ),
        .rs_cod_mon_o       (_if.rs_cod_mon_o       ),
        .mt_mon_o           (_if.mt_mon_o           ),
        .amt_mon_o          (_if.amt_mon_o          ),
        .fl_mon_o           (_if.fl_mon_o           ),
        //.fl_head_mon_o      (_if.fl_head_mon_o      ),
        //.fl_tail_mon_o      (_if.fl_tail_mon_o      ),
        //.vfl_fl_mon_o       (_if.vfl_fl_mon_o       ),
        .ALU_queue_mon_o    (_if.ALU_queue_mon_o    ),
        .MULT_queue_mon_o   (_if.MULT_queue_mon_o   ),
        .BR_queue_mon_o     (_if.BR_queue_mon_o     ),
        .LOAD_queue_mon_o   (_if.LOAD_queue_mon_o   ),
        .STORE_queue_mon_o  (_if.STORE_queue_mon_o  ),
        .ALU_valid_mon_o    (_if.ALU_valid_mon_o    ),
        .MULT_valid_mon_o   (_if.MULT_valid_mon_o   ),
        .BR_valid_mon_o     (_if.BR_valid_mon_o     ),
        .LOAD_valid_mon_o   (_if.LOAD_valid_mon_o   ),
        .STORE_valid_mon_o  (_if.STORE_valid_mon_o  ),
        .ALU_head_mon_o     (_if.ALU_head_mon_o     ),   // IB queue pointer monitor
        .ALU_tail_mon_o     (_if.ALU_tail_mon_o     ),   // IB queue pointer monitor
        .MULT_head_mon_o    (_if.MULT_head_mon_o    ),   // IB queue pointer monitor
        .MULT_tail_mon_o    (_if.MULT_tail_mon_o    ),   // IB queue pointer monitor
        .BR_head_mon_o      (_if.BR_head_mon_o      ),   // IB queue pointer monitor
        .BR_tail_mon_o      (_if.BR_tail_mon_o      ),   // IB queue pointer monitor
        .LOAD_head_mon_o    (_if.LOAD_head_mon_o    ),   // IB queue pointer monitor
        .LOAD_tail_mon_o    (_if.LOAD_tail_mon_o    ),   // IB queue pointer monitor
        .STORE_head_mon_o   (_if.STORE_head_mon_o   ),   // IB queue pointer monitor
        .STORE_tail_mon_o   (_if.STORE_tail_mon_o   ),   // IB queue pointer monitor
        .prf_mon_o          (_if.prf_mon_o          ),
        .lsq_array_mon_o    (_if.lsq_array_mon_o    ),
        .lsq_head_mon_o     (_if.lsq_head_mon_o     ),
        .lsq_tail_mon_o     (_if.lsq_tail_mon_o     ),
        .dmshr_array_mon_o  (_if.dmshr_array_mon_o  ),
        .dcache_array_mon_o (_if.dcache_array_mon_o ),
        .imshr_array_mon_o  (_if.imshr_array_mon_o  ),
        .icache_array_mon_o (_if.icache_array_mon_o )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Memory Instantiation
// --------------------------------------------------------------------
    // Instantiate the Data Memory
    mem memory (
        // Inputs
        .clk               ( clk_i                    ),
        .proc2mem_command  ( _if.proc2mem_o.command  ),
        .proc2mem_addr     ( _if.proc2mem_o.addr     ),
        .proc2mem_data     ( _if.proc2mem_o.data     ),
`ifndef CACHE_MODE
        .proc2mem_size     ( _if.proc2mem_o.size     ),
`endif

        // Outputs (to processor)
        .mem2proc_response ( _if.mem2proc_i.response ),
        .mem2proc_data     ( _if.mem2proc_i.data     ),
        .mem2proc_tag      ( _if.mem2proc_i.tag      )
    );

    assign  _if.unified_memory  =   memory.unified_memory;
    
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Test Instantiation
// --------------------------------------------------------------------
    test    t0;

// --------------------------------------------------------------------
// Call test
// --------------------------------------------------------------------
    initial begin
        $dumpvars;

        $display("@@\n@@\n@@  %t  Asserting System reset......", $realtime);
        _if.rst_i       =   1;
        // _if.fiq_dp      =   0;
        _if.exception_i =   0;

        for (int unsigned thread_idx = 0; thread_idx < `THREAD_NUM; thread_idx++) begin
            // _if.rst_pc_i[thread_idx]  =   thread_idx * 'h1900;
            _if.rst_pc_i[thread_idx]  =   thread_idx * 'h100;
        end

        @(posedge clk_i);
        @(posedge clk_i);

        $readmemh("program.mem", memory.unified_memory);

        @(posedge clk_i);
        @(posedge clk_i);
        `SD;

        _if.rst_i   =   0;
        $display("@@  %t  Deasserting System reset......\n@@\n@@", $realtime);

        t0  =   new;
        t0.e0.vif   =   _if;
        t0.run();

        // Because multiple components and clock are running
        // in the background, we need to call $finish explicitly
        $display("@@PASSED");
        #50 $finish;
    end

    // initial begin
    //     $dumpvars;
    //     $dumpfile("dump.vcd");
    // end

endmodule // pipeline_ss_smt_tb

// ====================================================================
// Testbench End
// ====================================================================