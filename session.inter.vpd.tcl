# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Tue Apr 12 23:54:03 2022
# Designs open: 1
#   Sim: simv
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
#   Source.1: cache_tb
#   Wave.1: 98 signals
#   Group count = 4
#   Group dut signal count = 9
#   Group cache_ctrl_inst signal count = 31
#   Group genblk1[3].mshr_entry_ctrl_inst signal count = 32
#   Group cache_mem_inst signal count = 26
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
gui_show_window -window ${TopLevel.1} -show_state normal -rect {{944 180} {2311 856}}

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
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 181]
catch { set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier] }
catch { set Stack.1 [gui_share_window -id ${HSPane.1} -type Stack -silent] }
catch { set Class.1 [gui_share_window -id ${HSPane.1} -type Class -silent] }
catch { set Object.1 [gui_share_window -id ${HSPane.1} -type Object -silent] }
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 181
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 180} {height 403} {dock_state left} {dock_on_new_line true} {child_hier_colhier 193} {child_hier_coltype 83} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 291]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
catch { set Local.1 [gui_share_window -id ${DLPane.1} -type Local -silent] }
catch { set Member.1 [gui_share_window -id ${DLPane.1} -type Member -silent] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 291
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 463
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 290} {height 403} {dock_state left} {dock_on_new_line true} {child_data_colvariable 196} {child_data_colvalue 103} {child_data_coltype 101} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 175]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value -1
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 175
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 271} {height 174} {dock_state bottom} {dock_on_new_line true}}
set DriverLoad.1 [gui_create_window -type DriverLoad -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line false -dock_extent 175]
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_width -value_type integer -value 150
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_height -value_type integer -value 175
gui_set_window_pref_key -window ${DriverLoad.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DriverLoad.1} {{left 0} {top 0} {width 1095} {height 174} {dock_state bottom} {dock_on_new_line false}}
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
gui_show_window -window ${TopLevel.2} -show_state normal -rect {{71 181} {1787 1042}}

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
gui_update_layout -id ${Wave.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {child_wave_left 498} {child_wave_right 1213} {child_wave_colname 201} {child_wave_colvalue 293} {child_wave_col1 0} {child_wave_col2 1}}

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
gui_load_child_values {cache_tb.dut}
gui_load_child_values {cache_tb.dut.cache_ctrl_inst}
gui_load_child_values {cache_tb.dut.cache_mem_inst}
gui_load_child_values {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst}


set _session_group_1 dut
gui_sg_create "$_session_group_1"
set dut "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { cache_tb.dut.clk_i cache_tb.dut.proc2cache_i cache_tb.dut.cache2proc_o cache_tb.dut.cache_ctrl_mem cache_tb.dut.cache_mem_ctrl cache_tb.dut.mem2cache_i cache_tb.dut.cache2mem_o cache_tb.dut.rst_i {cache_tb.dut.$unit} }

set _session_group_2 cache_ctrl_inst
gui_sg_create "$_session_group_2"
set cache_ctrl_inst "$_session_group_2"

gui_sg_addsignal -group "$_session_group_2" { cache_tb.dut.cache_ctrl_inst.clk_i cache_tb.dut.cache_ctrl_inst.cache_mem_ctrl_i cache_tb.dut.cache_ctrl_inst.proc2cache_i cache_tb.dut.cache_ctrl_inst.cache2proc_o cache_tb.dut.cache_ctrl_inst.cache_ctrl_mem_o cache_tb.dut.cache_ctrl_inst.mshr_memory cache_tb.dut.cache_ctrl_inst.C_CACHE_SASS cache_tb.dut.cache_ctrl_inst.proc_grant cache_tb.dut.cache_ctrl_inst.mem2cache_i cache_tb.dut.cache_ctrl_inst.C_MSHR_IDX_WIDTH cache_tb.dut.cache_ctrl_inst.mshr_hit_idx cache_tb.dut.cache_ctrl_inst.mshr_hit cache_tb.dut.cache_ctrl_inst.C_XLEN cache_tb.dut.cache_ctrl_inst.mshr_cache_mem cache_tb.dut.cache_ctrl_inst.cp_flag cache_tb.dut.cache_ctrl_inst.mshr_array cache_tb.dut.cache_ctrl_inst.evict_hit_idx cache_tb.dut.cache_ctrl_inst.cache_mem_grant cache_tb.dut.cache_ctrl_inst.C_CACHE_TAG_WIDTH cache_tb.dut.cache_ctrl_inst.memory_grant cache_tb.dut.cache_ctrl_inst.cache2mem_o cache_tb.dut.cache_ctrl_inst.evict_hit cache_tb.dut.cache_ctrl_inst.dp_sel cache_tb.dut.cache_ctrl_inst.cp_data cache_tb.dut.cache_ctrl_inst.C_CACHE_OFFSET_WIDTH cache_tb.dut.cache_ctrl_inst.C_MSHR_ENTRY_NUM cache_tb.dut.cache_ctrl_inst.rst_i cache_tb.dut.cache_ctrl_inst.mshr_proc cache_tb.dut.cache_ctrl_inst.C_CACHE_BLOCK_SIZE {cache_tb.dut.cache_ctrl_inst.$unit} cache_tb.dut.cache_ctrl_inst.C_CACHE_IDX_WIDTH }
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_SASS}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_SASS}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_MSHR_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_MSHR_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_XLEN}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_XLEN}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_TAG_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_TAG_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_OFFSET_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_OFFSET_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_MSHR_ENTRY_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_MSHR_ENTRY_NUM}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_BLOCK_SIZE}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_BLOCK_SIZE}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_ctrl_inst.C_CACHE_IDX_WIDTH}

