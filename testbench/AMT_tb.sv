module AMT_tb();

    parameter rt_num      = 2   ;
    parameter mt_entry    = 32  ;
    parameter phy_reg_idx = 5   ;

    logic clock;
    logic reset;
    logic rollback;
    ROB_AMT       [rt_num-1:0]   amt_input ;
    AMT_OUTPUT   [mt_entry-1:0] amt_output;
    AMT_OUTPUT   [mt_entry-1:0] correct   ;

    AMT amt (
        .clk_i(clock),
        .rst_i(reset),
        .rob_amt_i(amt_input),

        .rollback_i(rollback),
        .amt_o(amt_output)
    );

  task check_amt_output;
    input  AMT_OUTPUT [mt_entry-1:0]   amt_output;
    input  AMT_OUTPUT [mt_entry-1:0]   correct;

    integer i;
  
    for (i=0; i<mt_entry; i++) begin
      if (amt_output[i].amt_tag == correct[i].amt_tag) begin
        // $display("@@@ entry:%d", i);
        // $display("@@@ amt tag      :%d",  amt_output[i].amt_tag);
      end else begin
        $display("@@@ entry:%d", i);
        $display("@@@ amt tag      :%d",  amt_output[i].amt_tag);
        $display("@@@ correct tag, :%d",  correct[i].amt_tag);
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

        // ###########################
        // check initial values in maptable
        // ###########################
        
        @(negedge clock);
        reset = 0;
        $display("check for initial AMT entry");
        for (int i = 0; i < mt_entry; i++) begin
          correct[i].amt_tag = i;
        end

        check_amt_output(amt_output, correct);

        #5

        // ###########################
        // check for write enable trigger
        // ###########################
        $display("check for write enable triggered value");

        amt_input[0] = '{
            '1,    // wr_en      
            'd4,    // arch_reg 
            'd7       // physical reg   
        };

        amt_input[1] = '{
            '1,    // wr_en      
            'd5,    // arch_reg 
            'd8       // physical reg   
        };

        @(negedge clock);
        #20
        correct[4].amt_tag = 7;
        correct[5].amt_tag = 8;

        check_amt_output(amt_output, correct);
        #5

        // ###########################
        // check for rollback
        // ###########################

        $display("check for rollback (pull the value in the entry)");
        @(negedge clock);
        amt_input[0] = '{
            '0,    // wr_en      
            'd4,    // arch_reg 
            'd7       // physical reg   
        };

        amt_input[1] = '{
            '0,    // wr_en      
            'd5,    // arch_reg 
            'd8       // physical reg   
        };
        @(negedge clock);
        rollback = 1;

        @(negedge clock);
        rollback = 0;

        @(negedge clock);
        // rollback = 1;

        @(negedge clock);
        check_amt_output(amt_output, correct);
        // ###########################
        // check for rollback
        // ###########################
        $display("check for rollback");
        @(negedge clock);
        rollback = 1;

        @(negedge clock);
        rollback = 0;

        // @(negedge clock);
        // rollback = 1;

        @(negedge clock);
        check_amt_output(amt_output, correct);






        #100
        $finish;

    end

endmodule