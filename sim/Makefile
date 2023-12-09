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

SOURCE = test_progs/alexnet.c

CRT = crt.s
LINKERS = linker.lds
ASLINKERS = aslinker.lds

DEBUG_FLAG = -g
CFLAGS =  -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -std=gnu11 -mstrict-align -mno-div 
OFLAGS = -O0
ASFLAGS = -mno-relax -march=rv32im -mabi=ilp32 -nostartfiles -Wno-main -mstrict-align
OBJFLAGS = -SD -M no-aliases 
OBJCFLAGS = --set-section-flags .bss=contents,alloc,readonly
OBJDFLAGS = -SD -M numeric,no-aliases

##########################################################################
# IF YOU AREN'T USING A CAEN MACHINE, CHANGE THIS TO FALSE OR OVERRIDE IT
CAEN = 1
##########################################################################
ifeq (1, $(CAEN))
	GCC = riscv gcc
	OBJCOPY = riscv objcopy
	OBJDUMP = riscv objdump
	AS = riscv as
	ELF2HEX = riscv elf2hex
else
	GCC = riscv64-unknown-elf-gcc
	OBJCOPY = riscv64-unknown-elf-objcopy
	OBJDUMP = riscv64-unknown-elf-objdump
	AS = riscv64-unknown-elf-as
	ELF2HEX = elf2hex
endif


VCS = SW_VCS=2020.12-SP2-1 vcs -sverilog +vc -Mupdate -line -full64 -kdb -lca -debug_access+all+reverse -cm line+fsm+tgl+branch+assert -xprop=tmerge
LIB = /afs/umich.edu/class/eecs598-002/SAED32/SAED32_EDK/lib/stdcell_rvt/verilog/saed32nm.v

# SIMULATION CONFIG

HEADERS     = $(wildcard *.svh)
TESTBENCH   = $(wildcard testbench/*.sv)
PIPEFILES   = $(wildcard verilog/*.sv)

SIMFILES    = $(PIPEFILES)

# SYNTHESIS CONFIG
SYNTH_DIR = ./synth

export HEADERS
export PIPEFILES

export PIPELINE_NAME = pipeline

PIPELINE  = $(SYNTH_DIR)/$(PIPELINE_NAME).vg 
SYNFILES  = $(PIPELINE) $(SYNTH_DIR)/$(PIPELINE_NAME)_svsim.sv

# Passed through to .tcl scripts:
export CLOCK_NET_NAME = clock
export RESET_NET_NAME = reset
export CLOCK_PERIOD   = 100	# TODO: You will need to make match SYNTH_CLOCK_PERIOD in sys_defs
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
	./simv | tee sim_program.out

simv:	$(HEADERS) $(SIMFILES) $(TESTBENCH)
	$(VCS) $^ -o simv

.PHONY: sim

# Programs

compile: $(CRT) $(LINKERS)
	$(GCC) $(CFLAGS) $(OFLAGS) $(CRT) $(SOURCE) -T $(LINKERS) -o program.elf
	$(GCC) $(CFLAGS) $(DEBUG_FLAG) $(CRT) $(SOURCE) -T $(LINKERS) -o program.debug.elf
assemble: $(ASLINKERS)
	$(GCC) $(ASFLAGS) $(SOURCE) -T $(ASLINKERS) -o program.elf 
	cp program.elf program.debug.elf
disassemble: program.debug.elf
	$(OBJCOPY) $(OBJCFLAGS) program.debug.elf
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

# Debugging

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

verdi:	simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./simv -gui=verdi

verdi_syn:	syn_simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./syn_simv -gui=verdi

verdi_cov:	simv
	./simv -cm line+fsm+tgl+branch+assert
	./simv -gui=verdi -cov -covdir simv.vdb


nuke:	clean
	rm -rf synth/*.vg synth/*.rep synth/*.ddc synth/*.chk synth/*.log synth/*.syn
	rm -rf synth/*.out command.log synth/*.db synth/*.svf synth/*.mr synth/*.pvl







export MK_DESIGN_NAME = pipeline

# CPU core usage, capped at 6
export MK_USE_NUM_CORES = 6

# memory library selection
export MK_MEM_SUFFIX = typ_1d05_25

###########
# recipes #
###########

# all: syn

# syn: 
# 	-mkdir -p logs
# 	dc_shell -f scripts/synth.tcl | tee logs/synth.log
# 	-mkdir -p temp_files
# 	-mv alib-52 temp_files/
# 	-mv *_dclib temp_files/
# 	-mv command.log temp_files/
# 	-mv default.svf temp_files/
# 	-mkdir -p export
# 	-cp -f memory/db/*_${MK_MEM_SUFFIX}_ccs.db export/ 2>>/dev/null

# memgen:
# 	cd memory; ./memgen.sh

clean:
	-rm -rvf temp_files
	-rm -rvf alib-52 temp_files/
	-rm -rvf *_dclib temp_files/
	-rm -rvf command.log temp_files/
	-rm -rvf default.svf temp_files/
	-rm -rvf filenames*log 

	rm -rvf simv* *.daidir csrc vcs.key program.out \
	  syn_simv syn_simv.daidir syn_program.out \
          dve *.vpd *.vcd *.dump ucli.key \
	          DVEfiles/ vdCovLog/ verdi* novas* *fsdb*
