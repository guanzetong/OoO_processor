# Begin_DVE_Session_Save_Info
# DVE full session
<<<<<<< HEAD
# Saved on Fri Mar 25 17:11:54 2022
=======
# Saved on Sat Mar 26 21:07:16 2022
>>>>>>> ROB
# Designs open: 1
#   Sim: simv
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
<<<<<<< HEAD
#   Source.1: RS_tb.dut.COD_inst
#   Wave.1: 15 signals
#   Group count = 2
#   Group Group1 signal count = 6
=======
#   Source.1: ROB_tb
#   Wave.1: 43 signals
#   Group count = 1
#   Group dut signal count = 43
>>>>>>> ROB
# End_DVE_Session_Save_Info

# DVE version: R-2020.12-SP2-1_Full64
# DVE build date: Jul 18 2021 21:21:42


#<Session mode="Full" path="/afs/umich.edu/user/z/t/ztguan/group6w22/session.inter.vpd.tcl" type="Debug">

gui_set_loading_session_type Post
gui_continuetime_set

# Close design
if { [gui_sim_state -check active] } {
    gui_sim_terminate
}
gui_close_db -all
gui_expr_clear_all

# Close all windows
gui_close_window -type Console
gui_close_window -type Wave
gui_close_window -type Source
gui_close_window -type Schematic
gui_close_window -type Data
gui_close_window -type DriverLoad
gui_close_window -type List
gui_close_window -type Memory
gui_close_window -type HSPane
gui_close_window -type DLPane
gui_close_window -type Assertion
gui_close_window -type CovHier
gui_close_window -type CoverageTable
gui_close_window -type CoverageMap
gui_close_window -type CovDetail
gui_close_window -type Local
gui_close_window -type Stack
gui_close_window -type Watch
gui_close_window -type Group
gui_close_window -type Transaction



# Application preferences
gui_set_pref_value -key app_default_font -value {Helvetica,10,-1,5,50,0,0,0,0,0}
gui_src_preferences -tabstop 8 -maxbits 24 -windownumber 1
#<WindowLayout>

# DVE top-level session


# Create and position top-level window: TopLevel.1

if {![gui_exist_window -window TopLevel.1]} {
    set TopLevel.1 [ gui_create_window -type TopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set TopLevel.1 TopLevel.1
}
<<<<<<< HEAD
gui_show_window -window ${TopLevel.1} -show_state normal -rect {{1 112} {1294 780}}
=======
gui_show_window -window ${TopLevel.1} -show_state normal -rect {{184 153} {1723 954}}
>>>>>>> ROB

# ToolBar settings
gui_set_toolbar_attributes -toolbar {TimeOperations} -dock_state top
gui_set_toolbar_attributes -toolbar {TimeOperations} -offset 0
gui_show_toolbar -toolbar {TimeOperations}
gui_hide_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_hide_toolbar -toolbar {CopyPaste}
gui_set_toolbar_attributes -toolbar {&Trace} -dock_state top
gui_set_toolbar_attributes -toolbar {&Trace} -offset 0
gui_show_toolbar -toolbar {&Trace}
gui_hide_toolbar -toolbar {TraceInstance}
gui_hide_toolbar -toolbar {BackTrace}
gui_set_toolbar_attributes -toolbar {&Scope} -dock_state top
gui_set_toolbar_attributes -toolbar {&Scope} -offset 0
gui_show_toolbar -toolbar {&Scope}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Signal} -dock_state top
gui_set_toolbar_attributes -toolbar {Signal} -offset 0
gui_show_toolbar -toolbar {Signal}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}
gui_set_toolbar_attributes -toolbar {Grid} -dock_state top
gui_set_toolbar_attributes -toolbar {Grid} -offset 0
gui_show_toolbar -toolbar {Grid}
gui_set_toolbar_attributes -toolbar {Simulator} -dock_state top
gui_set_toolbar_attributes -toolbar {Simulator} -offset 0
gui_show_toolbar -toolbar {Simulator}
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -dock_state top
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -offset 0
gui_show_toolbar -toolbar {Interactive Rewind}
gui_set_toolbar_attributes -toolbar {Testbench} -dock_state top
gui_set_toolbar_attributes -toolbar {Testbench} -offset 0
gui_show_toolbar -toolbar {Testbench}

