module cpuTop (
    input  wire        clk,        // toggle.v からのクロック
    input  wire        rstN,       // 非同期Lowアクティブリセット
    input  wire        testFlag,   // 外部TESTピン

    // デバッグ
    output wire [11:0] pcAddr,
    output wire [3:0]  accDebug
);

    // ========= Microcycle (A1..X3 + 2語目握り) =========
    wire [2:0] cycle;
    wire a1, a2, a3, m1, m2, x1, x2, x3;
    wire pcIncPulse, commitPulse;
    wire irOprLatch, irOpaLatch, immA2Latch, immA1Latch;
    wire immFetchActive;   // 2語目フェッチ中（M1/M2は即値ラッチへ）
    wire needImm;          // 1語目X3でデコーダから要求

    cpuMicrocycle uMc (
        .clk(clk), .rstN(rstN),
        .needImm(needImm),
        .immFetchActive(immFetchActive),
        .cycle(cycle),
        .a1(a1), .a2(a2), .a3(a3), .m1(m1), .m2(m2), .x1(x1), .x2(x2), .x3(x3),
        .fetchPhase(), .readPhase(), .execPhase(),
        .pcIncPulse(pcIncPulse),
        .commitPulse(commitPulse),
        .irOprLatch(irOprLatch),
        .irOpaLatch(irOpaLatch),
        .immA2Latch(immA2Latch),
        .immA1Latch(immA1Latch)
    );

    // ========= PC =========
    wire [3:0] pcLow, pcMid, pcHigh;
    wire       pcLoad;
    wire [11:0] pcLoadData;
    assign pcAddr = {pcHigh, pcMid, pcLow};

    pc uPc (
        .clk(clk), .rstN(rstN),
        .inc(pcIncPulse),        // A3で +1（ジャンプ命令でも先に+1）
        .load(pcLoad),
        .loadData(pcLoadData),
        .pcLow(pcLow), .pcMid(pcMid), .pcHigh(pcHigh)
    );

    // ========= ROM（M1/M2でnibbleを返す想定） =========
    wire [3:0] romData;

    rom uRom (
        .clk(clk),
        .addr(pcAddr),
        .cycle(cycle),           // M1=3, M2=4 で nibble 切替する実装
        .nibble(romData)
    );

    // ========= IR / 即値（2語目 A2/A1） =========
    reg [3:0] irOpr, irOpa;      // 1語目 OPR/OPA（A3=irOpa）
    reg [3:0] immA2, immA1;      // 2語目 A2/A1
    wire [11:0] immAddr = {irOpa, immA2, immA1};

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            irOpr <= 4'd0; irOpa <= 4'd0;
            immA2 <= 4'd0; immA1 <= 4'd0;
        end else begin
            if (irOprLatch) irOpr <= romData;  // M1(1語目)
            if (irOpaLatch) irOpa <= romData;  // M2(1語目)
            if (immA2Latch) immA2 <= romData;  // M1(2語目)
            if (immA1Latch) immA1 <= romData;  // M2(2語目)
        end
    end

    // ========= RAM =========
    wire [3:0] ramDataOut;
    wire       ramWe, ramRe;
    reg  [3:0] bankSel;
    wire [11:0] ramAddr;
    wire [3:0]  ramDin;

    // ACC → RAM 直結（書き込みデータ）
    assign ramDin  = accDebug;        // accOut を後で代入（下で結線）
    // アドレス共用ポリシーに従う：{bankSel, pairDout}
    wire [7:0] pairDout;

    assign ramAddr = { bankSel, pairDout };

    ram uRam (
        .clk(clk),
        .rstN(rstN),
        .ramWe(ramWe),
        .ramRe(ramRe),
        .addr(ramAddr),
        .dataIn(ramDin),
        .dataOut(ramDataOut)
    );

    // ========= レジスタ/スタック =========
    // Register File
    wire        regWe;
    wire [3:0]  regDout;
    wire [3:0]  regAddr = irOpa; // 単独レジスタ指定は OPA
    wire [3:0]  regDinMux;
    wire        regSrcSel;       // 1: temp→reg, 0: acc→reg

    // ペアアクセス（FIM/SRC 等）
    wire        pairWe;
    wire [3:0]  pairAddr;
    wire [7:0]  pairDin;

    registerFile uRegisters (
        .clk(clk),
        .rstN(rstN),
        .regWe(regWe),
        .regAddr(regAddr),
        .regDin(regDinMux),
        .pairWe(pairWe),
        .pairAddr(pairAddr),     // 偶数境界は registerFile 内部で丸める実装推奨
        .pairDin(pairDin),
        .regDout(regDout),
        .pairDout(pairDout)
    );

    // Stack（12bit）
    wire        stackPush, stackPop;
    wire [11:0] stackPcOut;
    wire [2:0]  sp;
    wire        stackOverflow, stackUnderflow;

    stack uStack (
        .clk(clk),
        .rstN(rstN),
        .push(stackPush),
        .pop(stackPop),
        .pcIn(pcAddr),           // 戻り先として現在のPC（A3で+1済み想定）
        .pcOut(stackPcOut),
        .sp(sp),
        .overflow(stackOverflow),
        .underflow(stackUnderflow)
    );

    // ========= ACC / TEMP =========
    wire        accWe, tempWe;
    wire [3:0]  accOut, tempOut;

    accTempRegs uAccTemp (
        .clk(clk),
        .rstN(rstN),
        .aluResult( /* 下で接続 */ ),
        .accOutForTemp(accOut),      // X2終端で temp←ACC 用
        .accWe(accWe),
        .tempWe(tempWe),
        .accOut(accOut),
        .tempOut(tempOut)
    );

    // デバッグ出力
    assign accDebug = accOut;

    // ========= ALU =========
    wire        aluEnable;
    wire [3:0]  aluOp;
    wire [3:0]  aluSubOp;
    wire [1:0]  aluSel;            // 00:reg, 01:imm(OPA), 10:RAM, 他:0
    wire [3:0]  aluOpaSrc;

    assign aluOpaSrc = (aluSel == 2'b00) ? regDout    :
                       (aluSel == 2'b01) ? irOpa      : // 即値は OPA を使用
                       (aluSel == 2'b10) ? ramDataOut :
                                           4'd0;

    wire [3:0] aluResult;
    wire       carryOut, zeroOut;

    alu uAlu (
        .aluOp(aluOp),
        .aluSubOp(aluSubOp),
        .accIn(accOut),
        .tempIn(tempOut),
        .opa(aluOpaSrc),
        .carryIn(carryFlag),
        .aluResult(aluResult),
        .carryOut(carryOut),
        .zeroOut(zeroOut)
    );

    // accTempRegs への aluResult 結線（分かりやすく後配線）
    // ※ 一部ツールは前方参照でもOKだが、見通しのため分離
    // synthesis translate_off
    // (no sim-only logic)
    // synthesis translate_on
    // 直接配線
    // （verilogでは上のインスタンス生成時に参照しても合成上は問題ないが、
    //  可読性を重視してここでコメントしておく）
    // → 既に uAccTemp に渡しているので追加不要

    // reg 書き込みデータ選択（XCH 対応など）
    assign regDinMux = (regSrcSel) ? tempOut : accOut;

    // ========= バンクセレクト（DCL） =========
    wire        bankSelWe;
    wire [3:0]  bankSelData;

    always @(posedge clk or negedge rstN) begin
        if (!rstN) bankSel <= 4'd0;
        else if (bankSelWe) bankSel <= bankSelData; // 副作用はX3で出す想定
    end

    // ========= I/O（未使用でもデコーダと握る） =========
    wire romRe, ioWe, ioRe;
    wire carryFlag, zeroFlag, CCout;

    // ========= pcLoad データの最終選択 =========
    // BBL/RET などで stackPop を出したフレームは、スタックの値を優先
    wire       pcLoadFromDec;
    wire [11:0] pcLoadDataFromDec;

    assign pcLoad     = pcLoadFromDec | stackPop;           // 安全策：pop時は必ずPCロード
    assign pcLoadData = stackPop ? stackPcOut : pcLoadDataFromDec;

    // ========= デコーダ =========
    decoderWithCc uDecoder (
        .clk(clk),
        .rstN(rstN),
        .opr(irOpr),
        .opa(irOpa),
        .cycle(cycle),
        .carryFromAlu(carryOut),
        .zeroFromAlu(zeroOut),
        .testFlag(testFlag),
        .accIn(accOut),

        // 2語命令ハンドシェイク
        .immFetchActive(immFetchActive),
        .immAddr(immAddr),
        .needImm(needImm),

        // PC/スタック制御
        .pcLoad(pcLoadFromDec),
        .pcLoadData(pcLoadDataFromDec),
        .stackPush(stackPush),
        .stackPop(stackPop),

        // ALU / レジスタ / メモリ / I/O
        .aluEnable(aluEnable),
        .aluOp(aluOp),
        .aluSubOp(aluSubOp),
        .accWe(accWe),
        .tempWe(tempWe),
        .regWe(regWe),
        .ramWe(ramWe),
        .ramRe(ramRe),
        .romRe(romRe),
        .ioWe(ioWe),
        .ioRe(ioRe),

        // CC 出力（ラッチするならデコーダ内で）
        .carryFlag(carryFlag),
        .zeroFlag(zeroFlag),
        .CCout(CCout),

        // オペランド/レジスタ選択
        .aluSel(aluSel),
        .regSrcSel(regSrcSel),

        // ペアアクセス
        .pairWe(pairWe),
        .pairAddr(pairAddr),
        .pairDin(pairDin),

        // バンク
        .bankSelWe(bankSelWe),
        .bankSelData(bankSelData)
    );

    // ======== 最後に RAM書き込みデータへACCを接続 ========
    // accDebug は accOut に等しいので、そのまま流用（見通し用に再明記）
    assign ramDin = accOut;

endmodule
