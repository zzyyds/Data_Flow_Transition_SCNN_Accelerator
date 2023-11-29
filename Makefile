# make           <- runs simv (after compiling simv if needed)
# make simv      <- compile simv if needed (but do not run)
# make verdi     <- runs GUI debugger (after compiling it if needed)
# make verdi_cov <- runs Verdi in coverage mode
# make syn       <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make clean     <- remove files created during compilations (but not synthesis)
# make nuke      <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
#

VCS = SW_VCS=2020.12-SP2-1 vcs -sverilog +vc -Mupdate -line -full64 -kdb -lca -debug_access+all+reverse -cm line+cond+fsm+tgl+branch+assert

all:    simv
	./simv | tee program.out

##### 
# Modify starting here
#####

TESTBENCH = TB_PE.sv 
SIMFILES = $(wildcard verilog/*.sv)

SYNFILES = PE.vg 
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v


my_waveform_gen.vg:	my_waveform_gen.v my_waveform_gen.tcl 
	dc_shell-t -f my_waveform_gen.tcl | tee synth.out

my_controller.vg:	my_controller.v my_controller.tcl 
	dc_shell-t -f my_controller.tcl | tee synth.out
DFS.vg:	DFS.v DFS.tcl 
	dc_shell-t -f DFS.tcl | tee synth.out




#####
# Should be no need to modify after here
#####

simv:	$(SIMFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SIMFILES)	-o simv

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

verdi:	simv novas.rc
	if [[ ! -d /tmp/$${USER}470 ]] ; then mkdir /tmp/$${USER}470 ; fi
	./simv -gui=verdi

verdi_cov:	simv
	./simv -cm line+cond+fsm+tgl+branch+assert
	./simv -gui=verdi -cov -covdir simv.vdb

syn_simv:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) -o syn_simv

syn:	syn_simv
	./syn_simv | tee syn_program.out

clean:
	rm -rvf simv* *.daidir csrc vcs.key program.out \
	  syn_simv syn_simv.daidir syn_program.out \
          dve *.vpd *.vcd *.dump ucli.key \
	          DVEfiles/ vdCovLog/ verdi* novas* *fsdb*

nuke:	clean
	rm -rvf *.vg *.rep *.db *.chk *.log *.out
