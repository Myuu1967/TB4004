module decoderWithCc (
    input  wire       clk,
    input  wire       rstN,
    input  wire [3:0] opr,          // 命令コード (ROM上位4bit)
    input  wire [3:0] opa,          // オペランド (ROM下位4bit)
    input  wire [2:0] cycle,        // A1〜X3 (0〜7)
    input  wire       carryFromAlu,
    input  wire       zeroFromAlu,
    input  wire       testFlag,     // 外部TESTピン
    input  wire [3:0] accIn,

    // 2語命令ハンドシェイク
    input  wire       immFetchActive, // cpuMicrocycle から
    input  wire [11:0] immAddr,        // ★ output→input に変更（cpuTopで生成した即値アドレスを受ける）
    output reg        needImm,        // 1語目X3で立てる（JUN/JMS/JCN 等）

    // ALU制御信号
    output reg        aluEnable,
    output reg  [3:0] aluOp,
    output reg  [3:0] aluSubOp,

    // レジスタ制御信号
    output reg        accWe,
    output reg        tempWe,
    output reg        regWe,        // ✅ RegisterFile書き込み信号を追加

    output reg        ramWe,
    output reg        ramRe,
    output reg        romRe,
    output reg        ioWe,
    output reg        ioRe,

    // CCフラグ
    output reg        carryFlag,
    output reg        zeroFlag,
    output reg        CCout,

    // ✅ 追加
    output reg [1:0]  aluSel,  // 00=reg, 01=imm, 10=RAM
    output reg        regSrcSel,
    output reg        pairWe,
    output reg [3:0]  pairAddr,
    output reg [7:0]  pairDin,

    output reg        bankSelWe,
    output reg [3:0]  bankSelData,

    // PC / スタック制御（cpuTopと口合わせ）
    output reg        pcLoad,         // JUN/JMS/JCN成立時にX3で1
    output reg [11:0] pcLoadData,     // 上記のロード値
    output reg        stackPush,      // JMS の2語目X31
    output reg        stackPop,       // BBL のX3で1（RETは未実装）

    // JINで使用　PC変更を指示
    output reg         pcLoadUsePair,
    // FINで使用　ROM[RRR[0]]をA2A1とおくためのもの
    output reg         finImm   // ← 第1語X3で1クロックだけ立てる（セット要求）

);

    // ============================
    // 4004 命令コード localparam
    // ===============================
    localparam NOP = 4'h0;   // No Operation
    localparam JCN = 4'h1;   // 条件ジャンプ
    localparam FIM = 4'h2;   // 即値ロード（レジスタペア）
    localparam SRC = 4'h2;   // レジスタペアをROM/RAMアクセスに使う
    localparam FIN = 4'h3;   // ROM間接ロード
    localparam JIN = 4'h3;   // ROM間接ジャンプ
    localparam JUN = 4'h4;   // 無条件ジャンプ
    localparam JMS = 4'h5;   // サブルーチンコール
    localparam INC = 4'h6;   // レジスタインクリメント
    localparam ISZ = 4'h7;   // インクリメントしてゼロならスキップ
    localparam ADD = 4'h8;   // ACC ← ACC + reg + Carry
    localparam SUB = 4'h9;   // ACC ← ACC - reg - Borrow
    localparam LD  = 4'hA;   // ACC ← reg
    localparam XCH = 4'hB;   // ACC と reg の交換
    localparam BBL = 4'hC;   // リターン（即値をACCにロード）
    localparam LDM = 4'hD;   // ACCに即値ロード
    localparam E_  = 4'hE;   // I/O・RAMアクセス命令群
    localparam F_  = 4'hF;   // ACC/Carry操作命令群

    // ===============================
    // F_ 系命令サブコード (1111 xxxx)
    // ===============================
    localparam CLB = 4'h0;   // ACC=0, Carry=0
    localparam CLC = 4'h1;   // Carry=0
    localparam IAC = 4'h2;   // ACC=ACC+1
    localparam CMC = 4'h3;   // Carry=~Carry
    localparam CMA = 4'h4;   // ACC=~ACC
    localparam RAL = 4'h5;   // 左ローテート (ACCとCarry)
    localparam RAR = 4'h6;   // 右ローテート (ACCとCarry)
    localparam TCC = 4'h7;   // ACC=Carry, Carry=0
    localparam DAC = 4'h8;   // ACC=ACC-1
    localparam TCS = 4'h9;   // if Carry=1→ACC=9 else ACC=10, Carry=0
    localparam STC = 4'hA;   // Carry=1
    localparam DAA = 4'hB;   // BCD補正
    localparam KBP = 4'hC;   // キーボードプロセス
    localparam DCL = 4'hD;   // メモリバンク切替

    // ===============================
    // E_ 系命令 (I/O・RAMアクセス)
    // ===============================
    localparam WRM = 4'h0;
    localparam WMP = 4'h1;
    localparam WRR = 4'h2;
    localparam WPM = 4'h3;
    localparam WR0 = 4'h4;
    localparam WR1 = 4'h5;
    localparam WR2 = 4'h6;
    localparam WR3 = 4'h7;

    localparam SBM = 4'h8;
    localparam RDM = 4'h9;
    localparam RDR = 4'hA;
    localparam ADM = 4'hB;
    localparam RD0 = 4'hC;
    localparam RD1 = 4'hD;
    localparam RD2 = 4'hE;
    localparam RD3 = 4'hF;

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

            aluEnable <= 1'b0;
            aluOp     <= 4'h0;
            aluSubOp  <= 4'h0;

            accWe     <= 1'b0;
            tempWe    <= 1'b0;
            regWe     <= 1'b0;
            ramWe     <= 1'b0;       // ✅ リセット時に初期化
            ramRe     <= 1'b0;
            romRe     <= 1'b0;
            ioWe      <= 1'b0;
            ioRe      <= 1'b0;

            aluSel    <= 2'b00;  // 00=reg, 01=imm, 10=RAM
            regSrcSel <= 1'b0;   // ✅ ← 追加！
            bankSelWe <= 1'b0;
            bankSelData <= 4'd0;

            pairWe   <= 1'b0;
            pairAddr <= 4'd0;
            pairDin  <= 8'd0;

            needImm     <= 1'b0;

            pcLoad      <= 1'b0;
            pcLoadData  <= 12'd0;
            stackPush   <= 1'b0;
            stackPop    <= 1'b0;

            pcLoadUsePair <= 1'b0;
            finImm      <= 1'b0;

        end else begin
            // --- デフォルト値（毎クロック初期化） ---
            aluEnable <= 1'b0;
            aluOp     <= 4'h0;
            aluSubOp  <= 4'h0;

            accWe     <= 1'b0;
            tempWe    <= 1'b0;
            regWe     <= 1'b0;
            ramWe     <= 1'b0;       // ✅ リセット時に初期化
            ramRe     <= 1'b0;
            romRe     <= 1'b0;
            ioWe      <= 1'b0;
            ioRe      <= 1'b0;

            aluSel <= 2'b11;  // 00=reg, 01=imm, 10=RAM, 11=未定義
            regSrcSel <= 1'b0;   // ✅ ← 追加！
            bankSelWe <= 1'b0;
            bankSelData <= 4'd0;

            pairWe   <= 1'b0;
            pairAddr <= 4'd0;
            pairDin  <= 8'd0;

            needImm     <= 1'b0;

            pcLoad      <= 1'b0;
            pcLoadData  <= 12'd0;
            stackPush   <= 1'b0;
            stackPop    <= 1'b0;

            pcLoadUsePair <= 1'b0;
            finImm      <= 1'b0;

            // 全命令共通：X1 (cycle=5) で temp←ACC
            if (cycle == 3'd5) begin
                tempWe <= 1'b1;
            end

            case (opr)
            //    4'h0: // NOP

                // OPR=4'h2 グループ: FIM/SRC
                4'h2: begin
                    if (opa[0] == 1'b0) begin
                        // FIM (RRR0) : レジスタペア ← #D2D1
                        if (!immFetchActive) begin
                            // 第1語X3で即値フェッチ要求
                            if (cycle == 3'd7) begin
                                needImm <= 1'b1;   // 次フレームでM1/M2に即値を取りに行く
                            end
                        end else begin
                            // 第2語（M1:immA2, M2:immA1 がラッチ済み）
                            if (cycle == 3'd7) begin
                                pairWe   <= 1'b1;                          // ペア書き込み
                                pairAddr <= {opa[3:1], 1'b0};              // 偶数境界に丸め
                                // immAddr = { irOpa, immA2, immA1 } を利用
                                // 下位8bitが D2D1 に相当
                                pairDin  <= {immAddr[7:4], immAddr[3:0]};  // = {immA2, immA1}
                            end
                        end
                    end else begin
                    // SRC (RRR1)
                        if (cycle == 3'd5) begin // X1 で“どのペアか”を提示
                          pairAddr <= {opa[3:1], 1'b0}; // 偶数境界に丸め
                        end
                        // 以降は既存ルールでOK：X2/X3は memAddr が {bankSel, pairDout}
                    end
                end

                // OPR=4'h3 グループ：FIN / JIN
                4'h3: begin
                  if (opa[0] == 1'b0) begin
                    // ==========================
                    // FIN (RRR0) 2語命令（最小：finImmのみ）
                    // ==========================
                    if (!immFetchActive) begin
                      // 第1語X3：即値フェッチ開始（次フレームM1/M2を“インデックス”から）
                      if (cycle == 3'd7) begin
                        needImm <= 1'b1;
                        finImm  <= 1'b1;  // cpuTopの immFromIndex をセット
                      end
                    end else begin
                      // 第2語X3：M1/M2で取得済みの {immA2,immA1} を RRRペアへ書込
                      if (cycle == 3'd7) begin
                        pairWe   <= 1'b1;
                        pairAddr <= {opa[3:1], 1'b0};       // RRRを偶数丸め
                        pairDin  <= {immAddr[7:4], immAddr[3:0]}; // = {immA2, immA1}
                      end
                    end

                  end else begin
                    // -------------------------
                    // JIN (RRR1): PCmid,low ← (RRR)
                    // -------------------------
                    if (cycle == 3'd5) begin  // X1
                      pairAddr <= {opa[3:1], 1'b0}; // 偶数境界へ丸め
                    end
                    if (cycle == 3'd7) begin  // X3
                      pcLoadUsePair <= 1'b1;       // cpuTopが {pcHigh, pairDout} にしてロード
                    end
                  end
                end

                // -------------------------------
                // JUN: 無条件ジャンプ（12bit）
                // -------------------------------
                4'h4 /* JUN */: begin
                    if (cycle==3'd7) begin      // X3 でのみ確定
                      if (!immFetchActive) begin
                        // 1語目X3：次サイクルのM1/M2で第2語を取りに行かせる
                        needImm <= 1'b1;
                      end else begin
                        // 2語目X3：フェッチ完了後、即値アドレスへ飛ぶ
                        pcLoad     <= 1'b1;
                        pcLoadData <= immAddr;  // cpuTop 生成の {A3,A2A1}
                      end
                    end
                end

                4'h5: begin // JMS
                    if (cycle==3'd7) begin
                      if (!immFetchActive) needImm <= 1'b1;
                      else begin
                        stackPush <= 1'b1;       // 戻り先= A3で+1済みのpcAddr（cpuTop側でpcInに接続済み）
                        pcLoad    <= 1'b1;       // コール先へ
                        pcLoadData<= immAddr;
                      end
                    end
                end

                INC: begin
                    aluEnable <= 1'b1;   // X2 から ALU計算は常時動く
                    aluOp     <= INC;
                    if (cycle == 3'd7) begin  // ✅ X3 サイクルで書き込み
                        regWe     <= 1'b1;
                        aluSel    <= 2'b00;  // 00=reg, 01=imm, 10=RAM
                        carryFlag <= carryFromAlu;
                        zeroFlag  <= zeroFromAlu;
                    end
                end

                ADD: begin
                    aluEnable <= 1'b1;
                    aluOp     <= ADD;
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        aluSel    <= 2'b00;  // 00=reg, 01=imm, 10=RAM
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
                        aluSel    <= 2'b00;  // 00=reg, 01=imm, 10=RAM
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
                        aluSel    <= 2'b00;  // 00=reg, 01=imm, 10=RAM
                        zeroFlag  <= zeroFromAlu;
                        // carryFlag は変更しない
                    end
                end

                // ===========================
                // XCH（ACCとレジスタの交換）
                // ===========================
                XCH: begin
                    if (cycle == 3'd7) begin
                        accWe       <= 1'b1;    // ACCにも書く
                        aluSel      <= 2'b00;   // 00=reg, 01=imm, 10=RAM
                        regWe       <= 1'b1;    // RegisterFileにも書く
                        regSrcSel   <= 1'b1;    // ✅ Tempから書き込み
                    end
                end

                // ===========================
                // BBL（RET命令）
                // ===========================
                BBL: begin
                    // ✅ BBLでも即値を使う
                    aluSel    <= 2'b01;  // 00=reg, 01=imm, 10=RAM
                    aluEnable <= 1'b1;
                    aluOp     <= BBL;
                    if (cycle == 3'd7) begin
                        accWe    <= 1'b1;
                        // stack からPCを戻す処理も必要だが後で追加
                        stackPop <= 1'b1;
                    end
                end

                // ===========================
                // LDM（ACCに即値ロード）
                // ===========================
                LDM: begin
                    aluEnable <= 1'b1;
                    aluOp     <= LDM;  // ALU経由で即値をACCに書き込む
                    aluSel    <= 2'b01;  // 00=reg, 01=imm, 10=RAM   // ✅ ここに含める！
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        zeroFlag  <= zeroFromAlu;
                        // carryFlag は変更しない
                    end
                end

                // ===========================
                // E_（I/O命令など）
                // ===========================
                E_: begin
                    case (opa)

                        // E_（1110）ブロック中。camelCase維持・タイミング統一：X2でread要求、X3でwrite/ACC反映
                        E_: begin
                            case (opa)

                                // ---------------------------
                                // RAMメモリ書き込み（選択MMキャラ） WRM
                                // ---------------------------
                                WRM: if (cycle == 3'd7) begin
                                    ramWe <= 1'b1;         // ★RAM本体への書き込み意思
                                    // ※ 0xFF0-0xFFFのMMIO窓ヒットは cpuTop 側で抑止(ramWeEff)し、代わりにioWeに流す
                                end

                                // ---------------------------
                                // RAM側の“出力ポート”系（MMIO窓へ出力）
                                //   WMP, WR0, WR1, WR2, WR3
                                // ---------------------------
                                WMP, WR0, WR1, WR2, WR3: if (cycle == 3'd7) begin
                                    ioWe <= 1'b1;          // ★cpuTopのramOutWinならramIoWeに振られる
                                end

                                // ---------------------------
                                // ROM出力ポート WRR（0x7F0-0x7FF）
                                // ---------------------------
                                WRR: if (cycle == 3'd7) begin
                                    ioWe <= 1'b1;          // ★cpuTopのromOutWinならromIoWeに振られる
                                end

                                // ---------------------------
                                // RAM読んでACC←RAM  RDM
                                // ---------------------------
                                RDM: begin
                                    if (cycle == 3'd6) begin
                                        ramRe     <= 1'b1; // ★X2で同期RAMのread要求
                                        aluSel    <= 2'b10; // 00=reg, 01=imm(OPA), 10=RAM, 11=IO
                                        aluEnable <= 1'b1;
                                        aluOp     <= LD;   // ACC←opa
                                    end
                                    if (cycle == 3'd7) begin
                                        accWe     <= 1'b1; // X3でACC確定
                                    end
                                end

                                // ---------------------------
                                // RAMを減算（borrow付き） SBM
                                // ---------------------------
                                SBM: begin
                                    if (cycle == 3'd6) begin
                                        ramRe     <= 1'b1;
                                        aluSel    <= 2'b10;
                                        aluEnable <= 1'b1;
                                        aluOp     <= SUB;
                                    end
                                    if (cycle == 3'd7) begin
                                        accWe     <= 1'b1;
                                        carryFlag <= carryFromAlu;  // 6502流: not-borrow
                                        zeroFlag  <= zeroFromAlu;
                                    end
                                end

                                // ---------------------------
                                // RAMを加算（carry付き） ADM
                                // ---------------------------
                                ADM: begin
                                    if (cycle == 3'd6) begin
                                        ramRe     <= 1'b1;
                                        aluSel    <= 2'b10;
                                        aluEnable <= 1'b1;
                                        aluOp     <= ADD;
                                    end
                                    if (cycle == 3'd7) begin
                                        accWe     <= 1'b1;
                                        carryFlag <= carryFromAlu;
                                        zeroFlag  <= zeroFromAlu;
                                    end
                                end

                                // ---------------------------
                                // RAMステータス読み RD0..RD3（読みはRAM経路）
                                // ---------------------------
                                RD0, RD1, RD2, RD3: begin
                                    if (cycle == 3'd6) begin
                                        ramRe     <= 1'b1;
                                        aluSel    <= 2'b10;
                                        aluEnable <= 1'b1;
                                        aluOp     <= LD;
                                    end
                                    if (cycle == 3'd7) begin
                                        accWe     <= 1'b1;
                                    end
                                end

                                // ---------------------------
                                // ROM入力ポート RDR（0x7E0-0x7EF）
                                // ---------------------------
                                RDR: begin
                                    if (cycle == 3'd6) begin
                                        ioRe      <= 1'b1; // ★cpuTopのromInWinならromIoReに振られる
                                        aluSel    <= 2'b11; // IO→ALU opa
                                        aluEnable <= 1'b1;
                                        aluOp     <= LD;
                                    end
                                    if (cycle == 3'd7) begin
                                        accWe     <= 1'b1; // ACC ← romIoDataOut
                                    end
                                end

                                // ---------------------------
                                // 未実装（4008/4009, 4289等）
                                // ---------------------------
                                WPM: begin
                                    // NOP扱い
                                end

                                default: begin
                                    // NOP
                                end
                            endcase
                        end
                    endcase
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
                                bankSelData <= accIn; // ★ 直接accInを参照
                                if (cycle == 3'd7) begin
                                    bankSelWe <= 1'b1;  // ★ X3でラッチ
                                end
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
