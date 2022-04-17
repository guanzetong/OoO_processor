# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Sat Apr 16 19:00:40 2022
# Designs open: 1
#   Sim: simv
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
#   Source.1: pipeline_dp_lsq_tb
#   Wave.1: 163 signals
#   Group count = 8
#   Group genblk4[0].LSQ_inst signal count = 37
#   Group LSQ_memory_switch_inst signal count = 16
#   Group LSQ_rr_arbiter_inst signal count = 13
#   Group MEM_SW_inst signal count = 13
#   Group DC_inst signal count = 17
#   Group DC_SW_inst signal count = 15
#   Group genblk1[3].LSQ_entry_ctrl_inst signal count = 32
#   Group genblk4[0].store_unit signal count = 20
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
gui_show_window -window ${TopLevel.1} -show_state normal -rect {{672 231} {1627 971}}

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
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 300]
catch { set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier] }
catch { set Stack.1 [gui_share_window -id ${HSPane.1} -type Stack -silent] }
catch { set Class.1 [gui_share_window -id ${HSPane.1} -type Class -silent] }
catch { set Object.1 [gui_share_window -id ${HSPane.1} -type Object -silent] }
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 300
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 299} {height 455} {dock_state left} {dock_on_new_line true} {child_hier_colhier 242} {child_hier_coltype 86} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 269]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
catch { set Local.1 [gui_share_window -id ${DLPane.1} -type Local -silent] }
catch { set Member.1 [gui_share_window -id ${DLPane.1} -type Member -silent] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 269
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 455
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 268} {height 455} {dock_state left} {dock_on_new_line true} {child_data_colvariable 196} {child_data_colvalue 103} {child_data_coltype 101} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 163]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value 958
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 163
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 955} {height 162} {dock_state bottom} {dock_on_new_line true}}
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
gui_show_window -window ${TopLevel.2} -show_state maximized -rect {{150 169} {1877 1076}}

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
gui_update_layout -id ${Wave.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {child_wave_left 756} {child_wave_right 966} {child_wave_colname 228} {child_wave_colvalue 523} {child_wave_col1 0} {child_wave_col2 1}}

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
gui_set_env SIMSETUP::SIMARGS {{ -ucligui}}
gui_set_env SIMSETUP::SIMEXE {simv}
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
gui_load_child_values {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst}
gui_load_child_values {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst}
gui_load_child_values {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst}
gui_load_child_values {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit}
gui_load_child_values {pipeline_dp_lsq_tb.dut.DC_inst}
gui_load_child_values {pipeline_dp_lsq_tb.dut.DC_SW_inst}
gui_load_child_values {pipeline_dp_lsq_tb.dut.MEM_SW_inst}
gui_load_child_values {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst}


set _session_group_1 {genblk4[0].LSQ_inst}
gui_sg_create "$_session_group_1"
set {genblk4[0].LSQ_inst} "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.$unit} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_DP_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_DP_NUM_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LOAD_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_ENTRY_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_IDX_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_IN_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_ROB_IDX_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_RT_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_STORE_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_TAG_IDX_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_THREAD_IDX_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_THREAD_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.bc_lsq_entry} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.bc_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.clk_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.dp_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.dp_sel} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.fu_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.head} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_array} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_array_mon_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_bc_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_dp_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_entry_bc} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_entry_mem} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_head_mon_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_mem_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.lsq_tail_mon_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.mem_enable_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.mem_grant} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.mem_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.rob_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.rst_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.rt_sel} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.tail} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.thread_idx_i} }
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_DP_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_DP_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_DP_NUM_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_DP_NUM_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LOAD_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LOAD_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_ENTRY_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_ENTRY_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_IN_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_LSQ_IN_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_ROB_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_ROB_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_RT_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_RT_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_STORE_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_STORE_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_TAG_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_TAG_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_THREAD_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_THREAD_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_THREAD_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.C_THREAD_NUM}}

set _session_group_2 LSQ_memory_switch_inst
gui_sg_create "$_session_group_2"
set LSQ_memory_switch_inst "$_session_group_2"

