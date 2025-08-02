module registerFile (
    input  wire        clk,
    input  wire        rstN,

    // 単独レジスタ書き込み
    input  wire        regWe,       // 単一書き込み
    input  wire [3:0]  regAddr,     // 0〜15
    input  wire [3:0]  regDin,

    // ペア書き込み
    input  wire        pairWe,      // ペア書き込み
    input  wire [3:0]  pairAddr,    // 偶数レジスタの番号（0,2,4…）
    input  wire [7:0]  pairDin,     // 上位4bit:偶数レジスタ / 下位4bit:奇数レジスタ

    // 読み出し
    output wire [3:0]  regDout,     // 単独読み出し
    output wire [7:0]  pairDout     // ペア読み出し
);

    // 16本の4bitレジスタ
    reg [3:0] regs [0:15];
    integer i;

    // ⚠️【重要注意事項】
    // 1. pairAddr は必ず偶数を指定してください（偶数＋奇数のペアとして扱います）
    // 2. regWe と pairWe を同時に High にしないこと（同時書き込みの挙動は未定義）

    // リセット処理
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            for (i = 0; i < 16; i = i + 1) begin
                regs[i] <= 4'd0;
            end
        end else begin
            // 単独書き込み
            if (regWe) begin
                regs[regAddr] <= regDin;
            end
            // ペア書き込み（偶数・奇数同時）
            if (pairWe) begin
                regs[pairAddr]     <= pairDin[7:4];  // 偶数
                regs[pairAddr + 1] <= pairDin[3:0];  // 奇数
            end
        end
    end

    // 読み出し
    assign regDout  = regs[regAddr];
    assign pairDout = { regs[pairAddr], regs[pairAddr + 1] };

endmodule
