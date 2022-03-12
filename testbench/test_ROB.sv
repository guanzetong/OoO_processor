/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  test_ROB.sv                                         //
//                                                                     //
//  Description :  Test ROB MODULE of the pipeline;                    // 
//                 Reorders out of order instructions                  //
//                 and update state (as if) in the archiectural        //
//                 order.                                              //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

/*
1. Dispatch, fill all entries
2. Complete,
3. Retire, empty all entries,
4. Dispatch, Complete some, retire some
*/

// Transaction Object
// ====================================================================
// Transaction Object Start
// ====================================================================
class ROB_io_item; // for mon ->scb
    bit                             dp_en      ;
    bit [`DP_IDX_WIDTH-1:0]         dp_idx     ;
    DP_ROB  [`DP_NUM-1:0]           dp_rob_i   ;
    ROB_RS  [`DP_NUM-1:0]           rob_rs_o   ;
    CDB     [`CDB_NUM-1:0]          cdb_i      ;
    ROB_AMT [`RT_NUM-1:0]           rob_amt_o  ;
    ROB_FL  [`RT_NUM-1:0]           rob_fl_o   ;
    logic                           exception_i;

    function void assign_DP_ROB_item( DP_ROB_item dp_rob );
        for ( int n = 0; n < `DP_NUM; n++ ) begin
            dp_rob_i[n].dp_en      = dp_rob[n].dp_en;
            dp_rob_i[n].pc         = dp_rob[n].pc;
            dp_rob_i[n].arch_reg   = dp_rob[n].arch_reg;
            dp_rob_i[n].tag_old    = dp_rob[n].tag_old;
            dp_rob_i[n].tag        = dp_rob[n].tag;
            dp_rob_i[n].br_predict = dp_rob[n].br_predict;
        end // for
    endfunction
endclass

class ROB_trans_obj; // for gen -> driver
    rand int                        inst_dispatch; // Number of instructions to be dispatched
    rand int                        inst_complete; // Number of instructions completed
    rand bit                        has_exception;
    rand bit                        br_result;
    rand bit [`ROB_IDX_WIDTH-1:0]   br_rob_idx;
    rand int                        high;
    rand int                        low;
endclass

class DP_ROB_item;
    bit                                     dp_en       ;
    rand bit    [`XLEN-1:0]                 pc          ;
    rand bit    [`ARCH_REG_IDX_WIDTH-1:0]   arch_reg    ;
    rand bit    [`TAG_IDX_WIDTH-1:0]        tag_old     ;
    rand bit    [`TAG_IDX_WIDTH-1:0]        tag         ;
    rand bit                                br_predict  ;

    function new(bit en = 1);
        dp_en   =   en;
    endfunction
endclass

