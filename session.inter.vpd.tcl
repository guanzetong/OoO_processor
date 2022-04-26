# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Thu Apr 21 17:43:43 2022
# Designs open: 1
#   Sim: simv
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
#   Source.1: pipeline_ss_smt_tb
#   Wave.1: 85 signals
#   Group count = 3
#   Group genblk4[1].LSQ_inst signal count = 40
#   Group FU_inst signal count = 28
#   Group BC_inst signal count = 17
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
gui_show_window -window ${TopLevel.1} -show_state normal -rect {{100 101} {1618 881}}

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
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 262]
catch { set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier] }
catch { set Stack.1 [gui_share_window -id ${HSPane.1} -type Stack -silent] }
catch { set Class.1 [gui_share_window -id ${HSPane.1} -type Class -silent] }
catch { set Object.1 [gui_share_window -id ${HSPane.1} -type Object -silent] }
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 262
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 261} {height 512} {dock_state left} {dock_on_new_line true} {child_hier_colhier 242} {child_hier_coltype 86} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 231]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
catch { set Local.1 [gui_share_window -id ${DLPane.1} -type Local -silent] }
catch { set Member.1 [gui_share_window -id ${DLPane.1} -type Member -silent] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 231
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 512
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 230} {height 512} {dock_state left} {dock_on_new_line true} {child_data_colvariable 196} {child_data_colvalue 103} {child_data_coltype 101} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 170]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value 1519
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 170
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 1518} {height 169} {dock_state bottom} {dock_on_new_line true}}
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
gui_show_window -window ${TopLevel.2} -show_state normal -rect {{11 78} {1727 978}}

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
gui_update_layout -id ${Wave.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {child_wave_left 498} {child_wave_right 1213} {child_wave_colname 247} {child_wave_colvalue 247} {child_wave_col1 0} {child_wave_col2 1}}

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
gui_set_env SIMSETUP::SIMARGS {{}}
gui_set_env SIMSETUP::SIMEXE {./simv}
gui_set_env SIMSETUP::ALLOW_POLL {0}
if { ![gui_is_db_opened -db {simv}] } {
gui_sim_run Ucli -exe simv -args { -ucligui} -dir ../group6w22 -nosource
}
}
if { ![gui_sim_state -check active] } {error "Simulator did not start correctly" error}
gui_set_precision 1s
gui_set_time_units 1s
#</Database>

# DVE Global setting session: 


# Global: Breakpoints

# Global: Bus

# Global: Expressions

# Global: Signal Time Shift

# Global: Signal Compare

# Global: Signal Groups
gui_load_child_values {pipeline_ss_smt_tb.dut.FU_inst}
gui_load_child_values {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst}
gui_load_child_values {pipeline_ss_smt_tb.dut.BC_inst}


set _session_group_1 {genblk4[1].LSQ_inst}
gui_sg_create "$_session_group_1"
set {genblk4[1].LSQ_inst} "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.$unit} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_DP_NUM} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_DP_NUM_WIDTH} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LOAD_NUM} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_ENTRY_NUM} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_IDX_WIDTH} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_IN_NUM} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_ROB_IDX_WIDTH} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_RT_NUM} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_STORE_NUM} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_TAG_IDX_WIDTH} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_THREAD_IDX_WIDTH} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_THREAD_NUM} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.bc_lsq_entry} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.bc_lsq_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.br_mis_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.clk_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.dp_lsq_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.dp_sel} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.fu_lsq_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.head} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_array} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_array_mon_o} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_bc_o} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_dp_o} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_entry_bc} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_entry_mem} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_head_mon_o} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_mem_o} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.lsq_tail_mon_o} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.mem_enable_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.mem_grant} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.mem_lsq_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.rob_lsq_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.rob_retire} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.rollback} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.rst_i} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.rt_sel} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.tail} {pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.thread_idx_i} }
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_DP_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_DP_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_DP_NUM_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_DP_NUM_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LOAD_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LOAD_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_ENTRY_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_ENTRY_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_IN_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_LSQ_IN_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_ROB_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_ROB_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_RT_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_RT_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_STORE_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_STORE_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_TAG_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_TAG_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_THREAD_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_THREAD_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_THREAD_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_ss_smt_tb.dut.genblk4[1].LSQ_inst.C_THREAD_NUM}}

