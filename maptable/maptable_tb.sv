module maptable_tb();

    parameter dp_num = 2;
    parameter mt_entry = 32;
    parameter cdb_num = 2;

    logic clock;
    logic reset;
    logic rollback;

    DP_MT  [dp_num - 1 : 0]   dp_input;
    MT_DP [dp_num - 1 : 0]   mt_output;
    MT_DP [dp_num - 1 : 0]   correct;

    CDB [cdb_num-1:0] cdb_input;
    AMT_ENTRY [mt_entry-1:0] amt_input;

    maptable dut(
        .clk_i(clock),
        .rst_i(reset),
        .rollback_i(rollback),
        .cdb_i(cdb_input),
        .dp_mp_i(dp_input),
        .amt_i(amt_input),
        .mp_dp_o(mt_output)
    );

  task check_rs_read;
    input  MT_DP [dp_num - 1 : 0]   mt_packet;
    input  MT_DP [dp_num - 1 : 0]   correct;

    integer i;
  
    for (i=0; i<dp_num; i++) begin
      if (mt_output[i].tag1 == correct[i].tag1 && mt_output[i].tag1_ready == correct[i].tag1_ready &&
          mt_output[i].tag2 == correct[i].tag2 && mt_output[i].tag2_ready == correct[i].tag2_ready) begin
        // $display("tag for rs1,             tag: %d, preg_ready: %b", mt_packet[i].tag1, mt_packet[i].tag1_ready);
        // $display("tag for rs2,             tag: %d, preg_ready: %b", mt_packet[i].tag2, mt_packet[i].tag2_ready);
        // $display("correct packet for tag1, tag: %d, preg_ready: %b", correct[i].tag1, correct[i].tag1_ready);
        // $display("correct packet for tag2, tag: %d, preg_ready: %b", correct[i].tag2, correct[i].tag2_ready);
      end else begin
        $display("@@@ Incorrect result at TIME: %.4f", $time);
        $display("tag for rs1,             tag: %d, preg_ready: %b", mt_packet[i].tag1, mt_packet[i].tag1_ready);
        $display("tag for rs2,             tag: %d, preg_ready: %b", mt_packet[i].tag2, mt_packet[i].tag2_ready);
        $display("correct packet for tag1, tag: %d, preg_ready: %b", correct[i].tag1, correct[i].tag1_ready);
        $display("correct packet for tag2, tag: %d, preg_ready: %b", correct[i].tag2, correct[i].tag2_ready);
        $display("@@@ Failed");
      end
    end
  endtask;


  task  check_rd_write;
    input  MT_DP [dp_num - 1 : 0]   mt_packet;
    input  MT_DP [dp_num - 1 : 0]   correct;

    integer i;
  
    for (i=0; i<dp_num; i++) begin
      if (mt_output[i].tag_old == correct[i].tag_old) begin
        // $display("tag_old for destination reg, tag: %d", mt_packet[i].tag_old);
        // $display("correct value,               tag: %d", correct[i].tag_old);
      end else begin
        $display("@@@ Incorrect result at TIME: %.4f", $time);
        $display("tag_old for destination reg, tag: %d", mt_packet[i].tag_old);
        $display("correct value, tag: %d", correct[i].tag_old);
        $display("@@@ Failed");
      end
    end

  endtask //


    always #5 clock = ~clock;

    initial begin
        clock = 0;
        reset = 1;

        dp_input = 'b0;
        cdb_input = 'b0;
        amt_input = 'b0;

        // check initial values in maptable
        // ###########################
        @(negedge clock);
        @(negedge clock);
        $display("@@@ check initial values in maptable");
        reset = 0;
        rollback = 0;
        dp_input[0].read_en = 1;
        dp_input[1].read_en = 1;
        dp_input[0].rs1 = 'd0;
        dp_input[0].rs2 = 'd5;
        dp_input[1].rs1 = 'd7;
        dp_input[1].rs2 = 'd8;

        correct[0].tag1 = 'd0;
        correct[0].tag2 = 'd5;
        correct[1].tag1 = 'd7;
        correct[1].tag2 = 'd8;

        correct[0].tag1_ready = 1;
        correct[0].tag2_ready = 1;
        correct[1].tag1_ready = 1;
        correct[1].tag2_ready = 1;
        #5
        check_rs_read(mt_output, correct);
        // ###########################




        // testcase for write enable triggered,
        // check whether tag_old is updated as the value before write.
        // ###########################
        @(negedge clock);
        $display("@@@ check write enable triggered");
        dp_input[0].wr_en = 1;
        dp_input[0].rd = 'd5;
        dp_input[0].tag = 'd32;
        
        dp_input[1].wr_en = 1;
        dp_input[1].rd =  'd7;
        dp_input[1].tag = 'd10;


        correct[0].tag2 = 'd32;
        correct[1].tag1 = 'd10;
        correct[0].tag_old = 'd5;
        correct[1].tag_old = 'd7;

        correct[0].tag1_ready = 1;
        correct[0].tag2_ready = 0;
        correct[1].tag1_ready = 0;
        correct[1].tag2_ready = 1;

        #10
        check_rd_write(mt_output, correct);
        #10
        check_rs_read(mt_output, correct);
        // ###########################


        // testcase for superscalar: first-round destination reg is second-round source reg
        // ###########################
        
        
        $display("@@@ check superscalar");
        reset = 1;
        @(negedge clock);
        @(negedge clock);
        reset = 0;

        dp_input[0].rs1 = 'd0;
        dp_input[0].rs2 = 'd5;
        dp_input[0].wr_en = 1;
        dp_input[0].rd = 'd9;
        dp_input[0].tag = 'd32;


        dp_input[1].rs1 = 'd9;
        dp_input[1].rs2 = 'd8;

        correct[0].tag1 = 'd0;
        correct[0].tag2 = 'd5;
        correct[1].tag1 = 'd32;
        correct[1].tag2 = 'd8;

        correct[0].tag1_ready = 1;
        correct[0].tag2_ready = 1;
        correct[1].tag1_ready = 0;
        correct[1].tag2_ready = 1;


        #10
        check_rs_read(mt_output, correct);
        // ###########################


        // testcase for destination reg and source reg is the same.
        // ###########################
        
        reset = 1;
        $display("@@@ check same source reg and destination reg");
        @(negedge clock)
        @(negedge clock)
        reset = 0;
        

        dp_input[0].read_en = 1;
        dp_input[0].wr_en = 1;
        dp_input[0].rs1 = 'd5;
        dp_input[0].rs2 = 'd0;
        dp_input[1].rs1 = 'd7;
        dp_input[1].rs2 = 'd8;

        dp_input[0].rd = 'd5;
        dp_input[0].tag = 'd32;



        correct[0].tag1 = 'd0;
        correct[0].tag2 = 'd5;
        correct[1].tag1 = 'd7;
        correct[1].tag2 = 'd8;

        correct[0].tag1_ready = 1;
        correct[0].tag2_ready = 1;
        correct[1].tag1_ready = 1;
        correct[1].tag2_ready = 1;

        correct[0].tag_old = 5;

        #10
        check_rs_read(mt_output, correct);
        check_rd_write(mt_output, correct);
        // ###########################

        #200
        $display("@@@ Correct");
        $finish;

    end




endmodule