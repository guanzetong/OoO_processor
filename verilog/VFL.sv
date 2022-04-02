/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  VFL.sv                                              //
//                                                                     //
//  Description :  Victim Freelist                                     // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module VFL #(
    parameter   C_RT_NUM        =   `RT_NUM         ,
    parameter   C_FL_ENTRY_NUM  =   `FL_ENTRY_NUM 
) (
    input   logic                               clk_i       ,   //  Clock
    input   logic                               rst_i       ,   //  Reset
    input   ROB_VFL     [C_RT_NUM-1:0]          rob_vfl_i   ,
    output  FL_ENTRY    [C_FL_ENTRY_NUM-1:0]    vfl_fl_o           
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    FL_ENTRY    [C_FL_ENTRY_NUM-1:0]    vfl_entry       ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================

// --------------------------------------------------------------------
// Output Victim Freelist to Freelist
// --------------------------------------------------------------------
    assign  vfl_fl_o    =   vfl_entry   ;

// --------------------------------------------------------------------
// CAM into VFL at Retire
// --------------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        for (int unsigned entry_idx = 0; entry_idx < C_FL_ENTRY_NUM; entry_idx++) begin
            // System Reset
            if (rst_i) begin
                vfl_entry[entry_idx].tag    <=  `SD entry_idx;
            end else begin
                for (int unsigned rt_idx = 0; rt_idx < C_RT_NUM; rt_idx++) begin
                    // At Retire
                    if (rob_vfl_i[rt_idx].wr_en) begin 
                        // Compare retire tag with entry tag
                        if (rob_vfl_i[rt_idx].tag == vfl_entry[entry_idx].tag) begin 
                            vfl_entry[entry_idx].tag    <=  `SD rob_vfl_i[rt_idx].tag_old;
                        end
                    end
                end
            end
        end
    end

// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
