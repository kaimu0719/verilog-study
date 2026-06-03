`default_nettype none

module vram (
  input  wire        clk,

  // Port A: CPU 用(書き込み + 読み出し)
  input  wire [12:0] addr_a,
  input  wire [15:0] data_in,
  input  wire        we,
  output reg  [15:0] data_out_a,

  // Port B: display_fsm 用(読み出し専用)
  input  wire [12:0] addr_b,
  output reg  [15:0] data_out_b
);

  reg [15:0] mem [8191:0];

  initial begin
    $readmemb("vram_init.bin", mem);
  end

  always @(posedge clk) begin
    if (we) mem[addr_a] <= data_in;
    data_out_a <= mem[addr_a];
    data_out_b <= mem[addr_b];
  end

endmodule