gui_sg_addsignal -group "$_session_group_2" { {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.$unit} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.C_LSQ_ENTRY_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.C_LSQ_IDX_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.arbiter_ack} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.arbiter_req} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.clk_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.grant_idx} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.grant_valid} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.load_req} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.lsq_entry_mem_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.lsq_mem_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.mem_enable_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.mem_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.memory_grant_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.rst_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.store_req} }
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.C_LSQ_ENTRY_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.C_LSQ_ENTRY_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.C_LSQ_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.C_LSQ_IDX_WIDTH}}

set _session_group_3 LSQ_rr_arbiter_inst
gui_sg_create "$_session_group_3"
set LSQ_rr_arbiter_inst "$_session_group_3"

gui_sg_addsignal -group "$_session_group_3" { {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.$unit} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.C_REQ_IDX_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.C_REQ_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.ack_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.clk_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.grant_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.grant_rank} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.next_top_idx} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.req_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.req_rank} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.rst_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.top_idx} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.valid_o} }
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.C_REQ_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.C_REQ_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.C_REQ_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.LSQ_memory_switch_inst.LSQ_rr_arbiter_inst.C_REQ_NUM}}

set _session_group_4 MEM_SW_inst
gui_sg_create "$_session_group_4"
set MEM_SW_inst "$_session_group_4"

gui_sg_addsignal -group "$_session_group_4" { {pipeline_dp_lsq_tb.dut.MEM_SW_inst.$unit} pipeline_dp_lsq_tb.dut.MEM_SW_inst.C_REQ_IDX_WIDTH pipeline_dp_lsq_tb.dut.MEM_SW_inst.C_REQ_NUM pipeline_dp_lsq_tb.dut.MEM_SW_inst.arbiter_ack pipeline_dp_lsq_tb.dut.MEM_SW_inst.arbiter_req pipeline_dp_lsq_tb.dut.MEM_SW_inst.clk_i pipeline_dp_lsq_tb.dut.MEM_SW_inst.grant_idx pipeline_dp_lsq_tb.dut.MEM_SW_inst.grant_valid pipeline_dp_lsq_tb.dut.MEM_SW_inst.mem2switch_i pipeline_dp_lsq_tb.dut.MEM_SW_inst.memory_grant_o pipeline_dp_lsq_tb.dut.MEM_SW_inst.req2mem_i pipeline_dp_lsq_tb.dut.MEM_SW_inst.rst_i pipeline_dp_lsq_tb.dut.MEM_SW_inst.switch2mem_o }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.MEM_SW_inst.C_REQ_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.MEM_SW_inst.C_REQ_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.MEM_SW_inst.C_REQ_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.MEM_SW_inst.C_REQ_NUM}

set _session_group_5 DC_inst
gui_sg_create "$_session_group_5"
set DC_inst "$_session_group_5"

gui_sg_addsignal -group "$_session_group_5" { {pipeline_dp_lsq_tb.dut.DC_inst.$unit} pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_BLOCK_SIZE pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SASS pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SET_NUM pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SIZE pipeline_dp_lsq_tb.dut.DC_inst.C_MSHR_ENTRY_NUM pipeline_dp_lsq_tb.dut.DC_inst.cache2mem_o pipeline_dp_lsq_tb.dut.DC_inst.cache2proc_o pipeline_dp_lsq_tb.dut.DC_inst.cache_array_mon_o pipeline_dp_lsq_tb.dut.DC_inst.cache_ctrl_mem pipeline_dp_lsq_tb.dut.DC_inst.cache_mem_ctrl pipeline_dp_lsq_tb.dut.DC_inst.clk_i pipeline_dp_lsq_tb.dut.DC_inst.mem2cache_i pipeline_dp_lsq_tb.dut.DC_inst.memory_enable_i pipeline_dp_lsq_tb.dut.DC_inst.mshr_array_mon_o pipeline_dp_lsq_tb.dut.DC_inst.proc2cache_i pipeline_dp_lsq_tb.dut.DC_inst.rst_i }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_BLOCK_SIZE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_BLOCK_SIZE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SASS}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SASS}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SET_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SET_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SIZE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_CACHE_SIZE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_MSHR_ENTRY_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_inst.C_MSHR_ENTRY_NUM}

set _session_group_6 DC_SW_inst
gui_sg_create "$_session_group_6"
set DC_SW_inst "$_session_group_6"

