/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  DP.sv                                               //
//                                                                     //
//  Description :  DP MODULE of the pipeline;                          // 
//                 The Dispatcher is designed to check the             //
//                 structural hazards from ROB, RS, FIQ and FL.        //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module DP # ( 
    parameter       C_DP_NUM                =   `DP_NUM         ,
    parameter       C_THREAD_NUM            =   `THREAD_NUM     ,
    parameter       C_ROB_ENTRY_NUM         =   `ROB_ENTRY_NUM  ,
    parameter       C_ARCH_REG_NUM          =   `ARCH_REG_NUM   ,
    parameter       C_PHY_REG_NUM           =   `PHY_REG_NUM    
)(    
    input           ROB_DP                      rob_dp_i        ,   
    output          DP_ROB                      dp_rob_o        ,
    //combined   
     
    input           MT_DP   [C_DP_NUM-1:0]      mt_dp_i         ,   
    output          DP_MT   [C_DP_NUM-1:0]      dp_mt_o         ,
    //per_channel    
     
    input           FL_DP                       fl_dp_i         ,   
    output          DP_FL                       dp_fl_o         ,
    //combined   
     
    input           FIQ_DP                      fiq_dp_i        ,   
    output          DP_FIQ                      dp_fiq_o        ,
    //combined       
     
    input           RS_DP                       rs_dp_i         ,   
    output          DP_RS                       dp_rs_o         
    //combined
);//declaration of the interactive structures


// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam      C_DP_IDX_WIDTH          =   $clog2(C_DP_NUM+1)     ;
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

    logic           [C_DP_IDX_WIDTH-1:0]           comp_tmp1  ;
    logic           [C_DP_IDX_WIDTH-1:0]           comp_tmp2  ;
    logic           [C_DP_IDX_WIDTH-1:0]           comp_out   ;
	logic 			[C_DP_IDX_WIDTH-1:0]		   dp_num     ;
             
// ====================================================================
// Signal Declarations End
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
            comp_tmp1    =   rob_dp_i.avail_num  ;   
        end else begin
            comp_tmp1    =   fiq_dp_i.avail_num  ; 
        end//if-else
        
        if (fl_dp_i.avail_num < rs_dp_i.avail_num) begin 
            comp_tmp2    =   fl_dp_i.avail_num   ;   
        end else begin
            comp_tmp2    =   rs_dp_i.avail_num   ; 
        end//if-else

        if (comp_tmp1 < comp_tmp2) begin 
            comp_out      	 =   comp_tmp1   ;  
        end else begin
            comp_out     	 =   comp_tmp2   ;
        end//if-else

		dp_rob_o.dp_num  =   comp_out    ;
		dp_fl_o.dp_num   =   comp_out    ;
		dp_fiq_o.dp_num  =   comp_out    ;
		dp_rs_o.dp_num   =   comp_out    ; 
    end//comb

// --------------------------------------------------------------------
// use dp_num to tell how many channels can be dispatched in MT
// --------------------------------------------------------------------
    always_comb begin
    //  wr_en_concat   =   'b0;
        for (int idx = 0; idx < C_DP_NUM; idx++) begin
            dp_mt_o[idx].thread_idx  = fiq_dp_i.thread_idx[idx];
            if (idx < comp_out) begin
                dp_mt_o[idx].wr_en   =   1'b1;
            end else begin
                dp_mt_o[idx].wr_en   =   1'b0;
            end
        end//for
    end//comb

// --------------------------------------------------------------------
// pull and push what ROB needs
// --------------------------------------------------------------------
    
    assign    dp_rob_o.br_predict =   fiq_dp_i.br_predict   ;
    assign    dp_rob_o.pc         =   fiq_dp_i.pc           ;
    assign    dp_rob_o.tag        =   fl_dp_i.tag           ;
    always_comb begin
        for (integer idx = 0; idx < C_DP_NUM; idx = idx++ ) begin
            dp_rob_o.tag_old[idx]    =   mt_dp_i[idx].tag_old  ;
        end
    end//comb

// --------------------------------------------------------------------
// get what RS needs without decoder to update in the DEC_INST
// --------------------------------------------------------------------

    always_comb begin
        for(int idx=0; idx < C_DP_NUM; idx++)begin
        dp_rs_o.dec_inst[idx].pc          =   fiq_dp_i.pc[idx]          ;
        dp_rs_o.dec_inst[idx].inst        =   fiq_dp_i.inst[idx]        ;
        dp_rs_o.dec_inst[idx].tag         =   fl_dp_i.tag[idx]          ;
        dp_rs_o.dec_inst[idx].tag1        =   mt_dp_i[idx].tag1         ;
        dp_rs_o.dec_inst[idx].tag1_ready  =   mt_dp_i[idx].tag1_ready   ;
        dp_rs_o.dec_inst[idx].tag2        =   mt_dp_i[idx].tag2         ; 
        dp_rs_o.dec_inst[idx].tag2_ready  =   mt_dp_i[idx].tag2_ready   ;
        dp_rs_o.dec_inst[idx].thread_idx  =   fiq_dp_i.thread_idx[idx]  ;
        dp_rs_o.dec_inst[idx].rob_idx     =   rob_dp_i.rob_idx[idx]     ;
        end
    end//comb

// --------------------------------------------------------------------
// decoder insts from FIQ and send to RS using generate initialization
// --------------------------------------------------------------------

    INST     [C_DP_NUM-1:0]  inst   ;
    // logic    [C_DP_NUM_WIDTH-1:0]  dp_num   ;
    // assign   dp_num   =   fiq_dp_i.dp_num   ;

	assign dp_num      =   comp_out;

    genvar  idx;
    generate
        for(idx=0; idx < C_DP_NUM; idx++) begin 
            assign inst[idx]   =   fiq_dp_i.inst[idx];// initialize inst
            decoder#(
                .C_DEC_IDX(idx)
            )decoder_inst(
                .inst       (inst[idx]), 
                .dp_num     (dp_num)   ,
		        // inputs
		        .opa_select (dp_rs_o.dec_inst[idx].opa_select) ,
		        .opb_select (dp_rs_o.dec_inst[idx].opb_select) ,

		        .alu_func   (dp_rs_o.dec_inst[idx].alu_func)   ,
                .rd_mem     (dp_rs_o.dec_inst[idx].rd_mem)     ,
		        .wr_mem     (dp_rs_o.dec_inst[idx].wr_mem)     ,
		        .cond_br    (dp_rs_o.dec_inst[idx].cond_br)    ,
		        .uncond_br  (dp_rs_o.dec_inst[idx].uncond_br)  ,
		        .csr_op     (dp_rs_o.dec_inst[idx].csr_op)     ,

		        .halt       (dp_rs_o.dec_inst[idx].halt)       ,

		        .illegal    (dp_rs_o.dec_inst[idx].illegal)    ,
                .mult       (dp_rs_o.dec_inst[idx].mult)       ,
                .alu        (dp_rs_o.dec_inst[idx].alu)        ,

                .rd         (dp_rs_o.dec_inst[idx].rd)         ,
                .rs1        (dp_rs_o.dec_inst[idx].rs1)        ,
                .rs2        (dp_rs_o.dec_inst[idx].rs2)        
                // outputs
            );
        end
    endgenerate

// --------------------------------------------------------------------
// get destination tag from FL and send to RS MT ROB to update
// --------------------------------------------------------------------
    
    //assign    dp_rob_o.tag        =   fl_dp_i.tag  ;//
    
    always_comb begin
        for (integer idx = 0; idx < C_DP_NUM; idx = idx++ ) begin
            dp_mt_o[idx].tag    =   fl_dp_i.tag[idx]  ;
            //dp_rs_o.dec_inst[idx].tag   =   fl_dp_i.tag[idx]   ;//
        end
    end//comb
   

// --------------------------------------------------------------------
// use decoder results to send registers to MT and ROB
// --------------------------------------------------------------------

    always_comb begin

        for (integer idx = 0; idx < C_DP_NUM; idx = idx++ ) begin
            dp_mt_o[idx].rd  = dp_rs_o.dec_inst[idx].rd   ;
            dp_mt_o[idx].rs1 = dp_rs_o.dec_inst[idx].rs1  ;
            dp_mt_o[idx].rs2 = dp_rs_o.dec_inst[idx].rs2  ;
            dp_rob_o.rd[idx] = dp_rs_o.dec_inst[idx].rd  ;

        end
    end//comb

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule


// typedef struct packed {
// } DP_LSQ;

// ID_stage & EX_stage


`timescale 1ns/100ps

