`ifndef SYNTHESIS

//
// This is an automatically generated file from 
// dc_shell Version S-2021.06-SP1 -- Jul 13, 2021
//

// For simulation only. Do not modify.

module adder_svsim #(
    parameter   IN_NUM      =   8,
    parameter   IN_WIDTH    =   8,
    parameter   OUT_WIDTH   =   32
) (
    input   logic   [IN_NUM-1:0][IN_WIDTH-1:0]  in  ,
    output  logic   [OUT_WIDTH-1:0]             out     
);

    

  adder adder( {>>{ in }}, {>>{ out }} );
endmodule
`endif