gui_sg_addsignal -group "$_session_group_6" { {pipeline_dp_lsq_tb.dut.DC_SW_inst.$unit} pipeline_dp_lsq_tb.dut.DC_SW_inst.C_THREAD_IDX_WIDTH pipeline_dp_lsq_tb.dut.DC_SW_inst.C_THREAD_NUM pipeline_dp_lsq_tb.dut.DC_SW_inst.arbiter_ack pipeline_dp_lsq_tb.dut.DC_SW_inst.arbiter_req pipeline_dp_lsq_tb.dut.DC_SW_inst.clk_i pipeline_dp_lsq_tb.dut.DC_SW_inst.dcache_grant_o pipeline_dp_lsq_tb.dut.DC_SW_inst.dcache_lsq_i pipeline_dp_lsq_tb.dut.DC_SW_inst.grant_idx pipeline_dp_lsq_tb.dut.DC_SW_inst.grant_valid pipeline_dp_lsq_tb.dut.DC_SW_inst.load_req pipeline_dp_lsq_tb.dut.DC_SW_inst.lsq_dcache_o pipeline_dp_lsq_tb.dut.DC_SW_inst.lsq_mem_i pipeline_dp_lsq_tb.dut.DC_SW_inst.rst_i pipeline_dp_lsq_tb.dut.DC_SW_inst.store_req }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_SW_inst.C_THREAD_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_SW_inst.C_THREAD_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_SW_inst.C_THREAD_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_dp_lsq_tb.dut.DC_SW_inst.C_THREAD_NUM}

set _session_group_7 {genblk1[3].LSQ_entry_ctrl_inst}
gui_sg_create "$_session_group_7"
set {genblk1[3].LSQ_entry_ctrl_inst} "$_session_group_7"

gui_sg_addsignal -group "$_session_group_7" { {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.$unit} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LOAD_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_ENTRY_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_IDX_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_IN_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_RT_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_STORE_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_THREAD_IDX_WIDTH} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_THREAD_NUM} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.bc_lsq_entry_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.clk_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.depend_flag} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.depend_idx} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.dp_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.dp_sel_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.fu_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.head_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.lsq_array_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.lsq_entry_bc_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.lsq_entry_mem_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.lsq_entry_o} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.lsq_idx_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.mem_grant_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.mem_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.next_lsq_entry} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.older_store_known} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.rob_lsq_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.rst_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.rt_sel_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.store_check} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.tail_i} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.thread_idx_i} }
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LOAD_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LOAD_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_ENTRY_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_ENTRY_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_IN_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_LSQ_IN_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_RT_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_RT_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_STORE_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_STORE_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_THREAD_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_THREAD_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_THREAD_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.C_THREAD_NUM}}

set _session_group_8 {genblk4[0].store_unit}
gui_sg_create "$_session_group_8"
set {genblk4[0].store_unit} "$_session_group_8"

gui_sg_addsignal -group "$_session_group_8" { {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.ex_start} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.fu_bc_o} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.opb_mux_out} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.squash} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.fu_lsq_o} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.C_CYCLE} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.br_mis_i} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.C_THREAD_NUM} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.ib_fu_i} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.fu_ib_o} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.rst_i} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.valid_sh} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.ib_fu} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.store_addr} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.$unit} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.opa_mux_out} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.ex_end} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.exception_i} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.clk_i} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.bc_fu_i} }
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.C_CYCLE}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.C_CYCLE}}
gui_set_radix -radix {decimal} -signals {{Sim:pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.C_THREAD_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.C_THREAD_NUM}}

# Global: Highlighting

# Global: Stack
gui_change_stack_mode -mode list

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 576



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
catch {gui_list_expand -id ${Hier.1} pipeline_dp_lsq_tb}
catch {gui_list_expand -id ${Hier.1} pipeline_dp_lsq_tb.dut}
catch {gui_list_expand -id ${Hier.1} pipeline_dp_lsq_tb.dut.FU_inst}
catch {gui_list_select -id ${Hier.1} {{pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit}}}
gui_view_scroll -id ${Hier.1} -vertical -set 209
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Class 'Class.1'
gui_list_set_filter -id ${Class.1} -list { {OVM 1} {VMM 1} {All 1} {Object 1} {UVM 1} {RVM 1} }
gui_list_set_filter -id ${Class.1} -text {*}
gui_change_design -id ${Class.1} -design Sim
# Warning: Class view not found.

