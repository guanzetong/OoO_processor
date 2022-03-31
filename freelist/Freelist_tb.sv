module freelist_tb();
    parameter dp_num = 2;
    parameter rt_num = 2;
    parameter fl_entry_num = `FL_ENTRY_NUM;
    parameter fl_idx_num = $clog2(fl_entry_num);
    parameter preg_num = 64;
    parameter preg_idx = $clog2(preg_num);

    logic clock;
    logic reset;
    logic rollback;
    
    DP_FL dp_fl;
    ROB_FL rob_fl;
    ROB_VFL rob_vfl;

    FL_DP fl_dp;
    FL_DP correct;

    FL_ENTRY   [fl_entry_num-1:0]   fl_entry;
    FL_ENTRY   [fl_entry_num-1:0]    next_fl_entry;
    logic   [fl_idx_num-1:0]                 		fl_rollback_idx;
    logic   [fl_idx_num-1:0]                 		head, next_head;
    logic   [fl_idx_num-1:0]                 		tail, next_tail;
    logic   [dp_num-1:0] [fl_idx_num-1:0] 	fl_idx;
    

    freelist dut (
        .clk_i(clock),
        .rst_i(reset),
        .rollback_i(rollback),
        .dp_fl_i(dp_fl),
        .rob_fl_i(rob_fl),
        .vfl_i(rob_vfl),
        .fl_dp_o(fl_dp),
        .fl_entry(fl_entry),
        .next_fl_entry(next_fl_entry),
        .fl_rollback_idx(fl_rollback_idx),
        .head(head),
        .next_head(next_head),
        .tail(tail),
        .next_tail(next_tail),
        .fl_idx(fl_idx)
    );


  task monitor_fl_dp_output;
    input  FL_DP    fl_dp ;

    integer i;
  
    for (i=0; i<dp_num; i++) begin 
        $display("available entry num: %b, tag: %d", fl_dp.avail_num, fl_dp.tag[i] );
    end
  endtask;

  task fl_entry_monitor;
    input  FL_ENTRY  [fl_entry_num-1:0]  fl_entry ;
    input  FL_ENTRY  [fl_entry_num-1:0]  next_fl_entry ;

    integer i;
  
    for (i=0; i < fl_entry_num; i++) begin
        $display("fl entry[%d] is %d, next_entry is %d", i, fl_entry[i].tag, next_fl_entry[i].tag);
    end
  endtask;

  task head_tail_monitor;
    input   [fl_idx_num-1:0]                 		head;
    input   [fl_idx_num-1:0] next_head;
    input   [fl_idx_num-1:0]                 		tail;
    input   [fl_idx_num-1:0] next_tail;
    $display("head is %d, tail is %d", head , tail);
    $display("nhead is %d, ntail is %d", next_head , next_tail);
  endtask

  task rollback_idx_monitor;
    input   [fl_idx_num-1:0]                 		rollback_idx;

    $display("rollback_idx is %d", rollback_idx);

  endtask


  always begin 
    #5 clock = ~clock;
    //$monitor(reset);
  end
    
  initial begin 
        clock = 0;
        #20
        reset = 1'b1;
        #20

        rollback = 0;
        dp_fl = 'b0;
        rob_fl = 'b0;
        rob_vfl = 'b0;

        @(negedge clock);
        @(negedge clock);
        reset = 1'b0;
        @(negedge clock);

        @(negedge clock);

        // ###########################
        // testcase for reset,
        // check the entry tag and head/tail pointer
        // ###########################
        $display("@@@ check initial values in freelist");
        // monitor_fl_dp_output(fl_dp);
        // fl_entry_monitor(next_fl_entry, next_fl_entry);
        // head_tail_monitor(head, next_head, tail, next_tail);
        $display("@@@ End check");

        // ###########################
        // testcase for dispatch,
        // check the entry tag and head/tail pointer
        // try different dp_num
        // ###########################
        $display("@@@ check for dispatch as different dp_num");
        
        dp_fl.dp_num = 2'b00;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        dp_fl.dp_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        //fl_entry_monitor(next_fl_entry, next_fl_entry);
        head_tail_monitor(head, next_head, tail, next_tail);


        dp_fl.dp_num = 2'b01;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        dp_fl.dp_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        //fl_entry_monitor(next_fl_entry, next_fl_entry);
        head_tail_monitor(head, next_head, tail, next_tail);


        dp_fl.dp_num = 2'b10;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        dp_fl.dp_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        //fl_entry_monitor(next_fl_entry, next_fl_entry);
        head_tail_monitor(head, next_head, tail, next_tail);

        dp_fl.dp_num = 2'b11;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        dp_fl.dp_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        //fl_entry_monitor(next_fl_entry, next_fl_entry);
        head_tail_monitor(head, next_head, tail, next_tail);

        $display("@@@ End check");

        // ###########################
        // testcase for retire,
        // check the entry tag and head/tail pointer
        // try different dp_num
        // ###########################
        $display("@@@ check for retire");

        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b11;
        @(negedge clock)
        rob_fl.rt_num = 2'b00;
        @(negedge clock)
        monitor_fl_dp_output(fl_dp);
        //fl_entry_monitor(next_fl_entry, next_fl_entry);
        head_tail_monitor(head, next_head, tail, next_tail);
        $display("@@@ End check");


        // ###########################
        // testcase for dispatch after retire,
        // check the entry tag and head/tail pointer
        // ###########################
        $display("Check for dispatch after retire");
        dp_fl.dp_num = 2'b11;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        dp_fl.dp_num = 2'b00;
        @(negedge clock);
        head_tail_monitor(head, next_head, tail, next_tail);
        $display("@@@ End check");



        // ###########################
        // testcase for rollback,
        // ###########################
        $display("@@@ check for rollback");

        @(negedge clock);
        rollback = 1;
        @(negedge clock);

        rob_vfl.tag = 'd36;
        @(negedge clock);
        rollback = 1;
        @(negedge clock);
        rollback = 0;
        dp_fl.dp_num = 2'b00;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        @(negedge clock);
        monitor_fl_dp_output(fl_dp);
        // fl_entry_monitor(next_fl_entry, next_fl_entry);
        head_tail_monitor(head, next_head, tail, next_tail);
        rollback_idx_monitor(fl_rollback_idx);
        $display("@@@ End check");


        // ###########################
        // testcase for available dispatch number,
        // check the avail_num when head and tail pointer overflow or meet.
        // ###########################
        $display("@@@ check for available dispatch number");
        @(negedge clock);
        rollback = 0;
        @(negedge clock);
        dp_fl.dp_num = 2'b11;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        #120
        @(negedge clock)
        dp_fl.dp_num = 2'b01;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        #25
        dp_fl.dp_num = 2'b01;
        rob_fl.phy_reg[0] = 'd8;
        rob_fl.phy_reg[1] = 'd9;
        rob_fl.rt_num = 2'b00;
        #25
        monitor_fl_dp_output(fl_dp);
        //fl_entry_monitor(next_fl_entry, next_fl_entry);
        head_tail_monitor(head, next_head, tail, next_tail);
        $display("@@@ End Check")




        $finish;
    
  end 
  

endmodule