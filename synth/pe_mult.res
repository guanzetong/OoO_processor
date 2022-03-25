 
****************************************
Report : resources
Design : pe_mult
Version: S-2021.06-SP1
Date   : Thu Mar 24 23:00:18 2022
****************************************

Resource Sharing Report for design pe_mult in file
        /afs/umich.edu/user/z/t/ztguan/group6w22/verilog/pe.sv

===============================================================================
|          |              |            | Contained     |                      |
| Resource | Module       | Parameters | Resources     | Contained Operations |
===============================================================================
| r151     | DW01_ash     | A_width=32 |               | genblk1[0].genblk2.binary_decoder_inst/sll_22 |
 |            |               |                      |
|          |              | SH_width=5 |               |                      |
| r153     | DW01_ash     | A_width=32 |               | genblk1[1].genblk2.binary_decoder_inst/sll_22 |
 |            |               |                      |
|          |              | SH_width=5 |               |                      |
===============================================================================


Implementation Report
===============================================================================
|                    |                  | Current            | Set            |
| Cell               | Module           | Implementation     | Implementation |
===============================================================================
| genblk1[0].genblk2.binary_decoder_inst/sll_22              |                |
|                    | DW01_ash         | mx2                |                |
| genblk1[1].genblk2.binary_decoder_inst/sll_22              |                |
|                    | DW01_ash         | mx2                |                |
===============================================================================

1
