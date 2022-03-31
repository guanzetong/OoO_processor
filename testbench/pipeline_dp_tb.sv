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
    virtual pipeline_dp_if  vif                 ;
    mailbox                 drv_mbx             ;
    event                   drv_done            ;
    logic   [`XLEN-1:0]     pc                  ;
    logic   [`XLEN-1:0]     inst_pc             ;
    logic   [`XLEN-1:0]     program_mem_addr    ;
    logic   [64-1:0]        program_mem_data    ;
    logic   [64-1:0]        program_mem     [`MEM_64BIT_LINES-1:0];

    task run();
        $display("T=%0t [Driver] starting ...", $time);

        pc  =   0;
        @(negedge vif.clk_i);

        $display("T=%0t [Driver] Reading program.mem", $time);
        $readmemh("../program.mem", program_mem);

        forever begin
            // gen_item    item    ;
            
            // $display("T=%0t [Driver] waiting for item from Generator ...", $time);
            // drv_mbx.get(item);

            // item.print("[Driver]");

            // Fetch Instructions
            vif.fiq_dp.avail_num =   `DP_NUM;

            for (int unsigned dp_idx = 0; dp_idx < `DP_NUM; dp_idx++) begin
                inst_pc                     =   pc + dp_idx * 4;
                program_mem_addr            =   {inst_pc[`XLEN-1:3], 3'b0};
                program_mem_data            =   program_mem[program_mem_addr];
                vif.fiq_dp.inst[dp_idx]   =   inst_pc[2] ? program_mem_data[63:32] : program_mem_data[31:0];
            end

            // Move PC
            @(posedge vif.clk_i);
            if (vif.br_mis_mon_o.valid[0]) begin
                pc  =   vif.br_mis_mon_o.br_target[0];
            end else begin
                pc  =   pc + vif.dp_fiq.dp_num * 4;
            end

            @(negedge vif.clk_i);
        end
    endtask // run()

    task init();
        $display("T=%0t [Driver] Reading program.mem", $time);
        $readmemh("../program.mem", program_mem);
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
    // monitor         m0          ;   // monitor    handle
    generator       g0          ;   // generator  handle
    // scoreboard      s0          ;   // scoreboard handle

    mailbox         drv_mbx     ;   // Connect generator  <-> driver
    mailbox         scb_mbx     ;   // Connect monitor    <-> scoreboard
    event           drv_done    ;   // Indicates when driver is done

    virtual pipeline_dp_if  vif ;   // Virtual interface handle

    function new();
        d0          =   new         ;
        // m0          =   new         ;
        g0          =   new         ;
        // s0          =   new         ;
        
        drv_mbx     =   new()       ;
        scb_mbx     =   new()       ;

        d0.drv_mbx  =   drv_mbx     ;
        g0.drv_mbx  =   drv_mbx     ;
        // m0.scb_mbx  =   scb_mbx     ;
        // s0.scb_mbx  =   scb_mbx     ;

        d0.drv_done =   drv_done    ;
        g0.drv_done =   drv_done    ;
    endfunction // new()

    virtual task run();
        d0.vif  =   vif;
        // m0.vif  =   vif;

        fork
            d0.run();
            // m0.run();
            // g0.run();
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
interface pipeline_dp_if (input bit clk_i);
    logic                                       rst_i               ;   // Reset
    FIQ_DP                                      fiq_dp              ;   // From FIQ to DP
    DP_FIQ                                      dp_fiq              ;   // From DP to FIQ
    logic                                       exception_i         ;   // External exception
    // Testing
    //      Dispatch
    DP_RS                                       dp_rs_mon_o         ;   // From Dispatcher to RS
    //      Issue
    RS_IB                                       rs_ib_mon_o         ;   // From RS to IB
    //      Execute
    IB_FU   [`FU_NUM-1:0]                       ib_fu_mon_o         ;   // From IB to FU
    //      Complete
    FU_BC                                       fu_bc_mon_o         ;   // From FU to BC
    CDB                                         cdb_mon_o           ;   // CDB
    //      Retire
    logic   [`RT_NUM-1:0][`XLEN-1:0]            rt_pc_o             ;   // PC of retired instructions
    logic   [`RT_NUM-1:0]                       rt_valid_o          ;   // Retire valid
    ROB_AMT [`RT_NUM-1:0]                       rob_amt_mon_o       ;   // From ROB to AMT
    ROB_FL                                      rob_fl_mon_o        ;   // From ROB to FL
    ROB_VFL                                     rob_vfl_mon_o       ;   // From ROB to VFL
    BR_MIS                                      br_mis_mon_o        ;   // Branch Misprediction
    //      Contents
    ROB_ENTRY   [`ROB_ENTRY_NUM-1:0]            rob_mon_o           ;   // ROB contents monitor
    RS_ENTRY    [`RS_ENTRY_NUM-1:0]             rs_mon_o            ;   // RS contents monitor
    MT_ENTRY    [`ARCH_REG_NUM-1:0]             mt_mon_o            ;   // Map Table contents monitor
    IS_INST     [`ALU_Q_SIZE  -1:0]             ALU_queue_mon_o     ;   // IB queue monitor
    IS_INST     [`MULT_Q_SIZE -1:0]             MULT_queue_mon_o    ;   // IB queue monitor
    IS_INST     [`BR_Q_SIZE   -1:0]             BR_queue_mon_o      ;   // IB queue monitor
    IS_INST     [`LOAD_Q_SIZE -1:0]             LOAD_queue_mon_o    ;   // IB queue monitor
    IS_INST     [`STORE_Q_SIZE-1:0]             STORE_queue_mon_o   ;   // IB queue monitor
    logic       [`PHY_REG_NUM-1:0] [`XLEN-1:0]  prf_mon_o           ;   // Physical Register File monitor
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
        .clk_i              (   clk_i               ),
        .rst_i              (_if.rst_i              ),
        .fiq_dp             (_if.fiq_dp             ),
        .dp_fiq             (_if.dp_fiq             ),
        .exception_i        (_if.exception_i        ),
        .dp_rs_mon_o        (_if.dp_rs_mon_o        ),
        .rs_ib_mon_o        (_if.rs_ib_mon_o        ),
        .ib_fu_mon_o        (_if.ib_fu_mon_o        ),
        .fu_bc_mon_o        (_if.fu_bc_mon_o        ),
        .cdb_mon_o          (_if.cdb_mon_o          ),
        .rt_pc_o            (_if.rt_pc_o            ),
        .rt_valid_o         (_if.rt_valid_o         ),
        .rob_amt_mon_o      (_if.rob_amt_mon_o      ),
        .rob_fl_mon_o       (_if.rob_fl_mon_o       ),
        .rob_vfl_mon_o      (_if.rob_vfl_mon_o      ),
        .br_mis_mon_o       (_if.br_mis_mon_o       ),
        .rob_mon_o          (_if.rob_mon_o          ),
        .rs_mon_o           (_if.rs_mon_o           ),
        .mt_mon_o           (_if.mt_mon_o           ),
        .ALU_queue_mon_o    (_if.ALU_queue_mon_o    ),
        .MULT_queue_mon_o   (_if.MULT_queue_mon_o   ),
        .BR_queue_mon_o     (_if.BR_queue_mon_o     ),
        .LOAD_queue_mon_o   (_if.LOAD_queue_mon_o   ),
        .STORE_queue_mon_o  (_if.STORE_queue_mon_o  ),
        .prf_mon_o          (_if.prf_mon_o          )
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