set _session_group_2 FU_inst
gui_sg_create "$_session_group_2"
set FU_inst "$_session_group_2"

gui_sg_addsignal -group "$_session_group_2" { {pipeline_ss_smt_tb.dut.FU_inst.$unit} pipeline_ss_smt_tb.dut.FU_inst.C_ALU_BASE pipeline_ss_smt_tb.dut.FU_inst.C_ALU_NUM pipeline_ss_smt_tb.dut.FU_inst.C_BR_BASE pipeline_ss_smt_tb.dut.FU_inst.C_BR_NUM pipeline_ss_smt_tb.dut.FU_inst.C_FU_NUM pipeline_ss_smt_tb.dut.FU_inst.C_LOAD_BASE pipeline_ss_smt_tb.dut.FU_inst.C_LOAD_NUM pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_IN_NUM pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_LOAD_BASE pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_OUT_NUM pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_STORE_BASE pipeline_ss_smt_tb.dut.FU_inst.C_MULT_BASE pipeline_ss_smt_tb.dut.FU_inst.C_MULT_NUM pipeline_ss_smt_tb.dut.FU_inst.C_STORE_BASE pipeline_ss_smt_tb.dut.FU_inst.C_STORE_NUM pipeline_ss_smt_tb.dut.FU_inst.C_THREAD_NUM pipeline_ss_smt_tb.dut.FU_inst.bc_fu_i pipeline_ss_smt_tb.dut.FU_inst.bc_lsq_o pipeline_ss_smt_tb.dut.FU_inst.br_mis_i pipeline_ss_smt_tb.dut.FU_inst.clk_i pipeline_ss_smt_tb.dut.FU_inst.exception_i pipeline_ss_smt_tb.dut.FU_inst.fu_bc_o pipeline_ss_smt_tb.dut.FU_inst.fu_ib_o pipeline_ss_smt_tb.dut.FU_inst.fu_lsq_o pipeline_ss_smt_tb.dut.FU_inst.ib_fu_i pipeline_ss_smt_tb.dut.FU_inst.lsq_bc_i pipeline_ss_smt_tb.dut.FU_inst.rst_i }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_ALU_BASE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_ALU_BASE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_ALU_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_ALU_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_BR_BASE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_BR_BASE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_BR_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_BR_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_FU_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_FU_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LOAD_BASE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LOAD_BASE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LOAD_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LOAD_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_IN_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_IN_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_LOAD_BASE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_LOAD_BASE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_OUT_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_OUT_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_STORE_BASE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_LSQ_STORE_BASE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_MULT_BASE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_MULT_BASE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_MULT_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_MULT_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_STORE_BASE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_STORE_BASE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_STORE_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_STORE_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_THREAD_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.FU_inst.C_THREAD_NUM}

set _session_group_3 BC_inst
gui_sg_create "$_session_group_3"
set BC_inst "$_session_group_3"

gui_sg_addsignal -group "$_session_group_3" { {pipeline_ss_smt_tb.dut.BC_inst.$unit} pipeline_ss_smt_tb.dut.BC_inst.C_CDB_NUM pipeline_ss_smt_tb.dut.BC_inst.C_FU_NUM pipeline_ss_smt_tb.dut.BC_inst.C_PE_OUT_WIDTH pipeline_ss_smt_tb.dut.BC_inst.bc_fu_o pipeline_ss_smt_tb.dut.BC_inst.bc_prf_o pipeline_ss_smt_tb.dut.BC_inst.broadcasted pipeline_ss_smt_tb.dut.BC_inst.cdb_o pipeline_ss_smt_tb.dut.BC_inst.clk_i pipeline_ss_smt_tb.dut.BC_inst.fu_bc_i pipeline_ss_smt_tb.dut.BC_inst.mask pipeline_ss_smt_tb.dut.BC_inst.mux_select_dec pipeline_ss_smt_tb.dut.BC_inst.mux_select_enc pipeline_ss_smt_tb.dut.BC_inst.mux_valid pipeline_ss_smt_tb.dut.BC_inst.queued pipeline_ss_smt_tb.dut.BC_inst.rst_i pipeline_ss_smt_tb.dut.BC_inst.valid }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.BC_inst.C_CDB_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.BC_inst.C_CDB_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.BC_inst.C_FU_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.BC_inst.C_FU_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.BC_inst.C_PE_OUT_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.BC_inst.C_PE_OUT_WIDTH}

