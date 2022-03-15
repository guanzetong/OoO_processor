 
****************************************
Report : resources
Design : ROB
Version: S-2021.06-SP1
Date   : Tue Mar 15 17:18:14 2022
****************************************

Resource Sharing Report for design ROB in file
        /afs/umich.edu/user/z/t/ztguan/group6w22/verilog/ROB.sv

===============================================================================
|          |              |            | Contained     |                      |
| Resource | Module       | Parameters | Resources     | Contained Operations |
===============================================================================
| r860     | DW01_sub     | width=7    |               | sub_105 sub_142      |
|          |              |            |               | sub_232              |
| r862     | DW01_inc     | width=6    |               | add_110_I2           |
|          |              |            |               | add_244_I2 add_290_2 |
| r864     | DW_rash      | A_width=2  |               | srl_142 srl_232      |
|          |              | SH_width=32 |              |                      |
| r878     | DW01_ash     | A_width=32 |               | sll_92               |
|          |              | SH_width=5 |               |                      |
| r880     | DW01_ash     | A_width=32 |               | sll_105              |
|          |              | SH_width=5 |               |                      |
| r882     | DW_rash      | A_width=2  |               | srl_105              |
|          |              | SH_width=32 |              |                      |
| r884     | DW01_ash     | A_width=32 |               | sll_142              |
|          |              | SH_width=5 |               |                      |
| r886     | DW01_ash     | A_width=32 |               | sll_232              |
|          |              | SH_width=5 |               |                      |
| r888     | DW01_inc     | width=5    |               | add_278_2            |
| r890     | DW01_add     | width=5    |               | add_1_root_add_278_2_I2 |
| r892     | DW01_add     | width=5    |               | add_1_root_add_290_2_I2 |
===============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| sll_92             | DW01_ash         | mx2                |                |
| sll_105            | DW01_ash         | mx2                |                |
| sll_142            | DW01_ash         | mx2                |                |
| sll_232            | DW01_ash         | mx2                |                |
===============================================================================

1
