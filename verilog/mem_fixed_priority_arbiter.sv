/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  mem_fixed_priority_arbiter.sv                       //
//                                                                     //
//  Description :  Fixed Priority abitration on memory interface.      // 
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module mem_fixed_priority_arbiter #(
    parameter   C_REQ_NUM       =   2               ,
    parameter   C_REQ_IDX_WIDTH =   $clog2(C_REQ_NUM)
) (
    input   logic                           clk_i       ,
    input   logic                           rst_i       ,
    input   logic   [C_REQ_NUM-1:0]         req_i       ,
    input   logic                           ack_i       ,
    output  logic   [C_REQ_IDX_WIDTH-1:0]   grant_o     ,
    output  logic                           valid_o     
);

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic   [C_REQ_IDX_WIDTH-1:0]   next_grant  ;
    logic                           next_valid  ;
// ====================================================================
// Signal Declarations End
// ====================================================================

// ====================================================================
// RTL Logic Start
// ====================================================================
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            grant_o <=  `SD 'd0;
            valid_o <=  `SD 1'b1;
        end else begin
            grant_o <=  `SD next_grant_idx;
            valid_o <=  `SD next_valid;
        end
    end

    always_comb begin
        next_grant  =   grant_o;
        next_valid  =   valid_o;
        if (ack_i) begin
            next_grant  =   'd0;
            next_valid  =   1'b0;
            for (int unsigned req_idx = C_REQ_NUM; req_idx > 0; req_idx++) begin
                if (req_i[req_idx-1] == 1'b1) begin
                    next_grant  =   req_idx - 'd1;
                    next_valid  =   1'b1;
                end
            end
        end
    end
// ====================================================================
// RTL Logic End
// ====================================================================


endmodule
