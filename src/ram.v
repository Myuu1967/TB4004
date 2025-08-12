module ram (
    input  wire        clk,
    input  wire        rstN,   // 既存のまま（未使用可）
    input  wire        ramWe,
    input  wire        ramRe,  // 既存のまま（未使用可）
    input  wire [11:0] addr,   // 既存のまま
    input  wire [3:0]  dataIn,
    output reg  [3:0]  dataOut
);
    (* ram_style="block" *)
    // ★4K→2Kへ
    reg [3:0] ramMem [0:2047];

    wire [10:0] subAddr = addr[10:0]; // ★上位1bitは無視（2KB固定）

    always @(posedge clk) begin
        if (ramWe) begin
            ramMem[subAddr] <= dataIn;
            dataOut         <= dataIn;       // write-first（安全）
        end else begin
            dataOut         <= ramMem[subAddr];
        end
    end
endmodule
