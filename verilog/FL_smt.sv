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
    output  FL_DP                               fl_dp_o
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
    FL_smt_ENTRY    [C_FL_ENTRY_NUM-1:0]                fl_entry            ;   // Freelist entry

    logic                                               rt_check          ;
    logic           [C_DP_NUM_WIDTH-1:0]                dp_num              ;   // actual dispatched num

    logic           [C_FL_ENTRY_NUM-1:0]                entry_valid_concat  ;
    logic           [C_DP_NUM-1:0][C_FL_IDX_WIDTH-1:0]  fl_dp_idx           ;
    logic           [C_DP_NUM-1:0]                      fl_dp_valid         ;


// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// FL default set & Rollback manipulation as sequential logic
// --------------------------------------------------------------------
    // Initialization
    always_ff @(posedge clk_i) begin
        //RESET : default set as all tags are available;
        if (rst_i) begin
            for(int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++)begin
                fl_entry[fl_idx].valid <=  `SD 'd1;
                fl_entry[fl_idx].thread_idx <=  `SD 'd0;
                fl_entry[fl_idx].tag   <=  `SD fl_idx + C_ARCH_REG_NUM; 
            end//for
        end//if

        //ROLLBACK : set mispredicted thread's valid 'b1;
        else if (br_mis_i.valid)begin
            for(int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++)begin
            //check the roolback status and set relevant tag in flight valid
                for(int unsigned thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++)begin
                    //check each thread
                    if(!br_mis_i.valid[thread_idx] && !fl_entry[fl_idx].valid)begin
                        for(int unsigned rt_idx; rt_idx < C_RT_NUM; rt_idx++)begin
                        //check each ROB_FL_I
                            if((rt_idx < rob_fl_i[thread_idx].rt_num) && (fl_entry[fl_idx].thread == thread_idx) && (fl_entry[fl_idx].tag == rob_fl_i[thread_idx].tag[rt_idx]))begin
                                fl_entry[fl_idx].tag    <=  `SD rob_fl_i[thread_idx].tag_old[rt_idx];
                                fl_entry[fl_idx].valid  <=  `SD 'd1;
                            end//if
                            //RT available && Corresponding Thread & Tag
                        end//for rt_idx
                    end//if
                    // RETIRE irrelevant threads' tags normally

                    if(br_mis_i.valid[thread_idx] && !fl_entry[fl_idx].valid)begin
                        for(int unsigned rt_idx; rt_idx < C_RT_NUM; rt_idx++)begin
                        //check each ROB_FL_I
                            if((rt_idx < rob_fl_i[thread_idx].rt_num - 1) && (fl_entry[fl_idx].thread == thread_idx) && (fl_entry[fl_idx].tag == rob_fl_i[thread_idx].tag[rt_idx]))begin
                                fl_entry[fl_idx].tag    <=  `SD rob_fl_i[thread_idx].tag_old[rt_idx];
                                fl_entry[fl_idx].valid  <=  `SD 'd1;
                            end//if
                            //RT available && Corresponding Thread & Tag
                        end//for rt_idx
                    end//if
                    // RETIRE relevant threads' tags seperately

                    for(int unsigned rt_idx; rt_idx < C_RT_NUM - 1; rt_idx++)begin
                    //check each ROB_FL_I
                        if((rt_idx < rob_fl_i[thread_idx].rt_num) && (fl_entry[fl_idx].thread == thread_idx) && (fl_entry[fl_idx].tag == rob_fl_i[thread_idx].tag[rt_idx]))begin
                            fl_entry[fl_idx].tag    <=  `SD rob_fl_i[thread_idx].tag_old[rt_idx];
                        end//if
                    end//for rt_idx
                end// for thread_idx
                if(br_mis_i.valid[fl_entry[fl_idx].thread_idx] && !fl_entry[fl_idx].valid)begin
                    fl_entry[fl_idx].valid <=  `SD 'd1; 
                end//if
                //set corresponding thread's valid to 1 when ROLLBACK happens
            end//for fl_idx
        end//else if for ROLLBACK

        //RETIRE : get the used tags' from differnt thread's ROB valid set to 'b1;
        else if(rt_check)begin
            for(int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++)begin
            //check each entry
                if(!fl_entry[fl_idx].valid)begin
                    for(int unsigned thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++)begin
                        //check each thread
                        for(int unsigned rt_idx; rt_idx < C_RT_NUM; rt_idx++)begin
                        //check each ROB_FL_I
                            if((rt_idx < rob_fl_i[thread_idx].rt_num) && (fl_entry[fl_idx].thread == thread_idx) && (fl_entry[fl_idx].tag == rob_fl_i[thread_idx].tag[rt_idx]))begin
                                fl_entry[fl_idx].tag    <=  `SD rob_fl_i[thread_idx].tag_old[rt_idx];
                                fl_entry[fl_idx].valid  <=  `SD 'd1;
                            end//if
                            //RT available && Corresponding Thread & Tag
                        end//for rt_idx
                    end//for thread_idx
                end//if
            end//for fl_idx
        end//esle if for RETIRE 

        //DISPATCH : send the unused tags' to DP and set 'b0;
        else(dp_fl_i.dp_num)begin
            for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
            //fl_dp_o.tag[dp_idx] = 'b0;
            // Dispatch
                if(fl_dp_valid[dp_idx] && (dp_idx < dp_num))begin
                    fl_dp_o.tag[fl_dp_idx[dp_idx]]          <=  `SD fl_entry[fl_dp_idx[dp_idx]].tag;
                    fl_entry[fl_dp_idx[dp_idx]].valid       <=  `SD 'd0;
                    fl_entry[fl_dp_idx[dp_idx]].thread_idx  <=  `SD dp_fl_i.thread_idx;
                end//if
            end//for dp_idx
        end//else for Dispatch
    end//ff

    always_comb begin
        dp_num = dp_fl_i.dp_num;
        for (int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++) begin
            entry_valid_concat[fl_idx]   =   fl_entry[fl_idx].valid;
        end
        rt_check = 'b0;
        rt_num = 'b0;
        for (int unsigned thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++) begin
            rt_num = rob_fl_i[thread_idx].rt_num + rt_num;
            if(rob_fl_i[thread_idx].rt_num)begin
                rt_check = 'b1;
            end
        end
    end

    if (rt tag == entry tag)
        entry tag <= rt tag_old
        entry valid <= 1'b1
    else if (br_mis.valid [entry.thread_idx] == 1)
        entry tag<= entry tag
        entry valid <= 1'b1

// --------------------------------------------------------------------
// Calculation of avail_num 
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            fl_dp_o.avail_num   <=   `SD C_FL_ENTRY_NUM ;
        end//if
        else begin
            fl_dp_o.avail_num   <=   `SD fl_dp_o.avail_num + rt_num - dp_num;
        end  
    end//ff
    //available nums are the ones has vaild value to be dispatched

    pe_mult_fl pe_mult_fl_inst (
        .bit_i      (entry_valid_concat ),
        .enc_o      (fl_dp_idx          ),
        .valid_o    (fl_dp_valid        )
    );

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