# Global: Highlighting

# Global: Stack
gui_change_stack_mode -mode list

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 10090



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
catch {gui_list_expand -id ${Hier.1} pipeline_ss_smt_tb}
catch {gui_list_expand -id ${Hier.1} pipeline_ss_smt_tb.dut}
catch {gui_list_select -id ${Hier.1} {pipeline_ss_smt_tb.dut.BC_inst}}
gui_view_scroll -id ${Hier.1} -vertical -set 0
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Class 'Class.1'
gui_list_set_filter -id ${Class.1} -list { {OVM 1} {VMM 1} {All 1} {Object 1} {UVM 1} {RVM 1} }
gui_list_set_filter -id ${Class.1} -text {*}
gui_change_design -id ${Class.1} -design Sim

# Member 'Member.1'
gui_list_set_filter -id ${Member.1} -list { {InternalMember 0} {RandMember 1} {All 0} {BaseMember 0} {PrivateMember 1} {LibBaseMember 0} {AutomaticMember 1} {VirtualMember 1} {PublicMember 1} {ProtectedMember 1} {OverRiddenMember 0} {InterfaceClassMember 1} {StaticMember 1} }
gui_list_set_filter -id ${Member.1} -text {*}

# Data 'Data.1'
gui_list_set_filter -id ${Data.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {LowPower 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Data.1} -text {*}
gui_list_show_data -id ${Data.1} {pipeline_ss_smt_tb.dut.BC_inst}
gui_view_scroll -id ${Data.1} -vertical -set 0
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 0
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
gui_open_source -id ${Source.1}  -replace -active pipeline_ss_smt_tb testbench/pipeline_ss_smt_tb.sv
gui_src_value_annotate -id ${Source.1} -switch true
gui_set_env TOGGLE::VALUEANNOTATE 1
gui_view_scroll -id ${Source.1} -vertical -set 3525
gui_src_set_reusable -id ${Source.1}
# Warning: Class view not found.

# View 'Wave.1'
gui_wv_sync -id ${Wave.1} -switch false
set groupExD [gui_get_pref_value -category Wave -key exclusiveSG]
gui_set_pref_value -category Wave -key exclusiveSG -value {false}
set origWaveHeight [gui_get_pref_value -category Wave -key waveRowHeight]
gui_list_set_height -id Wave -height 25
set origGroupCreationState [gui_list_create_group_when_add -wave]
gui_list_create_group_when_add -wave -disable
gui_marker_set_ref -id ${Wave.1}  C1
gui_wv_zoom_timerange -id ${Wave.1} 9892 10289
gui_list_add_group -id ${Wave.1} -after {New Group} {{genblk4[1].LSQ_inst}}
gui_list_add_group -id ${Wave.1} -after {New Group} {FU_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {BC_inst}
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.FU_inst.bc_fu_i
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.FU_inst.bc_lsq_o
gui_list_select -id ${Wave.1} {{pipeline_ss_smt_tb.dut.FU_inst.bc_lsq_o[1]} }
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
gui_list_set_insertion_bar  -id ${Wave.1} -group BC_inst  -position in

gui_marker_move -id ${Wave.1} {C1} 10090
gui_view_scroll -id ${Wave.1} -vertical -set 1125
gui_show_grid -id ${Wave.1} -enable false
# Restore toplevel window zorder
# The toplevel window could be closed if it has no view/pane
if {[gui_exist_window -window ${TopLevel.1}]} {
	gui_set_active_window -window ${TopLevel.1}
	gui_set_active_window -window ${Source.1}
	gui_set_active_window -window ${HSPane.1}
}
if {[gui_exist_window -window ${TopLevel.2}]} {
	gui_set_active_window -window ${TopLevel.2}
	gui_set_active_window -window ${Wave.1}
}
#</Session>

