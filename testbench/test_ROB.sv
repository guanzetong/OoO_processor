/////////////////////////////////////////////////////////////////////////
//                                                                     //
//  Modulename  :  test_ROB.sv                                         //
//                                                                     //
//  Description :  Test ROB MODULE of the pipeline;                    // 
//                 Reorders out of order instructions                  //
//                 and update state (as if) in the archiectural        //
//                 order.                                              //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////

/*
1. Dispatch, fill all entries
2. Complete,
3. Retire, empty all entries,
4. Dispatch, Complete some, retire some
*/

module testbench;
    logic clk;
    logic rst;
    logic en;

    logic 
