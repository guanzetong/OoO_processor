# make          <- runs simv (after compiling simv if needed)
# make all      <- runs simv (after compiling simv if needed)
# make simv     <- compile simv if needed (but do not run)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
#
#

SOURCE = test_progs/rv32_mult.s
# SOURCE = test_progs/alexnet.c


CRT = crt.s
LINKERS = linker.lds
ASLINKERS = aslinker.lds

DEBUG_FLAG = -g
CFLAGS =  -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -std=gnu11 -mstrict-align -mno-div 
OFLAGS = -O0
ASFLAGS = -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -Wno-main -mstrict-align
OBJFLAGS = -SD -M no-aliases 
OBJDFLAGS = -SD -M numeric,no-aliases

##########################################################################
# IF YOU AREN'T USING A CAEN MACHINE, CHANGE THIS TO FALSE OR OVERRIDE IT
CAEN = 1
##########################################################################
ifeq (1, $(CAEN))
	GCC = riscv gcc
	OBJDUMP = riscv objdump
	AS = riscv as
	ELF2HEX = riscv elf2hex
else
	GCC = riscv64-unknown-elf-gcc
	OBJDUMP = riscv64-unknown-elf-objdump
	AS = riscv64-unknown-elf-as
	ELF2HEX = elf2hex
endif


VCS = vcs -V -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson -debug_pp
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

# SIMULATION CONFIG

HEADERS     = $(wildcard *.svh)

TESTBENCH	= testbench/pipeline_ss_smt_tb.sv
TESTBENCH	+= testbench/mem.sv

