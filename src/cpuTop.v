module cpuTop (
    input  wire clk,         // toggle.v からのクロック
    input  wire rstN,        // リセット
    input  wire testIn,      // TESTピン（CC用）

    // デバッグ用（外部へ出す）
    output wire [11:0] pcAddr,
    output wire [3:0]  accDebug,

    // ✅ 追加: 命令サイクルモニター
    output wire [2:0] cycleOut
);

    // ======== 内部配線 ========

    // cycle(0〜7) と sync
    wire [2:0] cycle;
    wire sync;

    // PC関連
    wire [3:0] pcLow, pcMid, pcHigh;

    // ROM関連
    wire [3:0] romData;

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
    wire [7:0] pairDout;

    // Stack
    wire [11:0] stackPcOut;
    wire [2:0]  stackSp;
    wire        stackOverflow;
    wire        stackUnderflow;

    // RAM / IO 関連（現状は未接続）
    wire [3:0] ramDataOut;
    wire [3:0] ioDataOut;
    wire [7:0] ioIn  = 8'd0;
    wire [7:0] ioOut;

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
        .pcLoad(1'b0),
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

    // decoder
    decoderWithCc uDecoder (
        .clk(clk),
        .rstN(rstN),
        .opr(romData),
        .opa(4'h0),
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
        .opa(4'h0),
        .carryIn(carryFlag),
        .aluResult(aluResult),
        .carryOut(carryOut),
        .zeroOut(zeroOut)
    );

    // Register File
    registerFile uRegisters (
        .clk(clk),
        .rstN(rstN),
        .regWe(1'b0),
        .regAddr(4'h0),
        .regDin(4'h0),
        .pairWe(1'b0),
        .pairAddr(4'h0),
        .pairDin(8'h00),
        .regDout(regDout),
        .pairDout(pairDout)
    );

    // Stack
    stack uStack (
        .clk(clk),
        .rstN(rstN),
        .push(1'b0),
        .pop(1'b0),
        .pcIn(pcAddr),
        .pcOut(stackPcOut),
        .sp(stackSp),
        .overflow(stackOverflow),
        .underflow(stackUnderflow)
    );

    // RAM
    ram uRam (
        .clk(clk),
        .rstN(rstN),
        .ramWe(1'b0),
        .ramRe(1'b0),
        .addr(12'd0),
        .dataIn(4'd0),
        .dataOut(ramDataOut)
    );

    // IO
    io uIo (
        .clk(clk),
        .rstN(rstN),
        .romIoWe(1'b0),
        .romIoRe(1'b0),
        .romIoAddr(4'd0),
        .ramIoWe(1'b0),
        .ramIoAddr(4'd0),
        .dataIn(4'd0),
        .romIoDataOut(ioDataOut),
        .ioIn(ioIn),
        .ioOut(ioOut)
    );

    // ======== デバッグ出力 ========
    assign accDebug = accOut;
    assign cycleOut = cycle;   // ✅ ここで外に出す

endmodule
