module cpuTopWith7seg (
    input  wire clk,           // FPGA基板クロック
    input  wire clkBtn,        // 手動クロックボタン
    input  wire [1:0] clkSel,  // クロック切替スイッチ
    input  wire extRstBtn,     // 🔵 外部リセットボタン（Lowでリセット）
//    input  wire testIn,        // TESTピン（in[0]など割り当て可）

    // 7セグLED出力
    output wire [7:0] seg,
    output wire [3:0] segDig,

    // LED（23〜30番ピン）
    output reg  [7:0] led
);

    // ========= 自動リセット(POR) =========
    reg [15:0] porCnt = 16'd0;
    reg        porRstN = 1'b0;

    always @(posedge clk) begin
        if (porCnt < 16'hFFFF) begin
            porCnt   <= porCnt + 1'b1;
            porRstN  <= 1'b0;   // カウント中はリセット状態
        end else begin
            porRstN  <= 1'b1;   // カウント完了でリセット解除
        end
    end

    // ========= 外部リセットボタンと統合 =========
    // ボタンが押されている間は強制リセット
    wire rstN = porRstN & extRstBtn;

    // ========= 分周クロック =========
    wire pulse1Hz, pulse10Hz;
    wire clk1Hz, clk10Hz;

    parameter MAX1HZ  = 24'd5999999;
    parameter MAX10HZ = 24'd599999;

    clkDiv u_clkDiv1Hz (
        .clk(clk),
        .rstN(rstN),
        .maxCount(MAX1HZ),
        .tc(pulse1Hz)
    );

    clkDiv u_clkDiv10Hz (
        .clk(clk),
        .rstN(rstN),
        .maxCount(MAX10HZ),
        .tc(pulse10Hz)
    );

    // ========= toggleで矩形波化 =========
    toggle u_toggle1Hz (
        .clk(clk),
        .rstN(rstN),
        .in(pulse1Hz),
        .out(clk1Hz)
    );

    toggle u_toggle10Hz (
        .clk(clk),
        .rstN(rstN),
        .in(pulse10Hz),
        .out(clk10Hz)
    );

    // ========= 手動クロック用 =========
    wire clkBtnDebounced;
    reg  prevBtn;
    wire stepClk;

    debounce uDebounce (
        .clk(clk),
        .rstN(rstN),
        .in(clkBtn),
        .out(clkBtnDebounced)
    );

    always @(posedge clk or negedge rstN) begin
        if (!rstN)
            prevBtn <= 1'b1;
        else
            prevBtn <= clkBtnDebounced;
    end

    assign stepClk = (prevBtn == 1'b1 && clkBtnDebounced == 1'b0);

    // ========= クロック切替 =========
    reg cpuClk;
    always @(*) begin
        case (clkSel)
            2'b00: cpuClk = stepClk;  // 手動
            2'b01: cpuClk = clk1Hz;
            2'b10: cpuClk = clk10Hz;
            2'b11: cpuClk = clk;      // フルスピード
        endcase
    end

    // ========= CPUコア =========
    wire [11:0] pcAddr;
    wire [3:0]  accDebug;
    wire [2:0]  cycleOut;
    wire        testIn;

    cpuTop uCpu (
        .clk(cpuClk),
        .rstN(rstN),        // ✅ 自動＋外部リセット併用
        .testIn(testIn),
        .pcAddr(pcAddr),
        .accDebug(accDebug),
        .cycleOut(cycleOut)
    );

    // ========= LEDワンホット点灯 =========
    always @(*) begin
        case (cycleOut)
            3'd0: led = 8'b00000001; // LED23
            3'd1: led = 8'b00000010; // LED24
            3'd2: led = 8'b00000100; // LED25
            3'd3: led = 8'b00001000; // LED26
            3'd4: led = 8'b00010000; // LED27
            3'd5: led = 8'b00100000; // LED28
            3'd6: led = 8'b01000000; // LED29
            3'd7: led = 8'b10000000; // LED30
            default: led = 8'b00000000;
        endcase
    end

    // ========= 7セグ変換 =========
    wire [7:0] segA, segB, segC, segD;

    drv7seg uDrvA (.in(pcAddr[11:8]), .dp(1'b0), .seg(segA));
    drv7seg uDrvB (.in(pcAddr[7:4]),  .dp(1'b0), .seg(segB));
    drv7seg uDrvC (.in(pcAddr[3:0]),  .dp(1'b0), .seg(segC));
    drv7seg uDrvD (.in(accDebug),     .dp(1'b0), .seg(segD));

    mux7seg uMux (
        .clk(clk),
        .rstN(rstN),
        .segA(segA),
        .segB(segB),
        .segC(segC),
        .segD(segD),
        .seg(seg),
        .segDig(segDig)
    );

endmodule  // cpuTopWith7seg
