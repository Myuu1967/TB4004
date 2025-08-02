module toggle (
    input      clk,
    input      rstN,   // 正論理リセットに変更
    input      in,
    output reg out
);

    reg prevIn;

    always @(negedge rstN or posedge clk) begin
        if (!rstN) begin
            out     <= 1'b0;
            prevIn  <= 1'b0;
        end else begin
            prevIn <= in;
            if ({prevIn, in} == 2'b10) // falling edge
                out <= ~out;
            else
                out <= out;
        end
    end

endmodule  // toggle