# Member 'Member.1'
gui_list_set_filter -id ${Member.1} -list { {InternalMember 0} {RandMember 1} {All 0} {BaseMember 0} {PrivateMember 1} {LibBaseMember 0} {AutomaticMember 1} {VirtualMember 1} {PublicMember 1} {ProtectedMember 1} {OverRiddenMember 0} {InterfaceClassMember 1} {StaticMember 1} }
gui_list_set_filter -id ${Member.1} -text {*}

# Data 'Data.1'
gui_list_set_filter -id ${Data.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {LowPower 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Data.1} -text {*}
gui_list_show_data -id ${Data.1} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit}
gui_view_scroll -id ${Data.1} -vertical -set 0
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 209
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
gui_open_source -id ${Source.1}  -replace -active pipeline_dp_lsq_tb testbench/pipeline_dp_lsq_tb.sv
gui_src_value_annotate -id ${Source.1} -switch true
gui_set_env TOGGLE::VALUEANNOTATE 1
gui_view_scroll -id ${Source.1} -vertical -set 2910
gui_src_set_reusable -id ${Source.1}

# View 'Wave.1'
gui_wv_sync -id ${Wave.1} -switch false
set groupExD [gui_get_pref_value -category Wave -key exclusiveSG]
gui_set_pref_value -category Wave -key exclusiveSG -value {false}
set origWaveHeight [gui_get_pref_value -category Wave -key waveRowHeight]
gui_list_set_height -id Wave -height 25
set origGroupCreationState [gui_list_create_group_when_add -wave]
gui_list_create_group_when_add -wave -disable
gui_marker_set_ref -id ${Wave.1}  C1
gui_wv_zoom_timerange -id ${Wave.1} 434 750
gui_list_add_group -id ${Wave.1} -after {New Group} {{genblk4[0].LSQ_inst}}
gui_list_add_group -id ${Wave.1} -after {New Group} {LSQ_memory_switch_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {LSQ_rr_arbiter_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {MEM_SW_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {DC_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {DC_SW_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {{genblk1[3].LSQ_entry_ctrl_inst}}
gui_list_add_group -id ${Wave.1} -after {New Group} {{genblk4[0].store_unit}}
gui_list_collapse -id ${Wave.1} {genblk4[0].LSQ_inst}
gui_list_collapse -id ${Wave.1} LSQ_memory_switch_inst
gui_list_collapse -id ${Wave.1} LSQ_rr_arbiter_inst
gui_list_collapse -id ${Wave.1} MEM_SW_inst
gui_list_collapse -id ${Wave.1} DC_inst
gui_list_collapse -id ${Wave.1} DC_SW_inst
gui_list_expand -id ${Wave.1} {pipeline_dp_lsq_tb.dut.genblk4[0].LSQ_inst.genblk1[3].LSQ_entry_ctrl_inst.lsq_entry_o}
gui_list_expand -id ${Wave.1} {pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.br_mis_i}
gui_list_select -id ${Wave.1} {{pipeline_dp_lsq_tb.dut.FU_inst.genblk4[0].store_unit.br_mis_i.valid} }
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
gui_list_set_insertion_bar  -id ${Wave.1} -group {genblk4[0].store_unit}  -position in

gui_marker_move -id ${Wave.1} {C1} 576
gui_view_scroll -id ${Wave.1} -vertical -set 1076
gui_show_grid -id ${Wave.1} -enable false
# Restore toplevel window zorder
# The toplevel window could be closed if it has no view/pane
if {[gui_exist_window -window ${TopLevel.2}]} {
	gui_set_active_window -window ${TopLevel.2}
	gui_set_active_window -window ${Wave.1}
}
if {[gui_exist_window -window ${TopLevel.1}]} {
	gui_set_active_window -window ${TopLevel.1}
	gui_set_active_window -window ${Source.1}
	gui_set_active_window -window ${HSPane.1}
}
#</Session>