# End ToolBar settings

# Docked window settings
<<<<<<< HEAD
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 262]
=======
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 251]
>>>>>>> ROB
catch { set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier] }
catch { set Stack.1 [gui_share_window -id ${HSPane.1} -type Stack -silent] }
catch { set Class.1 [gui_share_window -id ${HSPane.1} -type Class -silent] }
catch { set Object.1 [gui_share_window -id ${HSPane.1} -type Object -silent] }
<<<<<<< HEAD
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 262
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 261} {height 390} {dock_state left} {dock_on_new_line true} {child_hier_colhier 193} {child_hier_coltype 83} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 372]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
catch { set Local.1 [gui_share_window -id ${DLPane.1} -type Local -silent] }
catch { set Member.1 [gui_share_window -id ${DLPane.1} -type Member -silent] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 372
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 444
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 371} {height 390} {dock_state left} {dock_on_new_line true} {child_data_colvariable 196} {child_data_colvalue 103} {child_data_coltype 101} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 126]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value -1
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 126
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 271} {height 179} {dock_state bottom} {dock_on_new_line true}}
set DriverLoad.1 [gui_create_window -type DriverLoad -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line false -dock_extent 180]
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_width -value_type integer -value 150
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_height -value_type integer -value 180
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DriverLoad.1} {{left 0} {top 0} {width 1021} {height 179} {dock_state bottom} {dock_on_new_line false}}
=======
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 251
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 250} {height 529} {dock_state left} {dock_on_new_line true} {child_hier_colhier 193} {child_hier_coltype 83} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 361]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
catch { set Local.1 [gui_share_window -id ${DLPane.1} -type Local -silent] }
catch { set Member.1 [gui_share_window -id ${DLPane.1} -type Member -silent] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 361
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 529
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 360} {height 529} {dock_state left} {dock_on_new_line true} {child_data_colvariable 196} {child_data_colvalue 103} {child_data_coltype 101} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 174]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value 1540
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 174
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 1539} {height 173} {dock_state bottom} {dock_on_new_line true}}
>>>>>>> ROB
#### Start - Readjusting docked view's offset / size
set dockAreaList { top left right bottom }
foreach dockArea $dockAreaList {
  set viewList [gui_ekki_get_window_ids -active_parent -dock_area $dockArea]
  foreach view $viewList {
      if {[lsearch -exact [gui_get_window_pref_keys -window $view] dock_width] != -1} {
        set dockWidth [gui_get_window_pref_value -window $view -key dock_width]
        set dockHeight [gui_get_window_pref_value -window $view -key dock_height]
        set offset [gui_get_window_pref_value -window $view -key dock_offset]
        if { [string equal "top" $dockArea] || [string equal "bottom" $dockArea]} {
          gui_set_window_attributes -window $view -dock_offset $offset -width $dockWidth
        } else {
          gui_set_window_attributes -window $view -dock_offset $offset -height $dockHeight
        }
      }
  }
}
#### End - Readjusting docked view's offset / size
gui_sync_global -id ${TopLevel.1} -option true

# MDI window settings
set Source.1 [gui_create_window -type {Source}  -parent ${TopLevel.1}]
gui_show_window -window ${Source.1} -show_state maximized
gui_update_layout -id ${Source.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false}}

# End MDI window settings


# Create and position top-level window: TopLevel.2

