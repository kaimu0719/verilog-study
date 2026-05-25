module cpu_tb;

  reg         clk;
  reg         rst_n;
  wire [15:0] instruction;
  reg  [15:0] inM;
  wire [15:0] outM;
  wire [14:0] addressM;
  wire        writeM;
  wire [14:0] pc;

  // テスト用 ROM(4ワード)
  reg [15:0] rom_mem [0:7];

  // テスト用メモリ(16ワード)
  reg [15:0] data_mem [0:15];

  cpu dut (
    .clk(clk),
    .rst_n(rst_n),
    .instruction(instruction),
    .inM(inM),
    .outM(outM),
    .addressM(addressM),
    .writeM(writeM),
    .pc(pc)
  );

  assign instruction = rom_mem[pc[3:0]];

  // 書き込み: writeM=1のとき
  always @(posedge clk) begin
    if (writeM) begin
      data_mem[addressM[3:0]] <= outM;
    end
  end

  // 読み出し:アドレスから常に値を返す。
  // 非同期な読み出し:addressMが変わったら即座にinMを更新
  // これって
  // assign inM = data_mem[addressM[3:0]];
  // じゃだめなのか？
  always @(*) begin
    inM = data_mem[addressM[3:0]];
  end

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin

    $dumpfile("cpu_tb.vcd");
    $dumpvars(0, cpu_tb);

    // ROM に test.hack の中身を直接書く
    rom_mem[0] = 16'b0000_0000_0000_0101; // @5
    rom_mem[1] = 16'b1110_1100_0001_0000; // D=A   → D=5
    rom_mem[2] = 16'b0000_0000_0000_1000; // @8    → A=8(END の番地)
    rom_mem[3] = 16'b1110_0011_0000_0010; // D;JEQ → D=5≠0、飛ばない
    rom_mem[4] = 16'b0000_0000_0000_0001; // @1    → A=1
    rom_mem[5] = 16'b1110_0011_0000_1000; // M=D   → M[1]=5
    rom_mem[6] = 16'b0000_0000_0000_0110; // @6    → A=6(無限ループの番地)
    rom_mem[7] = 16'b1110_1010_1000_0111; // 0;JMP → pc=6 に飛ぶ(無限ループ)

    // メモリを初期化
    for (integer i = 0; i < 16; i = i + 1) begin
      data_mem[i] = 16'h0000;
    end

    // リセット
    rst_n = 0;
    #20
    rst_n = 1;

    // 4命令を実行するのに十分な時間を確保
    #100

    // 結果を確認
    $display("M[1] = %d (期待値: 5、JEQが飛ばなかった証拠)", data_mem[1]);
    $display("M[0] = %d (期待値: 0、書き換わってないこと)", data_mem[0]);

    $finish;
  end

endmodule
