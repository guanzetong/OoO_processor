/////////////////////////////////////////////////////////////////////////
//                                                                     //
//   Modulename :  sys_defs.vh                                         //
//                                                                     //
//  Description :  This file has the macro-defines for macros used in  //
//                 the pipeline design.                                //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


`ifndef __SYS_DEFS_VH__
`define __SYS_DEFS_VH__

/* Synthesis testing definition, used in DUT module instantiation */

`ifdef  SYNTH_TEST
`define DUT(mod) mod``_svsim
`else
`define DUT(mod) mod
`endif

//////////////////////////////////////////////
//
// Memory/testbench attribute definitions
//
//////////////////////////////////////////////
`define CACHE_MODE //removes the byte-level interface from the memory mode, DO NOT MODIFY!
`define NUM_MEM_TAGS           15

`define MEM_SIZE_IN_BYTES      (64*1024)
`define MEM_64BIT_LINES        (`MEM_SIZE_IN_BYTES/8)

//you can change the clock period to whatever, 10 is just fine
`define VERILOG_CLOCK_PERIOD   10.0
`define SYNTH_CLOCK_PERIOD     10.0 // Clock period for synth and memory latency

`define MEM_LATENCY_IN_CYCLES (100.0/`SYNTH_CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period).  The default behavior for
// float to integer conversion is rounding to nearest

typedef union packed {
    logic [7:0][7:0] byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

//////////////////////////////////////////////
// Exception codes
// This mostly follows the RISC-V Privileged spec
// except a few add-ons for our infrastructure
// The majority of them won't be used, but it's
// good to know what they are
//////////////////////////////////////////////

typedef enum logic [3:0] {
	INST_ADDR_MISALIGN  = 4'h0,
	INST_ACCESS_FAULT   = 4'h1,
	ILLEGAL_INST        = 4'h2,
	BREAKPOINT          = 4'h3,
	LOAD_ADDR_MISALIGN  = 4'h4,
	LOAD_ACCESS_FAULT   = 4'h5,
	STORE_ADDR_MISALIGN = 4'h6,
	STORE_ACCESS_FAULT  = 4'h7,
	ECALL_U_MODE        = 4'h8,
	ECALL_S_MODE        = 4'h9,
	NO_ERROR            = 4'ha, //a reserved code that we modified for our purpose
	ECALL_M_MODE        = 4'hb,
	INST_PAGE_FAULT     = 4'hc,
	LOAD_PAGE_FAULT     = 4'hd,
	HALTED_ON_WFI       = 4'he, //another reserved code that we used
	STORE_PAGE_FAULT    = 4'hf
} EXCEPTION_CODE;


//////////////////////////////////////////////
//
// Datapath control signals
//
//////////////////////////////////////////////

//
// ALU opA input mux selects
//
typedef enum logic [1:0] {
	OPA_IS_RS1  = 2'h0,
	OPA_IS_NPC  = 2'h1,
	OPA_IS_PC   = 2'h2,
	OPA_IS_ZERO = 2'h3
} ALU_OPA_SELECT;

//
// ALU opB input mux selects
//
typedef enum logic [3:0] {
	OPB_IS_RS2    = 4'h0,
	OPB_IS_I_IMM  = 4'h1,
	OPB_IS_S_IMM  = 4'h2,
	OPB_IS_B_IMM  = 4'h3,
	OPB_IS_U_IMM  = 4'h4,
	OPB_IS_J_IMM  = 4'h5
} ALU_OPB_SELECT;

//
// Destination register select
//
typedef enum logic [1:0] {
	DEST_RD = 2'h0,
	DEST_NONE  = 2'h1
} DEST_REG_SEL;

//
// ALU function code input
// probably want to leave these alone
//
typedef enum logic [4:0] {
	ALU_ADD     = 5'h00,
	ALU_SUB     = 5'h01,
	ALU_SLT     = 5'h02,
	ALU_SLTU    = 5'h03,
	ALU_AND     = 5'h04,
	ALU_OR      = 5'h05,
	ALU_XOR     = 5'h06,
	ALU_SLL     = 5'h07,
	ALU_SRL     = 5'h08,
	ALU_SRA     = 5'h09,
	ALU_MUL     = 5'h0a,
	ALU_MULH    = 5'h0b,
	ALU_MULHSU  = 5'h0c,
	ALU_MULHU   = 5'h0d,
	ALU_DIV     = 5'h0e,
	ALU_DIVU    = 5'h0f,
	ALU_REM     = 5'h10,
	ALU_REMU    = 5'h11
} ALU_FUNC;

//////////////////////////////////////////////
//
// Assorted things it is not wise to change
//
//////////////////////////////////////////////

//
// actually, you might have to change this if you change VERILOG_CLOCK_PERIOD
// JK you don't ^^^
//
`define SD #1


// the RISCV register file zero register, any read of this register always
// returns a zero value, and any write to this register is thrown away
//
`define ZERO_REG 5'd0

//
// Memory bus commands control signals
//
typedef enum logic [1:0] {
	BUS_NONE     = 2'h0,
	BUS_LOAD     = 2'h1,
	BUS_STORE    = 2'h2
} BUS_COMMAND;

`ifndef CACHE_MODE
typedef enum logic [1:0] {
	BYTE = 2'h0,
	HALF = 2'h1,
	WORD = 2'h2,
	DOUBLE = 2'h3
} MEM_SIZE;
`endif
//
// useful boolean single-bit definitions
//
`define FALSE  1'h0
`define TRUE  1'h1

// RISCV ISA SPEC
`define XLEN 32
typedef union packed {
	logic [31:0] inst;
	struct packed {
		logic [6:0] funct7;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} r; //register to register instructions
	struct packed {
		logic [11:0] imm;
		logic [4:0]  rs1; //base
		logic [2:0]  funct3;
		logic [4:0]  rd;  //dest
		logic [6:0]  opcode;
	} i; //immediate or load instructions
	struct packed {
		logic [6:0] off; //offset[11:5] for calculating address
		logic [4:0] rs2; //source
		logic [4:0] rs1; //base
		logic [2:0] funct3;
		logic [4:0] set; //offset[4:0] for calculating address
		logic [6:0] opcode;
	} s; //store instructions
	struct packed {
		logic       of; //offset[12]
		logic [5:0] s;   //offset[10:5]
		logic [4:0] rs2;//source 2
		logic [4:0] rs1;//source 1
		logic [2:0] funct3;
		logic [3:0] et; //offset[4:1]
		logic       f;  //offset[11]
		logic [6:0] opcode;
	} b; //branch instructions
	struct packed {
		logic [19:0] imm;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} u; //upper immediate instructions
	struct packed {
		logic       of; //offset[20]
		logic [9:0] et; //offset[10:1]
		logic       s;  //offset[11]
		logic [7:0] f;	//offset[19:12]
		logic [4:0] rd; //dest
		logic [6:0] opcode;
	} j;  //jump instructions
`ifdef ATOMIC_EXT
	struct packed {
		logic [4:0] funct5;
		logic       aq;
		logic       rl;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] funct3;
		logic [4:0] rd;
		logic [6:0] opcode;
	} a; //atomic instructions
