/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  binary_decoder.sv                                   //
//                                                                     //
//  Description :  binary_decoder                                      // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module binary_decoder #(
    parameter   C_OUT_WIDTH =   32                  ,
    parameter   C_IN_WIDTH  =   $clog2(C_IN_WIDTH)
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
