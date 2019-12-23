module top
(
  input clk_25mhz,
  output [3:0] gpdi_dp, gpdi_dn,
  output wifi_gpio0,
  input wire ftdi_txd,
  output wire usb_fpga_pu_dp, usb_fpga_pu_dn,
  input wire usb_fpga_dp, usb_fpga_dn,
  output [7:0] led
);

  assign wifi_gpio0 = 1'b1;
  /* assign led = 8'h00; */

  wire [23:0] color;
  wire [9:0] x;
  wire [9:0] y;

  // framebuffer
  reg [7:0] mem [0:2400];
  parameter BOOT_SIZE = 479;
  reg [7:0] boot [0:BOOT_SIZE];
  reg [9:0] boot_char;
  reg pop;

  // ~500 kHz tick
  wire cursor_blink;
  reg [22:0] clk_500khz;
  reg [1:0] cursor_on;
  assign cursor_blink = &clk_500khz;

  wire boot_up;
  assign boot_up = (boot_char < BOOT_SIZE);

  integer k;

  initial
  begin
    $readmemh("wt-220-header.mem", boot);
    for (k = 0; k < 2400; k = k + 1) begin
      mem[k] <= 32;
    end
  end


  wire rx_valid;
  wire locked;

  wire [7:0] uart_out;

  uart_rx uart(
    .clk(clk_25mhz),
    .resetn(locked),

    .ser_rx(ftdi_txd),

    .cfg_divider(25000000/115200),

    .data(uart_out),
    .valid(rx_valid)
  );

  wire [11:0] pos;
  // char cords to place next char
  reg [6:0] p_x;
  reg [4:0] p_y;

  reg valid;
  reg [7:0] display_char;
  reg [7:0] display_data;

  assign pos = p_x + p_y*80;

  always @(posedge clk_25mhz) begin
    // put char in memory
    if (valid) begin
      mem[pos] <= display_char;
    // blink cursor
    end else if (cursor_blink) begin
      mem[pos] <= cursor_on ? 8'd95 : 8'd32;
      cursor_on <= !cursor_on;
    end
    display_data <= mem[(y >> 4) * 80 + (x>>3)];
    clk_500khz <= clk_500khz + 1;
  end

  reg [1:0] state;

  always @(posedge clk_25mhz) begin
      if (!locked) begin
        state <= 2;
        p_x <= 0;
        p_y <= 0;
        valid <= 0;
        boot_char <= 0;
        pop <= 0;
      end else begin
        case (state)
          0: begin  // receiving char
            if (rx_valid) begin
              if (uart_out == 8'd13) begin// CR
                if (p_y < 29) begin
                  p_y <= p_y +1;
                end else begin
                  state <= 3;
                  p_y <= 0;
                end
              end else if (uart_out == 8'd10) begin  // LF
                p_x <= 0;
              end else begin
                valid <= 1;
                display_char <= uart_out;
                state <= 1;
              end
            end
          end
          1: begin  // display char
            if (p_x < 79) begin
              p_x <= p_x + 1;
              if (pop) state <= 3;
              else if (boot_up) state <= 2;
              else state <= 0;
            end else begin
              // less than max lines
              if (p_y < 29) begin
                p_y <= p_y + 1;
                p_x <= 0;
                if (pop) state <= 3;
                else if (boot_up) state <= 2;
                else state <= 0;
              end else begin
                // if popping, it's done so return to rx state
                if (pop) begin
                  p_y <= 0;
                  pop <= 0;
                  state <= 0;
                // otherwise start popping
                end else begin
                  state <= 3;
                  p_y <= 0;
                end
                p_x <= 0;
              end
            end
            valid <= 0;
          end
          2: begin // print char buffer
            if (boot_up) begin
              if (boot[boot_char] == 8'd13) begin// CR
                p_y <= (p_y < 29) ? p_y + 1 : 0;
              end else if (boot[boot_char] == 8'd10) begin // LFCR
                p_y <= (p_y < 29) ? p_y + 1 : 0;
                p_x <= 0;
              end else begin
                valid <= 1;
                display_char <= boot[boot_char];
                state <= 1;
              end
              boot_char <= boot_char + 1;
            end else begin
              state <= 0;
            end
          end
          3: begin
            display_char <= 8'd32;
            valid <= 1;
            pop <= 1;
            state <= 1;
          end
      endcase
    end
  end

  wire [7:0] data_out;

  font_rom vga_font(
    .clk(clk_25mhz),
    .addr({display_data, y[3:0] }),
    .data_out(data_out)
  );

  assign color = data_out[7-x[2:0]+1] ? 24'h00ff00 : 24'h000000; // +1 for sync

  hdmi_video hdmi_video
  (
    .clk_25mhz(clk_25mhz),
    .x(x),
    .y(y),
    .color(color),
    .gpdi_dp(gpdi_dp),
    .gpdi_dn(gpdi_dn),
    .clk_locked(locked)
  );

  // enable pull ups on both D+ and D-
  assign usb_fpga_pu_dp = 1'b1;
  assign usb_fpga_pu_dn = 1'b1;

  wire ps2clk  = usb_fpga_dp;
  wire ps2data = usb_fpga_dn;
  wire [7:0] ps2char;

  ps2kbd kbd(clk_25mhz, ps2clk, ps2data, led, , );

endmodule
