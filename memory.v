`default_nettype none

module memory (
  input wire clk,

  // CPUとの接続
  input  wire [15:0] inM,
  input  wire [14:0] addressM,
  input  wire        writeM,
  output wire [15:0] outM,

  // display_fsmとの接続
  input  wire [12:0] vram_addr_b,
  output wire [15:0] vram_data_out
);

  wire is_ram  = (addressM[14] == 1'b0);
  wire is_vram = (addressM[14:13] == 2'b10);
  wire is_kbd  = (addressM[14:13] == 2'b11);

  wire ram_we  = is_ram & writeM;
  wire vram_we = is_vram & writeM;

  wire [15:0] ram_data_out;
  ram u_ram (
    .clk(clk),
    .addr(addressM[13:0]),
    .data_in(inM),
    .we(ram_we),
    .data_out(ram_data_out)
  );

  wire [15:0] vram_data_out_a;
  vram u_vram (
    .clk(clk),
    .addr_a(addressM[12:0]),
    .data_in(inM),
    .we(vram_we),
    .data_out_a(vram_data_out_a),
    .addr_b(vram_addr_b),
    .data_out_b(vram_data_out)
  );

  wire [15:0] kbd_data_out = 16'h0000;

  assign outM = is_ram  ? ram_data_out :
                is_vram ? vram_data_out_a :
                kbd_data_out;

endmodule
