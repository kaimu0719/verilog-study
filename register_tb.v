module register_tb;

  reg         clk;
  reg  [15:0] in;
  reg         load;
  wire [15:0] out;

  register dut (
    .clk(clk),
    .in(in),
    .load(load),
    .out(out)
  );

  // クロック生成
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin

    $dumpfile("register_tb.vcd");
    $dumpvars(0, register_tb);

    // シナリオ1: load=1で書き込み
    in = 16'hAAAA;
    load = 1'b1;
    #10;
    $display("Scenario 1: out=%h (expected AAAA)", out);

    // シナリオ2: load=0で保持
    in = 16'h5555;
    load = 1'b0;
    #10;
    $display("Scenario 2: out=%h (expected AAAA, not 5555)", out);

    // シナリオ3: load=1で書き込み
    in = 16'h1111;
    load = 1'b1;
    #10;
    $display("Scenario 3: out=%h (expected 1111)", out);

    // シナリオ4: load=0で保持
    in = 16'h0000;
    load = 1'b0;
    #30;
    $display("Scenario 4: out=%h (expected 1111, not 0000)", out);

    $finish;
  end

endmodule
