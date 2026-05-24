module pc (
  input wire clk,
  input wire reset,
  input wire load,
  input wire inc,
  input wire [14:0] in,
  output reg [14:0] out
);

  always @(posedge clk) begin
    if (reset) begin
      out <= 15'b0;
    end else if (load) begin
      out <= in;
    end else if (inc) begin
      out <= out + 1;
    end
  end

endmodule
