################################################################################
## DO NOT EDIT THESE FILES BY HAND
##
## CONFIGURATION HAS BEEN MOVED TO THE MAKEFILE
################################################################################
set search_path [ list "./" "/afs/umich.edu/class/eecs470/lib/synopsys/" ]
set target_library "lec25dscc25_TT.db"
set link_library [concat  "*" $target_library]

#/***********************************************************/
#/* Set some flags to suppress warnings we don't care about */
set suppress_errors [concat $suppress_errors "UID-401"]
suppress_message {"VER-130"}

#/***********************************************************/
#/* The following lines are set from environment variables
#/* automatically by the Makefile
#/***********************************************************/
lappend search_path ../

set DCACHE [getenv DCACHE_NAME]
read_file -f ddc [list ${DCACHE}.ddc]
set_dont_touch ${DCACHE} 

set ICACHE [getenv ICACHE_NAME]
read_file -f ddc [list ${ICACHE}.ddc]
set_dont_touch ${ICACHE} 

set IF [getenv IF_NAME]
read_file -f ddc [list ${IF}.ddc]
set_dont_touch ${IF} 

# set DP [getenv DP_NAME]
# read_file -f ddc [list ${DP}.ddc]
# set_dont_touch ${DP} 

set ROB [getenv ROB_NAME]
read_file -f ddc [list ${ROB}.ddc]
set_dont_touch ${ROB} 

set FL [getenv FL_NAME]
read_file -f ddc [list ${FL}.ddc]
set_dont_touch ${FL} 

set AMT [getenv AMT_NAME]
read_file -f ddc [list ${AMT}.ddc]
set_dont_touch ${AMT} 

set MT [getenv MT_NAME]
read_file -f ddc [list ${MT}.ddc]
set_dont_touch ${MT} 

set RS [getenv RS_NAME]
read_file -f ddc [list ${RS}.ddc]
set_dont_touch ${RS} 

set IB [getenv IB_NAME]
read_file -f ddc [list ${IB}.ddc]
set_dont_touch ${IB} 

set FU [getenv FU_NAME]
read_file -f ddc [list ${FU}.ddc]
set_dont_touch ${FU} 

set PRF [getenv PRF_NAME]
read_file -f ddc [list ${PRF}.ddc]
set_dont_touch ${PRF} 

set LSQ [getenv LSQ_NAME]
read_file -f ddc [list ${LSQ}.ddc]
set_dont_touch ${LSQ} 

set BC [getenv BC_NAME]
read_file -f ddc [list ${BC}.ddc]
set_dont_touch ${BC} 

set MEMSW [getenv MEMSW_NAME]
read_file -f ddc [list ${MEMSW}.ddc]
set_dont_touch ${MEMSW} 

set DCSW [getenv DCSW_NAME]
read_file -f ddc [list ${DCSW}.ddc]
set_dont_touch ${DCSW} 

set headers [getenv HEADERS]
set sources [getenv PIPEFILES]

read_file -f sverilog [list ${headers} ${sources}]
set design_name [getenv PIPELINE_NAME]
set clock_name [getenv CLOCK_NET_NAME]
set reset_name [getenv RESET_NET_NAME]
set CLK_PERIOD [getenv CLOCK_PERIOD]

set SYN_DIR ./


#/***********************************************************/
#/* You should NOT edit anything below this line for 470    */
#/***********************************************************/

#/***********************************************************/
#/* Set some flags for optimisation */

set compile_top_all_paths "true"
set auto_wire_load_selection "false"
set compile_seqmap_synchronous_extraction "true"

# uncomment this and change number appropriately if on multi-core machine
#set_host_options -max_cores 2

#/***********************************************************/
#/*  Clk Periods/uncertainty/transition                     */

set CLK_TRANSITION 0.1
set CLK_UNCERTAINTY 0.1
set CLK_LATENCY 0.1

#/* Input/output Delay values */
set AVG_INPUT_DELAY 0.1
set AVG_OUTPUT_DELAY 0.1

