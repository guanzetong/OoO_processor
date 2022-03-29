`timescale 1ns/100ps

module PRF_tb();

 parameter       C_DP_NUM                =   4     ;
 parameter       C_THREAD_NUM            =   3     ;
 parameter       C_ROB_ENTRY_NUM         =   32    ;
 parameter       C_ARCH_REG_NUM          =   32    ;
 parameter       C_PHY_REG_NUM           =   64    ;
 parameter       C_DP_NUM_WIDTH          =   2     ;

 logic                          clk_i    ;   // Clock
 logic                          rst_i    ;   // Reset
 RS_PRF                         rs_prf_i ;            
    //per_channel 
 PRF_RS                         prf_rs_o ;           
    //per_channel
 BC_PRF                         bc_prf_i ;

localparam       C _PERIOD               =     5    ;   
 

PRF dut( 
    .clk_i              (clk_i              ),
    .rst_i              (rst_i              ),
    .rs_prf_i           (rs_prf_i           ),
    .prf_rs_o           (prf_rs_o           ),
    .bc_prf_i           (bc_prf_i           )
);//declaration of the interactive structures


// ====================================================================
// Design Under Test (DUT) Instantiation End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [`DP_IDX_WIDTH:0]     comp_tmp1 ;
    logic   [`DP_IDX_WIDTH:0]     comp_tmp2 ;
    logic   [`DP_IDX_WIDTH:0]     comp_out  ;
    
// --------------------------------------------------------------------
//  actual number of dispatched instructions known as the comparator
// --------------------------------------------------------------------

    // Generate dp_en
    function logic [C_DP_NUM-1:0] dp_en (
        input int dp_en_num
    );
        dp_en = 0;
        for (integer idx = 0; idx < C_DP_NUM; idx++) begin
            if (idx < dp_en_num) begin
                dp_en[idx]   =  1'b1;
            end else begin
                dp_en[idx]   =  1'b0;
            end
        end
    endfunction

    // // Generate min_dp
    // function int min_int (
    //     input int inta, intb
    // );
    //     if (inta < intb) begin
    //         min_int =   inta;
    //     end else begin
    //         min_int =   intb;
    //     end
    // endfunction

    // drive without inst & avail_num
    task int signal_in_dp (
        input   int     dispatch_num
    ); 
        logic   [`DP_NUM-1:0]   dp_num_concat  ;
        begin
            // Generate the dp_en in each dispatch channel
            dp_num_concat   =   dp_en(dispatch_num);

            for (int idx = 0; idx < C_DP_NUM; n++) begin
                if(dp_num_concat[idx])begin
                    //Dispatcher gets from MT channel
                    mt_dp_i[idx].tag1       =   $urandom %  `PHY_REG_NUM ;
                    mt_dp_i[idx].tag1_ready =   $urandom %  2;
                    mt_dp_i[idx].tag2       =   $urandom %  `PHY_REG_NUM ;
                    mt_dp_i[idx].tag2_ready =   $urandom %  2;
                    mt_dp_i[idx].tag_old    =   $urandom %  `PHY_REG_NUM ;
                    $display
                    ("@@ Time= %4.0f, Dispatcher gets from MT channel%1d, 
                    tag1 = %d, tag1_ready = %d, tag2 = %d, tag2_ready = %d, tag_old: %d",
                    $time, idx, mt_dp_i[idx].tag1, mt_dp_i[idx].tag1_ready, 
                    mt_dp_i[idx].tag2, mt_dp_i[idx].tag2_ready, mt_dp_i[idx].tag_old);

                    //Dispatcher gets from FL channel
                    fl_dp_i.tag[idx]        =   $urandom %  `PHY_REG_NUM ;
                    $display
                    ("@@ Time= %4.0f, Dispatcher gets from FL channel%1d, fl_dp_i.tag = %d",
                    $time, fl_dp_i.tag[idx]);

                    //Dispatcher gets from ROB channel
                    rob_dp_i.rob_idx[idx]   =   $urandom %  `PHY_REG_NUM ;
                    $display
                    ("@@ Time= %4.0f, Dispatcher gets from ROB channel%1d, rob_dp_i.rob_idx = %d",
                    $time, rob_dp_i.rob_idx[idx]);

                    //Dispatcher gets from FIQ channel
                    fiq_dp_i.thread_idx[idx]=   $urandom %  `THREAD_NUM  ;
                    fiq_dp_i.pc[idx]        =   $urandom %  `XLEN        ;
                    ("@@ Time= %4.0f, Dispatcher gets from FIQ channel%1d, 
                    fiq_dp_i.thread_idx = %d,  fiq_dp_i.pc = %h",
                    $time, fiq_dp_i.thread_idx[idx], fiq_dp_i.pc[idx]);

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
                end //else
            end//for
        end//task
    endtask

initial begin
    signal_in_dp(dispatch_num = $urandom %  C_DP_NUM); 
    #C_PERIOD;
end

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
