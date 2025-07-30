module registerFile (
    input  wire        clk,
    input  wire        rstN,

    // 書き込み制御
    input  wire        regWe,       // 書き込みイネーブル
    input  wire [3:0]  regAddr,     // 書き込み/読み出しアドレス (0〜15)
    input  wire [3:0]  regDin,      // 書き込みデータ

    // 読み出し
    output wire [3:0]  regDout      // 読み出しデータ
);

    // 16本の4bitレジスタ
    reg [3:0] regs [0:15];
    integer i;

    // リセット時は全部0に
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            for (i = 0; i < 16; i = i + 1) begin
                regs[i] <= 4'd0;
            end
        end else begin
            if (regWe) begin
                regs[regAddr] <= regDin;
            end
        end
    end

    // 常時読み出し（コンビネーション）
    assign regDout = regs[regAddr];

endmodule  // registerFile
