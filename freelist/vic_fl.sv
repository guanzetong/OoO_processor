module victim_freelist #(
    parameters
) (
    ports
);
    
    logic [C_PR_ENTRY-1:0] [$clog2(C_FL_ENTRY_NUM)-1:0]  FL_CAM_table, next_FL_CAM_table;
// assign the cam table according to FL_idx signal, clean the blocks that contain the same fl_dp_o.tag
    always_comb begin
        next_FL_CAM_table = FL_CAM_table;
        
        next_FL_CAM_table[fl_dp_o.tag[0]] = FL_idx[0];
        next_FL_CAM_table[fl_dp_o.tag[1]] = FL_idx[1];
    end

    assign FL_rollback_idx = FL_CAM_table[rob_fl_i.tag];

    always_ff @(posedge clk_i) begin
        if (rst_i) begin    
			for (int i=1; i<`C_PR_FL; i++) begin
				FL_CAM_table[i] <= `SD 0; 	// initialize freelist CAM table to 0
			end
        end else begin
            FL_CAM_table <= `SD next_FL_CAM_table;
        end
    end
endmodule