module clock_reset (
    input  wire toggle_clk, // toggle.v からのクロック
    input  wire rst_n,      // 非同期リセット（Lowでリセット）
    output reg  [2:0] cycle, // 8サイクル (0〜7: A1〜X3)
    output reg  sync        // X3サイクルでHighになる1クロックパルス
);

    // 8サイクルカウンタ
    always @(posedge toggle_clk or negedge rst_n) begin
        if (!rst_n) begin
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

endmodule