SIMFILES    = $(wildcard verilog/*.sv)

# SYNTHESIS CONFIG
SYNTH_DIR = ./synth

export HEADERS

# Pipeline
PIPEFILES   = verilog/pipeline_ss_smt.sv verilog/DP_lsq.sv
export PIPEFILES
PIPELINE_NAME = pipeline_ss_smt
export PIPELINE_NAME
PIPELINE  = $(SYNTH_DIR)/$(PIPELINE_NAME).vg 
SYNFILES  = $(PIPELINE) $(SYNTH_DIR)/$(PIPELINE_NAME)_svsim.sv

# Data Cache
DCACHE_NAME	= dcache
export DCACHE_NAME
DCACHE_FILES = verilog/dcache_mem.sv verilog/cache_ctrl.sv verilog/dcache.sv
DCACHE_FILES += verilog/dcache_LRU_update.sv verilog/mshr_entry_ctrl.sv verilog/mshr_cache_mem_switch.sv
DCACHE_FILES += verilog/mshr_dispatch_selector.sv verilog/mshr_hit_detector.sv verilog/evict_hit_detector.sv
DCACHE_FILES += verilog/mshr_memory_switch.sv verilog/mshr_proc_switch.sv verilog/mshr_rr_arbiter.sv
export DCACHE_FILES
DCACHE = $(SYNTH_DIR)/$(DCACHE_NAME).ddc
export DCACHE_CLOCK_PERIOD = 10.4

# Instruction Cache
ICACHE_NAME = icache
export ICACHE_NAME
ICACHE_FILES = verilog/icache_mem.sv verilog/cache_ctrl.sv verilog/icache.sv
ICACHE_FILES += verilog/icache_LRU_update.sv verilog/mshr_entry_ctrl.sv verilog/mshr_cache_mem_switch.sv
ICACHE_FILES += verilog/mshr_dispatch_selector.sv verilog/mshr_hit_detector.sv verilog/evict_hit_detector.sv
ICACHE_FILES += verilog/mshr_memory_switch.sv verilog/mshr_proc_switch.sv verilog/mshr_rr_arbiter.sv
export ICACHE_FILES
ICACHE = $(SYNTH_DIR)/$(ICACHE_NAME).ddc
export ICACHE_CLOCK_PERIOD = 10.4

# Instruction Fetch
IF_NAME = IF
export IF_NAME
IF_FILES = verilog/IF.sv
export IF_FILES
IF = $(SYNTH_DIR)/$(IF_NAME).ddc
export IF_CLOCK_PERIOD = 3.3
# export IF_CLOCK_PERIOD = 3.5

# Dispatcher
DP_NAME = DP_lsq
export DP_NAME
DP_FILES = verilog/$(DP_NAME).sv
export DP_FILES
DP = $(SYNTH_DIR)/$(DP_NAME).ddc

# Reorder Buffer
ROB_NAME = ROB
export ROB_NAME
ROB_FILES = verilog/$(ROB_NAME).sv
export ROB_FILES
ROB = $(SYNTH_DIR)/$(ROB_NAME).ddc
export ROB_CLOCK_PERIOD = 2.5

# Freelist
FL_NAME = FL_smt
export FL_NAME
FL_FILES = verilog/$(FL_NAME).sv
export FL_FILES
FL = $(SYNTH_DIR)/$(FL_NAME).ddc
export FL_CLOCK_PERIOD = 4.5

# Architectural Map Table
AMT_NAME = AMT
export AMT_NAME
AMT_FILES = verilog/$(AMT_NAME).sv
export AMT_FILES
AMT = $(SYNTH_DIR)/$(AMT_NAME).ddc
export AMT_CLOCK_PERIOD = 1.7

# Map Table (Superscalar)
MT_NAME = MT_SS
export MT_NAME
MT_FILES = verilog/$(MT_NAME).sv
export MT_FILES
MT = $(SYNTH_DIR)/$(MT_NAME).ddc
export MT_CLOCK_PERIOD = 2.3

# Reservation Station
RS_NAME = RS
export RS_NAME
RS_FILES = verilog/$(RS_NAME).sv
export RS_FILES
RS = $(SYNTH_DIR)/$(RS_NAME).ddc
export RS_CLOCK_PERIOD = 6

# Issue Buffer
IB_NAME = IB
export IB_NAME
IB_FILES = verilog/IB.sv
IB_FILES += verilog/IB_ALU_pop_out_router.sv verilog/IB_ALU_push_in_router.sv verilog/IB_ALU_queue.sv verilog/IB_ALU.sv
IB_FILES += verilog/IB_MULT_pop_out_router.sv verilog/IB_MULT_push_in_router.sv verilog/IB_MULT_queue.sv verilog/IB_MULT.sv
IB_FILES += verilog/IB_BR_pop_out_router.sv verilog/IB_BR_push_in_router.sv verilog/IB_BR_queue.sv verilog/IB_BR.sv
IB_FILES += verilog/IB_LOAD_pop_out_router.sv verilog/IB_LOAD_push_in_router.sv verilog/IB_LOAD_queue.sv verilog/IB_LOAD.sv
IB_FILES += verilog/IB_STORE_pop_out_router.sv verilog/IB_STORE_push_in_router.sv verilog/IB_STORE_queue.sv verilog/IB_STORE.sv
export IB_FILES
IB = $(SYNTH_DIR)/$(IB_NAME).ddc
export IB_CLOCK_PERIOD = 5

# Functional Unit
FU_NAME = FU
export FU_NAME
FU_FILES = verilog/FU.sv
export FU_FILES
FU = $(SYNTH_DIR)/$(FU_NAME).ddc
export FU_CLOCK_PERIOD = 12.5

# Physical Register File
PRF_NAME = PRF
export PRF_NAME
PRF_FILES = verilog/PRF.sv
export PRF_FILES
PRF = $(SYNTH_DIR)/$(PRF_NAME).ddc
export PRF_CLOCK_PERIOD = 2.4

# Load/Store Queue
LSQ_NAME = LSQ
export LSQ_NAME
LSQ_FILES = verilog/LSQ.sv
LSQ_FILES += verilog/LSQ_bc_switch.sv verilog/LSQ_entry_ctrl.sv verilog/LSQ_global_ctrl.sv verilog/LSQ_memory_switch.sv
LSQ_FILES += verilog/LSQ_rr_arbiter.sv 
export LSQ_FILES
LSQ = $(SYNTH_DIR)/$(LSQ_NAME).ddc
export LSQ_CLOCK_PERIOD = 5

# Broadcaster
BC_NAME = BC
export BC_NAME
BC_FILES = verilog/BC.sv
export BC_FILES
BC = $(SYNTH_DIR)/$(BC_NAME).ddc
export BC_CLOCK_PERIOD = 3

# Memory Interface Switch
MEMSW_NAME = mem_switch
export MEMSW_NAME
MEMSW_FILES = verilog/mem_switch.sv verilog/mem_fixed_priority_arbiter.sv
export MEMSW_FILES
MEMSW = $(SYNTH_DIR)/$(MEMSW_NAME).ddc
export MEMSW_CLOCK_PERIOD = 1.1

# Data Cache Interface Switch
DCSW_NAME = dcache_switch
export DCSW_NAME
DCSW_FILES = verilog/dcache_switch.sv verilog/dcache_rr_arbiter.sv
export DCSW_FILES
DCSW = $(SYNTH_DIR)/$(DCSW_NAME).ddc
export DCSW_CLOCK_PERIOD = 2

# Pipeline DDC
PIPE_DDC = $(DCACHE) $(ICACHE) $(IF) $(ROB) $(FL) $(AMT) $(MT) #$(DP)
PIPE_DDC += $(RS) $(IB) $(FU) $(PRF) $(LSQ) $(BC) $(MEMSW) $(DCSW)

# Passed through to .tcl scripts:
export CLOCK_NET_NAME = clk_i
export RESET_NET_NAME = rst_i
export CLOCK_PERIOD   = 15   	# TODO: You will need to make match SYNTH_CLOCK_PERIOD in sys_defs
                                #       and make this more aggressive

################################################################################
## RULES
################################################################################

# Default target:
all:    simv
	./simv | tee program.out

.PHONY: all

# Simulation:

sim:	simv
	./simv -cm line+tgl | tee sim_program.out

simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $^ -o simv -cm line+tgl +lint=TFIPC-L

.PHONY: sim

urg: 	sim
	urg -dir simv.vdb -format text

# Programs

compile: $(CRT) $(LINKERS)
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.elf
	$(GCC) $(CFLAGS) $(DEBUG_FLAG) $(CRT) $(SOURCE) -T $(LINKERS) -o program.debug.elf
assemble: $(ASLINKERS)
	$(GCC) $(ASFLAGS) $(SOURCE) -T $(ASLINKERS) -o program.elf 
	cp program.elf program.debug.elf
disassemble: program.debug.elf
	$(OBJDUMP) $(OBJFLAGS) program.debug.elf > program.dump
	$(OBJDUMP) $(OBJDFLAGS) program.debug.elf > program.debug.dump
	rm program.debug.elf
hex: program.elf
	$(ELF2HEX) 8 8192 program.elf > program.mem

program: compile disassemble hex
	@:

debug_program:
	gcc -lm -g -std=gnu11 -DDEBUG $(SOURCE) -o debug_bin
assembly: assemble disassemble hex
	@:


# Synthesis

# $(PIPELINE): $(HEADERS) $(PIPE_DDC) $(SYNTH_DIR)/$(PIPELINE_NAME).tcl
$(PIPELINE): $(HEADERS) $(SYNTH_DIR)/$(PIPELINE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(PIPELINE_NAME).tcl | tee $(PIPELINE_NAME)_synth.out
	echo -e -n 'H\n1\ni\n`timescale 1ns/100ps\n.\nw\nq\n' | ed $(PIPELINE)

$(DCACHE): $(HEADERS) $(DCACHE_FILES) $(SYNTH_DIR)/$(DCACHE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DCACHE_NAME).tcl | tee $(DCACHE_NAME)_synth.out

$(ICACHE): $(HEADERS) $(ICACHE_FILES) $(SYNTH_DIR)/$(ICACHE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(ICACHE_NAME).tcl | tee $(ICACHE_NAME)_synth.out

$(IF): $(HEADERS) $(IF_FILES) $(SYNTH_DIR)/$(IF_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(IF_NAME).tcl | tee $(IF_NAME)_synth.out

$(DP): $(HEADERS) $(DP_FILES) $(SYNTH_DIR)/$(DP_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DP_NAME).tcl | tee $(DP_NAME)_synth.out

$(ROB): $(HEADERS) $(ROB_FILES) $(SYNTH_DIR)/$(ROB_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(ROB_NAME).tcl | tee $(ROB_NAME)_synth.out

$(FL): $(HEADERS) $(FL_FILES) $(SYNTH_DIR)/$(FL_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(FL_NAME).tcl | tee $(FL_NAME)_synth.out

$(AMT): $(HEADERS) $(AMT_FILES) $(SYNTH_DIR)/$(AMT_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(AMT_NAME).tcl | tee $(AMT_NAME)_synth.out

$(MT): $(HEADERS) $(MT_FILES) $(SYNTH_DIR)/$(MT_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(MT_NAME).tcl | tee $(MT_NAME)_synth.out

$(RS): $(HEADERS) $(RS_FILES) $(SYNTH_DIR)/$(RS_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(RS_NAME).tcl | tee $(RS_NAME)_synth.out

$(IB): $(HEADERS) $(IB_FILES) $(SYNTH_DIR)/$(IB_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(IB_NAME).tcl | tee $(IB_NAME)_synth.out

$(FU): $(HEADERS) $(FU_FILES) $(SYNTH_DIR)/$(FU_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(FU_NAME).tcl | tee $(FU_NAME)_synth.out

$(PRF): $(HEADERS) $(PRF_FILES) $(SYNTH_DIR)/$(PRF_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(PRF_NAME).tcl | tee $(PRF_NAME)_synth.out

$(LSQ): $(HEADERS) $(LSQ_FILES) $(SYNTH_DIR)/$(LSQ_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(LSQ_NAME).tcl | tee $(LSQ_NAME)_synth.out

$(BC): $(HEADERS) $(BC_FILES) $(SYNTH_DIR)/$(BC_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(BC_NAME).tcl | tee $(BC_NAME)_synth.out

$(MEMSW): $(HEADERS) $(MEMSW_FILES) $(SYNTH_DIR)/$(MEMSW_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(MEMSW_NAME).tcl | tee $(MEMSW_NAME)_synth.out

$(DCSW): $(HEADERS) $(DCSW_FILES) $(SYNTH_DIR)/$(DCSW_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DCSW_NAME).tcl | tee $(DCSW_NAME)_synth.out

syn:	syn_simv 
	./syn_simv | tee syn_program.out

syn_simv:	$(HEADERS) $(SYNFILES) $(TESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST -o syn_simv 

.PHONY: syn


# Debugging

dve:	sim
	./simv -gui &

dve_syn: syn_sim 
	./syn_simv -gui &

.PHONY: dve dve_syn 

clean:
	rm -rf *simv *simv.daidir csrc vcs.key program.out *.key
	rm -rf vis_simv vis_simv.daidir
	rm -rf dve* inter.vpd DVEfiles
	rm -rf syn_simv syn_simv.daidir syn_program.out
	rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h
	rm -f *.elf *.dump *.mem debug_bin

nuke:	clean
	rm -rf synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/*.log synth/*.syn
	rm -rf synth/*.out command.log synth/*.db synth/*.svf synth/*.mr synth/*.pvl
	rm -rf simv.vdb
	rm -rf cm.log
	rm -rf urgReport

Robin:
	git config user.name "xiongrob"
	git config user.email "62448777+xiongrob@users.noreply.github.com"