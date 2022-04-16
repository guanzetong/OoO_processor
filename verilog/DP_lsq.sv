/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  DP_lsq.sv                                           //
//                                                                     //
//  Description :  DP_lsq MODULE of the pipeline;                      // 
//                 Integrated with LSQ module                          //
//                 structural hazards from ROB, RS, FIQ and FL.        //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module DP_lsq # ( 
    parameter       C_DP_NUM                =   `DP_NUM         ,
    parameter       C_THREAD_NUM            =   `THREAD_NUM     ,
    parameter       C_ROB_ENTRY_NUM         =   `ROB_ENTRY_NUM  ,
    parameter       C_ARCH_REG_NUM          =   `ARCH_REG_NUM   ,
    parameter       C_PHY_REG_NUM           =   `PHY_REG_NUM    
)(    
    input           ROB_DP      [C_THREAD_NUM-1:0]                rob_dp_i  ,
    output          DP_ROB      [C_THREAD_NUM-1:0]                dp_rob_o  ,
    input           MT_DP       [C_THREAD_NUM-1:0][C_DP_NUM-1:0]  mt_dp_i   ,   
    // output          DP_MT_READ  [C_DP_NUM-1:0]  dp_mt_o    ,
    // output          DP_MT_WRITE [C_DP_NUM-1:0]  dp_mt_o    ,
    output          DP_MT       [C_THREAD_NUM-1:0][C_DP_NUM-1:0]  dp_mt_o   ,
    input           FL_DP                                         fl_dp_i   ,   
    output          DP_FL                                         dp_fl_o   ,
    input           FIQ_DP                                        fiq_dp_i  ,   
    output          DP_FIQ                                        dp_fiq_o  ,
    input           RS_DP                                         rs_dp_i   ,   
    output          DP_RS                                         dp_rs_o   ,
    output          DP_LSQ      [C_THREAD_NUM-1:0]                dp_lsq_o  ,
    input           LSQ_DP      [C_THREAD_NUM-1:0]                lsq_dp_i      
);//declaration of the interactive structures

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam      C_DP_NUM_WIDTH          =   $clog2(C_DP_NUM+1)     ;
    localparam      C_THREAD_IDX_WIDTH      =   $clog2(C_THREAD_NUM)   ;
    localparam      C_ROB_IDX_WIDTH         =   $clog2(C_ROB_ENTRY_NUM);
    localparam      C_ARCH_REG_IDX_WIDTH    =   $clog2(C_ARCH_REG_NUM) ;
    localparam      C_TAG_IDX_WIDTH         =   $clog2(C_PHY_REG_NUM)  ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_DP_NUM_WIDTH-1:0]                        comp_1          ;   // Dispatch number comparator output
    logic   [C_DP_NUM_WIDTH-1:0]                        comp_2          ;   // Dispatch number comparator output
    logic   [C_DP_NUM_WIDTH-1:0]                        dp_num          ;
    logic   [C_DP_NUM_WIDTH-1:0]                        legal_dp_num    ;
    logic   [C_DP_NUM_WIDTH-1:0]                        lsq_dp_num      ;
    logic   [C_DP_NUM_WIDTH-1:0]                        fl_dp_num       ;
    logic   [C_DP_NUM_WIDTH-1:0]                        lsq_avail_num   ;
    logic   [C_THREAD_IDX_WIDTH-1:0]                    thread_sel      ;
    logic   [C_DP_NUM-1:0][C_DP_NUM_WIDTH-1:0]          fl_route        ;
    logic   [C_DP_NUM-1:0][C_DP_NUM_WIDTH-1:0]          lsq_route       ;
    INST    [C_DP_NUM-1:0]                              inst            ;

    logic   [C_DP_NUM-1:0][C_ARCH_REG_IDX_WIDTH-1:0]    dec_rd          ;
    logic   [C_DP_NUM-1:0][C_ARCH_REG_IDX_WIDTH-1:0]    dec_rs1         ;
    logic   [C_DP_NUM-1:0][C_ARCH_REG_IDX_WIDTH-1:0]    dec_rs2         ;

    int unsigned    legal_cnt           ;
    int unsigned    lsq_cnt             ;
    int unsigned    fl_cnt              ;
    int unsigned    illegal_flag        ;
    int unsigned    lsq_hazard_flag     ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================

// --------------------------------------------------------------------
// Module name  :   Decoder
// Description  :   Decode instructions
// --------------------------------------------------------------------
// --------------------------------------------------------------------
// decoder insts from FIQ and send to RS using generate initialization
// --------------------------------------------------------------------
    genvar  dec_idx;
    generate
        for(dec_idx=0; dec_idx < C_DP_NUM; dec_idx++) begin 
            // Connect instructions into Decoders
            assign inst[dec_idx]   =   fiq_dp_i.inst[dec_idx];
            // decoder#(
            //     .C_DEC_IDX  (dec_idx                                )
            // )decoder_inst(
            decoder decoder_inst (
                .dec_idx    (dec_idx[C_DP_NUM_WIDTH-1:0]            ),
                .inst       (inst[dec_idx]                          ),
                .dp_num     (dp_num                                 ),
                // inputs
                .opa_select (dp_rs_o.dec_inst[dec_idx].opa_select   ),
                .opb_select (dp_rs_o.dec_inst[dec_idx].opb_select   ),

                .alu_func   (dp_rs_o.dec_inst[dec_idx].alu_func     ),
                .rd_mem     (dp_rs_o.dec_inst[dec_idx].rd_mem       ),
                .wr_mem     (dp_rs_o.dec_inst[dec_idx].wr_mem       ),
                .cond_br    (dp_rs_o.dec_inst[dec_idx].cond_br      ),
                .uncond_br  (dp_rs_o.dec_inst[dec_idx].uncond_br    ),
                .csr_op     (dp_rs_o.dec_inst[dec_idx].csr_op       ),

                .halt       (dp_rs_o.dec_inst[dec_idx].halt         ),

                .illegal    (dp_rs_o.dec_inst[dec_idx].illegal      ),
                .mult       (dp_rs_o.dec_inst[dec_idx].mult         ),
                .alu        (dp_rs_o.dec_inst[dec_idx].alu          ),

                .rd         (dec_rd [dec_idx]                       ),
                .rs1        (dec_rs1[dec_idx]                       ),
                .rs2        (dec_rs2[dec_idx]                       )
                // outputs
            );
        end
    endgenerate
// --------------------------------------------------------------------

// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// Function Start
// ====================================================================

    function automatic logic [C_DP_NUM-1:0][C_DP_NUM_WIDTH-1:0] lsq_router;
        input   logic   [C_DP_NUM_WIDTH-1:0]    dp_num;
        int     lsq_idx   ;
        begin
            lsq_idx     =   0;
            lsq_router   =   0;
            for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
                if ((dp_idx < dp_num) && (dp_rs_o.dec_inst[dp_idx].wr_mem || dp_rs_o.dec_inst[dp_idx].rd_mem)) begin
                    lsq_router[dp_idx]   =   lsq_idx;
                    lsq_idx++;
                end
            end
        end
    endfunction

    function automatic logic [C_DP_NUM-1:0][C_DP_NUM_WIDTH-1:0] fl_router;
        input   logic   [C_DP_NUM_WIDTH-1:0]    dp_num;
        int     fl_idx   ;
        begin
            fl_idx      =   0;
            fl_router    =   0;
            for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
                if ((dp_idx < dp_num) && (dp_mt_o[thread_sel][dp_idx].rd != `ZERO_REG)) begin
                    fl_router[dp_idx]   =   fl_idx;
                    fl_idx++;
                end
            end
        end
    endfunction
    
