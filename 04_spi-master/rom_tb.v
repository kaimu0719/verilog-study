module rom_tb;

  reg         clk;
  reg  [11:0] addr;
  wire [15:0] instruction;

  rom dut (
    .clk(clk),
    .addr(addr),
    .instruction(instruction)
  );

  initial clk = 0;
  always #5 clk = ~clk; // 5単位ごとに反転

  initial begin
    $dumpfile("rom_tb.vcd");
    $dumpvars(0, rom_tb);

    // 初期値
    addr = 0;

    // テスト1: addr = 0 にして、1サイクル待つ
    #10;
    $display("addr=%d, inst=%h", addr, instruction);

    addr = 1;
    #10;
    $display("addr=%d, inst=%h", addr, instruction);

    addr = 2;
    #10;
    $display("addr=%d, inst=%h", addr, instruction);

    addr = 3;
    #10;
    $display("addr=%d, inst=%h", addr, instruction);

    $finish;
  end

endmodule
