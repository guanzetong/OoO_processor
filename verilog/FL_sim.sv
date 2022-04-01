/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  FL_sim.sv                                           //
//                                                                     //
//  Description :  FL_sim                                              // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module FL_sim #(
    parameter   C_DP_NUM        =   `DP_NUM         ,
    parameter   C_RT_NUM        =   `RT_NUM         ,
    parameter   C_PHY_REG_NUM   =   `PHY_REG_NUM    ,
    parameter   C_ARCH_REG_NUM  =   `ARCH_REG_NUM   ,
    parameter   C_FL_ENTRY_NUM  =   C_PHY_REG_NUM - C_ARCH_REG_NUM
)(
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    output  FL_DP                               fl_dp_o         ,
    input   DP_FL                               dp_fl_i         ,
    input   ROB_FL                              rob_fl_i        ,
    input   FL_ENTRY    [C_FL_ENTRY_NUM-1:0]    vfl_i           ,
    input   logic                               rollback_i      
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_FL_NUM_WIDTH  =   $clog2(C_FL_ENTRY_NUM+1)  ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    FL_ENTRY                            freelist    [$] ;
    FL_ENTRY                            fl_entry        ;
    logic       [C_FL_NUM_WIDTH-1:0]    avail_num       ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   sub_module_name
// Description  :   sub module function
// --------------------------------------------------------------------


// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------
    task freelist_init();
        for (int unsigned entry_idx = 0; entry_idx < C_FL_ENTRY_NUM; entry_idx++) begin
            fl_entry.tag    =   entry_idx + C_ARCH_REG_NUM;
            freelist.push_back(fl_entry);
        end
    endtask

    task freelist_run();
        fl_dp_o =   0;
        forever begin
            @(posedge clk_i);
            // System reset
            if (rst_i) begin
                freelist.delete();
                freelist_init();
                // $display("Reset Freelist size=%0d", freelist.size());
            end else if (rollback_i) begin
                freelist.delete();
                for (int unsigned entry_idx = 0; entry_idx < C_FL_ENTRY_NUM; entry_idx++) begin
                    fl_entry.tag =  vfl_i[entry_idx].tag;
                    freelist.push_back(fl_entry);
                end
                fl_dp_o.avail_num   =   C_DP_NUM;
                // $display("Rollback Freelist size=%0d", freelist.size());
            end else begin
                // Retire
                for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++)begin
                    if ((rt_idx < rob_fl_i.rt_num) && (rob_fl_i.tag_old[rt_idx] != `ZERO_REG))begin
                        fl_entry.tag[rt_idx] = rob_fl_i.tag_old[rt_idx];
                        freelist.push_back(fl_entry);
                    end
                end
            end

            @(negedge clk_i);
            
            // Dispatch
            avail_num   =   freelist.size();
            // $display("Normal Freelist size=%0d", freelist.size());
            if (avail_num > C_DP_NUM) begin
                fl_dp_o.avail_num   =   C_DP_NUM;
            end else begin
                fl_dp_o.avail_num   =   avail_num;
            end

            #1;
            // $display("avail num=%0d", avail_num);
            // $display("FL avail num=%0d", fl_dp_o.avail_num);

            for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++)begin
                if(dp_idx < dp_fl_i.dp_num)begin
                    fl_dp_o.tag[dp_idx] = freelist.pop_front();    
                end else begin
                    fl_dp_o.tag[dp_idx] = 'b0;
                end
            end
        end
    endtask

    initial begin
        freelist_init();
        freelist_run();
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
