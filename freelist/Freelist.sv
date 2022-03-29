module freelist #(
	parameter C_FL_ENTRY_NUM = FL_ENTRY_NUM
    parameter C_FL_IDX = `FL_IDX
    parameter C_DP_NUM = `DP_NUM
    parameter C_RF_ENTRY = `PHY_REG_NUM/2
    parameter C_PR_ENTRY = `PHY_REG_NUM
) (
	input logic clk_i,
	input logic rst_i,
	input logic rollback_i,

	input DP_FL dp_fl_i,
    input ROB_FL rob_fl_i,
    input [C_DP_NUM-1:0] [4:0] rd_idx

    `ifdef DEBUG
	output logic   [`C_FL_ENTRY_NUM-1:0][$clog2(`C_PR_ENTRY)-1:0]   FL_table, next_FL_table,
	output logic   [$clog2(`C_FL_ENTRY_NUM)-1:0]                 		FL_rollback_idx,
	output logic   [$clog2(`C_FL_ENTRY_NUM)-1:0]                 		head, next_head,
	output logic   [$clog2(`C_FL_ENTRY_NUM)-1:0]                 		tail, next_tail,
	output logic   [`C_DP_NUM-1:0][$clog2(`C_FL_ENTRY_NUM)-1:0] 	FL_idx,		 		// the position of tail in freelist
	`endif

    output FL_DP fl_dp_o
);

    logic [C_FL_IDX - 1] dp_tail;
    logic [C_FL_IDX - 1] rt_head;

	`ifndef DEBUG
    logic [`C_DP_NUM-1:0][$clog2(`C_FL_ENTRY_NUM)-1:0] 	FL_idx;	
	logic [$clog2(`C_FL_ENTRY_NUM)-1:0]                 head, next_head;	// write, indicate where the tag should be retired in the freelist
	logic [$clog2(`C_FL_ENTRY_NUM)-1:0]                 tail, next_tail;  	// read, indicate where the tag should be dispatched in the freelist
	logic [$clog2(`C_FL_ENTRY_NUM)-1:0]                 		FL_rollback_idx;
	logic [`C_FL_ENTRY_NUM-1:0] [$clog2(`PHY_REG_NUM)-1:0]    FL_table, next_FL_table;
	`endif

    logic [$clog2(`C_FL_ENTRY_NUM)-1:0]                 	head_plus_one, head_plus_two;		// specify the num of bits
	logic [$clog2(`C_FL_ENTRY_NUM)-1:0]                 	tail_plus_one, tail_plus_two;
	logic [$clog2(`C_FL_ENTRY_NUM)-1:0]                 	dispatch_tail;		// next tail position when dispatch is enabled, virtually
	logic [$clog2(`C_FL_ENTRY_NUM)-1:0]                 	retire_head;		// next head position when retire is enabled


    logic empty, full, almost_full;
	logic first_rd_nz;
	logic second_rd_nz;
	logic first_told_nz;
	logic second_told_nz;

    assign first_rd_nz = (rd_idx[0] != `ZERO_REG);
    assign second_rd_nz = (rd_idx[1] != `ZERO_REG);

    assign first_told_nz = (rob_fl_i.phy_reg[0] != `ZERO_REG);
    assign second_told_nz = (rob_fl_i.phy_reg[1] != `ZERO_REG);

    assign next_head = (rob_fl_i.rt_num[0] || rob_fl_i.rt_num[1]) ? rt_head : head
	assign next_tail =  rollback_i ? FL_rollback_idx :
                        (dp_fl_i.dp_num[0] || dp_fl_i.dp_num[1]) ? dispatch_tail : tail;

    assign tail_plus_one = tail + 1;
	assign tail_plus_two = tail + 2;
	assign head_plus_one = head + 1;
	assign head_plus_two = head + 2;

    assign fl_dp_o.avail_num = 	(next_head == tail)? 2'b00:		// empty, no preg available
						        (next_head == tail_plus_one) ? 2'b01:	// only one preg away from empty
						                        2'b11;					// both spots availale
	
    always_comb begin
		unique if (first_rd_nz && second_rd_nz && (dp_fl_i.dp_num == 2'b11)) begin
			dispatch_tail = tail_plus_two;
			T_idx = {next_FL_table[tail_plus_one], next_FL_table[tail]};
			FL_idx = {tail_plus_two, tail_plus_one};
		end else if (first_rd_nz && (dp_fl_i.dp_num == 2'b01)) begin
			dispatch_tail = tail_plus_one;
			T_idx = {`ZERO_PREG, next_FL_table[tail]};
			FL_idx = {tail_plus_one, tail_plus_one};
		end else if (second_rd_nz && (dp_fl_i.dp_num == 2'b10)) begin
			dispatch_tail = tail_plus_one;
			T_idx = {next_FL_table[tail], `ZERO_PREG};
			FL_idx = {tail_plus_one, tail};
		end else begin
			dispatch_tail = tail;
			T_idx 		 = {`ZERO_PREG, `ZERO_PREG};
			FL_idx 		 = {tail, tail};
		end
	end

    always_comb begin
		next_FL_table = FL_table;
		unique if (first_told_nz && second_told_nz && (rob_fl_i.rt_num == 2'b11)) begin
			next_FL_table[head] = ROB_FL_out_Told_idx[0];
			next_FL_table[head_plus_one] = ROB_FL_out_Told_idx[1];
			retire_head = head_plus_two;
		end else if (first_told_nz  && (rob_fl_i.rt_num == 2'b01)) begin
			next_FL_table[head] = ROB_FL_out_Told_idx[0];
			retire_head = head_plus_one;
		end else if (second_told_nz && (rob_fl_i.rt_num == 2'b10)) begin
			next_FL_table[head] = ROB_FL_out_Told_idx[1];
			retire_head = head_plus_one;
		end else begin
			retire_head = head;
			next_FL_table = FL_table;
		end
	end


    always_ff @(posedge clk_i) begin
		if (rst_i) begin
			head <= `SD {$clog2(`C_FL_ENTRY_NUM){1'b0}};
			tail <= `SD 1'b1;
			for (int i=1; i<`C_FL_ENTRY_NUM; i++) begin
				FL_table[i] <= `SD i + `C_RF_ENTRY; 	// initialize freelist to index [32:63] physical register file
			end

		end else begin
			head <= `SD next_head;
			tail <= `SD next_tail;
			FL_table <= `SD next_FL_table;
		end
	end



    logic [`C_PR_ENTRY-1:0] [$clog2(`C_FL_ENTRY_NUM)-1:0]  FL_CAM_table, next_FL_CAM_table;
// assign the cam table according to FL_idx signal, clean the blocks that contain the same T_idx
    always_comb begin
        next_FL_CAM_table = FL_CAM_table;
        
        next_FL_CAM_table[T_idx[0]] = FL_idx[0];
        next_FL_CAM_table[T_idx[1]] = FL_idx[1];
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