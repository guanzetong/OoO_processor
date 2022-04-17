# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Sun Apr 17 02:27:37 2022
# Designs open: 1
#   Sim: simv
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
#   Source.1: pipeline_ss_smt_tb
#   Wave.1: 67 signals
#   Group count = 4
#   Group IC signal count = 17
#   Group IF_inst signal count = 26
#   Group MEM_SW_inst signal count = 13
#   Group mem_fixed_priority_arbiter_inst signal count = 11
# End_DVE_Session_Save_Info

# DVE version: R-2020.12-SP2-1_Full64
# DVE build date: Jul 18 2021 21:21:42


#<Session mode="Full" path="/afs/umich.edu/user/z/t/ztguan/group6w22_2/session.inter.vpd.tcl" type="Debug">

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
gui_show_window -window ${TopLevel.1} -show_state normal -rect {{186 170} {1725 971}}

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
set HSPane.1 [gui_create_window -type HSPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 283]
catch { set Hier.1 [gui_share_window -id ${HSPane.1} -type Hier] }
catch { set Stack.1 [gui_share_window -id ${HSPane.1} -type Stack -silent] }
catch { set Class.1 [gui_share_window -id ${HSPane.1} -type Class -silent] }
catch { set Object.1 [gui_share_window -id ${HSPane.1} -type Object -silent] }
gui_set_window_pref_key -window ${HSPane.1} -key dock_width -value_type integer -value 283
gui_set_window_pref_key -window ${HSPane.1} -key dock_height -value_type integer -value -1
gui_set_window_pref_key -window ${HSPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${HSPane.1} {{left 0} {top 0} {width 282} {height 557} {dock_state left} {dock_on_new_line true} {child_hier_colhier 242} {child_hier_coltype 86} {child_hier_colpd 0} {child_hier_col1 0} {child_hier_col2 1} {child_hier_col3 -1}}
set DLPane.1 [gui_create_window -type DLPane -parent ${TopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 252]
catch { set Data.1 [gui_share_window -id ${DLPane.1} -type Data] }
catch { set Local.1 [gui_share_window -id ${DLPane.1} -type Local -silent] }
catch { set Member.1 [gui_share_window -id ${DLPane.1} -type Member -silent] }
gui_set_window_pref_key -window ${DLPane.1} -key dock_width -value_type integer -value 252
gui_set_window_pref_key -window ${DLPane.1} -key dock_height -value_type integer -value 557
gui_set_window_pref_key -window ${DLPane.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${DLPane.1} {{left 0} {top 0} {width 251} {height 557} {dock_state left} {dock_on_new_line true} {child_data_colvariable 196} {child_data_colvalue 103} {child_data_coltype 101} {child_data_col1 0} {child_data_col2 1} {child_data_col3 2}}
set Console.1 [gui_create_window -type Console -parent ${TopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 146]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value 1540
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 146
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 1539} {height 145} {dock_state bottom} {dock_on_new_line true}}
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
gui_show_window -window ${TopLevel.2} -show_state normal -rect {{1 38} {1545 859}}

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
gui_update_layout -id ${Wave.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {child_wave_left 448} {child_wave_right 1091} {child_wave_colname 213} {child_wave_colvalue 231} {child_wave_col1 0} {child_wave_col2 1}}

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
gui_sim_run Ucli -exe simv -args { -ucligui} -dir ../group6w22_2 -nosource
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
gui_load_child_values {pipeline_ss_smt_tb.dut.MEM_SW_inst}
gui_load_child_values {pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst}
gui_load_child_values {pipeline_ss_smt_tb.dut.IF_inst}
gui_load_child_values {pipeline_ss_smt_tb.dut.IC}


set _session_group_1 IC
gui_sg_create "$_session_group_1"
set IC "$_session_group_1"

gui_sg_addsignal -group "$_session_group_1" { pipeline_ss_smt_tb.dut.IC.C_CACHE_SIZE pipeline_ss_smt_tb.dut.IC.proc2cache_i pipeline_ss_smt_tb.dut.IC.cache2proc_o pipeline_ss_smt_tb.dut.IC.cache_ctrl_mem pipeline_ss_smt_tb.dut.IC.C_CACHE_SASS pipeline_ss_smt_tb.dut.IC.mem2cache_i pipeline_ss_smt_tb.dut.IC.cache2mem_o pipeline_ss_smt_tb.dut.IC.memory_enable_i pipeline_ss_smt_tb.dut.IC.cache_mem_ctrl pipeline_ss_smt_tb.dut.IC.cache_array_mon_o pipeline_ss_smt_tb.dut.IC.mshr_array_mon_o pipeline_ss_smt_tb.dut.IC.C_CACHE_SET_NUM pipeline_ss_smt_tb.dut.IC.C_MSHR_ENTRY_NUM pipeline_ss_smt_tb.dut.IC.rst_i pipeline_ss_smt_tb.dut.IC.C_CACHE_BLOCK_SIZE {pipeline_ss_smt_tb.dut.IC.$unit} pipeline_ss_smt_tb.dut.IC.clk_i }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_CACHE_SIZE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_CACHE_SIZE}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_CACHE_SASS}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_CACHE_SASS}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_CACHE_SET_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_CACHE_SET_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_MSHR_ENTRY_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_MSHR_ENTRY_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_CACHE_BLOCK_SIZE}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IC.C_CACHE_BLOCK_SIZE}

