/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  FU_tb.sv                                            //
//                                                                     //
//  Description :  Testbench module for FU;                            //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

module testbench;

// ====================================================================
// Local Parameters Declarations Start
// ====================================================================
    localparam  C_CLK_PERIOD    =   10;
// ====================================================================
// Local Parameters Declarations End
// ====================================================================

// ====================================================================
// Signal Declarations Start
// ====================================================================
    logic                           clk_i       ;
    logic                           rst_i       ;
    IB_FU   [`FU_NUM-1:0]           ib_fu_i     ;
    FU_IB   [`FU_NUM-1:0]           fu_ib_o     ;
    FU_BC   [`FU_NUM-1:0]           fu_bc_o     ;
    BC_FU   [`FU_NUM-1:0]           bc_fu_i     ;
    ALU_FUNC                        alu_func    ;
    logic                           quit ;
    logic                           correct ;

// ====================================================================
// Signal Declarations End
// ====================================================================


// ====================================================================
// Design Under Test (DUT) Instantiation Start
// ====================================================================
// --------------------------------------------------------------------
// Module name  :   FU
// Description  :   Execute the instruction.
// --------------------------------------------------------------------
    FU dut(
        .clk_i              (clk_i              ),
        .rst_i              (rst_i              ),
        .ib_fu_i            (ib_fu_i            ),
        .fu_ib_o            (fu_ib_o            ),
        .fu_bc_o            (fu_bc_o            ),
        .bc_fu_i            (bc_fu_i            )
    );
// ====================================================================
// Design Under Test (DUT) Instantiation End
// ====================================================================

// ====================================================================
// Clock Generator Start
// ====================================================================
    initial begin
        clk_i   =   0;
        forever begin
            #(C_CLK_PERIOD/2)   clk_i   =   ~clk_i;
        end
    end
// ====================================================================
// Clock Generator End
// ====================================================================

// ====================================================================
// wait_until_valid Start
// ====================================================================
    task wait_until_valid;
        // int i = 0;
        // int i = `ALU_NUM;
        int i = `ALU_NUM + `MULT_NUM;
        forever begin : wait_loop
            @(posedge fu_bc_o[i].valid);
            @(negedge clk_i);
            if(fu_bc_o[i].valid) disable wait_until_valid;
        end
    endtask
// ====================================================================
// wait_until_valid End
// ====================================================================

// ====================================================================
// Correctness Check Start
// ====================================================================
    always @(posedge clk_i)
        if(!correct) begin 
            $display("incorrect!");
            $finish;
        end

// ====================================================================
// Correctness Check End
// ====================================================================