class CDB_ROB_item;
    rand bit valid;
    rand bit [`TAG_IDX_WIDTH-1:0] tag;
endclass

// ====================================================================
// Transaction Object End
// ====================================================================
// ====================================================================
// Interface Start
// ====================================================================
interface ROB_if(input bit clk);
    logic                           rst_i               ;
    ROB_DP  [`DP_NUM-1:0]           rob_dp_o            ;
    DP_ROB  [`DP_NUM-1:0]           dp_rob_i            ;
    ROB_RS  [`DP_NUM-1:0]           rob_rs_o            ;
    CDB     [`CDB_NUM-1:0]          cdb_i               ;
    ROB_AMT [`RT_NUM-1:0]           rob_amt_o           ;
    ROB_FL  [`RT_NUM-1:0]           rob_fl_o            ;
    logic                           exception_i         ;
endinterface
// ====================================================================
// Interface End
// ====================================================================
// ====================================================================
// Drivers Start
// ====================================================================
class driver;
    virtual ROB_if vif;
    event drv_done;
    event monitor_done;
    semaphore sema_drv_mon;
    mailbox drv_mbx;

    function new(semaphore sema);
        seam_drv_mon = sema;
    endfunction

    task run();
        $display("T=%0t [Driver] starting...", $time);

        forever begin
            ROB_trans_obj item; // High level abstraction of transaction
            //DP_ROB_item [`DP_NUM-1:0]   dp_item;

            $display("T=%0t [Driver] waiting for item...", $time);
            drv_mbx.get(item); // Waiting for generator to give item

            @(negedge clk_i);

            int rob_ready_concat;
            // Read rob_ready
            for ( int n = 0 ; n < `DP_NUM; n++) begin
                rob_ready_concat[n] = vif.rob_dp_o[n].rob_ready;
            end
            vif.dp_rob_i    = dp_rob( rob_ready_num( rob_ready_concat ),  item.inst_dispatch);
            vif.cdb_i       = cdb_rob( item.inst_complete, item.high, item.low );
            vif.exception_i = item.exception_i;

            // Now wait until monitor finishes
            @(monitor_done);

            ->drv_done; // Tell generator to send another item (may be )
        end // forever begin
    endtask

    // Creats a DP_ROB bit array
    function automatic DP_ROB [`DP_NUM-1:0] dp_rob ( int rob_ready_num, int inst_dispatch );
        automatic logic [`DP_NUM-1:0] dp_en = dp_en(rob_ready_num, inst_dispatch);
        for ( int n = 0; n < `DP_NUM; n++ ) begin
            dp_rob[n].dp_en      = dp_en[n];
            dp_rob[n].pc         = $random;
            dp_rob[n].arch_reg   = $random;
            dp_rob[n].tag_old    = $random;
            dp_rob[n].tag        = $random;
            dp_rob[n].br_predict = 0;
        end
    endfunction

    function logic [`DP_NUM-1:0] dp_en ( int rob_ready_num, int inst_dispatch );
        for ( int n = 0; n < `DP_NUM; n++ ) begin
            if ( n < min_int( rob_ready_num, inst_dispatch ) ) begin
                dp_en[n]    =   1'b1; // Set to one.
            end // if
        end // for
    endfunction // dp_en

    function int rob_ready_num ( int rob_ready );
        rob_ready_num = 0;
        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            if (rob_ready[idx]) begin
                rob_ready_num   =   idx + 1;
            end
        end
    endfunction

    // [14, 17]

    // [0, 13] + 3
    // $random % (high - low) + low
    // 0, 1, 2 + 14 = 14, 15, 16

    function automatic CDB [`CDB_NUM-1:0] cdb_rob( int instr_complete, int high, int low);
        for ( int n = 0; n < `CDB_NUM; n++ ) begin
            if ( n < instr_complete ) begin
                cdb_rob[n].valid = 1'b1;
                cdb_rob[n].rob_idx = $random % (high - low) + low;
            end
        end
    endfunction

    function int min_int ( int a, int b );
        min_int = a < b ? a : b;
    endfunction
endclass


// ====================================================================
// Drivers End
// ====================================================================

