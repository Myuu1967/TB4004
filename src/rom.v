module rom (
    input  wire        clk,
    input  wire [11:0] addr,   // 既存のまま
    input  wire [2:0]  cycle,
    output reg  [3:0]  nibble
);
    (* rom_style="block", ram_style="block" *)
    // ★4K→2Kへ
    reg [7:0] romMem [0:2047];
    reg [7:0] byteReg;

    initial $readmemh("prog_byte.hex", romMem);

    wire [10:0] subAddr = addr[10:0]; // ★上位1bitは無視（2KB固定）

    always @(posedge clk) begin
        byteReg <= romMem[subAddr];   // ★2KB化
    end

    always @* begin
        case (cycle)
            3'd3: nibble = byteReg[7:4];
            3'd4: nibble = byteReg[3:0];
            default: nibble = 4'h0;
        endcase
    end
endmodule
