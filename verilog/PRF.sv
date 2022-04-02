
/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  PRF.sv                                              //
//                                                                     //
//  Description :  PRF MODULE of the pipeline;                         // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`ifndef __PRF_V__
`define __PRF_V__

module PRF # ( 
    parameter   C_XLEN              =   `XLEN           ,
    parameter   C_IS_NUM            =   `IS_NUM         ,
    parameter   C_CDB_NUM           =   `CDB_NUM        ,
    parameter   C_THREAD_NUM        =   `THREAD_NUM     ,
    parameter   C_ROB_ENTRY_NUM     =   `ROB_ENTRY_NUM  ,
    parameter   C_ARCH_REG_NUM      =   `ARCH_REG_NUM   ,
    parameter   C_PHY_REG_NUM       =   `PHY_REG_NUM    
) (
    input   logic                       clk_i                ,   // Clock
    input   logic                       rst_i                ,   // Reset
    input   RS_PRF  [C_IS_NUM-1:0]      rs_prf_i             ,  
    output  PRF_RS  [C_IS_NUM-1:0]      prf_rs_o             ,
    input   BC_PRF  [C_CDB_NUM-1:0]     bc_prf_i             ,
    // For Testing
    output  logic   [C_PHY_REG_NUM-1:0] [C_XLEN-1:0]    prf_mon_o
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    logic  [C_IS_NUM-1:0][C_CDB_NUM-1:0]        hit1        ;
    logic  [C_IS_NUM-1:0][C_CDB_NUM-1:0]        hit2        ;
    logic  [C_PHY_REG_NUM-1:0][C_XLEN-1:0]      registers   ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
// --------------------------------------------------------------------
// hit detection
// --------------------------------------------------------------------

//   rd_idx: loop over read ports
//   wr_idx: loop over write ports
    always_comb begin
        hit1    =   0;
        hit2    =   0;
        for (int unsigned rd_idx = 0 ; rd_idx < C_IS_NUM; rd_idx++) begin
            for (int unsigned wr_idx = 0 ; wr_idx < C_CDB_NUM; wr_idx++) begin
                if(bc_prf_i[wr_idx].wr_addr == rs_prf_i[rd_idx].rd_addr1) begin
                    hit1[rd_idx][wr_idx] = 1;
                end//if hit1
                if(bc_prf_i[wr_idx].wr_addr == rs_prf_i[rd_idx].rd_addr2) begin
                    hit2[rd_idx][wr_idx] = 1;
                end//if hit2
            end//for wr_idx
        end//for rd_idx
    end

  // --------------------------------------------------------------------
  // Read port A
  // --------------------------------------------------------------------

    always_comb begin
        for (int unsigned rd_idx = 0 ; rd_idx < C_IS_NUM; rd_idx++) begin
            if (rs_prf_i[rd_idx].rd_addr1 == `ZERO_REG)begin
                prf_rs_o[rd_idx].data_out1 = 0;
            end else if (bc_prf_i[rd_idx].wr_en && (|hit1[rd_idx])) begin //There's match
                for (int unsigned wr_idx = 0; wr_idx < C_CDB_NUM; wr_idx++) begin
                    if (hit1[rd_idx][wr_idx]) begin
                        prf_rs_o[rd_idx].data_out1 = bc_prf_i[wr_idx].data_in;  // internal forwarding
                    end
                end
            end else begin
                prf_rs_o[rd_idx].data_out1 = registers[rs_prf_i[rd_idx].rd_addr1];
            end
        end//for
    end//comb

  // --------------------------------------------------------------------
  // Read port B
  // --------------------------------------------------------------------

    always_comb begin
        for (int unsigned rd_idx = 0 ; rd_idx < C_IS_NUM; rd_idx++) begin
            if (rs_prf_i[rd_idx].rd_addr2 == `ZERO_REG)begin
                prf_rs_o[rd_idx].data_out2 = 0;
            end else if (bc_prf_i[rd_idx].wr_en && (|hit2[rd_idx])) begin //There's match
                for (int unsigned wr_idx = 0; wr_idx < C_CDB_NUM; wr_idx++) begin
                    if (hit2[rd_idx][wr_idx]) begin
                        prf_rs_o[rd_idx].data_out2 = bc_prf_i[wr_idx].data_in;  // internal forwarding
                    end
                end
            end else begin
                prf_rs_o[rd_idx].data_out2 = registers[rs_prf_i[rd_idx].rd_addr2];
            end
        end//for
    end//comb

  // --------------------------------------------------------------------
  // Write port
  // --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            registers   <=  `SD 'b0;
        end else begin
            for (int unsigned idx = 0 ; idx < C_CDB_NUM; idx++) begin
                if (bc_prf_i[idx].wr_en) begin
                    registers[bc_prf_i[idx].wr_addr] <= `SD bc_prf_i[idx].data_in;
                end//if
            end//for
        end
    end//ff

    assign  prf_mon_o   =   registers   ;

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule // regfile
`endif //__PRF__

