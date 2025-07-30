module accTempRegs (
    input  wire       clk,
    input  wire       rstN,        // ← rst_n → rstN に変更

    // ALUからの4bit結果
    input  wire [3:0] aluResult,   // ← alu_result → aluResult

    // 書き込み制御
    input  wire       accWe,       // ← acc_we → accWe
    input  wire       tempWe,      // ← temp_we → tempWe

    // 出力
    output reg  [3:0] accOut,      // ← acc_out → accOut
    output reg  [3:0] tempOut      // ← temp_out → tempOut
);

    // ACCとTempの4bitレジスタ
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            accOut  <= 4'd0;
            tempOut <= 4'd0;
        end else begin
            if (accWe)  accOut  <= aluResult;
            if (tempWe) tempOut <= aluResult;
        end
    end

endmodule
