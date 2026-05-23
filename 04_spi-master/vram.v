module vram (
  input  wire        clk,
  input  wire [12:0] addr,
  output reg  [15:0] data_out
);

  (* ram_style = "block" *) reg [15:0] mem [5119:0];

  initial begin
    $readmemb("vram_init.bin", mem);
  end

  always @(posedge clk) begin
    data_out <= mem[addr];
  end

endmodule
