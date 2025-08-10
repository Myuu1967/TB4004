module cpuMicrocycle (
    input  wire clk,
    input  wire rstN,

    // 2語命令の要求: 1語目の X3 で decoder から立つ
    input  wire needImm,

    // 2語目フェッチ中フラグ（M1/M2 を IR ではなく即値バッファへ）
    output reg  immFetchActive,

    // 8サイクルカウンタ
    output reg  [2:0] cycle,       // 0:A1 1:A2 2:A3 3:M1 4:M2 5:X1 6:X2 7:X3

    // ワンホットストローブ（使いやすさ優先）
    output wire a1, a2, a3, m1, m2, x1, x2, x3,

    // フェーズ／便利パルス
    output wire fetchPhase,        // A1-A3
    output wire readPhase,         // M1-M2
    output wire execPhase,         // X1-X3
    output wire pcIncPulse,        // A3 で 1
    output wire commitPulse,       // X3 で 1

    // IR/即値ラッチ用パルス
    output wire irOprLatch,        // M1 かつ immFetchActive=0
    output wire irOpaLatch,        // M2 かつ immFetchActive=0
    output wire immA2Latch,        // M1 かつ immFetchActive=1（A2）
    output wire immA1Latch         // M2 かつ immFetchActive=1（A1）
);

    // 8サイクル管理カウンタ
    always @(posedge clk or negedge rstN) begin
        if (!rstN) cycle <= 3'd0;
        else        cycle <= (cycle == 3'd7) ? 3'd0 : cycle + 3'd1;
    end

    // ワンホット
    assign a1 = (cycle == 3'd0);
    assign a2 = (cycle == 3'd1);
    assign a3 = (cycle == 3'd2);
    assign m1 = (cycle == 3'd3);
    assign m2 = (cycle == 3'd4);
    assign x1 = (cycle == 3'd5);
    assign x2 = (cycle == 3'd6);
    assign x3 = (cycle == 3'd7);

    // フェーズ
    assign fetchPhase = a1 | a2 | a3;
    assign readPhase  = m1 | m2;
    assign execPhase  = x1 | x2 | x3;

    // 便利パルス
    assign pcIncPulse   = a3; // A3 で PC+1（ジャンプ命令でも先に+1）
    assign commitPulse  = x3; // すべての副作用は X3 で確定

    // 2語フェッチ握り（16サイクル命令の簡易識別）
    always @(posedge clk or negedge rstN) begin
        if (!rstN) immFetchActive <= 1'b0;
        else if (x3 && needImm && !immFetchActive)
            immFetchActive <= 1'b1;   // 1語目の X3 で第2語を取りに行く
        else if (x3 && immFetchActive)
            immFetchActive <= 1'b0;   // 2語目の X3 を終えたら解除
    end

    // IR/即値ラッチパルス
    assign irOprLatch =  m1 & ~immFetchActive; // 1語目の OPR
    assign irOpaLatch =  m2 & ~immFetchActive; // 1語目の OPA
    assign immA2Latch =  m1 &  immFetchActive; // 2語目の A2
    assign immA1Latch =  m2 &  immFetchActive; // 2語目の A1
endmodule
