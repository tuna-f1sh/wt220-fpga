TOP_MODULE_FILE = top.v

YOSYS_ECP5 = /home/john/.apio/packages/toolchain-yosys/share/yosys/ecp5

VERILOG_TESTBENCH = top_tb.v

VERILOG_FILES = \
  $(TOP_MODULE_FILE) \
  clk_25_250_125_25.v \
  fake_differential.v \
  hdmi_video.v \
  tmds_encoder.v \
  vga2dvid.v \
  vga_video.v \
  font_rom.v \
  uart_rx.v

VERILOG_ECP5_FILES = \
  $(YOSYS_ECP5)/cells_sim.v \
  $(YOSYS_ECP5)/cells_bb.v

.PHONY: sim

sim:
	iverilog -B "/home/john/.apio/packages/toolchain-iverilog/lib/ivl" -D VCD_OUTPUT=top_tb $(VERILOG_ECP5_FILES) $(VERILOG_FILES) -o testbench $(VERILOG_TESTBENCH)
	vvp testbench
