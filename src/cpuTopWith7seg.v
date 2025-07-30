module cpuTopWith7seg (
    input  wire clk,           // FPGA基板クロック
    input  wire clkBtn,        // 手動クロックボタン
    input  wire [1:0] clkSel,  // クロック切替スイッチ
    input  wire nrst,          // リセット（負論理）
    input  wire testIn,        // TESTピン（in[0]など割り当て可）

    // 7セグLED出力
    output wire [7:0] seg,
    output wire [3:0] segDig
);

    // ========= 分周クロック =========
    wire clk1Hz;
    wire clk10Hz;

    parameter MAX1HZ  = 24'd5999999 ;
    parameter MAX10HZ =  24'd599999 ;
    parameter MAX1KHZ =    24'd5999 ;

    clkdiv u_div1Hz (
        .clk(clk),
        .rst(~nrst),
        .max(MAX1HZ),    // 基板クロック50MHz想定
        .tc(clk1Hz)
    );

    clkdiv u_div10Hz (
        .clk(clk),
        .rst(~nrst),
        .max(MAX10HZ),
        .tc(clk10Hz)
    );

    // ========= 手動クロック用（debounce + edge detect） =========
    wire clkBtnDebounced;
    reg  prevBtn;
    wire stepClk;

    // ボタンのチャタリング除去
    debounce u_debounce (
        .clk(clk),
        .rst(~nrst),
        .in(clkBtn),
        .out(clkBtnDebounced)
    );

    // 立下りエッジ検出 → 1クロックだけ High
    always @(posedge clk or negedge nrst) begin
        if (!nrst)
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

    cpuTop u_cpu (
        .clk(cpuClk),
        .rst_n(nrst),
        .test_in(testIn),
        .pc_addr(pcAddr),
        .acc_debug(accDebug)
    );

    // ========= 7セグ変換 =========
    wire [7:0] segA, segB, segC, segD;

    drv7seg u_drvA (.in(pcAddr[11:8]), .dp(1'b0), .seg(segA));
    drv7seg u_drvB (.in(pcAddr[7:4]),  .dp(1'b0), .seg(segB));
    drv7seg u_drvC (.in(pcAddr[3:0]),  .dp(1'b0), .seg(segC));
    drv7seg u_drvD (.in(accDebug),     .dp(1'b0), .seg(segD));

    mux7seg u_mux (
        .clk(clk),          // 7セグは速いクロックで切替
        .seg_a(segA),
        .seg_b(segB),
        .seg_c(segC),
        .seg_d(segD),
        .seg(seg),
        .seg_dig(segDig)
    );

endmodule   // cpuTopWith7seg
