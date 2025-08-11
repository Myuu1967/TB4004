module pc (
    input  wire        clk,
    input  wire        rstN,
    input  wire [2:0]  cycle,        // 0:A1 1:A2 2:A3 3:M1 4:M2 5:X1 6:X2 7:X3
    input  wire        pcLoad,       // X3で出す規約
    input  wire [11:0] pcLoadData,   // 統一名
    output wire [11:0] pcAddr,       // 現在のPC（= pcReg）
    output wire [3:0]  pcLow,
    output wire [3:0]  pcMid,
    output wire [3:0]  pcHigh
);
    reg [11:0] pcReg;

    always @(posedge clk or negedge rstN) begin
        if (!rstN)        pcReg <= 12'h000;
        else if (pcLoad)  pcReg <= pcLoadData;   // ジャンプ/RET確定
        else if (cycle==3'd2) pcReg <= pcReg + 12'd1; // A3で+1
    end

    assign pcAddr            = pcReg;
    assign {pcHigh,pcMid,pcLow} = pcReg;
endmodule
