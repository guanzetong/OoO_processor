// ====================================================================
// Transaction Object Start
// ====================================================================
class gen_item; // GEN -> DRV
    rand    logic   [`XLEN-1:0]     addr        ;
    rand    logic   [64-1:0]        data        ;
    rand    MEM_SIZE                size        ;
    rand    BUS_COMMAND             cmd         ;
    string                          size_str    ;
    string                          cmd_str     ;

    constraint addr_range {addr < 'd64;}

    function void print (string msg_tag="");
        case (cmd)
            BUS_NONE    :   cmd_str =   "BUS_NONE"  ;
            BUS_LOAD    :   cmd_str =   "BUS_LOAD"  ;
            BUS_STORE   :   cmd_str =   "BUS_STORE" ;
            default     :   cmd_str =   "BUS_NONE"  ;
        endcase
        case (size)
            BYTE    :   size_str    =   "BYTE"      ;
            HALF    :   size_str    =   "HALF"      ;
            WORD    :   size_str    =   "WORD"      ;
            DOUBLE  :   size_str    =   "DOUBLE"    ;
            default :   size_str    =   "BYTE"      ;
        endcase

        $display("T=%0t %s Generator cmd=%s, size=%s, addr=%0d, data=%0h",
                $time, msg_tag, cmd_str, size_str, addr, data);
    endfunction // print
endclass // gen_item

class mon_item; // MON -> SCB
    MEM_IN  proc2cache  ;
    MEM_OUT cache2proc  ;
    string  feature     ;

    function void print (string msg_tag="");
        case (feature)
            "OUTPUT": begin
                $display("T=%0t %s Memory Data Output, data=%0h, tag=%0d",
                $time, msg_tag, cache2proc.data, cache2proc.tag);
            end
            "LOAD": begin
                $display("T=%0t %s Memory Load Request, addr=%0d, size=%0d, response=%0d",
                $time, msg_tag, proc2cache.addr, proc2cache.size, cache2proc.response);
            end
            "STORE": begin
                $display("T=%0t %s Memory Store Request, addr=%0d, size=%0d, data=%0h, response=%0d",
                $time, msg_tag, proc2cache.addr, proc2cache.size, proc2cache.data, cache2proc.response);
            end
            "ERROR": begin
                $display("T=%0t %s ERROR!!, addr=%0d, size=%0d, data=%0h, response=%0d",
                $time, msg_tag, proc2cache.addr, proc2cache.size, proc2cache.data, cache2proc.response);
            end
        endcase
    endfunction
endclass

// ====================================================================
// Transaction Object End
// ====================================================================

// ====================================================================
// Driver Start
// ====================================================================
class driver;
    virtual cache_if    vif             ;
    event               drv_done        ;
    mailbox             drv_mbx         ;

    task run();
        $display("T=%0t [Driver] starting ...", $time);
        @(negedge vif.clk_i);

        forever begin
            gen_item    item;

            $display("T=%0t [Driver] waiting for item from Generator ...", $time);
            drv_mbx.get(item);

            item.print("[Driver]");

            vif.proc2cache_i.command    =   item.cmd    ;
            if (vif.proc2cache_i.command != BUS_NONE) begin
                vif.proc2cache_i.size   =   item.size   ;
                case (item.size)
                    BYTE    :   begin
                        vif.proc2cache_i.addr   =   item.addr   ;
                        vif.proc2cache_i.data   =   {56'b0, item.data[8-1:0]};
                    end
                    HALF    :   begin
                        vif.proc2cache_i.addr   =   {item.addr[`XLEN-1:1], 1'b0};
                        vif.proc2cache_i.data   =   {48'b0, item.data[16-1:0]};
                    end
                    WORD    :   begin
                        vif.proc2cache_i.addr   =   {item.addr[`XLEN-1:2], 2'b0};
                        vif.proc2cache_i.data   =   {32'b0, item.data[32-1:0]};
                    end
                    DOUBLE  :   begin
                        vif.proc2cache_i.addr   =   {item.addr[`XLEN-1:3], 3'b0};
                        vif.proc2cache_i.data   =   item.data;
                    end
                    default :   begin
                        vif.proc2cache_i.addr   =   item.addr   ;
                        vif.proc2cache_i.data   =   item.data   ;
                    end
                endcase
            end
            $display("T=%0t [Driver] Actrual drive: cmd=%0d, addr=%0d, data=%0h", 
            $time, vif.proc2cache_i.command, vif.proc2cache_i.addr, vif.proc2cache_i.data);

            // When transfer is over, raise the done event and reset the inputs
            @(negedge vif.clk_i);
            vif.proc2cache_i  =   'd0;
            ->drv_done;
        end

    endtask
endclass
// ====================================================================
// Driver End
// ====================================================================

// ====================================================================
// Scoreboard Start
// ====================================================================
class scoreboard;
    mailbox                         scb_mbx ;

    typedef struct packed {
        logic   [`XLEN-1:0]                 addr        ;
        logic   [64-1:0]                    ref_data    ;
        logic   [64-1:0]                    real_data   ;
        logic   [`MSHR_IDX_WIDTH-1:0]       tag         ;
        logic                               complete    ;
    } SCB_LOAD_QUEUE;

    logic   [64-1:0]    ref_memory  [`MEM_64BIT_LINES-1:0]  ;
    SCB_LOAD_QUEUE      load_queue  [$]                     ;
    SCB_LOAD_QUEUE      load_item                           ;
    logic               match_flag                          ;
    int                 match_idx                           ;

    task run();
        for (int unsigned double_addr = 0; double_addr < `MEM_64BIT_LINES; double_addr++) begin
            ref_memory[double_addr] =   64'b0;
        end

        forever begin
            mon_item    item    ;
            // Get item from mailbox
            $display("T=%0t [Scoreboard] Waiting for item from Monitor ...", $time);
            scb_mbx.get(item);

            item.print("[Scoreboard]");

            case (item.feature)
                "OUTPUT"    :   begin
                    match_flag  =   1'b0;
                    match_idx   =   0   ;
                    for (int unsigned i = 0; i < load_queue.size; i++) begin
                        if (load_queue[i].complete == 1'b0 
                        &&  load_queue[i].tag == item.cache2proc.tag) begin
                            load_queue[i].complete  =   1'b1                ;
                            load_queue[i].real_data =   item.cache2proc.data;
                            match_flag              =   1'b1                ;
                            match_idx               =   i                   ;
                            break;
                        end
                    end
                    if (match_flag == 1'b0) begin
                        $display("T=%0t [Scoreboard] Returned tag doesn't match any previous load, tag=%0d, data=%0h",
                        $time, item.cache2proc.tag, item.cache2proc.data);
                        exit_on_error();
                    end else if (load_queue[match_idx].ref_data != load_queue[match_idx].real_data) begin
                        $display("T=%0t [Scoreboard] Returned data doesn't match with reference, addr=%0d, ref_data=%0h, real_data=%0d, tag=%0d",
                        $time, load_queue[match_idx].addr, load_queue[match_idx].ref_data, load_queue[match_idx].real_data, load_queue[match_idx].tag);
                        exit_on_error();
                    end else begin
                        $display("T=%0t [Scoreboard] Load #%0d completed, addr=%0d, ref_data=%0h, real_data=%0d, tag=%0d",
                        $time, match_idx, load_queue[match_idx].addr, load_queue[match_idx].ref_data, load_queue[match_idx].real_data, load_queue[match_idx].tag);
                    end
                end
                "LOAD"      :   begin
                    load_item.addr  =   item.proc2cache.addr;
                    case (item.proc2cache.size)
                        BYTE    :   load_item.ref_data  =   {56'b0, ref_memory[load_item.addr[`XLEN-1:3]][load_item.addr[2:0]+: 8]};
                        HALF    :   load_item.ref_data  =   {48'b0, ref_memory[load_item.addr[`XLEN-1:3]][load_item.addr[2:0]+:16]};
                        WORD    :   load_item.ref_data  =   {32'b0, ref_memory[load_item.addr[`XLEN-1:3]][load_item.addr[2:0]+:32]};
                        DOUBLE  :   load_item.ref_data  =   ref_memory[load_item.addr[`XLEN-1:3]];
                    endcase
                    load_item.real_data =   'b0                     ;
                    load_item.tag       =   item.cache2proc.response;
                    load_item.complete  =   1'b0                    ;
                    load_queue.push_back(load_item)                 ;
                    $display("T=%0t [Scoreboard] ref_data=%0h", $time, load_item.ref_data);
                end
                "STORE"     :   begin
                    case (item.proc2cache.size)
                        BYTE    :   ref_memory[item.proc2cache.addr[`XLEN-1:3]][item.proc2cache.addr[2:0]+: 8]  =   item.proc2cache.data[ 8-1:0];
                        HALF    :   ref_memory[item.proc2cache.addr[`XLEN-1:3]][item.proc2cache.addr[2:0]+:16]  =   item.proc2cache.data[16-1:0];
                        WORD    :   ref_memory[item.proc2cache.addr[`XLEN-1:3]][item.proc2cache.addr[2:0]+:32]  =   item.proc2cache.data[32-1:0];
                        DOUBLE  :   ref_memory[item.proc2cache.addr[`XLEN-1:3]]                                 =   item.proc2cache.data        ;
                    endcase
                end
                default     :   begin
                    $display("T=%0t [Scoreboard] Interface Error Detected",
                    $time);
                    exit_on_error();
                end
            endcase
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
    virtual cache_if    vif     ;
    mailbox             scb_mbx ;

    task run();
        $display("T=%0t [Monitor] starting ...", $time);
        forever begin
            @(posedge vif.clk_i);
            if (vif.cache2proc_o.response != 'd0) begin
                mon_item    item    =   new;
                item.proc2cache.addr        =   vif.proc2cache_i.addr       ;
                item.proc2cache.data        =   vif.proc2cache_i.data       ;
                item.proc2cache.size        =   vif.proc2cache_i.size       ;
                item.proc2cache.command     =   vif.proc2cache_i.command    ;
                item.cache2proc.response    =   vif.cache2proc_o.response   ;
                item.cache2proc.data        =   vif.cache2proc_o.data       ;
                item.cache2proc.tag         =   vif.cache2proc_o.tag        ;
                if (vif.proc2cache_i.command == BUS_LOAD) begin
                    item.feature    =   "LOAD";
                end else if (vif.proc2cache_i.command == BUS_STORE) begin
                    item.feature    =   "STORE";
                end else begin
                    item.feature    =   "ERROR";
                end
                scb_mbx.put(item);
                $display("T=%0t [Monitor] %s detected , addr=%0d, size=%0d, data=%0h, response=%0d",
                $time, item.feature, item.proc2cache.addr, item.proc2cache.size, item.proc2cache.data, item.cache2proc.response);
            end
            
            if (vif.cache2proc_o.tag != 'd0) begin
                mon_item    item    =   new;
                item.proc2cache.addr        =   vif.proc2cache_i.addr       ;
                item.proc2cache.data        =   vif.proc2cache_i.data       ;
                item.proc2cache.size        =   vif.proc2cache_i.size       ;
                item.proc2cache.command     =   vif.proc2cache_i.command    ;
                item.cache2proc.response    =   vif.cache2proc_o.response   ;
                item.cache2proc.data        =   vif.cache2proc_o.data       ;
                item.cache2proc.tag         =   vif.cache2proc_o.tag        ;
                item.feature                =   "OUTPUT"                    ;
                scb_mbx.put(item);
                $display("T=%0t [Monitor] %s detected , data=%0h, tag=%0d",
                $time, item.feature, item.cache2proc.data, item.cache2proc.tag);
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
    driver              d0          ;   // driver     handle
    monitor             m0          ;   // monitor    handle
    generator           g0          ;   // generator  handle
    scoreboard          s0          ;   // scoreboard handle

    mailbox             drv_mbx     ;   // Connect generator  <-> driver
    mailbox             scb_mbx     ;   // Connect monitor    <-> scoreboard
    event               drv_done    ;   // Indicates when driver is done

    virtual cache_if    vif         ;   // Virtual interface handle

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
interface cache_if (input bit clk_i);
    logic       rst_i           ;
    MEM_IN      proc2cache_i    ;
    MEM_OUT     cache2proc_o    ;
    MEM_IN      cache2mem_o     ;
    MEM_OUT     mem2cache_i     ;
endinterface // cache_if
// ====================================================================
// Interface End
// ====================================================================

// ====================================================================
// Testbench Start
// ====================================================================
module cache_tb;

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
    cache_if    _if     (clk_i);

// --------------------------------------------------------------------
// DUT Instantiation
// --------------------------------------------------------------------
    cache dut (
        .clk_i          (    clk_i          ),
        .rst_i          (_if.rst_i          ),
        .proc2cache_i   (_if.proc2cache_i   ),
        .cache2proc_o   (_if.cache2proc_o   ),
        .cache2mem_o    (_if.cache2mem_o    ),
        .mem2cache_i    (_if.mem2cache_i    )
    );

    // Instantiate the Data Memory
    mem mem_inst (
        // Inputs
        .clk               (    clk_i                   ),
        .proc2mem_command  (_if.cache2mem_o.command     ),
        .proc2mem_addr     (_if.cache2mem_o.addr        ),
        .proc2mem_data     (_if.cache2mem_o.data        ),
`ifndef CACHE_MODE
        .proc2mem_size     (_if.cache2mem_o.size        ),
`endif
        // Outputs
        .mem2proc_response (_if.mem2cache_i.response    ),
        .mem2proc_data     (_if.mem2cache_i.data        ),
        .mem2proc_tag      (_if.mem2cache_i.tag         )
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
        _if.rst_i           =   'd1 ;
        _if.proc2cache_i    =   'd0 ;

        for (int unsigned double_addr = 0; double_addr < `MEM_64BIT_LINES; double_addr++) begin
            mem_inst.unified_memory[double_addr]    =   64'b0;
        end
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

endmodule // cache_tb

// ====================================================================
// Testbench End
// ====================================================================