set _session_group_3 {genblk1[3].mshr_entry_ctrl_inst}
gui_sg_create "$_session_group_3"
set {genblk1[3].mshr_entry_ctrl_inst} "$_session_group_3"

gui_sg_addsignal -group "$_session_group_3" { {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.next_mshr_cp_flag} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.dp_sel_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.cache_mem_ctrl_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.proc2cache_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_cp_data_o} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_proc_o} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mem2cache_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_MSHR_IDX_WIDTH} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_entry_idx_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_XLEN} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.evict_hit_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.next_mshr_entry} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.cp_data_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.next_mshr_cp_data} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_hit_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.memory_grant_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_cp_flag_o} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_memory_o} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_entry_o} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_CACHE_OFFSET_WIDTH} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_MSHR_ENTRY_NUM} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.evict_hit_idx_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_hit_idx_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.rst_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.cache_mem_grant_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_entry} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.cp_flag_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_CACHE_BLOCK_SIZE} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.proc_grant_i} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.$unit} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_cache_mem_o} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.clk_i} }
gui_set_radix -radix {decimal} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_MSHR_IDX_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_MSHR_IDX_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_XLEN}}
gui_set_radix -radix {twosComplement} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_XLEN}}
gui_set_radix -radix {decimal} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_CACHE_OFFSET_WIDTH}}
gui_set_radix -radix {twosComplement} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_CACHE_OFFSET_WIDTH}}
gui_set_radix -radix {decimal} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_MSHR_ENTRY_NUM}}
gui_set_radix -radix {twosComplement} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_MSHR_ENTRY_NUM}}
gui_set_radix -radix {decimal} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_CACHE_BLOCK_SIZE}}
gui_set_radix -radix {twosComplement} -signals {{Sim:cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.C_CACHE_BLOCK_SIZE}}

set _session_group_4 cache_mem_inst
gui_sg_create "$_session_group_4"
set cache_mem_inst "$_session_group_4"

gui_sg_addsignal -group "$_session_group_4" { cache_tb.dut.cache_mem_inst.C_CACHE_SIZE cache_tb.dut.cache_mem_inst.cache_ctrl_mem_i cache_tb.dut.cache_mem_inst.mem_idx cache_tb.dut.cache_mem_inst.C_CACHE_SASS cache_tb.dut.cache_mem_inst.cache_mem_ctrl_o cache_tb.dut.cache_mem_inst.C_XLEN cache_tb.dut.cache_mem_inst.use_history cache_tb.dut.cache_mem_inst.mem_blk_offset cache_tb.dut.cache_mem_inst.C_CACHE_TAG_WIDTH cache_tb.dut.cache_mem_inst.access cache_tb.dut.cache_mem_inst.next_lru cache_tb.dut.cache_mem_inst.mem_tag cache_tb.dut.cache_mem_inst.C_WAY_IDX_WIDTH cache_tb.dut.cache_mem_inst.empty_way_idx cache_tb.dut.cache_mem_inst.next_use_history cache_tb.dut.cache_mem_inst.C_CACHE_SET_NUM cache_tb.dut.cache_mem_inst.cache_array cache_tb.dut.cache_mem_inst.C_CACHE_OFFSET_WIDTH cache_tb.dut.cache_mem_inst.rst_i cache_tb.dut.cache_mem_inst.C_USE_HISTORY_WIDTH cache_tb.dut.cache_mem_inst.empty_way_valid cache_tb.dut.cache_mem_inst.next_cache_array cache_tb.dut.cache_mem_inst.C_CACHE_BLOCK_SIZE {cache_tb.dut.cache_mem_inst.$unit} cache_tb.dut.cache_mem_inst.C_CACHE_IDX_WIDTH cache_tb.dut.cache_mem_inst.clk_i }
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_SIZE}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_SIZE}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_SASS}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_SASS}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_XLEN}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_XLEN}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_TAG_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_TAG_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_WAY_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_WAY_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_SET_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_SET_NUM}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_OFFSET_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_OFFSET_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_USE_HISTORY_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_USE_HISTORY_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_BLOCK_SIZE}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_BLOCK_SIZE}
gui_set_radix -radix {decimal} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:cache_tb.dut.cache_mem_inst.C_CACHE_IDX_WIDTH}