// Decode an instruction: given instruction bits IR produce the
// appropriate datapath control signals.
// This is a *combinational* module (basically a PLA).

module decoder#(
    parameter     C_DEC_IDX    		   =   0
)(

	//input [31:0] inst,
	//input valid_inst_in,  
    //ignore inst when low, outputs will
	//reflect noop (except valid_inst)
	//see sys_defs.svh for definition

	input 	INST 						 inst	     ,
	input 	logic	[2:0] 				 dp_num		 ,
	output  ALU_OPA_SELECT          	 opa_select  ,
	output  ALU_OPB_SELECT         		 opb_select  ,

    // mux selects
	output  ALU_FUNC               		 alu_func    ,
	output  logic                   	 rd_mem      ,
    output  logic                 		 wr_mem      , 
    output  logic                 		 cond_br     ,
    output  logic                 		 uncond_br   ,
	output  logic                 		 csr_op      ,     
    // used for CSR operations, we only used this as a cheap way to get the return code out
	output  logic                   	 halt        ,
    // non-zero on a halt
	output  logic                   	 illegal     ,
	output  logic                   	 mult	     ,
	output  logic                   	 alu	     ,

	output  logic	[4:0]            	 rd          ,
	output  logic	[4:0]                rs1         ,
	output  logic	[4:0]                rs2         
);
// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
	logic 					valid_inst_in	;
	RD_SEL 					rd_select		;
	RS1_SEL					rs1_select		;
	RS2_SEL					rs2_select		;
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
			valid_inst_in =   `TRUE		;		
		end else begin
			valid_inst_in =   `FALSE	;
		end
	end

