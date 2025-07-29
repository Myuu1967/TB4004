module drv7seg (
	input [3:0]  in,
	input        dp,
	output [7:0] seg
) ;

    function [6:0] f ;
        input [3:0] sw ;
        begin
            case(sw)
            4'h0: f = 7'h3F ; // 011_1111
            4'h1: f = 7'h06 ; // 000_0110
            4'h2: f = 7'h5B ; // 101_1011
            4'h3: f = 7'h4F ; // 100_1111
            4'h4: f = 7'h66 ; // 110_0110
            4'h5: f = 7'h6D ; // 110_1101
            4'h6: f = 7'h7D ; // 111_1101
            4'h7: f = 7'h27 ; // 010_0111
            4'h8: f = 7'h7F ; // 111_1111
            4'h9: f = 7'h6F ; // 110_1011
            4'hA: f = 7'h77 ; // 111_0111
            4'hB: f = 7'h7C ; // 111_1100
            4'hC: f = 7'h58 ; // 101_1000
            4'hD: f = 7'h5E ; // 101_1110
            4'hE: f = 7'h79 ; // 111_1001
            4'hF: f = 7'h71 ; // 111_0001
            endcase
        end
    endfunction

    assign seg = { dp, f(in) } ;

endmodule /* drv7seg */