# Global: Highlighting

# Global: Stack
gui_change_stack_mode -mode list

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 196



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
catch {gui_list_expand -id ${Hier.1} cache_tb}
catch {gui_list_expand -id ${Hier.1} cache_tb.dut}
catch {gui_list_select -id ${Hier.1} {cache_tb.dut.cache_mem_inst}}
gui_view_scroll -id ${Hier.1} -vertical -set 301
gui_view_scroll -id ${Hier.1} -horizontal -set 1

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
gui_list_show_data -id ${Data.1} {cache_tb.dut.cache_mem_inst}
gui_view_scroll -id ${Data.1} -vertical -set 0
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 301
gui_view_scroll -id ${Hier.1} -horizontal -set 1

# DriverLoad 'DriverLoad.1'
gui_get_drivers -session -id ${DriverLoad.1} -signal {cache_tb.dut.cache_ctrl_inst.mshr_dispatch_selector_inst.mshr_array_i[15:0]} -time 0 -starttime 2509
gui_get_drivers -session -id ${DriverLoad.1} -signal cache_tb.dut.cache_ctrl_inst.mshr_cache_mem_switch_inst.mshr_rr_arbiter_inst.clk_i -time 55 -starttime 56
gui_get_drivers -session -id ${DriverLoad.1} -signal {cache_tb.dut.cache_ctrl_inst.genblk1[1].mshr_entry_ctrl_inst.mshr_entry_idx_i[3:0]} -time 0 -starttime 76
gui_get_drivers -session -id ${DriverLoad.1} -signal {cache_tb.dut.cache_ctrl_inst.genblk1[1].mshr_entry_ctrl_inst.mshr_memory_o.command[1:0]} -time 86 -starttime 86

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
gui_open_source -id ${Source.1}  -replace -active cache_tb testbench/cache_tb.sv
gui_src_value_annotate -id ${Source.1} -switch true
gui_set_env TOGGLE::VALUEANNOTATE 1
gui_view_scroll -id ${Source.1} -vertical -set 2235
gui_src_set_reusable -id ${Source.1}

# View 'Wave.1'
gui_wv_sync -id ${Wave.1} -switch false
set groupExD [gui_get_pref_value -category Wave -key exclusiveSG]
gui_set_pref_value -category Wave -key exclusiveSG -value {false}
set origWaveHeight [gui_get_pref_value -category Wave -key waveRowHeight]
gui_list_set_height -id Wave -height 25
set origGroupCreationState [gui_list_create_group_when_add -wave]
gui_list_create_group_when_add -wave -disable
gui_marker_create -id ${Wave.1} M1 75
gui_marker_create -id ${Wave.1} M2 95
gui_marker_create -id ${Wave.1} M3 105
gui_marker_create -id ${Wave.1} M4 115
gui_marker_create -id ${Wave.1} M5 145
gui_marker_select -id ${Wave.1} {  M5 }
gui_marker_set_ref -id ${Wave.1}  C1
gui_wv_zoom_timerange -id ${Wave.1} 64 209
gui_list_add_group -id ${Wave.1} -after {New Group} {dut}
gui_list_add_group -id ${Wave.1} -after {New Group} {cache_ctrl_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {{genblk1[3].mshr_entry_ctrl_inst}}
gui_list_add_group -id ${Wave.1} -after {New Group} {cache_mem_inst}
gui_list_expand -id ${Wave.1} cache_tb.dut.proc2cache_i
gui_list_expand -id ${Wave.1} cache_tb.dut.cache2proc_o
gui_list_expand -id ${Wave.1} cache_tb.dut.cache_mem_ctrl
gui_list_expand -id ${Wave.1} cache_tb.dut.cache_ctrl_inst.cache_mem_ctrl_i
gui_list_expand -id ${Wave.1} cache_tb.dut.cache_ctrl_inst.proc2cache_i
gui_list_expand -id ${Wave.1} cache_tb.dut.cache_ctrl_inst.cache2proc_o
gui_list_expand -id ${Wave.1} cache_tb.dut.cache_ctrl_inst.cache_ctrl_mem_o
gui_list_expand -id ${Wave.1} {cache_tb.dut.cache_ctrl_inst.genblk1[3].mshr_entry_ctrl_inst.mshr_entry_o}
gui_list_select -id ${Wave.1} {cache_tb.dut.cache_mem_inst.mem_tag }
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
gui_list_set_insertion_bar  -id ${Wave.1} -group cache_mem_inst  -position in

gui_marker_move -id ${Wave.1} {C1} 196
gui_view_scroll -id ${Wave.1} -vertical -set 2872
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