// ====================================================================
// ALU Test Start
// ====================================================================
    // initial begin
    //     int i = 0;
    //     logic signed [`XLEN-1:0] signed_opa, signed_opb;
    //     assign signed_opa = ib_fu_i[i].is_inst.rs1_value;
    //     assign signed_opb = ib_fu_i[i].is_inst.rs2_value;
    //     $monitor("fu_ib_o.ready:%h rs1_value:%h rs2_value:%h rd_value:%h fu_bc_o.valid:%h write_reg:%h br_result:%h br_target:%h broadcasted:%h", 
    //         fu_ib_o[i].ready, 
    //         ib_fu_i[i].is_inst.rs1_value, 
    //         ib_fu_i[i].is_inst.rs2_value, 
    //         fu_bc_o[i].rd_value, 
    //         fu_bc_o[i].valid, 
    //         fu_bc_o[i].write_reg, 
    //         fu_bc_o[i].br_result, 
    //         fu_bc_o[i].br_target,
    //         bc_fu_i[i].broadcasted);

    //     correct = 1;

    //     //ALU_ADD test
    //     alu_func = ALU_ADD;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value + ib_fu_i[i].is_inst.rs2_value);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);

    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(! (fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value + ib_fu_i[i].is_inst.rs2_value)) correct = 0;
    //         if(! (fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(! (fu_bc_o[i].br_result == 0)) correct = 0;
    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //         if(! (fu_ib_o[i].ready == 1)) correct = 0;
    //         if(! (fu_bc_o[i].valid == 0)) correct = 0;

    //     end

    //     //ALU_SUB test
    //     alu_func = ALU_SUB;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value - ib_fu_i[i].is_inst.rs2_value);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value - ib_fu_i[i].is_inst.rs2_value)) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_AND test
    //     alu_func = ALU_AND;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == (ib_fu_i[i].is_inst.rs1_value & ib_fu_i[i].is_inst.rs2_value));
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == (ib_fu_i[i].is_inst.rs1_value & ib_fu_i[i].is_inst.rs2_value))) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_SLT test
    //     alu_func = ALU_SLT;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == signed_opa < signed_opb);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == signed_opa < signed_opb)) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_SLTU test
    //     alu_func = ALU_SLTU;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value < ib_fu_i[i].is_inst.rs2_value);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value < ib_fu_i[i].is_inst.rs2_value)) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_OR test
    //     alu_func = ALU_OR;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value | ib_fu_i[i].is_inst.rs2_value);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value | ib_fu_i[i].is_inst.rs2_value)) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end


    //     //ALU_XOR test
    //     alu_func = ALU_XOR;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value ^ ib_fu_i[i].is_inst.rs2_value);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value ^ ib_fu_i[i].is_inst.rs2_value)) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_SRL test
    //     alu_func = ALU_SRL;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == (ib_fu_i[i].is_inst.rs1_value >> ib_fu_i[i].is_inst.rs2_value[4:0]));
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == (ib_fu_i[i].is_inst.rs1_value >> ib_fu_i[i].is_inst.rs2_value[4:0]))) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;
    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_SLL test
    //     alu_func = ALU_SLL;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == (ib_fu_i[i].is_inst.rs1_value << ib_fu_i[i].is_inst.rs2_value[4:0]));
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == (ib_fu_i[i].is_inst.rs1_value << ib_fu_i[i].is_inst.rs2_value[4:0]))) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_SRA test
    //     alu_func = ALU_SRA;
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = alu_func;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         //assert (fu_bc_o[i].rd_value === (signed_opa >>> ib_fu_i[i].is_inst.rs2_value[4:0]) );
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         //$display("signed_opa >> ib_fu_i[i].is_inst.rs2_value[4:0]:%h",signed_opa >>> ib_fu_i[i].is_inst.rs2_value[4:0]);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         //if(!(fu_bc_o[i].rd_value === (signed_opa >>> ib_fu_i[i].is_inst.rs2_value[4:0]) )) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     $display("ALU test pass");
    // end

// ====================================================================
// ALU Test End
// ====================================================================

