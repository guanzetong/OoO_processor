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

// Tranaction Object
// ====================================================================
// Transaction Object Start
// ====================================================================
class ROB_io_item;
    bit                             dp_en        ;
    rand bit [`DP_IDX_WIDTH-1:0]    dp_idx        ;
    DP_ROB  [`DP_NUM-1:0]           dp_rob_i      ;
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
    logic rst_i;
    ROB_DP  [`DP_NUM-1:0]           rob_dp_o;
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
    mailbox drv_mbx;


    task run();
        $display("T=%0t [Driver] starting...", $time);
        

        forever begin
            DP_ROB_item [`DP_NUM-1:0]   dp_item;

            $display("T=%0t [Driver] wating for item...", $time);
            drv_mbx.get(item); // Waiting for generator to give item

            @(negedge vif.clk);
            vif.dp_rob_i <= dp_item.dp_rob_i;
            vif.cdb_i    <= dp_item.dp_
        end // forever begin
    endtask

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
        ROB_io_item item = new;
        int tag_inc = 0;
        for ( int n = 0; n < `DP_NUM; n++ ) begin
            if ( n < dispatch_num ) begin
                item.dp_rob_i[ n ].dp_en = 1'b1;
            end else begin
                item.dp_rob_i[ n ].dp_en = 1'b0;
            end
            item.dp_rob_i[ n ].tag_old = tag_inc++;
            item.dp_rob_i[ n ].tag = item.dp_rob_i[ n ].tag_old + 1;
            item.dp_rob_i[n].arch_reg = 1;
            item.dp_rob_i[n].br_predict = 0;
        end
        drv_mbx.put(item);
        
        @(drv_done); // Wait for driver to finish inputting.
        
    endtask

endclass //generator
// ====================================================================
// Generator End
// ====================================================================

// ====================================================================
// Monitor Start
// ====================================================================

// ====================================================================
// Monitor End
// ====================================================================

// ====================================================================
// Scoreboard Start
// ====================================================================

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
// Env Class Start
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