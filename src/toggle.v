module toggle (
    input      clk, rst, in,
    output reg out ) ;

    reg prev_in ;

    always @(posedge rst or posedge clk) begin
        if (rst == 1'b1) begin
            out      <= 1'b0 ;
            prev_in  <= 1'b0 ;
        end else begin
            prev_in <= in ;
            if ({prev_in, in} == 2'b10) /* falling edge */
                out <= ~out ;
            else
                out <= out ;
        end
    end /* always */
endmodule /* toggle */