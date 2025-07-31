module cpuTopWith7seg (
    input  wire clk,           // FPGA基板クロック
    input  wire clkBtn,        // 手動クロックボタン
    input  wire [1:0] clkSel,  // クロック切替スイッチ
    input  wire nRst,          // リセット（負論理）
    input  wire testIn,        // TESTピン（in[0]など割り当て可）

    // 7セグLED出力
    output wire [7:0] seg,
    output wire [3:0] segDig
);

// cpuTopWith7seg.v 抜粋

    // ========= 分周クロック =========
    wire pulse1Hz, pulse10Hz;
    wire clk1Hz, clk10Hz;   // ← toggle後の矩形波

    parameter MAX1HZ  = 24'd5999999;
    parameter MAX10HZ = 24'd599999;
    parameter MAX1KHZ = 24'd5999;

    clkDiv u_clkDiv1Hz (        // ← キャメル記法に変更
        .clk(clk),
        .rst(~nRst),
        .maxCount(MAX1HZ),
        .tc(pulse1Hz)
    );

    clkDiv u_clkDiv10Hz (
        .clk(clk),
        .rst(~nRst),
        .maxCount(MAX10HZ),
        .tc(pulse10Hz)
    );

    // ========= toggleを挟んで矩形波化 =========
    toggle u_toggle1Hz (
        .clk(clk),
        .rst(~nRst),
        .in(pulse1Hz),
        .out(clk1Hz)
    );

    toggle u_toggle10Hz (
        .clk(clk),
        .rst(~nRst),
        .in(pulse10Hz),
        .out(clk10Hz)
    );

    // ========= クロック切替 =========
    reg cpuClk;
    always @(*) begin
        case (clkSel)
            2'b00: cpuClk = stepClk;  // 手動クロック
            2'b01: cpuClk = clk1Hz;   // toggle後の矩形波
            2'b10: cpuClk = clk10Hz;  // toggle後の矩形波
            2'b11: cpuClk = clk;      // フルスピード
        endcase
    end

    // ========= 手動クロック用（debounce + edge detect） =========
    wire clkBtnDebounced;
    reg  prevBtn;
    wire stepClk;

    // ボタンのチャタリング除去
    debounce uDebounce (
        .clk(clk),
        .rst(~nRst),
        .in(clkBtn),
        .out(clkBtnDebounced)
    );

    // 立下りエッジ検出 → 1クロックだけ High
    always @(posedge clk or negedge nRst) begin
        if (!nRst)
            prevBtn <= 1'b1;
        else
            prevBtn <= clkBtnDebounced;
    end
    assign stepClk = (prevBtn == 1'b1 && clkBtnDebounced == 1'b0);

    // ========= クロック切替 =========
    reg cpuClk;
    always @(*) begin
        case (clkSel)
            2'b00: cpuClk = stepClk;  // ボタン1回押すごとに1ステップ
            2'b01: cpuClk = clk1Hz;   // 1Hz
            2'b10: cpuClk = clk10Hz;  // 10Hz
            2'b11: cpuClk = clk;      // フルスピード（50MHz）
        endcase
    end

    // ========= CPUコア =========
    wire [11:0] pcAddr;
    wire [3:0]  accDebug;

    cpuTop uCpu (
        .clk(cpuClk),
        .rstN(nRst),
        .testIn(testIn),
        .pcAddr(pcAddr),
        .accDebug(accDebug)
    );

    // ========= 7セグ変換 =========
    wire [7:0] segA, segB, segC, segD;

    drv7seg uDrvA (.in(pcAddr[11:8]), .dp(1'b0), .seg(segA));
    drv7seg uDrvB (.in(pcAddr[7:4]),  .dp(1'b0), .seg(segB));
    drv7seg uDrvC (.in(pcAddr[3:0]),  .dp(1'b0), .seg(segC));
    drv7seg uDrvD (.in(accDebug),     .dp(1'b0), .seg(segD));

    mux7seg uMux (
        .clk(clk),          // 7セグは速いクロックで切替
        .segA(segA),
        .segB(segB),
        .segC(segC),
        .segD(segD),
        .seg(seg),
        .segDig(segDig)
    );

endmodule  // cpuTopWith7seg