if {![gui_exist_window -window TopLevel.2]} {
    set TopLevel.2 [ gui_create_window -type TopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set TopLevel.2 TopLevel.2
}
<<<<<<< HEAD
gui_show_window -window ${TopLevel.2} -show_state normal -rect {{254 296} {1720 1007}}
=======
gui_show_window -window ${TopLevel.2} -show_state maximized -rect {{1 38} {1920 990}}
>>>>>>> ROB

# ToolBar settings
gui_set_toolbar_attributes -toolbar {TimeOperations} -dock_state top
gui_set_toolbar_attributes -toolbar {TimeOperations} -offset 0
gui_show_toolbar -toolbar {TimeOperations}
gui_hide_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_hide_toolbar -toolbar {CopyPaste}
gui_set_toolbar_attributes -toolbar {&Trace} -dock_state top
gui_set_toolbar_attributes -toolbar {&Trace} -offset 0
gui_show_toolbar -toolbar {&Trace}
gui_hide_toolbar -toolbar {TraceInstance}
gui_hide_toolbar -toolbar {BackTrace}
gui_set_toolbar_attributes -toolbar {&Scope} -dock_state top
gui_set_toolbar_attributes -toolbar {&Scope} -offset 0
gui_show_toolbar -toolbar {&Scope}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Signal} -dock_state top
gui_set_toolbar_attributes -toolbar {Signal} -offset 0
gui_show_toolbar -toolbar {Signal}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}
gui_set_toolbar_attributes -toolbar {Grid} -dock_state top
gui_set_toolbar_attributes -toolbar {Grid} -offset 0
gui_show_toolbar -toolbar {Grid}
gui_set_toolbar_attributes -toolbar {Simulator} -dock_state top
gui_set_toolbar_attributes -toolbar {Simulator} -offset 0
gui_show_toolbar -toolbar {Simulator}
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -dock_state top
gui_set_toolbar_attributes -toolbar {Interactive Rewind} -offset 0
gui_show_toolbar -toolbar {Interactive Rewind}
gui_set_toolbar_attributes -toolbar {Testbench} -dock_state top
gui_set_toolbar_attributes -toolbar {Testbench} -offset 0
gui_show_toolbar -toolbar {Testbench}

# End ToolBar settings

# Docked window settings
gui_sync_global -id ${TopLevel.2} -option true

# MDI window settings
set Wave.1 [gui_create_window -type {Wave}  -parent ${TopLevel.2}]
gui_show_window -window ${Wave.1} -show_state maximized
<<<<<<< HEAD
gui_update_layout -id ${Wave.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {child_wave_left 425} {child_wave_right 1036} {child_wave_colname 210} {child_wave_colvalue 211} {child_wave_col1 0} {child_wave_col2 1}}
=======
gui_update_layout -id ${Wave.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {child_wave_left 557} {child_wave_right 1357} {child_wave_colname 276} {child_wave_colvalue 276} {child_wave_col1 0} {child_wave_col2 1}}
>>>>>>> ROB

# End MDI window settings

gui_set_env TOPLEVELS::TARGET_FRAME(Source) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Schematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(PathSchematic) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(Wave) none
gui_set_env TOPLEVELS::TARGET_FRAME(List) none
gui_set_env TOPLEVELS::TARGET_FRAME(Memory) ${TopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(DriverLoad) none
gui_update_statusbar_target_frame ${TopLevel.1}
gui_update_statusbar_target_frame ${TopLevel.2}

#</WindowLayout>

#<Database>

# DVE Open design session: 

if { [llength [lindex [gui_get_db -design Sim] 0]] == 0 } {
<<<<<<< HEAD
gui_set_env SIMSETUP::SIMARGS {{ -ucligui}}
gui_set_env SIMSETUP::SIMEXE {simv}
=======
gui_set_env SIMSETUP::SIMARGS {{}}
gui_set_env SIMSETUP::SIMEXE {./simv}
>>>>>>> ROB
gui_set_env SIMSETUP::ALLOW_POLL {0}
if { ![gui_is_db_opened -db {simv}] } {
gui_sim_run Ucli -exe simv -args { -ucligui} -dir ../group6w22 -nosource
}
}
if { ![gui_sim_state -check active] } {error "Simulator did not start correctly" error}
<<<<<<< HEAD
gui_set_precision 1s
gui_set_time_units 1s
=======
gui_set_precision 100ps
gui_set_time_units 100ps
>>>>>>> ROB
#</Database>

# DVE Global setting session: 


# Global: Breakpoints

# Global: Bus

# Global: Expressions

# Global: Signal Time Shift

# Global: Signal Compare

# Global: Signal Groups
<<<<<<< HEAD


set _session_group_1 Group1
gui_sg_create "$_session_group_1"
set Group1 "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { RS_tb.dut.cod RS_tb.dut.is_ready RS_tb.dut.is_ready_cod RS_tb.dut.is_entry_idx RS_tb.dut.is_entry_idx_cod }
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.is_ready}
gui_set_radix -radix {unsigned} -signals {Sim:RS_tb.dut.is_ready}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.is_ready_cod}
gui_set_radix -radix {unsigned} -signals {Sim:RS_tb.dut.is_ready_cod}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.is_entry_idx}
gui_set_radix -radix {unsigned} -signals {Sim:RS_tb.dut.is_entry_idx}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.is_entry_idx_cod}
gui_set_radix -radix {unsigned} -signals {Sim:RS_tb.dut.is_entry_idx_cod}

