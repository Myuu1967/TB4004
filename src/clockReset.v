module clockReset (
    input  wire toggleClk,   // toggle.v からのクロック
    input  wire rstN,        // 非同期リセット（Lowでリセット）
    output reg  [2:0] cycle, // 8サイクル (0〜7: A1〜X3)
    output reg  sync         // X3サイクルでHighになる1クロックパルス
);

    // 8サイクルカウンタ
    always @(posedge toggleClk or negedge rstN) begin
        if (!rstN) begin
            cycle <= 3'd0;
        end else begin
            if (cycle == 3'd7)
                cycle <= 3'd0;
            else
                cycle <= cycle + 3'd1;
        end
    end

    // SYNC信号生成（X3サイクルでHigh）
    always @(*) begin
        sync = (cycle == 3'd7);
    end

endmodule  // clockReset
