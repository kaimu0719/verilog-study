module alu (
    input  wire [15:0] x,    // 入力1(通常 D)
    input  wire [15:0] y,    // 入力2(通常 A または M)
    input  wire        zx,   // x をゼロに?
    input  wire        nx,   // x を反転?
    input  wire        zy,   // y をゼロに?
    input  wire        ny,   // y を反転?
    input  wire        f,    // 1=加算, 0=AND
    input  wire        no,   // 出力を反転?
    output wire [15:0] out,
    output wire        zr,   // out == 0
    output wire        ng    // out < 0
);

  wire [15:0] x1;
  wire [15:0] x2;
  wire [15:0] y1;
  wire [15:0] y2;
  wire [15:0] fxy;

  // zx=1 なら x を 0 に
  assign x1 = zx ? 16'b0 : x;

  // nx=1 なら x を反転
  assign x2 = nx ? ~x1 : x1;

  // zy=1 なら y を 0 に
  assign y1 = zy ? 16'b0 : y;

  // ny=1 なら y を反転
  assign y2 = ny ? ~y1 : y1;

  // f=1 なら 加算、f=0 なら AND
  assign fxy = f ? (x2 + y2) : (x2 & y2);

  // no=1 なら 反転 → out
  assign out = no ? ~fxy : fxy;

  // zr = (out == 0)
  assign zr = (out == 16'b0) ? 1'b1 : 1'b0;

  // ng = out が負(最上位ビットが1)
  assign ng = out[15];

endmodule
