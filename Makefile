PROJECT_NAME = WT-220-FPGA

TOOLCHAIN_PATH = ~/.apio/packages
YOSYS_ECP5 = $(TOOLCHAIN_PATH)/toolchain-yosys/share/yosys/ecp5
# YOSYS = $(TOOLCHAIN_PATH)/toolchain-yosys/bin/yosys
YOSYS := $(shell which yosys)
NEXTPNR = $(TOOLCHAIN_PATH)/toolchain-ecp5/bin/nextpnr-ecp5
ECPPACK = $(TOOLCHAIN_PATH)/toolchain-ecp5/bin/ecppack
UJPROG = $(TOOLCHAIN_PATH)/toolchain-ecp5/bin/ujprog
LIBTRELLIS = ~/Projects/scratch/prjtrellis/libtrellis

TOP_MODULE_FILE = top.v
VERILOG_TESTBENCH = top_tb.v

VERILOG_FILES := $(wildcard *.v)
VERILOG_FILES := $(filter-out $(VERILOG_TESTBENCH), $(VERILOG_FILES))

VERILOG_ECP5_FILES = \
  $(YOSYS_ECP5)/cells_sim.v \
  $(YOSYS_ECP5)/cells_bb.v

VERILOG_SOURCE := $(VERILOG_FILES) $(VERILOG_ECP5_FILES)

.PHONY: sim clean

all: $(PROJECT_NAME).bit

upload: $(PROJECT_NAME).flash

sim: top.vvp
	vvp top.vvp
	rm top.vvp

%.vvp: %_tb.v $(VERILOG_SOURCE) $(VERILOG_TESTBENCH)
	iverilog -B "/home/john/.apio/packages/toolchain-iverilog/lib/ivl" -D VCD_OUTPUT=$(basename $<) $(VERILOG_TESTBENCH) $(VERILOG_SOURCE) -o $@

%.json: $(VERILOG_FILES)
	$(YOSYS) \
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

clean:
	rm -v *.config *.bit .*.d *.svf *.json
-include .*.d
