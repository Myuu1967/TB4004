module accTempRegs (
    input  wire       clk,
    input  wire       rstN,

    // ALUからの4bit結果
    input  wire [3:0] aluResult,
    // ACCの値（tempに書き込む用）
    input  wire [3:0] accOutForTemp,  // ✅ 新規追加

    // 書き込み制御
    input  wire       accWe,
    input  wire       tempWe,

    // 出力
    output reg  [3:0] accOut,
    output reg  [3:0] tempOut
);

    // ACCとTempの4bitレジスタ
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            accOut  <= 4'd0;
            tempOut <= 4'd0;
        end else begin
            // ✅ temp←ACC の処理
            if (tempWe) tempOut <= accOutForTemp;

            // ✅ ACC 書き込み（ALU結果）
            if (accWe)  accOut  <= aluResult;

//            if (accWe)  accOut  <= aluResult;
//            if (tempWe) tempOut <= aluResult;
        end
    end

endmodule
