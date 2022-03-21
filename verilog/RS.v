/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  RS.sv                                         //
//                                                                     //
//  Description :  RS                                            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module RS #(
    parameter   C_RS_ENTRY_NUM  =   `RS_ENTRY_NUM   ,
    parameter   C_DP_NUM        =   `DP_NUM         ,
    parameter   C_IS_NUM        =   `IS_NUM         ,
    parameter   C_ALU_NUM       =   `ALU_NUM        ,
    parameter   C_MULT_NUM      =   `MULT_NUM       ,
    parameter   C_BR_NUM        =   `BR_NUM         ,
    parameter   C_LOAD_NUM      =   `LOAD_NUM       ,
    parameter   C_STORE_NUM     =   `STORE_NUM      ,
    parameter   C_FU_NUM        =   `FU_NUM         
) (
    input   logic                       clk_i           ,   //  Clock
    input   logic                       rst_i           ,   //  Reset
    output  RS_DP                       rs_dp_o         ,
    input   DP_RS                       dp_rs_i         ,
    input   CDB     [C_CDB_NUM-1:0]     cdb_i           ,
    output  RS_IB   [C_FU_NUM-1:0]      rs_ib_o         ,
    input   IB_RS   [C_FU_NUM-1:0]      ib_rs_i         ,
    output  RS_PRF  [C_IS_NUM-1:0]      rs_prf_o        ,
    input   PRF_RS  [C_IS_NUM-1:0]      prf_rs_i        ,
    input   BR_MIS                      br_mis_i        
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_RS_IDX_WIDTH  =   $clog2(C_RS_ENTRY_NUM);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    RS_ENTRY    [C_RS_ENTRY_NUM-1:0]            rs_array                ;

    // Dispatch
    logic   [C_RS_ENTRY_NUM-1:0]                entry_empty_concat      ;
    logic   [C_DP_NUM-1:0][C_RS_IDX_WIDTH-1:0]  dp_entry_idx            ;
    logic   [C_DP_NUM-1:0]                      dp_pe_valid             ;
    DEC_INST    [C_RS_ENTRY_NUM-1:0]            dp_switch               ;
    logic   [C_RS_ENTRY_NUM-1:0]                dp_sel                  ;

    // Complete
    logic   [C_RS_ENTRY_NUM-1:0]                cp_sel_tag1             ;
    logic   [C_RS_ENTRY_NUM-1:0]                cp_sel_tag2             ;

    // Issue
    logic   [C_RS_ENTRY_NUM-1:0]                is_ready                ;
    logic   [C_IS_NUM-1:0][C_RS_IDX_WIDTH-1:0]  is_entry_idx            ;
    logic   [C_IS_NUM-1:0]                      is_pe_valid             ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   dp_pe
// Description  :   Priority Encoder with multiple outputs
//                  to select the entries allocated for dispatch.
// --------------------------------------------------------------------
    pe_mult #(
        .C_IN_WIDTH (C_RS_ENTRY_NUM     ),
        .C_OUT_NUM  (C_DP_NUM           )
    ) dp_pe (
        .bit_i      (entry_empty_concat ),
        .enc_o      (dp_entry_idx       ),
        .valid_o    (dp_pe_valid        )
    );
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// Module name  :   dp_pe
// Description  :   Priority Encoder with multiple outputs
//                  to select the entries allocated for dispatch.
// --------------------------------------------------------------------
    pe_mult #(
        .C_IN_WIDTH (C_RS_ENTRY_NUM     ),
        .C_OUT_NUM  (C_IS_NUM           )
    ) is_pe (
        .bit_i      (is_ready           ),
        .enc_o      (is_entry_idx       ),
        .valid_o    (is_pe_valid        )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Concatenate Valid bit of each entry
// --------------------------------------------------------------------
    always_comb begin
        for (int i = 0; i < C_RS_ENTRY_NUM; i++) begin
            entry_empty_concat[i]   =   ~rs_array[i].valid;
        end
    end

// --------------------------------------------------------------------
// Dispatch Switch
// --------------------------------------------------------------------
    always_comb begin
        dp_sel      =   'b0;
        dp_switch   =   'b0;
        for (int entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            for (int dp_idx = 0; dp_idx < C_IS_NUM; dp_idx++) begin
                if ((dp_entry_idx[dp_idx] == entry_idx) 
                    && (dp_pe_valid[dp_idx] == 1'b1)) begin
                    dp_sel   [entry_idx]    =   1'b1                    ;
                    dp_switch[entry_idx]    =   dp_rs_i.dec_inst[dp_idx];
                end
            end
        end
    end

// --------------------------------------------------------------------
// Comparator network for Complete
// --------------------------------------------------------------------
    // Search for matched tag1
    always_comb begin
        cp_sel_tag1 =   'b0;
        for (int entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            for (int cp_idx = 0; cp_idx < C_IS_NUM; cp_idx++) begin
                // Compare tag1 and thread_idx
                if ((cdb_i[cp_idx].valid == 1'b1) && 
                    (cdb_i[cp_idx].tag == rs_array[entry_idx].dec_inst.tag1) && 
                    (cdb_i[cp_idx].thread_idx == rs_array[entry_idx].dec_inst.thread_idx)) begin
                    cp_sel_tag1[entry_idx]  =   1'b1;
                end
            end
        end
    end

    // Search for matched tag2
    always_comb begin
        cp_sel_tag2 =   'b0;
        for (int entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            for (int cp_idx = 0; cp_idx < C_IS_NUM; cp_idx++) begin
                // Compare tag1 and thread_idx
                if ((cdb_i[cp_idx].valid == 1'b1) && 
                    (cdb_i[cp_idx].tag == rs_array[entry_idx].dec_inst.tag2) && 
                    (cdb_i[cp_idx].thread_idx == rs_array[entry_idx].dec_inst.thread_idx)) begin
                    cp_sel_tag2[entry_idx]  =   1'b1;
                end
            end
        end
    end

// --------------------------------------------------------------------
// Ready-to-Issue Checker
// --------------------------------------------------------------------
    always_comb begin
        for (int entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; idx++) begin
            
        end
    end

    always_ff @(posedge clk_i) begin
        for (int idx = 0; idx < C_RS_ENTRY_NUM; idx++) begin
            // Reset
            if (rst_i) begin
                rs_array[idx]   <=  `SD 'b0;
            // Dispatch
            end else if (dp_sel[idx]) begin
                rs_array[idx].valid     <=  `SD 1'b1;
                rs_array[idx].dec_inst  <=  `SD dp_switch[idx];

                rs_array[idx].pc        <=  `SD dp_rs_i.pc[dp_ch_idx]
            // Complete
            end else if (rs_array[idx].valid && 
                cp_sel_tag1[idx] || cp_sel_tag2[idx]) begin
                // tag1_ready & tag2_ready should be independently set
                if (cp_sel_tag1[idx]) begin
                    rs_array[idx].dec_inst.tag1_ready   <=  `SD 1'b1;
                end
                if (cp_sel_tag2[idx]) begin
                    rs_array[idx].dec_inst.tag2_ready   <=  `SD 1'b1;
                end
            // Issue
            end else if () begin
                rs_array[idx]   <=  `SD 'b0;
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule


opa_select
opb_select
alu_func  
rd_mem    
wr_mem    
cond_br   
uncond_br 
halt      
illegal   
csr_op     from decoder

dp_rs_o.dec_inst[idx].pc <= fiq_dp_i.pc[idx]
