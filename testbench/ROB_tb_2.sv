
function automatic int min_int (
    input int inta, intb
);
    if (inta < intb) begin
        min_int =   inta;
    end else begin
        min_int =   intb;
    end
endfunction

function automatic int thermometer_to_binary (
    input logic [32-1:0] thermometer
);
    thermometer_to_binary   =   0;
    for (integer idx = 0; idx < 32; idx++) begin
        if (thermometer[idx]) begin
            thermometer_to_binary   =   idx + 1;
        end
    end
endfunction

function automatic logic [32-1:0] binary_to_thermometer (
    input int dp_en_num
);
    binary_to_thermometer   =   32'b0;
    for (integer idx = 0; idx < 32; idx++) begin
        if (idx < dp_en_num) begin
            binary_to_thermometer[idx]  =   1'b1;
        end else begin
            binary_to_thermometer[idx]  =   1'b0;
        end
    end
endfunction

// ====================================================================
// Transaction Object Start
// ====================================================================
class gen_item; // GEN -> DRV
    rand int    dp_num;
    rand int    cp_num;
    rand int    br_channel;
    rand bit    br_result;

    constraint dispatch_num_range {dp_num >= 0; dp_num <= `DP_NUM;}
    constraint complete_num_range {cp_num >= 0; cp_num <= `CDB_NUM;}
    constraint br_channel_range {br_channel >= 0; br_channel < `CDB_NUM;};
    constraint br_result_rate {br_result dist{0:=50, 1:=50};}
    function void print (string msg_tag="");
        $display("T=%0t %s Generator requests #Dispatch=%0d, #Complete=%0d, Branch Misprediction=%0b",
                $time, msg_tag, dp_num, cp_num, br_result);
    endfunction // print
endclass // gen_item

class mon_item; // MON -> SCB
    string                              feature         ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]   arch_reg        ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag             ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag_old         ;
    logic   [`ROB_IDX_WIDTH-1:0]        rob_idx         ;
    logic                               br_result       ;
    logic   [`ROB_IDX_WIDTH-1:0]        expected_head   ;
    logic   [`ROB_IDX_WIDTH-1:0]        expected_tail   ;
    logic                               br_flush        ;

    function void print (string msg_tag="");
        $display("T=%0t %s %s arch_reg=%0d tag=%0d tag_old=%0d rob_idx=%0d br_result=%0b expected_head=%0d expected_tail=%0d br_flush=%0d",
                $time, msg_tag, feature, arch_reg, tag, tag_old, rob_idx, br_result, expected_head, expected_tail, br_flush);
    endfunction
endclass

class squash_item;
    bit     squash;
endclass
// ====================================================================
// Transaction Object End
// ====================================================================

// ====================================================================
// Driver Start
// ====================================================================
class driver;
    virtual ROB_if  vif                 ;
    event           drv_done            ;
    mailbox         drv_mbx             ;
    
    logic       [`ROB_IDX_WIDTH-1:0]    in_flight_queue [$] ;

    task run();
        $display("T=%0t [Driver] starting ...", $time);
        @(negedge vif.clk_i);

        forever begin
            gen_item    item;

            $display("T=%0t [Driver] waiting for item from Generator ...", $time);
            drv_mbx.get(item);

            item.print("[Driver]");

            if (vif.br_flush_o) begin
                squash_in_flight();
            end else begin
                complete(item.cp_num, item.br_result, item.br_channel);  // Firstly, complete ROB entries
                dispatch(item.dp_num);  // Secondly, dispatch new instructions
            end
            
            vif.exception_i =   0;  // Disable external exceptions

            // Branch misprediction is also disabled for now

            // When transfer is over, raise the done event and reset the inputs
            @(negedge vif.clk_i);
            for (int n = 0; n < `CDB_NUM; n++) begin
                vif.cdb_i[n].valid      =   0;
                vif.cdb_i[n].rob_idx    =   0;
            end
            for (int n = 0; n < `DP_NUM; n++) begin
                vif.dp_rob_i[n].dp_en       =   0;
                vif.dp_rob_i[n].pc          =   0;
                vif.dp_rob_i[n].arch_reg    =   0;
                vif.dp_rob_i[n].tag         =   0;
                vif.dp_rob_i[n].tag_old     =   0;
                vif.dp_rob_i[n].br_predict  =   0;
            end
            ->drv_done;
        end
    endtask // run()

    task complete(int cp_num, bit br_result, int br_channel);
        logic   [`ROB_IDX_WIDTH-1:0]    cp_rob_idx  [`CDB_NUM-1:0]  ;
        int                             queue_size                  ;
        int                             queue_idx                   ;
        int                             cdb_valid_num               ;
        begin
            // Choose arbitary entries in the in_flight_queue to complete
            queue_size      =   in_flight_queue.size();
            cdb_valid_num   =   min_int(queue_size, cp_num);
            $display("T=%0t [Driver] #in-flight=%0d, #requested complete=%0d, #actual complete=%0d",
                    $time, queue_size, cp_num, cdb_valid_num);
            for (int n = 0; n < cdb_valid_num; n++) begin
                queue_size      =   in_flight_queue.size();
                queue_idx       =   $urandom % queue_size;
                cp_rob_idx[n]   =   in_flight_queue[queue_idx];
                in_flight_queue.delete(queue_idx);
            end
            // Assign the CDB action to cdb_i
            for (int n = 0; n < `CDB_NUM; n++) begin
                if (n < cdb_valid_num) begin
                    vif.cdb_i[n].valid      =   1'b1;
                    vif.cdb_i[n].rob_idx    =   cp_rob_idx[n];
                    vif.cdb_i[n].tag        =   'd0;
                    if (n == br_channel) begin
                        vif.cdb_i[n].br_result  =   br_result;
                    end else begin
                        vif.cdb_i[n].br_result  =   1'b0;
                    end
                    $display("T=%0t [Driver] Complete in channel%0d, rob_idx=%0d",
                    $time, n, vif.cdb_i[n].rob_idx);
                end else begin
                    vif.cdb_i[n].valid      =   1'b0;
                    vif.cdb_i[n].rob_idx    =   'b0;
                    vif.cdb_i[n].tag        =   'd0;
                    vif.cdb_i[n].br_result  =   1'b0;
                end
            end
        end
    endtask // complete()

    task dispatch(
        input   int     dp_num
    );
        logic   [32-1:0]            rob_ready_concat    ;
        logic   [32-1:0]            dp_en_concat        ;
        int                         rob_ready_num       ;
        int                         dp_en_num           ;
        int                         squash_msg_num      ;

        begin
            // Read rob_ready in each dispatch channel
            rob_ready_concat    =   32'b0;
            for (int n = 0 ; n < `DP_NUM; n++) begin
                rob_ready_concat[n] = vif.rob_dp_o[n].rob_ready;
            end
            // Generate the dp_en in each dispatch channel
            rob_ready_num   =   thermometer_to_binary(rob_ready_concat);
            dp_en_num       =   min_int(dp_num, rob_ready_num);
            dp_en_concat    =   binary_to_thermometer(dp_en_num);
            $display("T=%0t [Driver] #available ROB=%0d, #requested dispatch=%0d, #actual dispatch=%0d",
                    $time, rob_ready_num, dp_num, dp_en_num);
            for (int n = 0; n < `DP_NUM; n++) begin
                vif.dp_rob_i[n].dp_en       =   dp_en_concat[n];
                if (dp_en_concat[n]) begin
                    vif.dp_rob_i[n].pc          =   $urandom;
                    vif.dp_rob_i[n].arch_reg    =   $urandom % `ARCH_REG_NUM;
                    vif.dp_rob_i[n].tag         =   $urandom % `PHY_REG_NUM;
                    vif.dp_rob_i[n].tag_old     =   $urandom % `PHY_REG_NUM;
                    vif.dp_rob_i[n].br_predict  =   0;
                    $display("T=%0t [Driver] Dispatch in channel%0d, PC=%0h, arch_reg= %0d, tag=%0d, tag_old=%0d, br_predict=%0b, rob_idx=%0d",
                    $time, n, vif.dp_rob_i[n].pc, vif.dp_rob_i[n].arch_reg, vif.dp_rob_i[n].tag, 
                    vif.dp_rob_i[n].tag_old, vif.dp_rob_i[n].br_predict, vif.rob_rs_o[n].rob_idx);
                    in_flight_queue.push_back(vif.rob_rs_o[n].rob_idx);
                end else begin
                    vif.dp_rob_i[n].pc          =   0;
                    vif.dp_rob_i[n].arch_reg    =   0;
                    vif.dp_rob_i[n].tag         =   0;
                    vif.dp_rob_i[n].tag_old     =   0;
                    vif.dp_rob_i[n].br_predict  =   0;
                end
            end
        end
    endtask // dispatch()

    task squash_in_flight();
        begin
            $display("T=%0t [Driver] Branch misprediction. Squash in-flight queue.", $time);
            in_flight_queue.delete();
        end
    endtask // squash_in_flight()
endclass // driver
// ====================================================================
// Driver End
// ====================================================================

// ====================================================================
// Scoreboard Start
// ====================================================================
class scoreboard;
    mailbox     scb_mbx                     ;
    mon_item    dispatch_queue  [$]         ;
    mon_item    complete_queue  [$]         ;
    mon_item    retire_queue    [$]         ;
    int         check_idx                   ;
    int         squash_start_idx            ;
    int         last_squash_time    =   0   ;

    task run();
        forever begin
            mon_item item;
            // Get item from mailbox
            $display("T=%0t [Scoreboard] waiting for item from Monitor ...", $time);
            scb_mbx.get(item);

            item.print("[Scoreboard]");

            // Push into a queue according to the "feature" of item
            case (item.feature)
                "dispatch"  :   dispatch_queue.push_back(item);
                "complete"  :   complete_queue.push_back(item);
                "retire"    :   retire_queue.push_back(item);
            endcase

            if (item.feature == "dispatch") begin
                // Should not dispatch any instruction at branch misprediction
                if (item.br_flush) begin
                    $display("T=%0t [Scoreboard] Dispatch & branch misprediction at the same time", $time);
                    $display("T=%0t [Scoreboard] Error: dispatch & br_flush=%0b", 
                            $time, item.br_flush);
                    exit_on_error();
                end
                // Check dispatched rob index
                if (item.expected_tail != item.rob_idx) begin
                    $display("T=%0t [Scoreboard] Mismatched dispatched entry index", $time);
                    $display("T=%0t [Scoreboard] Error: check_idx=%0d rob_idx=%0d expected_tail=%0d", 
                            $time, dispatch_queue.size()-1, item.rob_idx, item.expected_tail);
                    exit_on_error();
                end
            end

            // Check in-order retirement by comparing 
            // dispatch_queue and retire_queue
            if (item.feature == "retire") begin
                // Should not retire any instruction at branch misprediction
                if (item.br_flush) begin
                    $display("T=%0t [Scoreboard] Retire & branch misprediction at the same time", $time);
                    $display("T=%0t [Scoreboard] Error: retire & br_flush=%0b", 
                            $time, item.br_flush);
                    exit_on_error();
                end

                // Check the length of retire queue. Should not exceeds the length
                // of dispatch queue.
                if (retire_queue.size() > dispatch_queue.size()) begin
                    $display("T=%0t [Scoreboard] #Retired > #Dispatched", $time);
                    $display("T=%0t [Scoreboard] Error: #Dispatched=%0d #Retired=%0d", 
                            $time, dispatch_queue.size(), retire_queue.size());
                    exit_on_error();
                end

                check_idx   =   retire_queue.size() - 1;
                // Check the arch_reg of retired and dispatched instruction
                if (retire_queue[check_idx].arch_reg != dispatch_queue[check_idx].arch_reg) begin
                    $display("T=%0t [Scoreboard] Mismatched architectural register", $time);
                    $display("T=%0t [Scoreboard] Error: check_idx=%0d dp_arch_reg=%0d rt_arch_reg=%0d", 
                            $time, check_idx, dispatch_queue[check_idx].arch_reg, retire_queue[check_idx].arch_reg);
                    exit_on_error();
                end
                // Check the tag of retired and dispatched instruction
                if (retire_queue[check_idx].tag != dispatch_queue[check_idx].tag) begin
                    $display("T=%0t [Scoreboard] Mismatched tag", $time);
                    $display("T=%0t [Scoreboard] Error: check_idx=%0d dp_tag=%0d rt_tag=%0d", 
                            $time, check_idx, dispatch_queue[check_idx].tag, retire_queue[check_idx].tag);
                    exit_on_error();
                end
                // Check the tag_old of retired and dispatched instruction
                if (retire_queue[check_idx].tag_old != dispatch_queue[check_idx].tag_old) begin
                    $display("T=%0t [Scoreboard] Mismatched tag_old", $time);
                    $display("T=%0t [Scoreboard] Error: check_idx=%0d dp_tag_old=%0d rt_tag_old=%0d", 
                            $time, check_idx, dispatch_queue[check_idx].tag_old, retire_queue[check_idx].tag_old);
                    exit_on_error();
                end
            end

            // Squash the younger entries in dispatch queue if a branch misprediction occurs
            if (item.feature == "branch") begin
                squash_start_idx    =   retire_queue.size() - 1;
                dispatch_queue      =   dispatch_queue[0:squash_start_idx];
                $display("T=%0t [Scoreboard] Branch misprediction. Squash any instruction in dispatched queue that is younger than the tail of retired queue.", 
                        $time);
            end
        end
    endtask // run()

    task exit_on_error;
        $display("@@FAILED");
        $finish;
    endtask // exit_on_error()
endclass // scoreboard
// ====================================================================
// Scoreboard End
// ====================================================================

// ====================================================================
// Monitor Start
// ====================================================================
class monitor;
    virtual ROB_if                  vif                         ;
    mailbox                         scb_mbx                     ;
    logic   [`ROB_IDX_WIDTH-1:0]    expected_head       =   0   ;
    logic   [`ROB_IDX_WIDTH-1:0]    expected_tail       =   0   ;

    task run();
        $display("T=%0t [Monitor] starting ...", $time);
        forever begin
            @(posedge vif.clk_i);
            // Check dispatch channels
            for (int n = 0; n < `DP_NUM; n++) begin
                if (vif.dp_rob_i[n].dp_en) begin
                    mon_item item       =   new;
                    item.feature        =   "dispatch";
                    item.arch_reg       =   vif.dp_rob_i[n].arch_reg;
                    item.tag            =   vif.dp_rob_i[n].tag;
                    item.tag_old        =   vif.dp_rob_i[n].tag_old;
                    item.rob_idx        =   vif.rob_rs_o[n].rob_idx;
                    item.br_result      =   0;
                    item.expected_head  =   expected_head;
                    item.expected_tail  =   expected_tail;
                    item.br_flush       =   vif.br_flush_o;
                    expected_tail       =   expected_tail + 1;  // Move tail pointer
                    scb_mbx.put(item);
                    $display("T=%0t [Monitor] Dispatch detected in channel %0d",
                            $time, n);
                end
            end
            // Check complete channels
            for (int n = 0; n < `CDB_NUM; n++) begin
                if (vif.cdb_i[n].valid) begin
                    mon_item item       =   new;
                    item.feature        =   "complete";
                    item.arch_reg       =   0;
                    item.tag            =   vif.cdb_i[n].tag;
                    item.tag_old        =   0;
                    item.rob_idx        =   vif.cdb_i[n].rob_idx;
                    item.br_result      =   vif.cdb_i[n].br_result;
                    item.expected_head  =   expected_head;
                    item.expected_tail  =   expected_tail;
                    item.br_flush       =   vif.br_flush_o;
                    scb_mbx.put(item);
                    $display("T=%0t [Monitor] Complete detected in channel %0d",
                            $time, n);
                end
            end
            // Check retire channels
            for (int n = 0; n < `RT_NUM; n++) begin
                if (vif.rob_amt_o[n].valid && vif.rob_fl_o[n].valid) begin
                    mon_item item       =   new;
                    item.feature        =   "retire";
                    item.arch_reg       =   vif.rob_amt_o[n].arch_reg;
                    item.tag            =   vif.rob_amt_o[n].phy_reg;
                    item.tag_old        =   vif.rob_fl_o[n].phy_reg;
                    item.rob_idx        =   0;
                    item.br_result      =   0;
                    item.expected_head  =   expected_head;
                    item.expected_tail  =   expected_tail;
                    expected_head       =   expected_head + 1;
                    item.br_flush       =   vif.br_flush_o; // Move head pointer
                    scb_mbx.put(item);
                    $display("T=%0t [Monitor] Retire detected in channel %0d",
                            $time, n);
                end
            end

            // Check branch misprediction
            if (vif.br_flush_o) begin
                mon_item item = new;
                item.feature        =   "branch";
                item.arch_reg       =   0;
                item.tag            =   0;
                item.tag_old        =   0;
                item.rob_idx        =   0;
                item.expected_head  =   expected_head;
                item.expected_tail  =   expected_tail;
                item.br_flush       =   vif.br_flush_o;
                scb_mbx.put(item);
                $display("T=%0t [Monitor] Branch misprediction detected",
                        $time);
                expected_head       =   0;
                expected_tail       =   0;
            end
        end
    endtask // run()
