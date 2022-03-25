module maptable #(
    parameter C_DP_NUM = `DP_NUM,
    parameter C_MT_ENTRY = `MT_ENTRY,
    parameter C_CDB_NUM = `CDB_NUM,
    parameter C_TAG_IDX_WIDTH = `TAG_IDX_WIDTH
) (
    input logic clk_i,         
    input logic rst_i,         
    input logic rollback_i,    

    input CDB [C_CDB_NUM-1:0] cdb_i,
    input DP_MT [C_DP_NUM-1:0] dp_mp_i,
    input  AMT_ENTRY [C_MT_ENTRY-1:0] amt_i,
    output MT_DP [C_DP_NUM-1:0] mp_dp_o
);
    MP_ENTRY [C_MT_ENTRY-1:0] mt_entry;
    logic [`TAG_IDX_WIDTH-1:0] rd_tag_buffer;
    logic rd_ready_bit_buffer;
    // read == mp_dp.rs1 and rs2
    // write == rd;
    // genvar i,j;
    // generate;
    // for (i = 0; i<C_DP_NUM; i++) begin
    //     always_comb begin
    //         // if (i == 1 && dp_mp_i[0].wr_en && dp_mp_i[i].rs1 == dp_mp_i[0].rd) begin
    //         //     mp_dp_o[i].tag1 = dp_mp_i[i-1].tag;
    //         //     mp_dp_o[i].tag1_ready = 0;
    //         // end else begin 
    //         //     mp_dp_o[i].tag1 = mt_entry[dp_mp_i[i].rs1].tag;
    //         //     mp_dp_o[i].tag1_ready = mt_entry[dp_mp_i[i].rs1].phy_reg_ready;
    //         // end

    //         // if (i == 1 && dp_mp_i[0].wr_en && dp_mp_i[i].rs2 == dp_mp_i[0].rd) begin 
    //         //     mp_dp_o[i].tag2 = dp_mp_i[i-1].tag;
    //         //     mp_dp_o[i].tag2_ready = 0;
    //         // end else begin 
    //         //     mp_dp_o[i].tag2 = mt_entry[dp_mp_i[i].rs2].tag;
    //         //     mp_dp_o[i].tag2_ready = mt_entry[dp_mp_i[i].rs2].phy_reg_ready;
    //         // end

    //         for (integer cdb_idx = 0; cdb_idx < C_CDB_NUM; cdb_idx++) begin
    //             if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mp_dp_o[cdb_idx].tag1) begin
    //                 mp_dp_o[cdb_idx].tag1_ready = 1;
    //             end else if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mp_dp_o[cdb_idx].tag2) begin
    //                 mp_dp_o[cdb_idx].tag2_ready = 1;
    //             end 
    //         end
    //     end
    // // end
    // always_comb begin
    //     for (integer j = 0; j< C_DP_NUM; j++) begin
    //         if (!dp_mp_i[j].wr_en) begin
    //             mp_dp_o[j].tag_old = mt_entry[dp_mp_i[j].rd].tag;
    //         end 
    //     end
    // end

    // endgenerate

    always_comb begin
        // if (i == 1 && dp_mp_i[0].wr_en && dp_mp_i[i].rs1 == dp_mp_i[0].rd) begin
        //     mp_dp_o[i].tag1 = dp_mp_i[i-1].tag;
        //     mp_dp_o[i].tag1_ready = 0;
        // end else begin 
        //     mp_dp_o[i].tag1 = mt_entry[dp_mp_i[i].rs1].tag;
        //     mp_dp_o[i].tag1_ready = mt_entry[dp_mp_i[i].rs1].phy_reg_ready;
        // end
        for (integer i = 0; i<C_DP_NUM; i++) begin
            if (i == 1 && dp_mp_i[0].wr_en && dp_mp_i[i].rs1 == dp_mp_i[0].rd) begin
                mp_dp_o[i].tag1 = dp_mp_i[i-1].tag;
                mp_dp_o[i].tag1_ready = 0;
            end 
            // else if (dp_mp_i[i].rs1 == dp_mp_i[i].rd && dp_mp_i[i].read_en)begin 
            //     mp_dp_o[i].tag1 = rd_tag_buffer[i];
            //     mp_dp_o[i].tag1_ready = rd_ready_bit_buffer[i];
            // end 
            else if (dp_mp_i[i].read_en) begin 
                mp_dp_o[i].tag1 = mt_entry[dp_mp_i[i].rs1].tag;
                mp_dp_o[i].tag1_ready = mt_entry[dp_mp_i[i].rs1].phy_reg_ready;
            end else begin 
                mp_dp_o[i].tag1 = 0;
                mp_dp_o[i].tag1_ready = 0;
            end

            if (i == 1 && dp_mp_i[0].wr_en && dp_mp_i[i].rs2 == dp_mp_i[0].rd) begin 
                mp_dp_o[i].tag2 = dp_mp_i[i-1].tag;
                mp_dp_o[i].tag2_ready = 0;
            end else if (dp_mp_i[i].read_en) begin 
                mp_dp_o[i].tag2 = mt_entry[dp_mp_i[i].rs2].tag;
                mp_dp_o[i].tag2_ready = mt_entry[dp_mp_i[i].rs2].phy_reg_ready;
            end else begin 
                mp_dp_o[i].tag2 = 0;
                mp_dp_o[i].tag2_ready = 0;
            end
        end
        
        for (integer cdb_idx = 0; cdb_idx < C_CDB_NUM; cdb_idx++) begin
            if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mp_dp_o[cdb_idx].tag1) begin
                mp_dp_o[cdb_idx].tag1_ready = 1;
            end else if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mp_dp_o[cdb_idx].tag2) begin
                mp_dp_o[cdb_idx].tag2_ready = 1;
            end 
        end
    end



    // always_comb begin
    //     for (integer cdb_idx = 0; idx < CDB_NUM; idx++) begin
    //         if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mp_dp_o[cdb_idx].tag1) begin
    //             mp_dp_o[cdb_idx].tag1_ready = 1;
    //         end else if (cdb_i[cdb_idx].valid && cdb_i[cdb_idx].tag == mp_dp_o[cdb_idx].tag2) begin
    //             mp_dp_o[cdb_idx].tag2_ready = 1;
    //         end 
    //     end
    // end

    always_ff @(posedge clk_i) begin
        
        if (rst_i) begin
            for (integer entry_idx=0; entry_idx<C_MT_ENTRY; entry_idx++) begin
                mt_entry[entry_idx].tag <= entry_idx;
                mt_entry[entry_idx].phy_reg_ready <= 1;
            end
        end else if (rollback_i) begin
            for (integer entry_idx=0; entry_idx<C_MT_ENTRY; entry_idx++) begin
                mt_entry[entry_idx].phy_reg_ready <= 1;
                mt_entry[entry_idx].tag <= amt_i[entry_idx].amt_tag;
            end
        end else begin
            for (integer r=0; r<C_DP_NUM; r++) begin
                // if (dp_mp_i[r].rs1 == dp_mp_i[r].rd && dp_mp_i[r].read_en) begin 
                //         rd_tag_buffer[r] <= mt_entry[dp_mp_i[r].rd].tag;
                //         rd_ready_bit_buffer [r] <= mt_entry[dp_mp_i[r].rd].phy_reg_ready;
                // end
                if (dp_mp_i[r].wr_en) begin
                    mp_dp_o[r].tag_old <= mt_entry[dp_mp_i[r].rd].tag;

                    mt_entry[dp_mp_i[r].rd].tag <= dp_mp_i[r].tag;
                    mt_entry[dp_mp_i[r].rd].phy_reg_ready <= 0; 
                end 
            end
               
            for (integer entry_idx = 0; entry_idx < C_MT_ENTRY; entry_idx++) begin
                for (integer cdb_idx = 0; cdb_idx < C_CDB_NUM; cdb_idx++) begin
                    if(mt_entry[entry_idx].tag == cdb_i[cdb_idx].tag && cdb_i[cdb_idx].valid ) begin
                        mt_entry[entry_idx].phy_reg_ready <= 1'b1;
                    end
                end
            end
        end     
    end

endmodule