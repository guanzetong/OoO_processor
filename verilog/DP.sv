/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  DP.sv                                               //
//                                                                     //
//  Description :  DP MODULE of the pipeline;                          // 
//                 The Dispatcher is designed to check the             //
//                 structural hazards from ROB, RS, FIQ and FL.        //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module DP # ( 
    parameter       C_DP_NUM                =   `DP_NUM         ,
    parameter       C_THREAD_NUM            =   `THREAD_NUM     ,
    parameter       C_ROB_ENTRY_NUM         =   `ROB_ENTRY_NUM  ,
    parameter       C_ARCH_REG_NUM          =   `ARCH_REG_NUM   ,
    parameter       C_PHY_REG_NUM           =   `PHY_REG_NUM    
)(    
    input           ROB_DP                      rob_dp_i        ,
    output          DP_ROB                      dp_rob_o        ,
    input           MT_DP       [C_DP_NUM-1:0]  mt_dp_i         ,   
    output          DP_MT_READ  [C_DP_NUM-1:0]  dp_mt_read_o    ,
    output          DP_MT_WRITE [C_DP_NUM-1:0]  dp_mt_write_o   ,
    input           FL_DP                       fl_dp_i         ,   
    output          DP_FL                       dp_fl_o         ,
    input           FIQ_DP                      fiq_dp_i        ,   
    output          DP_FIQ                      dp_fiq_o        ,
    input           RS_DP                       rs_dp_i         ,   
    output          DP_RS                       dp_rs_o         
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
    logic   [C_DP_NUM_WIDTH-1:0]                comp_1      ;   // Dispatch number comparator output
    logic   [C_DP_NUM_WIDTH-1:0]                comp_2      ;   // Dispatch number comparator output
    logic   [C_DP_NUM_WIDTH-1:0]                dp_num      ;
    logic   [C_DP_NUM-1:0][C_DP_NUM_WIDTH-1:0]  fl_route    ;
    INST    [C_DP_NUM-1:0]                      inst        ;
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
            decoder#(
                .C_DEC_IDX  (dec_idx                                )
            )decoder_inst(
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

                .rd         (dp_mt_write_o[dec_idx].rd              ),
                .rs1        (dp_mt_read_o[dec_idx].rs1              ),
                .rs2        (dp_mt_read_o[dec_idx].rs2              )
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
    function automatic logic [C_DP_NUM-1:0][C_DP_NUM_WIDTH-1:0] route;
        input   logic   [C_DP_NUM_WIDTH-1:0]    dp_num;
        int     fl_idx   ;
        begin
            fl_idx  =   0;
            route   =   0;
            for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
                if ((dp_idx < dp_num) && (dp_mt_write_o[dp_idx].rd != `ZERO_REG)) begin
                    route[dp_idx]   =   fl_idx;
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
//  actual number of dispatched instructions known as the comparator
// --------------------------------------------------------------------
    always_comb begin
        // calculates the actual minum number of dispatched entries.
        if (rob_dp_i.avail_num < fiq_dp_i.avail_num) begin 
            comp_1  =   rob_dp_i.avail_num  ;   
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

        dp_rob_o.dp_num  =   dp_num    ;
        dp_fiq_o.dp_num  =   dp_num    ;
        dp_rs_o.dp_num   =   dp_num    ;
        dp_fl_o.dp_num   =   dp_num    ;

        for (int idx = 0; idx < C_DP_NUM; idx++) begin
            if(idx < dp_num && (dp_mt_write_o[idx].rd == `ZERO_REG))begin
                dp_fl_o.dp_num-- ;
            end//if    
        end//for
    end//comb

// --------------------------------------------------------------------
// get what RS needs without decoder to update in the DEC_INST
// get tags renewed from fl needs consider OoO
// --------------------------------------------------------------------  
    always_comb begin
        fl_route    =    route(dp_num);
        for(int idx=0; idx < C_DP_NUM; idx++)begin
            // DP_RS
            //  The rest of the signals are directly assigned in Decoder
            dp_rs_o.dec_inst[idx].pc            =   fiq_dp_i.pc[idx]          ;
            dp_rs_o.dec_inst[idx].inst          =   fiq_dp_i.inst[idx]        ;
            dp_rs_o.dec_inst[idx].tag1          =   mt_dp_i[idx].tag1         ;
            dp_rs_o.dec_inst[idx].tag1_ready    =   mt_dp_i[idx].tag1_ready   ;
            dp_rs_o.dec_inst[idx].tag2          =   mt_dp_i[idx].tag2         ; 
            dp_rs_o.dec_inst[idx].tag2_ready    =   mt_dp_i[idx].tag2_ready   ;
            dp_rs_o.dec_inst[idx].thread_idx    =   fiq_dp_i.thread_idx[idx]  ;
            dp_rs_o.dec_inst[idx].rob_idx       =   rob_dp_i.rob_idx[idx]     ;

            // DP_MT
            if (idx < dp_num) begin
                dp_mt_write_o[idx].wr_en    =   1'b1;
            end else begin
                dp_mt_write_o[idx].wr_en    =   1'b0;
            end
            dp_mt_write_o[idx].thread_idx   =   fiq_dp_i.thread_idx[idx]   ;
            dp_mt_read_o[idx].thread_idx    =   fiq_dp_i.thread_idx[idx]   ;

            // DP_ROB
            dp_rob_o.tag_old[idx]           =   mt_dp_i[idx].tag_old        ;
            dp_rob_o.br_predict[idx]        =   fiq_dp_i.br_predict[idx]    ;   
            dp_rob_o.pc[idx]                =   fiq_dp_i.pc[idx]            ;
            dp_rob_o.rd[idx]                =   dp_mt_write_o[idx].rd    ;

            // Free List routing
            if(dp_mt_write_o[idx].rd == `ZERO_REG)begin
                dp_rs_o.dec_inst[idx].tag   =   `ZERO_REG   ;
                dp_rob_o.tag[idx]           =   `ZERO_REG   ;
                dp_mt_write_o[idx].tag      =   `ZERO_REG   ;
            end else begin
                dp_rs_o.dec_inst[idx].tag   =   fl_dp_i.tag[fl_route[idx]]  ;
                dp_rob_o.tag[idx]           =   fl_dp_i.tag[fl_route[idx]]  ;
                dp_mt_write_o[idx].tag      =   fl_dp_i.tag[fl_route[idx]]  ;
            end//if-else
        end//for
    end//comb

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule

// Decode an instruction: given instruction bits IR produce the
// appropriate datapath control signals.
// This is a *combinational* module (basically a PLA).

module decoder#(
    parameter   C_DEC_IDX               =   0               ,
    parameter   C_DP_NUM_WIDTH          =   `DP_NUM_WIDTH   ,
    parameter   C_ARCH_REG_IDX_WIDTH    =   `ARCH_REG_IDX_WIDTH
)(

    //input [31:0] inst,
    //input valid_inst_in,  
    //ignore inst when low, outputs will
    //reflect noop (except valid_inst)
    //see sys_defs.svh for definition

    input   INST                                inst        ,
    input   logic    [C_DP_NUM_WIDTH-1:0]       dp_num      ,
    output  ALU_OPA_SELECT                      opa_select  ,
    output  ALU_OPB_SELECT                      opb_select  ,

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
        if(dp_num > C_DEC_IDX)begin
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

        csr_op      =   `FALSE      ; // ALU=`TRUE
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




