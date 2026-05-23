module rom (
  input wire clk,

  // プログラムが 4K(0〜4095) 命令以内に収まる前提で、それ以上のアドレスは指さない。
  // 足りなくなったら後で拡張する。
  input wire [11:0] addr,
  output reg [15:0] instruction
);

  reg [15:0] mem [4095:0];

  initial begin
    $readmemb("test.hack", mem);
  end

  always @(posedge clk) begin
    instruction <= mem[addr];
  end

endmodule
