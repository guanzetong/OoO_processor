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
`define SYNTH_CLOCK_PERIOD     20.0 // Clock period for synth and memory latency

`define MEM_LATENCY_IN_CYCLES (100.0/`SYNTH_CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period).  The default behavior for
// float to integer conversion is rounding to nearest

typedef union packed {
    logic [7:0][7:0]  byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
} EXAMPLE_CACHE_BLOCK;

//////////////////////////////////////////////
// 
// Architecture Parameters
// 
//////////////////////////////////////////////
`define FETCH_NUM       8   // The number of fetch channels.
`define IF_NUM          16  // The number of instructions buffered.
`define DP_NUM          2   // The number of Dispatch channels.
`define IS_NUM          2   // The number of Issue channels.
`define CDB_NUM         2   // The number of CDB/Complete channels.
`define RT_NUM          2   // The number of Retire channels.
`define ROB_ENTRY_NUM   32  // The number of ROB entries.
`define RS_ENTRY_NUM    16	// The number of RS entries.
`define ARCH_REG_NUM    32  // The number of Architectural registers.
`define PHY_REG_NUM     64  // The number of Physical registers.
`define FL_ENTRY_NUM    (`PHY_REG_NUM - `ARCH_REG_NUM)
`define THREAD_NUM      2

`define ALU_NUM         3
`define MULT_NUM        2
`define BR_NUM          1
`define LOAD_NUM        1
`define STORE_NUM       1
`define FU_NUM          (`ALU_NUM + `MULT_NUM + `BR_NUM + `LOAD_NUM + `STORE_NUM)

`define ALU_CYCLE       1
`define MULT_CYCLE      3
`define BR_CYCLE        1

`define ALU_Q_SIZE      8
`define MULT_Q_SIZE     8
`define BR_Q_SIZE       8
`define LOAD_Q_SIZE     8
`define STORE_Q_SIZE    8

// General Cache
`define CACHE_SIZE          256     // The capacity of cache in bytes.
`define CACHE_BLOCK_SIZE    8       // The number of bytes in a block
`define CACHE_SASS          4       // Set associativity.
`define CACHE_SET_NUM       (`CACHE_SIZE / `CACHE_BLOCK_SIZE / `CACHE_SASS)
`define MSHR_ENTRY_NUM      16      // The number of entries in the MSHR.

// ICache
`define ICACHE_SASS         2       // Set associativity.
`define ICACHE_SET_NUM      (`CACHE_SIZE / `CACHE_BLOCK_SIZE / `ICACHE_SASS)

// DCache
`define DCACHE_SASS         4       // Set associativity.
`define DCACHE_SET_NUM      (`CACHE_SIZE / `CACHE_BLOCK_SIZE / `DCACHE_SASS)

//////////////////////////////////////////////
// 
// Signal width
// 
//////////////////////////////////////////////
`define IF_IDX_WIDTH        $clog2(`IF_NUM)

`define IF_NUM_WIDTH        $clog2(`IF_NUM+1)
`define DP_NUM_WIDTH        $clog2(`DP_NUM+1)
`define RT_NUM_WIDTH        $clog2(`RT_NUM+1)

`define ARCH_REG_IDX_WIDTH  $clog2(`ARCH_REG_NUM)
`define TAG_IDX_WIDTH       $clog2(`PHY_REG_NUM)
`define ROB_IDX_WIDTH       $clog2(`ROB_ENTRY_NUM)
`define RS_IDX_WIDTH        $clog2(`RS_ENTRY_NUM)
`define THREAD_IDX_WIDTH    $clog2(`THREAD_NUM)
`define FL_IDX_WIDTH        $clog2(`FL_ENTRY_NUM)

`define ALU_IDX_WIDTH       $clog2(`ALU_Q_SIZE  )
`define MULT_IDX_WIDTH      $clog2(`MULT_Q_SIZE )
`define BR_IDX_WIDTH        $clog2(`BR_Q_SIZE   )
`define LOAD_IDX_WIDTH      $clog2(`LOAD_Q_SIZE )
`define STORE_IDX_WIDTH     $clog2(`STORE_Q_SIZE)

