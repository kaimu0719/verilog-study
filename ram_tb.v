`default_nettype none

module ram_tb;

  reg         clk;
  reg  [13:0] addr;
  reg  [15:0] data_in;
  reg         we;
  wire [15:0] data_out;

  ram dut (
    .clk(clk),
    .addr(addr),
    .data_in(data_in),
    .we(we),
    .data_out(data_out)
  );

  always #5 clk = ~clk;

  initial begin

    $dumpfile("ram_tb.vcd");
    $dumpvars(0, ram_tb);

    // 初期化
    clk = 0; addr = 0; data_in = 0; we = 0;
    #10;

    // シナリオ1: 書き込み → 読み出し
    addr = 14'h0001;
    data_in = 16'h1111;
    we = 1'b1;
    #10

    data_in = 16'h0000;
    we = 1'b0;
    #10
    if (data_out !== 16'h1111) begin
      $display("Scenario 1 FAIL: data_out = %h (expected 1111)", data_out);
    end else begin
      $display("Scenario 1 PASS: data_out = %h", data_out);
    end

    // シナリオ2: 書き込みと別アドレス読み出しが独立して動く
    addr = 14'h0002;
    data_in = 16'h2222;
    we = 1'b1;
    #10;

    data_in = 16'h0000;
    we = 1'b0;
    addr = 14'h0001;
    #10;

    if (data_out !== 16'h1111) begin
      $display("Scenario 2a FAIL: data_out = %h (expected 1111)", data_out);
    end else begin
      $display("Scenario 2a PASS: data_out = %h", data_out);
    end

    addr = 14'h0002;
    #10;

    if (data_out !== 16'h2222) begin
      $display("Scenario 2b FAIL: data_out = %h (expected 2222)", data_out);
    end else begin
      $display("Scenario 2b PASS: data_out = %h", data_out);
    end

    // シナリオ3:we=0 で書き込みが起きないこと
    //   シナリオ1 で mem[1] = 0x1111 を書き込んだ状態を流用
    //   ここで data_in=0x2222、we=0 にして「書き込みが起きないこと」を確認
    //   → 読み出し結果が 0x1111(古い値)のままなら、we=0 が正しく効いている
    addr = 14'h0001;
    data_in = 16'h2222;
    we = 1'b0;
    #10

    data_in = 16'h0000;
    we = 1'b0;
    #10;
    
    if (data_out !== 16'h1111) begin
      $display("Scenario 3 FAIL: data_out = %h (expected 1111)", data_out);
    end else begin
      $display("Scenario 3 PASS: data_out = %h", data_out);
    end

    $finish;
  end

endmodule
