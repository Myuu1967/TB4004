module mux7seg (
    input clk,
    input [7:0] seg_a,
    input [7:0] seg_b,
    input [7:0] seg_c,
    input [7:0] seg_d,
    output[7:0] seg,
    output[3:0] seg_dig
) ;

    wire clk10KHz ;

    reg [2:0] seg_no ;

    clkdiv(.clk(clk), .rst(1'b0), .max(24'd1200), .tc(clk10KHz)) ;

    always @(posedge(clk10KHz)) begin
        seg_no <= ((seg_no + 3'd1) % 8) ;
    end /* alwasy */

    function [7:0] sel_seg ;
        input [7:0] a, b, c, d ;
        input [1:0] seg_no ;

        case(seg_no) 
        2'd0: sel_seg = seg_a ; 
        2'd1: sel_seg = seg_b ; 
        2'd2: sel_seg = seg_c ; 
        2'd3: sel_seg = seg_d ; 
        endcase      
    endfunction

    function [3:0] sel_dig ;
        input [1:0] seg_no ;
         case(seg_no) 
        2'd0: sel_dig = 4'b1110 ;
        2'd1: sel_dig = 4'b1101 ; 
        2'd2: sel_dig = 4'b1011 ; 
        2'd3: sel_dig = 4'b0111 ; 
        endcase      
    endfunction       

    assign seg     = sel_seg(.a(seg_a), .b(seg_b), .c(seg_c), .d(seg_d), .seg_no(seg_no[2:1])) ;
    assign seg_dig = sel_dig(.seg_no(seg_no[2:1])) ;

endmodule /* mux7seg */