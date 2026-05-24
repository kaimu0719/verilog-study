module alu_tb;

  // 入力
  reg [15:0] x;
  reg [15:0] y;
  reg zx, nx, zy, ny, f, no;

  // 出力
  wire [15:0] out;
  wire zr, ng;

  alu dut(
    .x(x), .y(y),
    .zx(zx), .nx(nx), .zy(zy), .ny(ny), .f(f), .no(no),
    .out(out), .zr(zr), .ng(ng)
  );

  initial begin
    $dumpfile("alu_tb.vcd");
    $dumpvars(0, alu_tb);

    // テスト用の入力
    x = 16'h0005;
    y = 16'h0003;

    // テスト1: 0を出力
    {zx, nx, zy, ny, f, no} = 6'b101010;
    #1;
    $display("Test 1: 0 出力 → out=%h zr=%b ng=%b (expected 0000)", out, zr, ng);

    // テスト2: 1を出力
    {zx, nx, zy, ny, f, no} = 6'b111111;
    #1;
    $display("Test 2: 1 出力 → out=%h zr=%b ng=%b (expected 0001)", out, zr, ng);

    // テスト3: -1を出力
    {zx, nx, zy, ny, f, no} = 6'b111010;
    #1;
    $display("Test 3: -1 出力 → out=%h zr=%b ng=%b (expected FFFF)", out, zr, ng);

    // テスト4: xをそのまま出力
    {zx, nx, zy, ny, f, no} = 6'b001100;
    #1;
    $display("Test 4: x 出力 → out=%h zr=%b ng=%b (expected x)", out, zr, ng);

    // テスト5: x+y
    {zx, nx, zy, ny, f, no} = 6'b000010;
    #1;
    $display("Test 5: x+y 出力 → out=%h zr=%b ng=%b (expected x+y)", out, zr, ng);

    // テスト6: x&y
    {zx, nx, zy, ny, f, no} = 6'b000000;
    #1;
    $display("Test 6: x&y 出力 → out=%h zr=%b ng=%b (expected x&y)", out, zr, ng);

    $finish;

  end

endmodule