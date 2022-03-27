`timescale 1ns/100ps

module DP_tb();

    parameter       C_DP_NUM                =   2     ;
    parameter       C_THREAD_NUM            =   3     ;
    parameter       C_ROB_ENTRY_NUM         =   32    ;
    parameter       C_ARCH_REG_NUM          =   32    ;
    parameter       C_PHY_REG_NUM           =   64    ;


    logic                       clk_i      ;
    ROB_DP                      rob_dp_i   ; 
    DP_ROB                      dp_rob_o   ;

    MT_DP   [C_DP_NUM-1:0]      mt_dp_i    ; 
    DP_MT   [C_DP_NUM-1:0]      dp_mt_o    ;
    //per_channel    
    FL_DP                       fl_dp_i    ; 
    DP_FL                       dp_fl_o    ;

    FIQ_DP                      fiq_dp_i   ; 
    DP_FIQ                      dp_fiq_o   ;
    
    RS_DP                       rs_dp_i    ; 
    DP_RS                       dp_rs_o    ;


// ====================================================================
// Signal Declarations End
// ====================================================================
    localparam       C_CLK_PERIOD            =   10;
    localparam       C_DP_IDX_WIDTH          =   $clog2(C_DP_NUM)+1 ;
 
// ====================================================================
// Design Under Test (DUT) Instantiation Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   DP
// Description  :   The Dispatcher is designed to check the     
//                  structural hazards from ROB, RS, FIQ and FL.
// --------------------------------------------------------------------

    DP dut( 
    .rob_dp_i                    (rob_dp_i ),   
    .dp_rob_o                    (dp_rob_o ),

    .mt_dp_i                     (mt_dp_i  ),   
    .dp_mt_o                     (dp_mt_o  ),
    //per_channel  

    .fl_dp_i                     (fl_dp_i  ),   
    .dp_fl_o                     (dp_fl_o  ),

    .fiq_dp_i                    (fiq_dp_i ),   
    .dp_fiq_o                    (dp_fiq_o ),

    .rs_dp_i                     (rs_dp_i  ),   
    .dp_rs_o                     (dp_rs_o  )

);//declaration of the interactive structures

// ====================================================================
// Design Under Test (DUT) Instantiation End
// ====================================================================
// ====================================================================
// Signal Declarations Start
// ====================================================================


// ====================================================================
// Clock Generator Start
// ====================================================================
    // initial begin
    //     clk_i   =   0;
    //     forever begin
    //         #(C_CLK_PERIOD/2)   clk_i   =   ~clk_i;
    //     end
    // end
// ====================================================================
// Clock Generator End
// ====================================================================
// --------------------------------------------------------------------
//  actual number of dispatched instructions known as the comparator
// --------------------------------------------------------------------

// Generate signal from decimal to binary 2 ---> 010
    function logic [C_DP_IDX_WIDTH-1:0] signal_dtb (
        input int signal_dtb_num      
    );
    signal_dtb = 0;
    for (integer idx = 0; (idx < C_DP_IDX_WIDTH); idx++) begin
        signal_dtb[idx]  =  signal_dtb_num % 2;
        signal_dtb_num   =  signal_dtb_num / 2;
    end//for
    endfunction

// Generate channel indicator as dp_en 2 ---> 0011
    function logic [`DP_NUM-1:0] dp_en (
        input int dp_en_num
    );
        dp_en = 0;
        for (integer idx = 0; idx < `DP_NUM; idx++) begin
            if (idx < dp_en_num) begin
                dp_en[idx]   =  1'b1;
            end else begin
                dp_en[idx]   =  1'b0;
            end
        end
    endfunction

// Generate min_dp
    function int min_int (
        input int inta, intb
    );
        if (inta < intb) begin
            min_int =   inta;
        end else begin
            min_int =   intb;
        end
    endfunction        

// randomnize without inst & avail_num
    task signal_in_dp (
        input   int     dispatch_num
    ); 
        logic   [C_DP_NUM-1:0]   dp_num_concat  ;
        begin
            // Generate the dp_num in each dispatch channel
            dp_num_concat   =   dp_en(dispatch_num);

            for (int idx = 0; idx < C_DP_NUM; idx++) begin
                if(dp_num_concat[idx])begin
                    // Dispatcher gets from MT channel
                    mt_dp_i[idx].tag1       =   3 ;
                    mt_dp_i[idx].tag1_ready =   1 ;
                    mt_dp_i[idx].tag2       =   4 ;
                    mt_dp_i[idx].tag2_ready =   0 ;
                    mt_dp_i[idx].tag_old    =   23;

                    // mt_dp_i[idx].tag1       =   $urandom %  C_PHY_REG_NUM ;
                    // mt_dp_i[idx].tag1_ready =   $urandom %  2;
                    // mt_dp_i[idx].tag2       =   $urandom %  C_PHY_REG_NUM ;
                    // mt_dp_i[idx].tag2_ready =   $urandom %  2;
                    // mt_dp_i[idx].tag_old    =   $urandom %  C_PHY_REG_NUM ;
                    // // $display("@@ Time= %4.0f, Dispatcher gets from MT channel%1d, tag1 = %d, tag1_ready = %d, tag2 = %d, tag2_ready = %d, tag_old: %d",
                    // // $time, idx, mt_dp_i[idx].tag1, mt_dp_i[idx].tag1_ready, 
                    // // mt_dp_i[idx].tag2, mt_dp_i[idx].tag2_ready, mt_dp_i[idx].tag_old);

                    fl_dp_i.tag[idx]        =   7  ;

                    // //Dispatcher gets from FL channel
                    // fl_dp_i.tag[idx]        =   $urandom %  C_PHY_REG_NUM ;
                    // // $display("@@ Time= %4.0f, Dispatcher gets from FL channel%1d, fl_dp_i.tag = %d",
                    // // $time, idx, fl_dp_i.tag[idx]);

                    rob_dp_i.rob_idx[idx]   =   23 ;

                    // //Dispatcher gets from ROB channel
                    // rob_dp_i.rob_idx[idx]   =   $urandom %  C_PHY_REG_NUM ;
                    // // $display("@@ Time= %4.0f, Dispatcher gets from ROB channel%1d, rob_dp_i.rob_idx = %d",
                    // // $time, idx, rob_dp_i.rob_idx[idx]);

                    fiq_dp_i.thread_idx[idx]=   3  ;
                    fiq_dp_i.pc[idx]        =   $urandom        ;
                    fiq_dp_i.br_predict[idx]=   1  ;
                    fiq_dp_i.inst[idx]      =   {7'b0000000, 5'd15,  5'd8, 3'b000, 5'd30, 7'b0110011}  ;

                    // //Dispatcher gets from FIQ channel
                    // fiq_dp_i.thread_idx[idx]=   $urandom %  C_THREAD_NUM  ;
                    // fiq_dp_i.pc[idx]        =   $urandom %  `XLEN         ;
                    // fiq_dp_i.br_predict[idx]=   $urandom %  2;
                    // $display("@@ Time= %4.0f, Dispatcher gets from FIQ channel%1d, fiq_dp_i.thread_idx = %d,  fiq_dp_i.pc = %h",


                    // $time, idx, fiq_dp_i.thread_idx[idx], fiq_dp_i.pc[idx]);

                end //if
                else begin
                    //Dispatcher gets from MT idle channel
                    mt_dp_i[idx].tag1        =   0;
                    mt_dp_i[idx].tag1_ready  =   0;
                    mt_dp_i[idx].tag2        =   0;
                    mt_dp_i[idx].tag2_ready  =   0;
                    mt_dp_i[idx].tag_old     =   0;

                    //Dispatcher gets from FL  idle channel
                    fl_dp_i.tag[idx]         =   0;

                    //Dispatcher gets from ROB idle channel
                    rob_dp_i.rob_idx[idx]    =   0;

                    //Dispatcher gets from FIQ idle channel
                    fiq_dp_i.thread_idx[idx] =   0;
                    fiq_dp_i.pc[idx]         =   0;
                    fiq_dp_i.br_predict[idx] =   0  ;
                    fiq_dp_i.inst[idx]      =   0;
                end //else
            end//for1

            #1;

            for (int idx = 0; idx < C_DP_NUM; idx++) begin
                if ((dp_rs_o.dec_inst[idx].pc          ==   fiq_dp_i.pc[idx]          ) &&
                    (dp_rs_o.dec_inst[idx].inst        ==   fiq_dp_i.inst[idx]        ) &&
                    (dp_rs_o.dec_inst[idx].tag         ==   fl_dp_i.tag[idx]          ) &&
                    (dp_rs_o.dec_inst[idx].tag1        ==   mt_dp_i[idx].tag1         ) &&
                    (dp_rs_o.dec_inst[idx].tag1_ready  ==   mt_dp_i[idx].tag1_ready   ) &&
                    (dp_rs_o.dec_inst[idx].tag2        ==   mt_dp_i[idx].tag2         ) &&
                    (dp_rs_o.dec_inst[idx].tag2_ready  ==   mt_dp_i[idx].tag2_ready   ) &&
                    (dp_rs_o.dec_inst[idx].thread_idx  ==   fiq_dp_i.thread_idx[idx]  ) &&
                    (dp_rs_o.dec_inst[idx].rob_idx     ==   rob_dp_i.rob_idx[idx]     ))begin
                    $display("@@@ Correct result of dp_rs_o[%1d] at TIME: %.1f", idx, $time);
                end else begin
                    $display("@@@ Incorrect result of dp_rs_o[%1d] at TIME: %.1f, tag1 = %.1f, rob_idx = %.1f", idx, $time, dp_rs_o.dec_inst[idx].tag1, dp_rs_o.dec_inst[idx].rob_idx);
                end//if_else

                if ((dp_rob_o.tag_old[idx]    ==   mt_dp_i[idx].tag_old)&&
                    (dp_mt_o[idx].tag         ==   fl_dp_i.tag[idx]    ))begin
                    $display("@@@ Correct result of dp_rob_o.tag_old[%1d] & dp_mt_o[%1d].tag at TIME: %.1f", idx, idx, $time);
                end else begin
                    $display("@@@ Incorrect result of dp_rob_o.tag_old[%1d] & dp_mt_o[%1d].tag at TIME: %.1f", idx, idx, $time);
                end//if_else
            end//for2

            if ((dp_rob_o.br_predict   ==   fiq_dp_i.br_predict ) &&
                (dp_rob_o.pc           ==   fiq_dp_i.pc         ) &&
                (dp_rob_o.tag          ==   fl_dp_i.tag         ))begin
                $display("@@@ Correct result of dp_rs_o.pc etc at TIME: %.1f", $time);       
            end else begin
                $display("@@@ Incorrect result of dp_rs_o.pc etc at TIME: %.1f", $time);
            end//if-else  
        end//task
    endtask

// randomnize inst 
// task inst_in_dp (
//         input   int         dispatch_num ,
//         input 	INST        inst	     
//     ); 
//         logic   [`DP_NUM-1:0]   dp_num_concat  ;
//         begin
//             // Generate the dp_en in each dispatch channel
//             dp_num_concat   =   signal_en(dispatch_num);

//             for (int idx = 0; idx < C_DP_NUM; idx++) begin
//                 if(dp_num_concat[idx])begin
//                     //Dispatcher gets from MT channel
//                     mt_dp_i[idx].tag1       =   $urandom %  C_PHY_REG_NUM ;
//                     mt_dp_i[idx].tag1_ready =   $urandom %  2;


//verification
//monitor_dp_num
    task monitor_dp_num(
        input     int               fl_avail_num   ,
        input     int               fiq_avail_num  ,
        input     int               rs_avail_num   ,
        input     int               rob_avail_num  
    );
        int       avail_num_int;
        int       wr_en_cnt    ;
        int       avail_num_cnt;
        logic     [C_DP_IDX_WIDTH-1:0]    avail_num_logic;
        logic     [C_DP_NUM-1:0]          avail_num_channel;

        begin
            avail_num_int       =   min_int(min_int(fl_avail_num , fiq_avail_num), 
                                            min_int(rs_avail_num , rob_avail_num));
            //ind the minimum avail_num
            avail_num_cnt       =   0;
            avail_num_logic     =   signal_dtb(avail_num_int);
            avail_num_channel   =   dp_en(avail_num_int);

            fl_dp_i.avail_num   =   signal_dtb(fl_avail_num) ;
            fiq_dp_i.avail_num  =   signal_dtb(fiq_avail_num);
            rs_dp_i.avail_num   =   signal_dtb(rs_avail_num) ;
            rob_dp_i.avail_num  =   signal_dtb(rob_avail_num);

            #1;

            $display("%0d,  %0d, %0d",avail_num_int, avail_num_logic,  dp_rob_o.dp_num);
            $display("%0d,  %0d, %0d",dp_fl_o.dp_num, dp_rs_o.dp_num,  dp_fiq_o.dp_num);

            if ((dp_rob_o.dp_num == avail_num_logic) && (dp_fl_o.dp_num == avail_num_logic) &&
                (dp_fiq_o.dp_num == avail_num_logic) && (dp_rs_o.dp_num == avail_num_logic)) begin
                $display("@@@ Correct result of dp_num as %d at TIME: %.1f", $time, avail_num_int);
            end else begin
                $display("@@@ Incorrect result of dp_num at TIME: %.1f ,four numbers are %.1f %.1f %.1f %.1f, :", 
                        $time, fl_avail_num , fiq_avail_num , rs_avail_num , rob_avail_num);
            end//if_else

            for (wr_en_cnt = 0; wr_en_cnt < C_DP_NUM; wr_en_cnt++) begin
                $display("@@@ dp_mt_o[%0d].wr_en=%0b, avail_num_channel[]=%0b", wr_en_cnt, dp_mt_o[wr_en_cnt].wr_en, avail_num_channel[wr_en_cnt]);
                if(dp_mt_o[wr_en_cnt].wr_en == avail_num_channel[wr_en_cnt])begin
                    $display("@@@ wr_en = 1 at TIME: %.4f , %d", $time, avail_num_channel[wr_en_cnt]);
                end else begin
                    $display("@@@ wr_en = 0 at TIME: %.4f , %d", $time, avail_num_channel[wr_en_cnt]);
                    avail_num_cnt++;
                end//if_else   
            end//for
            $display("@@@ dp_num = %1d", avail_num_cnt);
        end//begin
    endtask

    // //monitor_signal_in
    // task monitor_signal_in(
    //     input     int               fl_avail_num   ,
    //     input     int               fiq_avail_num  ,
    //     input     int               rs_avail_num   ,
    //     input     int               rob_avail_num  
    // );
    //     int       avail_num_int;
    //     int       wr_en_cnt    ;
    //     int       avail_num_cnt;
    //     logic     [C_DP_IDX_WIDTH-1:0]    avail_num_logic;

    //     begin

    //     end//begin
    // endtask




initial begin
        // monitor_signal_in(1); 
        // randomnize dp_num
        signal_in_dp(1);
        // a = rand_num ;
        // $display("value of a is %h", a);
        monitor_dp_num(2, 1, 1, 2);
        // monitor_wr_en(
end

endmodule

// // --------------------------------------------------------------------
// // decoder insts from FIQ and send to RS using generate initialization
// // --------------------------------------------------------------------

//     INST     [C_DP_NUM-1:0]  inst   ;
//     // logic    [C_DP_NUM_WIDTH-1:0]  dp_num   ;
//     // assign   dp_num   =   fiq_dp_i.dp_num   ;

//     genvar   idx;
//     generate
//         for(idx=0; idx < C_DP_NUM; idx++)begin 
//             inst[idx]   =   fiq_dp_i.inst[idx];// initialize inst
            
//             decoder#(
//                 .C_DEC_IDX(idx)
//             )decoder_inst(
//                 .inst (inst[idx]) , 
//                 // .dp_num (dp_num)  ,
// 		        // inputs
// 		        .opa_select(dp_rs_o.dec_inst[idx].opa_select)  ,
// 		        .opb_select(dp_rs_o.dec_inst[idx].opb_select)  ,
// 		        .alu_func  (dp_rs_o.dec_inst[idx].alu_func)    ,
        
// 		        // .dest_reg(dest_reg_select),
        
// 		        .rd_mem     (dp_rs_o.dec_inst[idx].rd_mem)     ,
// 		        .wr_mem     (dp_rs_o.dec_inst[idx].wr_mem)     ,
// 		        .cond_br    (dp_rs_o.dec_inst[idx].cond_br)    ,
// 		        .uncond_br  (dp_rs_o.dec_inst[idx].uncond_br)  ,
// 		        .csr_op     (dp_rs_o.dec_inst[idx].csr_op)     ,
// 		        .halt       (dp_rs_o.dec_inst[idx].halt)       ,
// 		        .illegal    (dp_rs_o.dec_inst[idx].illegal)    ,

//                 .mult       (dp_rs_o.dec_inst[idx].mult)       ,
//                 .alu        (dp_rs_o.dec_inst[idx].alu)        ,
//                 .rd         (dp_rs_o.dec_inst[idx].rd)         ,
//                 .rs1        (dp_rs_o.dec_inst[idx].rs1)        ,
//                 .rs2        (dp_rs_o.dec_inst[idx].rs2)        ,
//                 // outputs
//             );
//         end
//     endgenerate
