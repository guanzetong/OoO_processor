 
****************************************
Report : resources
Design : ROB
Version: S-2021.06-SP1
Date   : Tue Mar 15 21:54:30 2022
****************************************

Resource Sharing Report for design ROB in file
        /afs/umich.edu/user/z/t/ztguan/group6w22/verilog/ROB.sv

===============================================================================
|          |              |            | Contained     |                      |
| Resource | Module       | Parameters | Resources     | Contained Operations |
===============================================================================
| r828     | DW01_sub     | width=7    |               | sub_107 sub_144      |
|          |              |            |               | sub_234              |
| r830     | DW01_inc     | width=6    |               | add_112_I2           |
|          |              |            |               | add_246_I2 add_292_2 |
| r832     | DW_rash      | A_width=2  |               | srl_144 srl_234      |
|          |              | SH_width=32 |              |                      |
| r846     | DW01_ash     | A_width=32 |               | sll_94               |
|          |              | SH_width=5 |               |                      |
| r848     | DW01_ash     | A_width=32 |               | sll_107              |
|          |              | SH_width=5 |               |                      |
| r850     | DW_rash      | A_width=2  |               | srl_107              |
|          |              | SH_width=32 |              |                      |
| r852     | DW01_ash     | A_width=32 |               | sll_144              |
|          |              | SH_width=5 |               |                      |
| r854     | DW01_ash     | A_width=32 |               | sll_234              |
|          |              | SH_width=5 |               |                      |
| r856     | DW01_inc     | width=5    |               | add_280_2            |
| r858     | DW01_add     | width=5    |               | add_1_root_add_280_2_I2 |
| r860     | DW01_add     | width=5    |               | add_1_root_add_292_2_I2 |
===============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| sll_94             | DW01_ash         | mx2                |                |
| sll_107            | DW01_ash         | mx2                |                |
| sll_144            | DW01_ash         | mx2                |                |
| sll_234            | DW01_ash         | mx2                |                |
===============================================================================

1