`endif
`ifdef SYSTEM_EXT
	struct packed {
		logic [11:0] csr;
		logic [4:0]  rs1;
		logic [2:0]  funct3;
		logic [4:0]  rd;
		logic [6:0]  opcode;
	} sys; //system call instructions
`endif

} INST; //instruction typedef, this should cover all types of instructions

//
// Basic NOP instruction.  Allows pipline registers to clearly be reset with
// an instruction that does nothing instead of Zero which is really an ADDI x0, x0, 0
//
`define NOP 32'h00000013

//////////////////////////////////////////////
//
// IF Packets:
// Data that is exchanged between the IF and the ID stages  
//
//////////////////////////////////////////////

typedef struct packed {
	logic 								  valid		; // If low, the data in this struct is garbage
    INST       							  inst		; // fetched instruction out
	logic [`XLEN-1:0] 					  NPC		; // PC + 4
	logic [`XLEN-1:0]   				  PC		; // PC 
	logic [`THREAD_IDX_WIDTH-1:0]         thread_idx;
} IF_DP_PACKET;

//////////////////////////////////////////////
//
// ID Packets:
// Data that is exchanged from ID to EX stage
//
//////////////////////////////////////////////

typedef struct packed {
	logic [`XLEN-1:0] NPC;   // PC + 4
	logic [`XLEN-1:0] PC;    // PC

	logic [`XLEN-1:0] rs1_value;    // reg A value                                  
	logic [`XLEN-1:0] rs2_value;    // reg B value                                  
	                                                                                
	ALU_OPA_SELECT opa_select; // ALU opa mux select (ALU_OPA_xxx *)
	ALU_OPB_SELECT opb_select; // ALU opb mux select (ALU_OPB_xxx *)
	INST inst;                 // instruction
	
	logic [4:0] dest_reg_idx;  // destination (writeback) register index      
	ALU_FUNC    alu_func;      // ALU function select (ALU_xxx *)
	logic       rd_mem;        // does inst read memory?
	logic       wr_mem;        // does inst write memory?
	logic       cond_branch;   // is inst a conditional branch?
	logic       uncond_branch; // is inst an unconditional branch?
	logic       halt;          // is this a halt?
	logic       illegal;       // is this instruction illegal?
	logic       csr_op;        // is this a CSR operation? (we only used this as a cheap way to get return code)
	logic       valid;         // is inst a valid instruction to be counted for CPI calculations?
} FU_PACKET;

typedef struct packed {
	logic [`XLEN-1:0] alu_result; // alu_result
	logic [`XLEN-1:0] NPC; //pc + 4
	logic             take_branch; // is this a taken branch?
	//pass throughs from decode stage
	logic [`XLEN-1:0] rs2_value;
	logic             rd_mem, wr_mem;
	logic [4:0]       dest_reg_idx;
	logic             halt, illegal, csr_op, valid;
	logic [2:0]       mem_size; // byte, half-word or word
} EX_MEM_PACKET;

