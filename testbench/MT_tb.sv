module MT_tb();

    parameter dp_num   = 2 ;
    parameter mt_entry = 32;
    parameter cdb_num  = 2 ;

    logic     clock     ;
    logic     reset     ;
    logic     rollback  ;

    DP_MT_READ   [dp_num - 1 : 0]   dp_read_input ;
    DP_MT_WRITE  [dp_num - 1 : 0]   dp_write_input;
    MT_DP        [dp_num - 1 : 0]   mt_output     ;
    MT_DP        [dp_num - 1 : 0]   correct       ;

    CDB          [cdb_num-1:0]      cdb_input     ;
    AMT_ENTRY    [mt_entry-1:0]     amt_input     ;

    MT dut(
        .clk_i            (clock),
        .rst_i            (reset),
        .rollback_i       (rollback),
        .cdb_i            (cdb_input),
        .dp_mt_read_i     (dp_read_input),
        .dp_mt_write_i    (dp_write_input),
        .amt_i            (amt_input),
        .mt_dp_o          (mt_output)
    );

  task check_rs_read;
    input  MT_DP [dp_num - 1 : 0]   mt_packet ;
    input  MT_DP [dp_num - 1 : 0]   correct   ;

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
        $display("@@@ Incorrect result at dispatch [%d]", i);
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
        $display("@@@ Incorrect result at dispatch[%d]", i);
        $display("tag_old for destination reg, tag: %d", mt_packet[i].tag_old);
        $display("correct value,               tag: %d", correct[i].tag_old);
        $display("@@@ Failed");
      end
    end

  endtask //


    always #5 clock = ~clock;

    initial begin
        clock = 0;
        reset = 1;

        dp_read_input = 'b0;
        dp_write_input = 'b0;
        cdb_input = 'b0;
        amt_input = 'b0;

        // check initial values in maptable
        // ###########################
        @(negedge clock);
        @(negedge clock);
        $display("@@@ check initial values in maptable");
        reset = 0;
        rollback = 0;
        dp_read_input[0] = '{
          'd0, // rs1
          'd5, // rs2
            1, // read_en
            0  // thread idx
        };
        dp_read_input[1] = '{
          'd7, // rs1
          'd8, // rs2
            1, // read_en
            0  // thread idx
        };

        correct[0] = '{
          'd0, // tag1
            1, // tag1_ready
          'd5, // tag2
            1, // tag2_ready
            0 // tag_old
        };
        correct[1] = '{
          'd7, // tag1
            1, // tag1_ready
          'd8, // tag2
            1, // tag2_ready
            0 // tag_old
        };
        #5
        check_rs_read(mt_output, correct);



        // testcase for write enable triggered,
        // check whether tag_old is updated as the value before write.
        // ###########################
        reset = 1;
        @(negedge clock);
        @(negedge clock);
        $display("@@@ check write enable triggered");
        reset = 0;
        rollback = 0;
        dp_read_input[0] = '{
          'd0, // rs1
          'd5, // rs2
            1, // read_en
            0  // thread idx
        };
        dp_write_input[0] = '{
          'd0, // rd
          'd32, // tag
            1, // write_en
            0  // thread idx
        };
        
        dp_read_input[1] = '{
          'd7, // rs1
          'd8, // rs2
            1, // read_en
            0  // thread idx
        };

        dp_write_input[1] = '{
          'd7, // rd
          'd37, // tag
            1, // write_en
            0  // thread idx
        };

        correct[0] = '{
          'd0, // tag1
            1, // tag1_ready
          'd5, // tag2
            1, // tag2_ready
            0 // tag_old
        };
        correct[1] = '{
          'd7, // tag1
            1, // tag1_ready
          'd8, // tag2
            1, // tag2_ready
            7 // tag_old
        };
        #5
        check_rs_read(mt_output, correct);
        check_rd_write(mt_output, correct);


        // ###########################
        // testcase for same rd and rs of one instruction,
        // check the tag and ready bit for rs1/rs2 should be value before write.
        // ###########################
        reset = 1;
        @(negedge clock);
        @(negedge clock);
        $display("@@@ check same source and destination register");
        reset = 0;

        dp_read_input[0] = '{
          'd7, // rs1
          'd7, // rs2
            1, // read_en
            0  // thread idx
        };
        dp_write_input[0] = '{
          'd7, // rd
          'd32, // tag
            1, // write_en
            0  // thread idx
        };
        
        dp_read_input[1] = '{
          'd8, // rs1
          'd8, // rs2
            1, // read_en
            0  // thread idx
        };

        dp_write_input[1] = '{
          'd8, // rd
          'd37, // tag
            1, // write_en
            0  // thread idx
        };

        correct[0] = '{
          'd7, // tag1
            1, // tag1_ready
          'd7, // tag2
            1, // tag2_ready
            7 // tag_old
        };
        correct[1] = '{
          'd8, // tag1
            1, // tag1_ready
          'd8, // tag2
            1, // tag2_ready
            8 // tag_old
        };
        #5
        check_rs_read(mt_output, correct);
        check_rd_write(mt_output, correct);

        // ###########################
        // testcase for same rd and rs of one instruction,
        // check the tag and ready bit in the entry has changed
        // ###########################
        $display("@@@ check entry changed");
        dp_read_input[0] = '{
          'd7, // rs1
          'd8, // rs2
            1, // read_en
            0  // thread idx
        };

        dp_read_input[1] = '{
          'd5, // rs1
          'd6, // rs2
            1, // read_en
            0  // thread idx
        };

        correct[0] = '{
          'd32, // tag1
            0, // tag1_ready
          'd37, // tag2
            0, // tag2_ready
            7 // tag_old
        };

        correct[1] = '{
          'd5, // tag1
            1, // tag1_ready
          'd6, // tag2
            1, // tag2_ready
            8 // tag_old
        };

        #5
        check_rs_read(mt_output, correct);

        // ###########################
        // testcase for CDB value,
        // check the tag and ready bit in the entry has changed
        // ###########################
        @(negedge clock);
        @(negedge clock);
        $display("@@@ check CDB update");

        cdb_input[0] = '{
          1,  // valid    
          0, // pc
          'd32,  // tag      
          0 , // rob_idx  
          0 , // thread_id
          0  ,// br_result
          0   // Branch Target
        };

        cdb_input[1] = '{
          1 , // valid    
          0, //pc
          'd37 , // tag      
          0  ,// rob_idx  
          0 , // thread_id
          0 ,// br_result
          0   // Branch Target
        };

        @(negedge clock);

        dp_read_input[0] = '{
          'd7, // rs1
          'd8, // rs2
            1, // read_en
            0  // thread idx
        };

        dp_read_input[1] = '{
          'd5, // rs1
          'd6, // rs2
            1, // read_en
            0  // thread idx
        };

        correct[0] = '{
          'd32, // tag1
            1, // tag1_ready
          'd37, // tag2
            1, // tag2_ready
            7 // tag_old
        };

        correct[1] = '{
          'd5, // tag1
            1, // tag1_ready
          'd6, // tag2
            1, // tag2_ready
            8 // tag_old
        };

        check_rs_read(mt_output, correct);

        // ###########################
        // testcase for zero reg,
        // check the zero tag write, always result in tag = 0 and ready bit = 1
        // ###########################
        $display("@@@ check zero reg write");
        @(negedge clock);
        reset = 1;
        #10
        @(negedge clock);
        @(negedge clock);
        reset = 0;
        dp_read_input[0] = '{
          'd0, // rs1
          'd0, // rs2
            1, // read_en
            0  // thread idx
        };

        dp_write_input[0] = '{
          'd0, // rd
          'd7, // tag
            1, // write_en
            0  // thread idx
        };

        dp_read_input[1] = '{
          'd5, // rs1
          'd6, // rs2
            1, // read_en
            0  // thread idx
        };
        @(negedge clock);

        correct[0] = '{
          'd0, // tag1
            1, // tag1_ready
          'd0, // tag2
            1, // tag2_ready
            0 // tag_old
        };
        correct[1] = '{
          'd5, // tag1
            1, // tag1_ready
          'd6, // tag2
            1, // tag2_ready
            0 // tag_old
        };

      check_rs_read(mt_output, correct);


        #200
        $display("@@@ Correct");
        $finish;

    end




endmodule