set _session_group_2 IF_inst
gui_sg_create "$_session_group_2"
set IF_inst "$_session_group_2"

gui_sg_addsignal -group "$_session_group_2" { pipeline_ss_smt_tb.dut.IF_inst.dp_fiq_i pipeline_ss_smt_tb.dut.IF_inst.thread_data_o_t pipeline_ss_smt_tb.dut.IF_inst.inst_num_sel pipeline_ss_smt_tb.dut.IF_inst.thread_to_ft_o_t pipeline_ss_smt_tb.dut.IF_inst.n_thread_data pipeline_ss_smt_tb.dut.IF_inst.C_THREAD_IDX_WIDTH pipeline_ss_smt_tb.dut.IF_inst.C_DP_NUM_WIDTH pipeline_ss_smt_tb.dut.IF_inst.if_ic_o pipeline_ss_smt_tb.dut.IF_inst.fiq_dp_o pipeline_ss_smt_tb.dut.IF_inst.n_thread_data_o_t pipeline_ss_smt_tb.dut.IF_inst.br_mis_i pipeline_ss_smt_tb.dut.IF_inst.thread_idx_disp pipeline_ss_smt_tb.dut.IF_inst.C_THREAD_NUM pipeline_ss_smt_tb.dut.IF_inst.pc_en_i pipeline_ss_smt_tb.dut.IF_inst.ic_if_i pipeline_ss_smt_tb.dut.IF_inst.thread_to_ft pipeline_ss_smt_tb.dut.IF_inst.pc_en pipeline_ss_smt_tb.dut.IF_inst.rst_i pipeline_ss_smt_tb.dut.IF_inst.thread_data pipeline_ss_smt_tb.dut.IF_inst.C_DP_NUM pipeline_ss_smt_tb.dut.IF_inst.rst_pc_i {pipeline_ss_smt_tb.dut.IF_inst.$unit} pipeline_ss_smt_tb.dut.IF_inst.C_IF_NUM pipeline_ss_smt_tb.dut.IF_inst.C_FIQ_NUM pipeline_ss_smt_tb.dut.IF_inst.thread_idx_disp_o_t pipeline_ss_smt_tb.dut.IF_inst.clk_i }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_THREAD_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_THREAD_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_DP_NUM_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_DP_NUM_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_THREAD_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_THREAD_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_DP_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_DP_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_IF_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_IF_NUM}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_FIQ_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.IF_inst.C_FIQ_NUM}

set _session_group_3 MEM_SW_inst
gui_sg_create "$_session_group_3"
set MEM_SW_inst "$_session_group_3"

