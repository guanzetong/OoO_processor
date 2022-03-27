// ====================================================================
// Transaction Object Start
// ====================================================================
class gen_item; // GEN -> DRV
    
endclass // gen_item
// ====================================================================
// Transaction Object End
// ====================================================================

// ====================================================================
// Driver Start
// ====================================================================

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
interface pipeline_dp_if (input bit clk_i);
    logic                       rst_i       ;
    FIQ_DP                      fiq_dp      ;
    DP_FIQ                      dp_fiq      ;
    CDB                         cdb         ;
    ROB_AMT [C_RT_NUM-1:0]      rob_amt     ;
    ROB_FL                      rob_fl      ;
    FU_IB   [C_FU_NUM-1:0]      fu_ib       ;
    IB_FU   [C_FU_NUM-1:0]      ib_fu       ;
    BC_PRF                      bc_prf      ;
    BR_MIS                      br_mis      ;
    logic                       exception_i ;
endinterface // pipeline_dp_if
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
    pipeline_dp_if  _if(clk_i);

// --------------------------------------------------------------------
// DUT Instantiation
// --------------------------------------------------------------------
    pipeline_dp dut (
        .clk_i          (    clk_i          ),
        .rst_i          (_if.rst_i          ),
        .fiq_dp         (_if.fiq_dp         ),
        .dp_fiq         (_if.dp_fiq         ),
        .cdb            (_if.cdb            ),
        .rob_amt        (_if.rob_amt        ),
        .rob_fl         (_if.rob_fl         ),
        .fu_ib          (_if.fu_ib          ),
        .ib_fu          (_if.ib_fu          ),
        .bc_prf         (_if.bc_prf         ),
        .br_mis         (_if.br_mis         ),
        .exception_i    (_if.exception_i    )
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