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
    output reg  [3:0] aluSubOp,

    // レジスタ制御信号
    output reg        accWe,
    output reg        tempWe,
    output reg        regWe,        // ✅ RegisterFile書き込み信号を追加

    // CCフラグ
    output reg        carryFlag,
    output reg        zeroFlag,
    output reg        cplFlag,
    output reg        testFlag,
    output reg        CCout,

    // ✅ 追加
    output reg        decoderUseImm,
    output reg        pairWe,
    output reg [3:0]  pairAddr,
    output reg [7:0]  pairDin
);

    // ======== ALU操作コード定義 ========
    localparam NOP = 4'h0;
    localparam INC = 4'h6;
    localparam ADD = 4'h8;
    localparam SUB = 4'h9;
    localparam LD  = 4'hA;
    localparam XCH = 4'hB;
    localparam LDM = 4'hD;
    localparam F_  = 4'hF;

    // （F_ 系命令のサブコード）
    localparam CLB = 4'h0;
    localparam CLC = 4'h1;
    localparam IAC = 4'h2;
    localparam CMC = 4'h3;
    localparam RAL = 4'h5;
    localparam RAR = 4'h6;
    localparam TCC = 4'h7;
    localparam DAC = 4'h8;
    localparam TCS = 4'h9;
    localparam STC = 4'hA;
    localparam DAA = 4'hB;
    localparam KBP = 4'hC;
    localparam DCL = 4'hD;

    // （E_ 系命令もあとで追加）

    // ======== CC出力ロジック ========
    always @(*) begin
        CCout = (~testFlag & opa[0]) | (carryFlag & opa[1]) | (zeroFlag & opa[2]);
        if (opa[3]) begin
            CCout = ~CCout;
        end
    end

    // ======== 命令デコード ========
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            // --- リセット時の初期化 ---
            carryFlag <= 1'b0;
            zeroFlag  <= 1'b0;
            cplFlag   <= 1'b0;

            aluEnable <= 1'b0;
            aluOp     <= 4'h0;
            aluSubOp  <= 4'h0;

            accWe     <= 1'b0;
            tempWe    <= 1'b0;
            regWe     <= 1'b0;
            decoderUseImm <= 1'b0;   // ✅ リセット時も初期化

            pairWe   <= 1'b0;
            pairAddr <= 4'd0;
            pairDin  <= 8'd0;

        end else begin
            // --- デフォルト値（毎クロック初期化） ---
            aluEnable <= 1'b0;
            aluOp     <= 4'h0;
            aluSubOp  <= 4'h0;

            accWe     <= 1'b0;
            tempWe    <= 1'b0;
            regWe     <= 1'b0;
            decoderUseImm <= 1'b0;   // ✅ リセット時も初期化

            // 毎サイクル初期化
            pairWe   <= 1'b0;
            pairAddr <= 4'd0;
            pairDin  <= 8'd0;

            // TESTピンは常時フラグに反映
            testFlag <= testIn;

            // 全命令共通：X1 (cycle=5) で temp←ACC
            if (cycle == 3'd5) begin
                tempWe <= 1'b1;
            end

            case (opr)
                // FIM命令（将来用）
                4'h2: begin
                    if (opa[0] == 1'b0) begin // FIM（RRR0）
                        if (cycle == 3'd7) begin
                            pairWe   <= 1'b1;
                            pairAddr <= {opa[3:1],1'b0};   // 偶数レジスタ
                        //    pairDin  <= 8'h??;             // TODO: ROMのD2D1 nibbleを結合
                        end
                    end
                end

                INC: begin
                    aluEnable <= 1'b1;   // X2 から ALU計算は常時動く
                    aluOp     <= INC;
                    if (cycle == 3'd7) begin  // ✅ X3 サイクルで書き込み
                        regWe     <= 1'b1; 
                        carryFlag <= carryFromAlu;
                        zeroFlag  <= zeroFromAlu;
                    end
                end

                ADD: begin
                    aluEnable <= 1'b1;
                    aluOp     <= ADD;
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        carryFlag <= carryFromAlu;
                        zeroFlag  <= zeroFromAlu;
                    end
                end

                // ===========================
                // SUB（ACC = ACC - reg - borrow）
                // ===========================
                SUB: begin
                    aluEnable <= 1'b1;
                    aluOp     <= SUB;
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        carryFlag <= carryFromAlu;
                        zeroFlag  <= zeroFromAlu;
                    end
                end

                // ===========================
                // LD（ACC ← reg）
                // ===========================
                LD: begin
                    aluEnable <= 1'b1;
                    aluOp     <= LD;
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        zeroFlag  <= zeroFromAlu;
                        // carryFlag は変更しない
                    end
                end

                // ===========================
                // XCH（ACCとレジスタの交換）
                // ===========================
                XCH: begin
                    if (cycle == 3'd7) begin
                        accWe   <= 1'b1;    // ACCにも書く
                        regWe   <= 1'b1;    // RegisterFileにも書く
                    end
                end

                // ===========================
                // BBL（RET命令）
                // ===========================
                BBL: begin
                    decoderUseImm <= 1'b1;   // ✅ BBLでも即値を使う
                    aluEnable <= 1'b1;
                    aluOp     <= BBL;
                    if (cycle == 3'd7) begin
                        accWe    <= 1'b1;
                        // stack からPCを戻す処理も必要だが後で追加
                    end
                end

                // ===========================
                // LDM（ACCに即値ロード）
                // ===========================
                LDM: begin
                    aluEnable <= 1'b1;
                    aluOp     <= LDM;  // ALU経由で即値をACCに書き込む
                    decoderUseImm <= 1'b1;    // ✅ ここに含める！
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        zeroFlag  <= zeroFromAlu;
                        // carryFlag は変更しない
                    end
                end

                // ===========================
                // F_（キャリー操作命令など）
                // ===========================
                F_: begin
                    aluEnable <= 1'b1;      // ALUを動かす
                    aluOp     <= F_;        // 大分類はF_
                    aluSubOp  <= opa;       // 下位4bitをALUに渡す（CLB/CLC/IAC…）

                    if (cycle == 3'd7) begin
                        case (opa)
                            4'h0: begin // CLB
                                accWe     <= 1'b1;
                                carryFlag <= 1'b0;
                            end

                            4'h1: begin // CLC
                                carryFlag <= 1'b0;
                            end

                            4'h2: begin // IAC
                                accWe     <= 1'b1;
                                carryFlag <= carryFromAlu;
                                zeroFlag  <= zeroFromAlu;
                            end

                            4'h3: begin // CMC
                                carryFlag <= ~carryFlag;
                            end

                            4'h4: begin // CMA
                                accWe     <= 1'b1;
                            end

                            4'h5: begin // RAL
                                accWe     <= 1'b1;
                                carryFlag <= carryFromAlu;
                            end

                            4'h6: begin // RAR
                                accWe     <= 1'b1;
                                carryFlag <= carryFromAlu;
                            end

                            4'h7: begin // TCC
                                accWe     <= 1'b1;
                                carryFlag <= 1'b0;
                            end

                            4'h8: begin // DAC
                                accWe     <= 1'b1;
                                carryFlag <= carryFromAlu;
                                zeroFlag  <= zeroFromAlu;
                            end

                            4'h9: begin // TCS
                                accWe     <= 1'b1;
                                carryFlag <= 1'b0;
                            end

                            4'hA: begin // STC
                                carryFlag <= 1'b1;
                            end

                            4'hB: begin // DAA
                                accWe     <= 1'b1;
                                carryFlag <= carryFromAlu; // BCD補正でcarry更新される可能性あり
                            end

                            4'hC: begin // KBP
                                accWe     <= 1'b1;
                            end

                            4'hD: begin // DCL
                                // TODO: メモリバンクセレクト信号を後で追加
                            end

                            default: begin
                                // 4'hE, 4'hFは未定義 or 予約
                            end
                        endcase
                    end
                end
                default: begin
                    // 何もしない（NOP扱い）
                end
            endcase
        end
    end

endmodule
