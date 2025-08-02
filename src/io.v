module io (
    input  wire        clk,
    input  wire        rstN,

    // ROM I/O操作
    input  wire        romIoWe,      // WRR
    input  wire        romIoRe,      // RDR
    input  wire [3:0]  romIoAddr,    // ROMのI/Oポート番号

    // RAM I/O操作
    input  wire        ramIoWe,      // WR0〜3
    input  wire [3:0]  ramIoAddr,    // RAMのI/Oポート番号

    // CPUデータバス
    input  wire [3:0]  dataIn,
    output reg  [3:0]  romIoDataOut, // RDRでCPUに返すデータ

    // FPGAのGPIO
    input  wire [7:0]  ioIn,         // スイッチなど
    output reg  [7:0]  ioOut         // LEDなど
);

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            ioOut <= 8'd0;
        end else begin
            // ROM I/O書き込み (WRR)
            if (romIoWe) begin
                case (romIoAddr)
                    4'h0: ioOut[3:0] <= dataIn;
                    4'h1: ioOut[7:4] <= dataIn;
                    // 必要なら他のアドレスも追加
                    default: ;
                endcase
            end

            // RAM I/O書き込み (WR0〜WR3)
            if (ramIoWe) begin
                case (ramIoAddr)
                    4'h0: ioOut[3:0] <= dataIn;
                    4'h1: ioOut[7:4] <= dataIn;
                    default: ;
                endcase
            end
        end
    end

    // ROM I/O読み込み (RDR)
    always @(*) begin
        if (romIoRe) begin
            case (romIoAddr)
                4'h0: romIoDataOut = ioIn[3:0];
                4'h1: romIoDataOut = ioIn[7:4];
                default: romIoDataOut = 4'd0;
            endcase
        end else begin
            romIoDataOut = 4'd0;
        end
    end

endmodule
