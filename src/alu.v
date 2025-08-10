// alu.v
// ALU for TB4004 FPGA Project – 全命令対応版

module alu (
    input  wire [3:0] aluOp,       // decoder からの ALU操作コード（メイン）
    input  wire [3:0] aluSubOp,    // decoder からの ALUサブ操作コード (F_系で使用)

    input  wire [3:0] accIn,       // ACCの値
    input  wire [3:0] tempIn,      // Tempの値（XCH等で使用）
    input  wire [3:0] opa,         // オペランド（ROM下位4bit、またはレジスタ値）
    input  wire       carryIn,     // Carryフラグ（ADD, SUB, F_命令などで使用）

    output reg  [3:0] aluResult,   // 演算結果（ACCやTempへ）
    output reg        carryOut,    // キャリーフラグ
    output reg        zeroOut      // ゼロ判定
);

    // ===============================
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

    // ===============================
    // ALU処理本体
    // ===============================
    always @(*) begin
        // デフォルト値
        aluResult = accIn;
        carryOut  = carryIn;
        zeroOut   = 1'b0;

        case (aluOp)
            // ---------------------------
            // NOP: 何もしない
            // ---------------------------
            NOP: begin
                aluResult = accIn;
                carryOut  = carryIn;
            end

            // ---------------------------
            // JCN, FIM, SRC, FIN, JIN, JUN, JMS, ISZ は
            // ALUで処理しない（PC操作のみ）
            // ---------------------------
            JCN, FIM, SRC, FIN, JIN, JUN, JMS, ISZ: begin
                aluResult = accIn;
                carryOut  = carryIn;
            end

            // ---------------------------
            // INC: reg + 1
            // ---------------------------
            INC: begin
                {carryOut, aluResult} = opa + 4'h1;
            end

            // ---------------------------
            // ADD: ACC + reg + carry
            // ---------------------------
            ADD: begin
                {carryOut, aluResult} = accIn + opa + carryIn;
            end

            // ---------------------------
            // SUB: ACC - reg - borrow  ( C=1: no borrow )
            // ---------------------------
            SUB: begin
                {carryOut, aluResult} = {1'b0, accIn} - {1'b0, opa} - 5'd1 + {4'd0, carryIn};
            end

            // ---------------------------
            // LD: reg → ACC
            // ---------------------------
            LD: begin
                aluResult = opa;
                carryOut  = carryIn;   // carryはそのまま
            end

            // ---------------------------
            // LDM: 即値 → ACC
            // ---------------------------
            LDM: begin
                aluResult = opa;
                carryOut  = carryIn;
            end

            // ---------------------------
            // BBL: 即値 → ACC (Return)
            // ---------------------------
            BBL: begin
                aluResult = opa;
                carryOut  = carryIn;
            end

            // ---------------------------
            // XCH: ACCとreg交換 → ALUでは何もしない
            // ---------------------------
            XCH: begin
                aluResult = accIn;
                carryOut  = carryIn;
            end

            // ---------------------------
            // ✅ F_ 系命令 (1111 xxxx)
            // ---------------------------
            F_: begin
                case (aluSubOp)
                    CLB: begin
                        aluResult = 4'h0;
                        carryOut  = 1'b0;
                    end
                    CLC: begin
                        aluResult = accIn;
                        carryOut  = 1'b0;
                    end
                    IAC: begin
                        {carryOut, aluResult} = accIn + 4'h1;
                    end
                    CMC: begin
                        aluResult = accIn;
                        carryOut  = ~carryIn;
                    end
                    CMA: begin
                        aluResult = ~accIn;
                        carryOut  = carryIn;
                    end
                    RAL: begin
                        {carryOut, aluResult} = {accIn, carryIn};
                    end
                    RAR: begin
                        {aluResult, carryOut} = {carryIn, accIn};
                    end
                    TCC: begin
                        aluResult = {3'b000, carryIn};
                        carryOut  = 1'b0;
                    end
                    DAC: begin
                        {carryOut, aluResult} = {1'b0, accIn} - 5'd1;
                    end
                    TCS: begin
                        aluResult = (carryIn) ? 4'd9 : 4'd10;
                        carryOut  = 1'b0;
                    end
                    STC: begin
                        aluResult = accIn;
                        carryOut  = 1'b1;
                    end
                    DAA: begin
                        if (accIn >= 4'd10 || carryIn) begin
                            {carryOut, aluResult} = accIn + 4'd6;
                        end else begin
                            aluResult = accIn;
                            carryOut  = carryIn;
                        end
                    end
                    KBP: begin
                        case (accIn)
                            4'd0: aluResult = 4'd0;
                            4'd1: aluResult = 4'd1;
                            4'd2: aluResult = 4'd2;
                            4'd4: aluResult = 4'd3;
                            4'd8: aluResult = 4'd4;
                            default: aluResult = 4'd15;
                        endcase
                        carryOut = carryIn;
                    end
                    DCL: begin
                        aluResult = accIn; // メモリバンク切替は外部で処理
                        carryOut  = carryIn;
                    end
                    default: begin
                        aluResult = accIn;
                        carryOut  = carryIn;
                    end
                endcase
            end

            // ---------------------------
            // ✅ E_ 系命令 (1110 xxxx)
            // ALU自体はI/OやRAMアクセスの結果を渡すだけ（ここでは処理なし）
            // ---------------------------
            E_: begin
                aluResult = accIn;
                carryOut  = carryIn;
            end

            default: begin
                aluResult = accIn;
                carryOut  = carryIn;
            end
        endcase

        // ===========================
        // Zeroフラグ設定
        // ===========================
        zeroOut = (aluResult == 4'h0);
    end

endmodule
