

module bc_pe_mult #(
    parameter   C_IN_WIDTH  =   FU_NUM                  ,
    parameter   C_OUT_WIDTH =   $clog2(C_IN_WIDTH)  ,
    parameter   C_OUT_NUM   =   CDB_NUM
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
            pe #(
                .C_IN_WIDTH     (C_IN_WIDTH     ),
                .C_OUT_WIDTH    (C_OUT_WIDTH    )
            ) pe_inst (
                .bit_i          (pe_bit_i[i]    ),
                .enc_o          (enc_o[i]       ),
                .valid_o        (valid_o[i]     )
            );

            // Instantiate binary_decoders for masks generation
            if (i < C_OUT_NUM-1) begin
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



module broadcaster ( 
    parameter   C_ALU_NUM            =   `ALU_NUM         ,
    parameter   C_MULT_NUM           =   `MULT_NUM        ,
    parameter   C_BRANCH_NUM            =   `BRANCH_NUM         ,
    parameter   C_LOAD_NUM     =   `LOAD_NUM  ,
    parameter   C_STORE_NUM      =   `STORE_NUM   ,
    parameter   C_FU_NUM         =   `FU_NUM,
    parameter   C_CDB_NUM         =   `CDB_NUM,
    parameter   C_PE_OUT_WIDTH =   $clog2(C_FU_NUM)  

)(
    input   logic                            clk_i               ,   // Clock
    input   logic                            rst_i               ,   // Reset

    output   logic [C_ALU_NUM-1:0]            alu_reset_o,
    input  logic [C_ALU_NUM-1:0]            alu_valid_i,
    input  logic [C_ALU_NUM-1:0][`XLEN-1:0] alu_result_i,

    output   logic [C_MULT_NUM-1:0]            mult_reset_o,
    input  logic [C_MULT_NUM-1:0]            mult_valid_i,
    input  logic [C_MULT_NUM-1:0][`XLEN-1:0] mult_result_i,

    output   logic [C_BRANCH_NUM-1:0]            branch_reset_o,
    input  logic [C_BRANCH_NUM-1:0]            branch_valid_i,
    input  logic [C_BRANCH_NUM-1:0][`XLEN-1:0] branch_result_i,
    input  logic [C_BRANCH_NUM-1:0]            take_branch_i,

    output   logic [C_LOAD_NUM-1:0]             load_reset_o,
    input  logic [C_LOAD_NUM-1:0]             load_valid_i,
    input  logic [C_LOAD_NUM-1:0][`XLEN-1:0]  load_result_i,

    output   logic [C_STORE_NUM-1:0]             store_reset_o,
    input  logic [C_STORE_NUM-1:0]             store_valid_i,
    input  logic [C_LOAD_NUM-1:0][`XLEN-1:0]   store_result_i,
    output logic [C_CDB_NUM-1:0]               cdb_write
);
    logic [C_FU_NUM-1:0] valid;
    logic [C_CDB_NUM-1:0][C_PE_OUT_WIDTH-1:0] mux_select;
    logic [C_CDB_NUM-1:0] mux_valid;
    logic [C_FU_NUM-1:0][`XLEN-1:0]  result ;

    bc_pe_mult pe_0(
        .bit_i(valid),
        .enc_o(mux_select),
        .valid_o(mux_valid)
    );
    assign valid = {alu_valid_i, mult_valid_i, branch_valid_i, load_valid_i, store_valid_i};
    assign result = {alu_result_i, mult_result_i, branch_result_i, load_result_i, store_result_i};
    for (i = 0; i < C_CDB_NUM; i++)begin
        cdb_write[i] = result[mux_select[i]] ;
    end
    


endmodule // alu

