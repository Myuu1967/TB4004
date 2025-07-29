module debounce(
    input  clk,
    input  rst,
    input  in,
    output out
) ;

    reg [3:0] key_n ;
    wire      clk400Hz ;

    clkdiv clkdiv_1 (.clk(clk), .rst(rst), .max(24'd29999), .tc(clk400Hz)) ;

    always @(posedge(clk400Hz) or posedge(rst)) begin
        if (rst == 1'b1) begin
            key_n = 4'd0 ;
        end else begin
            key_n[3] <= key_n[2] ;
            key_n[2] <= key_n[1] ;
            key_n[1] <= key_n[0] ;
            key_n[0] <= in ;
        end
    end

    assign out = |key_n ; // key_n[0] | key_n[1] | key_n[2] | key_n[3]

endmodule /* debounce */
        