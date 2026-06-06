`default_nettype none
`timescale 1ns / 1ps

module memory_tb;

  reg         clk;
  reg  [15:0] inM;
  reg  [14:0] addressM;
  reg         writeM;
  wire [15:0] outM;
  reg  [12:0] vram_addr_b;
  wire [15:0] vram_data_out;

  memory dut (
    .clk(clk),
    .inM(inM),
    .addressM(addressM),
    .writeM(writeM),
    .outM(outM),
    .vram_addr_b(vram_addr_b),
    .vram_data_out(vram_data_out)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpfile("memory_tb.vcd");
    $dumpvars(0, memory_tb);

    inM         = 16'h0000;
    addressM    = 15'h0000;
    writeM      = 1'b0;
    vram_addr_b = 13'h0000;
    #10;

    // S1: RAM領域の書き込み&読み出し
    //   addressM = 0x0010 に 0xAAAA を書いて、 読み戻す
    //   addressM[14]=0 なので is_ram が立つ
    addressM = 15'h0010;
    inM      = 16'hAAAA;
    writeM   = 1'b1;
    #10;

    writeM = 1'b0;
    inM    = 16'h0000;
    #10;

    if (outM !== 16'hAAAA) begin
      $display("S1 FAIL: outM = %h (expected AAAA)", outM);
    end else begin
      $display("S1 PASS: RAM write/read at 0x0010 = %h", outM);
    end

    // S2: RAM 領域の境界アドレス
    //   addressM = 0x3FFF(RAM 最終番地)で同じことをやる
    //   addressM[14]=0 なので is_ram のままで OK
    addressM = 15'h3FFF;
    inM      = 16'hBEEF;
    writeM   = 1'b1;
    #10;

    writeM = 1'b0;
    inM    = 16'h0000;
    #10;

    if (outM !== 16'hBEEF) begin
      $display("S2 FAIL: outM = %h (expected BEEF)", outM);
    end else begin
      $display("S2 PASS: RAM boundary 0x3FFF = %h", outM);
    end

    // S3: VRAM 領域の書き込み&CPU 読み出し
    //   addressM = 0x4010 に 0xBBBB を書いて、 CPU が読み戻す
    //   addressM[14:13]=10 なので is_vram が立つ
    //   data_out_a 経由で読まれる
    addressM = 15'h4010;
    inM      = 16'hBBBB;
    writeM   = 1'b1;
    #10;

    writeM = 1'b0;
    inM    = 16'h0000;
    #10;

    if (outM !== 16'hBBBB) begin
      $display("S3 FAIL: outM = %h (expected BBBB)", outM);
    end else begin
      $display("S3 PASS: VRAM write/read at 0x4010 = %h", outM);
    end

    // S4: VRAM 領域の境界アドレス
    //   addressM = 0x5FFF(VRAM 最終番地)で同じことをやる
    //   addressM[14:13]=10、 addressM[12:0]=0x1FFF が vram の addr_a に渡る
    addressM = 15'h5FFF;
    inM      = 16'hCAFE;
    writeM   = 1'b1;
    #10;

    writeM = 1'b0;
    inM    = 16'h0000;
    #10;

    if (outM !== 16'hCAFE) begin
      $display("S4 FAIL: outM = %h (expected CAFE)", outM);
    end else begin
      $display("S4 PASS: VRAM boundary 0x5FFF = %h", outM);
    end

    // S5: CPUとdisplay_fsmの独立性
    //   CPUはVRAMの0x4010(中身 0xBBBB)を読む
    //   display_fsm は VRAM の 0x1FFF(0x5FFFの物理アドレス、中身0xCAFE)を読む
    //   → outM = 0xBBBB、 vram_data_out = 0xCAFE が同時に取れる
    addressM    = 15'h4010;     // CPU: VRAM 0x4010 を読みたい
    writeM      = 1'b0;
    vram_addr_b = 13'h1FFF;     // display_fsm: 物理 0x1FFF(= VRAM 0x5FFF 相当)を読みたい
    #10;

    if (outM !== 16'hBBBB) begin
      $display("S5a FAIL: outM = %h (expected BBBB)", outM);
    end else begin
      $display("S5a PASS: CPU got outM = %h", outM);
    end

    if (vram_data_out !== 16'hCAFE) begin
      $display("S5b FAIL: vram_data_out = %h (expected CAFE)", vram_data_out);
    end else begin
      $display("S5b PASS: display_fsm got vram_data_out = %h", vram_data_out);
    end

    $finish;
  end

endmodule
