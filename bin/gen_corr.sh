#!/bin/bash

# text
green="\e[32m"
DONE="\e[0m"

# Must declare function first before you can call it.
# Assembles given file. Uses indirection to change test_progs/sampler.s to 
# $file and runs make compile through it.
function assemble( ) {
	# Arguments (filename w/o extension, Source-file name)
	file="$1" 
	SOURCE="$2" # Name of source file
	echo "Assembling $file"
	cp "$SOURCE" project-v-open-beta/test_progs/sampler.s
	#cat project-v-open-beta/test_progs/sampler.s

	# Run makefile against compile
	(cd project-v-open-beta && make assembly)
	# The actual memory portion is finally outputed to program.mem
	echo ""
}

# Executes testbench (now converted to a memory_file (program.mem)
function run( ) {
	file="$1" 
	echo "Running $file"

	# Use makefile to run testcase (make simv)
	(cd project-v-open-beta && make)
	echo ""
}

# Copies writeback.out file to a known location with a decernable name "testname-writeback.out
# (also program.out to "testname-program.out")
function save_writeback_out( ) {
	# Simply save writeback.out to some known file
	file="$1"
	echo "Saving $file output"

	# Get the assembly_test_name stub and use it to construct a file named
	# corr-$file.out

	#test_name=`echo $file | cut -d "/" -f2`
	test_name=$(basename "${file%.*}") # Get rid of extension and just leave the basename
	test_output="corr-${test_name}"
	
	echo "Copying writeback file for prog $file to $test_output-writeback.out"
	cp project-v-open-beta/writeback.out corrOutput/"${test_output}-writeback.out"
	cp project-v-open-beta/program.out corrOutput/"${test_output}-program.out"
	echo ""
} # end save_writeback_out( )


# Make sure correct_output exists (directory). O.w. create it.
if [ ! -d corrOutput ]
then
	mkdir -p corrOutput
fi

# Beginning of Meaningful Execution
# Iterate through entire directory and execute any assembly (.s) file,
# writing program.out and writeback.out to some known file
for file in test_progs/*.s; do
	SOURCE=$file
	file=$(basename "$file")
	
	# Always ignore the file used as source
	if [ $(basename "$SOURCE") == "sampler.s" ]; then
		echo "Skipping sampler.s"
		continue
	fi

	# Obtain the base testname
	#test_name=`echo $file | cut -d "/" -f2`
	test_name=${file%.*}

	#Intialize two flags used to indicate when we've found the two output file needed.
	prog_exists=0
	wb_exists=0
	exec_test=1 # Start assuming that we will be executing testcase
	
	# Look to see if already exists in 
	echo "$test_name"
	# Checks every file in corrOutput with the beginning of corr-$test_name (should have at most two)
	for corr_out in `find corrOutput -name corr-$test_name-*`; do
		echo "Checking $corr_out"
		if [[ $corr_out =~ "program.out" ]]; then # do a regex (seach for substring)
			prog_exists=1
		elif [[ $corr_out =~ "writeback.out" ]];then
			wb_exists=1
		fi
		# If we find both writeback.out and program.out, we can skip running testcase.
		if [[ prog_exists -eq 1 && wb_exists -eq 1 ]];then
			echo "output for testcase $SOURCE already exists. Skipping execution..."
			exec_test=0
			break
		fi
	done
	echo "Finished"

	# If didn't find
	if [ $exec_test -eq 1 ]; then
	    assemble "$file" "$SOURCE"

	    #Run testcase
	    run "$file"

	    save_writeback_out "$file"
	fi
done

# Replace with original
cp bin/sampler_orig.s project-v-open-beta/test_progs/sampler.s

echo -e "${green}Done generating output!${DONE}"
export -f assemble # export function to be used in testing
export -f run




