 
****************************************
Report : resources
Design : ROB
Version: S-2021.06-SP1
Date   : Tue Mar 15 21:41:55 2022
****************************************

Resource Sharing Report for design ROB in file
        /afs/umich.edu/user/z/t/ztguan/group6w22/verilog/ROB.sv

===============================================================================
|          |              |            | Contained     |                      |
| Resource | Module       | Parameters | Resources     | Contained Operations |
===============================================================================
| r828     | DW01_sub     | width=7    |               | sub_129 sub_166      |
|          |              |            |               | sub_256              |
| r830     | DW01_inc     | width=6    |               | add_134_I2           |
|          |              |            |               | add_268_I2 add_314_2 |
| r832     | DW_rash      | A_width=2  |               | srl_166 srl_256      |
|          |              | SH_width=32 |              |                      |
| r846     | DW01_ash     | A_width=32 |               | sll_116              |
|          |              | SH_width=5 |               |                      |
| r848     | DW01_ash     | A_width=32 |               | sll_129              |
|          |              | SH_width=5 |               |                      |
| r850     | DW_rash      | A_width=2  |               | srl_129              |
|          |              | SH_width=32 |              |                      |
| r852     | DW01_ash     | A_width=32 |               | sll_166              |
|          |              | SH_width=5 |               |                      |
| r854     | DW01_ash     | A_width=32 |               | sll_256              |
|          |              | SH_width=5 |               |                      |
| r856     | DW01_inc     | width=5    |               | add_302_2            |
| r858     | DW01_add     | width=5    |               | add_1_root_add_302_2_I2 |
| r860     | DW01_add     | width=5    |               | add_1_root_add_314_2_I2 |
===============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| sll_116            | DW01_ash         | mx2                |                |
| sll_129            | DW01_ash         | mx2                |                |
| sll_166            | DW01_ash         | mx2                |                |
| sll_256            | DW01_ash         | mx2                |                |
===============================================================================

1