set _session_group_2 $_session_group_1|
append _session_group_2 COD_inst
gui_sg_create "$_session_group_2"
set Group1|COD_inst "$_session_group_2"

gui_sg_addsignal -group "$_session_group_2" { RS_tb.dut.COD_inst.C_SUM_WIDTH RS_tb.dut.COD_inst.C_ADDER_IN_NUM RS_tb.dut.COD_inst.sum RS_tb.dut.COD_inst.C_DP_NUM_WDITH RS_tb.dut.COD_inst.C_RS_ENTRY_NUM RS_tb.dut.COD_inst.rs_idx_i RS_tb.dut.COD_inst.cod_o RS_tb.dut.COD_inst.valid_i RS_tb.dut.COD_inst.C_RS_IDX_WIDTH RS_tb.dut.COD_inst.C_DP_NUM }
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.C_SUM_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:RS_tb.dut.COD_inst.C_SUM_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.C_ADDER_IN_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:RS_tb.dut.COD_inst.C_ADDER_IN_NUM}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.sum}
gui_set_radix -radix {unsigned} -signals {Sim:RS_tb.dut.COD_inst.sum}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.C_DP_NUM_WDITH}
gui_set_radix -radix {twosComplement} -signals {Sim:RS_tb.dut.COD_inst.C_DP_NUM_WDITH}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.C_RS_ENTRY_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:RS_tb.dut.COD_inst.C_RS_ENTRY_NUM}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.rs_idx_i}
gui_set_radix -radix {unsigned} -signals {Sim:RS_tb.dut.COD_inst.rs_idx_i}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.cod_o}
gui_set_radix -radix {unsigned} -signals {Sim:RS_tb.dut.COD_inst.cod_o}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.valid_i}
gui_set_radix -radix {unsigned} -signals {Sim:RS_tb.dut.COD_inst.valid_i}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.C_RS_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:RS_tb.dut.COD_inst.C_RS_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:RS_tb.dut.COD_inst.C_DP_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:RS_tb.dut.COD_inst.C_DP_NUM}

# Global: Highlighting
gui_highlight_signals -color #00ff00 {{RS_tb.dut.COD_inst.sum[3:0]}}
=======
gui_load_child_values {ROB_tb.dut}


