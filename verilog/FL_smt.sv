/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  FL_smt.sv                                           //
//                                                                     //
//  Description :  The edition which Freelist supports SMT             // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module FL_smt #(
    parameter   C_FL_ENTRY_NUM  =   `FL_ENTRY_NUM       ,
    parameter   C_THREAD_NUM    =   `THREAD_NUM         ,
    parameter   C_DP_NUM        =   `DP_NUM             ,
    parameter   C_RT_NUM        =   `RT_NUM             ,
    parameter   C_ARCH_REG_NUM  =   `ARCH_REG_NUM       ,
    parameter   C_PHY_REG_NUM   =   `PHY_REG_NUM        ,
    parameter   C_TAG_IDX_WIDTH =   `TAG_IDX_WIDTH      ,
    parameter   C_FL_IDX_WIDTH  =   $clog2(C_FL_ENTRY_NUM)
) (
    input   logic                               clk_i       ,   //  Clock
    input   logic                               rst_i       ,   //  Reset
    input   BR_MIS                              br_mis_i    ,  
    input   DP_FL                               dp_fl_i     ,
    input   ROB_FL      [C_THREAD_NUM-1:0]      rob_fl_i    ,
    output  FL_DP                               fl_dp_o
);

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    // localparam  C_FL_IDX_WIDTH  =   $clog2(C_FL_ENTRY_NUM);
    localparam  C_FL_NUM_WIDTH  =   $clog2(C_FL_ENTRY_NUM+1);
    localparam  C_DP_NUM_WIDTH  =   $clog2(C_DP_NUM+1)      ;
    localparam  C_RT_NUM_WIDTH  =   $clog2(C_RT_NUM+1)      ;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    FL_smt_ENTRY    [C_FL_ENTRY_NUM-1:0]                fl_entry        ;   // Freelist entry
    FL_smt_ENTRY    [C_FL_ENTRY_NUM-1:0]                next_fl_entry   ;   // Freelist entry store

    logic           [C_FL_NUM_WIDTH-1:0]                avail_num       ;   // 0 ~ C_FL_ENTRY_NUM
    logic           [C_RT_NUM_WIDTH-1:0]                rt_num          ;
    logic           [C_DP_NUM_WIDTH-1:0]                dp_num          ;   // actual dispatched num

// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// FL default set & Rollback manipulation as sequential logic
// --------------------------------------------------------------------
    // Initialization
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            for(int fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++)begin
                fl_entry[fl_idx].valid <=  `SD 'd1; 
            end//for
        end//if
        //default set as all tags are available
        else begin
            for(int fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++)begin
            //check the roolback status and set relevant tag in flight valid
                if(br_mis_i.valid[fl_entry[fl_idx].thread_idx] && !fl_entry[fl_idx].valid)begin
                    fl_entry[fl_idx].valid <=  `SD 'd1; 
                end//if
            end//for
        end//else
        //set corresponding thread's valid to 1 when rollback happens
    end//ff

// --------------------------------------------------------------------
// Calculation of avail_num 
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            avail_num   <=   `SD C_FL_ENTRY_NUM ;
        end//if
        else begin
            avail_num   <=   `SD rt_num - dp_num;
        end
        
    end//ff
    //available nums are the ones has vaild value to be dispatched

// --------------------------------------------------------------------
// Allocate dp_num tags in actual dispatch stage
// --------------------------------------------------------------------
    always_comb begin
        next_fl_entry   =   fl_entry;
        dp_num = dp_fl_i.dp_num;
        for (int fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++) begin 
            if((fl_entry[fl_idx].valid) && (dp_num > 0))begin
                fl_dp_o.tag[dp_fl_i.dp_num - dp_num] = fl_entry[fl_idx].tag;
                next_fl_entry[fl_idx].valid = 'd0;
                next_fl_entry[fl_idx].thread_idx = dp_fl_i.thread_idx;
                dp_num--;
            end//if
        end//for fl_idx         
    end//comb
    //dispatch stage: set thread_idx and vaild value & send tags out.

    logic   [C_FL_ENTRY_NUM-1:0]    dp_sel  ;
    int unsigned                    dp_idx  ;

    always_comb begin
        dp_idx  =   0;
        for (int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++) begin 
            
        end
    end

// --------------------------------------------------------------------
// Replace tags and Renew with tag_old
// --------------------------------------------------------------------
    always_comb begin
        rt_num  =   0;
        next_fl_entry   =   fl_entry;
        for(int thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++)begin
            rt_num  =   rob_fl_i[thread_idx].rt_num + rt_num;
        end//for
        for (int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++) begin
            if(!fl_entry[fl_idx].valid)begin
                for(int thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++)begin
                    if((fl_entry[fl_idx].thread == thread_idx) && (fl_entry[fl_idx].tag == rob_fl_i[thread_idx].tag))begin
                        next_fl_entry[fl_idx].tag    = rob_fl_i[thread_idx].tag_old;
                        next_fl_entry[fl_idx].valid  = 'd1;
                    end//if
                end//for
            end//if
        end//for fl_entry
    end//comb

    always_comb begin
        for (int unsigned fl_idx = 0; fl_idx < C_FL_ENTRY_NUM; fl_idx++) begin
            // Dispatch


            // Retire

            if(!fl_entry[fl_idx].valid)begin
                for(int thread_idx = 0; thread_idx < C_THREAD_NUM; thread_idx++)begin
                    if((fl_entry[fl_idx].thread == thread_idx) && (fl_entry[fl_idx].tag == rob_fl_i[thread_idx].tag))begin
                        next_fl_entry[fl_idx].tag    = rob_fl_i[thread_idx].tag_old;
                        next_fl_entry[fl_idx].valid  = 'd1;
                    end//if
                end//for
            end//if
        end//for fl_entry    
    end

// ====================================================================
// RTL Logic End
// ====================================================================

endmodule