endclass // monitor
// ====================================================================
// Monitor End
// ====================================================================

// ====================================================================
// Generator Start
// ====================================================================
class generator;
    mailbox drv_mbx;
    event   drv_done;
    int     num     =   1000;

    task run();
        for (int i = 0; i < num; i++) begin
            gen_item item   =   new;
            item.randomize();
            $display("T=%0t [Generator] Loop:%0d/%0d create next item",
                    $time, i+1, num);
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
    driver          d0          ;   // driver     handle
    monitor         m0          ;   // monitor    handle
    generator       g0          ;   // generator  handle
    scoreboard      s0          ;   // scoreboard handle

    mailbox         drv_mbx     ;   // Connect generator  <-> driver
    mailbox         scb_mbx     ;   // Connect monitor    <-> scoreboard
    event           drv_done    ;   // Indicates when driver is done

    virtual ROB_if  vif         ;   // Virtual interface handle

    function new();
        d0          =   new         ;
        m0          =   new         ;
        g0          =   new         ;
        s0          =   new         ;
        
        drv_mbx     =   new()       ;
        scb_mbx     =   new()       ;

        d0.drv_mbx  =   drv_mbx     ;
        g0.drv_mbx  =   drv_mbx     ;
        m0.scb_mbx  =   scb_mbx     ;
        s0.scb_mbx  =   scb_mbx     ;

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
            s0.run();
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
interface ROB_if (input bit clk_i);
    logic                           rst_i       ;
    ROB_DP  [`DP_NUM-1:0]           rob_dp_o    ;
    DP_ROB  [`DP_NUM-1:0]           dp_rob_i    ;
    ROB_RS  [`DP_NUM-1:0]           rob_rs_o    ;
    CDB     [`CDB_NUM-1:0]          cdb_i       ;
    ROB_AMT [`RT_NUM-1:0]           rob_amt_o   ;
    ROB_FL  [`RT_NUM-1:0]           rob_fl_o    ;
    logic                           exception_i ;
    logic                           br_flush_o  ;
