
module AMT #(
    parameter C_RT_NUM           = `RT_NUM          ,
    parameter C_MT_ENTRY_NUM     = `ARCH_REG_NUM    ,
    parameter C_TAG_IDX_WIDTH    = `TAG_IDX_WIDTH
)(
    input   logic        clk_i       ,
    input   logic        rst_i       ,
    input   logic        rollback_i  , 

    input   ROB_AMT      [C_RT_NUM-1:0]   rob_amt_i, 
   
    output  AMT_OUTPUT   [C_MT_ENTRY_NUM-1:0] amt_o

);

    AMT_ENTRY  [C_RT_NUM- 1:0] amt_entry;

    always_comb begin
        if (rollback_i) begin
            for (int i=0; i<C_MT_ENTRY_NUM; i++) begin
                if (rob_amt_i[0].wr_en && rob_amt_i[0].arch_reg == i) begin
                    amt_o[i].amt_tag = rob_amt_i[0].phy_reg;
                end else if (rob_amt_i[1].wr_en && rob_amt_i[1].arch_reg == i) begin
                    amt_o[i].amt_tag = rob_amt_i[1].phy_reg;
                end else begin
                    amt_o[i].amt_tag = amt_entry[i].amt_tag;
                end
            end
        end else begin
            for (int i=0; i<C_MT_ENTRY_NUM; i++) begin
                amt_o[i].amt_tag = amt_entry[i].amt_tag;
            end
        end
            
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            for(int i=0; i<C_MT_ENTRY_NUM; i++) begin
                amt_entry[i].amt_tag <= i;
            end
        end else begin
            for (int i=0; i<C_MT_ENTRY_NUM; i++) begin
                for (int j=0; j<C_RT_NUM; j++) begin
                    if (rob_amt_i[j].wr_en && rob_amt_i[j].arch_reg == i) begin
                        amt_entry[rob_amt_i[j].arch_reg].amt_tag <= rob_amt_i[j].phy_reg;
                    end else begin
                    end
                end
            end
        end
    end
    
endmodule