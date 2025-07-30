module mux7seg (
    input  wire clk,
    input  wire [7:0] segA,
    input  wire [7:0] segB,
    input  wire [7:0] segC,
    input  wire [7:0] segD,
    output wire [7:0] seg,
    output wire [3:0] segDig
);

    wire clk10Khz;
    reg [2:0] segNo;

    // 10kHz クロック生成用分周
    clkDiv uClkDiv (
        .clk(clk),
        .rst(1'b0),
        .maxCount(24'd1200),
        .tc(clk10Khz)
    );
    
    // セグメントの切り替え（3ビットカウンタ使用）
    always @(posedge clk10Khz) begin
        segNo <= (segNo + 3'd1) % 8;
    end

    // セグメント選択（どの数字を表示するか）
    function [7:0] selectSeg;
        input [7:0] a, b, c, d;
        input [1:0] segNoBits;
        begin
            case (segNoBits)
                2'd0: selectSeg = a;
                2'd1: selectSeg = b;
                2'd2: selectSeg = c;
                2'd3: selectSeg = d;
            endcase
        end
    endfunction

    // 桁選択（どの桁を点灯させるか）
    function [3:0] selectDigit;
        input [1:0] segNoBits;
        begin
            case (segNoBits)
                2'd0: selectDigit = 4'b1110;
                2'd1: selectDigit = 4'b1101;
                2'd2: selectDigit = 4'b1011;
                2'd3: selectDigit = 4'b0111;
            endcase
        end
    endfunction       

    // 2:1ビットだけ使用（上位2ビットで4桁を切り替え）
    assign seg    = selectSeg(segA, segB, segC, segD, segNo[2:1]);
    assign segDig = selectDigit(segNo[2:1]);

endmodule  // mux7seg
