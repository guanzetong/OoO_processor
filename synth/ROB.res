 
****************************************
Report : resources
Design : ROB
Version: S-2021.06-SP1
Date   : Fri Mar 11 23:00:16 2022
****************************************

Resource Sharing Report for design ROB in file
        /afs/umich.edu/user/z/t/ztguan/group6w22/verilog/ROB.sv

===============================================================================
|          |              |            | Contained     |                      |
| Resource | Module       | Parameters | Resources     | Contained Operations |
===============================================================================
| r812     | DW01_sub     | width=7    |               | sub_112 sub_149      |
| r817     | DW01_cmp6    | width=5    |               | gt_240 lt_243        |
| r843     | DW01_ash     | A_width=32 |               | sll_97               |
|          |              | SH_width=5 |               |                      |
| r845     | DW01_ash     | A_width=32 |               | sll_112              |
|          |              | SH_width=5 |               |                      |
| r847     | DW_rash      | A_width=2  |               | srl_112              |
|          |              | SH_width=32 |              |                      |
| r849     | DW01_inc     | width=5    |               | add_117_I2           |
| r851     | DW01_ash     | A_width=32 |               | sll_149              |
|          |              | SH_width=5 |               |                      |
| r853     | DW_rash      | A_width=2  |               | srl_149              |
|          |              | SH_width=32 |              |                      |
| r859     | DW01_sub     | width=6    |               | sub_244              |
| r861     | DW01_cmp2    | width=6    |               | lt_272               |
| r863     | DW01_cmp2    | width=6    |               | lt_272_I2            |
| r865     | DW01_inc     | width=6    |               | add_312_2            |
| r867     | DW01_add     | width=6    |               | add_1_root_add_312_2_I2 |
| r869     | DW01_inc     | width=6    |               | add_324_2            |
| r871     | DW01_add     | width=6    |               | add_1_root_add_324_2_I2 |
| r978     | DW01_sub     | width=6    |               | sub_241              |
| r980     | DW01_sub     | width=6    |               | sub_241_2            |
===============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| sll_97             | DW01_ash         | mx2                |                |
| sll_149            | DW01_ash         | mx2                |                |
| sll_112            | DW01_ash         | mx2                |                |
===============================================================================

1
