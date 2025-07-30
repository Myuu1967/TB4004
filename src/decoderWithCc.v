module decoderWithCc (
    input  wire       clk,
    input  wire       rstN,
    input  wire [3:0] opr,          // 命令コード (ROM上位4bit)
    input  wire [3:0] opa,          // オペランド (ROM下位4bit)
    input  wire [2:0] cycle,        // A1〜X3 (0〜7)
    input  wire       carryFromAlu,
    input  wire       zeroFromAlu,
    input  wire       testIn,       // 外部TESTピン

    // ALU制御信号
    output reg        aluEnable,
    output reg  [3:0] aluOp,

    // レジスタ制御信号
    output reg        accWe,
    output reg        tempWe,

    // CCフラグ
    output reg        carryFlag,
    output reg        zeroFlag,
    output reg        cplFlag,
    output reg        testFlag
);

    // 命令デコード処理
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            carryFlag <= 1'b0;
            zeroFlag  <= 1'b0;
            cplFlag   <= 1'b0;
            testFlag  <= 1'b0;

            aluEnable <= 1'b0;
            aluOp     <= 4'h0;

            accWe     <= 1'b0;
            tempWe    <= 1'b0;

        end else begin
            // testFlagは常時外部ピンの値を反映
            testFlag <= testIn;

            // デフォルト値（命令により上書き）
            aluEnable <= 1'b0;
            aluOp     <= 4'h0;
            accWe     <= 1'b0;
            tempWe    <= 1'b0;

            case (opr)
                4'h0: begin 
                    // NOP（何もしない）
                end

                4'h8: begin // ADD (例: ACC = ACC + (OPA指定レジスタ) + Carry)
                    aluEnable <= 1'b1;
                    aluOp     <= 4'h8;  // ADD命令
                    if (cycle == 3'd7) begin // X3サイクルで結果書き込み
                        accWe     <= 1'b1;
                        // フラグ更新
                        carryFlag <= carryFromAlu;
                        zeroFlag  <= zeroFromAlu;
                    end
                end

                4'hF: begin // CC系 (CLC, STC, CMC)
                    if (opa == 4'h1 && cycle == 3'd7) begin
                        carryFlag <= 1'b0; // CLC (Carry Clear)
                    end
                    if (opa == 4'hA && cycle == 3'd7) begin
                        carryFlag <= 1'b1; // STC (Carry Set)
                    end
                    if (opa == 4'h3 && cycle == 3'd7) begin
                        carryFlag <= ~carryFlag; // CMC (Carry Complement)
                    end
                end

                default: begin
                    // 未定義命令 → 何もしない
                end
            endcase
        end
    end

endmodule  // decoderWithCc