// --------------------------------------------------------------------
// Decode inst and get rd, rs1, rs2 & encrypted information
// --------------------------------------------------------------------

	always_comb begin
		// default control values:
		// - valid instructions must override these defaults as necessary.
		//	 opa_select, opb_select, and alu_func should be set explicitly.
		// - invalid instructions should clear valid_inst.
		// - These defaults are equivalent to a noop
		// * see sys_defs.vh for the constants used here
		opa_select     =    OPA_IS_RS1    ;
		opb_select     =    OPB_IS_RS2    ;
		alu_func       =    ALU_ADD       ;

		rd 		       =    RD_NONE       ;
		rs1 		   =    RS1_NONE      ;
		rs2 		   =    RS2_NONE      ;

		csr_op         =    `FALSE        ;//ALU=`TRUE
		rd_mem         =    `FALSE        ;//ALU=`TRUE
		wr_mem         =    `FALSE        ;//ALU=`TRUE
		cond_br        =    `FALSE        ;//ALU=`TRUE
		uncond_br      =    `FALSE        ;//ALU=`TRUE
		mult 		   =  	`FALSE        ;//ALU=`TRUE
		alu			   =	`TRUE		  ;	
		halt           =    `FALSE        ;
		illegal        =    `FALSE        ;
		if(valid_inst_in) begin    
			casez (inst)           
				`RV32_LUI: begin     
					rd         		 =    RD_USED       ;
					opa_select       =    OPA_IS_ZERO   ;
					opb_select       =    OPB_IS_U_IMM  ;
				end                  
				`RV32_AUIPC: begin       
					rd         		 =    RD_USED       ;
					opa_select       =    OPA_IS_PC     ;
					opb_select       =    OPB_IS_U_IMM  ;
				end                  
				`RV32_JAL: begin         
					rd         		 =    RD_USED       ;
					opa_select       =    OPA_IS_PC     ;
					opb_select       =    OPB_IS_J_IMM  ;
					uncond_br        =    `TRUE         ;
					alu				 =	  `FALSE        ;
				end                  
				`RV32_JALR: begin        
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opa_select       =    OPA_IS_RS1    ;
					opb_select       =    OPB_IS_I_IMM  ;
					uncond_br        =    `TRUE         ;
					alu				 =	  `FALSE        ;
				end             
				`RV32_BEQ, `RV32_BNE, 
				`RV32_BLT, `RV32_BGE,
				`RV32_BLTU, `RV32_BGEU: begin
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					opa_select       =    OPA_IS_PC     ;
					opb_select       =    OPB_IS_B_IMM  ;
					cond_br          =    `TRUE         ;
					alu				 =	  `FALSE        ;
				end             
				`RV32_LB, `RV32_LH, `RV32_LW,
				`RV32_LBU, `RV32_LHU: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					rd_mem           =    `TRUE         ;
					alu				 =	  `FALSE        ;
				end
				`RV32_SB, `RV32_SH, `RV32_SW: begin
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					opb_select       =    OPB_IS_S_IMM  ;
					wr_mem           =    `TRUE         ;
					alu				 =	  `FALSE        ;
				end
				`RV32_ADDI: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
				end
				`RV32_SLTI: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					alu_func         =    ALU_SLT       ;
				end
				`RV32_SLTIU: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					alu_func         =    ALU_SLTU      ;
				end
				`RV32_ANDI: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					alu_func         =    ALU_AND       ;
				end
				`RV32_ORI: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					alu_func         =    ALU_OR        ;
				end
				`RV32_XORI: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					alu_func         =    ALU_XOR       ;
				end
				`RV32_SLLI: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					alu_func         =    ALU_SLL       ;
				end
				`RV32_SRLI: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					alu_func         =    ALU_SRL       ;
				end
				`RV32_SRAI: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					opb_select       =    OPB_IS_I_IMM  ;
					alu_func         =    ALU_SRA       ;
				end
				`RV32_ADD: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
				end
				`RV32_SUB: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_SUB       ;
				end
				`RV32_SLT: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_SLT       ;
				end
				`RV32_SLTU: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_SLTU      ;
				end
				`RV32_AND: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_AND       ;
				end
				`RV32_OR: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_OR        ;
				end
				`RV32_XOR: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_XOR       ;
				end
				`RV32_SLL: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_SLL       ;
				end
				`RV32_SRL: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_SRL       ;
				end
				`RV32_SRA: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_SRA       ;
				end
				`RV32_MUL: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_MUL       ;
					mult			 =	  `TRUE         ;
				end
				`RV32_MULH: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_MULH      ;
					mult			 =	  `TRUE         ;
				end
				`RV32_MULHSU: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_MULHSU    ;
					mult			 =	  `TRUE         ;
				end
				`RV32_MULHU: begin
					rd         		 =    RD_USED       ;
					rs1				 =    RS1_USED      ;
					rs2				 =    RS2_USED      ;
					alu_func         =    ALU_MULHU     ;
					mult			 =	  `TRUE         ;
				end
				`RV32_CSRRW, `RV32_CSRRS, `RV32_CSRRC: begin
					csr_op           =    `TRUE         ;
					alu				 =	  `FALSE        ;
				end         
				`WFI: begin         
					halt             =    `TRUE         ;
				end         
				default:            
                    illegal          =    `TRUE         ;

			endcase // casez (inst)

			case (rd_select)
				RD_USED:     rd  = inst.r.rd ;
				RD_NONE:     rd  = `ZERO_REG ;
				default:     rd  = `ZERO_REG ; 
			endcase

			case (rs1_select)
				RS1_USED:    rs1 = inst.r.rs1;
				RS1_NONE:    rs1 = `ZERO_REG ;
				default:     rs1 = `ZERO_REG ; 
			endcase

			case (rs2_select)
				RS2_USED:    rs2 = inst.r.rs2;
				RS2_NONE:    rs2 = `ZERO_REG ;
				default:     rs2 = `ZERO_REG ; 
			endcase

		end // if(valid_inst_in)
	end // always

// ====================================================================
// RTL Logic End
// ====================================================================
endmodule // decoder



// update sys_defs.svh line 104
// //
// // Destination register select
// //
// typedef enum logic [1:0] {
// 	RD_USED  = 2'h0,
// 	RD_NONE  = 2'h1
// } RD_SEL;

// //
// // Source register 1 select
// //
// typedef enum logic [1:0] {
// 	RS1_USED  = 2'h0,
// 	RS1_NONE  = 2'h1
// } RS1_SEL;

// //
// // Source register 2 select
// //
// typedef enum logic [1:0] {
// 	RS2_USED  = 2'h0,
// 	RS2_USED  = 2'h1
// } RS2_SEL;



