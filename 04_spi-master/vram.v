`default_nettype none

module vram (
  input  wire        clk,
  input  wire [12:0] addr_a,
  input  wire [15:0] data_in,
  input  wire        we,
  input  wire [12:0] addr_b,
  output reg  [15:0] data_out
);

  reg [15:0] mem [8191:0];

  initial begin
    $readmemb("vram_init.bin", mem);
  end

  always @(posedge clk) begin
    if (we) mem[addr_a] <= data_in;
    data_out <= mem[addr_b];
  end

endmodule
