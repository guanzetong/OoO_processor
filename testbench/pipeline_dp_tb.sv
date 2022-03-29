// ====================================================================
// Transaction Object Start
// ====================================================================
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
    virtual pipeline_dp_if      vif         ;
    mailbox                     drv_mbx     ;
    event                       drv_done    ;
    int                         pc          ;
    logic   [][64-1:0]          program_mem ;

    int                         inst_type   ;   // 0: R, 1: I, 2: S, 

    task run();
        $display("T=%0t [Driver] starting ...", $time);

        pc  =   0;
        @(negedge vif.clk_i);

        forever begin
            gen_item    item    ;
            
            $display("T=%0t [Driver] waiting for item from Generator ...", $time);
            drv_mbx.get(item);

            item.print("[Driver]");

            // Dispatch
            dispatch(item.dp_num);

        end
    endtask //

    task init();
        $display("T=%0t [Driver] Reading program.mem", $time);

    endtask

    task dispatch(int dp_num);
        begin
            vif.fiq_dp.avail_num =   dp_num;
            for (int dp_idx = 0; dp_idx < `DP_NUM; dp_idx++) begin
                vif.fiq_dp.thread_idx[dp_idx]   =   0;
                vif.fiq_dp.br_predict[dp_idx]   =   0;
                vif.fiq_dp.pc[dp_idx]           =   pc + dp_idx * 4;

                inst_type   =   $urandom % 4;
            end

        end
    endtask
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
            item.print("[Generator]");
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

    virtual pipeline_dp_if  vif ;   // Virtual interface handle

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
module pipeline_dp_tb;

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
        .fiq_dp         (_if.fiq_dp         ),  // input
        .dp_fiq         (_if.dp_fiq         ),
        .cdb            (_if.cdb            ),  // input
        .rob_amt        (_if.rob_amt        ),
        .rob_fl         (_if.rob_fl         ),
        .fu_ib          (_if.fu_ib          ),  // input
        .ib_fu          (_if.ib_fu          ),
        .bc_prf         (_if.bc_prf         ),
        .br_mis         (_if.br_mis         ),
        .exception_i    (_if.exception_i    )   // input
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
        _if.fiq_dp      =   0;
        _if.cdb         =   0;
        _if.fu_ib       =   0;
        _if.exception_i =   0;
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