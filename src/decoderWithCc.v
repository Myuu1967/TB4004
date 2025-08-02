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
    output reg        regWe,

    // CCフラグ
    output reg        carryFlag,
    output reg        zeroFlag,
    output reg        cplFlag,
    output reg        testFlag,
    output reg        CCout,

    // ✅ 追加
    output reg  decoderUseImm
);

    // ALU操作コード定義（完全版）
    localparam NOP = 4'h0;
    localparam JCN = 4'h1;          //  2Byte Command

    localparam H2  = 4'h2;
    localparam FIM = 1'b0;          //  2Byte Command
    localparam SRC = 1'b1;

    localparam H3  = 4'h3;
    localparam FIN = 1'b0;            
    localparam JIN = 1'b1;            

    localparam JUN = 4'h4;         //  2Byte Command
    localparam JMS = 4'h5;         //  2Byte Command
    localparam INC = 4'h6;
    localparam ISZ = 4'h7;         //  2Byte Command 
    localparam ADD = 4'h8;
    localparam SUB = 4'h9;
    localparam LD  = 4'hA;
    localparam XCH = 4'hB;
    localparam BBL = 4'hC;
    localparam LDM = 4'hD;

    localparam F_  = 4'hF;

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
        CCout = 1'b0; // デフォルト
        CCout = (~testFlag & opa[0]) | (carryFlag & opa[1]) | (zeroFlag & opa[2]);
        if (opa[3]) begin
            CCout = ~CCout;
        end
    end

    // 命令デコード処理
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            carryFlag <= 1'b0;
            zeroFlag  <= 1'b0;
            cplFlag   <= 1'b0;

            aluEnable <= 1'b0;
            aluOp     <= 4'h0;

            accWe     <= 1'b0;
            tempWe    <= 1'b0;
            regWe     <= 1'b0;    // ✅ これも毎サイクル初期化

        end else begin
            // testFlagは常時外部ピンの値を反映
            testFlag <= testIn;

            // デフォルト値（命令により上書き）
            aluEnable <= 1'b0;
            aluOp     <= 4'h0;
            accWe     <= 1'b0;
            tempWe    <= 1'b0;
            regWe     <= 1'b0;    // ✅ これも毎サイクル初期化

            // 全命令共通：X1 (cycle=5) で temp←ACC
            if (cycle == 3'd5) begin
                tempWe <= 1'b1;
            end
            case (opr)
                4'h0: begin 
                    // NOP（何もしない）
                end

                // ADD
                4'h8: begin
                    aluEnable <= 1'b1;
                    aluOp     <= 4'h8;
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        carryFlag <= carryFromAlu;
                        zeroFlag  <= zeroFromAlu;
                    end
                end

                // SUB
                4'h9: begin
                    aluEnable <= 1'b1;
                    aluOp     <= 4'h9;
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        carryFlag <= carryFromAlu;
                        zeroFlag  <= zeroFromAlu;
                    end
                end

                // LD
                4'hA: begin
                    aluEnable <= 1'b1;
                    aluOp     <= 4'hA;
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;
                        zeroFlag  <= zeroFromAlu;
                        // carryFlagは変更しない
                    end
                end

                // XCH（ACCとレジスタの交換）
                4'hB: begin
                    if (cycle == 3'd7) begin
                        accWe   <= 1'b1;    // ACCにも書く
                        regWe   <= 1'b1;    // RegisterFileにも書く
                    end
                end

                // LDM (ACCに即値ロード)
                4'hD: begin
                    aluEnable <= 1'b1;
                    aluOp     <= 4'hD;  // ALUにLDM指定
                    if (cycle == 3'd7) begin
                        accWe     <= 1'b1;       // ACCに書き込む
                        zeroFlag  <= zeroFromAlu; // Zeroフラグ更新
                        // carryFlag は変更しない
                    end
                end

                4'hF : begin // CC系 (CLC, STC, CMC)
                    if (opa == CLC && cycle == 3'd7) begin
                        carryFlag <= 1'b0; // CLC (Carry Clear)
                    end
                    if (opa == CMC && cycle == 3'd7) begin
                        carryFlag <= ~carryFlag; // CMC (Carry Complement)
                    end
                    if (opa == STC && cycle == 3'd7) begin
                        carryFlag <= 1'b1; // STC (Carry Set)
                    end
                end

                default: begin
                    // 未定義命令 → 何もしない
                end
            endcase
        end
    end

    always @(*) begin
        decoderUseImm = 1'b0;   // デフォルトは 0（即値ではない）
        case (opr)
            4'b1101: decoderUseImm = 1'b1;  // ✅ LDM のとき即値を使う
            // 必要に応じて LD A, #imm みたいな命令でも追加
            default: decoderUseImm = 1'b0;
        endcase
    end

endmodule  // decoderWithCc
