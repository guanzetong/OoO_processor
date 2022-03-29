/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  MT_sim.sv                                           //
//                                                                     //
//  Description :  Map Table simulation                                // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module MT_sim #(
    parameter    C_DP_NUM           =      `DP_NUM          ,
    parameter    C_ARCH_REG_NUM     =      `ARCH_REG_NUM    ,
    parameter    C_CDB_NUM          =      `CDB_NUM         ,
    parameter    C_TAG_IDX_WIDTH    =      `TAG_IDX_WIDTH
) (
    input   logic                               clk_i           ,         
    input   logic                               rst_i           ,         
    input   logic                               rollback_i      ,    

    input   CDB         [C_CDB_NUM-1:0]         cdb_i           ,
    input   DP_MT_READ  [C_DP_NUM-1:0]          dp_mt_read_i    ,
    input   DP_MT_WRITE [C_DP_NUM-1:0]          dp_mt_write_i   ,
    input   AMT_ENTRY   [C_ARCH_REG_NUM-1:0]    amt_i           ,
    output  MT_DP       [C_DP_NUM-1:0]          mt_dp_o         ,

    // For Testing
    output  MT_ENTRY    [C_ARCH_REG_NUM-1:0]    mt_mon_o        
); 

// ====================================================================
// Signal Declarations Start
// ====================================================================
    MT_ENTRY    [C_ARCH_REG_NUM-1:0]    mt_entry    ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

    task map_table_init();
        for (int unsigned entry_idx = 0; entry_idx < C_ARCH_REG_NUM; entry_idx++) begin
            mt_entry[entry_idx].tag         =   entry_idx;
            mt_entry[entry_idx].tag_ready   =   1'b1;
        end
    endtask

    task map_table_run();
        forever begin
            @(negedge clk_i);
            // System reset
            if (rst_i) begin
                for (int unsigned entry_idx = 0; entry_idx < C_ARCH_REG_NUM; entry_idx++) begin
                    mt_entry[entry_idx].tag         =   entry_idx;
                    mt_entry[entry_idx].tag_ready   =   1'b1;
                end
            // Roll-back, copy AMT tags
            end else if (rollback_i) begin
                for (int unsigned entry_idx = 0; entry_idx < C_ARCH_REG_NUM; entry_idx++) begin
                    mt_entry[entry_idx].tag         =   amt_i[entry_idx].amt_tag;
                    mt_entry[entry_idx].tag_ready   =   1'b1;
                end
            // Normal
            end else begin
                // Complete, assert the ready bit of completed tag
                for (int unsigned cp_idx = 0; cp_idx < C_CDB_NUM; cp_idx++) begin
                    if (cdb_i[cp_idx].valid) begin
                        for (int unsigned entry_idx = 0; entry_idx < C_ARCH_REG_NUM; entry_idx++) begin
                            if (mt_entry[entry_idx].tag == cdb_i[cp_idx].tag) begin
                                mt_entry[entry_idx].ready   =   1'b1;
                            end
                        end
                    end
                end

                // Dispatch, read tags and also update.
                for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
                    // Read RS1, RS2 and RD tags
                    if (dp_mt_read_i[dp_idx].rs1 == `ZERO_REG) begin
                        mt_dp_o[dp_idx].tag1        =   'd0 ;
                        mt_dp_o[dp_idx].tag1_ready  =   1'b1;
                    end else begin
                        mt_dp_o[dp_idx].tag1        =   mt_entry[dp_mt_read_i[dp_idx].rs1].tag      ;
                        mt_dp_o[dp_idx].tag1_ready  =   mt_entry[dp_mt_read_i[dp_idx].rs1].tag_ready;
                    end

                    if (dp_mt_read_i[dp_idx].rs2 == `ZERO_REG) begin
                        mt_dp_o[dp_idx].tag2        =   'd0 ;
                        mt_dp_o[dp_idx].tag2_ready  =   1'b1;
                    end else begin
                        mt_dp_o[dp_idx].tag2        =   mt_entry[dp_mt_read_i[dp_idx].rs2].tag      ;
                        mt_dp_o[dp_idx].tag2_ready  =   mt_entry[dp_mt_read_i[dp_idx].rs2].tag_ready;
                    end

                    if (dp_mt_write_i[dp_idx].rd == `ZERO_REG) begin
                        mt_dp_o[dp_idx].tag_old     =   'd0;
                    end else begin
                        mt_dp_o[dp_idx].tag_old     =   mt_entry[dp_mt_write_i[dp_idx].rd].tag      ;
                    end

                    // Update Map Table for newly dispatched instructions
                    if (dp_mt_write_i[dp_idx].wr_en == 1'b1) begin
                        mt_entry[dp_mt_write_i[dp_idx].rd].tag          =   dp_mt_write_i[dp_idx].tag;
                        mt_entry[dp_mt_write_i[dp_idx].rd].tag_ready    =   1'b0;
                    end
                end
            end
        end
    endtask


    initial begin
        map_table_init();
        map_table_run();
    end

    assign  mt_mon_o    =   mt_entry;
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
