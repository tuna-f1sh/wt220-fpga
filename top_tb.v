`timescale 1ns/10ps //Adjust to suit

module tb_top;

reg clk_25mhz;
reg ftdi_txd;
wire[3:0] gpdi_dp;
wire wifi_gpio0;
reg rst;

top uut (
  .clk_25mhz(clk_25mhz),
  .gpdi_dp(gpdi_dp),
  .ftdi_txd(ftdi_txd),
  .wifi_gpio0(wifi_gpio0)
);

parameter PERIOD = 5; //adjust for your timescale

initial begin
  $dumpfile("tb_output.vcd");
  $dumpvars(2, tb_top);
  clk_25mhz = 1'b0;
  ftdi_txd = 1'b0;
  #(PERIOD/2);
  forever
    #(PERIOD/2) clk_25mhz = ~clk_25mhz;
end

initial begin
  rst=1'b0;
  #(PERIOD*2) rst=~rst;
  #PERIOD rst=~rst;
end

initial begin
  #(PERIOD * 500) 
  $finish;
end

endmodule