// ====================================================================
// Generator Start
// ====================================================================
class generator;
    mailbox drv_mbx;
    event drv_done;
    int num = 20;

    function new();
        
    endfunction //new()

    task run();
        int dispatch_num = 2;
        /*
        for (int n = 0; n < num; n++) begin
            DP_ROB_item     [`DP_NUM-1:0]   dp_item;
            ROB_io_item item = new;
            for (integer idx = 0; idx < `DP_NUM; idx++) begin
                dp_item[idx] = new();
                dp_item[idx].dp_en = vif.rob_dp_o[idx].rob_ready;
                dp_item[idx].randomize();
            end // for
            // Transform to transaction object
            item.dp_rob_i <= dp_item;


            drv_mbx.put(item);
        end // for
        */
        // ROB_io_item item = new;
        // int tag_inc = 0;
        // for ( int n = 0; n < `DP_NUM; n++ ) begin
        //     if ( n < dispatch_num ) begin
        //         item.dp_rob_i[ n ].dp_en = 1'b1;
        //     end else begin
        //         item.dp_rob_i[ n ].dp_en = 1'b0;
        //     end
        //     item.dp_rob_i[ n ].tag_old = tag_inc++;
        //     item.dp_rob_i[ n ].tag = item.dp_rob_i[ n ].tag_old + 1;
        //     item.dp_rob_i[n].arch_reg = 1;
        //     item.dp_rob_i[n].br_predict = 0;
        // end
        // drv_mbx.put(item);
        
        // @(drv_done); // Wait for driver to finish inputting.
        int inst_dispatched = 0;
        for (int i = 0; ; ) begin
            
        end
        ROB_trans_obj item = new;
        //item.randomize();
        item.dispatch_num = `ROB_ENTRY_NUM;
        item.low  = 0;
        item.high = 15;
        
    endtask

endclass //generator
// ====================================================================
// Generator End
// ====================================================================

// ====================================================================
// Monitor Start
// ====================================================================
class monitor;
    virtual ROB_if vif;
    mailbox scb_mbx;
    semaphore sema_mon;
    function new();
        sema_mon = new(1);
    endfunction //new()

    task run();
        $display("T=%0t [Monitor] starting ...",$time);
        fork
           sample_port("Thread0");
           sample_port("Thread1");
        join
    endtask

    task sample_port(string notice="");
        forever begin
            @(posedge clk_i);

            int rob_dp_i_dp_en_concat;  // Read rob_dp_i_dp_en_concat
            int cdb_i_concat;           // Read cdb_i_valid_concat
   
            for (integer index; index < `DP_NUM; index++) begin 
                rob_dp_i_dp_en_concat[index] = vif.rob_dp_i[index].dp_en;
                if (rob_dp_i_dp_en_concat[index]) begin 
                    ROB_io_item item = new;
                    sema_mon.get();
                    item.dp_rob_i[index].tag        =   vif.dp_rob_i[index].tag;
                    item.dp_rob_i[index].tag_old    =   vif.dp_rob_i[index].tag_old;
                    item.dp_rob_i[index].arch_reg   =   vif.dp_rob_i[index].arch_reg;
                    item.dp_rob_i[index].br_predict =   vif.dp_rob_i[index].br_predict;
                end
            end 
            $display("T=%0t [Monitor]%s ROB -> Dispatch",$time, notice);

            for (integer index; index < `CDB_NUM; index++) begin 
                cdb_i_valid_concat[index] = vif.cdb_i[index].valid;
                if (cdb_i_valid_concat[index]) begin 
                    ROB_io_item item = new;
                    sema_mon.get();
                    item.dp_rob_i[index].tag        =   vif.dp_rob_i[index].tag;
                    item.dp_rob_i[index].tag_old    =   vif.dp_rob_i[index].tag_old;
                    item.dp_rob_i[index].arch_reg   =   vif.dp_rob_i[index].arch_reg;
                    item.dp_rob_i[index].br_predict =   vif.dp_rob_i[index].br_predict;
                end
            end 
            $display("T=%0t [Monitor]%s CDB valid -> ROB",$time, notice);

            @(posedge clk_i); 
            sema_mon.put();
            for(integer index; index < `RT_NUM; index++) begin
                item.rob_amt_o[index].arch_reg      =    vif.rob_amt_o[index].arch_reg ;
                item.rob_amt_o[index].phy_reg       =    vif.rob_amt_o[index].phy_reg  ;
                item.rob_fl_o[index] .phy_reg       =    vif.rob_fl_o[index] .phy_reg  ;
                end
            $display("T=%0t [Monitor]%s Monitor Output",$time, notice);
            scb_mbx.put(item);
            item.print({"Monitor_",notice});
        end// forever begin
    endtask//sample port
endclass // monitor

concat_dp_i [dp_nums]
if 
for (0 ~ dp_num-1)
    update tag, tag_old, arch reg, br_predict;
end

for (0 ~ CDB_num-1)
    update tag, 

// ====================================================================
// Monitor End
// ====================================================================

// ====================================================================
// Scoreboard Start
// ====================================================================

// High-level discription of ROB which minimally discribes sucha a structure.
class scoreboard;

    int head; // Indices for head and tail ()
    int tail;
    int entries_avail; // Used to represent that state -> Which based off the input provided by the transactional object.

    function new();
        this.head = 0;
        this.tail = 0;
    endfunction

    // Modifies its state based on the transaction object.
    // This is fine since it 
    function update_state( ROB_trans_obj item );

    endfunction

    // Uses the current transaction object to verify that state matches appropriately.
    task verify_correctness( input ROB_trans_obj item );

    endtask

endclass

class rob_sim;


endclass


// ====================================================================
// Scoreboard End
// ====================================================================

// ====================================================================
// Checker Start
// ====================================================================

// ====================================================================
// Checker End
// ====================================================================

// ====================================================================
// Env Class Start
// ====================================================================

class env;
    driver     d0; // Diver handle
    monitor    m0;
    generator  g0;
    scoreboard s0;

    mailbox   drv_mbx; // Connects GEN -> DRV
    mailbox   scb_mbx; // Connect  MON -> SCB
    event     drv_done;

    virtual ROB_if vif; // Virtual inteface handle


    function new();
        d0 = new;
        m0 = new;
        g0 = new;
        s0 = new;
        drv_mbx = new();
        scb_mbx = new();


        d0.drv_mbx = drv_mbx;
        g0.drv_mbx = drv_mbx;
        m0.scb_mbx = scb_mbx;
        s0.scb_mbx = scb_mbx;

        d0.drv_done = drv_done;
        g0.drv_done = drv_done;
    endfunction

    virtual task run();
        // Connects the interface to the driver and monitor
        d0.vif = vif;
        m0.vif = vif;

        fork
            d0.run();
            m0.run();
            g0.run();
            s0.run();
        join_any // Wait until at least one thread joins
    endtask
