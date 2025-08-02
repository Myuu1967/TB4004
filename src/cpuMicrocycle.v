module cpuMicrocycle (
    input  wire clk,
    input  wire rstN,

    output reg  [2:0] cycle,       // 0〜7を繰り返すカウンタ
    output wire fetchPhase,        // T0〜T2
    output wire readPhase,         // T3〜T4
    output wire execPhase          // T5〜T7
);

    // 8サイクル管理カウンタ
    always @(posedge clk or posedge rstN) begin
        if (!rstN) begin
            cycle <= 3'd0;
        end else begin
            cycle <= cycle + 3'd1;   // 0〜7を繰り返す
        end
    end

    // フェーズ判定信号
//    assign fetchPhase = (cycle <= 3'd2);                  // T0-T2
//    assign readPhase  = (cycle >= 3'd3 && cycle <= 3'd4); // T3-T4
//    assign execPhase  = (cycle >= 3'd5);                  // T5-T7

endmodule  // cpuMicrocycle
