module pc_tb;

  reg         clk;
  reg         reset;
  reg         load;
  reg         inc;
  reg  [14:0] in;
  wire [14:0] out;

  pc dut (
    .clk(clk),
    .reset(reset),
    .load(load),
    .inc(inc),
    .in(in),
    .out(out)
  );

  // クロック生成
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin

    $dumpfile("pc_tb.vcd");
    $dumpvars(0, pc_tb);

    // シナリオ1: 初期化 - reset=1 で out=0
    in = 15'h0;
    {reset, load, inc} = 3'b100;
    #10;
    $display("Scenario 1: reset → out=%h (expected 0000)", out);

    // シナリオ2: インクリメント - inc=1 で out が +1 される
    {reset, load, inc} = 3'b001;
    #10;
    $display("Scenario 2: inc → out=%h (expected 0001)", out);

    // シナリオ3: 連続インクリメント - inc=1 のまま out が階段状に増える
    #30;
    $display("Scenario 3: 連続inc → out=%h (expected 0004)", out);

    // シナリオ4: ジャンプ - load=1 で out=in になる
    in = 15'h0064;
    {reset, load, inc} = 3'b010;
    #10;
    $display("Scenario 4: load → out=%h (expected 0064)", out);

    // シナリオ5: 保持 - 全部0 で out が変わらない
    {reset, load, inc} = 3'b000;
    #10;
    $display("Scenario 5: hold → out=%h (expected 0064)", out);

    // シナリオ6: 優先順位1 - load=1 と inc=1 が同時なら load が勝つ
    in = 15'h1111;
    {reset, load, inc} = 3'b011;
    #10;
    $display("Scenario 6: 優先順位1 → out=%h (expected 1111)", out);

    // シナリオ7: 優先順位2 - reset=1 と load=1 が同時なら reset が勝つ
    in = 15'h2222;
    {reset, load, inc} = 3'b110;
    #10;
    $display("Scenario 7: 優先順位2 → out=%h (expected 0000)", out);

    $finish;

  end

endmodule