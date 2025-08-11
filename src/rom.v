// rom.v（4K x 8bit を同期読み出し → nibble選択）
module rom (
    input  wire        clk,
    input  wire [11:0] addr,    // 12bitアドレス
    input  wire [2:0]  cycle,   // A1〜X3 (0〜7)
    output reg  [3:0]  nibble   // 4bit出力
);
    (* rom_style="block", ram_style="block" *)
    reg [7:0] romMem [0:4095];
    reg [7:0] byteReg;  // 同期読出しレジスタ

    // ★合成用：巨大for初期化はやめる。必要ならreadmemhに寄せる。
    initial $readmemh("prog_byte.hex", romMem); // 8bit/行のほうが扱いやすい

    // ★同期Read（これがBRAM推論の鍵）
    always @(posedge clk) begin
        byteReg <= romMem[addr];
    end

    // nibble選択はメモリ外で（コンビ）
    always @* begin
        case (cycle)
            3'd3: nibble = byteReg[7:4]; // M1
            3'd4: nibble = byteReg[3:0]; // M2
            default: nibble = 4'h0;
        endcase
    end
endmodule
