module adder_tb;
    logic                   clk ;
    logic                   rst ;
    logic   [8-1:0][8-1:0]  in  ;
    logic   [32-1:0]        out ;

    adder adder_inst (
        .in     (in),
        .out    (out)
    );
    
    initial begin
        clk =   0;
        forever begin
            #5 clk = ~clk;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            in  <=  0;
        end else begin
            in  <=  in + 1;
        end
    end

    initial begin
        rst =   1;
        #50;
        rst =   0;
        repeat(50) begin
            @(posedge clk);
            $display(out);
        end
        #50 $finish;
    end

endmodule