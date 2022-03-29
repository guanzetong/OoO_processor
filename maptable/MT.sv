module MT #(
    parameter    C_DP_NUM           =      `DP_NUM          ,
    parameter    C_MT_ENTRY_NUM     =      `MT_ENTRY_NUM    ,
    parameter    C_CDB_NUM          =      `CDB_NUM         ,
    parameter    C_TAG_IDX_WIDTH    =      `TAG_IDX_WIDTH
) (
    input        logic              clk_i       ,         
    input        logic              rst_i       ,         
    input        logic              rollback_i  ,    

    input        CDB                [C_CDB_NUM-1:0]      cdb_i           ,
    input        DP_MT_READ         [C_DP_NUM-1:0]       dp_mt_read_i    ,
    input        DP_MT_WRITE        [C_DP_NUM-1:0]       dp_mt_write_i   ,
    input        AMT_ENTRY          [C_MT_ENTRY_NUM-1:0] amt_i           ,
    output       MT_DP              [C_DP_NUM-1:0]       mt_dp_o
); 
   
    MT_ENTRY    [C_MT_ENTRY_NUM-1:0]    mt_entry    ;
    
    always_comb begin
        for (integer i = 0; i<C_DP_NUM; i++) begin
            if (i == 1 && dp_mt_write_i[0].wr_en && dp_mt_read_i[i].rs1 == dp_mt_write_i[0].rd) begin
                mt_dp_o[i].tag1 = dp_mt_write_i[i-1].tag;
                mt_dp_o[i].tag1_ready = 0;
            end 
            else if (dp_mt_read_i[i].read_en) begin 
                mt_dp_o[i].tag1 = mt_entry[dp_mt_read_i[i].rs1].tag;
                mt_dp_o[i].tag1_ready = mt_entry[dp_mt_read_i[i].rs1].tag_ready;
            end else begin 
                mt_dp_o[i].tag1 = 0;
                mt_dp_o[i].tag1_ready = 0;
            end

            if (i == 1 && dp_mt_write_i[0].wr_en && dp_mt_read_i[i].rs2 == dp_mt_write_i[0].rd) begin 
                mt_dp_o[i].tag2 = dp_mt_write_i[i-1].tag;
                mt_dp_o[i].tag2_ready = 0;
            end else if (dp_mt_read_i[i].read_en) begin 
                mt_dp_o[i].tag2 = mt_entry[dp_mt_read_i[i].rs2].tag;
                mt_dp_o[i].tag2_ready = mt_entry[dp_mt_read_i[i].rs2].tag_ready;
            end else begin 
                mt_dp_o[i].tag2 = 0;
                mt_dp_o[i].tag2_ready = 0;
            end
        end
        
        for (integer cdb_idx = 0; cdb_idx < C_CDB_NUM; cdb_idx++) begin
            if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mt_dp_o[cdb_idx].tag1) begin
                mt_dp_o[cdb_idx].tag1_ready = 1;
            end else if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mt_dp_o[cdb_idx].tag2) begin
                mt_dp_o[cdb_idx].tag2_ready = 1;
            end 
        end
    end

    always_comb begin 
        integer i;
        for (i = 0; i< C_DP_NUM; i++) begin
            if (dp_mt_write_i[i].wr_en) begin 
                mt_dp_o[i].tag_old <= mt_entry[dp_mt_write_i[i].rd].tag;
            end
        end
    end

    always_ff @(posedge clk_i) begin
        
        if (rst_i) begin
            for (integer entry_idx=0; entry_idx<C_MT_ENTRY_NUM; entry_idx++) begin
                mt_entry[entry_idx].tag <= entry_idx;
                mt_entry[entry_idx].tag_ready <= 1;
            end
        end else if (rollback_i) begin
            for (integer entry_idx=0; entry_idx<C_MT_ENTRY_NUM; entry_idx++) begin
                mt_entry[entry_idx].tag_ready <= 1;
                mt_entry[entry_idx].tag <= amt_i[entry_idx].amt_tag;
            end
        end else begin
            for (integer r=0; r<C_DP_NUM; r++) begin
                if (dp_mt_write_i[r].wr_en) begin
                    mt_entry[dp_mt_write_i[r].rd].tag <= dp_mt_write_i[r].tag;
                    mt_entry[dp_mt_write_i[r].rd].tag_ready <= 0; 
                end
            end
               
            for (integer entry_idx = 0; entry_idx < C_MT_ENTRY_NUM; entry_idx++) begin
                for (integer cdb_idx = 0; cdb_idx < C_CDB_NUM; cdb_idx++) begin
                    if(mt_entry[entry_idx].tag == cdb_i[cdb_idx].tag && cdb_i[cdb_idx].valid ) begin
                        mt_entry[entry_idx].tag_ready <= 1'b1;
                    end
                end
            end
        end     
    end

endmodule