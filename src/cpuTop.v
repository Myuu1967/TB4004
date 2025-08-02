module cpuTop (
    input  wire clk,         // toggle.v からのクロック
    input  wire rstN,        // リセット
    input  wire testIn,      // TESTピン（CC用）

    // デバッグ用
    output wire [11:0] pcAddr,
    output wire [3:0]  accDebug
);

    // ======== 内部配線 ========

    // cycle(0〜7) と sync
    wire [2:0] cycle;
    wire sync;

    // PC関連
    wire [3:0] pcLow, pcMid, pcHigh;

    // ROM関連
    wire [3:0] romData;   // 4bit (M1=OPR, M2=OPA)

    // decoder関連
    wire aluEnable;
    wire [3:0] aluOp;
    wire accWe;
    wire tempWe;

    // ACC & Temp
    wire [3:0] accOut;
    wire [3:0] tempOut;

    // ALU
    wire [3:0] aluResult;
    wire       carryOut;
    wire       zeroOut;

    // CC（decoder内）
    wire carryFlag, zeroFlag, cplFlag, testFlag, CCout;

    // Register File
    wire [3:0] regDout;

    // ======== モジュール接続 ========

    // 8サイクル生成
    clockReset uClockReset (
        .toggleClk(clk),
        .rstN(rstN),
        .cycle(cycle),
        .sync(sync)
    );

    // PC
    pc uPc (
        .clk(clk),
        .rstN(rstN),
        .cycle(cycle),
        .pcLoad(1'b0),        // とりあえず固定（ジャンプ命令は後で）
        .pcNew(12'h000),
        .pcLow(pcLow),
        .pcMid(pcMid),
        .pcHigh(pcHigh),
        .pcAddr(pcAddr)
    );

    // ROM
    rom uRom (
        .addr(pcAddr),
        .cycle(cycle),
        .nibble(romData)
    );

    // decoder（CC統合）
    decoderWithCc uDecoder (
        .clk(clk),
        .rstN(rstN),
        .opr(romData),    
        .opa(4'h0),       // ← M2の実装がまだ途中
        .cycle(cycle),
        .carryFromAlu(carryOut),
        .zeroFromAlu(zeroOut),
        .testIn(testIn),

        .aluEnable(aluEnable),
        .aluOp(aluOp),
        .accWe(accWe),
        .tempWe(tempWe),

        .carryFlag(carryFlag),
        .zeroFlag(zeroFlag),
        .cplFlag(cplFlag),
        .testFlag(testFlag),

        .CCout(CCout)
    );

    // ACC & Temp
    accTempRegs uAccTemp (
        .clk(clk),
        .rstN(rstN),
        .aluResult(aluResult),
        .accOutForTemp(accOut),   // ✅ temp←ACCの対応時に追加
        .accWe(accWe),
        .tempWe(tempWe),
        .accOut(accOut),
        .tempOut(tempOut)
    );

    // ALU
    alu uAlu (
        .aluOp(aluOp),
        .accIn(accOut),
        .tempIn(tempOut),
        .opa(4'h0),           // ← 本来 regDout を繋ぐ予定
        .carryIn(carryFlag),
        .aluResult(aluResult),
        .carryOut(carryOut),
        .zeroOut(zeroOut)
    );

    // Register File（仮）
    registerFile uRegisters (
        .clk(clk),
        .rstN(rstN),
        .regWe(1'b0),
        .regAddr(4'h0),
        .regDin(4'h0),
        .regDout(regDout)
    );

    // Stack（未完全）
    stack uStack (
        .clk(clk),
        .rstN(rstN),
        .push(1'b0),
        .pop(1'b0),
        .pcIn(pcAddr),
        .pcOut(),
        .sp(),
        .overflow(),
        .underflow()
    );

    // デバッグ出力
    assign accDebug = accOut;

endmodule  // cpuTop
