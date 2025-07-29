module cpu_microcycle (
    input  wire clk,
    input  wire rst,
    output reg [2:0] cycle,       // 0〜7を繰り返すカウンタ
    output wire fetch_phase,      // T0〜T2
    output wire read_phase,       // T3〜T4
    output wire exec_phase        // T5〜T7
);

    // 8サイクル管理カウンタ
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cycle <= 3'd0;
        end else begin
            cycle <= cycle + 3'd1;   // 0〜7を繰り返す
        end
    end

    // フェーズ判定信号
    assign fetch_phase = (cycle <= 3'd2);                // T0-T2
    assign read_phase  = (cycle >= 3'd3 && cycle <= 3'd4); // T3-T4
    assign exec_phase  = (cycle >= 3'd5);                // T5-T7

endmodule
