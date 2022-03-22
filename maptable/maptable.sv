module maptable #(
    parameter C_DP_NUM = `DP_NUM,
    parameter C_MT_ENTRY = `MT_ENTRY;
    parameter C_CDB_NUM = CDB_NUM;
) (
    input logic clk_i,
    input logic rst_i,
    input logic rollback_i,

    input CDB [C_CDB_NUM-1:0] cdb_i,
    input DP_MT [C_DP_NUM-1:0] dp_i,
    input  AMT_ENTRY [C_MT_ENTRY-1:0] amt_i,
    output MT_DP [C_DP_NUM-1:0] mp_o
);
    MP_ENTRY [C_MT_ENTRY-1:0] mt_entry;

    // read == mp_dp.rs1 and rs2
    // write == rd;
    genvar i,j;
    generate;
    for (i = 0; i<C_DP_NUM; i++) begin
        always_comb begin
            if (i = 1 && dp_i[0].wr_en && dp_i[i].rs1 == dp_i[0].rd) begin
                mp_o[i].tag1 = dp_i[0].tag;
                mp_o[i].tag1_ready = 0;
            end else if (i = 1 && dp_i[0].wr_en && dp_i[i].rs2 == dp_i[0].rd) begin 
                mp_o[i].tag2 = dp_i[0].tag;
                mp_o[i].tag2_ready = 0;
            end else if ( dp_i[i].read_en) begin 
                mp_o[i].tag1 = mt_entry[dp_i[i].rs1].tag;
                mp_o[i].tag2 = mt_entry[dp_i[i].rs2].tag;
                mp_o[i].tag1_ready = mt_entry[dp_i[i].rs1].phy_reg_ready;
                mp_o[i].tag2_ready = mt_entry[dp_i[i].rs2].phy_reg_ready;
            end else begin
                mp_o[i].tag1 = 0;
                mp_o[i].tag2 = 0;
                mp_o[i].tag1_ready = 0;
                mp_o[i].tag2_ready = 0;
            end 
        end
    end

    for (j = 0; j< C_DP_NUM; j++) begin
        always_comb begin
            mp_o[i].tag_old = mt_entry[dp_i[i].rd].tag;
        end
    end
    endgenerate


    always_comb begin
        for (integer cdb_idx = 0; idx < CDB_NUM; idx++) begin
            if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mp_o[cdb_idx].tag1) begin
                mp_o[cdb_idx].tag1_ready = 1;
            end else if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mp_o[cdb_idx].tag2) begin
                mp_o[cdb_idx].tag2_ready = 1;
            end 
        end
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            for (integer entry_idx=0; entry_idx<C_MT_ENTRY; entry_idx++) begin
                mt_entry[entry_idx].tag <= entry_idx;
                mt_entry[entry_idx].phy_reg_ready <= 1;
            end
        end else if (rollback) begin
            for (integer entry_idx=0; entry_idx<C_MT_ENTRY; entry_idx++) begin
                mt_entry[entry_idx].phy_reg_ready <= 1;
                mt_entry[entry_idx].tag <= amt_i[entry_idx].amt_tag;
            end
        end else begin
            for (integer r=0; r<C_DP_NUM; r++) begin
                if (dp_i[r].write_en) begin
                    mt_entry[dp_i[r].rd].tag <= dp_i[r].tag;
                    mt_entry[dp_i[r].rd].phy_reg_ready <= 0; 
                end 
            end
               
            for (integer entry_idx = 0; entry_idx < C_MT_ENTRY; entry_idx++) begin
                for (integer cdb_idx = 0; cdb_idx < C_CDB_NUM; cdb_idx++) begin
                    if(mt_entry[entry_idx].tag == cdb_i[cdb_idx].tag && cdb_i[cdb_idx].valid ) {
                        mt_entry[entry_idx].phy_reg_ready <= 1;
                    }
                end
            end
        end     
    end

endmodule