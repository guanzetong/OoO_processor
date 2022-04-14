/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  FL_smt.sv                                           //
//                                                                     //
//  Description :  The edition which Freelist supports SMT             // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module FL_smt #(
    parameter   C_FL_ENTRY_NUM  =   `FL_ENTRY_NUM       ,
    parameter   C_THREAD_NUM    =   `THREAD_NUM         ,
    parameter   C_DP_NUM        =   `DP_NUM             ,
    parameter   C_RT_NUM        =   `RT_NUM             ,
    parameter   C_ARCH_REG_NUM  =   `ARCH_REG_NUM       ,
    parameter   C_PHY_REG_NUM   =   `PHY_REG_NUM        ,
    parameter   C_TAG_IDX_WIDTH =   `TAG_IDX_WIDTH      ,
    parameter   C_FL_IDX_WIDTH  =   $clog2(C_FL_ENTRY_NUM)
) (
    input   logic                               clk_i       ,   //  Clock
    input   logic                               rst_i       ,   //  Reset
    input   BR_MIS                              br_mis_i    ,  
    input   DP_FL                               dp_fl_i     ,
    input   ROB_FL      [C_THREAD_NUM-1:0]      rob_fl_i    ,
    output  FL_DP                               fl_dp_o     ,
    input   logic                               exception_i ,
    //test
    output  FL_ENTRY                        fl_mon_o
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    // localparam  C_FL_IDX_WIDTH  =   $clog2(C_FL_ENTRY_NUM);
    localparam  C_FL_NUM_WIDTH  =   $clog2(C_FL_ENTRY_NUM+1);
    localparam  C_DP_NUM_WIDTH  =   $clog2(C_DP_NUM+1)      ;
    localparam  C_RT_NUM_WIDTH  =   $clog2(C_RT_NUM+1)      ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // Freelist array
    FL_ENTRY        [C_FL_ENTRY_NUM-1:0]                fl_entry            ;   // Freelist entry
    logic           [C_RT_NUM_WIDTH-1:0]                rt_num              ;

    // Dispatch entry select
    logic           [C_FL_ENTRY_NUM-1:0]                entry_valid_concat  ;
    logic           [C_DP_NUM-1:0][C_FL_IDX_WIDTH-1:0]  fl_dp_idx           ;
    logic           [C_DP_NUM-1:0]                      fl_dp_valid         ;
    logic           [C_FL_ENTRY_NUM-1:0]                dp_sel              ;
    logic           [C_DP_NUM-1:0]                      dp_valid            ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   pe_mult_fl
// Description  :   Priority Encoder with multiple outputs
// --------------------------------------------------------------------
    pe_mult_fl pe_mult_fl_inst (
        .bit_i      (entry_valid_concat ),
        .enc_o      (fl_dp_idx          ),
        .valid_o    (fl_dp_valid        )
    );
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// FL default set & Rollback manipulation as sequential logic
// --------------------------------------------------------------------
    // Initialization
    always_ff @(posedge clk_i) begin
        for(int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++)begin
            //RESET : default set as all tags are available;
            if (rst_i || exception_i) begin
                    fl_entry[fl_idx].valid      <=  `SD 'd1;
                    fl_entry[fl_idx].thread_idx <=  `SD 'd0;
                    fl_entry[fl_idx].tag        <=  `SD fl_idx + C_ARCH_REG_NUM; 
            end//if
            // IF the entry is in-flight
            else if (!fl_entry[fl_idx].valid) begin
                // IF   the corresponding thread needs roll-back
                // ->   Assert its valid bit
                if (br_mis_i.valid[fl_entry[fl_idx].thread_idx]) begin
                    fl_entry[fl_idx].valid  <=  `SD 'd1;
                end
                // ELSE the corresponding thread doesn't need roll-back
                // ->   Check for retirement
                else begin
                    for(int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++)begin
                        // The retirement matches this entry
                        if((rt_idx < rob_fl_i[fl_entry[fl_idx].thread_idx].rt_num) 
                        && (fl_entry[fl_idx].tag == rob_fl_i[fl_entry[fl_idx].thread_idx].tag[rt_idx]))begin
                            fl_entry[fl_idx].valid      <=  `SD 'd1;
                            fl_entry[fl_idx].thread_idx <=  `SD 'd0;
                            fl_entry[fl_idx].tag        <=  `SD rob_fl_i[fl_entry[fl_idx].thread_idx].tag_old[rt_idx];
                        end//if
                    end//for rt_idx
                end
            end
            // IF   the entry is selected for dispatch
            // ->   send the unused tags to DP and set 'b0;
            else if (dp_sel[fl_idx]) begin
                fl_entry[fl_idx].valid       <=  `SD 'd0;
                fl_entry[fl_idx].thread_idx  <=  `SD dp_fl_i.thread_idx;
            end//else for Dispatch
        end//for fl_idx
    end//ff

    always_comb begin
        rt_num = 'b0;
        for (int unsigned thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++) begin
            rt_num = rob_fl_i[thread_idx].rt_num + rt_num;
        end
    end

    assign fl_mon_o = fl_entry;

