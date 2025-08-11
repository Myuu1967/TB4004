module ram (
    input  wire        clk,
    input  wire        rstN,   // 使うなら制御レジスタ用程度に
    input  wire        ramWe,
    input  wire        ramRe,  // 使わなくてもOK（必要ならゲートに）
    input  wire [11:0] addr,
    input  wire [3:0]  dataIn,
    output reg  [3:0]  dataOut
);
    (* ram_style="block" *)
    reg [3:0] ramMem [0:4095];

    // 同期Write & 同期Read
    always @(posedge clk) begin
        if (ramWe) ramMem[addr] <= dataIn;
        dataOut <= ramMem[addr];     // ★同期Read（常時でも良い）
    end
endmodule
