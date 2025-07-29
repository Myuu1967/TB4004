module decoder_with_cc (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] opr,       // 命令コード (ROM上位4bit)
    input  wire [3:0] opa,       // オペランド (ROM下位4bit)
    input  wire [2:0] cycle,     // A1〜X3 (0〜7)
    input  wire       carry_from_alu,
    input  wire       zero_from_alu,
    input  wire       test_in,   // 外部TESTピン

    // ALU制御信号
    output reg        alu_enable,
    output reg  [3:0] alu_op,

    // レジスタ制御信号
    output reg        acc_we,
    output reg        temp_we,

    // CCフラグ
    output reg        carry_flag,
    output reg        zero_flag,
    output reg        cpl_flag,
    output reg        test_flag
);

    // 命令デコード処理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_flag <= 1'b0;
            zero_flag  <= 1'b0;
            cpl_flag   <= 1'b0;
            test_flag  <= 1'b0;

            alu_enable <= 1'b0;
            alu_op     <= 4'h0;

            acc_we     <= 1'b0;
            temp_we    <= 1'b0;

        end else begin
            // test_flagは常時外部ピンの値を反映
            test_flag <= test_in;

            // デフォルト値（命令により上書き）
            alu_enable <= 1'b0;
            alu_op     <= 4'h0;
            acc_we     <= 1'b0;
            temp_we    <= 1'b0;

            case (opr)
                4'h0: begin // NOP
                    // 何もしない
                end

                4'h8: begin // ADD (例: ACC = ACC + (OPA指定レジスタ) + Carry)
                    alu_enable <= 1'b1;
                    alu_op     <= 4'h8;  // ADD命令
                    if (cycle == 3'd7) begin // X3サイクルで結果書き込み
                        acc_we     <= 1'b1;
                        // フラグ更新
                        carry_flag <= carry_from_alu;
                        zero_flag  <= zero_from_alu;
                    end
                end

                4'hF: begin // CC系 (ここではCLCのみ)
                    // CLC (Carry Clear)
                    if (opa == 4'h1 && cycle == 3'd7) begin
                        carry_flag <= 1'b0;
                    end
                    // STC (Carry Set)
                    if (opa == 4'hA && cycle == 3'd7) begin
                        carry_flag <= 1'b1;
                    end
                    // CMC (Carry Complement)
                    if (opa == 4'h3 && cycle == 3'd7) begin
                        carry_flag <= ~carry_flag;
                    end
                end

                default: begin
                    // 未定義命令 → 何もしない
                end
            endcase
        end
    end

endmodule
