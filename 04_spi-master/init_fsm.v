`default_nettype none

module init_fsm (
  input  wire        clk,
  input  wire        rst_n,
  
  // 物理ピンへの出力
  output reg         lcd_rst,
  output reg         lcd_dc,
  output reg         lcd_cs,
  
  // spi_master への接続
  output reg         spi_start,
  output reg [7:0]   spi_data,
  input  wire        spi_busy,
  
  // 完了フラグ(任意、デバッグ用)
  output reg         init_done
);

  localparam [21:0] WAIT_5MS   = 22'd135_000;
  localparam [21:0] WAIT_120MS = 22'd3_240_000;

  localparam ROM_SIZE = 18;

  // 状態定義(4ビットあれば10状態を表現できる: 2^4=16)
  localparam [3:0] S_RESET_LOW        = 4'd0;
  localparam [3:0] S_RESET_HIGH       = 4'd1;
  localparam [3:0] S_LOAD             = 4'd2;
  localparam [3:0] S_SEND             = 4'd3;
  localparam [3:0] S_WAIT_START       = 4'd4;
  localparam [3:0] S_WAIT_BUSY        = 4'd5;
  localparam [3:0] S_WAIT_TIMING      = 4'd6;
  localparam [3:0] S_DONE             = 4'd7;

  reg [30:0] cmd_rom [0:ROM_SIZE-1];
  initial begin
    // dc, data, wait_time
    cmd_rom[ 0] = {1'b0, 8'h01, WAIT_5MS}; // SWRESET
    cmd_rom[ 1] = {1'b0, 8'h11, WAIT_120MS}; // SLPOUT
    cmd_rom[ 2] = {1'b0, 8'h3A, 22'd0}; // COLMODコマンド
    cmd_rom[ 3] = {1'b1, 8'h55, 22'd0}; // COLMODデータ 16bpp (RGB565)
    cmd_rom[ 4] = {1'b0, 8'h36, 22'd0}; // MADCTLコマンド
    cmd_rom[ 5] = {1'b1, 8'h48, 22'd0}; // MADCTLデータ
    cmd_rom[ 6] = {1'b0, 8'h2A, 22'd0}; // CASETコマンド
    cmd_rom[ 7] = {1'b1, 8'h00, 22'd0}; // x_start_h
    cmd_rom[ 8] = {1'b1, 8'h00, 22'd0}; // x_start_l
    cmd_rom[ 9] = {1'b1, 8'h00, 22'd0}; // x_end_h
    cmd_rom[10] = {1'b1, 8'hEF, 22'd0}; // x_end_l
    cmd_rom[11] = {1'b0, 8'h2B, 22'd0}; // PASETコマンド
    cmd_rom[12] = {1'b1, 8'h00, 22'd0}; // y_start_h
    cmd_rom[13] = {1'b1, 8'h00, 22'd0}; // y_start_l
    cmd_rom[14] = {1'b1, 8'h01, 22'd0}; // y_end_h
    cmd_rom[15] = {1'b1, 8'h3F, 22'd0}; // y_end_l
    cmd_rom[16] = {1'b0, 8'h29, 22'd0}; // DISPON
    cmd_rom[17] = {1'b0, 8'h2C, 22'd0}; // RAMWR
  end

  reg [3:0]  state;
  reg [21:0] wait_counter;
  reg [4:0]  index;
  reg [21:0] current_wait_count;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lcd_rst            <= 1'b0;
      lcd_dc             <= 1'b0;
      lcd_cs             <= 1'b1;
      spi_start          <= 1'b0;
      spi_data           <= 8'b0000_0000;
      state              <= S_RESET_LOW;
      init_done          <= 1'b0;
      index              <= 5'b0000;
      current_wait_count <= 22'd0;
      wait_counter       <= 22'd0;
    end else begin
      case (state)
        S_RESET_LOW: begin
          if (wait_counter == WAIT_120MS - 1) begin
            state        <= S_RESET_HIGH;
            lcd_rst      <= 1'b1;
            wait_counter <= 22'b0;
          end else begin
            wait_counter <= wait_counter + 1;
          end
        end

        S_RESET_HIGH: begin
          if (wait_counter == WAIT_120MS - 1) begin
            state        <= S_LOAD;
            wait_counter <= 22'b0;
            lcd_cs       <= 1'b0;
            index        <= 5'b0000;
          end else begin
            wait_counter <= wait_counter + 1;
          end
        end

        S_LOAD: begin
          lcd_dc             <= cmd_rom[index][30];
          spi_data           <= cmd_rom[index][29:22];
          current_wait_count <= cmd_rom[index][21:0];
          state              <= S_SEND;
        end

        S_SEND: begin
          spi_start <= 1'b1;
          state     <= S_WAIT_START;
        end

        S_WAIT_START: begin
          if (spi_busy == 1) begin
            state <= S_WAIT_BUSY;
          end
        end

        S_WAIT_BUSY: begin
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            if (current_wait_count == 0) begin
              index <= index + 1;
              if (index == ROM_SIZE-1) begin
                state <= S_DONE;
              end else begin
                state <= S_LOAD;
              end
            end else begin
              state <= S_WAIT_TIMING;
            end
          end
        end

        S_WAIT_TIMING: begin
          if (wait_counter == current_wait_count) begin
            wait_counter <= 0;
            index        <= index + 1;
            if (index == ROM_SIZE-1) begin
              state <= S_DONE;
            end else begin
              state <= S_LOAD;
            end
          end else begin
            wait_counter <= wait_counter + 1;
          end
        end

        S_DONE: begin
          init_done <= 1'b1;
        end
      endcase
    end
  end

endmodule
