`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module pe_mult_svsim #(
    parameter   C_IN_WIDTH  =   32                  ,
    parameter   C_OUT_WIDTH =   $clog2(C_IN_WIDTH)  ,
    parameter   C_OUT_NUM   =   3
) (
    input   logic   [C_IN_WIDTH-1:0]                    bit_i       ,
    output  logic   [C_OUT_NUM-1:0][C_OUT_WIDTH-1:0]    enc_o       ,
    output  logic   [C_OUT_NUM-1:0]                     valid_o 
);

    

  pe_mult pe_mult( {>>{ bit_i }}, {>>{ enc_o }}, {>>{ valid_o }} );
endmodule
`endif
