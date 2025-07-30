module drv7seg (
    input  wire [3:0] in,
    input  wire       dp,
    output wire [7:0] seg
);

    // 数字 → セグメントパターン変換
    function [6:0] segPattern;
        input [3:0] value;
        begin
            case (value)
                4'h0: segPattern = 7'h3F; // 011_1111
                4'h1: segPattern = 7'h06; // 000_0110
                4'h2: segPattern = 7'h5B; // 101_1011
                4'h3: segPattern = 7'h4F; // 100_1111
                4'h4: segPattern = 7'h66; // 110_0110
                4'h5: segPattern = 7'h6D; // 110_1101
                4'h6: segPattern = 7'h7D; // 111_1101
                4'h7: segPattern = 7'h27; // 010_0111
                4'h8: segPattern = 7'h7F; // 111_1111
                4'h9: segPattern = 7'h6F; // 110_1011
                4'hA: segPattern = 7'h77; // 111_0111
                4'hB: segPattern = 7'h7C; // 111_1100
                4'hC: segPattern = 7'h58; // 101_1000
                4'hD: segPattern = 7'h5E; // 101_1110
                4'hE: segPattern = 7'h79; // 111_1001
                4'hF: segPattern = 7'h71; // 111_0001
            endcase
        end
    endfunction

    // dp（小数点）は最上位ビット
    assign seg = { dp, segPattern(in) };

endmodule  // drv7seg
