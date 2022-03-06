#!/bin/bash

# Author: Xinhao Sun
# bash script for comparing output with groudtruth output
# flag for pass or fail
TEST_PASS=1
# compare output of all asemble programs
for SOURCE in test_progs/*.c; do
    # get sour_name from the path
    SOURCE_NAME=$(echo $SOURCE | cut -d'.' -f1)
    SOURCE_NAME=$(echo $SOURCE_NAME | cut -d'/' -f2)
    # get the difference between writeback files
    DIFF=$(diff output/$SOURCE_NAME-writeback.out groundtruth_output/$SOURCE_NAME-writeback.out)
    # test if writeback files are exactly same
    if [[ $DIFF != "" ]]; then
        # writeback files should be exactly same
        TEST_PASS=0
        # print the difference
        echo "IN $SOURCE_NAME-writeback.out"
        # diff output/$SOURCE_NAME-writeback.out groundtruth_output/$SOURCE_NAME-writeback.out
    fi
    # get the difference between program output, only consider lines with @@@
    DIFF=$(diff output/$SOURCE_NAME-program.out groundtruth_output/$SOURCE_NAME-program.out | grep '@@@')
    # test if lines with @@@ are exactly same
    if [[ $DIFF =~ '@@@' ]]; then
        # lines with @@@ should be exactly same
        TEST_PASS=0
        # print the difference
        echo "IN $SOURCE_NAME-program.out"
        # diff output/$SOURCE_NAME-program.out groundtruth_output/$SOURCE_NAME-program.out | grep '@@@'
    fi
done

for SOURCE in test_progs/*.c; do
    # get sour_name from the path
    SOURCE_NAME=$(echo $SOURCE | cut -d'.' -f1)
    SOURCE_NAME=$(echo $SOURCE_NAME | cut -d'/' -f2)
    # get the difference between writeback files
    DIFF=$(diff output/$SOURCE_NAME-writeback.out groundtruth_output/$SOURCE_NAME-writeback.out)
    # test if writeback files are exactly same
    if [[ $DIFF != "" ]]; then
        # writeback files should be exactly same
        TEST_PASS=0
        # print the difference
        echo "IN $SOURCE_NAME-writeback.out"
        # diff output/$SOURCE_NAME-writeback.out groundtruth_output/$SOURCE_NAME-writeback.out
    fi
    # get the difference between program output, only consider lines with @@@
    DIFF=$(diff output/$SOURCE_NAME-program.out groundtruth_output/$SOURCE_NAME-program.out | grep '@@@')
    # test if lines with @@@ are exactly same
    if [[ $DIFF =~ '@@@' ]]; then
        # lines with @@@ should be exactly same
        TEST_PASS=0
        # print the difference
        echo "IN $SOURCE_NAME-program.out"
        # diff output/$SOURCE_NAME-program.out groundtruth_output/$SOURCE_NAME-program.out | grep '@@@'
    fi
done
# print if pass or fail
if [ $TEST_PASS = 1 ]; then
    echo "passed"
else
    echo "failed"
fi