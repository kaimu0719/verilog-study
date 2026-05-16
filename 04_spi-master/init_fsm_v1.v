`default_nettype none

module init_fsm (
  input  wire        clk,
  input  wire        rst_n,
  
  // 物理ピンへの出力
  output reg         lcd_rst,
  output reg         lcd_dc,
  
  // spi_master への接続
  output reg         spi_start,
  output reg [7:0]   spi_data,
  input  wire        spi_busy,
  
  // 完了フラグ(任意、デバッグ用)
  output reg         init_done
);

  // 待機時間定数
  localparam [21:0] WAIT_5MS   = 22'd135_000;
  localparam [21:0] WAIT_120MS = 22'd3_240_000;
  
  // ILI9341 コマンド
  localparam [7:0] CMD_SWRESET = 8'h01;
  localparam [7:0] CMD_SLPOUT  = 8'h11;
  localparam [7:0] CMD_MADCTL  = 8'h36;
  localparam [7:0] DATA_MADCTL = 8'h48;
  localparam [7:0] CMD_COLMOD  = 8'h3A;
  localparam [7:0] DATA_COLMOD = 8'h55;
  localparam [7:0] CMD_DISPON  = 8'h29;
  
  // 状態定義(4ビットあれば11状態を表現できる: 2^4=16)
  localparam [4:0] S_RESET_LOW    = 5'd0;
  localparam [4:0] S_RESET_HIGH   = 5'd1;
  localparam [4:0] S_CMD_SWRESET  = 5'd2;
  localparam [4:0] S_WAIT_BUSY1   = 5'd3;
  localparam [4:0] S_WAIT_5MS     = 5'd4;
  localparam [4:0] S_CMD_SLPOUT   = 5'd5;
  localparam [4:0] S_WAIT_BUSY2   = 5'd6;
  localparam [4:0] S_WAIT_120MS   = 5'd7;
  localparam [4:0] S_CMD_MADCTL   = 5'd8;
  localparam [4:0] S_WAIT_BUSY_M  = 5'd9;
  localparam [4:0] S_DATA_MADCTL  = 5'd10;
  localparam [4:0] S_WAIT_BUSY_MD = 5'd11;
  localparam [4:0] S_CMD_COLMOD   = 5'd12;
  localparam [4:0] S_WAIT_BUSY_C  = 5'd13;
  localparam [4:0] S_DATA_COLMOD  = 5'd14;
  localparam [4:0] S_WAIT_BUSY_CD = 5'd15;
  localparam [4:0] S_CMD_DISPON   = 5'd16;
  localparam [4:0] S_WAIT_BUSY3   = 5'd17;
  localparam [4:0] S_DONE         = 5'd18;
  
  reg [4:0]  state;
  reg [21:0] wait_counter;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // ============================
      // リセット時の初期化
      // 全部の reg を安全な値にする
      // 特に lcd_rst は最初 0(リセット中)にする
      // ============================
      lcd_rst      <= 1'b0;
      lcd_dc       <= 1'b0;
      spi_start    <= 1'b0;
      spi_data     <= 8'b0000_0000;
      state        <= S_RESET_LOW;
      wait_counter <= 22'd0;
      init_done    <= 1'b0;
    end else begin
      case (state)
        S_RESET_LOW: begin
          // ============================
          // lcd_rst = 0(リセット中)、120ms 待つ
          // 待ち終わったら S_RESET_HIGH に遷移
          // ============================
          if (wait_counter == WAIT_120MS - 1) begin
            state        <= S_RESET_HIGH;
            lcd_rst      <= 1'b1;
            wait_counter <= 22'b0;
          end else begin
            wait_counter <= wait_counter + 1;
          end
        end
        
        S_RESET_HIGH: begin
          // ============================
          // lcd_rst = 1(リセット解除)、120ms 待つ
          // 待ち終わったら S_CMD_SWRESET に遷移
          // ============================
          if (wait_counter == WAIT_120MS - 1) begin
            state        <= S_CMD_SWRESET;
            wait_counter <= 22'b0;
          end else begin
            wait_counter <= wait_counter + 1;
          end
        end
        
        S_CMD_SWRESET: begin
          // ============================
          // DC=0 (コマンド)、spi_data=CMD_SWRESET、spi_start=1 を1サイクルだけ
          // → S_WAIT_BUSY1 に遷移
          // ============================
          lcd_dc    <= 1'b0;
          spi_data  <= CMD_SWRESET;
          spi_start <= 1'b1;
          state     <= S_WAIT_BUSY1;
        end
        
        S_WAIT_BUSY1: begin
          // ============================
          // spi_busy が 0 になるのを待つ(送信完了)
          // 0 になったら S_WAIT_5MS に遷移
          // ============================
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            state <= S_WAIT_5MS;
          end
        end
        
        S_WAIT_5MS: begin
          // ============================
          // 5ms 待つ
          // 待ち終わったら S_CMD_SLPOUT に遷移
          // ============================
          if (wait_counter == WAIT_5MS -1) begin
            state        <= S_CMD_SLPOUT;
            wait_counter <= 22'b0;
          end else begin
            wait_counter <= wait_counter + 1;
          end
        end
        
        S_CMD_SLPOUT: begin
          // SLPOUT を送信、S_WAIT_BUSY2 へ
          lcd_dc    <= 1'b0;
          spi_data  <= CMD_SLPOUT;
          spi_start <= 1'b1;
          state     <= S_WAIT_BUSY2;
        end
        
        S_WAIT_BUSY2: begin
          // busy=0 を待つ、S_WAIT_120MS へ
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            state <= S_WAIT_120MS;
          end
        end
        
        S_WAIT_120MS: begin
          // 120ms 待つ、S_CMD_MADCTL へ
          if (wait_counter == WAIT_120MS - 1) begin
            state        <= S_CMD_MADCTL;
            wait_counter <= 22'b0;
          end else begin
            wait_counter <= wait_counter + 1;
          end
        end

        S_CMD_MADCTL: begin
          lcd_dc    <= 1'b0;
          spi_data  <= CMD_MADCTL;
          spi_start <= 1'b1;
          state     <= S_WAIT_BUSY_M;
        end

        S_WAIT_BUSY_M: begin
          // busy=0 を待つ、S_DATA_MADCTL へ
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            state <= S_DATA_MADCTL;
          end
        end

        S_DATA_MADCTL: begin
          lcd_dc    <= 1'b1;
          spi_data  <= DATA_MADCTL;
          spi_start <= 1'b1;
          state     <= S_WAIT_BUSY_MD;
        end

        S_WAIT_BUSY_MD: begin
          // busy=0 を待つ、S_CMD_COLMOD へ
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            state <= S_CMD_COLMOD;
          end
        end

        S_CMD_COLMOD: begin
          lcd_dc    <= 1'b0;
          spi_data  <= CMD_COLMOD;
          spi_start <= 1'b1;
          state     <= S_WAIT_BUSY_C;
        end

        S_WAIT_BUSY_C: begin
          // busy=0 を待つ、S_DATA_COLMOD へ
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            state <= S_DATA_COLMOD;
          end
        end

        S_DATA_COLMOD: begin
          lcd_dc    <= 1'b1;
          spi_data  <= DATA_COLMOD;
          spi_start <= 1'b1;
          state     <= S_WAIT_BUSY_CD;
        end

        S_WAIT_BUSY_CD: begin
          // busy=0 を待つ、S_CMD_DISPON へ
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            state <= S_CMD_DISPON;
          end
        end
        
        S_CMD_DISPON: begin
          // DISPON を送信、S_WAIT_BUSY3 へ
          lcd_dc    <= 1'b0;
          spi_data  <= CMD_DISPON;
          spi_start <= 1'b1;
          state     <= S_WAIT_BUSY3;
        end
        
        S_WAIT_BUSY3: begin
          // busy=0 を待つ、S_DONE へ
          spi_start <= 1'b0;
          if (spi_busy == 0) begin
            state <= S_DONE;
          end
        end
        
        S_DONE: begin
          // init_done = 1、何もしない(待機)
          init_done <= 1'b1;
        end
      endcase
    end
  end

endmodule
