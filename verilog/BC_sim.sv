/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  BC_sim.sv                                         //
//                                                                     //
//  Description :  BC_sim                                            // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module BC_sim #(
    parameter   C_FU_NUM    =   `FU_NUM     ,
    parameter   C_CDB_NUM   =   `CDB_NUM    
) (
    input   logic                       clk_i       ,
    input   logic                       rst_i       ,
    input   FU_BC   [C_FU_NUM-1:0]      fu_bc_i     ,
    output  BC_FU   [C_FU_NUM-1:0]      bc_fu_o     ,
    output  BC_PRF  [C_CDB_NUM-1:0]     bc_prf_o    ,
    output  CDB     [C_CDB_NUM-1:0]     cdb_o       
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    parameter   C_FU_IDX_WIDTH  =   $clog2(C_FU_NUM);
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_FU_IDX_WIDTH-1:0]    cnt     ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// Module Instantiations Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   sub_module_name
// Description  :   sub module function
// --------------------------------------------------------------------


// --------------------------------------------------------------------


// ====================================================================
// Module Instantiations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Logic Divider
// --------------------------------------------------------------------

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            cnt <=  `SD 'd0;
        end else begin
            cnt <=  `SD cnt + 'd1;
        end
    end

    task bc_run();
        int     cp_num          ;
        int     fu_true_idx     ;
        begin

            forever begin
                @(negedge clk_i);
                cdb_o       =   0;
                bc_fu_o     =   0;
                bc_prf_o    =   0;
                cp_num      =   0;
                for (int unsigned fu_idx = 0; fu_idx < C_FU_NUM; fu_idx++) begin
                    if (fu_idx + cnt >= C_FU_NUM) begin
                        fu_true_idx =   fu_idx + cnt - C_FU_NUM;
                    end else begin
                        fu_true_idx =   fu_idx + cnt;
                    end

                    if (fu_bc_i[fu_true_idx].valid) begin
                        bc_fu_o[fu_true_idx].broadcasted  =   1'b1;
                        cdb_o[cp_num].valid         =   fu_bc_i[fu_true_idx].valid      ;
                        cdb_o[cp_num].pc            =   fu_bc_i[fu_true_idx].pc         ;
                        cdb_o[cp_num].tag           =   fu_bc_i[fu_true_idx].tag        ;
                        cdb_o[cp_num].rob_idx       =   fu_bc_i[fu_true_idx].rob_idx    ;
                        cdb_o[cp_num].thread_idx    =   fu_bc_i[fu_true_idx].thread_idx ;
                        if (fu_bc_i[fu_true_idx].br_inst) begin
                            cdb_o[cp_num].br_result     =   'b0 ;
                            cdb_o[cp_num].br_target     =   'b0 ;
                        end else begin
                            cdb_o[cp_num].br_result     =   fu_bc_i[fu_true_idx].br_result  ;
                            cdb_o[cp_num].br_target     =   fu_bc_i[fu_true_idx].br_target  ;
                        end
                        bc_prf_o[cp_num].wr_addr    =   fu_bc_i[fu_true_idx].tag        ;
                        bc_prf_o[cp_num].data_in    =   fu_bc_i[fu_true_idx].rd_value   ;
                        bc_prf_o[cp_num].wr_en      =   fu_bc_i[fu_true_idx].write_reg  ;
                        cp_num++;
                    end

                    if (cp_num == C_CDB_NUM) begin
                        break;
                    end
                end
            end
        end
    endtask

    initial begin
        bc_run();
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
