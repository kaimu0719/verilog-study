module display_fsm (
  input  wire      clk,
  input  wire      rst_n,
  input  wire      init_done,

  // spi_masterへの接続
  input  wire      spi_busy,
  output reg       spi_start,
  output reg [7:0] spi_data,

  // 物理ピンへの出力
  output reg       lcd_dc,
  output reg       lcd_cs,

  output reg       disp_done
);

  reg [2:0] state;
  reg [7:0] x_count; // 0..239 (8ビットで足りる、最大239)
  reg [8:0] y_count; // 0..319 (9ビットで足りる、最大319)
  reg       byte_select;

  // 9bit + 4bit = 13bit
  wire [12:0] vram_addr = {y_count[8:0], x_count[7:4]};
  wire [15:0] vram_word; // 16ピクセルのvramデータ

  wire        pixel_bit    = vram_word[x_count[3:0]];
  wire [15:0] pixel_color  = pixel_bit ? 16'hFFFF : 16'h0000;
  wire [7:0]  byte_to_send = byte_select ? pixel_color[7:0] : pixel_color[15:8];

  localparam [2:0] IDLE             = 3'd0;
  localparam [2:0] PIXEL_LOAD       = 3'd1;
  localparam [2:0] PIXEL_SEND       = 3'd2;
  localparam [2:0] PIXEL_WAIT_START = 3'd3;
  localparam [2:0] PIXEL_WAIT_BUSY  = 3'd4;
  localparam [2:0] DONE             = 3'd5;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      spi_start   <= 1'b0;
      lcd_cs      <= 1'b1;
      lcd_dc      <= 1'b0;
      disp_done   <= 1'b0;
      x_count     <= 8'b0;
      y_count     <= 9'b0;
      byte_select <= 1'b0;
      state       <= IDLE;
    end else begin
      case (state)
        IDLE: begin
          if (init_done == 1) begin
            lcd_cs <= 1'b0;
            lcd_dc <= 1'b1;
            state  <= PIXEL_LOAD;
          end
        end

        PIXEL_LOAD: begin
          spi_data <= byte_to_send;
          state    <= PIXEL_SEND;
        end

        PIXEL_SEND: begin
          spi_start <= 1'b1;
          state     <= PIXEL_WAIT_START;
        end

        PIXEL_WAIT_START: begin
          if (spi_busy == 1) begin
            state <= PIXEL_WAIT_BUSY;
          end
        end

        PIXEL_WAIT_BUSY: begin
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            if (byte_select == 0) begin
              // 上位ビット
              byte_select <= 1'b1;
              state       <= PIXEL_LOAD;
            end else begin
              // 下位ビット
              byte_select <= 1'b0;
              x_count     <= x_count + 1;
              if (x_count == 8'd240 - 1) begin
                x_count <= 8'd0;
                y_count <= y_count + 1;
                if (y_count == 9'd320 - 1) begin
                  lcd_cs    <= 1'b1;
                  disp_done <= 1'b1;
                  state     <= DONE;
                end else begin
                  state <= PIXEL_LOAD;
                end
              end else begin
                state <= PIXEL_LOAD;
              end
            end
          end
        end

        DONE: begin
        end
      endcase
    end
  end

endmodule