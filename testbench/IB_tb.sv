// ====================================================================
// Transaction Object Start
// ====================================================================
class gen_item;
    rand int                    inst_num                    ;
    rand int                    inst_type   [`IS_NUM-1:0]   ;
    rand bit    [`FU_NUM-1:0]   FU_ready                    ;

    constraint inst_num_range {inst_num >= 0; inst_num <=`IS_NUM;}
    constraint inst_type_range {
        foreach(inst_type[i]) {
            inst_type[i]>=0; inst_type[i] < 6;
        }
    }

    function void print (string msg_tag="");
        $display("T=%0t %s Generator requests #push-in=%0d, FU_ready=%10b",
                $time, msg_tag, inst_num, FU_ready);
    endfunction
endclass // gen_item

class mon_item;
    string      feature     ;
    IS_INST     is_inst     ;
    int         is_channel  ;

    function void print (string msg_tag="");
        $display("T=%0t %s %s in channel %0d, PC=%0d",
            $time, msg_tag, feature, is_channel, is_inst.pc);
    endfunction

endclass

// ====================================================================
// Transaction Object End
// ====================================================================

// ====================================================================
// Driver Start
// ====================================================================
class driver;
    virtual IB_if           vif         ;
    event                   drv_done    ;
    mailbox                 drv_mbx     ;
    
    logic   [`XLEN-1:0]     pc          ;

    task run();
        $display("T=%0t [Driver] starting ...", $time);
        pc  =   0;
        @(negedge vif.clk_i);

        forever begin
            gen_item    item;

            $display("T=%0t [Driver] waiting for item from Generator ...", $time);
            drv_mbx.get(item);

            item.print("[Driver]");

            // Set FU_IB insterface
            vif.fu_ib_i =   item.FU_ready   ;

            #1; // Let the Simulator proceed and calculate the number of available entries inside IB
                // Otherwise the following codes won't generate the correct number of push-in
                // This is only for the testbench to behave correctly, and does not affect the
                // correctness of IB.

            // Set RS_IB interface
            for (int is_idx = 0; is_idx < `IS_NUM; is_idx++) begin
                if (is_idx < item.inst_num) begin
                    vif.rs_ib_i[is_idx].valid   =   1'b0;
                    vif.rs_ib_i[is_idx].is_inst =   'b0;
                    case (item.inst_type[is_idx])
                        'd0 :   begin
                            if (vif.ib_rs_o.LOAD_ready) begin
                                vif.rs_ib_i[is_idx].valid           =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.rd_mem  =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.pc      =   pc;
                                pc  =   pc + 4;
                            end
                        end
                        'd1 :   begin
                            if (vif.ib_rs_o.STORE_ready) begin
                                vif.rs_ib_i[is_idx].valid           =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.wr_mem  =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.pc      =   pc;
                                pc  =   pc + 4;
                            end
                        end
                        'd2 :   begin
                            if (vif.ib_rs_o.BR_ready) begin
                                vif.rs_ib_i[is_idx].valid           =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.cond_br =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.pc      =   pc;
                                pc  =   pc + 4;
                            end

                        end
                        'd3 :   begin
                            if (vif.ib_rs_o.BR_ready) begin
                                vif.rs_ib_i[is_idx].valid               =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.uncond_br   =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.pc          =   pc;
                                pc  =   pc + 4;
                            end
                        end
                        'd4 :   begin
                            if (vif.ib_rs_o.ALU_ready) begin
                                vif.rs_ib_i[is_idx].valid       =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.alu =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.pc  =   pc;
                                pc  =   pc + 4;
                            end
                        end
                        'd6 :   begin
                            if (vif.ib_rs_o.MULT_ready) begin
                                vif.rs_ib_i[is_idx].valid           =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.mult    =   1'b1;
                                vif.rs_ib_i[is_idx].is_inst.pc      =   pc;
                                pc  =   pc + 4;
                            end
                        end
                    endcase
                end else begin
                    vif.rs_ib_i[is_idx] =   'b0;
                end
            end



            @(negedge vif.clk_i);
            vif.rs_ib_i     =   0;
            vif.fu_ib_i     =   0;
            vif.br_mis_i    =   0;
            vif.exception_i =   0;
            ->drv_done;
        end
    endtask // run()

endclass // driver
// ====================================================================
// Driver End
// ====================================================================

// ====================================================================
// Scoreboard Start
// ====================================================================
class scoreboard;
    mailbox     scb_mbx                     ;
    mon_item    ALU_push_in_queue     [$]   ;
    mon_item    ALU_pop_out_queue     [$]   ;
    mon_item    MULT_push_in_queue    [$]   ;
    mon_item    MULT_pop_out_queue    [$]   ;
    mon_item    BR_push_in_queue      [$]   ;
    mon_item    BR_pop_out_queue      [$]   ;
    mon_item    LOAD_push_in_queue    [$]   ;
    mon_item    LOAD_pop_out_queue    [$]   ;
    mon_item    STORE_push_in_queue   [$]   ;
    mon_item    STORE_pop_out_queue   [$]   ;
    string      inst_type                   ;
    int         check_idx                   ;
    task run();
        forever begin
            mon_item    item    ;
            // Get item from mailbox
            $display("T=%0t [Scoreboard] Waiting for item from Monitor ...", $time);
            scb_mbx.get(item);

            item.print("[Scoreboard]");

            if (item.is_inst.rd_mem) begin
                inst_type   =   "LOAD";
            end else if (item.is_inst.wr_mem) begin
                inst_type   =   "STORE";
            end else if (item.is_inst.cond_br) begin
                inst_type   =   "BR";
            end else if (item.is_inst.uncond_br) begin
                inst_type   =   "BR";
            end else if (item.is_inst.alu) begin
                inst_type   =   "ALU";
            end else if (item.is_inst.mult) begin
                inst_type   =   "MULT";
            end

            if (item.feature == "Push-In") begin
                case (inst_type)
                    "LOAD"  :   LOAD_push_in_queue.push_back(item);
                    "STORE" :   STORE_push_in_queue.push_back(item);
                    "BR"    :   BR_push_in_queue.push_back(item);
                    "BR"    :   BR_push_in_queue.push_back(item);
                    "ALU"   :   ALU_push_in_queue.push_back(item);
                    "MULT"  :   MULT_push_in_queue.push_back(item);
                endcase
            end else if (item.feature == "Pop-Out") begin
                case (inst_type)
                    "LOAD"  : begin
                        LOAD_pop_out_queue.push_back(item);
                        if (LOAD_push_in_queue[check_idx].is_inst != LOAD_pop_out_queue[check_idx].is_inst) begin
                            $display("T=%0t [Scoreboard] LOAD Pop-Out and Push-In instructions don't match", $time);
                            $display("T=%0t [Scoreboard] Error: Issued PC=%0d", 
                                    $time, item.is_inst.pc);
                            exit_on_error();
                        end
                    end
                    "STORE" : begin
                        STORE_pop_out_queue.push_back(item);
                        if (STORE_push_in_queue[check_idx].is_inst != STORE_pop_out_queue[check_idx].is_inst) begin
                            $display("T=%0t [Scoreboard] STORE Pop-Out and Push-In instructions don't match", $time);
                            $display("T=%0t [Scoreboard] Error: Issued PC=%0d", 
                                    $time, item.is_inst.pc);
                            exit_on_error();
                        end
                    end
                    "BR"    : begin
                        BR_pop_out_queue.push_back(item);
                        if (BR_push_in_queue[check_idx].is_inst != BR_pop_out_queue[check_idx].is_inst) begin
                            $display("T=%0t [Scoreboard] BR Pop-Out and Push-In instructions don't match", $time);
                            $display("T=%0t [Scoreboard] Error: Issued PC=%0d", 
                                    $time, item.is_inst.pc);
                            exit_on_error();
                        end
                    end
                    "ALU"   : begin
                        ALU_pop_out_queue.push_back(item);
                        if (ALU_push_in_queue[check_idx].is_inst != ALU_pop_out_queue[check_idx].is_inst) begin
                            $display("T=%0t [Scoreboard] ALU Pop-Out and Push-In instructions don't match", $time);
                            $display("T=%0t [Scoreboard] Error: Issued PC=%0d", 
                                    $time, item.is_inst.pc);
                            exit_on_error();
                        end
                    end
                    "MULT"  : begin
                        MULT_pop_out_queue.push_back(item);
                        if (MULT_push_in_queue[check_idx].is_inst != MULT_pop_out_queue[check_idx].is_inst) begin
                            $display("T=%0t [Scoreboard] MULT Pop-Out and Push-In instructions don't match", $time);
                            $display("T=%0t [Scoreboard] Error: Issued PC=%0d", 
                                    $time, item.is_inst.pc);
                            exit_on_error();
                        end
                    end
                endcase
            end
        end
    endtask // run()

    task exit_on_error;
        $display("@@FAILED");
        $finish;
    endtask // exit_on_error()

endclass //scoreboard
// ====================================================================
// Scoreboard End
// ====================================================================

// ====================================================================
// Monitor Start
// ====================================================================
class monitor;
    virtual IB_if   vif     ;
    mailbox         scb_mbx ;
    task run();
        $display("T=%0t [Monitor] starting ...", $time);
        forever begin
            @(posedge vif.clk_i);
            push_in();
            pop_out();
        end
    endtask // run()

    task push_in();
        for (int is_idx = 0; is_idx < `IS_NUM; is_idx++) begin
            if (vif.rs_ib_i[is_idx].valid == 1'b1) begin
                mon_item    item    =   new                         ;
                item.feature        =   "Push-In"                   ;
                item.is_channel     =   is_idx                      ;
                item.is_inst        =   vif.rs_ib_i[is_idx].is_inst ;
                scb_mbx.put(item);
                $display("T=%0t [Monitor] Push-In detected in channel %0d, PC=%0d",
                        $time, is_idx, item.is_inst.pc);
            end
        end
    endtask // push_in()

    task pop_out();
        for (int fu_idx = 0; fu_idx < `IS_NUM; fu_idx++) begin
            if (vif.ib_fu_o[fu_idx].valid == 1'b1) begin
                mon_item    item    =   new                         ;
                item.feature        =   "Pop-Out"                   ;
                item.is_channel     =   fu_idx                      ;
                item.is_inst        =   vif.ib_fu_o[fu_idx].is_inst ;
                scb_mbx.put(item);
                $display("T=%0t [Monitor] Pop-Out detected in channel %0d, PC=%0d",
                    $time, fu_idx, item.is_inst.pc);
            end
        end
    endtask // pop_out()
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

    virtual IB_if   vif         ;   // Virtual interface handle

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
interface IB_if (input bit clk_i);
    logic                       rst_i           ;
    IB_RS                       ib_rs_o         ;
    RS_IB   [`IS_NUM-1:0]       rs_ib_i         ;
    FU_IB   [`FU_NUM-1:0]       fu_ib_i         ;
    IB_FU   [`FU_NUM-1:0]       ib_fu_o         ;
    BR_MIS                      br_mis_i        ;
    logic                       exception_i     ;
endinterface // IB_if
// ====================================================================
// Interface End
// ====================================================================

// ====================================================================
// Testbench Start
// ====================================================================
module IB_tb;

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
    IB_if  _if(clk_i);

// --------------------------------------------------------------------
// DUT Instantiation
// --------------------------------------------------------------------
    IB  dut (
        .clk_i          (    clk_i          ),
        .rst_i          (_if.rst_i          ),
        .ib_rs_o        (_if.ib_rs_o        ),
        .rs_ib_i        (_if.rs_ib_i        ),
        .fu_ib_i        (_if.fu_ib_i        ),
        .ib_fu_o        (_if.ib_fu_o        ),
        .br_mis_i       (_if.br_mis_i       ),
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
        _if.rs_ib_i     =   0;
        _if.fu_ib_i     =   0;
        _if.br_mis_i    =   0;
        _if.exception_i =   0;
        $display("Start Test");
        // Apply reset and start stimulus
        #50 _if.rst_i   =   0;
        $display("reset = %0d", _if.rst_i);

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

endmodule // RS_tb

// ====================================================================
// Testbench End
// ====================================================================