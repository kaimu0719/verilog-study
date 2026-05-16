`default_nettype none

module top (
  input  wire clk,
  input  wire rst_n,
  output wire lcd_sck,
  output wire lcd_mosi,
  output wire lcd_dc,
  output wire lcd_rst,
  output wire lcd_cs,
  output wire led
);

  // init_fsm と spi_master を繋ぐ内部信号
  wire        init_spi_start;
  wire [7:0]  init_spi_data;
  wire        init_lcd_dc;
  wire        init_lcd_cs;

  // display_fsm から出る信号
  wire        disp_spi_start;
  wire [7:0]  disp_spi_data;
  wire        disp_lcd_dc;
  wire        disp_lcd_cs;
  wire        disp_done; // デバック用

  wire        spi_start;
  wire [7:0]  spi_data;
  wire        spi_busy;
  wire        init_done;

  assign spi_start = init_done ? disp_spi_start : init_spi_start;
  assign spi_data  = init_done ? disp_spi_data  : init_spi_data;
  assign lcd_dc    = init_done ? disp_lcd_dc    : init_lcd_dc;
  assign lcd_cs    = init_lcd_cs & disp_lcd_cs;

  assign led = ~disp_done;

  init_fsm u_init (
    .clk        (clk),
    .rst_n      (rst_n),
    .lcd_rst    (lcd_rst),
    .lcd_dc     (init_lcd_dc),
    .lcd_cs     (init_lcd_cs),
    .spi_start  (init_spi_start),
    .spi_data   (init_spi_data),
    .spi_busy   (spi_busy),
    .init_done  (init_done)
  );

  display_fsm u_disp (
    .clk        (clk),
    .rst_n      (rst_n),
    .init_done  (init_done), // init_fsmからのトリガ
    .spi_busy   (spi_busy),
    .spi_start  (disp_spi_start),
    .spi_data   (disp_spi_data),
    .lcd_dc     (disp_lcd_dc),
    .lcd_cs     (disp_lcd_cs),
    .disp_done  (disp_done)
  );

  spi_master u_spi (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (spi_start),
    .data_in (spi_data),
    .sclk    (lcd_sck),
    .mosi    (lcd_mosi),
    .cs      (),
    .busy    (spi_busy)
  );
endmodule
