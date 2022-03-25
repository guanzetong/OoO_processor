module pe_mult_tb;

    parameter   C_IN_WIDTH  =   32                  ;
    parameter   C_OUT_WIDTH =   $clog2(C_IN_WIDTH)  ;
    parameter   C_OUT_NUM   =   3                   ;

    logic   [C_IN_WIDTH-1:0]                    bit_i   ;
    logic   [C_OUT_NUM-1:0][C_OUT_WIDTH-1:0]    enc_o   ;
    logic   [C_OUT_NUM-1:0]                     valid_o ;

    pe_mult #(
        .C_IN_WIDTH (32     ),
        .C_OUT_NUM  (4           )
    ) dp_pe (
        .bit_i      (bit_i              ),
        .enc_o      (enc_o              ),
        .valid_o    (valid_o            )
    );

    initial begin
        repeat(50) begin
            #5;
            bit_i   =   $urandom;
            #5;
            $display("Time=%0t, Input=%32b, Output0=%0d|%0b, Output1=%0d|%0b, Output2=%0d|%0b",
            $time, bit_i, enc_o[0], valid_o[0], enc_o[1], valid_o[1], enc_o[2], valid_o[2]);
        end
    end
endmodule