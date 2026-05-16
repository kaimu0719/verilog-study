`timescale 1ns/1ps

module spi_master_tb;

  // テストベンチ内で使う信号
  reg        clk;
  reg        rst_n;
  reg        start;
  reg [7:0]  data_in;
  wire       sclk;
  wire       mosi;
  wire       cs;
  wire       busy;

  // テスト対象のモジュールをインスタンス化
  spi_master u_dut (
    .clk     (clk),
    .rst_n   (rst_n),
    .start   (start),
    .data_in (data_in),
    .sclk    (sclk),
    .mosi    (mosi),
    .cs      (cs),
    .busy    (busy)
  );

  // クロック生成: 5ns周期 → 200MHz相当(シミュレーション用なので速度は適当)
  initial clk = 0;
  always #5 clk = ~clk;

  // テストシナリオ
  initial begin
    // 波形を保存するための設定
    $dumpfile("spi_master.vcd");
    $dumpvars(0, spi_master_tb);

    // 信号を初期化する
    rst_n   = 0;
    start   = 0;
    data_in = 8'b0000_0000;

    // 少し待つ
    #20;

    // rst_nを1にしてリセット解除
    rst_n = 1;

    // もう少し待つ
    #20;

    // data_inに 0xAA をセット
    data_in = 8'b1010_1010;

    //  start を1にして1サイクル後に0に戻す
    start = 1;
    #10;
    start = 0;

    // busyが0に戻るまで待つ(送信完了まで)
    wait (busy == 0);
    #50;

    // ↓ シミュレーション終了
    $finish;
  end

endmodule
