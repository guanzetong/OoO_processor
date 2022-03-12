 
****************************************
Report : resources
Design : ROB
Version: S-2021.06-SP1
Date   : Fri Mar 11 22:07:06 2022
****************************************

Resource Sharing Report for design ROB in file
        /afs/umich.edu/user/z/t/ztguan/group6w22/verilog/ROB.sv

===============================================================================
|          |              |            | Contained     |                      |
| Resource | Module       | Parameters | Resources     | Contained Operations |
===============================================================================
| r812     | DW01_sub     | width=7    |               | sub_111 sub_148      |
| r817     | DW01_cmp6    | width=5    |               | gt_239 lt_242        |
| r843     | DW01_ash     | A_width=32 |               | sll_98               |
|          |              | SH_width=5 |               |                      |
| r845     | DW01_ash     | A_width=32 |               | sll_111              |
|          |              | SH_width=5 |               |                      |
| r847     | DW_rash      | A_width=2  |               | srl_111              |
|          |              | SH_width=32 |              |                      |
| r849     | DW01_inc     | width=5    |               | add_116_I2           |
| r851     | DW01_ash     | A_width=32 |               | sll_148              |
|          |              | SH_width=5 |               |                      |
| r853     | DW_rash      | A_width=2  |               | srl_148              |
|          |              | SH_width=32 |              |                      |
| r859     | DW01_sub     | width=6    |               | sub_243              |
| r861     | DW01_cmp2    | width=6    |               | lt_271               |
| r863     | DW01_cmp2    | width=6    |               | lt_271_I2            |
| r865     | DW01_inc     | width=6    |               | add_311_2            |
| r867     | DW01_add     | width=6    |               | add_1_root_add_311_2_I2 |
| r869     | DW01_inc     | width=6    |               | add_323_2            |
| r871     | DW01_add     | width=6    |               | add_1_root_add_323_2_I2 |
| r978     | DW01_sub     | width=6    |               | sub_240              |
| r980     | DW01_sub     | width=6    |               | sub_240_2            |
===============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| sll_98             | DW01_ash         | mx2                |                |
| sll_148            | DW01_ash         | mx2                |                |
| sll_111            | DW01_ash         | mx2                |                |
===============================================================================

1