endinterface // ROB_if
// ====================================================================
// Interface End
// ====================================================================

// ====================================================================
// Testbench Start
// ====================================================================
module ROB_tb;

// --------------------------------------------------------------------
// Local Parameters
// --------------------------------------------------------------------
    localparam  C_CLOCK_PERIOD  =   10;

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
            #(C_CLOCK_PERIOD/2) clk_i   =   ~clk_i;
        end
    end

// --------------------------------------------------------------------
// Interface Instantiation
// --------------------------------------------------------------------
    ROB_if  _if(clk_i);

// --------------------------------------------------------------------
// DUT Instantiation
// --------------------------------------------------------------------
    ROB dut (
        .clk_i          (    clk_i          ),
        .rst_i          (_if.rst_i          ),
        .rob_dp_o       (_if.rob_dp_o       ),
        .dp_rob_i       (_if.dp_rob_i       ),
        .rob_rs_o       (_if.rob_rs_o       ),
        .cdb_i          (_if.cdb_i          ),
        .rob_amt_o      (_if.rob_amt_o      ),
        .rob_fl_o       (_if.rob_fl_o       ),
        .exception_i    (_if.exception_i    ),
        .br_flush_o     (_if.br_flush_o     )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Test Instantiation
// --------------------------------------------------------------------
    test    t0;

// --------------------------------------------------------------------
// Call test
// --------------------------------------------------------------------
    initial begin
        _if.rst_i       =   1;
        _if.dp_rob_i    =   0;
        _if.cdb_i       =   0;
        _if.exception_i =   0;
        // $display("tail_o=%0b", _if.tail_o);
        // Apply reset and start stimulus
        #50 _if.rst_i   =   0;
        // $display("tail_o=%0b", _if.tail_o);

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

endmodule // ROB_tb

// ====================================================================
// Testbench End
// ====================================================================