`default_nettype none

module vram_tb;

  reg         clk;
  reg  [12:0] addr_a;
  reg  [15:0] data_in;
  reg         we;
  reg  [12:0] addr_b;
  wire [15:0] data_out_a;    // ← 新規追加(検証はしないが接続のため)
  wire [15:0] data_out_b;    // ← data_out からリネーム

  vram dut (
    .clk(clk),
    .addr_a(addr_a),
    .data_in(data_in),
    .we(we),
    .data_out_a(data_out_a), // ← 新規ポート接続
    .addr_b(addr_b),
    .data_out_b(data_out_b)  // ← .data_out からリネーム
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin

    $dumpfile("vram_tb.vcd");
    $dumpvars(0, vram_tb);

    addr_a  = 13'b0;
    data_in = 16'b0;
    we      = 1'b0;
    addr_b  = 13'b0;

    // シナリオ1:Port A から書き込み、同じアドレスを Port B で読み出す
    addr_a  = 13'h0001;
    data_in = 16'h1111;
    we      = 1'b1;

    addr_b = 13'h0001;
    #10;
    we = 1'b0;
    #10;
    if (data_out_b !== 16'h1111) begin
      $display("Scenario 1 FAIL: data_out_b = %h (expected 1111)", data_out_b);
    end else begin
      $display("Scenario 1 PASS: data_out_b = %h", data_out_b);
    end

    addr_a  = 13'b0;
    data_in = 16'b0;
    we      = 1'b0;
    addr_b  = 13'b0;

    // シナリオ2:アドレス独立性
    //   100 番地と 200 番地に異なる値を書いて、両方が独立して保持されているか確認

    // (a) 100 番地に 0x1111 を書く
    addr_a  = 13'd100;
    data_in = 16'h1111;
    we      = 1'b1;
    #10;

    // (b) 200 番地に 0x2222 を書く(100 番地とは異なる値!)
    addr_a  = 13'd200;
    data_in = 16'h2222;
    we      = 1'b1;
    #10;

    // (c) 100 番地を読む(0x1111 が読めるはず = 壊れていない)
    we     = 1'b0;
    addr_b = 13'd100;
    #10;
    #10;
    if (data_out_b !== 16'h1111) begin
      $display("Scenario 2a FAIL: data_out_b = %h (expected 1111)", data_out_b);
    end else begin
      $display("Scenario 2a PASS: data_out_b = %h", data_out_b);
    end

    // (d) 200 番地を読む(0x2222 が読めるはず = 独立して書き込まれた)
    addr_b = 13'd200;
    #10;
    #10;
    if (data_out_b !== 16'h2222) begin
      $display("Scenario 2b FAIL: data_out_b = %h (expected 2222)", data_out_b);
    end else begin
      $display("Scenario 2b PASS: data_out_b = %h", data_out_b);
    end

    addr_a  = 13'b0;
    data_in = 16'b0;
    we      = 1'b0;
    addr_b  = 13'b0;

    // シナリオ3:we=0 で書き込みが起きないこと
    //   シナリオ1 で mem[1] = 0x1111 を書き込んだ状態を流用
    //   ここで data_in=0x2222、we=0 にして「書き込みが起きないこと」を確認
    //   → 読み出し結果が 0x1111(古い値)のままなら、we=0 が正しく効いている
    addr_a  = 13'h0001;
    data_in = 16'h2222;
    we      = 1'b0;

    addr_b = 13'h0001;
    #10;
    we = 1'b0;
    #10;
    if (data_out_b !== 16'h1111) begin
      $display("Scenario 3 FAIL: data_out_b = %h (expected 1111 = unchanged)", data_out_b);
    end else begin
      $display("Scenario 3 PASS: we=0 prevented write");
    end

    $finish;
  end

endmodule
