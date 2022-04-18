module AMT #(
    parameter   C_RT_NUM            =   `RT_NUM         ,
    parameter   C_ARCH_REG_NUM      =   `ARCH_REG_NUM   ,
    parameter   C_TAG_IDX_WIDTH     =   `TAG_IDX_WIDTH  ,
    parameter   C_THREAD_NUM        =   `THREAD_NUM     ,
    parameter   C_THREAD_IDX_WIDTH  =   $clog2(C_THREAD_NUM)
)(
    input   logic                                   clk_i           ,
    input   logic                                   rst_i           ,
    input   logic                                   rollback_i      , 
    input   logic       [C_THREAD_IDX_WIDTH-1:0]    thread_idx_i    ,
    input   ROB_AMT     [C_RT_NUM-1:0]   			rob_amt_i       , 
    output  AMT_ENTRY  [C_ARCH_REG_NUM-1:0] 		amt_o
);

    localparam  C_ARCH_REG_IDX_WIDTH    =   $clog2(C_ARCH_REG_NUM);

    AMT_ENTRY  [C_ARCH_REG_NUM- 1:0] amt_entry;

    always_comb begin
        for (int unsigned arch_idx = 0; arch_idx < C_ARCH_REG_NUM; arch_idx++) begin
            amt_o[arch_idx].amt_tag =   amt_entry[arch_idx].amt_tag;
            if (rollback_i) begin
                for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++) begin
                    if ((rob_amt_i[rt_idx].wr_en == 1'b1) && (rob_amt_i[rt_idx].arch_reg == arch_idx)) begin
                        amt_o[arch_idx].amt_tag =   rob_amt_i[rt_idx].phy_reg;
                    end
                end
            end
        end            
    end

    always_ff @(posedge clk_i) begin
        for (int unsigned arch_idx = 0; arch_idx < C_ARCH_REG_NUM; arch_idx++) begin
            if (rst_i) begin
                if (arch_idx == 0) begin
                    amt_entry[arch_idx].amt_tag <=  `SD 'd0;
                end else begin
                    amt_entry[arch_idx].amt_tag <=  `SD arch_idx + (thread_idx_i << C_ARCH_REG_IDX_WIDTH) - thread_idx_i;
                end
            end else begin
                for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++) begin
                    if ((rob_amt_i[rt_idx].wr_en == 1'b1) && (rob_amt_i[rt_idx].arch_reg == arch_idx)) begin
                        amt_entry[arch_idx].amt_tag <=  `SD rob_amt_i[rt_idx].phy_reg;
                    end
                end
            end
        end
    end
    
endmodule