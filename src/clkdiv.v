module clkdiv(
    input        clk,
    input        rst,
    input [23:0] max,
    output       tc
) ;

    reg [23:0] count ;

    always @(posedge clk or posedge rst) begin 
        if (rst == 1'b1) begin
            count <= 24'd0 ;
        end else begin
            if (tc == 1'b1) 
                count <= 24'd0 ;
            else
                count <= count + 24'd1 ;
        end 
    end /* always */

    assign tc = (count >= max) ? 1'b1 : 1'b0 ;

endmodule /* cldkiv */
