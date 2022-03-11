module ROB_tb;

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_SCB_NUM  =   128;
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

    int                             dispatch_num    ;
    int                             complete_num    ;
    int                             retire_amt_num  ;
    int                             retire_fl_num   ;

    // Scoreboard
    logic   [`ARCH_REG_IDX_WIDTH-1:0]   dispatch_arch_reg_seq   [C_SCB_NUM-1:0]    ;
    logic   [`TAG_IDX_WIDTH-1:0]        dispatch_tag_seq        [C_SCB_NUM-1:0]    ;
    logic   [`TAG_IDX_WIDTH-1:0]        dispatch_tag_old_seq    [C_SCB_NUM-1:0]    ;
    logic   [`ROB_IDX_WIDTH-1:0]        dispatch_rob_idx_seq    [C_SCB_NUM-1:0]    ;

    logic   [`ROB_IDX_WIDTH-1:0]        complete_rob_idx_seq    [C_SCB_NUM-1:0]    ;

    logic   [`ARCH_REG_IDX_WIDTH-1:0]   retire_arch_reg_seq     [C_SCB_NUM-1:0]    ;
    logic   [`TAG_IDX_WIDTH-1:0]        retire_tag_seq          [C_SCB_NUM-1:0]    ;
    logic   [`TAG_IDX_WIDTH-1:0]        retire_tag_old_seq      [C_SCB_NUM-1:0]    ;
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
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rob_dp_o       (rob_dp_o       ),
        .dp_rob_i       (dp_rob_i       ),
        .rob_rs_o       (rob_rs_o       ),
        .cdb_i          (cdb_i          ),
        .rob_amt_o      (rob_amt_o      ),
        .rob_fl_o       (rob_fl_o       ),
        .exception_i    (exception_i    )
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
            #(C_CLOCK_PERIOD/2) clk_i   =   ~clk_i;
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
            dp_en_num   =   inta;
        end else begin
            dp_en_num   =   intb;
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

            // Generate the dp_en in each dispatch channel
            rob_ready_num   =   rob_ready_num(rob_ready_concat);  
            dp_en_num       =   min_int(dispatch_num, rob_ready_num);
            dp_en_concat    =   dp_en(dp_en_num);

            // Assign values to dispatch channels
            for (int n = 0; n < `DP_NUM; n++) begin
                dp_rob_i[n].dp_en       =   dp_en_concat[n];
                dp_rob_i[n].pc          =   $urandom;
                dp_rob_i[n].arch_reg    =   $urandom % `ARCH_REG_NUM;
                dp_rob_i[n].tag_old     =   $urandom % `PHY_REG_NUM;
                dp_rob_i[n].tag         =   $urandom % `PHY_REG_NUM;
                dp_rob_i[n].br_predict  =   0;
                if (dp_en_concat[n]) begin
                    $display("@@ Dispatch on channel %d, PC = %h, arch_reg = %d, T = %d, tag_old = %d, br_predict: %b",
                    n, pc, arch_reg, tag, tag_old, br_predict);
                end
            end
        end
    endtask

    // Calculate the number of available entries based on rob_ready
    function int rob_ready_num (
        input logic [`DP_NUM-1:0] rob_ready
    );
        rob_ready_num = 0;
        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            if (rob_ready[idx]) begin
                rob_ready_num   =   idx + 1;
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
        input   int                             complete_num    ,
        input   logic   [`ROB_IDX_WIDTH-1:0]    head_ptr        ,
        input   logic   [`ROB_IDX_WIDTH-1:0]    tail_ptr        
    );
        int                     avail_num           ;
        int                     cdb_valid_num       ;
        logic   [`CDB_NUM-1:0]  cdb_valid_concat    ;

        begin
            @(negedge clk_i);
            // Generate the cdb_valid in each complete/CDB channel
            avail_num           =   avail_num(head_ptr, tail_ptr);
            cdb_valid_num       =   min_int(avail_num, complete_num);
            cdb_valid_concat    =   cdb_valid(cdb_valid_num);

            // Assign values to complete/CDB channels
            for (n = 0; n < `CDB_NUM; n++) begin
                cdb_i[n].valid      =   cdb_valid_concat[n];
                cdb_i[n].rob_idx    =   ($urandom % avail_num) + head_ptr;
                cdb_i[n].br_result  =   1'b0;
                if (cdb_valid_concat[n]) begin
                    $display("@@ Complete on channel %d, rob_idx = %d",
                    n, rob_idx);
                end
            end

        end
    endtask

    function int avail_num(
        input   logic   [`ROB_IDX_WIDTH-1:0]    head_ptr        ,
        input   logic   [`ROB_IDX_WIDTH-1:0]    tail_ptr        
    );
        if (head_ptr > tail_ptr) begin
            avail_num   =   tail_ptr + `ROB_ENTRY_NUM - head_ptr;
        end else begin
            avail_num   =   tail_ptr - head_ptr;
        end
    endfunction

    function logic [`CDB_NUM-1:0] cdb_valid (
        input   int                             cdb_valid_num
    );
        for (n = 0; n < `CDB_NUM; n++) begin
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
    task dispatch_monitor;
        output  int     dispatched_num  =   0;
        begin
            @(posedge clk_i);
            
            for (n = 0; n < `DP_NUM; n++) begin
                if (dp_rob_i[n].dp_en) begin
                    dispatch_arch_reg_seq[dispatch_num] =   dp_rob_i[n].arch_reg;
                    dispatch_tag_seq[dispatch_num]      =   dp_rob_i[n].tag     ;
                    dispatch_tag_old_seq[dispatch_num]  =   dp_rob_i[n].tag_old ;
                    dispatch_rob_idx_seq[dispatch_num]  =   rob_rs_o[n].rob_idx ;
                    dispatch_num++;
                end
            end
            
        end
    endtask

// --------------------------------------------------------------------
// Complete Monitor
// --------------------------------------------------------------------
    task complete_monitor;
        output  int     complete_num    =   0;
        begin
            @(posedge clk_i);
            
            for (n = 0; n < `CDB_NUM; n++) begin
                if (dp_rob_i[n].dp_en) begin
                    complete_rob_idx_seq[complete_num]  =   cdb_i[n].rob_idx ;
                    complete_num++;
                end
            end
            
        end
    endtask

// --------------------------------------------------------------------
// Retire Monitors
// --------------------------------------------------------------------
    task retire_amt_monitor;
        output  int     retire_amt_num      =   0;
        begin
            @(posedge clk_i);

            for (n = 0; n < `RT_NUM; n++) begin
                if (rob_amt_o[n].valid) begin
                    retire_arch_reg_seq[retire_amt_num] =   rob_amt_o[n].arch_reg   ;
                    retire_tag_seq[retire_amt_num]      =   rob_amt_o[n].tag        ;
                    retire_amt_num++;
                end
            end
        end
    endtask

    task retire_fl_monitor;
        output  int     retire_fl_num      =   0;
        begin
            @(posedge clk_i);

            for (n = 0; n < `RT_NUM; n++) begin
                if (rob_amt_o[n].valid) begin
                    retire_tag_seq[retire_fl_num]  =   rob_fl_o[n].tag_old ;
                    retire_fl_num++;
                end
            end
        end
    endtask

// --------------------------------------------------------------------
// Monitor Call
// --------------------------------------------------------------------
    initial begin
        fork
            dispatch_monitor(dispatch_num);
            complete_monitor(complete_num);
            retire_amt_monitor(retire_amt_num);
            retire_fl_monitor(retire_fl_num);
        join
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
        if (retire_amt_num != retire_fl_num) begin
            exit_failed();
        end
        for (int n = 0; n < retire_amt_num; n++) begin
            if ((dispatch_arch_reg_seq[n] != retire_arch_reg_seq[n]) ||
                (dispatch_tag_seq[n]      != retire_tag_seq[n])      ||
                (dispatch_tag_old_seq[n]  != retire_tag_old_seq[n])) begin
                exit_failed();
            end
        end
    endtask

// --------------------------------------------------------------------
// Scoreboard/Checker Call
// --------------------------------------------------------------------
    initial begin
        forever begin
            scoreboard_checker(retire_amt_num, retire_fl_num);
        end
    end
// ====================================================================
// Scoreboard/Checker Start
// ====================================================================

// ====================================================================
// Stimulus Generator Start
// ====================================================================
    task testcase_1 (
        input   int     dispatch_num    ,
        input   int     complete_num    
    );
        // 1. Dispatch 1 instruction per cycle to fill up the ROB
        // 2. Complete 1 instruction per cycle out-of-order.
        while (dispatch_num < `ROB_ENTRY_NUM) begin
            dispatch_driver(1);
        end

        while (complete_num < `ROB_ENTRY_NUM) begin
            complete_driver(1);
        end
    endtask
// ====================================================================
// Stimulus Generator End
// ====================================================================

// ====================================================================
// Test case call Start
// ====================================================================
    initial begin
        rst_i   =   0;
        @(negedge clk_i);
        rst_i   =   1;
        @(negedge clk_i);
        rst_i   =   0;

        repeat(10) @(negedge clk_i);

        testcase_1(dispatch_num, complete_num);

    end
// ====================================================================
// Test case call End
// ====================================================================

endmodule