`endif // __SYS_DEFS_VH__

//////////////////////////////////////////////
// 
// Architecture Parameters
// 
//////////////////////////////////////////////
`define DP_NUM          2   // The number of Dispatch channels.
`define IS_NUM          2   // The number of Issue channels.
`define CDB_NUM         2   // The number of CDB/Complete channels.
`define RT_NUM          2   // The number of Retire channels.
`define ROB_ENTRY_NUM   32  // The number of ROB entries.
`define RS_ENTRY_NUM    32	// The number of RS entries.
`define ARCH_REG_NUM    32  // The number of Architectural registers.
`define PHY_REG_NUM     64  // The number of Physical registers.
`define BR_NUM          1   // The number of Branch Resolvers.
`define THREAD_NUM      2

`define ALU_NUM         3
`define MULT_NUM        2
`define BR_NUM          1
`define LOAD_NUM        1
`define STORE_NUM       1
`define FU_NUM          `ALU_NUM + `MULT_NUM + `BR_NUM + `LOAD_NUM + `STORE_NUM

//////////////////////////////////////////////
// 
// Interfaces between modules
// 
//////////////////////////////////////////////

`define ARCH_REG_IDX_WIDTH  $clog2(`ARCH_REG_NUM)
`define TAG_IDX_WIDTH       $clog2(`PHY_REG_NUM)
`define ROB_IDX_WIDTH       $clog2(`ROB_ENTRY_NUM)
`define THREAD_IDX_WIDTH    $clog2(`THREAD_NUM)

`define DP_NUM_WIDTH        $clog2(`DP_NUM)+1
`define RT_NUM_WIDTH        $clog2(`RT_NUM)+1

// Array Entry Contents Start

// typedef struct packed {
//     logic   [`XLEN-1:0]                 pc          ;
//     logic   [`ARCH_REG_IDX_WIDTH-1:0]   rd          ;
//     logic   [`TAG_IDX_WIDTH-1:0]        tag_old     ;
//     logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
//     logic                               br_predict  ;
// } ROB_DATA;

typedef struct packed {
    logic   [`XLEN-1:0]                 pc          ;
    logic   [`XLEN-1:0]                 inst        ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag1        ;
    logic                               tag1_ready  ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag2        ;
    logic                               tag2_ready  ;
    logic   [`THREAD_IDX_WIDTH-1:0]     thread_idx  ;
    logic   [`ROB_IDX_WIDTH-1:0]        rob_idx     ;
    ALU_OPA_SELECT                      opa_select  ;
    ALU_OPB_SELECT                      opb_select  ;
    ALU_FUNC                            alu_func    ;
    logic                               rd_mem      ;
    logic                               wr_mem      ;
    logic                               cond_br     ;
    logic                               uncond_br   ;
    logic                               halt        ;
    logic                               illegal     ;
    logic                               csr_op      ;
} DEC_INST;