#/* Critical Range (ns) */
set CRIT_RANGE 1.0

#/***********************************************************/
#/* Design Constrains: Not all used                         */
set MAX_TRANSITION 1.0
set FAST_TRANSITION 0.1
set MAX_FANOUT 32
set MID_FANOUT 8
set LOW_FANOUT 1
set HIGH_DRIVE 0
set HIGH_LOAD 1.0
set AVG_LOAD 0.1
set AVG_FANOUT_LOAD 10

#/***********************************************************/
#/*BASIC_INPUT = cb18os120_tsmc_max/nd02d1/A1
#BASIC_OUTPUT = cb18os120_tsmc_max/nd02d1/ZN*/

set DRIVING_CELL dffacs1

#/* DONT_USE_LIST = {   } */

#/*************operation cons**************/
#/*OP_WCASE = WCCOM;
#OP_BCASE = BCCOM;*/
set WIRE_LOAD "tsmcwire"
set LOGICLIB lec25dscc25_TT
#/*****************************/

#/* Sourcing the file that sets the Search path and the libraries(target,link) */

set sys_clk $clock_name

set netlist_file [format "%s%s"  [format "%s%s"  $SYN_DIR $design_name] ".vg"]
set svsim_file [format "%s%s%s" $SYN_DIR $design_name "_svsim.sv"]
set ddc_file [format "%s%s"  [format "%s%s"  $SYN_DIR $design_name] ".ddc"]
set rep_file [format "%s%s"  [format "%s%s"  $SYN_DIR $design_name] ".rep"]
set res_file [format "%s%s%s" $SYN_DIR $design_name ".res"]
set dc_shell_status [ set chk_file [format "%s%s"  [format "%s%s"  $SYN_DIR $design_name] ".chk"] ]

#/* if we didnt find errors at this point, run */
if {  $dc_shell_status != [list] } {
  current_design $design_name
  link
  set_wire_load_model -name $WIRE_LOAD -lib $LOGICLIB $design_name
  set_wire_load_mode top
  set_fix_multiple_port_nets -outputs -buffer_constants
  create_clock -period $CLK_PERIOD -name $sys_clk [find port $sys_clk]
  set_clock_uncertainty $CLK_UNCERTAINTY $sys_clk
  set_fix_hold $sys_clk
  group_path -from [all_inputs] -name input_grp
  group_path -to [all_outputs] -name output_grp
  set_driving_cell  -lib_cell $DRIVING_CELL [all_inputs]
  remove_driving_cell [find port $sys_clk]
  set_fanout_load $AVG_FANOUT_LOAD [all_outputs]
  set_load $AVG_LOAD [all_outputs]
  set_input_delay $AVG_INPUT_DELAY -clock $sys_clk [all_inputs]
  remove_input_delay -clock $sys_clk [find port $sys_clk]
  set_output_delay $AVG_OUTPUT_DELAY -clock $sys_clk [all_outputs]
  set_dont_touch $reset_name
  set_resistance 0 $reset_name
  set_drive 0 $reset_name
  set_critical_range $CRIT_RANGE [current_design]
  set_max_delay $CLK_PERIOD [all_outputs]
  set MAX_FANOUT $MAX_FANOUT
  set MAX_TRANSITION $MAX_TRANSITION
  uniquify
  ungroup -all -flatten
  redirect $chk_file { check_design }
  compile -map_effort medium
  write -hier -format verilog -output $netlist_file $design_name
  write -hier -format ddc -output $ddc_file $design_name
  write -format svsim -output $svsim_file $design_name
  redirect $rep_file { report_design -nosplit }
  redirect -append $rep_file { report_area }
  redirect -append $rep_file { report_timing -max_paths 2 -input_pins -nets -transition_time -nosplit }
  redirect -append $rep_file { report_constraint -max_delay -verbose -nosplit }
  redirect $res_file { report_resources -hier }
  remove_design -all
  read_file -format verilog $netlist_file
  current_design $design_name
  redirect -append $rep_file { report_reference -nosplit }
  quit
} else {
  quit
}


