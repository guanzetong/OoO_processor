/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  BC.sv                                               //
//                                                                     //
//  Description :  Broadcaster. Broadcast results from FU to CDB.      //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


module BC #( 
    parameter   C_FU_NUM             =   `FU_NUM                 ,
    parameter   C_CDB_NUM            =   `CDB_NUM                ,
    parameter   C_PE_OUT_WIDTH       =   $clog2(C_FU_NUM)        
)(
// debug start
    // output   logic [C_CDB_NUM-1:0]          mux_valid_o         ,
    // output   logic [C_FU_NUM-1:0]           mask_o              ,
    // output   logic                          queued_o            ,
// debug end

    input   logic                            clk_i               ,   // Clock
    input   logic                            rst_i               ,   // Reset
    input   FU_BC  [C_FU_NUM-1:0]            fu_bc_i             ,
    output  BC_FU  [C_FU_NUM-1:0]            bc_fu_o             ,
    output  CDB    [C_CDB_NUM-1:0]           cdb_o            ,
    output  BC_PRF [C_CDB_NUM-1:0]           bc_prf_o            


);

    logic [C_FU_NUM-1:0] valid;
    logic [C_FU_NUM-1:0] mask;
    logic [C_FU_NUM-1:0] broadcasted;
    logic queued;

    

    logic [C_CDB_NUM-1:0][C_PE_OUT_WIDTH-1:0] mux_select_enc;
    logic [C_CDB_NUM-1:0][C_FU_NUM-1:0] mux_select_dec;
    logic [C_CDB_NUM-1:0] mux_valid;


    
    genvar i;
    generate
        for(i = 0; i < C_FU_NUM; i++) begin                                    : gen_FU_IO
            assign valid[i] = fu_bc_i[i].valid;
            assign bc_fu_o[i].broadcasted = broadcasted[i];
        end
    endgenerate

    select_decoder sd_0 [(C_CDB_NUM-1):0] (
        .enc_i(mux_select_enc),
        .valid_i(mux_valid),
        .bit_o(mux_select_dec)
    );

    multi_bit_and_or mbao_0 (
        .and_i(mux_valid),
        .or_i(mux_select_dec),
        .result_o(broadcasted)
    );

    bc_pe_mult pe_0(
        .bit_i(valid & mask),
        .enc_o(mux_select_enc),
        .valid_o(mux_valid)
    );
    
    multi_bit_or mbo_0 (
        .or_i(valid & mask & (~broadcasted)),
        .result_o(queued)
    );
    // assign queued = (valid & mask & (~broadcasted)) || (valid & mask & (~broadcasted));

    // mask broadcasted inputs if queued to increase fairness
    always_ff @(posedge clk_i) begin
        if(queued) begin
            mask <= mask & (~broadcasted);
        end
        else begin
            mask <=  {C_FU_NUM{1'b1}};
        end
    end

    generate
        for(i = 0; i < C_CDB_NUM; i++) begin                                   : gen_CDB_IO
            assign cdb_o[i].valid      = mux_valid[i] ;
            assign cdb_o[i].pc         = mux_valid[i] ? fu_bc_i[mux_select_enc[i]].pc         : 'b0;
            assign cdb_o[i].tag        = mux_valid[i] ? fu_bc_i[mux_select_enc[i]].tag        : 'b0;
            assign cdb_o[i].rob_idx    = mux_valid[i] ? fu_bc_i[mux_select_enc[i]].rob_idx    : 'b0;
            assign cdb_o[i].thread_idx = mux_valid[i] ? fu_bc_i[mux_select_enc[i]].thread_idx : 'b0;
            assign cdb_o[i].br_result  = mux_valid[i] ? fu_bc_i[mux_select_enc[i]].br_result  : 'b0;
            assign cdb_o[i].br_target  = mux_valid[i] ? fu_bc_i[mux_select_enc[i]].br_target  : 'b0;
        end
    endgenerate

    generate
        for(i = 0; i < C_CDB_NUM; i++) begin                                   : gen_PRF_IO
            assign bc_prf_o[i].wr_addr    = mux_valid[i] ? fu_bc_i[mux_select_enc[i]].tag        : 'b0;
            assign bc_prf_o[i].data_in    = mux_valid[i] ? fu_bc_i[mux_select_enc[i]].rd_value   : 'b0;
            assign bc_prf_o[i].wr_en      = mux_valid[i] ;
        end
    endgenerate

// debug start
    // assign mux_valid_o = mux_valid;
    // assign mask_o = mask;
    // assign queued_o = queued;
// debug end


endmodule // BC




module select_decoder #(
    parameter   C_OUT_WIDTH =   `FU_NUM                  ,
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



module multi_bit_or #(
    parameter   C_IN_NUM_1  =   `FU_NUM
)(
    input   logic   [C_IN_NUM_1-1:0]    or_i   ,
    output  logic                       result_o   
);

// ====================================================================
// RTL Logic Start
// ====================================================================
    logic [C_IN_NUM_1-1:0]    prev_result;
    genvar i;
    generate
        for(i = 0; i < C_IN_NUM_1; i++) begin                                  : gen_multi_bit_or_i
            if(i == 0) begin                                                   : gen_multi_bit_or_i_0
                assign prev_result[i] = or_i[i];
            end
            else begin                                                         : gen_multi_bit_or_i_plus
                assign prev_result[i] = prev_result[i-1] | or_i[i];
            end
        end
    endgenerate
    assign  result_o = prev_result[C_IN_NUM_1-1];
    

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule


module multi_bit_and_or #(
    parameter   C_IN_NUM_1  =   `CDB_NUM,
    parameter   C_IN_NUM_2  =   `FU_NUM
)(
    input   logic   [C_IN_NUM_1-1:0]                    and_i   ,
    input   logic   [C_IN_NUM_1-1:0][C_IN_NUM_2-1:0]    or_i   ,
    output  logic   [C_IN_NUM_2-1:0]                    result_o   
);

