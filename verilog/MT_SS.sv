/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  MT_SS.sv                                            //
//                                                                     //
//  Description :  Map Table with support of N-way superscalar.        // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////
module MT_SS #(
    parameter   C_DP_NUM        =   `DP_NUM         ,
    parameter   C_CDB_NUM       =   `CDB_NUM        ,
    parameter   C_ARCH_REG_NUM  =   `ARCH_REG_NUM
) (
    input   logic                               clk_i       ,
    input   logic                               rst_i       ,
    input   logic                               rollback_i  ,
    input   DP_MT       [C_DP_NUM-1:0]          dp_mt_i     ,
    input   CDB         [C_CDB_NUM-1:0]         cdb_i       ,
    input   AMT_ENTRY   [C_ARCH_REG_NUM-1:0]    amt_i       ,
    output  MT_DP       [C_DP_NUM-1:0]          mt_dp_o     
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    MT_ENTRY    [C_ARCH_REG_NUM-1:0]    mt_entry        ;
    MT_ENTRY    [C_ARCH_REG_NUM-1:0]    next_mt_entry   ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Read tags & tag_readys of each new Dispatch
// --------------------------------------------------------------------
    always_comb begin : MT_READ
        // Loop over the Dispatch channels
        for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
            // Use the latched tag and tag_ready by default
            mt_dp[dp_idx].tag1          =   mt_entry[dp_mt[dp_idx].rs1].tag;
            mt_dp[dp_idx].tag1_ready    =   mt_entry[dp_mt[dp_idx].rs1].tag_ready;
            mt_dp[dp_idx].tag2          =   mt_entry[dp_mt[dp_idx].rs2].tag;
            mt_dp[dp_idx].tag2_ready    =   mt_entry[dp_mt[dp_idx].rs2].tag_ready;
            mt_dp[dp_idx].tag_old       =   mt_entry[dp_mt[dp_idx].rd].tag;

            // Check CDB.tag to forward tag_ready
            for (int unsigned cp_idx = 0; cp_idx < C_CDB_NUM; cp_idx++) begin
                if (cdb_i[cp_idx].valid && (cdb_i[cp_idx].tag != `ZERO_REG)) begin
                    // Compare "tag1" of this channel to "tag" of a CDB channel
                    if (cdb_i[cp_idx].tag == mt_dp[dp_idx].tag1) begin
                        mt_dp[dp_idx].tag1_ready    =   1'b1;
                    end
                    // Compare "tag2" of this channel to "tag" of a CDB channel
                    if (cdb_i[cp_idx].tag == mt_dp[dp_idx].tag2) begin
                        mt_dp[dp_idx].tag2_ready    =   1'b1;
                    end
                end
            end

            // Loop over the "rd" in Dispatch channels
            for (int unsigned rd_idx = 0; rd_idx < C_DP_NUM; rd_idx++) begin
                // Check the older Dispatch channels
                if (rd_idx < dp_idx) begin
                    // Compare "rs1" of this channel to "rd" of the older channel
                    if ((dp_mt[dp_idx].rs1 != `ZERO_REG) && (dp_mt[dp_idx].rs1 == dp_mt[rd_idx].rd)
                    && (dp_mt[rd_idx].wr_en == 1'b1)) begin
                        mt_dp[dp_idx].tag1          =   dp_mt[rd_idx].tag;
                        mt_dp[dp_idx].tag1_ready    =   1'b0;
                    end
                    // Compare "rs2" of this channel to "rd" of the older channel
                    if ((dp_mt[dp_idx].rs2 != `ZERO_REG) && (dp_mt[dp_idx].rs2 == dp_mt[rd_idx].rd)
                    && (dp_mt[rd_idx].wr_en == 1'b1)) begin
                        mt_dp[dp_idx].tag2          =   dp_mt[rd_idx].tag;
                        mt_dp[dp_idx].tag2_ready    =   1'b0;
                    end
                    // Compare "rd" of this channel to "rd" of the older channel
                    if ((dp_mt[dp_idx].rd != `ZERO_REG) && (dp_mt[dp_idx].rd == dp_mt[rd_idx].rd)
                    && (dp_mt[rd_idx].wr_en == 1'b1)) begin
                        mt_dp[dp_idx].tag_old       =   dp_mt[rd_idx].tag;
                    end
                end
            end
        end
    end

// --------------------------------------------------------------------
// Derive the entry content of the next cycle
// --------------------------------------------------------------------
    always_comb begin
        // Map Table entries Remain unchanged by default
        next_mt_entry   =   mt_entry;
        // R0 should never be renamed
        next_mt_entry[0].tag        =   'd0;
        next_mt_entry[0].tag_ready  =   1'b1;
        // Loop over Map Table Entries
        for (int unsigned entry_idx = 1; entry_idx < C_ARCH_REG_NUM; entry_idx++) begin
            // Loop over CDB channels
            for (int unsigned cp_idx = 0; cp_idx < C_CDB_NUM; cp_idx++) begin
                // Compare "tag" of this entry to "tag" of a CDB channel
                if ((cdb_i[cp_idx].valid == 1'b1) && (cdb_i[cp_idx].tag == mt_entry[entry_idx].tag)) begin
                    next_mt_entry[entry_idx].tag_ready    =   1'b1;
                end
            end
            // Loop over Dispatch channels 
            for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
                // Compare "tag" of this entry to "tag" of Dispatch channels
                // Pick the "tag" of the newest match
                if ((dp_mt[dp_idx].wr_en == 1'b1) && (dp_mt[dp_idx].rd == entry_idx)) begin
                    next_mt_entry[entry_idx].tag        =   dp_mt[dp_idx].tag;
                    next_mt_entry[entry_idx].tag_ready  =   1'b0;
                end
            end
        end
    end

// --------------------------------------------------------------------
// Write entries
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin : MT_WRITE
        // Loop over the Dispatch channels
        for (int unsigned entry_idx = 0; entry_idx < C_ARCH_REG_NUM; entry_idx++) begin
            // System Reset
            if (rst_i) begin
                mt_entry[entry_idx].tag         <=  `SD entry_idx;
                mt_entry[entry_idx].tag_ready   <=  `SD 1'b1;
            // Rollback
            end else if (rollback_i) begin
                mt_entry[entry_idx].tag         <=  `SD amt_i[entry_idx].tag;
                mt_entry[entry_idx].tag_ready   <=  `SD 1'b1;
            // Update entries
            end else begin
                mt_entry[entry_idx]             <=  `SD next_mt_entry[entry_idx];
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================
endmodule


