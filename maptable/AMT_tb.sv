module AMT_tb();

    parameter rt_num      = 2   ;
    parameter mt_entry    = 32  ;
    parameter phy_reg_idx = 2   ;

    logic clock;
    logic reset;
    logic rollback;
    DP_AMT       [rt_num-1:0]   amt_input ;
    AMT_OUTPUT   [mt_entry-1:0] amt_output;
    AMT_OUTPUT   [mt_entry-1:0] correct   ;

    AMT amt (
        .clk_i(clock),
        .rst_i(reset),
        .dp_amt_i(amt_input),

        .rollback_i(rollback),
        .amt_o(amt_output)
    );

  task check_amt_output;
    input  AMT_OUTPUT [mt_entry-1:0]   amt_output;
    input  AMT_OUTPUT [mt_entry-1:0]   correct;

    integer i;
  
    for (i=0; i<mt_entry; i++) begin
      if (amt_output[i].amt_tag == correct[i].amt_tag) begin
                  $display("@@@ entry    :%d", i);
        $display("amt tag      :%d",  amt_output[i].amt_tag);
        $display("correct tag, :%d",  correct[i].amt_tag);
      end else begin
        $display("@@@ entry    :%d", i);
        $display("amt tag      :%d",  amt_output[i].amt_tag);
        $display("correct tag, :%d",  correct[i].amt_tag);
        $display("@@@ Failed");
      end
    end
  endtask;


    always #5 clock = ~clock;

    initial begin
        clock = 0;
        reset = 1;
        rollback = 0;
        amt_input = 'b0;
        correct = 'b0;
        #10

        // ###########################
        // check initial values in maptable
        // ###########################
        @(negedge clock);
        reset = 0;
        // amt_input[0] = '{
        //     'd0,    // rd      
        //     'd7,    // tag_old 
        //     1       // wr_en   
        // };

        // amt_input[1] = '{
        //     'd1,    // rd      
        //     'd6,    // tag_old 
        //     1       // wr_en   
        // };

        check_amt_output(amt_output, correct);

        // @(negedge clock);
        // @(negedge clock);
        // rollback = 1;
        // @(negedge clock);
        // rollback = 0;
        // @(negedge clock);
        // rollback = 1;
        // amt_input[0] = '{
        //     'd4,    // rd      
        //     'd12,    // tag_old 
        //     1       // wr_en   
        // };

        // amt_input[1] = '{
        //     'd5,    // rd      
        //     'd13,    // tag_old 
        //     1       // wr_en   
        // };
        
        
        // #10
        // check_amt_output(amt_output, correct);

        // rrat_write_packet[0].write_en = 1;
        // rrat_write_packet[0].addr = 'd0;
        // rrat_write_packet[0].tag = 'd6;

        // rrat_write_packet[1].write_en = 1;
        // rrat_write_packet[1].addr = 'd1;
        // rrat_write_packet[1].tag = 'd7;

        // @(negedge clock);
        // rrat_write_packet[0].write_en = 0;
        // rrat_write_packet[1].write_en = 0;

        // @(negedge clock);
        // rrat_write_packet[0].write_en = 1;
        // rrat_write_packet[0].addr = 'd2;
        // rrat_write_packet[0].tag = 'd8;

        // rrat_write_packet[1].write_en = 3;
        // rrat_write_packet[1].addr = 'd3;
        // rrat_write_packet[1].tag = 'd9;

        // @(negedge clock);
        // rrat_write_packet[0].write_en = 0;
        // rrat_write_packet[1].write_en = 0;

        // @(negedge clock);
        // rollback = 1;

        // @(negedge clock);
        // rollback = 0;

        #100
        $finish;

    end

endmodule