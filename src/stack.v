module stack (
    input  wire        clk,
    input  wire        rst_n,

    // PUSH/POP制御
    input  wire        push,          // CALL命令など
    input  wire        pop,           // RET命令など

    // 書き込みデータ（PUSH時）
    input  wire [11:0] pc_in,

    // 読み出しデータ（POP時）
    output reg  [11:0] pc_out,

    // SP（スタックポインタ）
    output reg  [2:0] sp,

    // エラーフラグ（デバッグ用）
    output reg        overflow,
    output reg        underflow
);

    // 8段の12bitスタック
    reg [11:0] stack_mem [0:7];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
                    stack_mem[sp + 3'd1] <= pc_in;
                end
            end

            // POP
            if (pop) begin
                if (sp == 3'd0) begin
                    underflow <= 1'b1; // 空の状態でPOP
                    pc_out <= 12'h000;
                end else begin
                    pc_out <= stack_mem[sp];
                    sp <= sp - 3'd1;
                end
            end
        end
    end

endmodule