set _session_group_1 dut
gui_sg_create "$_session_group_1"
set dut "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { ROB_tb.dut.rt_window ROB_tb.dut.cdb_i ROB_tb.dut.C_ROB_IDX_WIDTH ROB_tb.dut.rt_valid ROB_tb.dut.C_TAG_IDX_WIDTH ROB_tb.dut.br_mispredict ROB_tb.dut.C_PHY_REG_NUM ROB_tb.dut.rob_array ROB_tb.dut.head ROB_tb.dut.C_DP_NUM_WIDTH ROB_tb.dut.cp_idx ROB_tb.dut.rt_num ROB_tb.dut.head_rollover ROB_tb.dut.dp_num ROB_tb.dut.rob_amt_o ROB_tb.dut.C_DP_IDX_WIDTH ROB_tb.dut.C_CDB_NUM ROB_tb.dut.rob_fl_o ROB_tb.dut.tail_rollover ROB_tb.dut.rt_sel ROB_tb.dut.next_head ROB_tb.dut.C_ROB_ENTRY_NUM ROB_tb.dut.dp_sel ROB_tb.dut.br_mis_o ROB_tb.dut.tail ROB_tb.dut.rst_i ROB_tb.dut.avail_num ROB_tb.dut.dp_rob_i ROB_tb.dut.C_RT_NUM ROB_tb.dut.rob_dp_o ROB_tb.dut.C_ARCH_REG_NUM ROB_tb.dut.C_ARCH_REG_IDX_WIDTH ROB_tb.dut.C_RT_NUM_WIDTH ROB_tb.dut.C_DP_NUM ROB_tb.dut.C_CDB_IDX_WIDTH {ROB_tb.dut.$unit} ROB_tb.dut.head_sel ROB_tb.dut.C_RT_IDX_WIDTH ROB_tb.dut.cp_sel ROB_tb.dut.exception_i ROB_tb.dut.next_tail ROB_tb.dut.clk_i ROB_tb.dut.C_ROB_NUM_WIDTH }
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_ROB_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_ROB_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_TAG_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_TAG_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_PHY_REG_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_PHY_REG_NUM}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_DP_NUM_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_DP_NUM_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_DP_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_DP_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_CDB_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_CDB_NUM}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_ROB_ENTRY_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_ROB_ENTRY_NUM}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_RT_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_RT_NUM}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_ARCH_REG_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_ARCH_REG_NUM}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_ARCH_REG_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_ARCH_REG_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_RT_NUM_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_RT_NUM_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_DP_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_DP_NUM}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_CDB_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_CDB_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_RT_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_RT_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:ROB_tb.dut.C_ROB_NUM_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:ROB_tb.dut.C_ROB_NUM_WIDTH}

# Global: Highlighting
>>>>>>> ROB

# Global: Stack
gui_change_stack_mode -mode list

# Post database loading setting...

# Restore C1 time
<<<<<<< HEAD
gui_set_time -C1_only 1060
=======
gui_set_time -C1_only 8460
>>>>>>> ROB



# Save global setting...

# Wave/List view global setting
gui_cov_show_value -switch false

# Close all empty TopLevel windows
foreach __top [gui_ekki_get_window_ids -type TopLevel] {
    if { [llength [gui_ekki_get_window_ids -parent $__top]] == 0} {
        gui_close_window -window $__top
    }
}
gui_set_loading_session_type noSession
# DVE View/pane content session: 


# Hier 'Hier.1'
gui_show_window -window ${Hier.1}
gui_list_set_filter -id ${Hier.1} -list { {Package 1} {All 0} {Process 1} {VirtPowSwitch 0} {UnnamedProcess 1} {UDP 0} {Function 1} {Block 1} {SrsnAndSpaCell 0} {OVA Unit 1} {LeafScCell 1} {LeafVlgCell 1} {Interface 1} {LeafVhdCell 1} {$unit 1} {NamedBlock 1} {Task 1} {VlgPackage 1} {ClassDef 1} {VirtIsoCell 0} }
gui_list_set_filter -id ${Hier.1} -text {*}
gui_hier_list_init -id ${Hier.1}
gui_change_design -id ${Hier.1} -design Sim
<<<<<<< HEAD
catch {gui_list_expand -id ${Hier.1} RS_tb}
catch {gui_list_expand -id ${Hier.1} RS_tb.dut}
catch {gui_list_select -id ${Hier.1} {RS_tb.dut.COD_inst}}
gui_view_scroll -id ${Hier.1} -vertical -set 40
=======
catch {gui_list_expand -id ${Hier.1} ROB_tb}
catch {gui_list_select -id ${Hier.1} {ROB_tb.dut}}
gui_view_scroll -id ${Hier.1} -vertical -set 0
>>>>>>> ROB
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Class 'Class.1'
gui_list_set_filter -id ${Class.1} -list { {OVM 1} {VMM 1} {All 1} {Object 1} {UVM 1} {RVM 1} }
gui_list_set_filter -id ${Class.1} -text {*}
gui_change_design -id ${Class.1} -design Sim
<<<<<<< HEAD
# Warning: Class view not found.
=======
>>>>>>> ROB

