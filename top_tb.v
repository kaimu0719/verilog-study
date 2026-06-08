`default_nettype none

module top_tb;

  reg clk;
  reg rst_n;

  wire lcd_sclk;
  wire lcd_mosi;
  wire lcd_dc;
  wire lcd_rst;
  wire lcd_cs;
  wire led;

  top u_top (
    .clk(clk),
    .rst_n(rst_n),
    .lcd_sclk(lcd_sclk),
    .lcd_mosi(lcd_mosi),
    .lcd_dc(lcd_dc),
    .lcd_rst(lcd_rst),
    .lcd_cs(lcd_cs),
    .led(led)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin

    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);

    rst_n = 0;
    #100;
    rst_n = 1;

    // --- 段階1: CPU が VRAM に書けたか ---
    #200;
    if (u_top.u_memory.u_vram.mem[0] === 16'hFFFF) begin
      $display("PASS stage1: VRAM[0] = FFFF (CPU wrote correctly)");
    end else begin
      $display("FAIL stage1: VRAM[0] = %h", u_top.u_memory.u_vram.mem[0]);
    end

    // --- 段階2: display_fsm が読み出せたか  ---
    // init_done が立つのを待つ
    wait(u_top.init_done == 1);

    wait(u_top.u_display_fsm.vram_addr == 13'd0);
    @(posedge clk); // vram_addr=0 を出した次のエッジ
    @(posedge clk); // BRAM レイテンシ分、もう1エッジ（vram_word 確定）
    if (u_top.u_display_fsm.vram_word === 16'hFFFF) begin
      $display("PASS stage2: display_fsm read VRAM[0] = FFFF");
    end else begin 
      $display("FAIL stage2: vram_word = %h", u_top.u_display_fsm.vram_word);
    end

    $finish;
  end

  // タイムアウト監視（独立した initial ブロック）
  initial begin
    #50000000;   // 5000万 ns = 500万サイクル(周期10ns)。
    $display("--- VRAM fill check ---");
    $display("  mem[0]    = %h (expect FFFF)", u_top.u_memory.u_vram.mem[0]);
    $display("  mem[100]  = %h (expect FFFF)", u_top.u_memory.u_vram.mem[100]);
    $display("  mem[4096] = %h (expect FFFF)", u_top.u_memory.u_vram.mem[4096]);
    $display("  mem[8191] = %h (expect FFFF)", u_top.u_memory.u_vram.mem[8191]);
    $finish;
  end

endmodule