// General Cache
`define CACHE_OFFSET_WIDTH  $clog2(`CACHE_BLOCK_SIZE)
`define CACHE_IDX_WIDTH     $clog2(`CACHE_SET_NUM)
`define CACHE_TAG_WIDTH     (`XLEN - `CACHE_IDX_WIDTH - `CACHE_OFFSET_WIDTH)
`define MSHR_IDX_WIDTH      $clog2(`MSHR_ENTRY_NUM)

// ICache
`define ICACHE_IDX_WIDTH    $clog2(`ICACHE_SET_NUM)
`define ICACHE_TAG_WIDTH    (`XLEN - `ICACHE_IDX_WIDTH - `CACHE_OFFSET_WIDTH)

// DCache
`define DCACHE_IDX_WIDTH     $clog2(`DCACHE_SET_NUM)
`define DCACHE_TAG_WIDTH     (`XLEN - `DCACHE_IDX_WIDTH - `CACHE_OFFSET_WIDTH)

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

// `ifndef CACHE_MODE
typedef enum logic [1:0] {
    BYTE = 2'h0,
    HALF = 2'h1,
    WORD = 2'h2,
    DOUBLE = 2'h3
} MEM_SIZE;
// `endif
//
// useful boolean single-bit definitions
//
`define FALSE  1'h0
`define TRUE  1'h1

// RISCV ISA SPEC
`define XLEN 32
`define XLEN_BYTES  `XLEN >> 3

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
        logic [7:0] f;  //offset[19:12]
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

typedef enum logic [1:0] {
	RD_USED  = 2'h0,
	RD_NONE  = 2'h1
} RD_SEL;

typedef enum logic [1:0] {
	RS1_USED  = 2'h0,
	RS1_NONE  = 2'h1
} RS1_SEL;

typedef enum logic [1:0] {
	RS2_USED  = 2'h0,
	RS2_NONE  = 2'h1
} RS2_SEL;

typedef enum logic [2:0] {
    REQ_NONE        =   3'h0    ,   // Do nothing
    REQ_LOAD        =   3'h1    ,   // Load request from processor
    REQ_STORE       =   3'h2    ,   // Store request from processor
    REQ_LOAD_MISS   =   3'h3    ,   // Miss handling request from LOAD miss
    REQ_STORE_MISS  =   3'h4        // Miss handling request from LOAD miss
} CACHE_REQ_CMD;

typedef enum logic [2:0] {
    ST_IDLE         =   3'h0    ,
    ST_WAIT_DEPEND  =   3'h1    ,
    ST_WAIT_EVICT   =   3'h2    ,
    ST_RD_MEM       =   3'h3    ,
    ST_WAIT_MEM     =   3'h4    ,
    ST_UPDATE       =   3'h5    ,
    ST_OUTPUT       =   3'h6    ,
    ST_EVICT        =   3'h7    
} MSHR_STATE;

//////////////////////////////////////////////
// 
// Entry contents struct
// 
//////////////////////////////////////////////

// Array Entry Contents Start

// Struct that holds both the PC and the 
typedef struct packed {
    INST                                inst                ;
    logic   [`XLEN-1:0]                 pc                  ;
} INST_PC;

// Per-thread data structures.
typedef struct packed {
    logic   [`XLEN-1:0]                 PC_reg             ;
    INST_PC [`IF_NUM-1:0]               inst_buff          ;           // Instruction buffer (remember doesn't have logic since we're using a user defined type)
    logic   [`IF_NUM_WIDTH-1:0]         avail_size         ;           // Essentially size of buff where can fetch (used to indicate 
    logic   [`IF_IDX_WIDTH:0]           hd_ptr             ;           // Points to the front of the queue (extra bit for wrapping around).
    logic   [`IF_IDX_WIDTH:0]           tail_ptr           ;           // Points to the back of the queue.
} CONTEXT;

typedef struct packed {
    logic   [`XLEN-1:0]                 pc          ;
    INST                                inst        ;
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
    logic                               alu         ;
    logic                               mult        ;
} DEC_INST;

