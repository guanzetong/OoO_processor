/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  COD.sv                                              //
//                                                                     //
//  Description :  Calculate the Center Of Dispatched RS index.        // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module COD #(
    parameter   C_IN_NUM        =   `DP_NUM                 ,
    parameter   C_RS_ENTRY_NUM  =   `RS_ENTRY_NUM           ,
    parameter   C_DATA_WIDTH    =   $clog2(C_RS_ENTRY_NUM)
) (
    input   logic   [C_IN_NUM-1:0][C_DATA_WIDTH-1:0]  rs_idx_i        ,
    input   logic   [C_IN_NUM-1:0]                      valid_i         ,
    output  logic   [C_DATA_WIDTH-1:0]                cod_o       
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  SUM_WIDTH   =   (C_IN_NUM+1)/2 + C_DATA_WIDTH;
    localparam  LEVEL_NUM   =   $clog2(DP_NUM);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [SUM_WIDTH-1:0]                         sum         ;
    logic   [C_IN_NUM-1:0][C_DATA_WIDTH-1:0]      adder_in    ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   sub_module_name
// Description  :   sub module function
// --------------------------------------------------------------------


// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

    genvar i;
    generate
        for (i = 0; i < ; ) begin
            
        end
    endgenerate

// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
