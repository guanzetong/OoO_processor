module ROB_tb;

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_SCB_NUM       =   128;
    localparam  C_CLK_PERIOD    =   10;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic                           clk_i       ;
    logic                           rst_i       ;
    ROB_DP  [`DP_NUM-1:0]           rob_dp_o    ;
    DP_ROB  [`DP_NUM-1:0]           dp_rob_i    ;
    ROB_RS  [`DP_NUM-1:0]           rob_rs_o    ;
    CDB     [`CDB_NUM-1:0]          cdb_i       ;
    ROB_AMT [`RT_NUM-1:0]           rob_amt_o   ;
    ROB_FL  [`RT_NUM-1:0]           rob_fl_o    ;
    logic                           exception_i ;

    logic   [`ROB_IDX_WIDTH:0]      head_o      ;
    logic   [`ROB_IDX_WIDTH:0]      tail_o      ;
    logic   [`ROB_IDX_WIDTH:0]      next_tail_o ;

    int                             dispatch_num_monitor    ;
    int                             complete_num_monitor    ;
    int                             retire_amt_num_monitor  ;
    int                             retire_fl_num_monitor   ;

    // Scoreboard
    // Logically, it's 128 entries that records each transaction I/O and compares against.

    logic   [`TAG_IDX_WIDTH-1:0]        dispatch_tag_seq        [C_SCB_NUM-1:0]    ;
    logic   [`TAG_IDX_WIDTH-1:0]        dispatch_tag_old_seq    [C_SCB_NUM-1:0]    ;
    logic   [`ROB_IDX_WIDTH-1:0]        dispatch_rob_idx_seq    [C_SCB_NUM-1:0]    ;

    logic   [`ROB_IDX_WIDTH-1:0]        complete_rob_idx_seq    [C_SCB_NUM-1:0]    ;

    logic   [`ARCH_REG_IDX_WIDTH-1:0]   retire_arch_reg_seq     [C_SCB_NUM-1:0]    ;
    logic   [`TAG_IDX_WIDTH-1:0]        retire_tag_seq          [C_SCB_NUM-1:0]    ;
    logic   [`TAG_IDX_WIDTH-1:0]        retire_tag_old_seq      [C_SCB_NUM-1:0]    ;

    logic   [`ROB_ENTRY_NUM-1:0]        entry_valid_o       ;
    logic   [`ROB_ENTRY_NUM-1:0]        entry_complete_o    ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Design Under Test (DUT) Instantiation Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   ROB
// Description  :   Reorder the retirement in program order.
// --------------------------------------------------------------------
    ROB dut(
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .rob_dp_o           (rob_dp_o           ),
        .dp_rob_i           (dp_rob_i           ),
        .rob_rs_o           (rob_rs_o           ),
        .cdb_i              (cdb_i              ),
        .rob_amt_o          (rob_amt_o          ),
        .rob_fl_o           (rob_fl_o           ),
        .exception_i        (exception_i        ),
        .head_o             (head_o             ),
        .tail_o             (tail_o             ),
        .entry_valid_o      (entry_valid_o      ),
        .entry_complete_o   (entry_complete_o   )
        // .next_tail_o        (next_tail_o        )
    );
// ====================================================================
// Design Under Test (DUT) Instantiation End
// ====================================================================

// ====================================================================
// Clock Generator Start
// ====================================================================
    initial begin
        clk_i   =   0;
        forever begin
            #(C_CLK_PERIOD/2)   clk_i   =   ~clk_i;
        end
    end
// ====================================================================
// Clock Generator End
// ====================================================================

// --------------------------------------------------------------------
// Retire Monitors
// --------------------------------------------------------------------
    function int min_int (
        input int inta, intb
    );
        if (inta < intb) begin
            min_int =   inta;
        end else begin
            min_int =   intb;
        end
    endfunction

