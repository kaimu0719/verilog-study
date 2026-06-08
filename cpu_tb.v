module cpu_tb;

  reg         clk;
  reg         rst_n;
  reg  [15:0] instruction;
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

  always @(posedge clk) begin
    instruction <= rom_mem[pc[3:0]];
  end
  // assign instruction = rom_mem[pc[3:0]];

  // 書き込み: writeM=1のとき
  always @(posedge clk) begin
    if (writeM) begin
      data_mem[addressM[3:0]] <= outM;
    end
  end

  // 同期読み出し: posedge で addressM 番地の値を読み、1サイクル遅れて inM に出す(実機 BRAM と同じ遅延)
  always @(posedge clk) begin
    inM <= data_mem[addressM[3:0]];
  end

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin

    $dumpfile("cpu_tb.vcd");
    $dumpvars(0, cpu_tb);

    // ROM に test.hack の中身を直接書く
    rom_mem[0] = 16'b0000_0000_0000_0101; // @5
    rom_mem[1] = 16'b1110_1100_0001_0000; // D=A   → D=0x0005
    rom_mem[2] = 16'b0000_0000_0000_0111; // @7
    rom_mem[3] = 16'b1110_0011_0000_1000; // M=D   → M[7]=5
    rom_mem[4] = 16'b0000_0000_0000_0111; // @7
    rom_mem[5] = 16'b1111_1101_1100_1000; // M=M+1 → M[7]=5+1=6
    rom_mem[6] = 16'b0000_0000_0000_0110; // @6    → A=8(無限ループの番地)
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
    #200

    // 結果を確認
    $display("M[7] = %h (期待値: 0006, M=M+1のリードモディファイライト検証)", data_mem[7]);
    if (data_mem[7] === 16'h0006) begin
      $display("PASS: D=M が inM 経路を正しく通った");
    end else begin
      $display("FAIL: inM が間に合っていない可能性");
    end

    $finish;
  end

endmodule
