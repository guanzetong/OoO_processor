/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  VFL_sim.sv                                          //
//                                                                     //
//  Description :  VFL_sim                                             // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module VFL_sim #(
    parameter   C_RT_NUM            =   `RT_NUM         ,
    parameter   C_ARCH_REG_NUM      =   `ARCH_REG_NUM   ,
    parameter   C_PHY_REG_NUM       =   `PHY_REG_NUM    ,
    parameter   C_FL_ENTRY_NUM      =   C_PHY_REG_NUM - C_PHY_REG_NUM
) (
    input   logic                               clk_i       ,   //  Clock
    input   logic                               rst_i       ,   //  Reset
    input   ROB_VFL     [C_RT_NUM-1:0]          rob_vfl_i   ,
    output  FL_ENTRY    [C_FL_ENTRY_NUM-1:0]    vfl_o       ,
    input   logic                               roll_back_i 
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================

// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    FL_ENTRY    [C_FL_ENTRY_NUM-1:0]    victim_freelist ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

    task victim_freelist_init();
        begin
            for (int unsigned entry_idx = 0; entry_idx < C_FL_ENTRY_NUM; entry_idx++) begin
                victim_freelist[entry_idx]  =   entry_idx + C_ARCH_REG_NUM;
            end
        end
    endtask

    task victim_freelist_run();
        begin
            forever begin
                @(posedge clk_i);
                if (rst_i) begin
                    victim_freelist_init();
                end else begin
                    for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++) begin
                        if (rob_vfl_i[rt_idx].wr_en) begin
                            for (int unsigned entry_idx = 0; entry_idx < C_FL_ENTRY_NUM; entry_idx++) begin
                                if (rob_vfl_i[rt_idx].tag_old == victim_freelist[entry_idx].tag) begin
                                    victim_freelist[entry_idx].tag  =   rob_vfl_i[rt_idx].tag;
                                end
                            end
                        end
                    end
                end
            end
        end
    endtask

    initial begin
        victim_freelist_init();
        victim_freelist_run();
    end

    assign  vfl_o   =   victim_freelist;
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
