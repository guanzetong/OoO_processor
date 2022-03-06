#!/bin/bash

# Author: Xinhao Sun
# bash script for generating groudtruth output

# define linker
ASLINKERS='aslinker.lds'
LINKERS='linker.lds'
# define assemble flags
ASFLAGS='-mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -Wno-main -mstrict-align'
# define c flags
CFLAGS='-mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -std=gnu11 -mstrict-align -mno-div'
# define o flags
OFLAGS='-O0'
CRT='crt.s'
# define gcc
GCC='riscv gcc'
# define program changing elf to hex
ELF2HEX='riscv elf2hex'
# define VCS command
VCS='vcs -V -sverilog +vc -Mupdate -line -full64 +vcs+vcdpluson -debug_access+all'
# define testbench
TESTBENCH='sys_defs.svh ISA.svh testbench/mem.sv testbench/testbench.sv testbench/pipe_print.c'
# define simulation files
SIMFILES='verilog/pipeline.sv verilog/regfile.sv verilog/if_stage.sv verilog/id_stage.sv verilog/ex_stage.sv verilog/mem_stage.sv verilog/wb_stage.sv'
SYNFILES='synth/pipeline.vg'
LIB='/afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v'

# # generate output of all assebly language files in test_progs folder
# for SOURCE in test_progs/*.s; do
#     # get sour_name from the path
#     SOURCE_NAME=$(echo $SOURCE | cut -d'.' -f1)
#     SOURCE_NAME=$(echo $SOURCE_NAME | cut -d'/' -f2)
#     # use gcc to generate compiled program
#     $GCC $ASFLAGS $SOURCE -T $ASLINKERS -o program.elf
#     # change the compiled program to a memory file
#     $ELF2HEX 8 8192 program.elf > program.mem
#     # use VCS to generate simulation program
# 	$VCS $TESTBENCH $SIMFILES -o simv
#     # runt the simulation program
#     ./simv | tee program.out
#     # move the program output to output folder
#     mv program.out $SOURCE_NAME-program.out
#     mv $SOURCE_NAME-program.out output
#     # move the writeback to output folder
#     mv writeback.out $SOURCE_NAME-writeback.out
#     mv $SOURCE_NAME-writeback.out output
# done

# for SOURCE in test_progs/*.c; do
#     # get sour_name from the path
#     SOURCE_NAME=$(echo $SOURCE | cut -d'.' -f1)
#     SOURCE_NAME=$(echo $SOURCE_NAME | cut -d'/' -f2)

#     # use gcc to generate compiled program
#     $GCC $CFLAGS $OFLAGS $CRT $SOURCE -T $LINKERS -o program.elf
#     # change the compiled program to a memory file
#     $ELF2HEX 8 8192 program.elf > program.mem
#     # use VCS to generate simulation program
# 	$VCS $TESTBENCH $SIMFILES -o simv
#     # runt the simulation program
#     ./simv | tee program.out
#     # move the program output to output folder
#     mv program.out $SOURCE_NAME-program.out
#     mv $SOURCE_NAME-program.out output
#     # move the writeback to output folder
#     mv writeback.out $SOURCE_NAME-writeback.out
#     mv $SOURCE_NAME-writeback.out output
# done



# generate output of all assebly language files in test_progs folder
# for SOURCE in test_progs/*.s; do
#     # get sour_name from the path
#     SOURCE_NAME=$(echo $SOURCE | cut -d'.' -f1)
#     SOURCE_NAME=$(echo $SOURCE_NAME | cut -d'/' -f2)
#     # use gcc to generate compiled program
#     $GCC $ASFLAGS $SOURCE -T $ASLINKERS -o program.elf
#     # change the compiled program to a memory file
#     $ELF2HEX 8 8192 program.elf > program.mem
#     # use VCS to generate simulation program
# 	$VCS $TESTBENCH $SYNFILES $LIB -o simv
#     # runt the simulation program
#     ./simv | tee program.out
#     # move the program output to output folder
#     mv program.out $SOURCE_NAME-program.out
#     mv $SOURCE_NAME-program.out output
#     # move the writeback to output folder
#     mv writeback.out $SOURCE_NAME-writeback.out
#     mv $SOURCE_NAME-writeback.out output
# done

for SOURCE in test_progs/*.c; do
    # get sour_name from the path
    SOURCE_NAME=$(echo $SOURCE | cut -d'.' -f1)
    SOURCE_NAME=$(echo $SOURCE_NAME | cut -d'/' -f2)
    echo $SOURCE_NAME
    # use gcc to generate compiled program
    $GCC $CFLAGS $OFLAGS $CRT $SOURCE -T $LINKERS -o program.elf
    # change the compiled program to a memory file
    $ELF2HEX 8 8192 program.elf > program.mem
    rm program.elf
    # use VCS to generate simulation program
	$VCS $TESTBENCH $SYNFILES $LIB -o simv
    # runt the simulation program
    ./simv | tee program.out
    # move the program output to output folder
    mv program.out $SOURCE_NAME-program.out
    mv $SOURCE_NAME-program.out output
    # move the writeback to output folder
    mv writeback.out $SOURCE_NAME-writeback.out
    mv $SOURCE_NAME-writeback.out output
done