typedef struct packed {
    logic   [`XLEN-1:0]                 pc          ;
    logic   [`XLEN-1:0]                 npc         ;
    INST                                inst        ;
    logic   [`XLEN-1:0]                 rs1_value   ;
    logic   [`XLEN-1:0]                 rs2_value   ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
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
    logic                               alu         ;
    logic                               mult        ;
} IS_INST;

typedef struct packed {
    logic                               valid       ;
    logic   [`XLEN-1:0]                 pc          ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]   rd          ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag_old     ;
    logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
    logic                               br_predict  ;
    logic                               br_result   ;
    logic   [`XLEN-1:0]                 br_target   ;
    logic                               complete    ;
} ROB_ENTRY;

typedef struct packed {
	logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
    logic                               tag_ready   ;
} MT_ENTRY; // Per-channel

typedef struct packed {
    logic                               valid       ;
    DEC_INST                            dec_inst    ;
} RS_ENTRY;

typedef struct packed {
    logic   [`TAG_IDX_WIDTH-1:0]        amt_tag     ;
} AMT_ENTRY;

typedef struct packed {
    logic   [`TAG_IDX_WIDTH-1:0]        tag         ;
} FL_ENTRY;

typedef struct packed {
    MSHR_STATE                          state       ;
    BUS_COMMAND                         cmd         ;
    logic   [`XLEN-1:0]                 req_addr    ;
    logic   [`CACHE_BLOCK_SIZE*8-1:0]   req_data    ;
    MEM_SIZE                            req_size    ;
    logic   [`XLEN-1:0]                 evict_addr  ;
    logic   [`CACHE_BLOCK_SIZE*8-1:0]   evict_data  ;
    logic                               evict_dirty ;
    logic   [`MSHR_IDX_WIDTH-1:0]       link_idx    ;
    logic                               linked      ;
    logic   [4-1:0]                     mem_tag     ;
} MSHR_ENTRY;

typedef struct packed {
    logic                               valid       ;
    logic                               dirty       ;
    logic                               lru         ;
    logic   [`CACHE_TAG_WIDTH-1:0]      tag         ;
    logic   [8*`CACHE_BLOCK_SIZE-1:0]   data        ;
} CACHE_MEM_ENTRY;  // for each block

// Array Entry Contents End

//////////////////////////////////////////////
// 
// Module interface struct
// 
//////////////////////////////////////////////
// Interface Start

//  If an interface is marked as "Combined", no external dimension should
//  be defined at port instantiation.
//  If an interface is marked as "Per-Channel", an external dimension should
//  be defined at port instantiation as the number of channels.

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     dp_num     ;
    logic   [`DP_NUM-1:0][`XLEN-1:0]                pc         ;
    logic   [`DP_NUM-1:0][`ARCH_REG_IDX_WIDTH-1:0]  rd         ;
    logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag        ;
    logic   [`DP_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag_old    ;
    logic   [`DP_NUM-1:0]                           br_predict ;
} DP_ROB; // Combined

typedef struct packed {
    logic   [`DP_NUM_WIDTH-1:0]                     avail_num  ;
    logic   [`DP_NUM-1:0][`ROB_IDX_WIDTH-1:0]       rob_idx    ;
} ROB_DP; // Combined

typedef struct packed{
    logic                                           valid       ;   // Is this signal valid?
    logic   [`XLEN-1:0]                             pc          ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;   // Physical Register (Used for broadcasting to M_T and RS)
    logic   [`ROB_IDX_WIDTH-1:0]                    rob_idx     ;   // Used to locate rob entry
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;   // Used to locate rob entry
    logic                                           br_result   ;   // Branch result, Taken or Not-Taken
    logic   [`XLEN-1:0]                             br_target   ;   // Branch Target
} CDB; // Per-Channel

typedef struct packed {
    logic                                           wr_en       ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               arch_reg    ;   // Key
    logic   [`TAG_IDX_WIDTH-1:0]                    phy_reg     ;   // Value
} ROB_AMT; // Per-Channel

typedef struct packed {
    logic   [`RT_NUM_WIDTH-1:0]                     rt_num      ;
    logic   [`RT_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag         ;
    logic   [`RT_NUM-1:0][`TAG_IDX_WIDTH-1:0]       tag_old     ;
} ROB_FL; // Combined

typedef struct packed {
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs1         ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs2         ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rd          ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;
    logic                                           wr_en       ;
    logic                                           thread_idx  ;
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
    logic [`THREAD_NUM-1:0][`XLEN-1:0]              addr            ;
    logic [`THREAD_NUM-1:0][`IF_NUM_WIDTH-1:0]      inst_num_to_ft  ; // Number of instructions to fetch (obtain) relative to pc.
} IF_IC;

typedef struct packed {
    logic [`THREAD_NUM-1:0][`IF_NUM-1:0][`XLEN-1:0] data            ;
    logic [`THREAD_NUM-1:0][`IF_NUM_WIDTH-1:0]      inst_num_fted   ; // Number of instructions fetched relative to pc.
} IC_IF;

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
} DP_RS; // Combined

typedef struct packed {
    logic                                           valid       ;
    IS_INST                                         is_inst     ;
} RS_IB; // Per-Channel

typedef struct packed {
    // logic   [`FU_NUM-1:0]                           ready       ;
    logic                                           ALU_ready   ;
    logic                                           MULT_ready  ;
    logic                                           BR_ready    ;
    logic                                           LOAD_ready  ;
    logic                                           STORE_ready ;
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
    IS_INST                                         is_inst     ;
} IB_FU; // Per-Channel

typedef struct packed {
    logic                                           ready       ;
} FU_IB; // Per-Channel

typedef struct packed {
    logic                                           valid       ;
    logic   [`XLEN-1:0]                             pc          ;
    logic                                           write_reg   ;
    logic   [`XLEN-1:0]                             rd_value    ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;
    logic                                           br_inst     ;
    logic                                           br_result   ;
    logic   [`XLEN-1:0]                             br_target   ;
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;
    logic   [`ROB_IDX_WIDTH-1:0]                    rob_idx     ;
} FU_BC; // Per-Channel

typedef struct packed {
    logic                                           broadcasted ;
} BC_FU; // Per-Channel

typedef struct packed {
    logic   [`TAG_IDX_WIDTH-1:0]                    wr_addr     ;
    logic   [`XLEN-1:0]                             data_in     ;
    logic                                           wr_en       ;
} BC_PRF; // Per-Channel

typedef struct packed {
    logic   [`THREAD_NUM-1:0]                       valid       ;
    logic   [`THREAD_NUM-1:0][`XLEN-1:0]            br_target   ;
} BR_MIS; // Combined

typedef struct packed {
    logic                                           wr_en       ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag_old     ;
} ROB_VFL;  // Per-Channel

typedef struct packed {
    logic   [`XLEN-1:0]                             addr        ;
    logic   [64-1:0]                                data        ;
    MEM_SIZE                                        size        ;
    BUS_COMMAND                                     command     ;
} MEM_IN;

typedef struct packed {
    logic   [4-1:0]                                 response    ;
    logic   [64-1:0]                                data        ;
    logic   [4-1:0]                                 tag         ;
} MEM_OUT;

typedef struct packed {
    // Request Interface
    CACHE_REQ_CMD                                   req_cmd     ;   // Requested command.
    logic   [`XLEN-1:0]                             req_addr    ;   // Requested address.
    logic   [`CACHE_BLOCK_SIZE*8-1:0]               req_data_in ;
} CACHE_CTRL_MEM;

typedef struct packed {
    // Request Interface
    logic                                           req_hit     ;
    logic   [`CACHE_BLOCK_SIZE*8-1:0]               req_data_out;
    // Evict Interface
    logic                                           evict_dirty ;
    logic   [`XLEN-1:0]                             evict_addr  ;
    logic   [`CACHE_BLOCK_SIZE*8-1:0]               evict_data  ;
} CACHE_MEM_CTRL;




// Interface End

`endif // __SYS_DEFS_VH__
