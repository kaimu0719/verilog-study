module vram (
  input  wire        clk,
  input  wire [12:0] addr,
  output reg  [15:0] data_out
);

  reg [15:0] mem [5119:0];

  integer i;
  initial begin
    for (i = 0; i < 5120; i = i + 1) begin
      if (i[0] == 1'b0) mem[i] = 16'h0000;
      else              mem[i] = 16'hFFFF;
    end
  end

  always @(posedge clk) begin
    data_out <= mem[addr];
  end

endmodule
