module toggle (
    input      clk,
    input      rst,   // 正論理リセットに変更
    input      in,
    output reg out
);

    reg prevIn;

    always @(posedge rst or posedge clk) begin
        if (rst) begin
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