// This specifies a queue of instructions that are exposed
// by the interface as well as the number of the instructions that
// are available. This will allow for the dispatcher to look at the 
// inst_queued and realize which instructions are available 
// (e.g. if inst_avail == 2), inst_queued[0]  and inst_queued[1]
// are valid instructions (that can be dispatched).
typedef struct packed {
	logic   [`DP_NUM-1:0]				inst_queued ;
	logic 	[`DP_NUM_WIDTH-1:0]			inst_avail  ;
} FET_DP;

typedef struct packed {
    logic                               valid       ;
    // ROB_DATA                            rob_data    ;
    logic   [`XLEN-1:0]                 pc          ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]   rd          ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag_old     ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
    logic                               br_predict  ;
    logic                               br_result   ;
    logic                               complete    ;
} ROB_ENTRY;

typedef struct packed {
    logic                               ready       ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]           ;
    logic   [`TAG_IDX_WIDTH-1:0]        phy_reg     ;
} MT_ENTRY;

typedef struct packed {
    logic                               valid       ;
    DEC_INST                            dec_inst    ;
    // logic   [`XLEN-1:0]                 pc          ;
    // logic   [`XLEN-1:0]                 inst        ;
    // logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
    // logic   [`TAG_IDX_WIDTH-1:0]        tag1        ;
    // logic                               tag1_ready  ;
    // logic   [`TAG_IDX_WIDTH-1:0]        tag2        ;
    // logic                               tag2_ready  ;
    // logic   [`THREAD_IDX_WIDTH-1:0]     thread_idx  ;
    // logic   [`ROB_IDX_WIDTH-1:0]        rob_idx     ;
    // ALU_OPA_SELECT                      opa_select  ;
    // ALU_OPB_SELECT                      opb_select  ;
    // ALU_FUNC                            alu_func    ;
    // logic                               rd_mem      ;
    // logic                               wr_mem      ;
    // logic                               cond_br     ;
    // logic                               uncond_br   ;
    // logic                               halt        ;
    // logic                               illegal     ;
    // logic                               csr_op      ;
} RS_ENTRY;

// Array Entry Contents End

// Interface Start

//  If an interface is marked as "Combined", no external dimension should
//  be defined at port instantiation.
//  If an interface is marked as "Per-Channel", an external dimension should
//  be defined at port instantiation as the number of channels.

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     dp_num      ;
    logic   [`DP_NUM-1:0][`XLEN-1:0]                pc          ;
    logic   [`DP_NUM-1:0][`ARCH_REG_IDX_WIDTH-1:0]  rd          ;
    logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag         ;
    logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag_old     ;
    logic   [`DP_NUM-1:0]                           br_predict  ;
} DP_ROB; // Combined

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     avail_num   ;
    logic   [`DP_NUM-1:0][`ROB_IDX_WIDTH-1:0]       rob_idx     ;
} ROB_DP; // Combined

typedef struct packed{
    logic                                           valid       ;   // Is this signal valid?
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;   // Physical Register (Used for broadcasting to M_T and RS)
    logic   [`ROB_IDX_WIDTH-1:0]                    rob_idx     ;   // Used to locate rob entry
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;   // Used to locate rob entry
    logic                                           br_result   ;   // Branch result
} CDB; // Per-Channel

typedef struct packed {
    logic                                           wr_en       ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               arch_reg    ;   // Key
    logic   [`TAG_IDX_WIDTH-1:0]                    phy_reg     ;   // Value
} ROB_AMT; // Per-Channel

typedef struct packed {
    logic   [`RT_NUM_WIDTH-1:0]                     rt_num      ;
    logic   [`RT_NUM-1:0][`TAG_IDX_WIDTH-1:0]       phy_reg     ;
} ROB_FL; // Combined

typedef struct packed {
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs1         ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs2         ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rd          ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;
    logic                                           wr_en       ;
} DP_MT; // Per-Channel

