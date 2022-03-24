`timescale 1ns/100ps

function automatic int min_int (
    input int inta, intb
);
    if (inta < intb) begin
        min_int =   inta;
    end else begin
        min_int =   intb;
    end
endfunction

// ====================================================================
// Transaction Object Start
// ====================================================================
class gen_item; // GEN -> DRV
    rand int                dp_num          ;
    rand int                cp_num          ;
    rand int                br_mis_valid    ;
    rand int                br_mis_thread   ;
    rand logic  [5-1:0]     ib_ready        ;

    constraint dp_num_range {dp_num >= 0; dp_num <= `DP_NUM;}
    constraint cp_num_range {cp_num >= 0; cp_num <= `CDB_NUM;}
    constraint br_mis_rate {br_mis_valid dist{0:=95, 1:=5};}
    constraint br_mis_thread_range {br_mis_thread >= 0; br_mis_thread < `THREAD_NUM;}

    function void print (string msg_tag="");
        $display("T=%0t %s Generator requests #Dispatch=%0d, #Complete=%0d, Branch Misprediction=%0b in Thread=%0d",
                $time, msg_tag, dp_num, cp_num, br_mis_valid, br_mis_thread);
    endfunction // print
endclass // gen_item

class mon_item; // MON -> SCB
    string      feature     ;
    int         dp_channel  ;
    DEC_INST    dp_inst     ;
    int         cdb_channel ;
    CDB         cdb         ;
    int         is_channel  ;
    IS_INST     is_inst     ;

    function void print (string msg_tag="");
        case (feature)
            "dispatch": begin
                $display("T=%0t %s %s in channel %0d, PC=%0d",
                $time, msg_tag, feature, dp_channel, dp_inst.pc);
            end
            "complete": begin
                $display("T=%0t %s %s in channel %0d, tag=%0d",
                $time, msg_tag, feature, cdb_channel, cdb.tag);
            end
            "issue": begin
                $display("T=%0t %s %s in channel %0d, PC=%0d",
                $time, msg_tag, feature, is_channel, is_inst.pc);
            end
            default: begin
                $display("T=%0t %s %s",
                $time, msg_tag, feature);
            end
        endcase
        $display("T=%0t %s %s ",
                $time, msg_tag, feature);
    endfunction
endclass

// ====================================================================
// Transaction Object End
// ====================================================================

