module rom (
    input  wire [11:0] addr,    // 12bitアドレス
    input  wire [2:0]  cycle,   // A1〜X3 (0〜7)
    output reg  [3:0]  nibble   // 4bit出力（CPUに渡す）
);

    // 4K×8bit ROM
    reg [7:0] romMem [0:4095];

    // 初期化用カウンタ
    integer i;

    // 初期化（命令直書き）
    initial begin
        // 例: NOP(0x00)、ADD R5(0x85)、SUB R7(0x97) を並べる
        romMem[12'h000] = 8'h00; // NOP
        romMem[12'h001] = 8'h85; // ADD R5
        romMem[12'h002] = 8'h97; // SUB R7
        romMem[12'h003] = 8'h00; // NOP

        // 使わない領域をNOPで埋める
        for (i = 4; i < 2000; i = i + 1) begin
            romMem[i] = 8'h00;
        end

        for (i = 2000; i < 3000; i = i + 1) begin
            romMem[i] = 8'h00;
        end

        for (i = 3000; i < 4096; i = i + 1) begin
            romMem[i] = 8'h00;
        end
    end

    // 4bit出力制御
    always @(*) begin
        case (cycle)
            3'd3: nibble = romMem[addr][7:4]; // M1 → 上位4bit
            3'd4: nibble = romMem[addr][3:0]; // M2 → 下位4bit
            default: nibble = 4'hZ;           // それ以外のサイクルはバス解放（Z）
        endcase
    end

endmodule  // rom
