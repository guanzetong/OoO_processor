function automatic string cmd_str_conv(input BUS_COMMAND cmd);
    begin
        case (cmd)
            BUS_NONE    :   cmd_str_conv    =   "BUS_NONE " ;
            BUS_LOAD    :   cmd_str_conv    =   "BUS_LOAD " ;
            BUS_STORE   :   cmd_str_conv    =   "BUS_STORE" ;
            default     :   cmd_str_conv    =   "ERROR    " ;
        endcase
    end
endfunction

function automatic string size_str_conv(input MEM_SIZE size);
    begin
        case (size)
            BYTE    :   size_str_conv   =   "BYTE  "    ;
            HALF    :   size_str_conv   =   "HALF  "    ;
            WORD    :   size_str_conv   =   "WORD  "    ;
            DOUBLE  :   size_str_conv   =   "DOUBLE"    ;
            default :   size_str_conv   =   "ERROR "    ;
        endcase
    end
endfunction

function automatic string mshr_state_str_conv(input MSHR_STATE state);
    begin
        case (state)
            ST_IDLE         :   mshr_state_str_conv =   "ST_IDLE       ";
            ST_WAIT_DEPEND  :   mshr_state_str_conv =   "ST_WAIT_DEPEND";
            ST_WAIT_EVICT   :   mshr_state_str_conv =   "ST_WAIT_EVICT ";
            ST_RD_MEM       :   mshr_state_str_conv =   "ST_RD_MEM     ";
            ST_WAIT_MEM     :   mshr_state_str_conv =   "ST_WAIT_MEM   ";
            ST_UPDATE       :   mshr_state_str_conv =   "ST_UPDATE     ";
            ST_OUTPUT       :   mshr_state_str_conv =   "ST_OUTPUT     ";
            ST_EVICT        :   mshr_state_str_conv =   "ST_EVICT      ";
            default         :   mshr_state_str_conv =   "ERROR         ";
        endcase
    end
