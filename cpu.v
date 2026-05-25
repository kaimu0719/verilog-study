module cpu (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [15:0] instruction,
  input  wire [15:0] inM,
  output wire [15:0] outM,
  output wire [14:0] addressM,
  output wire        writeM,
  output wire [14:0] pc
);

  wire is_c = instruction[15];
  wire is_a = ~instruction[15];

  wire       a_bit  = instruction[12];
  wire [5:0] c_bits = instruction[11:6];

  wire dest_a = instruction[5];
  wire dest_d = instruction[4];
  wire dest_m = instruction[3];

  wire j_lt = instruction[2];
  wire j_eq = instruction[1];
  wire j_gt = instruction[0];

  // Aレジスタの出力
  wire [15:0] a_value;

  // ALUのy入力を決めるマルチプレクサ
  wire [15:0] alu_y = a_bit ? inM : a_value;

  // ALUの出力
  wire [15:0] alu_out;

  // Aレジスタの入力選択
  wire [15:0] a_in = is_c ? alu_out : instruction;

  // Aレジスタのロード条件
  wire a_load = is_a | (is_c & dest_a);

  // Aレジスタのインスタンス化
  register a_reg (
    .clk(clk),
    .in(a_in),
    .load(a_load),
    .out(a_value)
  );

  // Dレジスタの出力
  wire [15:0] d_value;

  // ALUのフラグ出力
  wire alu_zr;
  wire alu_ng;

  // aluのインスタンス化
  alu cpu_alu (
    .x(d_value),
    .y(alu_y),
    .zx(c_bits[5]),
    .nx(c_bits[4]),
    .zy(c_bits[3]),
    .ny(c_bits[2]),
    .f(c_bits[1]),
    .no(c_bits[0]),
    .out(alu_out),
    .zr(alu_zr),
    .ng(alu_ng)
  );

  // Dレジスタのロード条件
  wire d_load = is_c & dest_d;

  // Dレジスタのインスタンス化
  register d_reg (
    .clk(clk),
    .in(alu_out),
    .load(d_load),
    .out(d_value)
  );

  // ジャンプ条件の計算(jjjとALUフラグの組み合わせ)
  wire jump_cond = (j_lt & alu_ng)
                 | (j_eq & alu_zr)
                 | (j_gt & ~alu_ng & ~alu_zr);

  // C命令の時のみジャンプ有効
  wire jump = is_c & jump_cond;

  // pcのインスタンス化
  pc cpu_pc (
    .clk(clk),
    .reset(~rst_n),
    .load(jump),
    .inc(~jump),
    .in(a_value[14:0]),
    .out(pc)
  );

  // メモリ関連の出力
  assign outM = alu_out;
  assign addressM = a_value[14:0];
  assign writeM = is_c & dest_m;

endmodule
