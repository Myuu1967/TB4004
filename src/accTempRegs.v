module accTempRegs (
    input  wire       clk,
    input  wire       rstN,

    // ALUからの4bit結果
    input  wire [3:0] aluResult,

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
            if (accWe)  accOut  <= aluResult;
            if (tempWe) tempOut <= aluResult;
        end
    end

endmodule
