MAKEFLAGS += --silent
SRC=\
	./src/*

help:
	@echo "commands: make [ compile-all / critical-all / libtest-all / milky-all ]"
	@echo "               [ dc-topo-300k / dc-topo-300k-nowire ]"
	@echo "               [ dc-topo-77k / dc-topo-77k-nowire ]"
	@echo "               [ dc-topo-4k / dc-topo-4k-nowire ]"
	@echo "               [ critical-300k / critical-300k-nowire ]"
	@echo "               [ critical-77k / critical-77k-nowire ]"
	@echo "               [ critical-4k / critical-4k-nowire ]"
	@echo "               [ libtest-77k / libtest-4k / libtest-ideal ]"
	@echo "               [ milky-300k / milky-77k / milky-4k / milky-ideal ]"
	@echo "               [ clean ]"


# [ compile / ctritical / libtest / milky ] all
compile-all:
	+make dc-topo-300k
	+make dc-topo-300k-nowire
	+make dc-topo-77k
	+make dc-topo-77k-nowire
	+make dc-topo-4k
	+make dc-topo-4k-nowire

critical-all:
	rm latency_result/*
	+make critical-300k
	+make critical-300k-nowire
	+make critical-77k
	+make critical-77k-nowire
	+make critical-4k
	+make critical-4k-nowire

libtest-all:
	+make libtest-77k
	+make libtest-4k
	+make libtest-ideal

milky-all:
	+make milky-300k
	+make milky-77k
	+make milky-4k
	+make milky-ideal


# logic synthesis (with accurate wire latency)
dc-topo-300k:
	dc_shell -64bit -topo -f dc_compile/logic_synthesis/dc_compile_300k.tcl | tee dc-300k.log
dc-topo-300k-nowire:
	dc_shell -64bit -topo -f dc_compile/logic_synthesis/dc_compile_300k_nowire.tcl | tee dc-300k-nw.log

dc-topo-77k:
	dc_shell -64bit -topo -f dc_compile/logic_synthesis/dc_compile_77k.tcl | tee dc-77k.log
dc-topo-77k-nowire:
	dc_shell -64bit -topo -f dc_compile/logic_synthesis/dc_compile_77k_nowire.tcl | tee dc-77k-nw.log

dc-topo-4k:
	dc_shell -64bit -topo -f dc_compile/logic_synthesis/dc_compile_4k.tcl | tee dc-4k.log
dc-topo-4k-nowire:
	dc_shell -64bit -topo -f dc_compile/logic_synthesis/dc_compile_4k_nowire.tcl | tee dc-4k-nw.log


# Critical-path latency extraction
critical-300k:
	dc_shell -64bit -topo -f dc_compile/critical_path_extraction/critical_path_300k.tcl | tee critical-300k.log
critical-300k-nowire:
	dc_shell -64bit -topo -f dc_compile/critical_path_extraction/critical_path_300k_nowire.tcl | tee critical-300k-nw.log

critical-77k:
	dc_shell -64bit -topo -f dc_compile/critical_path_extraction/critical_path_77k.tcl | tee critical-77k.log
critical-77k-nowire:
	dc_shell -64bit -topo -f dc_compile/critical_path_extraction/critical_path_77k_nowire.tcl | tee critical-77k-nw.log

critical-4k:
	dc_shell -64bit -topo -f dc_compile/critical_path_extraction/critical_path_4k.tcl | tee critical-4k.log
critical-4k-nowire:
	dc_shell -64bit -topo -f dc_compile/critical_path_extraction/critical_path_4k_nowire.tcl | tee critical-4k-nw.log


# Library validation
libtest-77k:
	dc_shell -64bit -topo -f dc_compile/library_validation/dc_lib_test_77k.tcl | tee lib-77k.txt
libtest-4k:
	dc_shell -64bit -topo -f dc_compile/library_validation/dc_lib_test_4k.tcl | tee lib-4k.txt
libtest-ideal:
	dc_shell -64bit -topo -f dc_compile/library_validation/dc_lib_test_ideal.tcl | tee lib-ideal.txt


# Generate milkyway library
# # convert Cadence-style physical library (.lef) to Synopsys-style physical library (milkyway, .tf)
milky-300k:
	Milkyway -galaxy -nogui -tcl -log log.txt -file dc_compile/physical_library_generation/gen_milky_300k.tcl
	mv milky-45nm-300k.tf ./freepdk-45nm/stdview/rtk-tech-300k.tf

milky-77k:
	Milkyway -galaxy -nogui -tcl -log log.txt -file dc_compile/physical_library_generation/gen_milky_77k.tcl
	mv milky-45nm-77k.tf ./freepdk-45nm/stdview/rtk-tech-77k.tf

milky-4k:
	Milkyway -galaxy -nogui -tcl -log log.txt -file dc_compile/physical_library_generation/gen_milky_4k.tcl
	mv milky-45nm-4k.tf ./freepdk-45nm/stdview/rtk-tech-4k.tf

milky-ideal:
	Milkyway -galaxy -nogui -tcl -log log.txt -file dc_compile/physical_library_generation/gen_milky_ideal.tcl
	mv milky-45nm-ideal.tf ./freepdk-45nm/stdview/rtk-tech-ideal.tf


# Clean-up
clean:
	rm -rf *.mr *.sdc *.vh *.v *.syn *.pvl *.max *.min *.sdf *.log WORK_autoread default.svf *.script Milkyway.tcl.* rtk-tech.lef* stdcells.lef.* *.sum alib-52 Milkyway.*.* rtk-tech-* *.txt mw_design_lib_*