endfunction

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

    constraint addr_range {addr < `MEM_SIZE_IN_BYTES;}
    // constraint addr_range {addr < 64;}

    function void print (string msg_tag="");
        cmd_str     =   cmd_str_conv(cmd);
        size_str    =   size_str_conv(size);
        $display("T=%0t %s Generator cmd=%s, size=%s, addr=%8h, data=%16h",
                $time, msg_tag, cmd_str, size_str, addr, data);
    endfunction // print
endclass // gen_item

class mon_item; // MON -> SCB
    MEM_IN  mem_in  ;
    MEM_OUT mem_out  ;
    MEM_IN  cache2mem   ;
    MEM_OUT mem2cache   ;
    string  feature     ;

    function void print (string msg_tag="");
        string  size_str    ;
        size_str    =   size_str_conv(mem_in.size);
        case (feature)
            "CACHE_OUTPUT": begin
                $display("T=%0t %s Cache Launch Data Output to Processor, data=%16h, tag=%0d",
                $time, msg_tag, mem_out.data, mem_out.tag);
            end
            "PROC_LOAD": begin
                $display("T=%0t %s Processor Launch Load Request to Cache, addr=%8h, size=%s, response=%0d",
                $time, msg_tag, mem_in.addr, size_str, mem_out.response);
            end
            "PROC_STORE": begin
                $display("T=%0t %s Processor Launch Store Request to Cache, addr=%8h, size=%s, data=%16h, response=%0d",
                $time, msg_tag, mem_in.addr, size_str, mem_in.data, mem_out.response);
            end
            "CACHE_LOAD": begin
                $display("T=%0t %s Cache Launch Load Request to Memory, addr=%8h, size=%s, response=%0d",
                $time, msg_tag, mem_in.addr, size_str, mem_out.response);
            end
            "CACHE_STORE": begin
                $display("T=%0t %s Cache Launch Store Request to Memory, addr=%8h, size=%s, data=%16h, response=%0d",
                $time, msg_tag, mem_in.addr, size_str, mem_in.data, mem_out.response);
            end
            "MEM_OUTPUT": begin
                $display("T=%0t %s Memory Launch Data Output to Cache, data=%16h, tag=%0d",
                $time, msg_tag, mem_out.data, mem_out.tag);
            end
            "ERROR": begin
                $display("T=%0t %s ERROR!!, addr=%8h, size=%s, data=%16h, response=%0d",
                $time, msg_tag, mem_in.addr, size_str, mem_in.data, mem_out.response);
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
    string              cmd_str         ;
    string              size_str        ;

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
            cmd_str     =   cmd_str_conv(vif.proc2cache_i.command);
            size_str    =   size_str_conv(vif.proc2cache_i.size);
            $display("T=%0t [Driver] Actual drive: cmd=%s, size=%s, addr=%8h, data=%16h", 
            $time, cmd_str, size_str, vif.proc2cache_i.addr, vif.proc2cache_i.data);

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
    SCB_LOAD_QUEUE      proc2cache_load_queue   [$]         ;
    SCB_LOAD_QUEUE      cache2mem_load_queue    [$]         ;
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
                "CACHE_OUTPUT"    :   begin
                    match_flag  =   1'b0;
                    match_idx   =   0   ;
                    for (int unsigned i = 0; i < proc2cache_load_queue.size(); i++) begin
                        if (proc2cache_load_queue[i].complete == 1'b0 
                        &&  proc2cache_load_queue[i].tag == item.mem_out.tag) begin
                            proc2cache_load_queue[i].complete  =   1'b1                ;
                            proc2cache_load_queue[i].real_data =   item.mem_out.data;
                            match_flag              =   1'b1                ;
                            match_idx               =   i                   ;
                            break;
                        end
                    end
                    if (match_flag == 1'b0) begin
                        $display("T=%0t [Scoreboard] Returned tag doesn't match any previous load, tag=%0d, data=%16h",
                        $time, item.mem_out.tag, item.mem_out.data);
                        exit_on_error();
                    end else if (proc2cache_load_queue[match_idx].ref_data != proc2cache_load_queue[match_idx].real_data) begin
                        $display("T=%0t [Scoreboard] Returned data doesn't match with reference, addr=%8h, ref_data=%16h, real_data=%16h, tag=%0d",
                        $time, proc2cache_load_queue[match_idx].addr, proc2cache_load_queue[match_idx].ref_data, proc2cache_load_queue[match_idx].real_data, proc2cache_load_queue[match_idx].tag);
                        exit_on_error();
                    end else begin
                        $display("T=%0t [Scoreboard] PROC_LOAD #%0d completed, addr=%8h, ref_data=%16h, real_data=%0d, tag=%0d",
                        $time, match_idx, proc2cache_load_queue[match_idx].addr, proc2cache_load_queue[match_idx].ref_data, proc2cache_load_queue[match_idx].real_data, proc2cache_load_queue[match_idx].tag);
                    end
                end
                "PROC_LOAD"      :   begin
                    load_item.addr  =   item.mem_in.addr;
                    case (item.mem_in.size)
                        BYTE    :   load_item.ref_data  =   {56'b0, ref_memory[load_item.addr[`XLEN-1:3]][load_item.addr[2:0]+: 8]};
                        HALF    :   load_item.ref_data  =   {48'b0, ref_memory[load_item.addr[`XLEN-1:3]][load_item.addr[2:0]+:16]};
                        WORD    :   load_item.ref_data  =   {32'b0, ref_memory[load_item.addr[`XLEN-1:3]][load_item.addr[2:0]+:32]};
                        DOUBLE  :   load_item.ref_data  =   ref_memory[load_item.addr[`XLEN-1:3]];
                    endcase
                    load_item.real_data =   'b0                     ;
                    load_item.tag       =   item.mem_out.response;
                    load_item.complete  =   1'b0                    ;
                    proc2cache_load_queue.push_back(load_item)                 ;
                    $display("T=%0t [Scoreboard] PROC_LOAD ref_data=%16h", $time, load_item.ref_data);
                end
                "PROC_STORE"     :   begin
                    case (item.mem_in.size)
                        BYTE    :   ref_memory[item.mem_in.addr[`XLEN-1:3]][item.mem_in.addr[2:0]+: 8]  =   item.mem_in.data[ 8-1:0];
                        HALF    :   ref_memory[item.mem_in.addr[`XLEN-1:3]][item.mem_in.addr[2:0]+:16]  =   item.mem_in.data[16-1:0];
                        WORD    :   ref_memory[item.mem_in.addr[`XLEN-1:3]][item.mem_in.addr[2:0]+:32]  =   item.mem_in.data[32-1:0];
                        DOUBLE  :   ref_memory[item.mem_in.addr[`XLEN-1:3]]                                 =   item.mem_in.data        ;
                    endcase
                end

                "MEM_OUTPUT"    :   begin
                    match_flag  =   1'b0;
                    match_idx   =   0   ;
                    for (int unsigned i = 0; i < cache2mem_load_queue.size(); i++) begin
                        if (cache2mem_load_queue[i].complete == 1'b0 
                        &&  cache2mem_load_queue[i].tag == item.mem_out.tag) begin
                            cache2mem_load_queue[i].complete  =   1'b1                ;
                            cache2mem_load_queue[i].real_data =   item.mem_out.data;
                            match_flag              =   1'b1                ;
                            match_idx               =   i                   ;
                            break;
                        end
                    end
                end
                "CACHE_LOAD"      :   begin
                    load_item.addr      =   item.mem_in.addr        ;
                    load_item.ref_data  =   'b0                     ;
                    load_item.real_data =   'b0                     ;
                    load_item.tag       =   item.mem_out.response   ;
                    load_item.complete  =   1'b0                    ;
                    cache2mem_load_queue.push_back(load_item)       ;
                    $display("T=%0t [Scoreboard] CACHE_LOAD", $time);
                end
                "CACHE_STORE"     :   begin

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
    virtual cache_if    vif         ;
    mailbox             scb_mbx     ;
    string              cmd_str     ;
    string              size_str    ;

    task run();
        $display("T=%0t [Monitor] starting ...", $time);
        forever begin
            @(posedge vif.clk_i);
            if (vif.cache2proc_o.response != 'd0) begin
                mon_item    item    =   new;
                item.mem_in.addr        =   vif.proc2cache_i.addr       ;
                item.mem_in.data        =   vif.proc2cache_i.data       ;
                item.mem_in.size        =   vif.proc2cache_i.size       ;
                item.mem_in.command     =   vif.proc2cache_i.command    ;
                item.mem_out.response    =   vif.cache2proc_o.response   ;
                item.mem_out.data        =   vif.cache2proc_o.data       ;
                item.mem_out.tag         =   vif.cache2proc_o.tag        ;
                if (vif.proc2cache_i.command == BUS_LOAD) begin
                    item.feature    =   "PROC_LOAD";
                end else if (vif.proc2cache_i.command == BUS_STORE) begin
                    item.feature    =   "PROC_STORE";
                end else begin
                    item.feature    =   "ERROR";
                end
                scb_mbx.put(item);
                size_str    =   size_str_conv(item.mem_in.size);
                $display("T=%0t [Monitor] %s detected, size=%s, addr=%8h, data=%16h, response=%0d",
                $time, item.feature, size_str, item.mem_in.addr, item.mem_in.data, item.mem_out.response);
            end
            
            if (vif.cache2proc_o.tag != 'd0) begin
                mon_item    item    =   new;
                item.mem_in.addr        =   vif.proc2cache_i.addr       ;
                item.mem_in.data        =   vif.proc2cache_i.data       ;
                item.mem_in.size        =   vif.proc2cache_i.size       ;
                item.mem_in.command     =   vif.proc2cache_i.command    ;
                item.mem_out.response   =   vif.cache2proc_o.response   ;
                item.mem_out.data       =   vif.cache2proc_o.data       ;
                item.mem_out.tag        =   vif.cache2proc_o.tag        ;
                item.feature            =   "CACHE_OUTPUT"              ;
                scb_mbx.put(item);
                $display("T=%0t [Monitor] %s detected , data=%16h, tag=%0d",
                $time, item.feature, item.mem_out.data, item.mem_out.tag);
            end

            if (vif.mem2cache_i.response != 'd0) begin
                mon_item    item    =   new;
                item.mem_in.addr        =   vif.cache2mem_o.addr       ;
                item.mem_in.data        =   vif.cache2mem_o.data       ;
                item.mem_in.size        =   vif.cache2mem_o.size       ;
                item.mem_in.command     =   vif.cache2mem_o.command    ;
                item.mem_out.response    =   vif.mem2cache_i.response   ;
                item.mem_out.data        =   vif.mem2cache_i.data       ;
                item.mem_out.tag         =   vif.mem2cache_i.tag        ;
                if (vif.cache2mem_o.command == BUS_LOAD) begin
                    item.feature    =   "CACHE_LOAD";
                end else if (vif.cache2mem_o.command == BUS_STORE) begin
                    item.feature    =   "CACHE_STORE";
                end else begin
                    item.feature    =   "ERROR";
                end
                scb_mbx.put(item);
                size_str    =   size_str_conv(item.mem_in.size);
                $display("T=%0t [Monitor] %s detected, size=%s, addr=%8h, data=%16h, response=%0d",
                $time, item.feature, size_str, item.mem_in.addr, item.mem_in.data, item.mem_out.response);
            end
            
            if (vif.mem2cache_i.tag != 'd0) begin
                mon_item    item    =   new;
                item.mem_in.addr        =   vif.cache2mem_o.addr       ;
                item.mem_in.data        =   vif.cache2mem_o.data       ;
                item.mem_in.size        =   vif.cache2mem_o.size       ;
                item.mem_in.command     =   vif.cache2mem_o.command    ;
                item.mem_out.response   =   vif.mem2cache_i.response   ;
                item.mem_out.data       =   vif.mem2cache_i.data       ;
                item.mem_out.tag        =   vif.mem2cache_i.tag        ;
                item.feature            =   "MEM_OUTPUT"                ;
                scb_mbx.put(item);
                $display("T=%0t [Monitor] %s detected , data=%16h, tag=%0d",
                $time, item.feature, item.mem_out.data, item.mem_out.tag);
            end

            print_mshr(vif.mshr_array_mon_o);
            print_cache_mem(vif.cache_array_mon_o);
        end
    endtask

    function void print_mshr(input MSHR_ENTRY [`MSHR_ENTRY_NUM-1:0] mshr_array_mon);
        string  cmd_str     ;
        string  size_str    ;
        string  state_str   ;
        begin
            $display("T=%0t MSHR Contents", $time);
            $display("index\t|state\t\t|cmd\t\t|req_addr\t|req_data\t\t|req_size\t|evict_addr\t|evict_data\t\t|evict_dirty\t|link_idx\t|linked\t|mem_tag");
            for (int entry_idx = 0; entry_idx < `MSHR_ENTRY_NUM; entry_idx++) begin
                state_str   =   mshr_state_str_conv(mshr_array_mon[entry_idx].state);
                cmd_str     =   cmd_str_conv(mshr_array_mon[entry_idx].cmd);
                size_str    =   size_str_conv(mshr_array_mon[entry_idx].req_size);
                $display("%0d\t|%s\t|%s\t|%8h\t|%16h\t|%s\t\t|%8h\t|%16h\t|%0b\t\t|%0d\t\t|%0b\t|%0d",
                entry_idx, state_str, cmd_str, mshr_array_mon[entry_idx].req_addr,
                mshr_array_mon[entry_idx].req_data, size_str, mshr_array_mon[entry_idx].evict_addr,
                mshr_array_mon[entry_idx].evict_data, mshr_array_mon[entry_idx].evict_dirty,
                mshr_array_mon[entry_idx].link_idx, mshr_array_mon[entry_idx].linked, 
                mshr_array_mon[entry_idx].mem_tag
                );
            end
        end
    endfunction

    function void print_cache_mem(input CACHE_MEM_ENTRY [`CACHE_SET_NUM-1:0][`CACHE_SASS-1:0] cache_array_mon);
        begin
            $display("T=%0t Cache Mem Contents", $time);
            $display("index\t|valid\t|dirty\t|lru\t|tag\t|data\t\t\t|\t\t|index\t|valid\t|dirty\t|lru\t|tag\t|data\t");
            for (int set_idx = 0; set_idx < `CACHE_SET_NUM; set_idx++) begin
                $display("%2h\t|%0b\t|%0b\t|%0b\t|%6h\t|%16h\t|\t\t|%2h\t|%0b\t|%0b\t|%0b\t|%6h\t|%16h\t",
                set_idx, cache_array_mon[set_idx][0].valid, cache_array_mon[set_idx][0].dirty, cache_array_mon[set_idx][0].lru,
                cache_array_mon[set_idx][0].tag, cache_array_mon[set_idx][0].data,
                set_idx, cache_array_mon[set_idx][1].valid, cache_array_mon[set_idx][1].dirty, cache_array_mon[set_idx][1].lru,
                cache_array_mon[set_idx][1].tag, cache_array_mon[set_idx][1].data);
            end
        end
    endfunction

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
    int     num     =   2000;

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
    CACHE_MEM_ENTRY [`CACHE_SET_NUM-1:0][`CACHE_SASS-1:0]   cache_array_mon_o   ;
    MSHR_ENTRY      [`MSHR_ENTRY_NUM-1:0]                   mshr_array_mon_o    ;

    logic       rst_i           ;
    MEM_IN      proc2cache_i    ;
    MEM_OUT     cache2proc_o    ;
    logic       memory_enable_i ;
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
        .mshr_array_mon_o   (_if.mshr_array_mon_o   ),
        .cache_array_mon_o  (_if.cache_array_mon_o  ),
        .clk_i              (    clk_i              ),
        .rst_i              (_if.rst_i              ),
        .proc2cache_i       (_if.proc2cache_i       ),
        .cache2proc_o       (_if.cache2proc_o       ),
        .memory_enable_i    (_if.memory_enable_i    ),
        .cache2mem_o        (_if.cache2mem_o        ),
        .mem2cache_i        (_if.mem2cache_i        )
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
        _if.memory_enable_i =   1'b1;
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