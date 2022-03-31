`define DEBUG
module freelist #(
	parameter C_FL_ENTRY_NUM = `FL_ENTRY_NUM,
    parameter C_FL_IDX = `FL_IDX,
    parameter C_DP_NUM = `DP_NUM,
	parameter C_RT_NUM = `RT_NUM,
    parameter C_ARCH_REG_NUM = `ARCH_REG_NUM,
    parameter C_PHY_REG_NUM = `PHY_REG_NUM,
	parameter C_PHY_IDX = `TAG_IDX_WIDTH
) (
	input logic clk_i,
	input logic rst_i,
	input logic rollback_i,

	input DP_FL dp_fl_i,
    input ROB_FL rob_fl_i,
	input ROB_VFL    vfl_i,

    `ifdef DEBUG
	output FL_ENTRY   [C_FL_ENTRY_NUM-1:0]   fl_entry, next_fl_entry,
	output logic   [C_FL_IDX-1:0]                 		fl_rollback_idx,
	output logic   [C_FL_IDX-1:0]                 		head, next_head,
	output logic   [C_FL_IDX-1:0]                 		tail, next_tail,
	output logic   [C_DP_NUM-1:0] [C_FL_IDX-1:0] 	fl_idx,   // tail position in fl, used to rollback cam
	`endif

    output FL_DP fl_dp_o
);



	`ifndef DEBUG
    logic [C_DP_NUM-1:0] [C_FL_IDX-1:0] 	fl_idx;	
	logic [C_FL_IDX-1:0]                 head, next_head;	//  indicate location of tag retired in the fl
	logic [C_FL_IDX-1:0]                 tail, next_tail;  	// indicate location of tag  dispatched in the fl
	logic [C_FL_IDX-1:0]                 		fl_rollback_idx;
	FL_ENTRY   [C_FL_ENTRY_NUM-1:0]   fl_entry, next_fl_entry;
	`endif

    logic [C_FL_IDX-1:0]                 	head_plus_one, head_plus_two;		// superscalar
	logic [C_FL_IDX-1:0]                 	tail_plus_one, tail_plus_two;
	logic [C_FL_IDX-1:0]                 	dp_tail;		// next tail position when dispatch is enabled
	logic [C_FL_IDX-1:0]                 	rt_head;		// next head position when retire is enabled


	logic first_rd_nz;
	logic second_rd_nz;
	logic second_told_nz;


    assign first_rd_nz = (rob_fl_i.phy_reg[0] != `ZERO_PREG);
    assign second_rd_nz = (rob_fl_i.phy_reg[1] != `ZERO_PREG);

    assign next_head = (rob_fl_i.rt_num[0] || rob_fl_i.rt_num[1]) ? rt_head : head;

	assign next_tail =  rollback_i ? fl_rollback_idx :
                        (dp_fl_i.dp_num[0] || dp_fl_i.dp_num[1]) ? dp_tail : tail;


    assign tail_plus_one = tail + 1;
	assign tail_plus_two = tail + 2;
	assign head_plus_one = head + 1;
	assign head_plus_two = head + 2;

    assign fl_dp_o.avail_num = 	(next_head == tail)? 2'b00:		//no preg available
						        (next_head == tail_plus_one) ? 2'b01:	// one available
						                        2'b11;					// both available
	
	// dispatch logic 
    always_comb begin
		if (first_rd_nz && second_rd_nz && (dp_fl_i.dp_num == 2'b11)) begin
			dp_tail = tail_plus_two;
			fl_dp_o.tag = {next_fl_entry[tail_plus_one], next_fl_entry[tail]};
			fl_idx = {tail_plus_two, tail_plus_one};
		end else if (first_rd_nz && (dp_fl_i.dp_num == 2'b01)) begin
			dp_tail = tail_plus_one;
			fl_dp_o.tag = {`ZERO_PREG, next_fl_entry[tail]};
			fl_idx = {tail_plus_one, tail_plus_one};
		end else if (second_rd_nz && (dp_fl_i.dp_num == 2'b10)) begin
			dp_tail = tail_plus_one;
			fl_dp_o.tag = {next_fl_entry[tail], `ZERO_PREG};
			fl_idx = {tail_plus_one, tail};
		end else begin
			dp_tail = tail;
			fl_dp_o.tag = {`ZERO_PREG, `ZERO_PREG};
			fl_idx = {tail, tail};
		end
	end


	// retire logic
    always_comb begin
		next_fl_entry = fl_entry;
		unique if (first_rd_nz && second_rd_nz && (rob_fl_i.rt_num == 2'b11)) begin
			next_fl_entry[head].tag = rob_fl_i.phy_reg[0];
			next_fl_entry[head_plus_one].tag = rob_fl_i.phy_reg[1];
			rt_head = head_plus_two;
		end else if (first_rd_nz  && (rob_fl_i.rt_num == 2'b01)) begin
			next_fl_entry[head].tag = rob_fl_i.phy_reg[0];
			rt_head = head_plus_one;
		end else if (second_told_nz && (rob_fl_i.rt_num == 2'b10)) begin
			next_fl_entry[head].tag = rob_fl_i.phy_reg[1];
			rt_head = head_plus_one;
		end else begin
			rt_head = head;
			next_fl_entry = fl_entry;
		end
	end

	// initialize the entry
    always_ff @(posedge clk_i) begin
		if (rst_i) begin
			head <=  {$clog2(C_FL_ENTRY_NUM){1'b0}};
			tail <=  1'b1;
			for (int i=1; i<C_FL_ENTRY_NUM; i++) begin
				if (i == 0) begin
					fl_entry[0].tag <= `ZERO_PREG;
				end
				else fl_entry[i].tag <=  i + C_ARCH_REG_NUM; 	// [32:63] physical register file
			end

		end else begin
			head <=  next_head;
			tail <=  next_tail;
			fl_entry <=  next_fl_entry;
		end
	end

	fl_cam freelist_cam(
		.clock(clk_i),
		.reset(rst_i),
		.vfl_i(vfl_i),
		.fl_idx(fl_idx),
		.fl_dp_i(fl_dp_o),
		.fl_rollback_idx(fl_rollback_idx)
	);
endmodule


module fl_cam #(
	parameter C_FL_ENTRY_NUM = `FL_ENTRY_NUM,
    parameter C_FL_IDX = `FL_IDX,
    parameter C_DP_NUM = `DP_NUM,
	parameter C_RT_NUM = `RT_NUM,
    parameter C_ARCH_REG_NUM = `ARCH_REG_NUM,
    parameter C_PHY_REG_NUM = `PHY_REG_NUM,
	parameter C_PHY_IDX = `TAG_IDX_WIDTH
) (
    input   clock, reset,
    input   ROB_VFL    vfl_i,  
	input FL_DP fl_dp_i,				//destination register
	input   [C_DP_NUM-1:0] [C_FL_IDX-1:0]    fl_idx,

    //outputs
    output logic    [$clog2(C_FL_ENTRY_NUM)-1:0]       fl_rollback_idx
);
    logic [C_PHY_REG_NUM-1:0][C_FL_IDX-1:0]  fl_cam, next_fl_cam; // This array store the tail position at fl of dispatched tag

	// assign the cam table according to fl_idx signal, clean the blocks that contain the same tag
    always_comb begin
        next_fl_cam = fl_cam;
        next_fl_cam[fl_dp_i.tag[0]] = fl_idx[0];
        next_fl_cam[fl_dp_i.tag[1]] = fl_idx[1];
    end

    assign fl_rollback_idx = fl_cam[vfl_i.tag];


    always_ff @(posedge clock) begin
        if (reset) begin    
			for (int i=1; i<C_PHY_REG_NUM; i++) begin
				fl_cam[i] <=  0; 
			end
        end else begin
            fl_cam <=  next_fl_cam;
        end
    end
endmodule