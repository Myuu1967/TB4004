module accTempRegs (
    input  wire       clk,
    input  wire       rst_n,

    // ALUからの4bit結果
    input  wire [3:0] alu_result,

    // 書き込み制御
    input  wire       acc_we,     // ACC書き込み
    input  wire       temp_we,    // Temp書き込み

    // 出力
    output reg  [3:0] acc_out,
    output reg  [3:0] temp_out
);

    // ACCとTempの4bitレジスタ
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_out  <= 4'd0;
            temp_out <= 4'd0;
        end else begin
            if (acc_we)  acc_out  <= alu_result;
            if (temp_we) temp_out <= alu_result;
        end
    end

endmodule
