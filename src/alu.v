// alu.v
// ALU for LEG4

module alu (
    input  wire [3:0] aluOp,       // decoder からの ALU操作コード
    input  wire [3:0] aluSubOp,       // decoder からの ALU操作コード

    input  wire [3:0] accIn,       // ACCの値
    input  wire [3:0] tempIn,      // Tempの値
    input  wire [3:0] opa,         // オペランド（ROM下位4bit、またはレジスタ値）
    input  wire       carryIn,     // CCのCarryフラグ（ADD, SUB用）

    output reg  [3:0] aluResult,   // 演算結果（ACCやTempへ）
    output reg        carryOut,    // キャリーフラグ
    output reg        zeroOut      // ゼロ判定
);

    // ALU操作コード定義（完全版）
    localparam NOP = 4'h0;
    localparam JCN = 4'h1;          // 2Byte Command

    localparam H2  = 4'h2;
    localparam FIM = 1'b0;          // 2Byte Command
    localparam SRC = 1'b1;

    localparam H3  = 4'h3;
    localparam FIN = 1'b0;            
    localparam JIN = 1'b1;            

    localparam JUN = 4'h4;         // 2Byte Command
    localparam JMS = 4'h5;         // 2Byte Command
    localparam INC = 4'h6;
    localparam ISZ = 4'h7;         // 2Byte Command 
    localparam ADD = 4'h8;
    localparam SUB = 4'h9;
    localparam LD  = 4'hA;
    localparam XCH = 4'hB;
    localparam BBL = 4'hC;
    localparam LDM = 4'hD;

    localparam F_  = 4'hF;

    // F_系命令（CLB, CLC, など）
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

    localparam E_  = 4'hE;

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


    always @(*) begin
        // デフォルト値
        aluResult = 4'h0;
        carryOut  = 1'b0;
        zeroOut   = 1'b0;

        case (aluOp)
            // ===========================
            // NOP: 何もせずACCをそのまま通す
            // ===========================
            NOP: begin
                aluResult = accIn;
            end

            // JCN は ALU処理不要（分岐だけ）
            JCN: begin
                aluResult = accIn;
            end

            INC: begin
                {carryOut, aluResult} = opa + 4'h1;  // opa=regDout
            end

            // ===========================
            // ADD: ACC + reg + carry
            // ===========================
            ADD: begin
                {carryOut, aluResult} = accIn + opa + carryIn;
            end

            // ===========================
            // SUB: ACC - reg - carry（carryInはborrowとして扱う）
            // ===========================
            SUB: begin
                {carryOut, aluResult} = {1'b0, accIn} - opa - carryIn;
            end

            // ===========================
            // LD: reg → ACC
            // ===========================
            LD: begin
                aluResult = opa;        // opa=regDout
                carryOut  = carryIn;    // carryはそのまま維持
            end

            // ===========================
            // LDM: 即値 → ACC
            // ===========================
            LDM: begin
                aluResult = opa;        // OPA nibble をそのまま
                carryOut  = carryIn;    // carryは変化なし
            end

            // ===========================
            // BBL: 即値 → ACC
            // ===========================
            BBL: begin
                aluResult = opa;        // ✅ LDMと同じ処理
                carryOut  = carryIn;
            end

            // ===========================
            // XCH: ACCとレジスタの交換（ALU処理はしない）
            // ===========================
            XCH: begin
                aluResult = accIn;      // ALU経由せず、decoderで処理
            end

            F_: begin
                case (aluSubOp)
                    CLB: begin
                        aluResult = 4'h0;     // ACCをゼロ
                        carryOut  = 1'b0;     // 使わないけど一応ゼロ
                    end
                endcase
            end

            default: begin
                aluResult = 4'h0;
            end
        endcase

        // ===========================
        // Zeroフラグ設定
        // ===========================
        if (aluResult == 4'h0)
            zeroOut = 1'b1;
        else
            zeroOut = 1'b0;
    end

endmodule
