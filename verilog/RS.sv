/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  RS.sv                                               //
//                                                                     //
//  Description :  Reservation Station. Store the dispatched           //
//                 instructions, receive completed instruction         //
//                 from CDB, and select instructions to issue.         // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

// `timescale 1ns/100ps

module RS #(
    parameter   C_RS_ENTRY_NUM  =   `RS_ENTRY_NUM   ,
    parameter   C_DP_NUM        =   `DP_NUM         ,
    parameter   C_IS_NUM        =   `IS_NUM         ,
    parameter   C_CDB_NUM       =   `CDB_NUM        ,
    parameter   C_THREAD_NUM    =   `THREAD_NUM     ,
    localparam  C_RS_IDX_WIDTH  =   $clog2(C_RS_ENTRY_NUM)
) (
    // For Testing
    output  RS_ENTRY    [C_RS_ENTRY_NUM-1:0]    rs_mon_o        ,
    output  logic       [C_RS_IDX_WIDTH-1:0]    rs_cod_mon_o    ,
    // Testing end
    input   logic                               clk_i           ,   //  Clock
    input   logic                               rst_i           ,   //  Reset
    output  RS_DP                               rs_dp_o         ,
    input   DP_RS                               dp_rs_i         ,
    input   CDB         [C_CDB_NUM-1:0]         cdb_i           ,
    output  RS_IB       [C_IS_NUM-1:0]          rs_ib_o         ,
    input   IB_RS                               ib_rs_i         ,
    output  RS_PRF      [C_IS_NUM-1:0]          rs_prf_o        ,
    input   PRF_RS      [C_IS_NUM-1:0]          prf_rs_i        ,
    input   BR_MIS                              br_mis_i        ,
    input   logic                               exception_i     


);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_DP_NUM_WIDTH  =   $clog2(C_DP_NUM+1);
    localparam  C_IS_NUM_WIDTH  =   $clog2(C_IS_NUM+1);
    // localparam  C_RS_IDX_WIDTH  =   $clog2(C_RS_ENTRY_NUM);
    localparam  C_RS_NUM_WIDTH  =   $clog2(C_RS_ENTRY_NUM+1);

    // Center-Of-Dispatch
    localparam  C_DP_IDX_WIDTH  =   $clog2(C_DP_NUM);
    localparam  C_ADDER_IN_NUM  =   2 ** C_DP_IDX_WIDTH;
    localparam  C_SOD_WIDTH     =   C_DP_IDX_WIDTH + C_RS_IDX_WIDTH;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    // Array
    RS_ENTRY    [C_RS_ENTRY_NUM-1:0]                    rs_array            ;

    // Available Entry Counter
    logic       [C_RS_NUM_WIDTH-1:0]                    avail_cnt           ;
    logic       [C_THREAD_NUM-1:0][C_RS_NUM_WIDTH-1:0]  valid_cnt           ;
    logic       [C_THREAD_NUM-1:0][C_DP_NUM_WIDTH-1:0]  dp_cnt              ;
    logic       [C_THREAD_NUM-1:0][C_IS_NUM_WIDTH-1:0]  is_cnt              ;

    // Dispatch
    logic       [C_RS_ENTRY_NUM-1:0]                    entry_empty_concat  ;   // Concatenate the availability of entries
    logic       [C_DP_NUM-1:0][C_RS_ENTRY_NUM-1:0]      dp_pe_bit           ;   // The input to each level of Priority Encoder for Dispatch
    logic       [C_DP_NUM-2:0][C_RS_ENTRY_NUM-1:0]      dp_pe_mask          ;   // The mask from each level of Priority Encoder for Dispatch
    logic       [C_DP_NUM-1:0][C_RS_IDX_WIDTH-1:0]      dp_entry_idx        ;   // The selected entry indexes for Dispatch
    logic       [C_DP_NUM-1:0]                          dp_entry_idx_valid  ;   // The validity of dp_entry_idx
    logic       [C_DP_NUM-1:0]                          dp_valid            ;   // The ultimate validity of Dispatch channels
    DEC_INST    [C_RS_ENTRY_NUM-1:0]                    dp_switch           ;   // The newly Dispatched instructions routed to entries
    logic       [C_RS_ENTRY_NUM-1:0]                    dp_sel              ;   // Indicates if a entry is selected for Dispatch

    // Complete
    logic       [C_RS_ENTRY_NUM-1:0]                    cp_sel_tag1         ;
    logic       [C_RS_ENTRY_NUM-1:0]                    cp_sel_tag2         ;

    // Issue
    logic       [C_SOD_WIDTH-1:0]                       sod                 ;   // Sum of newly dispatch entry index
    logic       [C_RS_IDX_WIDTH-1:0]                    cod                 ;   
    logic       [C_RS_ENTRY_NUM-1:0]                    is_ready            ;
    logic       [C_RS_ENTRY_NUM-1:0]                    is_ready_cod        ;
    logic       [C_IS_NUM-1:0][C_RS_ENTRY_NUM-1:0]      is_pe_bit           ;   // The input to each level of Priority Encoder for Dispatch
    logic       [C_IS_NUM-2:0][C_RS_ENTRY_NUM-1:0]      is_pe_mask          ;   // The mask from each level of Priority Encoder for Dispatch
    logic       [C_IS_NUM-1:0][C_RS_IDX_WIDTH-1:0]      is_entry_idx        ;
    logic       [C_IS_NUM-1:0][C_RS_IDX_WIDTH-1:0]      is_entry_idx_cod    ;
    logic       [C_IS_NUM-1:0]                          is_entry_idx_valid  ;
    logic       [C_RS_ENTRY_NUM-1:0]                    is_sel              ;

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Available entry counter
// --------------------------------------------------------------------
    // The number of valid instructions of a thread in RS
    always_ff @(posedge clk_i) begin
        for (int unsigned th_idx = 0; th_idx < C_THREAD_NUM; th_idx++) begin
            // Reset
            if (rst_i) begin
                valid_cnt[th_idx]   <=  `SD 'd0;
            // External Exception
            end else if (exception_i) begin
                valid_cnt[th_idx]   <=  `SD 'd0;
            // Branch Misprediction
            end else if (br_mis_i.valid[th_idx]) begin
                valid_cnt[th_idx]   <=  `SD 'd0;
            // Normal, should consider the number of dispatched and issued
            // instructions in the current cycle.
            end else begin
                valid_cnt[th_idx]   <=  `SD valid_cnt[th_idx] + dp_cnt[th_idx] - is_cnt[th_idx];
            end
        end
    end

    // The number of dispatched instruction of a thread in the current cycle
    always_comb begin
        dp_cnt  =   0;
        for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
            // Only count the valid Dispatch Channels.
            // dp_rs_i.dp_num indicates the number of actually dispatched 
            // instructions in the current cycle.
            if (dp_idx < dp_rs_i.dp_num) begin
                dp_cnt[dp_rs_i.dec_inst[dp_idx].thread_idx] = dp_cnt[dp_rs_i.dec_inst[dp_idx].thread_idx] + 'd1;
            end
        end
    end

    // The number of issued instruction of a thread in the current cycle
    always_comb begin
        is_cnt  =   0;
        for (int unsigned is_idx = 0; is_idx < C_IS_NUM; is_idx++) begin
            // Only count the valid Issue Channels.
            if (rs_ib_o[is_idx].valid) begin
                is_cnt[rs_ib_o[is_idx].is_inst.thread_idx]  =   is_cnt[rs_ib_o[is_idx].is_inst.thread_idx] + 'd1;
            end
        end
    end

    // Calculate the number of available entry for dispatch
    always_comb begin
        // Initial value is the number of entry in RS
        avail_cnt   =   C_RS_ENTRY_NUM;
        // Substract the number of entries occupied or is about to be freed 
        // thread by thread, to derive the number of available entries for 
        // Dispatch in the next cycle.
        for (int unsigned th_idx = 0; th_idx < C_THREAD_NUM; th_idx++) begin
            avail_cnt =   avail_cnt - valid_cnt[th_idx] + is_cnt[th_idx];
        end

        // If the the number of available entries for Dispatch in the next 
        // cycle is larger than the maximum dispatch number (C_DP_NUM), 
        // saturate at maximum.
        if (avail_cnt >= C_DP_NUM) begin
            rs_dp_o.avail_num   =   C_DP_NUM;
        end else begin
            rs_dp_o.avail_num   =   avail_cnt;
        end
    end

// --------------------------------------------------------------------
// Concatenate Valid bit of each entry
// --------------------------------------------------------------------
    // If an entry is issued and leaves RS at the current cycle, 
    // it can be immediately allocated to a newly dispatched instruction
    // in the next cycle.
    always_comb begin
        for (int unsigned entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            entry_empty_concat[entry_idx]   =   (~rs_array[entry_idx].valid) || is_sel[entry_idx];
        end
    end

// --------------------------------------------------------------------
// Select a number of entries for newly Dispatched instructions
// --------------------------------------------------------------------
    // Priority Encoder with multiple outputs
    genvar  dp_pe_idx;
    generate
        for (dp_pe_idx = 0; dp_pe_idx < C_DP_NUM; dp_pe_idx++) begin
            // Generate the input to each Priority Encoder
            // The bits with higher priority should be masked
            if (dp_pe_idx == 0) begin
                assign  dp_pe_bit[dp_pe_idx] =   entry_empty_concat ;
            end else begin
                assign  dp_pe_bit[dp_pe_idx] =   dp_pe_bit[dp_pe_idx-1] & (~dp_pe_mask[dp_pe_idx-1]);
            end

            // Priority Encoders for each output
            always_comb begin
                dp_entry_idx[dp_pe_idx]   =   0;
                for (int unsigned entry_idx = C_RS_ENTRY_NUM; entry_idx > 0 ; entry_idx--) begin
                    if (dp_pe_bit[dp_pe_idx][entry_idx-1]) begin
                        dp_entry_idx[dp_pe_idx] =   entry_idx - 1;
                    end
                end
                dp_entry_idx_valid[dp_pe_idx]   =   dp_pe_bit[dp_pe_idx] ? 1'b1 : 1'b0;
            end

            // Generate masks
            if (dp_pe_idx < C_DP_NUM-1) begin
                assign  dp_pe_mask[dp_pe_idx]   =   dp_entry_idx_valid[dp_pe_idx] 
                                                ?   {{(C_RS_ENTRY_NUM-1){1'b0}},1'b1} << dp_entry_idx[dp_pe_idx]
                                                :   {C_RS_ENTRY_NUM{1'b0}};
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Dispatch Switch
// --------------------------------------------------------------------
    // dp_sel is a per-entry signal to notify the entry to receive newly
    // dispatched instruction.
    // dp_switch is the output of a router logic, to route the newly
    // dispatched instruction to the selected entry.
    // dp_valid is the indicator of the validity of Dispatch channels
    always_comb begin
        dp_sel      =   'b0;
        dp_switch   =   'b0;
        dp_valid    =   'b0;
        for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
            if ((dp_entry_idx_valid[dp_idx] == 1'b1) && (dp_idx < dp_rs_i.dp_num)) begin
                dp_valid[dp_idx]    =   1'b1;
            end
        end

        for (int unsigned entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            for (int unsigned dp_idx = 0; dp_idx < C_DP_NUM; dp_idx++) begin
                if ((dp_entry_idx[dp_idx] == entry_idx) && dp_valid[dp_idx]) begin
                    dp_sel   [entry_idx]    =   1'b1                    ;
                    dp_switch[entry_idx]    =   dp_rs_i.dec_inst[dp_idx];
                end
            end
        end
    end

// --------------------------------------------------------------------
// Comparator network for Complete
// --------------------------------------------------------------------
    // Search for matched tag1
    always_comb begin
        // cp_sel_tag1 is a per-entry signal to indicate whether tag1 is matched
        // Also, the thread index must be considered.
        cp_sel_tag1 =   'b0;
        for (int unsigned entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            for (int unsigned cp_idx = 0; cp_idx < C_CDB_NUM; cp_idx++) begin
                // Compare tag1 and thread_idx
                if ((cdb_i[cp_idx].valid == 1'b1) && 
                    (cdb_i[cp_idx].tag == rs_array[entry_idx].dec_inst.tag1) && 
                    (cdb_i[cp_idx].thread_idx == rs_array[entry_idx].dec_inst.thread_idx)) begin
                    cp_sel_tag1[entry_idx]  =   1'b1;
                end
            end
        end
    end

    // Search for matched tag2
    always_comb begin
        // cp_sel_tag2 is a per-entry signal to indicate whether tag2 is matched
        // Also, the thread index must be considered.
        cp_sel_tag2 =   'b0;
        for (int unsigned entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            for (int unsigned cp_idx = 0; cp_idx < C_CDB_NUM; cp_idx++) begin
                // Compare tag2 and thread_idx
                if ((cdb_i[cp_idx].valid == 1'b1) && 
                    (cdb_i[cp_idx].tag == rs_array[entry_idx].dec_inst.tag2) && 
                    (cdb_i[cp_idx].thread_idx == rs_array[entry_idx].dec_inst.thread_idx)) begin
                    cp_sel_tag2[entry_idx]  =   1'b1;
                end
            end
        end
    end

// --------------------------------------------------------------------
// Ready-to-Issue Checker
// --------------------------------------------------------------------
    always_comb begin
        is_ready    =   'b0;
        for (int unsigned entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            // If both source register are ready in PRF
            // and not the instruction is not squahsed
            if (rs_array[entry_idx].dec_inst.tag1_ready && 
                rs_array[entry_idx].dec_inst.tag2_ready &&
                rs_array[entry_idx].valid &&
                (br_mis_i.valid[rs_array[entry_idx].dec_inst.thread_idx] == 1'b0)) begin
                // Check FU availibility
                //  LOAD
                if (rs_array[entry_idx].dec_inst.rd_mem && ib_rs_i.LOAD_ready) begin
                    is_ready[entry_idx] =   1'b1;
                // STORE
                end else if (rs_array[entry_idx].dec_inst.wr_mem && ib_rs_i.STORE_ready) begin
                    is_ready[entry_idx] =   1'b1;
                // Branch Resolver
                end else if ((rs_array[entry_idx].dec_inst.cond_br || rs_array[entry_idx].dec_inst.uncond_br) 
                && ib_rs_i.BR_ready) begin
                    is_ready[entry_idx] =   1'b1;
                // Multiplier
                end else if (rs_array[entry_idx].dec_inst.mult && ib_rs_i.MULT_ready) begin
                    is_ready[entry_idx] =   1'b1;
                // ALU
                end else if (rs_array[entry_idx].dec_inst.alu && ib_rs_i.ALU_ready) begin
                    is_ready[entry_idx] =   1'b1;
                // FU not available
                end else begin
                    is_ready[entry_idx] =   1'b0;
                end
            // Either of the source registers not ready
            end else begin
                is_ready[entry_idx] =   1'b0;
            end
        end
    end

// --------------------------------------------------------------------
// Center-Of-Dispatch and set priority for Issue
// --------------------------------------------------------------------
    always_comb begin
        // Calculate Sum-Of-Dispatch
        sod =   0;
        for (int unsigned add_idx = 0; add_idx < C_ADDER_IN_NUM; add_idx++) begin
            // Add the actual dispatched RS entry indexes
            if (add_idx < C_DP_NUM) begin
                // Add the dp_entry_idx input if it is valid
                if (dp_valid[add_idx]) begin
                    sod =   sod + dp_entry_idx[add_idx];
                // Else add the center index of RS
                // Note that with right shift, the center is
                // biased to the lower half, so the LSB of add_idx is
                // added to balance.
                end else begin
                    sod =   sod + (C_RS_ENTRY_NUM >> 1);
                end
            // Add the center index of RS
            end else begin
                sod =   sod + (C_RS_ENTRY_NUM >> 1);
            end
        end

        // Set the priorities of entries according to COD
        for (int unsigned entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            // If the COD is at the higher half, lowest index is of highest priority
            if (cod >= (C_RS_ENTRY_NUM >> 1)) begin
                is_ready_cod[entry_idx] =   is_ready[entry_idx];
            // If the COD is at the lower half, highest index is of highest priority
            end else begin
                is_ready_cod[entry_idx] =   is_ready[C_RS_ENTRY_NUM-1-entry_idx];
            end
        end

        // Get the selected entry_idx to issue
        for (int unsigned is_idx = 0; is_idx < C_IS_NUM; is_idx++) begin
            if (cod >= (C_RS_ENTRY_NUM >> 1)) begin
                is_entry_idx[is_idx]    =   is_entry_idx_cod[is_idx];
            end else begin
                is_entry_idx[is_idx]    =   C_RS_ENTRY_NUM - 1 - is_entry_idx_cod[is_idx];
            end
        end
    end

    always_ff @(posedge clk_i) begin
        // Calculate the COD with right shift.
        cod <=  `SD sod >> C_DP_IDX_WIDTH;
    end