// ====================================================================
// Driver Start
// ====================================================================
class driver;
    virtual RS_if                                   vif             ;
    event                                           drv_done        ;
    mailbox                                         drv_mbx         ;
    IS_INST                                         issue_queue [$] ;
    logic   [`ARCH_REG_NUM-1:0][`TAG_IDX_WIDTH:0]   map_table       ;
    logic   [`TAG_IDX_WIDTH:0]                      free_list   [$] ;
    ROB_ENTRY                                       rob         [$] ;
    logic   [`XLEN-1:0]                             prf             ;
    int                                             rob_avail_num   ;
    int                                             fl_avail_num    ;
    int                                             pc              ;

    task run();
        $display("T=%0t [Driver] starting ...", $time);
        init();
        @(negedge vif.clk_i);

        forever begin
            gen_item    item;

            $display("T=%0t [Driver] waiting for item from Generator ...", $time);
            drv_mbx.get(item);

            item.print("[Driver]");

            // Set IB_RS interface
            vif.ib_rs_i =   item.ib_ready;
            $display("T=%0t [Driver] IB status: ALU=%0b, MULT=%0b, BR=%0b, LOAD=%0b, STORE=%0b",
                    $time, vif.ib_rs_i.ALU_ready, vif.ib_rs_i.MULT_ready, vif.ib_rs_i.BR_ready, 
                    vif.ib_rs_i.LOAD_ready, vif.ib_rs_i.STORE_ready);
            // Set DP, CDB, PRF interface
            retire();
            complete(item.cp_num);
            issue();
            dispatch(item.dp_num);

            // When transfer is over, raise the done event and reset the inputs
            @(negedge vif.clk_i);
            vif.dp_rs_i     =   0;
            vif.cdb_i       =   0;
            vif.ib_rs_i     =   0;
            vif.prf_rs_i    =   0;
            vif.br_mis_i    =   0;
            vif.exception_i =   0;
            ->drv_done;
        end

    endtask

    task init();
        // Initialize Map Table
        for (int i = 0; i < `ARCH_REG_NUM; i++) begin
            map_table[i][`TAG_IDX_WIDTH]        =   1'b1;   // Ready bit of each entry
            map_table[i][`TAG_IDX_WIDTH-1:0]    =   i;      // PR#
        end
        // Initialize Free List
        for (int i = `ARCH_REG_NUM; i < `PHY_REG_NUM; i++) begin
            free_list.push_back(i);
        end
        // Initialize PC
        pc = 0;
        // Initialize Physical Register File
        for (int i = 0; i < `PHY_REG_NUM; i++) begin
            prf[i]  =   i;
        end
    endtask

    task dispatch(int dp_num);
        int         dp_valid_num    ;
        ROB_ENTRY   rob_entry       ;
        int         inst_type       ;
        int         min_rob_fl      ;
        int         min_cp_rs       ;
        begin
            // Derive the number of valid dispatch
            rob_avail_num   =   `ROB_ENTRY_NUM - rob.size();
            fl_avail_num    =   free_list.size();
            min_rob_fl      =   min_int(rob_avail_num, fl_avail_num);
            min_cp_rs       =   min_int(dp_num, vif.rs_dp_o.avail_num);
            dp_valid_num    =   min_int(min_rob_fl, min_cp_rs);
            // Assign value to interface
            vif.dp_rs_i.dp_num  =   dp_valid_num;
            for (int n = 0; n < `DP_NUM; n++) begin
                if (n < dp_valid_num) begin
                    inst_type   =   $urandom % 6;
                    // Allocate RS entry
                    case (inst_type)
                        'd0 : vif.dp_rs_i.dec_inst[n].alu       =   1'b1;
                        'd1 : vif.dp_rs_i.dec_inst[n].mult      =   1'b1;
                        'd2 : vif.dp_rs_i.dec_inst[n].cond_br   =   1'b1;
                        'd3 : vif.dp_rs_i.dec_inst[n].uncond_br =   1'b1;
                        'd4 : vif.dp_rs_i.dec_inst[n].rd_mem    =   1'b1;
                        'd5 : vif.dp_rs_i.dec_inst[n].wr_mem    =   1'b1;
                    endcase
                    vif.dp_rs_i.dec_inst[n].pc          =   pc;
                    vif.dp_rs_i.dec_inst[n].inst.r.rd   =   $urandom % `ARCH_REG_NUM;
                    vif.dp_rs_i.dec_inst[n].inst.r.rs1  =   $urandom % `ARCH_REG_NUM;
                    vif.dp_rs_i.dec_inst[n].inst.r.rs2  =   $urandom % `ARCH_REG_NUM;
                    vif.dp_rs_i.dec_inst[n].tag         =   free_list.pop_front();  // Allocate FL entry
                    vif.dp_rs_i.dec_inst[n].tag1        =   map_table[vif.dp_rs_i.dec_inst[n].inst.r.rs1][`TAG_IDX_WIDTH-1:0];
                    vif.dp_rs_i.dec_inst[n].tag1_ready  =   map_table[vif.dp_rs_i.dec_inst[n].inst.r.rs1][`TAG_IDX_WIDTH];
                    vif.dp_rs_i.dec_inst[n].tag2        =   map_table[vif.dp_rs_i.dec_inst[n].inst.r.rs2][`TAG_IDX_WIDTH-1:0];
                    vif.dp_rs_i.dec_inst[n].tag2_ready  =   map_table[vif.dp_rs_i.dec_inst[n].inst.r.rs2][`TAG_IDX_WIDTH];
                    $display("T=%0t [Driver] Dispatch in channel%0d, PC=%0h, rd= %0d, rs1=%0d, rs2=%0d, tag=%0b, tag1=%0d|%0d, tag2=%0d|%0d",
                    $time, n, pc, vif.dp_rs_i.dec_inst[n].inst.r.rd, vif.dp_rs_i.dec_inst[n].inst.r.rs1, vif.dp_rs_i.dec_inst[n].inst.r.rs2,
                    vif.dp_rs_i.dec_inst[n].tag, vif.dp_rs_i.dec_inst[n].tag1, vif.dp_rs_i.dec_inst[n].tag1_ready,
                    vif.dp_rs_i.dec_inst[n].tag2, vif.dp_rs_i.dec_inst[n].tag2_ready);
                    // Allocate ROB entry
                    rob_entry.valid         =   1'b1;
                    rob_entry.pc            =   pc;
                    rob_entry.rd            =   vif.dp_rs_i.dec_inst[n].inst.r.rd;
                    rob_entry.tag_old       =   map_table[rob_entry.rd][`TAG_IDX_WIDTH-1:0];
                    rob_entry.tag           =   vif.dp_rs_i.dec_inst[n].tag;
                    rob_entry.br_predict    =   1'b0;
                    rob_entry.br_result     =   1'b0;
                    rob_entry.complete      =   1'b0;
                    rob.push_back(rob_entry);
                    // Update Map Table
                    map_table[vif.dp_rs_i.dec_inst[n].inst.r.rd]  =   {1'b0, vif.dp_rs_i.dec_inst[n].tag};
                    // Increment PC
                    pc = pc + 4;
                end else begin
                    vif.dp_rs_i.dec_inst[n] =   'b0;
                end
            end
        end
    endtask // dispatch

    task complete(int cp_num);
        int                     queue_size      ;   // size of issue_queue
        int                     queue_idx       ;   // selected queue entry index to complete
        int                     cdb_valid_num   ;   // number of asserted CDB.valid
        IS_INST [`CDB_NUM-1:0]  cp_inst         ;   // selected instruction to complete
        begin
            queue_size      =   issue_queue.size();
            cdb_valid_num   =   min_int(queue_size, cp_num);
            $display("T=%0t [Driver] #issued=%0d, #requested complete=%0d, #actual complete=%0d",
                    $time, queue_size, cp_num, cdb_valid_num);
            for (int n = 0; n < cdb_valid_num; n++) begin
                queue_size  =   issue_queue.size();
                queue_idx   =   $urandom % queue_size;
                cp_inst[n]  =   issue_queue[queue_idx];
                issue_queue.delete(queue_idx);
            end
            // Assign the CDB action to cdb_i
            for (int n = 0; n < `CDB_NUM; n++) begin
                if (n < cdb_valid_num) begin
                    // CBD
                    vif.cdb_i[n].valid      =   1'b1;
                    vif.cdb_i[n].rob_idx    =   cp_inst[n].rob_idx;
                    vif.cdb_i[n].tag        =   cp_inst[n].tag;
                    vif.cdb_i[n].thread_idx =   cp_inst[n].thread_idx;
                    vif.cdb_i[n].br_result  =   1'b0;
                    $display("T=%0t [Driver] Complete in channel%0d, tag=%0d, thread=%0d",
                    $time, n, vif.cdb_i[n].tag, vif.cdb_i[n].thread_idx);
                    // Set ROB complete bit
                    for (int m = 0; m < rob.size(); m++) begin
                        if (rob[m].tag == vif.cdb_i[n].tag) begin
                            rob[m].complete =   1'b1;
                        end
                    end
                end else begin
                    vif.cdb_i[n]    =   'b0;
                end
            end
        end
    endtask // complete()

    task issue();
        for (int is_idx = 0; is_idx < `IS_NUM; is_idx++) begin
            vif.prf_rs_i[is_idx].data_out1  =   prf[vif.rs_prf_o[is_idx].rd_addr1];
            vif.prf_rs_i[is_idx].data_out2  =   prf[vif.rs_prf_o[is_idx].rd_addr2];
            if (vif.rs_ib_o[is_idx].valid) begin
                issue_queue.push_back(vif.rs_ib_o[is_idx].is_inst);
            end
        end
    endtask // issue()

    task retire();
        int     rt_num  ;
        if (rob.size() > 0) begin
            while(1) begin
                if (rob[0].complete == 1'b0) begin
                    break;
                end else begin
                    free_list.push_back(rob[0].tag_old);
                    rob.pop_front();
                    rt_num++;
                    if (rt_num == `RT_NUM) begin
                        break;
                    end
                end
            end
        end
    endtask // retire()

endclass
// ====================================================================
// Driver End
// ====================================================================

// ====================================================================
// Scoreboard Start
// ====================================================================
class scoreboard;
    mailbox     scb_mbx ;
    mon_item    dp_queue    [$] ;
    mon_item    cp_queue    [$] ;
    mon_item    is_queue    [$] ;

    task run();
        forever begin
            mon_item    item    ;
            // Get item from mailbox
            $display("T=%0t [Scoreboard] waiting for item from Monitor ...", $time);
            scb_mbx.get(item);

            item.print("[Scoreboard]");

            // Push into a queue according to the "feature"
            case (item.feature)
                "dispatch"  :   dp_queue.push_back(item);
                "complete"  :   cp_queue.push_back(item);
                "issue"     :   is_queue.push_back(item); 
            endcase

            if (item.feature == "complete") begin
                for (int i = 0; i < dp_queue.size(); i++) begin
                    if (item.cdb.tag == dp_queue[i].dp_inst.tag1) begin
                        dp_queue[i].dp_inst.tag1_ready  =   1'b1;
                    end
                    if (item.cdb.tag == dp_queue[i].dp_inst.tag2) begin
                        dp_queue[i].dp_inst.tag2_ready  =   1'b1;
                    end
                end
            end

            if (item.feature == "issue") begin
                int     pc_match_flag   =   0;
                int     inst_ready_flag =   0;
                int     match_idx       =   0;
                for (int i = 0; i < dp_queue.size(); i++) begin
                    if (dp_queue[i].dp_inst.pc == item.is_inst.pc) begin
                        pc_match_flag   =   1;
                        match_idx       =   i;
                        if (dp_queue[i].dp_inst.tag1_ready && dp_queue[i].dp_inst.tag2_ready) begin
                            inst_ready_flag  =   1;
                        end
                        break;
                    end
                end
                if (pc_match_flag == 0) begin
                    $display("T=%0t [Scoreboard] Issued instruction is not dispatched", $time);
                    $display("T=%0t [Scoreboard] Error: Issued PC=%0d", 
                            $time, item.is_inst.pc);
                    exit_on_error();
                end else if (inst_ready_flag == 0) begin
                    $display("T=%0t [Scoreboard] Issued instruction is dispatched but not ready", $time);
                    $display("T=%0t [Scoreboard] Error: Issued/Dispatched PC=%0d, tag1 = %0d|%0d, tag2 = %0d|%0d",
                            $time, item.is_inst.pc, dp_queue[match_idx].dp_inst.tag1, dp_queue[match_idx].dp_inst.tag1_ready,
                            dp_queue[match_idx].dp_inst.tag2, dp_queue[match_idx].dp_inst.tag2_ready);
                    exit_on_error();
                end
            end
        end
    endtask

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
    virtual RS_if   vif     ;
    mailbox         scb_mbx ;

    task run();
        $display("T=%0t [Monitor] starting ...", $time);
        forever begin
            @(posedge vif.clk_i);
            dispatch();
            complete();
            issue();
        end
    endtask

    task dispatch();
        // Check dispatch
        for (int i = 0; i < vif.dp_rs_i.dp_num; i++) begin
            mon_item    item    ;
            item.feature    =   "dispatch";
            item.dp_inst    =   vif.dp_rs_i.dec_inst[i];
            item.dp_channel =   i;
            scb_mbx.put(item);
            $display("T=%0t [Monitor] Dispatch detected in channel %0d",
                    $time, i);
        end
    endtask

    task complete();
        for (int i = 0; i < `CDB_NUM; i++) begin
            if (vif.cdb_i[i].valid) begin
                mon_item    item    ;
                item.feature        =   "complete";
                item.cdb            =   vif.cdb_i[i];
                item.cdb_channel    =   i;
                scb_mbx.put(item);
                $display("T=%0t [Monitor] Complete detected in channel %0d",
                        $time, i);
            end
        end
    endtask

    task issue();
        for (int i = 0; i < `IS_NUM; i++) begin
            if (vif.rs_ib_o[i].valid) begin
                mon_item    item    ;
                item.feature    =   "issue";
                item.is_inst    =   vif.rs_ib_o[i].is_inst;
                item.is_channel =   i;
                scb_mbx.put(item);
                $display("T=%0t [Monitor] Issue detected in channel %0d",
                        $time, i);
            end
        end
    endtask
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

    virtual RS_if   vif         ;   // Virtual interface handle

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
interface RS_if (input bit clk_i);
    logic                       rst_i       ;
    RS_DP                       rs_dp_o     ;
    DP_RS                       dp_rs_i     ;
    CDB     [`CDB_NUM-1:0]      cdb_i       ;
    RS_IB   [`IS_NUM-1:0]       rs_ib_o     ;
    IB_RS                       ib_rs_i     ;
    RS_PRF  [`IS_NUM-1:0]       rs_prf_o    ;
    PRF_RS  [`IS_NUM-1:0]       prf_rs_i    ;
    BR_MIS                      br_mis_i    ;
    logic                       exception_i ;
endinterface // ROB_if
// ====================================================================
// Interface End
// ====================================================================

// ====================================================================
// Testbench Start
// ====================================================================
module RS_tb;

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
    RS_if  _if(clk_i);

// --------------------------------------------------------------------
// DUT Instantiation
// --------------------------------------------------------------------
    RS dut (
        .clk_i          (    clk_i          ),
        .rst_i          (_if.rst_i          ),
        .rs_dp_o        (_if.rs_dp_o        ),
        .dp_rs_i        (_if.dp_rs_i        ),
        .cdb_i          (_if.cdb_i          ),
        .rs_ib_o        (_if.rs_ib_o        ),
        .ib_rs_i        (_if.ib_rs_i        ),
        .rs_prf_o       (_if.rs_prf_o       ),
        .prf_rs_i       (_if.prf_rs_i       ),
        .br_mis_i       (_if.br_mis_i       ),
        .exception_i    (_if.exception_i    )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Test Instantiation
// --------------------------------------------------------------------
    // test    t0;

// --------------------------------------------------------------------
// Call test
// --------------------------------------------------------------------
    initial begin
        _if.rst_i       =   1;
        _if.dp_rs_i     =   0;
        _if.cdb_i       =   0;
        _if.ib_rs_i     =   0;
        _if.prf_rs_i    =   0;
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

endmodule // ROB_tb

// ====================================================================
// Testbench End
// ====================================================================