// ====================================================================
// MULT Test Start
// ====================================================================
    // initial begin
    //     int i = `ALU_NUM;
    //     logic [`XLEN-1:0] opa, opb;
    //     logic signed [`XLEN-1:0] signed_opa, signed_opb;
    //     logic signed [2*`XLEN-1:0] signed_mul, mixed_mul;
    //     logic        [2*`XLEN-1:0] unsigned_mul;
    //     assign opa = ib_fu_i[i].is_inst.rs1_value;
    //     assign opa = ib_fu_i[i].is_inst.rs2_value;
    //     assign signed_opa = ib_fu_i[i].is_inst.rs1_value;
    //     assign signed_opb = ib_fu_i[i].is_inst.rs2_value;
    //     assign signed_mul = signed_opa * signed_opb;
    //     assign unsigned_mul = opa * opb;
    //     assign mixed_mul = signed_opa * opb;
    //     $monitor("fu_ib_o.ready:%h fu_ib_o.start:%h rs1_value:%h rs2_value:%h rd_value:%h fu_bc_o.valid:%h write_reg:%h br_result:%h br_target:%h broadcasted:%h", 
    //         fu_ib_o[i].ready, 
    //         ib_fu_i[i].start,
    //         ib_fu_i[i].is_inst.rs1_value, 
    //         ib_fu_i[i].is_inst.rs2_value, 
    //         fu_bc_o[i].rd_value, 
    //         fu_bc_o[i].valid, 
    //         fu_bc_o[i].write_reg, 
    //         fu_bc_o[i].br_result, 
    //         fu_bc_o[i].br_target,
    //         bc_fu_i[i].broadcasted);

    //     correct = 1;

    //     //ALU_MUL test
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = ALU_MUL;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == signed_mul[`XLEN-1:0]);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == signed_mul[`XLEN-1:0])) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_MULH test
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = ALU_MULH;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == signed_mul[2*`XLEN-1:`XLEN]);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == signed_mul[2*`XLEN-1:`XLEN])) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_MULHSU test
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = ALU_MULHSU;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == mixed_mul[2*`XLEN-1:`XLEN]);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == mixed_mul[2*`XLEN-1:`XLEN])) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end

    //     //ALU_MULHU test
    //     quit = 0;
    //     quit <= #10000 1;
    //     while(~quit) begin
    //         @(negedge clk_i);
    //         rst_i = 1;
    //         ib_fu_i[i].start = 0;
    //         bc_fu_i[i].broadcasted = 0;

    //         @(negedge clk_i);
    //         rst_i = 0;

    //         assert(fu_ib_o[i].ready == 1);
    //         assert(fu_bc_o[i].valid == 0);
    //         if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

    //         ib_fu_i[i].start = 1;
    //         ib_fu_i[i].valid = 1;
    //         ib_fu_i[i].is_inst.opa_select = 0;
    //         ib_fu_i[i].is_inst.opb_select = 0;
    //         ib_fu_i[i].is_inst.alu_func = ALU_MULHU;

    //         ib_fu_i[i].is_inst.rs1_value = {$random,$random};
    //         ib_fu_i[i].is_inst.rs2_value = {$random,$random};

    //         @(negedge clk_i);
    //         ib_fu_i[i].start = 0;

    //         wait_until_valid();
    //         // $display("wait_until_valid finish");
    //         assert (fu_ib_o[i].ready == 0);
    //         assert (fu_bc_o[i].valid == 1);
    //         assert (fu_bc_o[i].rd_value == unsigned_mul[2*`XLEN-1:`XLEN]);
    //         assert (fu_bc_o[i].br_inst == 0);
    //         assert (fu_bc_o[i].br_result == 0);
    //         if(!(fu_ib_o[i].ready == 0)) correct = 0;
    //         if(!(fu_bc_o[i].valid == 1)) correct = 0;
    //         if(!(fu_bc_o[i].rd_value == unsigned_mul[2*`XLEN-1:`XLEN])) correct = 0;
    //         if(!(fu_bc_o[i].br_inst == 0)) correct = 0;
    //         if(!(fu_bc_o[i].br_result == 0)) correct = 0;

    //         bc_fu_i[i].broadcasted = 1;

    //         @(negedge clk_i);
    //         assert (fu_ib_o[i].ready == 1);
    //         assert (fu_bc_o[i].valid == 0);
    //     end


    //     $display("MULT test pass");
    //     $finish;
    // end

// ====================================================================
// MULT Test End
// ====================================================================


