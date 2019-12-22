YOSYS_ECP5 = ~/.apio/packages/toolchain-yosys/share/yosys/ecp5
NEXTPNR = ~/.apio/packages/toolchain-ecp5/bin/nextpnr-ecp5
ECPPACK = ~/.apio/packages/toolchain-ecp5/bin/ecppack
UJPROG = ~/.apio/packages/toolchain-ecp5/bin/ujprog
LIBTRELLIS = ~/Projects/scratch/prjtrellis/libtrellis

TOP_MODULE_FILE = top.v
VERILOG_TESTBENCH = top_tb.v

VERILOG_FILES := $(wildcard *.v)
VERILOG_FILES := $(filter-out $(VERILOG_TESTBENCH), $(VERILOG_FILES))

VERILOG_ECP5_FILES = \
  $(YOSYS_ECP5)/cells_sim.v \
  $(YOSYS_ECP5)/cells_bb.v

VERILOG_SOURCE := $(VERILOG_FILES) $(VERILOG_ECP5_FILES)

.PHONY: sim

all: hardware.bit

sim: top_tb.vvp
	vvp top_tb.vvp

%.vvp: %.v
	iverilog -B "/home/john/.apio/packages/toolchain-iverilog/lib/ivl" -D VCD_OUTPUT=$(basename $(VERILOG_TESTBENCH)) $(VERILOG_TESTBENCH) $(VERILOG_SOURCE) -o $@

%.json:
	yosys \
		-p "synth_ecp5 -json $@" \
		-E .$(basename $@).d \
		-q \
		$(VERILOG_FILES)

%.config: %.json
	$(NEXTPNR) \
		--json $< \
		--textcfg $@ \
		--lpf ulx3s.lpf \
		--85k \
		--package CABGA381

%.bit: %.config
	$(ECPPACK) --db /home/john/.apio/packages/toolchain-ecp5/share/trellis/database $< $@

pll_%.v:
	$(LIBTRELLIS)/ecppll \
		-i 25 \
		-o $(subst pll_,,$(basename $@)) \
		-n $(basename $@) \
		-f $@

%.flash: %.bit
	$(UJPROG) $<
%.terminal: %.bit
	$(UJPROG) -t -b 3000000 $<
