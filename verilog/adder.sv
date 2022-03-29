module adder #(
    parameter   IN_NUM      =   8,
    parameter   IN_WIDTH    =   8,
    parameter   OUT_WIDTH   =   32
) (
    input   logic   [IN_NUM-1:0][IN_WIDTH-1:0]  in  ,
    output  logic   [OUT_WIDTH-1:0]             out     
);

    always_comb begin
        out     =   0;
        for (int i = 0; i < IN_NUM; i++) begin
            out =   out + in[i];
        end
    end

endmodule