Warning: Design 'IB' has '1' unresolved references. For more detailed information, use the "link" command. (UID-341)
 
****************************************
Report : resources
Design : IB
Version: S-2021.06-SP1
Date   : Sat Mar 26 16:05:25 2022
****************************************

Resource Sharing Report for design IB in file
        /afs/umich.edu/user/z/t/ztguan/group6w22/verilog/IB_push_in_router.sv

===============================================================================
|          |              |            | Contained     |                      |
| Resource | Module       | Parameters | Resources     | Contained Operations |
===============================================================================
| r939     | DW01_add     | width=4    |               | ALU_channel/IB_queue_inst/add_119 |
             |            |               |                      |
|          |              |            |               | ALU_channel/IB_queue_inst/add_141 |
             |            |               |                      |
|          |              |            |               | add_1_root_ALU_channel/IB_queue_inst/add_158 |
| r940     | DW01_add     | width=3    |               | ALU_channel/IB_queue_inst/add_120 |
             |            |               |                      |
|          |              |            |               | ALU_channel/IB_queue_inst/add_122 |
| r941     | DW01_add     | width=4    |               | ALU_channel/IB_queue_inst/add_125 |
             |            |               |                      |
|          |              |            |               | ALU_channel/IB_queue_inst/add_144 |
| r942     | DW01_add     | width=3    |               | ALU_channel/IB_queue_inst/add_126 |
             |            |               |                      |
|          |              |            |               | ALU_channel/IB_queue_inst/add_128 |
| r943     | DW01_sub     | width=4    |               | ALU_channel/IB_queue_inst/sub_155 |
             |            |               |                      |
|          |              |            |               | ALU_channel/IB_queue_inst/sub_156 |
| r952     | DW01_inc     | width=3    |               | ALU_channel/IB_queue_inst/add_179_I2 |
          |            |               |                      |
|          |              |            |               | ALU_channel/IB_queue_inst/add_181_I2 |
| r959     | DW01_inc     | width=3    |               | ALU_channel/IB_queue_inst/add_206_I2 |
          |            |               |                      |
|          |              |            |               | ALU_channel/IB_queue_inst/add_208_I2 |
| r962     | DW01_add     | width=3    |               | ALU_channel/IB_queue_inst/add_206_I3 |
          |            |               |                      |
|          |              |            |               | ALU_channel/IB_queue_inst/add_208_I3 |
| r991     | DW01_inc     | width=2    |               | ALU_channel/IB_queue_inst/add_86_I2 |
| r993     | DW01_inc     | width=2    |               | ALU_channel/IB_queue_inst/add_95_I2 |
| r995     | DW01_inc     | width=3    |               | ALU_channel/IB_queue_inst/add_95_I3 |
| r1001    | DW01_sub     | width=4    |               | sub_0_root_ALU_channel/IB_queue_inst/add_158 |
| r1007    | DW01_cmp2    | width=4    |               | ALU_channel/IB_queue_inst/lt_170 |
| r1009    | DW01_cmp2    | width=4    |               | ALU_channel/IB_queue_inst/lt_170_I2 |
| r1011    | DW01_inc     | width=4    |               | ALU_channel/IB_queue_inst/add_178_I2 |
| r1013    | DW01_ash     | A_width=8  |               | ALU_channel/IB_queue_inst/sll_188 |
             |            |               |                      |
|          |              | SH_width=3 |               |                      |
| r1015    | DW01_sub     | width=5    |               | ALU_channel/IB_queue_inst/sub_188 |
| r1017    | DW_rash      | A_width=2  |               | ALU_channel/IB_queue_inst/srl_188 |
             |            |               |                      |
|          |              | SH_width=32 |              |                      |
| r1019    | DW01_cmp2    | width=4    |               | ALU_channel/IB_queue_inst/lt_197 |
| r1021    | DW01_cmp2    | width=4    |               | ALU_channel/IB_queue_inst/lt_197_I2 |
| r1023    | DW01_inc     | width=4    |               | ALU_channel/IB_queue_inst/add_205_I2 |
| r1025    | DW01_cmp2    | width=4    |               | ALU_channel/IB_queue_inst/lt_197_I3 |
| r1027    | DW01_add     | width=4    |               | ALU_channel/IB_queue_inst/add_205_I3 |
| r1029    | DW01_ash     | A_width=8  |               | ALU_channel/IB_queue_inst/sll_213 |
             |            |               |                      |
|          |              | SH_width=3 |               |                      |
| r1031    | DW01_sub     | width=5    |               | ALU_channel/IB_queue_inst/sub_213 |
| r1033    | DW_rash      | A_width=3  |               | ALU_channel/IB_queue_inst/srl_213 |
             |            |               |                      |
|          |              | SH_width=32 |              |                      |
| r1035    | DW01_add     | width=2    |               | ALU_channel/IB_pop_out_router_inst/add_55_I2_C75_aco |
| r1142    | DW01_sub     | width=4    |               | ALU_channel/IB_queue_inst/sub_159 |
| r1144    | DW01_sub     | width=4    |               | ALU_channel/IB_queue_inst/sub_159_2 |
| r1252    | DW01_sub     | width=4    |               | sub_1_root_sub_0_root_ALU_channel/IB_queue_inst/add_155 |
| r1254    | DW01_add     | width=4    |               | add_0_root_sub_0_root_ALU_channel/IB_queue_inst/add_155 |
===============================================================================


No implementations to report
1