// ====================================================================
// BR Test Start
// ====================================================================
    initial begin
        int i = `ALU_NUM + `MULT_NUM;
        logic signed [`XLEN-1:0] signed_rs1, signed_rs2;
        assign signed_rs1 = ib_fu_i[i].is_inst.rs1_value;
        assign signed_rs2 = ib_fu_i[i].is_inst.rs2_value;
        $monitor("fu_ib_o.ready:%h rs1_value:%h rs2_value:%h rd_value:%h fu_bc_o.valid:%h write_reg:%h br_result:%h br_target:%h broadcasted:%h", 
            fu_ib_o[i].ready, 
            ib_fu_i[i].is_inst.rs1_value, 
            ib_fu_i[i].is_inst.rs2_value, 
            fu_bc_o[i].rd_value, 
            fu_bc_o[i].valid, 
            fu_bc_o[i].write_reg, 
            fu_bc_o[i].br_result, 
            fu_bc_o[i].br_target,
            bc_fu_i[i].broadcasted);

        correct = 1;

        //uncond_br test
        quit = 0;
        quit <= #10000 1;
        while(~quit) begin
            @(negedge clk_i);
            rst_i = 1;
            ib_fu_i[i].start = 0;
            bc_fu_i[i].broadcasted = 0;

            @(negedge clk_i);
            rst_i = 0;

            assert(fu_ib_o[i].ready == 1);
            assert(fu_bc_o[i].valid == 0);
            if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

            ib_fu_i[i].start = 1;
            ib_fu_i[i].valid = 1;
            ib_fu_i[i].is_inst.opa_select = OPA_IS_PC;
            ib_fu_i[i].is_inst.opb_select = OPB_IS_RS2;
            ib_fu_i[i].is_inst.alu_func = ALU_ADD;
            ib_fu_i[i].is_inst.uncond_br = 1;

            ib_fu_i[i].is_inst.pc = {$random,$random};
            ib_fu_i[i].is_inst.rs2_value = {$random,$random};

            @(negedge clk_i);
            ib_fu_i[i].start = 0;

            wait_until_valid();
            // $display("wait_until_valid finish");
            assert (fu_ib_o[i].ready == 0);
            assert (fu_bc_o[i].valid == 1);
            //assert (fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value + ib_fu_i[i].is_inst.rs2_value);
            assert (fu_bc_o[i].br_inst == 1);
            assert (fu_bc_o[i].br_result == 1);
            assert (fu_bc_o[i].br_target == ib_fu_i[i].is_inst.pc + ib_fu_i[i].is_inst.rs2_value);

            if(!(fu_ib_o[i].ready == 0)) correct = 0;
            if(!(fu_bc_o[i].valid == 1)) correct = 0;
            //if(!(fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value + ib_fu_i[i].is_inst.rs2_value)) correct = 0;
            if(!(fu_bc_o[i].br_inst == 1)) correct = 0;
            if(!(fu_bc_o[i].br_result == 1)) correct = 0;
            if(!(fu_bc_o[i].br_target == ib_fu_i[i].is_inst.pc + ib_fu_i[i].is_inst.rs2_value)) correct = 0;
            
            bc_fu_i[i].broadcasted = 1;

            @(negedge clk_i);
            assert (fu_ib_o[i].ready == 1);
            assert (fu_bc_o[i].valid == 0);
            if(! (fu_ib_o[i].ready == 1)) correct = 0;
            if(! (fu_bc_o[i].valid == 0)) correct = 0;

        end

        //cond_br test
        quit = 0;
        quit <= #10000 1;
        while(~quit) begin
            @(negedge clk_i);
            rst_i = 1;
            ib_fu_i[i].start = 0;
            bc_fu_i[i].broadcasted = 0;

            @(negedge clk_i);
            rst_i = 0;

            assert(fu_ib_o[i].ready == 1);
            assert(fu_bc_o[i].valid == 0);
            if(!(fu_ib_o[i].ready == 1) | !(fu_bc_o[i].valid == 0)) correct = 0;

            ib_fu_i[i].start = 1;
            ib_fu_i[i].valid = 1;
            ib_fu_i[i].is_inst.opa_select = OPA_IS_PC;
            ib_fu_i[i].is_inst.opb_select = OPB_IS_I_IMM;
            ib_fu_i[i].is_inst.alu_func = ALU_ADD;
            ib_fu_i[i].is_inst.uncond_br = 0;
            ib_fu_i[i].is_inst.inst.b.funct3 = 3'b000;

            ib_fu_i[i].is_inst.pc = {$random,$random};
            ib_fu_i[i].is_inst.rs1_value = {$random,$random};
            ib_fu_i[i].is_inst.rs2_value = {$random,$random};

            @(negedge clk_i);
            ib_fu_i[i].start = 0;

            wait_until_valid();
            // $display("wait_until_valid finish");
            assert (fu_ib_o[i].ready == 0);
            assert (fu_bc_o[i].valid == 1);
            //assert (fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value + ib_fu_i[i].is_inst.rs2_value);
            assert (fu_bc_o[i].br_inst == 1);
            assert (fu_bc_o[i].br_result == (signed_rs1 == signed_rs2));
            //assert (fu_bc_o[i].br_target == ib_fu_i[i].is_inst.pc + ib_fu_i[i].is_inst.rs2_value);

            if(!(fu_ib_o[i].ready == 0)) correct = 0;
            if(!(fu_bc_o[i].valid == 1)) correct = 0;
            //if(!(fu_bc_o[i].rd_value == ib_fu_i[i].is_inst.rs1_value + ib_fu_i[i].is_inst.rs2_value)) correct = 0;
            if(!(fu_bc_o[i].br_inst == 1)) correct = 0;
            if(!(fu_bc_o[i].br_result == (signed_rs1 == signed_rs2))) correct = 0;
            //if(!(fu_bc_o[i].br_target == ib_fu_i[i].is_inst.pc + ib_fu_i[i].is_inst.rs2_value)) correct = 0;
            
            bc_fu_i[i].broadcasted = 1;

            @(negedge clk_i);
            assert (fu_ib_o[i].ready == 1);
            assert (fu_bc_o[i].valid == 0);
            if(! (fu_ib_o[i].ready == 1)) correct = 0;
            if(! (fu_bc_o[i].valid == 0)) correct = 0;

        end

        $display("BR test pass");
        $finish;
    end

// ====================================================================
// BR Test End
// ====================================================================
endmodule  // module testbench
