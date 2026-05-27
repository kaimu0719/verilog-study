`default_nettype none

module ram (
  input  wire        clk,
  input  wire [13:0] addr,
  input  wire [15:0] data_in,
  input  wire        we,
  output reg  [15:0] data_out
);

  reg [15:0] mem [16383:0];

  always @(posedge clk) begin
    if (we) mem[addr] <= data_in;
    data_out <= mem[addr];
  end

endmodule
