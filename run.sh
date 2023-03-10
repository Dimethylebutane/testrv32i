#!/bin/sh

#import all sources
ghdl -i --workdir=work *.vhdl
#make project
ghdl -m --workdir=work test_bench
#run simulation
ghdl -r --workdir=work test_bench --wave=wave.ghw