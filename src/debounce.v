module debounce (
    input  wire clk,
    input  wire rstN,
    input  wire in,
    output wire out
);

    reg [3:0] keyN;
    wire clk400Hz;

    // clkDivを呼び出し
    clkDiv clkDivInst (
        .clk(clk),
        .rstN(rstN),
        .maxCount(24'd29999),
        .tc(clk400Hz)
    );

    always @(posedge clk400Hz or negedge rstN) begin
        if (!rstN) begin
            keyN <= 4'd0;
        end else begin
            keyN[3] <= keyN[2];
            keyN[2] <= keyN[1];
            keyN[1] <= keyN[0];
            keyN[0] <= in;
        end
    end

    // 4サンプル中1つでも1なら押下とみなす
    assign out = |keyN;

endmodule  // debounce
