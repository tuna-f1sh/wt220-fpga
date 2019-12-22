`timescale 1ns/10ps //Adjust to suit

module tb_top;

reg clk_25mhz;
reg ftdi_txd;
wire [3:0] gpdi_dp, gpdi_dn;
wire wifi_gpio0;
reg rst;
wire [7:0] led;

wire usb_dp, usb_dn;
wire usb_pu_dp, usb_pu_dn;

top uut (
  .clk_25mhz(clk_25mhz),
  .gpdi_dp(gpdi_dp),
  .gpdi_dn(gpdi_dn),
  .wifi_gpio0(wifi_gpio0),
  .ftdi_txd(ftdi_txd),
  .usb_fpga_pu_dp(usb_pu_dp),
  .usb_fpga_pu_dn(usb_pu_dn),
  .usb_fpga_dp(usb_dp),
  .usb_fpga_dn(usb_dn),
  .led(led)
);

parameter PERIOD = 5; //adjust for your timescale

initial begin
  $dumpfile("tb_output.vcd");
  /* $dumpvars(2, tb_top); */
  $dumpvars;
  clk_25mhz = 1'b0;
  ftdi_txd = 1'b0;
  /* usb_dp = 1'b0; */
  /* usb_dn = 1'b0; */
  /* usb_pu_dp = 1'b0; */
  /* usb_pu_dn = 1'b0; */
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
  #(PERIOD * 2000) 
  $finish;
end

endmodule
