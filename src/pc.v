module pc (
    input  wire       clk,
    input  wire       rstN,

    // cycle[2:0] = 0〜7 (A1〜X3)
    input  wire [2:0] cycle,

    // ジャンプ／サブルーチン用（あとで使う）
    input  wire       pcLoad,        // PCを書き換える時にHigh
    input  wire [11:0] pcNew,        // 新しいPC値

    // 出力
    output reg  [3:0] pcLow,
    output reg  [3:0] pcMid,
    output reg  [3:0] pcHigh,
    output wire [11:0] pcAddr        // 12bitのフルアドレス
);

    assign pcAddr = {pcHigh, pcMid, pcLow};

    // PCインクリメント用
    reg [11:0] pcFull;

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            pcFull <= 12'd0;
        end else begin
            // PC書き換え（ジャンプ命令など）
            if (pcLoad) begin
                pcFull <= pcNew;
            end else if (cycle == 3'd2) begin
                // A3サイクル（0:A1,1:A2,2:A3）で PC+1
                pcFull <= pcFull + 12'd1;
            end
        end
    end

    // 4bit分割出力
    always @(*) begin
        pcLow  = pcFull[3:0];
        pcMid  = pcFull[7:4];
        pcHigh = pcFull[11:8];
    end

//    assign pcLow  = pcFull[3:0];
//    assign pcMid  = pcFull[7:4];
//    assign pcHigh = pcFull[11:8];


endmodule  // pc