# Member 'Member.1'
gui_list_set_filter -id ${Member.1} -list { {InternalMember 0} {RandMember 1} {All 0} {BaseMember 0} {PrivateMember 1} {LibBaseMember 0} {AutomaticMember 1} {VirtualMember 1} {PublicMember 1} {ProtectedMember 1} {OverRiddenMember 0} {InterfaceClassMember 1} {StaticMember 1} }
gui_list_set_filter -id ${Member.1} -text {*}

# Data 'Data.1'
gui_list_set_filter -id ${Data.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {LowPower 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Data.1} -text {*}
<<<<<<< HEAD
gui_list_show_data -id ${Data.1} {RS_tb.dut.COD_inst}
gui_list_expand -id ${Data.1} {RS_tb.dut.COD_inst.$unit}
gui_show_window -window ${Data.1}
catch { gui_list_select -id ${Data.1} {_vcs_unit__1577238712.RV32_Jimm_width_gp _vcs_unit__1577238712.RV32_Jimm_width_gp }}
gui_view_scroll -id ${Data.1} -vertical -set 0
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 40
=======
gui_list_show_data -id ${Data.1} {ROB_tb.dut}
gui_view_scroll -id ${Data.1} -vertical -set 0
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 0
>>>>>>> ROB
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
<<<<<<< HEAD
gui_open_source -id ${Source.1}  -replace -active RS_tb.dut.COD_inst verilog/COD.sv
gui_src_value_annotate -id ${Source.1} -switch true
gui_set_env TOGGLE::VALUEANNOTATE 1
gui_view_scroll -id ${Source.1} -vertical -set 840
gui_src_set_reusable -id ${Source.1}
=======
gui_open_source -id ${Source.1}  -replace -active ROB_tb testbench/ROB_tb_2.sv
gui_src_value_annotate -id ${Source.1} -switch true
gui_set_env TOGGLE::VALUEANNOTATE 1
gui_view_scroll -id ${Source.1} -vertical -set 2070
gui_src_set_reusable -id ${Source.1}
# Warning: Class view not found.
>>>>>>> ROB

# View 'Wave.1'
gui_wv_sync -id ${Wave.1} -switch false
set groupExD [gui_get_pref_value -category Wave -key exclusiveSG]
gui_set_pref_value -category Wave -key exclusiveSG -value {false}
set origWaveHeight [gui_get_pref_value -category Wave -key waveRowHeight]
gui_list_set_height -id Wave -height 25
set origGroupCreationState [gui_list_create_group_when_add -wave]
gui_list_create_group_when_add -wave -disable
gui_marker_set_ref -id ${Wave.1}  C1
<<<<<<< HEAD
gui_wv_zoom_timerange -id ${Wave.1} 1026 1070
gui_list_add_group -id ${Wave.1} -after {New Group} {Group1}
gui_list_add_group -id ${Wave.1}  -after Group1 {Group1|COD_inst}
gui_list_expand -id ${Wave.1} RS_tb.dut.COD_inst.rs_idx_i
gui_list_expand -id ${Wave.1} RS_tb.dut.COD_inst.cod_o
gui_list_expand -id ${Wave.1} RS_tb.dut.COD_inst.valid_i
gui_list_expand -id ${Wave.1} RS_tb.dut.is_entry_idx
gui_list_expand -id ${Wave.1} RS_tb.dut.is_entry_idx_cod
gui_list_select -id ${Wave.1} {RS_tb.dut.is_entry_idx_cod }
gui_set_radix -radix unsigned -signal {{RS_tb.dut.COD_inst.rs_idx_i[1]}}
gui_set_radix -radix decimal -signal {{RS_tb.dut.COD_inst.rs_idx_i[1]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.COD_inst.rs_idx_i[0]}}
gui_set_radix -radix decimal -signal {{RS_tb.dut.COD_inst.rs_idx_i[0]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.is_entry_idx[1]}}
gui_set_radix -radix decimal -signal {{RS_tb.dut.is_entry_idx[1]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.is_entry_idx[1]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.is_entry_idx[0]}}
gui_set_radix -radix decimal -signal {{RS_tb.dut.is_entry_idx[0]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.is_entry_idx[0]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.is_entry_idx_cod[1]}}
gui_set_radix -radix decimal -signal {{RS_tb.dut.is_entry_idx_cod[1]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.is_entry_idx_cod[1]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.is_entry_idx_cod[0]}}
gui_set_radix -radix decimal -signal {{RS_tb.dut.is_entry_idx_cod[0]}}
gui_set_radix -radix unsigned -signal {{RS_tb.dut.is_entry_idx_cod[0]}}
=======
gui_wv_zoom_timerange -id ${Wave.1} 4229 10435
gui_list_add_group -id ${Wave.1} -after {New Group} {dut}
gui_list_expand -id ${Wave.1} ROB_tb.dut.rt_window
gui_list_expand -id ${Wave.1} ROB_tb.dut.cdb_i
gui_list_expand -id ${Wave.1} {ROB_tb.dut.cdb_i[0]}
gui_list_expand -id ${Wave.1} ROB_tb.dut.rob_array
gui_list_expand -id ${Wave.1} {ROB_tb.dut.rob_array[31]}
gui_list_expand -id ${Wave.1} {ROB_tb.dut.rob_array[1]}
gui_list_expand -id ${Wave.1} ROB_tb.dut.rt_sel
gui_list_expand -id ${Wave.1} ROB_tb.dut.head_sel
gui_list_select -id ${Wave.1} {{ROB_tb.dut.rt_window[1]} }
>>>>>>> ROB
gui_seek_criteria -id ${Wave.1} {Any Edge}



gui_set_env TOGGLE::DEFAULT_WAVE_WINDOW ${Wave.1}
gui_set_pref_value -category Wave -key exclusiveSG -value $groupExD
gui_list_set_height -id Wave -height $origWaveHeight
if {$origGroupCreationState} {
	gui_list_create_group_when_add -wave -enable
}
if { $groupExD } {
 gui_msg_report -code DVWW028
}
gui_list_set_filter -id ${Wave.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Wave.1} -text {*}
<<<<<<< HEAD
gui_list_set_insertion_bar  -id ${Wave.1} -group Group1|COD_inst  -item {RS_tb.dut.COD_inst.C_ADDER_IN_NUM[31:0]} -position below

gui_marker_move -id ${Wave.1} {C1} 1060
gui_view_scroll -id ${Wave.1} -vertical -set 222
gui_show_grid -id ${Wave.1} -enable false

# DriverLoad 'DriverLoad.1'
gui_get_drivers -session -id ${DriverLoad.1} -signal {RS_tb.dut.COD_inst.cod_o[2:0]} -time 110 -starttime 113
=======
gui_list_set_insertion_bar  -id ${Wave.1} -group dut  -position in

gui_marker_move -id ${Wave.1} {C1} 8460
gui_view_scroll -id ${Wave.1} -vertical -set 1800
gui_show_grid -id ${Wave.1} -enable false
>>>>>>> ROB
# Restore toplevel window zorder
# The toplevel window could be closed if it has no view/pane
if {[gui_exist_window -window ${TopLevel.1}]} {
	gui_set_active_window -window ${TopLevel.1}
	gui_set_active_window -window ${Source.1}
<<<<<<< HEAD
	gui_set_active_window -window ${DriverLoad.1}
=======
	gui_set_active_window -window ${HSPane.1}
>>>>>>> ROB
}
if {[gui_exist_window -window ${TopLevel.2}]} {
	gui_set_active_window -window ${TopLevel.2}
	gui_set_active_window -window ${Wave.1}
}
#</Session>

