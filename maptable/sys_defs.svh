`define MT_ENTRY 64
`define ARCH_REG_NUM    32  // The number of Architectural registers.
`define PHY_REG_IDX $clog2(PHY_REG_NUM)
`define PHY_REG_NUM     64  // The number of Physical registers.
`define ARCH_REG_IDX_WIDTH  $clog2(`ARCH_REG_NUM)
`define TAG_IDX_WIDTH       $clog2(`PHY_REG_NUM)


typedef struct packed {
	logic [`PHY_REG_IDX-1:0] tag;
    logic                   phy_reg_ready;
} MP_ENTRY; // Per-channel

typedef struct packed {
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs1         ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rs2         ;
    logic   [`ARCH_REG_IDX_WIDTH-1:0]               rd          ;
    logic   [`TAG_IDX_WIDTH-1:0]                    tag         ;
    logic                                           wr_en       ;
    logic read_en;
} DP_MT; // Per-Channel

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
    logic [`PHY_REG_IDX-1:0] rrat_tag;
} AMT_ENTRY;
