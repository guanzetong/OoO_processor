# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be
# similar to the information in those scripts but that seems hard to avoid.
#
#

SOURCE = test_progs/mult_no_lsq.s

CRT = crt.s
LINKERS = linker.lds
ASLINKERS = aslinker.lds

# added "SW_VCS=2011.03 and "-full64" option -- awdeorio fall 2011
# added "-sverilog" and "SW_VCS=2012.09" option,
#	and removed deprecated Virsim references -- jbbeau fall 2013
# updated library path name -- jbbeau fall 2013

VCS = SW_VCS=2017.12-SP2-1 vcs +v2k -sverilog +vc -Mupdate -line -full64
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
TESTBENCH	= testbench/pipeline_dp_tb.sv
PIPEFILES   = $(wildcard verilog/*.sv)
# PIPEFILES	= verilog/binary_encoder.sv verilog/pe.sv verilog/pe_mult.sv verilog/COD.sv verilog/RS.sv
# PIPEFILES	= verilog/IB.sv verilog/IB_channel.sv verilog/IB_push_in_router.sv verilog/IB_queue.sv verilog/IB_pop_out_router.sv

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
export PIPELINE_NAME = pipeline_dp


PIPELINE  = $(SYNTH_DIR)/$(PIPELINE_NAME).vg 
SYNFILES  = $(PIPELINE) $(SYNTH_DIR)/$(PIPELINE_NAME)_svsim.sv

# Passed through to .tcl scripts:
export CLOCK_NET_NAME = clk_i
export RESET_NET_NAME = rst_i
export CLOCK_PERIOD   = 20	# TODO: You will need to make match SYNTH_CLOCK_PERIOD in sys_defs
                                #       and make this more aggressive

################################################################################
## RULES
################################################################################

# Default target:
all:    simv
	./simv | tee program.out
##### 
# Modify starting here
#####

HEADERS     = $(wildcard *.svh)
TESTBENCH = ./testbench/FU_tb.sv
SIMFILES = ./verilog/FU.sv

sim:	simv
	./simv -cm line+tgl | tee sim_program.out

simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $^ -o simv -cm line+tgl

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


# updated interactive debugger "DVE", using the latest version of VCS
# awdeorio fall 2011
dve:	$(SIMFILES) $(TESTBENCH)
	$(VCS) +memcbk $(TESTBENCH) $(SIMFILES) -o dve -R -gui

syn_simv:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) -o syn_simv

syn:	syn_simv
	./syn_simv | tee syn_program.out

clean:
	rm -rvf simv *.daidir csrc vcs.key program.out \
	  syn_simv syn_simv.daidir syn_program.out \
		  dve *.vpd *.vcd *.dump ucli.key

nuke:	clean
	rm -rf synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/*.log synth/*.syn
	rm -rf synth/*.out command.log synth/*.db synth/*.svf synth/*.mr synth/*.pvl
	rm -rf simv.vdb
	rm -rf cm.log
	rm -rf urgReport

Robin:
	git config user.name "xiongrob"
	git config user.email "62448777+xiongrob@users.noreply.github.com"