gui_sg_addsignal -group "$_session_group_3" { pipeline_ss_smt_tb.dut.MEM_SW_inst.mem2switch_i pipeline_ss_smt_tb.dut.MEM_SW_inst.arbiter_ack pipeline_ss_smt_tb.dut.MEM_SW_inst.switch2mem_o pipeline_ss_smt_tb.dut.MEM_SW_inst.grant_idx pipeline_ss_smt_tb.dut.MEM_SW_inst.grant_valid pipeline_ss_smt_tb.dut.MEM_SW_inst.memory_grant_o pipeline_ss_smt_tb.dut.MEM_SW_inst.C_REQ_IDX_WIDTH pipeline_ss_smt_tb.dut.MEM_SW_inst.rst_i pipeline_ss_smt_tb.dut.MEM_SW_inst.req2mem_i pipeline_ss_smt_tb.dut.MEM_SW_inst.arbiter_req {pipeline_ss_smt_tb.dut.MEM_SW_inst.$unit} pipeline_ss_smt_tb.dut.MEM_SW_inst.C_REQ_NUM pipeline_ss_smt_tb.dut.MEM_SW_inst.clk_i }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.MEM_SW_inst.C_REQ_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.MEM_SW_inst.C_REQ_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.MEM_SW_inst.C_REQ_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.MEM_SW_inst.C_REQ_NUM}

set _session_group_4 mem_fixed_priority_arbiter_inst
gui_sg_create "$_session_group_4"
set mem_fixed_priority_arbiter_inst "$_session_group_4"

gui_sg_addsignal -group "$_session_group_4" { pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.next_grant pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.grant_o pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.ack_i pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.next_valid pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.C_REQ_IDX_WIDTH pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.valid_o pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.rst_i {pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.$unit} pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.C_REQ_NUM pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.req_i pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.clk_i }
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.C_REQ_IDX_WIDTH}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.C_REQ_IDX_WIDTH}
gui_set_radix -radix {decimal} -signals {Sim:pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.C_REQ_NUM}
gui_set_radix -radix {twosComplement} -signals {Sim:pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.C_REQ_NUM}

# Global: Highlighting

# Global: Stack
gui_change_stack_mode -mode list

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 2110



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
catch {gui_list_expand -id ${Hier.1} pipeline_ss_smt_tb.dut.MEM_SW_inst}
catch {gui_list_select -id ${Hier.1} {pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst}}
gui_view_scroll -id ${Hier.1} -vertical -set 160
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
gui_list_show_data -id ${Data.1} {pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst}
gui_view_scroll -id ${Data.1} -vertical -set 0
gui_view_scroll -id ${Data.1} -horizontal -set 0
gui_view_scroll -id ${Hier.1} -vertical -set 160
gui_view_scroll -id ${Hier.1} -horizontal -set 0

# Source 'Source.1'
gui_src_value_annotate -id ${Source.1} -switch false
gui_set_env TOGGLE::VALUEANNOTATE 0
gui_open_source -id ${Source.1}  -replace -active pipeline_ss_smt_tb testbench/pipeline_ss_smt_tb.sv
gui_src_value_annotate -id ${Source.1} -switch true
gui_set_env TOGGLE::VALUEANNOTATE 1
gui_view_scroll -id ${Source.1} -vertical -set 3225
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
gui_wv_zoom_timerange -id ${Wave.1} 0 116
gui_list_add_group -id ${Wave.1} -after {New Group} {IC}
gui_list_add_group -id ${Wave.1} -after {New Group} {IF_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {MEM_SW_inst}
gui_list_add_group -id ${Wave.1} -after {New Group} {mem_fixed_priority_arbiter_inst}
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.IC.proc2cache_i
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.IC.cache2proc_o
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.IC.mem2cache_i
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.IC.cache2mem_o
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.MEM_SW_inst.switch2mem_o
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.MEM_SW_inst.memory_grant_o
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.MEM_SW_inst.req2mem_i
gui_list_expand -id ${Wave.1} {pipeline_ss_smt_tb.dut.MEM_SW_inst.req2mem_i[1]}
gui_list_expand -id ${Wave.1} pipeline_ss_smt_tb.dut.MEM_SW_inst.arbiter_req
gui_list_select -id ${Wave.1} {pipeline_ss_smt_tb.dut.MEM_SW_inst.mem_fixed_priority_arbiter_inst.clk_i }
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
gui_list_set_insertion_bar  -id ${Wave.1} -group mem_fixed_priority_arbiter_inst  -position in

gui_marker_move -id ${Wave.1} {C1} 2110
gui_view_scroll -id ${Wave.1} -vertical -set 1887
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

