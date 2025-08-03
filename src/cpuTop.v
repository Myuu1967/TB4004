module cpuTop (
    input  wire clk,         // toggle.v からのクロック
    input  wire rstN,        // リセット
    input  wire testFlag,      // 外部から入力

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

    // RAM関連
    wire [3:0] ramDataOut;
    wire       ramWe, ramRe;
    reg  [3:0] bankSel;
    wire [11:0] ramAddr;
    wire [3:0]  ramDin;

    // decoder関連
    wire aluEnable;
    wire [3:0] aluOp;
    wire [3:0] aluSubOp;   // ✅ 新規追加
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
    wire carryFlag, zeroFlag, CCout;

    // Register File
    wire [3:0] regDout;
    wire       pairWe;
    wire [3:0] pairAddr;
    wire [7:0] pairDin;
    wire [7:0] pairDout;

    // ======== 仮追加 ========
    // decoderから将来出す信号
    // wire decoderUseImm;  // ← decoder からの本物の信号を受ける


    // M2でラッチされる予定の OPA nibble（今はROMのまま直結）
    wire [3:0] opaNibble;
    assign opaNibble = romData;    // TODO: M2 latch実装後に置き換え

    // ALUに渡すオペランド（即値かレジスタか）
    wire [3:0] aluOpaSrc;
    assign aluOpaSrc = (aluSel == 2'b00) ? regDout :
                       (aluSel == 2'b01) ? opaNibble :
                       (aluSel == 2'b10) ? ramDataOut :
                                       4'd0;

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

    // RAM本体
    ram uRam (
        .clk(clk),
        .rstN(rstN),
        .ramWe(ramWe),
        .ramRe(ramRe),
        .addr(ramAddr),
        .dataIn(ramDin),
        .dataOut(ramDataOut)
    );


    // ACC → RAMへ直結
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            bankSel <= 4'b0000;
        end else if (bankSelWe) begin
            bankSel <= bankSelData;
        end
    end

    assign ramDin = accOut;
    assign ramAddr = { bankSel, pairDout };   // 上位4bitがバンク、下位8bitがレジスタペアの値
    //assign ramRe = 1'b0;   // WRMだけなら読み出し不要



    // decoder（CC統合）
    decoderWithCc uDecoder (
        .clk(clk),
        .rstN(rstN),
        .opr(romData),    
        .opa(4'h0),       // TODO: M2 latch後にopaNibbleを接続
        .cycle(cycle),
        .carryFromAlu(carryOut),
        .zeroFromAlu(zeroOut),
        .testFlag(testFlag),

        .aluEnable(aluEnable),
        .aluOp(aluOp),
        .aluSubOp(aluSubOp),   // ✅ 追加
        .accWe(accWe),
        .tempWe(tempWe),
        .regWe(regWe),
        .ramWe(ramWe),
        .ramRe(ramRe),
        .romRe(romRe),
        .ioWe(ioWe),
        .ioRe(ioRe),

        .carryFlag(carryFlag),
        .zeroFlag(zeroFlag),
        .CCout(CCout),

        // ✅ decoderUseImm, regSrcSel 信号を追加
        .aluSel(aluSel),
        .regSrcSel(regSrcSel),
        // ✅ ペアレジスタ関連信号
        .pairWe(pairWe),
        .pairAddr(pairAddr),
        .pairDin(pairDin),

        .bankSelWe(bankSelWe),
        .bankSelData(bankSelData)
    );

    // ACC & Temp
    accTempRegs uAccTemp (
        .clk(clk),
        .rstN(rstN),
        .aluResult(aluResult),
        .accOutForTemp(accOut),   // ✅ temp←ACC の対応時に追加
        .accWe(accWe),
        .tempWe(tempWe),
        .accOut(accOut),
        .tempOut(tempOut)
    );

    // ALU
    alu uAlu (
        .aluOp(aluOp),
        .aluSubOp(aluSubOp),   // ✅ 追加
        .accIn(accOut),        // ✅ accOutWire→accOut に修正
        .tempIn(tempOut),
        .opa(aluOpaSrc),
        .carryIn(carryFlag),
        .aluResult(aluResult),
        .carryOut(carryOut),
        .zeroOut(zeroOut)
    );

    // 書き込みデータをmux
    wire [3:0] regDinMux;
    assign regDinMux = (regSrcSel) ? tempOut : accOut;

    // Register File（仮）
    registerFile uRegisters (
        .clk(clk),
        .rstN(rstN),

        // 単独レジスタ書き込み
        .regWe(regWe),
        .regAddr(opaNibble),   // OPA nibble がレジスタ番号
        .regDin(regDinMux),    // ✅ mux経由で書き込み
        // .regDin(accOut),       // XCHなどでACC→reg書き込み

        // ペア書き込み（FIM命令などで使用）
        .pairWe(pairWe),           // decoder から受け取る
        .pairAddr(pairAddr),       // decoder から受け取る
        .pairDin(pairDin),         // decoder から受け取る

        // 読み出し
        .regDout(regDout),
        .pairDout(pairDout)
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
