/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//   Modulename :  FU_tb.sv                                            //
//                                                                     //
//  Description :  Testbench module for FU;                            //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

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
    logic                           exception_i ;

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
        forever begin : wait_loop
            @(posedge fu_bc_o.valid);
            @(negedge clock);
            if(fu_bc_o.valid) disable wait_until_valid;
        end
    endtask
// ====================================================================
// wait_until_valid End
// ====================================================================

// ====================================================================
// ALU Test Start
// ====================================================================
    initial begin
        $dumpvars;
        $monitor("rs1_value:%d rs2_value:%d write_reg:%d rd_value:%d 
            br_result:%d br_target:%d", 
            ib_fu_i.is_inst.rs1_value, 
            ib_fu_i.is_inst.rs2_value, 
            fu_bc_o.write_reg, 
            fu_bc_o.rd_value, 
            fu_bc_o.br_result, 
            fu_bc_o.br_target);


        @(negedge clock);
        rst_i = 1;
        ib_fu_i.start = 0;
        bc_fu_i.broadcasted = 0;

        @(negedge clock);
        assert property (fu_ib_o.ready == 1);
        assert property (fu_bc_o.valid == 0);

        ib_fu_i.start = 1;
        ib_fu_i.valid = 1;
        ib_fu_i.is_inst.opa_select = 0;
        ib_fu_i.is_inst.opb_select = 0;
        ib_fu_i.is_inst.alu_func = ALU_ADD;

        ib_fu_i.is_inst.rs1_value = 0;
        ib_fu_i.is_inst.rs2_value = 0;

        wait_until_valid();
        assert property (fu_ib_o.ready == 0);
        assert property (fu_bc_o.valid == 1);
        assert property (fu_bc_o.rd_value == ib_fu_i.is_inst.rs1_value + ib_fu_i.is_inst.rs2_value);
        assert property (fu_bc_o.br_inst == 0);
        assert property (fu_bc_o.br_result == 0);

        bc_fu_i.broadcasted = 1;

        @(negedge clock);
        assert property (fu_ib_o.ready == 1);
        assert property (fu_bc_o.valid == 0);

        $finish;
    end

// ====================================================================
// ALU Test End
// ====================================================================
endmodule  // module testbench
