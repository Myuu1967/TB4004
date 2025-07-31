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
    output reg        testFlag,

    output reg        CCout
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

    always @(*) begin
        CCout = ~testFlag | carryFlag | zeroFlag;
        if (cplFlag) begin
            CCout = ~CCout;
        end
    end


endmodule  // decoderWithCc