// ====================================================================
// RTL Logic Start
// ====================================================================
    logic [C_IN_NUM_1-1:0][C_IN_NUM_2-1:0]    prev_result;
    genvar i;
    genvar j;
    generate
        for(j = 0; j < C_IN_NUM_2; j++) begin                                  : gen_multi_bit_and_or_j
            for(i = 0; i < C_IN_NUM_1; i++) begin                              : gen_multi_bit_and_or_i
                if(i == 0) begin                                               : gen_multi_bit_and_or_i_0
                    assign prev_result[i][j] = or_i[i][j] & and_i[i];
                end
                else begin                                                     : gen_multi_bit_and_or_i_plus
                    assign prev_result[i][j] = prev_result[i-1][j] | (or_i[i][j]  & and_i[i]);
                end
            end
            assign  result_o[j] = prev_result[C_IN_NUM_1-1][j];
        end
    endgenerate
    

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule


module bc_pe_mult #(
    parameter   C_IN_WIDTH  =   `FU_NUM                  ,
    parameter   C_OUT_WIDTH =   $clog2(C_IN_WIDTH)      ,
    parameter   C_OUT_NUM   =   `CDB_NUM
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
        for (i = 0; i < C_OUT_NUM; i++) begin : gen_output
            // Generate the input to each Priority Encoder
            // The bits with higher priority should be masked
            if (i == 0) begin : gen_input
                assign  pe_bit_i[i] =   bit_i   ;
            end else begin :gb_3
                assign  pe_bit_i[i] =   pe_bit_i[i-1] & (~mask[i-1]);
            end
            // Instantiate Priority Encoders for each output
            pe #(
                .C_IN_WIDTH     (C_IN_WIDTH     ),
                .C_OUT_WIDTH    (C_OUT_WIDTH    )
            ) pe_inst (
                .bit_i          (pe_bit_i[i]    ),
                .enc_o          (enc_o[i]       ),
                .valid_o        (valid_o[i]     )
            );

            // Instantiate binary_decoders for masks generation
            if (i < C_OUT_NUM-1) begin : gen_mask
                binary_decoder #(
                    .C_OUT_WIDTH    (C_IN_WIDTH     ),
                    .C_IN_WIDTH     (C_OUT_WIDTH    )
                ) binary_decoder_inst (
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