endclass

// ====================================================================
// Env Class End
// ====================================================================


// ====================================================================
// Test Class Start
// ====================================================================
class test;
    env e0;

    function new();
        e0 = new;
    endfunction

    task run();
        e0.run();
    endtask
endclass

// ====================================================================
// Test Class End
// ====================================================================

// ====================================================================
// Testbench Start
// ====================================================================
module testbench;


// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_CLOCK_PERIOD  =   10;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic                           clk_i               ;
    ROB_if _if( clk_i );

// ====================================================================
// Signal Declarations End
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

// ====================================================================
// Design Under Test (DUT) Instantiation Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   ROB
// Description  :   Reorder the retirement in program order.
// --------------------------------------------------------------------
    ROB dut (
        .clk_i          (    clk_i      ),
        .rst_i          (_if.rst_i      ),
        .rob_dp_o       (_if.rob_dp_o       ),
        .dp_rob_i       (_if.dp_rob_i       ),
        .rob_rs_o       (_if.rob_rs_o       ),
        .cdb_i          (_if.cdb_i          ),
        .rob_amt_o      (_if.rob_amt_o      ),
        .rob_fl_o       (_if.rob_fl_o       ),
        .exception_i    (_if.exception_i    )
    );
// --------------------------------------------------------------------

// ====================================================================
// Design Under Test (DUT) Instantiation End
// ====================================================================

// ====================================================================
// Drivers Start
// ====================================================================

// --------------------------------------------------------------------
// DP_ROB Driver
// --------------------------------------------------------------------
    task randomize_dispatch();
        
    endtask

    // 
    task dispatch(
        input   dp_en,
        input   arch_reg,
        input   tag,
        input   tag_old,
        input   br_predict
    );
        @(negedge clk_i);
        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            dp_rob_i[idx].dp_en         =   dp_en       ;
            dp_rob_i[idx].arch_reg      =   arch_reg    ;
            dp_rob_i[idx].tag           =   tag         ;
            dp_rob_i[idx].tag_old       =   tag_old     ;
            dp_rob_i[idx].br_predict    =   br_predict  ;
        end
    endtask //automatic
    
        task dp_channel (
        input   [`DP_IDX_WIDTH-1:0]         dp_idx      ,
        input                               dp_en       ,
        input   [`XLEN-1:0]                 pc          ,
        input   [`ARCH_REG_IDX_WIDTH-1:0]   arch_reg    ,
        input   [`TAG_IDX_WIDTH-1:0]        tag_old     ,
        input   [`TAG_IDX_WIDTH-1:0]        tag         ,
        input                               br_predict  
    );
        @(negedge clk_i);
        dp_rob_i[dp_idx].dp_en         =   dp_en       ;
        dp_rob_i[dp_idx].arch_reg      =   arch_reg    ;
        dp_rob_i[dp_idx].tag           =   tag         ;
        dp_rob_i[dp_idx].tag_old       =   tag_old     ;
        dp_rob_i[dp_idx].br_predict    =   br_predict  ;
    endtask

    task dp_multichannel(
        input   [`DP_NUM-1:0]               rob_ready,
        output  ROB_io_item                 item
    );
        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            if (rob_ready[idx]) begin
                rob_ready_num   =   idx;
            end
        end

        dp_actual_num   =   $random % (rob_ready_num + 1);

        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            if (idx < dp_actual_num) begin
                dp_channel(
                    .dp_idx     (dp_idx     ),
                    .dp_en      (dp_en      ),
                    .pc         (pc         ),
                    .arch_reg   (arch_reg   ),
                    .tag_old    (tag_old    ),
                    .tag        (tag        ),
                    .br_predict (br_predict )
                );
                $display("@@ Dispatch on channel %d, PC = %h, arch_reg = %d, T = %d, tag_old = %d, br_predict: %b",
                dp_idx, pc, arch_reg, tag, tag_old, br_predict);
            end
        end
        
    endtask


endmodule
// ====================================================================
// Testbench Start
// ====================================================================