#!/bin/csh -f

cd /afs/umich.edu/user/s/t/stzzzy/eecs470/group6w22

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/usr/caen/vcs-2020.12-SP2-1/linux64/bin/vcselab $* \
    -o \
    syn_simv \
    -nobanner \

cd -

