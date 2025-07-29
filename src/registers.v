module registers (
    input clk,
    input rst,                // リセット（仕様未定、今は無視してOK）

    // 4ビットアクセス
    input we4,
    input [3:0] addr4,
    input [3:0] wdata4,
    output reg [3:0] rdata4,

    // 8ビットアクセス
    input we8,
    input [2:0] addr8,
    input [7:0] wdata8,
    output reg [7:0] rdata8
);
    // 4ビットレジスタ × 16
    reg [3:0] regs [0:15];

    integer i;

    // --- レジスタ初期化（シミュレーション／FPGA初期化対応） ---
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            regs[i] = 4'b0000;
        end
    end

    // --- 書き込み処理 ---
    always @(posedge clk) begin
        if (we4) begin
            regs[addr4] <= wdata4;
        end
        if (we8) begin
            regs[{addr8, 1'b0}] <= wdata8[3:0];
            regs[{addr8, 1'b1}] <= wdata8[7:4];
        end
    end

    // --- クロック同期の読み出し ---
    always @(posedge clk) begin
        rdata4 <= regs[addr4];
        rdata8 <= {regs[{addr8, 1'b1}], regs[{addr8, 1'b0}]};
    end

endmodule