// ====================================================================
// Function End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// The thread to dispatch during the current cycle
// --------------------------------------------------------------------  
    always_comb begin
        thread_sel  =   fiq_dp_i.thread_idx[0];
    end//comb


// --------------------------------------------------------------------
// Route the tags from Freelist to those instructions with rd != ZERO_REG
// --------------------------------------------------------------------  
    always_comb begin
        fl_route    =   fl_router(legal_dp_num);
    end//comb

// --------------------------------------------------------------------
//  Actual number of dispatched instructions known as the comparator
// --------------------------------------------------------------------
    always_comb begin
        // calculates the actual minum number of dispatched entries.
        if (rob_dp_i[thread_sel].avail_num < fiq_dp_i.avail_num) begin 
            comp_1  =   rob_dp_i[thread_sel].avail_num  ;   
        end else begin
            comp_1  =   fiq_dp_i.avail_num  ; 
        end//if-else
        
        if (fl_dp_i.avail_num < rs_dp_i.avail_num) begin 
            comp_2  =   fl_dp_i.avail_num   ;   
        end else begin
            comp_2  =   rs_dp_i.avail_num   ; 
        end//if-else

        if (comp_1 < comp_2) begin 
            dp_num  =   comp_1   ;  
        end else begin
            dp_num  =   comp_2   ;
        end//if-else

        // Exclude the illegal instructions
        // legal_cnt    =   dp_num;
        // lsq_cnt      =   'b0;
        // lsq_avail_num     =   lsq_dp_i[thread_sel].avail_num;
        // for (int unsigned dp_idx = 0 ; dp_idx < C_DP_NUM ; dp_idx++) begin
        //     if((dp_idx < dp_num) && (lsq_avail_num > lsq_cnt))begin
        //         if(dp_rs_o.dec_inst[dp_idx].wr_mem || dp_rs_o.dec_inst[dp_idx].rd_mem)begin
        //             lsq_cnt++;
        //         end else if(dp_rs_o.dec_inst[dp_idx].illegal)begin
        //             legal_cnt--;
        //         end
        //     end else if((dp_idx < dp_num) && (lsq_avail_num <= lsq_cnt))begin
        //         lsq_cnt      =   lsq_avail_num;
        //     end
        // end
        // dp_lsq_o[thread_sel].dp_num =   lsq_cnt;

        legal_cnt       =   'd0 ;
        lsq_cnt         =   'd0 ;
        fl_cnt          =   'd0 ;
        illegal_flag    =   'd0 ;
        lsq_hazard_flag =   'd0 ;
        lsq_avail_num   =   lsq_dp_i[thread_sel].avail_num;
        for (int unsigned dp_idx = 0 ; dp_idx < C_DP_NUM ; dp_idx++) begin
            // IF   The instruction is a valid dispatch (dp_idx < dp_num)
            // AND  No illegal instruction is met
            // AND  LSQ hazard is not met
            if ((dp_idx < dp_num) && (illegal_flag == 'd0) && (lsq_hazard_flag == 'd0)) begin
                // IF   The instruction is illegal
                // ->   Assert illegal_flag, no younger instructions can be dispathed in this cycle
                if (dp_rs_o.dec_inst[dp_idx].illegal) begin
                    illegal_flag    =   'd1;
                // ELSE The instruction is legal
                end else begin
                    // IF   The instruction is LOAD/STORE 
                    if(dp_rs_o.dec_inst[dp_idx].wr_mem || dp_rs_o.dec_inst[dp_idx].rd_mem)begin
                        // IF   The number of valid LOAD/STORE is less than the number of available LSQ entry
                        // ->   increment counters
                        if (lsq_cnt < lsq_avail_num) begin
                            legal_cnt++;
                            lsq_cnt++;
                            if (dp_rs_o.dec_inst[dp_idx].rd_mem) begin
                                fl_cnt++;
                            end
                        // ELSE The number of counted LOAD/STORE equals to the number of available LSQ entry
                        // ->   Assert lsq_hazard_flag, no younger instructions can be dispatched in this cycle.
                        end else begin
                            lsq_hazard_flag =   'd1;
                        end
                    // ELSE The instruction is not LOAD/STORE
                    // ->   Increment legal_cnt
                    end else begin
                        legal_cnt++;
                        if (dp_mt_o[thread_sel][dp_idx].rd != `ZERO_REG) begin
                            fl_cnt++;
                        end
                    end
                end 
            end
        end
        lsq_dp_num      =   lsq_cnt     ;   // For LSQ
        legal_dp_num    =   legal_cnt   ;   // For ROB, RS and FIQ
        fl_dp_num       =   fl_cnt      ;   // For FL
    end//comb

// --------------------------------------------------------------------
// DP_LSQ
// --------------------------------------------------------------------  
	always_comb begin
        dp_lsq_o    =   'b0;
        lsq_route   =   lsq_router(lsq_dp_num);
        for (int unsigned thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++) begin
            if(thread_idx == thread_sel)begin
                dp_lsq_o[thread_idx].dp_num =   lsq_dp_num;
                // Loop over Dispatch channel
                for(int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++)begin
                    // IF   The channel is ready for dispatch
                    // AND  The instruction is LOAD/STORE
                    // ->   Route the instruction to a LSQ port.
                    if((dp_idx < legal_dp_num) && (dp_rs_o.dec_inst[dp_idx].wr_mem 
                    || dp_rs_o.dec_inst[dp_idx].rd_mem)) begin
                        dp_lsq_o[thread_idx].cmd[lsq_route[dp_idx]]         =   (dp_rs_o.dec_inst[dp_idx].wr_mem) ? BUS_STORE : BUS_LOAD;
                        dp_lsq_o[thread_idx].mem_size[lsq_route[dp_idx]]    =   MEM_SIZE'(fiq_dp_i.inst[dp_idx].r.funct3[1:0])          ;
                        dp_lsq_o[thread_idx].pc[lsq_route[dp_idx]]          =   fiq_dp_i.pc[dp_idx]                                     ;
                        dp_lsq_o[thread_idx].rob_idx[lsq_route[dp_idx]]     =   rob_dp_i[thread_sel].rob_idx[dp_idx]                    ;
                        dp_lsq_o[thread_idx].tag[lsq_route[dp_idx]]         =   fl_dp_i.tag[lsq_route[dp_idx]]                          ;
                    end
                end
            end
        end
    end

// --------------------------------------------------------------------
// DP_FIQ
// --------------------------------------------------------------------  
    always_comb begin
        dp_fiq_o.dp_num =   legal_dp_num    ;
    end

// --------------------------------------------------------------------
// DP_MT
// --------------------------------------------------------------------  
    always_comb begin
        dp_mt_o =   'b0;
        for (int unsigned thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++) begin
            if (thread_idx == thread_sel) begin
                for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
                    if (dp_idx < legal_dp_num) begin
                        dp_mt_o[thread_idx][dp_idx].wr_en   =   1'b1;
                    end else begin
                        dp_mt_o[thread_idx][dp_idx].wr_en   =   1'b0;
                    end
                    dp_mt_o[thread_idx][dp_idx].thread_idx  =   fiq_dp_i.thread_idx[dp_idx]     ;
                    dp_mt_o[thread_idx][dp_idx].rd          =   dec_rd [dp_idx]                 ;
                    dp_mt_o[thread_idx][dp_idx].rs1         =   dec_rs1[dp_idx]                 ;
                    dp_mt_o[thread_idx][dp_idx].rs2         =   dec_rs2[dp_idx]                 ;
                    if(dp_mt_o[thread_idx][dp_idx].rd == `ZERO_REG)begin
                        dp_mt_o[thread_idx][dp_idx].tag     =   `ZERO_REG                       ;
                    end else begin
                        dp_mt_o[thread_idx][dp_idx].tag     =   fl_dp_i.tag[fl_route[dp_idx]]   ;
                    end//if-else
                end
            end 
        end
    end

// --------------------------------------------------------------------
// DP_RS
// --------------------------------------------------------------------  
    always_comb begin
        dp_rs_o.dp_num  =   legal_dp_num    ;
        for(int dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++)begin
            // DP_RS
            //  The rest of the signals are directly assigned in Decoder
            dp_rs_o.dec_inst[dp_idx].pc            =   fiq_dp_i.pc[dp_idx]                      ;
            dp_rs_o.dec_inst[dp_idx].inst          =   fiq_dp_i.inst[dp_idx]                    ;
            dp_rs_o.dec_inst[dp_idx].tag1          =   mt_dp_i[thread_sel][dp_idx].tag1         ;
            dp_rs_o.dec_inst[dp_idx].tag1_ready    =   mt_dp_i[thread_sel][dp_idx].tag1_ready   ;
            dp_rs_o.dec_inst[dp_idx].tag2          =   mt_dp_i[thread_sel][dp_idx].tag2         ; 
            dp_rs_o.dec_inst[dp_idx].tag2_ready    =   mt_dp_i[thread_sel][dp_idx].tag2_ready   ;
            dp_rs_o.dec_inst[dp_idx].thread_idx    =   fiq_dp_i.thread_idx[dp_idx]              ;
            dp_rs_o.dec_inst[dp_idx].rob_idx       =   rob_dp_i[thread_sel].rob_idx[dp_idx]     ;
            if(dp_mt_o[thread_sel][dp_idx].rd == `ZERO_REG)begin
                dp_rs_o.dec_inst[dp_idx].tag      =   `ZERO_REG   ;
            end else begin
                dp_rs_o.dec_inst[dp_idx].tag      =   fl_dp_i.tag[fl_route[dp_idx]]  ;
            end//if-else
        end
    end


// --------------------------------------------------------------------
// DP_ROB
// --------------------------------------------------------------------  
    always_comb begin
        dp_rob_o    =   'b0     ;
        for (int unsigned thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++) begin
            if (thread_idx == thread_sel) begin
                dp_rob_o[thread_idx].dp_num =   legal_dp_num    ;
                for(int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++)begin
                    dp_rob_o[thread_idx].tag_old[dp_idx]    =   mt_dp_i[thread_idx][dp_idx].tag_old ;
                    dp_rob_o[thread_idx].br_predict[dp_idx] =   fiq_dp_i.br_predict[dp_idx]         ;
                    dp_rob_o[thread_idx].pc[dp_idx]         =   fiq_dp_i.pc[dp_idx]                 ;
                    dp_rob_o[thread_idx].rd[dp_idx]         =   dp_mt_o[thread_idx][dp_idx].rd      ;
                    if(dp_mt_o[thread_idx][dp_idx].rd == `ZERO_REG)begin
                        dp_rob_o[thread_idx].tag[dp_idx]    =   `ZERO_REG   ;
                    end else begin
                        dp_rob_o[thread_idx].tag[dp_idx]    =   fl_dp_i.tag[fl_route[dp_idx]]   ;
                    end//if-else
                end
            end
        end
    end

// --------------------------------------------------------------------
// DP_FL
// --------------------------------------------------------------------  
    always_comb begin
        dp_fl_o.thread_idx  =   fiq_dp_i.thread_idx[0]  ;
        dp_fl_o.dp_num      =   fl_dp_num            ;
        // for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
        //     if((dp_idx < fl_dp_num) && (dp_mt_o[thread_sel][dp_idx].rd == `ZERO_REG))begin
        //         dp_fl_o.dp_num-- ;
        //     end//if    
        // end//for
    end

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule

// Decode an instruction: given instruction bits IR produce the
// appropriate datapath control signals.
// This is a *combinational* module (basically a PLA).

module decoder#(
    // parameter   C_DEC_IDX               =   0               ,
    parameter   C_DP_NUM_WIDTH          =   `DP_NUM_WIDTH   ,
    parameter   C_ARCH_REG_IDX_WIDTH    =   `ARCH_REG_IDX_WIDTH
)(

    //input [31:0] inst,
    //input valid_inst_in,  
    //ignore inst when low, outputs will
    //reflect noop (except valid_inst)
    //see sys_defs.svh for definition
    input   logic           [C_DP_NUM_WIDTH-1:0]    dec_idx     ,
    input   INST                                    inst        ,
    input   logic           [C_DP_NUM_WIDTH-1:0]    dp_num      ,
    output  ALU_OPA_SELECT                          opa_select  ,
    output  ALU_OPB_SELECT                          opb_select  ,

    // mux selects
    output  ALU_FUNC                            alu_func    ,
    output  logic                               rd_mem      ,
    output  logic                               wr_mem      , 
    output  logic                               cond_br     ,
    output  logic                               uncond_br   ,
    output  logic                               csr_op      ,     
    // used for CSR operations , we only used this as a cheap way to get the return code out
    output  logic                               halt        ,
    // non-zero on a halt
    output  logic                               illegal     ,
    output  logic                               mult        ,
    output  logic                               alu         ,
    
    output  logic   [C_ARCH_REG_IDX_WIDTH-1:0]  rd          ,
    output  logic   [C_ARCH_REG_IDX_WIDTH-1:0]  rs1         ,
    output  logic   [C_ARCH_REG_IDX_WIDTH-1:0]  rs2         
);
// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    logic       valid_inst_in   ;
    RD_SEL      rd_select       ;
    RS1_SEL     rs1_select      ;
    RS2_SEL     rs2_select      ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Select available channels
