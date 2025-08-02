module clkDiv (
    input        clk,
    input        rstN,
    input  [23:0] maxCount,
    output       tc
);

    reg [23:0] count;

    always @(posedge clk or negedge rstN) begin 
        if (!rstN) begin
            count <= 24'd0;
        end else begin
            if (tc == 1'b1) 
                count <= 24'd0;
            else
                count <= count + 24'd1;
        end 
    end

    assign tc = (count >= maxCount) ? 1'b1 : 1'b0;

endmodule /* clkDiv */
