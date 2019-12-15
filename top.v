module top
(
  input clk_25mhz,
  output [3:0] gpdi_dp, gpdi_dn,
  output wifi_gpio0,
  input wire ftdi_txd
);
assign wifi_gpio0 = 1'b1;

wire [23:0] color;
wire [9:0] x;
wire [9:0] y;

// framebuffer
reg [7:0] mem[0:2400];
reg [7:0] boot [0:580];
reg [9:0] boot_char;

// ~500 kHz tick
wire cursor_blink;
reg [22:0] clk_500khz;
reg [1:0] cursor_on;
assign cursor_blink = &clk_500khz;

/* wire boot_up = !((boot_char & 579) == 579); */
reg boot_up;

integer k;

initial
begin
  $readmemh("fpga-wt-220-boot.mem", boot);
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
reg pop;

reg valid;
reg [7:0] display_char;
reg [7:0] display_data;

assign pos = p_x + p_y*80;
integer i;

always @(posedge clk_25mhz) begin
  if (pop) begin
    for (i = 0; i <  2400; i=i+1)
      mem[i] <= i < 2320 ? mem[i+80] : 8'd32;
  end
  // put char in memory
  else if (valid) begin
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

always @(posedge clk_25mhz)
  begin
    if (!locked) begin
      state <= 2;
      p_x <= 0;
      p_y <= 0;
      valid <= 0;
      boot_char <= 0;
      boot_up <= 1;
      pop <= 0;
    end else begin
      case (state)
        0: begin  // receiving char
          if (rx_valid)
            begin
            if (uart_out == 8'd13) begin// CR
              if (p_y < 29)
                p_y <= p_y + 1;
              else begin
                p_y <= 28;
                pop <= 1;
              end
            end else if (uart_out == 8'd10) begin  // LF
              p_x <= 0;
              pop <= 0;
            end else begin
              valid <= 1;
              display_char <= uart_out;
              state <= 1;
              pop <= 0;
            end
          end
        end
        1: begin  // display char
          if (p_x < 79) begin
            p_x <= p_x + 1;
            pop <= 0;
          end else begin
            if (p_y < 29) begin
              p_y <= p_y + 1;
              pop <= 0;
            end else begin
              p_y <= 28;
              pop <= 1;
            end
            p_x <= 0;
          end
          valid <= 0;
          state <= boot_up ? 2 : 0;
        end
        2: begin // print char buffer
          if (boot[boot_char] == 8'd13) begin// CR
            if (p_y < 29)
              p_y <= p_y + 1;
            else begin
              p_y <= 28;
              pop <= 1;
            end
          end else if (boot[boot_char] == 8'd10) begin
            p_y <= p_y + 1;
            p_x <= 0;
            pop <= 0;
          end else begin
            valid <= 1;
            display_char <= boot[boot_char];
            state <= 1;
            pop <= 0;
          end
          boot_char <= boot_up ? boot_char + 1 : 0;
          boot_up <= boot_char < 579 ? 1: 0;
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
endmodule