// --------------------------------------------------------------------
    always_comb begin
        if(dp_num > dec_idx)begin
            valid_inst_in   =   `TRUE   ;        
        end else begin
            valid_inst_in   =   `FALSE  ;
        end
    end

// --------------------------------------------------------------------
// Decode inst and get rd, rs1, rs2 & encrypted information
// --------------------------------------------------------------------

    always_comb begin
        // default control values:
        // - valid instructions must override these defaults as necessary.
        //     opa_select, opb_select, and alu_func should be set explicitly.
        // - invalid instructions should clear valid_inst.
        // - These defaults are equivalent to a noop
        // * see sys_defs.vh for the constants used here
        opa_select  =   OPA_IS_RS1  ;
        opb_select  =   OPB_IS_RS2  ;
        alu_func    =   ALU_ADD     ;

        rd_select   =   RD_NONE     ;
        rs1_select  =   RS1_NONE    ;
        rs2_select  =   RS2_NONE    ;

        csr_op      =   `FALSE      ;
        rd_mem      =   `FALSE      ; // ALU=`TRUE
        wr_mem      =   `FALSE      ; // ALU=`TRUE
        cond_br     =   `FALSE      ; // ALU=`TRUE
        uncond_br   =   `FALSE      ; // ALU=`TRUE
        mult        =   `FALSE      ; // ALU=`TRUE
        alu         =   `TRUE       ;    
        halt        =   `FALSE      ;
        illegal     =   `FALSE      ;
        if(valid_inst_in) begin    
            casez (inst)           
                `RV32_LUI: begin
                    rd_select       =   RD_USED         ;
                    opa_select      =   OPA_IS_ZERO     ;
                    opb_select      =   OPB_IS_U_IMM    ;
                end                 
                `RV32_AUIPC: begin
                    rd_select       =   RD_USED         ;
                    opa_select      =   OPA_IS_PC       ;
                    opb_select      =   OPB_IS_U_IMM    ;
                end                 
                `RV32_JAL: begin
                    rd_select       =   RD_USED         ;
                    opa_select      =   OPA_IS_PC       ;
                    opb_select      =   OPB_IS_J_IMM    ;
                    uncond_br       =   `TRUE           ;
                    alu             =   `FALSE          ;
                end                 
                `RV32_JALR: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opa_select      =   OPA_IS_RS1      ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    uncond_br       =   `TRUE           ;
                    alu             =   `FALSE          ;
                end             
                `RV32_BEQ, `RV32_BNE, 
                `RV32_BLT, `RV32_BGE,
                `RV32_BLTU, `RV32_BGEU: begin
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    opa_select      =   OPA_IS_PC       ;
                    opb_select      =   OPB_IS_B_IMM    ;
                    cond_br         =   `TRUE           ;
                    alu             =   `FALSE          ;
                end             
                `RV32_LB, `RV32_LH, `RV32_LW,
                `RV32_LBU, `RV32_LHU: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    rd_mem          =   `TRUE           ;
                    alu             =   `FALSE          ;
                end
                `RV32_SB, `RV32_SH, `RV32_SW: begin
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    opb_select      =   OPB_IS_S_IMM    ;
                    wr_mem          =   `TRUE           ;
                    alu             =   `FALSE          ;
                end
                `RV32_ADDI: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                end
                `RV32_SLTI: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    alu_func        =   ALU_SLT         ;
                end
                `RV32_SLTIU: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    alu_func        =   ALU_SLTU        ;
                end
                `RV32_ANDI: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    alu_func        =   ALU_AND         ;
                end
                `RV32_ORI: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    alu_func        =   ALU_OR          ;
                end
                `RV32_XORI: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    alu_func        =   ALU_XOR         ;
                end
                `RV32_SLLI: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    alu_func        =   ALU_SLL         ;
                end
                `RV32_SRLI: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    alu_func        =   ALU_SRL         ;
                end
                `RV32_SRAI: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    opb_select      =   OPB_IS_I_IMM    ;
                    alu_func        =   ALU_SRA         ;
                end
                `RV32_ADD: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                end
                `RV32_SUB: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_SUB         ;
                end
                `RV32_SLT: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_SLT         ;
                end
                `RV32_SLTU: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_SLTU        ;
                end
                `RV32_AND: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_AND         ;
                end
                `RV32_OR: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_OR          ;
                end
                `RV32_XOR: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_XOR         ;
                end
                `RV32_SLL: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_SLL         ;
                end
                `RV32_SRL: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_SRL         ;
                end
                `RV32_SRA: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_SRA         ;
                end
                `RV32_MUL: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_MUL         ;
                    alu             =   `FALSE          ;
                    mult            =   `TRUE           ;
                end
                `RV32_MULH: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_MULH        ;
                    alu             =   `FALSE          ;
                    mult            =   `TRUE           ;
                end
                `RV32_MULHSU: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_MULHSU      ;
                    alu             =   `FALSE          ;
                    mult            =   `TRUE           ;
                end
                `RV32_MULHU: begin
                    rd_select       =   RD_USED         ;
                    rs1_select      =   RS1_USED        ;
                    rs2_select      =   RS2_USED        ;
                    alu_func        =   ALU_MULHU       ;
                    alu             =   `FALSE          ;
                    mult            =   `TRUE           ;
                end
                `RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
                    csr_op          =   `TRUE           ;
                    alu             =   `FALSE          ;
                end         
                `WFI: begin         
                    halt            =   `TRUE           ;
                end         
                default:            
                    illegal         =   `TRUE           ;

            endcase // casez (inst)
        end // if(valid_inst_in)

        case (rd_select)
            RD_USED:    rd  =   inst.r.rd   ;
            RD_NONE:    rd  =   `ZERO_REG   ;
            default:    rd  =   `ZERO_REG   ; 
        endcase

        case (rs1_select)
            RS1_USED:   rs1 =   inst.r.rs1  ;
            RS1_NONE:   rs1 =   `ZERO_REG   ;
            default:    rs1 =   `ZERO_REG   ; 
        endcase

        case (rs2_select)
            RS2_USED:   rs2 =   inst.r.rs2  ;
            RS2_NONE:   rs2 =   `ZERO_REG   ;
            default:    rs2 =   `ZERO_REG   ; 
        endcase
    end // always

// ====================================================================
// RTL Logic End
// ====================================================================
endmodule // decoder