// --------------------------------------------------------------------
// Select a number of entries for newly Issued instructions
// --------------------------------------------------------------------
    // Priority Encoder with multiple outputs
    genvar  is_pe_idx;
    generate
        for (is_pe_idx = 0; is_pe_idx < C_IS_NUM; is_pe_idx++) begin
            // Generate the input to each Priority Encoder
            // The bits with higher priority should be masked
            if (is_pe_idx == 0) begin
                assign  is_pe_bit[is_pe_idx] =   is_ready_cod;
            end else begin
                assign  is_pe_bit[is_pe_idx] =   is_pe_bit[is_pe_idx-1] & (~is_pe_mask[is_pe_idx-1]);
            end

            // Priority Encoders for each output
            always_comb begin
                is_entry_idx_cod[is_pe_idx]   =   0;
                for (int unsigned entry_idx = C_RS_ENTRY_NUM; entry_idx > 0 ; entry_idx--) begin
                    if (is_pe_bit[is_pe_idx][entry_idx-1]) begin
                        is_entry_idx_cod[is_pe_idx] =   entry_idx - 1;
                    end
                end
                is_entry_idx_valid[is_pe_idx]   =   is_pe_bit[is_pe_idx] ? 1'b1 : 1'b0;
            end

            // Generate masks
            if (is_pe_idx < C_IS_NUM-1) begin
                assign  is_pe_mask[is_pe_idx]   =   is_entry_idx_valid[is_pe_idx] 
                                                ?   {{(C_RS_ENTRY_NUM-1){1'b0}},1'b1} << is_entry_idx_cod[is_pe_idx]
                                                :   {C_RS_ENTRY_NUM{1'b0}};
            end
        end
    endgenerate

// --------------------------------------------------------------------
// Issue Switch
// --------------------------------------------------------------------
    // Select the issued entries and route them to the issue channels
    always_comb begin
        is_sel      =   'b0;
        rs_ib_o     =   'b0;
        rs_prf_o    =   'b0;
        for (int unsigned entry_idx = 0; entry_idx < C_RS_ENTRY_NUM; entry_idx++) begin
            for (int unsigned is_idx = 0; is_idx < C_IS_NUM; is_idx++) begin
                if ((is_entry_idx[is_idx] == entry_idx) && (is_entry_idx_valid[is_idx] == 1'b1)) begin
                    is_sel[entry_idx]                   =   1'b1                                    ;
                    rs_prf_o[is_idx].rd_addr1           =   rs_array[entry_idx].dec_inst.tag1       ;
                    rs_prf_o[is_idx].rd_addr2           =   rs_array[entry_idx].dec_inst.tag2       ;
                    rs_ib_o[is_idx].valid               =   1'b1                                    ;
                    rs_ib_o[is_idx].is_inst.pc          =   rs_array[entry_idx].dec_inst.pc         ;
                    rs_ib_o[is_idx].is_inst.npc         =   rs_array[entry_idx].dec_inst.pc + 'd4   ;
                    rs_ib_o[is_idx].is_inst.inst        =   rs_array[entry_idx].dec_inst.inst       ;
                    rs_ib_o[is_idx].is_inst.rs1_value   =   prf_rs_i[is_idx].data_out1              ;
                    rs_ib_o[is_idx].is_inst.rs2_value   =   prf_rs_i[is_idx].data_out2              ;
                    rs_ib_o[is_idx].is_inst.tag         =   rs_array[entry_idx].dec_inst.tag        ;
                    rs_ib_o[is_idx].is_inst.thread_idx  =   rs_array[entry_idx].dec_inst.thread_idx ;
                    rs_ib_o[is_idx].is_inst.rob_idx     =   rs_array[entry_idx].dec_inst.rob_idx    ;
                    rs_ib_o[is_idx].is_inst.opa_select  =   rs_array[entry_idx].dec_inst.opa_select ;
                    rs_ib_o[is_idx].is_inst.opb_select  =   rs_array[entry_idx].dec_inst.opb_select ;
                    rs_ib_o[is_idx].is_inst.alu_func    =   rs_array[entry_idx].dec_inst.alu_func   ;
                    rs_ib_o[is_idx].is_inst.rd_mem      =   rs_array[entry_idx].dec_inst.rd_mem     ;
                    rs_ib_o[is_idx].is_inst.wr_mem      =   rs_array[entry_idx].dec_inst.wr_mem     ;
                    rs_ib_o[is_idx].is_inst.cond_br     =   rs_array[entry_idx].dec_inst.cond_br    ;
                    rs_ib_o[is_idx].is_inst.uncond_br   =   rs_array[entry_idx].dec_inst.uncond_br  ;
                    rs_ib_o[is_idx].is_inst.halt        =   rs_array[entry_idx].dec_inst.halt       ;
                    rs_ib_o[is_idx].is_inst.illegal     =   rs_array[entry_idx].dec_inst.illegal    ;
                    rs_ib_o[is_idx].is_inst.csr_op      =   rs_array[entry_idx].dec_inst.csr_op     ;
                    rs_ib_o[is_idx].is_inst.alu         =   rs_array[entry_idx].dec_inst.alu        ;
                    rs_ib_o[is_idx].is_inst.mult        =   rs_array[entry_idx].dec_inst.mult       ;
                end
            end
        end
    end

// --------------------------------------------------------------------
// RS entry
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        for (int unsigned idx = 0; idx < C_RS_ENTRY_NUM; idx++) begin
            // Reset
            if (rst_i) begin
                rs_array[idx].valid     <=  `SD 1'b0;
                rs_array[idx].dec_inst  <=  `SD 'b0;
            // Squash at External Exception
            end else if (exception_i) begin
                rs_array[idx].valid     <=  `SD 1'b0;
                rs_array[idx].dec_inst  <=  `SD 'b0;
            // Squash at Branch Misprediction
            end else if (br_mis_i.valid[rs_array[idx].dec_inst.thread_idx]) begin
                rs_array[idx].valid     <=  `SD 1'b0;
                rs_array[idx].dec_inst  <=  `SD 'b0;
            // Dispatch
            end else if (dp_sel[idx]) begin
                rs_array[idx].valid     <=  `SD 1'b1;
                rs_array[idx].dec_inst  <=  `SD dp_switch[idx];
            // Issue
            end else if (is_sel[idx]) begin
                rs_array[idx].valid     <=  `SD 'b0;
                rs_array[idx].dec_inst  <=  `SD 'b0;
            // Complete
            end else if (rs_array[idx].valid && (cp_sel_tag1[idx] || cp_sel_tag2[idx])) begin
                // tag1_ready & tag2_ready should be independently set
                if (cp_sel_tag1[idx]) begin
                    rs_array[idx].dec_inst.tag1_ready   <=  `SD 1'b1;
                end
                if (cp_sel_tag2[idx]) begin
                    rs_array[idx].dec_inst.tag2_ready   <=  `SD 1'b1;
                end
            end
        end
    end

// --------------------------------------------------------------------
// For Pipeline Testing
// --------------------------------------------------------------------
    assign  rs_mon_o    =   rs_array    ;
    assign  rs_cod_mon_o=   cod         ;

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule