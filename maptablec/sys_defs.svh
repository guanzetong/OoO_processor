`define MT_ENTRY 32
`define ARCH_REG_NUM    32  // The number of Architectural registers.
`define PHY_REG_NUM     64  // The number of Physical registers.
`define ROB_IDX_WIDTH 5
`define DP_NUM 2
`define CDB_NUM 2
`define PHY_REG_IDX     $clog2(`PHY_REG_NUM)
`define ARCH_REG_IDX_WIDTH  $clog2(`ARCH_REG_NUM)
`define TAG_IDX_WIDTH       $clog2(`PHY_REG_NUM)
`define THREAD_IDX_WIDTH   $clog2(4)


typedef struct packed {
	logic [`PHY_REG_IDX-1:0] tag;
    logic                   phy_reg_ready;
} MP_ENTRY; // Per-channel

typedef struct packed {
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs1         ;   // used to index mt entry for source register 1
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs2         ;   // used to index mt entry for source register 2
    logic                                           read_en;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rd          ;   // used to index mt entry for destination register
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;   // tag for destination register 
    logic                                           wr_en       ;   // the corresponding mt entry ready for write
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;   // used for SMT 

} DP_MT_READ; // Per-Channel


typedef struct packed {
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs1         ;   // used to index mt entry for source register 1
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs2         ;   // used to index mt entry for source register 2
    logic                                           read_en;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rd          ;   // used to index mt entry for destination register
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;   // tag for destination register 
    logic                                           wr_en       ;   // the corresponding mt entry ready for write
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;   // used for SMT 

} DP_MT_WRITE; // Per-Channel

typedef struct packed {
    logic   [`TAG_IDX_WIDTH-1:0]                    tag1        ;
    logic                                           tag1_ready  ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag2        ;
    logic                                           tag2_ready  ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag_old     ;
} MT_DP; // Per-Channel

typedef struct packed{
    logic                                           valid       ;   // Is this signal valid?
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;   // Physical Register (Used for broadcasting to M_T and RS)
    logic   [`ROB_IDX_WIDTH-1:0]                    rob_idx     ;   // Used to locate rob entry
    logic   [`THREAD_IDX_WIDTH-1:0]                 thread_idx  ;   // Used to locate rob entry
    logic                                           br_result   ;   // Branch result
} CDB; // Per-Channel

typedef struct packed {
    logic [`PHY_REG_IDX-1:0] amt_tag;
} AMT_ENTRY;
