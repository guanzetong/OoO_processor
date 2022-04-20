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

# SOURCE = test_progs/alexnet.c
# SOURCE = test_progs/rv32_mult_no_lsq.s
SOURCE = test_progs/rv32_mult.s
# SOURCE = test_progs/rv32_halt.s
# SOURCE = test_progs/rv32_parallel.s
# SOURCE = test_progs/sampler.s
# SOURCE = test_progs/rv32_btest1.s
# SOURCE = test_progs/rv32_fib_rec.s
# SOURCE = test_progs/backtrack.c
# SOURCE = test_progs/matrix_mult_rec.c
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
# TESTBENCH   = $(wildcard testbench/*.sv)
# TESTBENCH  += $(wildcard testbench/*.c)
# TESTBENCH	= testbench/RS_tb.sv
# TESTBENCH	= testbench/test_tb.sv
# TESTBENCH	= testbench/adder_tb.sv
# TESTBENCH	= testbench/pe_mult_tb.sv
# TESTBENCH	= testbench/IB_tb.sv
TESTBENCH	= testbench/pipeline_ss_smt_tb.sv
# TESTBENCH	= testbench/IF_IC_tb.sv
PIPEFILES   = $(wildcard verilog/*.sv)
# PIPEFILES   = $(wildcard dcache/*.sv)
# PIPEFILES	= verilog/IF.sv
# TESTBENCH	= testbench/cache_test.sv
# TESTBENCH	= testbench/cache_tb.sv
TESTBENCH	+= testbench/mem.sv
# TESTBENCH	+= $(wildcard verilog/*.sv)
# PIPEFILES   = $(wildcard verilog/*.sv)
# PIPEFILES	= verilog/binary_encoder.sv verilog/pe.sv verilog/pe_mult.sv verilog/COD.sv verilog/RS.sv
# PIPEFILES	= verilog/IB.sv verilog/IB_channel.sv verilog/IB_push_in_router.sv verilog/IB_queue.sv verilog/IB_pop_out_router.sv
# PIPEFILES	= verilog/IB.sv 
# PIPEFILES	+= verilog/IB_ALU_push_in_router.sv verilog/IB_ALU_queue.sv verilog/IB_ALU_pop_out_router.sv verilog/IB_ALU.sv
# PIPEFILES	+= verilog/IB_MULT_push_in_router.sv verilog/IB_MULT_queue.sv verilog/IB_MULT_pop_out_router.sv verilog/IB_MULT.sv
# PIPEFILES	+= verilog/IB_BR_push_in_router.sv verilog/IB_BR_queue.sv verilog/IB_BR_pop_out_router.sv verilog/IB_BR.sv
# PIPEFILES	+= verilog/IB_LOAD_push_in_router.sv verilog/IB_LOAD_queue.sv verilog/IB_LOAD_pop_out_router.sv verilog/IB_LOAD.sv
# PIPEFILES	+= verilog/IB_STORE_push_in_router.sv verilog/IB_STORE_queue.sv verilog/IB_STORE_pop_out_router.sv verilog/IB_STORE.sv 

# PIPEFILES	= verilog/cache_mem.sv verilog/cache_ctrl.sv verilog/cache.sv
# PIPEFILES   += verilog/LRU_update.sv verilog/mshr_entry_ctrl.sv verilog/mshr_cache_mem_switch.sv
# PIPEFILES	+= verilog/mshr_dispatch_selector.sv verilog/mshr_hit_detector.sv verilog/evict_hit_detector.sv
# PIPEFILES	+= verilog/mshr_memory_switch.sv verilog/mshr_proc_switch.sv verilog/mshr_rr_arbiter.sv
# PIPEFILES	= verilog/freelist.sv
SIMFILES    = $(PIPEFILES)

# SYNTHESIS CONFIG
SYNTH_DIR = ./synth

export HEADERS
export PIPEFILES

# export PIPELINE_NAME = pipeline
# export PIPELINE_NAME = RS
# export PIPELINE_NAME = binary_encoder
# export PIPELINE_NAME = adder
# export PIPELINE_NAME = pe_mult
export PIPELINE_NAME = pipeline_ss_smt
# export PIPELINE_NAME = IF
# export PIPELINE_NAME = cache
# export PIPELINE_NAME = dcache

PIPELINE  = $(SYNTH_DIR)/$(PIPELINE_NAME).vg 
SYNFILES  = $(PIPELINE) $(SYNTH_DIR)/$(PIPELINE_NAME)_svsim.sv


# CACHE_NAME	=	cache
# export CACHEFILES
# export CACHE_NAME
# CACHE     = $(SYNTH_DIR)/$(CACHE_NAME).vg 
# SYNFILES  = $(CACHE) $(SYNTH_DIR)/$(CACHE_NAME)_svsim.sv

# Data Cache
DCACHE_NAME	= dcache
export DCACHE_NAME
DCACHE_FILES = verilog/dcache_mem.sv verilog/cache_ctrl.sv verilog/dcache.sv
DCACHE_FILES += verilog/dcache_LRU_update.sv verilog/mshr_entry_ctrl.sv verilog/mshr_cache_mem_switch.sv
DCACHE_FILES += verilog/mshr_dispatch_selector.sv verilog/mshr_hit_detector.sv verilog/evict_hit_detector.sv
DCACHE_FILES += verilog/mshr_memory_switch.sv verilog/mshr_proc_switch.sv verilog/mshr_rr_arbiter.sv
export DCACHE_FILES
DCACHE = $(SYNTH_DIR)/$(DCACHE_NAME).ddc

# Instruction Cache
ICACHE_NAME = icache
export ICACHE_NAME
ICACHE_FILES = verilog/icache_mem.sv verilog/cache_ctrl.sv verilog/icache.sv
ICACHE_FILES += verilog/icache_LRU_update.sv verilog/mshr_entry_ctrl.sv verilog/mshr_cache_mem_switch.sv
ICACHE_FILES += verilog/mshr_dispatch_selector.sv verilog/mshr_hit_detector.sv verilog/evict_hit_detector.sv
ICACHE_FILES += verilog/mshr_memory_switch.sv verilog/mshr_proc_switch.sv verilog/mshr_rr_arbiter.sv
export ICACHE_FILES
ICACHE = $(SYNTH_DIR)/$(ICACHE_NAME).ddc

# Reorder Buffer
ROB_NAME = ROB
export ROB_NAME
ROB_FILES = verilog/$(ROB_NAME).sv
export ROB_FILES
ROB_TESTBENCH = testbench/ROB_tb_2.sv
ROB = $(SYNTH_DIR)/$(ROB_NAME).ddc

# Reservation Station
RS_NAME = RS
export RS_NAME
RS_FILES = verilog/$(RS_NAME).sv
export RS_FILES
RS_TESTBENCH = testbench/RS_tb.sv
RS = $(SYNTH_DIR)/$(RS_NAME).ddc

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
IB_TESTBENCH = IB_tb.sv
IB = $(SYNTH_DIR)/$(IB_NAME).ddc

#FL_smt
FL_SMT_NAME = FL_smt
export FL_SMT_NAME


# Passed through to .tcl scripts:
export CLOCK_NET_NAME = clk_i
export RESET_NET_NAME = rst_i
export CLOCK_PERIOD   = 15	# TODO: You will need to make match SYNTH_CLOCK_PERIOD in sys_defs
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

$(PIPELINE): $(SIMFILES) $(SYNTH_DIR)/$(PIPELINE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(PIPELINE_NAME).tcl | tee $(PIPELINE_NAME)_synth.out
	echo -e -n 'H\n1\ni\n`timescale 1ns/100ps\n.\nw\nq\n' | ed $(PIPELINE)

$(CACHE): $(SIMFILES) $(SYNTH_DIR)/$(CACHE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(CACHE_NAME).tcl | tee $(CACHE_NAME)_synth.out
	echo -e -n 'H\n1\ni\n`timescale 1ns/100ps\n.\nw\nq\n' | ed $(CACHE)


syn:	syn_simv 
	./syn_simv | tee syn_program.out

syn_simv:	$(HEADERS) $(SYNFILES) $(TESTBENCH)
	$(VCS) $^ $(LIB) +define+SYNTH_TEST -o syn_simv 

.PHONY: syn

$(DCACHE): $(HEADERS) $(DCACHE_FILES) $(SYNTH_DIR)/$(DCACHE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(DCACHE_NAME).tcl | tee $(DCACHE_NAME)_synth.out

$(ICACHE): $(HEADERS) $(ICACHE_FILES) $(SYNTH_DIR)/$(ICACHE_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(ICACHE_NAME).tcl | tee $(ICACHE_NAME)_synth.out

$(ROB): $(HEADERS) $(ROB_FILES) $(SYNTH_DIR)/$(ROB_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(ROB_NAME).tcl | tee $(ROB_NAME)_synth.out

$(RS): $(HEADERS) $(RS_FILES) $(SYNTH_DIR)/$(RS_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(RS_NAME).tcl | tee $(RS_NAME)_synth.out

$(IB): $(HEADERS) $(IB_FILES) $(SYNTH_DIR)/$(IB_NAME).tcl
	cd $(SYNTH_DIR) && dc_shell-t -f ./$(IB_NAME).tcl | tee $(IB_NAME)_synth.out

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