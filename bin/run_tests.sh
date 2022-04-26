#!/bin/bash

# text
green="\e[32m"
red="\e[31m"
DONE="\e[0m"

# Must declare function first before you can call it.
# Assembles given file. Uses indirection to change test_progs/testSrc.s to 
# $file and runs make compile through it.
function assemble( ) {
	# Arguments (filename w/o extension, Source-file name)
	file="$1" 
	SOURCE="$2" # Name of source file
	echo "Assembling $file"
	cp "$SOURCE" test_progs/testSrc.s
	#cp "$SOURCE" project-v-open-beta/test_progs/testSrc.s
	#cat project-v-open-beta/test_progs/testSrc.s

	# Run makefile against compile
	#(cd project-v-open-beta && make assembly)
	if ! (make assembly); then
		echo "Command make assembly returned some error"
		exit
	fi
	# The actual memory portion is finally outputed to program.mem
	echo ""
}

function compile( ) {
	# Arguments (filename w/o extension, Source-file name)
	file="$1" 
	SOURCE="$2" # Name of source file
	echo "Compiling $file"
	echo "Source name is: $SOURCE"
	cp "$SOURCE" test_progs/testSrc.c
	#cp "$SOURCE" project-v-open-beta/test_progs/testSrc.s
	#cat project-v-open-beta/test_progs/testSrc.s

	# Run makefile against compile
	#(cd project-v-open-beta && make assembly)
	if ! (make program); then
		echo "Command make program returned some error"
		exit
	fi
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
	make -j 8 syn
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

	# echo "Comparing output $file."
	# test_name="$2"
	# corr_output="corrOutput/corr-$test_name"

	# The reasoning of passing in writeback.out and program.out means that
	# this routine is no longer coupled with some filesystem structure (we can run and output anywhere and just compare it to the original (ground truth).
	WRITEBACK="$3"
	PROGRAMOUT="$4"
	cp program.mem ../eecs470_w22_project3_xiongrob/program.mem
	echo "Running groundtruth."
	(cd ../eecs470_w22_project3_xiongrob && make)

	mv ../eecs470_w22_project3_xiongrob/writeback.out corr-$WRITEBACK
	echo "Writing to corr-$WRITEBACK"
	mv ../eecs470_w22_project3_xiongrob/program.out corr-$PROGRAMOUT
	echo "Writing to corr-$PROGRAMOUT"

	

	# Use a flag to determine whether either writeback.out or program.out differs (should remain 0 if there are no differences).
	failed=0

	# Now look at program.out and writeback.out

	echo "Comparing writeback.out"
	if diff -q "$WRITEBACK" "corr-$WRITEBACK"; then
		echo "writeback.out same"
	else
		failed=1
		echo "${red}Test $file failed...( writeback.out differs )${DONE}"
		create_dir "wrongOutput"
		cp "$WRITEBACK" "wrongOutput/wrong-$test_name-writeback.out"
	fi # end if

	echo "Comparing $PROGRAMOUT with corr-$PROGRAMOUT"

	# Remove any lines not beginning with @@@
	# This is because all other lines are optimization dependent (e.g. CPI).
	cat "corr-$PROGRAMOUT" | grep @@@ > temp.txt
        if cat "$PROGRAMOUT" | grep @@@ | diff -q - temp.txt; then
		echo "$PROGRAMOUT is the same"
	else
		failed=1
        	echo "${red}Test $file failed...( $PROGRAMOUT differs )${DONE}"
		create_dir "wrongOutput"
		cp "$PROGRAMOUT" "wrongOutput/wrong-$test_name-program.out"
		#exit
	fi # end if

	rm temp.txt

	# If passed...
	if [ $failed -eq 0 ]; then
        	echo -e "${green}Test $file passed!${DONE}"
	else
		echo -e "${red}Test $file failed...${DONE}"
		exit
	fi
	# Delete writeback to save space
	rm corr-$WRITEBACK
	rm corr-$PROGRAMOUT
} # end compare_to_corr( )

# Remove all wrongOutput
if [ "(ls -A wrongOutput)" ]; then
	rm wrongOutput/*
fi


# Look for all .c and .s files
for file in test_progs/*.{s,c}; do
	SOURCE=$file
	#file=$(echo $file | cut -d '.' -f1)
	file=${file%.*} # Remove file extension

	# Always ignore the file used as source
	if [ "$SOURCE" == "test_progs/testSrc.s" ] || [ "$SOURCE" == "test_progs/testSrc.c" ]; then
		continue
	fi
	if [[ $SOURCE == *.s ]]; then
		# Assemble testcase
		assemble  "$file" "$SOURCE"
	elif [[ $SOURCE == *.c ]]; then
		# Compile testcase
		compile "$file" "$SOURCE"
	else
		echo "$SOURCE is not an executable"
		continue
	fi

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

echo -e "${green}All tests passed!${DONE}"

cp bin/testSrc_orig.s test_progs/testSrc.s