// --------------------------------------------------------------------
// Dispatch Select
// --------------------------------------------------------------------
    // dp_sel is a per-entry signal to notify the entry for a newly
    // dispatched instruction.
    // dp_valid is the indicator of valid dispatch
    always_comb begin
        // Concatenate all the valid bits of entries for Priority Encoder
        for (int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++) begin
            entry_valid_concat[fl_idx]   =   fl_entry[fl_idx].valid;
        end

        // Assert dp_valid according to dp_num and Priority Encoder output
        dp_valid    =   'b0;
        for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
            if ((fl_dp_valid[dp_idx] == 1'b1) && (dp_idx < dp_fl_i.dp_num)) begin
                dp_valid[dp_idx]    =   1'b1;
            end
        end

        // Assert Per-entry dp_sel
        dp_sel      =   'b0;
        for (int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++) begin
            for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
                if ((fl_dp_idx[dp_idx] == fl_idx) && dp_valid[dp_idx]) begin
                    dp_sel[fl_idx]   =   1'b1    ;
                end
            end
        end
    end
    
// --------------------------------------------------------------------
// Calculation of avail_num 
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i || exception_i) begin
            fl_dp_o.avail_num   <=   `SD C_FL_ENTRY_NUM ;
        end//if
        else begin
            fl_dp_o.avail_num   <=   `SD fl_dp_o.avail_num + rt_num - dp_fl_i.dp_num;
        end  
    end//ff
    //available nums are the ones has vaild value to be dispatched

// --------------------------------------------------------------------
// Output dispatch tags
// --------------------------------------------------------------------
    always_comb begin
        fl_dp_o.tag     =   fl_dp_idx;
    end
// ====================================================================
// RTL Logic End
// ====================================================================

endmodule


/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  pe_mult.sv                                          //
//                                                                     //
//  Description :  Priority Encoder with multiple outputs,             //
//                 LSB has highest priority                            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module pe_mult_fl #(
    parameter   C_IN_WIDTH  =   `FL_ENTRY_NUM       ,
    parameter   C_OUT_WIDTH =   $clog2(C_IN_WIDTH)  ,
    parameter   C_OUT_NUM   =   `DP_NUM
) (
    input   logic   [C_IN_WIDTH-1:0]                    bit_i       ,
    output  logic   [C_OUT_NUM-1:0][C_OUT_WIDTH-1:0]    enc_o       ,   
    output  logic   [C_OUT_NUM-1:0]                     valid_o 
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_OUT_NUM-1:0][C_IN_WIDTH-1:0]     pe_bit_i    ;
    logic   [C_OUT_NUM-2:0][C_IN_WIDTH-1:0]     mask        ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    genvar i;
    generate
        for (i = 0; i < C_OUT_NUM; i++) begin
            // Generate the input to each Priority Encoder
            // The bits with higher priority should be masked
            if (i == 0) begin
                assign  pe_bit_i[i] =   bit_i   ;
            end else begin
                assign  pe_bit_i[i] =   pe_bit_i[i-1] & (~mask[i-1]);
            end
            // Instantiate Priority Encoders for each output
            pe_fl #(
                .C_IN_WIDTH     (C_IN_WIDTH     ),
                .C_OUT_WIDTH    (C_OUT_WIDTH    )
            ) pe_fl_inst (
                .bit_i          (pe_bit_i[i]    ),
                .enc_o          (enc_o[i]       ),
                .valid_o        (valid_o[i]     )
            );

            // Instantiate binary_decoders for masks generation
            if (i < C_OUT_NUM-1) begin
                binary_decoder_fl #(
                    .C_OUT_WIDTH    (C_IN_WIDTH     ),
                    .C_IN_WIDTH     (C_OUT_WIDTH    )
                ) binary_decoder_fl_inst (
                    .enc_i          (enc_o[i]       ),
                    .valid_i        (valid_o[i]     ),
                    .bit_o          (mask[i]        )
                );
            end
        end
    endgenerate
// ====================================================================
// RTL Logic End
// ====================================================================

endmodule


module binary_decoder_fl #(
    parameter   C_OUT_WIDTH =   32                  ,
    parameter   C_IN_WIDTH  =   $clog2(C_OUT_WIDTH)
)(
    input   logic   [C_IN_WIDTH-1:0]    enc_i   ,
    input   logic                       valid_i ,
    output  logic   [C_OUT_WIDTH-1:0]   bit_o   
);

// ====================================================================
// RTL Logic Start
// ====================================================================

    assign  bit_o   =   valid_i ? {{(C_OUT_WIDTH-1){1'b0}},1'b1} << enc_i
                                : {C_OUT_WIDTH{1'b0}};

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule

module pe_fl #(
    parameter   C_IN_WIDTH  =   32                  ,
    parameter   C_OUT_WIDTH =   $clog2(C_IN_WIDTH)
)(
    input   logic   [C_IN_WIDTH-1:0]    bit_i   ,
    output  logic   [C_OUT_WIDTH-1:0]   enc_o   ,
    output  logic                       valid_o 
);

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Encoding
// --------------------------------------------------------------------
    always_comb begin
        enc_o   =   0;
        for (int i = C_IN_WIDTH-1; i >=0 ; i--) begin
            if (bit_i[i]) begin
                enc_o   =   i;
            end
        end
    end

// --------------------------------------------------------------------
// Valid
// --------------------------------------------------------------------
    assign  valid_o =   bit_i ? 1'b1 : 1'b0;

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
