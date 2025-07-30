module stack (
    input  wire        clk,
    input  wire        rstN,

    // PUSH/POP制御
    input  wire        push,          // CALL命令など
    input  wire        pop,           // RET命令など

    // 書き込みデータ（PUSH時）
    input  wire [11:0] pcIn,

    // 読み出しデータ（POP時）
    output reg  [11:0] pcOut,

    // SP（スタックポインタ）
    output reg  [2:0] sp,

    // エラーフラグ（デバッグ用）
    output reg        overflow,
    output reg        underflow
);

    // 8段の12bitスタック
    reg [11:0] stackMem [0:7];

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            sp        <= 3'd0;
            overflow  <= 1'b0;
            underflow <= 1'b0;
        end else begin
            // PUSH
            if (push) begin
                if (sp == 3'd7) begin
                    overflow <= 1'b1; // 8段を超えた
                end else begin
                    sp <= sp + 3'd1;
                    stackMem[sp + 3'd1] <= pcIn;
                end
            end

            // POP
            if (pop) begin
                if (sp == 3'd0) begin
                    underflow <= 1'b1; // 空の状態でPOP
                    pcOut <= 12'h000;
                end else begin
                    pcOut <= stackMem[sp];
                    sp <= sp - 3'd1;
                end
            end
        end
    end

endmodule  // stack
