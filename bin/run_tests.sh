#!/bin/bash

# text
green="\e[32m"
red="\e[31m"
DONE="\e[0m"

# Must declare function first before you can call it.
# Assembles given file. Uses indirection to change test_progs/sampler.s to 
# $file and runs make compile through it.
function assemble( ) {
	# Arguments (filename w/o extension, Source-file name)
	file="$1" 
	SOURCE="$2" # Name of source file
	echo "Assembling $file"
	cp "$SOURCE" test_progs/sampler.s
	#cp "$SOURCE" project-v-open-beta/test_progs/sampler.s
	#cat project-v-open-beta/test_progs/sampler.s

	# Run makefile against compile
	#(cd project-v-open-beta && make assembly)
	make assembly
	# The actual memory portion is finally outputed to program.mem
	echo ""
}

# Executes testbench (now converted to a memory_file (program.mem)
function run( ) {
	file="$1" 
	echo "Running $file"

	# Use makefile to run testcase (make simv)
	#(cd project-v-open-beta && make > /dev/null 2>&1)
	#make > /dev/null 2>&1
	make syn 
	echo ""
}

# Creates a directory if id doesn't already exists
function create_dir( ) {
	dir="$1"
        if [ ! -d $dir ]
        then
        	mkdir -p $dir 
        fi
} # end create_dir( )

# Compares writeback.out and program.out to the correct unoptimized version
# and copies to some known loccation if it isn't for further inspection.
function compare_to_corr( ) {
	file="$1" # The file used
	echo "Comparing output $file."
	test_name="$2"
	corr_output="corrOutput/corr-$test_name"

	# The reasoning of passing in writeback.out and program.out means that
	# this routine is no longer coupled with some filesystem structure (we can run and output anywhere and just compare it to the original (ground truth).
	WRITEBACK="$3"
	PROGRAMOUT="$4"

	# Use a flag to determine whether either writeback.out or program.out differs (should remain 0 if there are no differences).
	failed=0

	# Now look at program.out and writeback.out

	echo "Comparing writeback.out"
	if diff -q "$WRITEBACK" "$corr_output-writeback.out"; then
		echo "writeback.out same"
	else
		failed=1
		echo "${red}Test $file failed...( writeback.out differs )${DONE}"
		create_dir "wrongOutput"
		cp "$WRITEBACK" "wrongOutput/wrong-$test_name-writeback.out"
	fi # end if

	echo "Comparing program.out"

	# Remove any lines not beginning with @@@
	# This is because all other lines are optimization dependent (e.g. CPI).
	cat "$corr_output-program.out" | grep @@@ > temp.txt
        if cat "$PROGRAMOUT" | grep @@@ | diff -q - temp.txt; then
		echo "program.out is the same"
	else
		failed=1
        	echo "${red}Test $file failed...( program.out differs )${DONE}"
		create_dir "wrongOutput"
		cp "$PROGRAMOUT" "wrongOutput/wrong-$test_name-program.out"
	fi # end if

	rm temp.txt

	# If passed...
	if [ $failed -eq 0 ]; then
        	echo -e "${green}Test $file passed!${DONE}"
	fi
} # end compare_to_corr( )

# Remove all wrongOutput
if [ "(ls -A wrongOutput)" ]; then
	rm wrongOutput/*
fi


for file in test_progs/*.s; do
	SOURCE=$file
	#file=$(echo $file | cut -d '.' -f1)
	file=${file%.*} # Remove file extension

	# Always ignore the file used as source
	if [ "$SOURCE" == "test_progs/sampler.s" ]; then
		continue
	fi

	# Assemable testcase
	assemble "$file" "$SOURCE"

	# Exec function
	run "$file"

	# Get the filename without the file extension( .s )
	#test_name=`echo $file | cut -d "/" -f2` # the filename itself (minus the path)
	test_name=$(basename "$file")

	# Compare now to corr_output
	# In this case, we are just going to run the same program (with the same pipeline)
	#echo "@@@ Diff" >> project-v-open-beta/writeback.out
	#echo "@@@ Diff" >> project-v-open-beta/program.out
	#compare_to_corr "$file" "$test_name" "project-v-open-beta/writeback.out" "project-v-open-beta/program.out"
	compare_to_corr "$file" "$test_name" "writeback.out" "syn_program.out"
done

cp bin/sampler_orig.s test_progs/sampler.s
