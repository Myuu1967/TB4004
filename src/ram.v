module ram (
    input  wire        clk,
    input  wire        rstN,
    input  wire        ramWe,
    input  wire        ramRe,
    input  wire [11:0] addr,
    input  wire [3:0]  dataIn,
    output reg  [3:0]  dataOut
);

    // 4bit × 4K RAM
    reg [3:0] ramMem [0:4095];
    integer i;

    // 初期化
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            for (i = 0; i < 2000; i = i + 1) begin
                ramMem[i] <= 4'd0;
            end
            for (i = 2000; i < 3000; i = i + 1) begin
                ramMem[i] <= 4'd0;
            end
            for (i = 3000; i < 4096; i = i + 1) begin
                ramMem[i] <= 4'd0;
            end
        end else if (ramWe) begin
            ramMem[addr] <= dataIn;
        end
    end

    // 読み出し（同期式でも非同期でもOK）
    always @(*) begin
        if (ramRe) dataOut = ramMem[addr];
        else       dataOut = 4'd0;
    end

endmodule