typedef struct packed {
    logic   [`TAG_IDX_WIDTH-1:0]                    tag1        ;
    logic                                           tag1_ready  ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag2        ;
    logic                                           tag2_ready  ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag_old     ;
} MT_DP; // Per-Channel

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     avail_num   ;   
    logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag         ;
} FL_DP; // Combined

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     dp_num      ;
} DP_FL; // Combined

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     avail_num   ;
    INST    [`DP_NUM-1:0]                           inst        ;
    logic   [`DP_NUM-1:0][`THREAD_IDX_WIDTH-1:0]    thread_idx  ;
    logic   [`DP_NUM-1:0][`XLEN-1:0]                pc          ;
    logic   [`DP_NUM-1:0]                           br_predict  ;
} FIQ_DP; // Combined

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     dp_num      ; 
} DP_FIQ; // Combined

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     avail_num   ; 
} RS_DP; // Combined

typedef struct packed {
    logic       [`DP_NUM_WIDTH-1:0]                 dp_num      ;
    DEC_INST    [`DP_NUM-1:0]                       dec_inst    ;
    // logic   [`DP_NUM-1:0][`XLEN-1:0]                pc          ;
    // INST    [`DP_NUM-1:0]                           inst        ;
    // logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag         ;
    // logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag1        ;
    // logic   [`DP_NUM-1:0]                           tag1_ready  ;
    // logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag2        ;
    // logic   [`DP_NUM-1:0]                           tag2_ready  ;
    // logic   [`DP_NUM-1:0][`THREAD_IDX_WIDTH-1:0]    thread_idx  ;
    // logic   [`DP_NUM-1:0][`ROB_IDX_WIDTH-1:0]       rob_idx     ;
    // ALU_OPA_SELECT  [`DP_NUM-1:0]                   opa_select  ;
    // ALU_OPB_SELECT  [`DP_NUM-1:0]                   opb_select  ;
    // ALU_FUNC        [`DP_NUM-1:0]                   alu_func    ;
    // logic   [`DP_NUM-1:0]                           rd_mem      ;
    // logic   [`DP_NUM-1:0]                           wr_mem      ;
    // logic   [`DP_NUM-1:0]                           cond_br     ;
    // logic   [`DP_NUM-1:0]                           uncond_br   ;
    // logic   [`DP_NUM-1:0]                           halt        ;
    // logic   [`DP_NUM-1:0]                           illegal     ;
    // logic   [`DP_NUM-1:0]                           csr_op      ;
} DP_RS; // Combined

typedef struct packed {
    logic                                           valid       ;
    logic   [`XLEN-1:0]                             pc          ;
    INST                                            inst        ;
    logic   [`XLEN-1:0]                             rs1_value   ;
    logic   [`XLEN-1:0]                             rs2_value   ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;
    logic   [`ROB_IDX_WIDTH-1:0]                    rob_idx     ;
    ALU_OPA_SELECT                                  opa_select  ;
    ALU_OPB_SELECT                                  opb_select  ;
    ALU_FUNC                                        alu_func    ;
} RS_IB; // Per-Channel

typedef struct packed {
    logic   [`FU_NUM-1:0]                           ready       ;
} IB_RS; // Combined

typedef struct packed {
    logic   [`TAG_IDX_WIDTH-1:0]                    rd_addr1    ;
    logic   [`TAG_IDX_WIDTH-1:0]                    rd_addr2    ;
} RS_PRF; // Per-Channel

typedef struct packed {
    logic   [`XLEN-1:0]                             data_out1   ;
    logic   [`XLEN-1:0]                             data_out2   ;
} PRF_RS; // Per-Channel

typedef struct packed {
    logic                                           valid       ;
    logic   [`XLEN-1:0]                             pc          ;
    INST                                            inst        ;
    logic   [`XLEN-1:0]                             rs1_value   ;
    logic   [`XLEN-1:0]                             rs2_value   ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;
    logic   [`ROB_IDX_WIDTH-1:0]                    rob_idx     ;
    ALU_OPA_SELECT                                  opa_select  ;
    ALU_OPB_SELECT                                  opb_select  ;
    ALU_FUNC                                        alu_func    ;
} IB_FU; // Per-Channel

typedef struct packed {
    logic                                           ready       ;
} FU_IB; // Per-Channel

typedef struct packed {
    logic                                           valid       ;
    logic   [`XLEN-1:0]                             rd_value    ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;
    logic                                           br_result   ;
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;
    logic   [`ROB_IDX_WIDTH-1:0]                    rob_idx     ;
} FU_BC; // Per-Channel

typedef struct packed {
    logic                                           ready       ;
} BC_FU; // Per-Channel

typedef struct packed {
    logic   [`TAG_IDX_WIDTH-1:0]                    wr_addr     ;
    logic   [`XLEN-1:0]                             data_in     ;
    logic                                           wr_en       ;
} BC_PRF; // Per-Channel

typedef struct packed {
    logic   [`THREAD_NUM-1:0]                       valid       ;
} BR_MIS; // Combined

// Interface End