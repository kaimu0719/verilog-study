`default_nettype none

module spi_master (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [7:0]  data_in,
    output reg         sclk,
    output reg         mosi,
    output reg         cs,
    output reg         busy
);

  // SCLK の半周期 = clk 何サイクル分か
  parameter SCLK_HALF = 4;

  // 状態の定義
  localparam IDLE       = 2'd0;
  localparam SHIFT_LOW  = 2'd1;
  localparam SHIFT_HIGH = 2'd2;
  localparam DONE       = 2'd3;

  // 内部状態
  reg [1:0] state;
  reg [2:0] bit_count;
  reg [3:0] clk_count;
  reg [7:0] shift_reg;

  // メイン回路
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin

      // ============================
      // ここに「リセット時の初期化」を書く
      // 全部の reg を安全な値にする
      // ============================
      sclk      <= 1'b0;
      mosi      <= 1'b0;
      cs        <= 1'b1;
      busy      <= 1'b0;
      state     <= IDLE;
      bit_count <= 3'b000;
      clk_count <= 4'b0000;
      shift_reg <= 8'b0000_0000;

    end else begin
      case (state)
        IDLE: begin
          // ============================
          // 待機中。何もしない、cs=High, sclk=Low
          // start が来たら、shift_regにdata_inをロードして、
          //   SHIFT_LOWに遷移、mosi=data_in[7], cs=Low, busy=1
          // ============================
          cs   <= 1'b1;
          sclk <= 1'b0;
          busy <= 1'b0;

          if (start == 1) begin
            state     <= SHIFT_LOW;
            cs        <= 1'b0;
            busy      <= 1'b1;
            shift_reg <= data_in;
            mosi      <= data_in[7];
            bit_count <= 3'b000;
            clk_count <= 4'b0000;
          end
        end
        
        SHIFT_LOW: begin
          // ============================
          // sclk=Low の状態。clk_countを数える。
          // clk_count == SCLK_HALF-1 になったら SHIFT_HIGHに遷移
          // ============================
          if (clk_count == SCLK_HALF - 1) begin
            state     <= SHIFT_HIGH;
            clk_count <= 4'b0000;
            sclk      <= 1'b1;
          end else begin
            clk_count <= clk_count + 1;
          end
        end

        SHIFT_HIGH: begin
          // ============================
          // sclk=High の状態。clk_countを数える。
          // clk_count == SCLK_HALF-1 になったら、
          //   - bit_count == 7 なら DONE に遷移
          //   - そうでなければ SHIFT_LOW に戻り、bit_countを+1、shift_regをシフト、mosi更新
          // ============================
          if (clk_count == SCLK_HALF - 1) begin
            clk_count <= 4'b0000;
            sclk      <= 1'b0;

            if (bit_count == 7) begin
              state     <= DONE;
            end else begin
              state     <= SHIFT_LOW;
              bit_count <= bit_count + 1;
              shift_reg <= {shift_reg[6:0], 1'b0};
              mosi      <= shift_reg[6];   
            end
          end else begin
            clk_count <= clk_count + 1;
          end
        end

        DONE: begin
          // ============================
          // cs=High, busy=0 にして IDLEへ戻る
          // ============================
          cs    <= 1'b1;
          busy  <= 1'b0;
          state <= IDLE;
        end
      endcase
    end
  end

endmodule