// --------------------------------------------------------------------
// Dispatch
// --------------------------------------------------------------------
    task dispatch_driver (
        input   int     dispatch_num
    );
        logic   [`DP_NUM-1:0]   dp_en_concat    ;
        logic   [`DP_NUM-1:0]   rob_ready_concat;
        int                     rob_ready_num   ;
        int                     dp_en_num       ;

        begin
            @(negedge clk_i);

            // Read rob_ready in each dispatch channel
            for (int n = 0 ; n < `DP_NUM; n++) begin
                rob_ready_concat[n] = rob_dp_o[n].rob_ready;
            end
            // $display("rob_ready=%b", rob_ready_concat);

            // Generate the dp_en in each dispatch channel
            rob_ready_num   =   calc_rob_ready_num(rob_ready_concat);  
            dp_en_num       =   min_int(dispatch_num, rob_ready_num);
            dp_en_concat    =   dp_en(dp_en_num);

            // Assign values to dispatch channels
            for (int n = 0; n < `DP_NUM; n++) begin
                dp_rob_i[n].dp_en       =   dp_en_concat[n];
                if (dp_en_concat[n]) begin
                    dp_rob_i[n].pc          =   $urandom;
                    dp_rob_i[n].arch_reg    =   $urandom % `ARCH_REG_NUM;
                    dp_rob_i[n].tag         =   $urandom % `PHY_REG_NUM;
                    dp_rob_i[n].tag_old     =   $urandom % `PHY_REG_NUM;
                    dp_rob_i[n].br_predict  =   0;
                    $display("@@ Time= %4.0f, Dispatch in channel%1d, PC = %h, arch_reg = %d, T = %d, tag_old = %d, br_predict: %b",
                    $time, n, dp_rob_i[n].pc, dp_rob_i[n].arch_reg, dp_rob_i[n].tag, dp_rob_i[n].tag_old, dp_rob_i[n].br_predict);
                end else begin
                    dp_rob_i[n].pc          =   0;
                    dp_rob_i[n].arch_reg    =   0;
                    dp_rob_i[n].tag         =   0;
                    dp_rob_i[n].tag_old     =   0;
                    dp_rob_i[n].br_predict  =   0;
                end
            end
        end
    endtask

    // Calculate the number of available entries based on rob_ready
    function int calc_rob_ready_num (
        input logic [`DP_NUM-1:0] rob_ready
    );
        calc_rob_ready_num = 0;
        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            if (rob_ready[idx]) begin
                calc_rob_ready_num   =   idx + 1;
            end
        end
    endfunction

    // Generate dp_en
    function logic [`DP_NUM-1:0] dp_en (
        input int dp_en_num
    );
        dp_en = 0;
        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            if (idx < dp_en_num) begin
                dp_en[idx]   =  1'b1;
            end else begin
                dp_en[idx]   =  1'b0;
            end
        end
    endfunction

// --------------------------------------------------------------------
// Complete
// --------------------------------------------------------------------
    task complete_driver (
        input   int                         complete_num    ,
        input   logic   [`ROB_IDX_WIDTH:0]  head_ptr        ,
        input   logic   [`ROB_IDX_WIDTH:0]  tail_ptr        ,
        input   bit                         br_mispredict_en
    );
        int                             valid_num           ;
        int                             cdb_valid_num       ;
        logic   [`CDB_NUM-1:0]          cdb_valid_concat    ;
        logic   [`ROB_IDX_WIDTH-1:0]    complete_rob_idx    ;
        bit     [`ROB_ENTRY_NUM-1:0]    picked_flag         ;

        int                             random_part         ;

        begin
            @(negedge clk_i);
            picked_flag =   0;
            // Generate the cdb_valid in each complete/CDB channel
            valid_num           =   rob_valid_num(head_ptr, tail_ptr);
            cdb_valid_num       =   min_int(valid_num, complete_num);
            cdb_valid_concat    =   cdb_valid(cdb_valid_num);

            // Assign values to complete/CDB channels
            for (int n = 0; n < `CDB_NUM; n++) begin
                cdb_i[n].valid      =   cdb_valid_concat[n];
                if (cdb_valid_concat[n]) begin
                    // Make sure the entry to be completed is valid (active) and not completed yet.
                    // Also should prevent the same entry index if multiple completes is in the same cycle.
                    while (1) begin
                        random_part         =   ($urandom % valid_num);
                        complete_rob_idx    =   random_part + head_ptr[`ROB_IDX_WIDTH-1:0];
                        if ((!entry_complete_o[complete_rob_idx]) && (!picked_flag[complete_rob_idx])) begin
                            picked_flag[complete_rob_idx]   =   1'b1;
                            break;
                        end
                    end
                    // $display("Head=%d, Tail=%d, rob_idx=%d, valid_num=%3d, random_part=%3d", head_ptr[`ROB_IDX_WIDTH-1:0], tail_ptr[`ROB_IDX_WIDTH-1:0], complete_rob_idx, valid_num, random_part);
                    cdb_i[n].rob_idx    =   complete_rob_idx;
                    
                    if (br_mispredict_en) begin
                        cdb_i[n].br_result  =   $urandom % 2;
                    end else begin
                        cdb_i[n].br_result  =   1'b0;
                    end
                    $display("@@ Time= %4.0f, Complete in channel%1d, rob_idx = %d, br_result = %b",
                    $time, n, cdb_i[n].rob_idx, cdb_i[n].br_result);
                end else begin
                    cdb_i[n].rob_idx    =   0;
                    cdb_i[n].br_result  =   1'b0;
                end
            end

        end
    endtask

    function int rob_valid_num(
        input   logic   [`ROB_IDX_WIDTH:0]    head_ptr        ,
        input   logic   [`ROB_IDX_WIDTH:0]    tail_ptr        
    );
        if (head_ptr[`ROB_IDX_WIDTH-1:0] > tail_ptr[`ROB_IDX_WIDTH-1:0]) begin
            rob_valid_num   =   tail_ptr + `ROB_ENTRY_NUM - head_ptr;
        end else if (head_ptr[`ROB_IDX_WIDTH-1:0] < tail_ptr[`ROB_IDX_WIDTH-1:0]) begin
            rob_valid_num   =   tail_ptr - head_ptr;
        end else begin
            if (head_ptr[`ROB_IDX_WIDTH] == tail_ptr[`ROB_IDX_WIDTH]) begin
                rob_valid_num   =   0;
            end else begin
                rob_valid_num   =   `ROB_ENTRY_NUM;
            end
        end
    endfunction

    function logic [`CDB_NUM-1:0] cdb_valid (
        input   int                             cdb_valid_num
    );
        for (int n = 0; n < `CDB_NUM; n++) begin
            if (n < cdb_valid_num) begin
                cdb_valid[n]    =   1'b1;
            end else begin
                cdb_valid[n]    =   1'b0;
            end
        end
    endfunction
// ====================================================================
// Drivers End
// ====================================================================

// ====================================================================
// Monitor Start
// ====================================================================

// --------------------------------------------------------------------
// Dispatch Monitor
// --------------------------------------------------------------------
    task dispatch_monitor(
        output  int     dispatched_num_o
    );
        int     dispatched_num  =   0;
        begin
            @(posedge clk_i);
            
            for (int n = 0; n < `DP_NUM; n++) begin
                if (dp_rob_i[n].dp_en) begin
                    dispatch_arch_reg_seq[dispatched_num] =   dp_rob_i[n].arch_reg;
                    dispatch_tag_seq[dispatched_num]      =   dp_rob_i[n].tag     ;
                    dispatch_tag_old_seq[dispatched_num]  =   dp_rob_i[n].tag_old ;
                    dispatch_rob_idx_seq[dispatched_num]  =   rob_rs_o[n].rob_idx ;
                    dispatched_num++;
                    dispatched_num_o    =   dispatched_num;
                end
            end
            // $display("Dispatched num=%d", dispatched_num);
        end
    endtask

// --------------------------------------------------------------------
// Complete Monitor
// --------------------------------------------------------------------
    task complete_monitor(
        output  int     complete_num_o
    );
        int     complete_num    =   0;
        begin
            @(posedge clk_i);
            
            for (int n = 0; n < `CDB_NUM; n++) begin
                if (cdb_i[n].valid) begin
                    complete_rob_idx_seq[complete_num]  =   cdb_i[n].rob_idx ;
                    complete_num++;
                    complete_num_o  =   complete_num;
                end
            end
            // $display("Completed num=%d", complete_num);
        end
    endtask

// --------------------------------------------------------------------
// Retire Monitors
// --------------------------------------------------------------------
    task retire_amt_monitor(
        output  int     retire_amt_num_o
    );
        int     retire_amt_num      =   0;
        begin
            @(posedge clk_i);

            for (int n = 0; n < `RT_NUM; n++) begin
                if (rob_amt_o[n].valid) begin
                    retire_arch_reg_seq[retire_amt_num] =   rob_amt_o[n].arch_reg   ;
                    retire_tag_seq[retire_amt_num]      =   rob_amt_o[n].phy_reg    ;
                    retire_amt_num++;
                    retire_amt_num_o    =   retire_amt_num;
                end
            end
        end
    endtask

    task retire_fl_monitor(
        output  int     retire_fl_num_o
    );
        int     retire_fl_num      =   0;
        begin
            @(posedge clk_i);

            for (int n = 0; n < `RT_NUM; n++) begin
                if (rob_amt_o[n].valid) begin
                    retire_tag_old_seq[retire_fl_num]  =   rob_fl_o[n].phy_reg ;
                    retire_fl_num++;
                    retire_fl_num_o =   retire_fl_num;
                end
            end
        end
    endtask

// --------------------------------------------------------------------
// Monitor Call
// --------------------------------------------------------------------
    initial begin
        forever begin
            fork
                dispatch_monitor(dispatch_num_monitor);
                complete_monitor(complete_num_monitor);
                retire_amt_monitor(retire_amt_num_monitor);
                retire_fl_monitor(retire_fl_num_monitor);
            join
        end
    end
    
// ====================================================================
// Monitor End
// ====================================================================

// ====================================================================
// Scoreboard/Checker Start
// ====================================================================
    task scoreboard_checker (
        input   int     retire_amt_num  ,
        input   int     retire_fl_num   
    );
        @(negedge clk_i);
        if (retire_amt_num != retire_fl_num) begin
            exit_retire_num_error(retire_amt_num, retire_fl_num);
        end
        for (int n = 0; n < retire_amt_num; n++) begin
            if ((dispatch_arch_reg_seq[n] != retire_arch_reg_seq[n]) ||
                (dispatch_tag_seq[n]      != retire_tag_seq[n])      ||
                (dispatch_tag_old_seq[n]  != retire_tag_old_seq[n])) begin
                exit_retire_content_error(n);
            end
        end
    endtask

// --------------------------------------------------------------------
// Scoreboard/Checker Call
// --------------------------------------------------------------------
    initial begin
        forever begin
            scoreboard_checker(retire_amt_num_monitor, retire_fl_num_monitor);
        end
    end
// ====================================================================
// Scoreboard/Checker Start
// ====================================================================

// ====================================================================
// Stimulus Generator Start
// ====================================================================
    task testcase_1;
        // 1. Dispatch 1 instruction per cycle to fill up the ROB
        // 2. Complete 1 instruction per cycle out-of-order.
        while (dispatch_num_monitor < `ROB_ENTRY_NUM) begin
            dispatch_driver($urandom % 3);
            // $display("Dispatched num =%d", dispatch_num_monitor);
        end

        while (retire_fl_num_monitor < `ROB_ENTRY_NUM) begin
            complete_driver($urandom % 3, head_o, tail_o, 0);
            // $display("Completed num =%d", complete_num_monitor);
            // $display("Retired num =%d", retire_fl_num_monitor);
        end
    endtask

    task testcase_2;
        for (int i = 0; i < 31; i++) begin
            fork
                dispatch_driver($urandom % 3);
                complete_driver($urandom % 3, head_o, tail_o, 0);
            join
        end

    endtask

// ====================================================================
// Stimulus Generator End
// ====================================================================

// ====================================================================
// Test case call Start
// ====================================================================
    initial begin
        rst_i       =   0;
        dp_rob_i    =   0;
        cdb_i       =   0;
        exception_i =   0;


        @(negedge clk_i);
        rst_i   =   1;
        @(negedge clk_i);
        rst_i   =   0;

        // repeat(10) @(negedge clk_i);

        testcase_1();
        testcase_2();

        // repeat(40) begin
        //     dispatch_driver(1);
        //     // $display("Dispatched num =%d", dispatch_num_monitor);
        //     $display("rob_ready: %b, %b, head: %d, tail: %d, next_tail:%d", rob_dp_o[0].rob_ready, rob_dp_o[1].rob_ready, head_o, tail_o, next_tail_o);
        // end
        // repeat(40) complete_driver(1, head_o, tail_o, 0);

        $display("\nENDING TESTBENCH: SUCCESS!\n");
        $display("@@@Passed");
        $finish;
    end
// ====================================================================
// Test case call End
// ====================================================================

// ====================================================================
// Exit Start
// ====================================================================
    task exit_retire_num_error(
        input   int     retire_amt_num,
        input   int     retire_fl_num
    );
        begin
            $display("Mismatch between ROB_AMT and ROB_FL Interfaces at time %4.0f", $time);
            $display("Time:%4.0f clock:%b retire_amt_num: %d, retire_fl_num: %d", $time, clk_i, retire_amt_num, retire_fl_num);
            $display("@@@Failed");
            $finish;
        end
    endtask

    task exit_retire_content_error(
        input   int     scb_idx
    );
        $display("Mismatch between dispatch and retire at time %4.0f", $time);
        $display("Time:%4.0f clock:%b scb_idx: %d", $time, clk_i, scb_idx);
        $display("dispatch_arch_reg_seq: %d, retire_arch_reg_seq: %d", dispatch_arch_reg_seq[scb_idx], retire_arch_reg_seq[scb_idx]);
        $display("dispatch_tag_seq: %d, retire_tag_seq: %d", dispatch_tag_seq[scb_idx], retire_tag_seq[scb_idx]);
        $display("dispatch_tag_old_seq: %d, retire_tag_old_seq: %d", dispatch_tag_old_seq[scb_idx], retire_tag_old_seq[scb_idx]);
        $display("@@@Failed");
        $finish;
    endtask

// ====================================================================
// Exit End
// ====================================================================

endmodule