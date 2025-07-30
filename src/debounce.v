module debounce (
    input  wire clk,
    input  wire rst,
    input  wire in,
    output wire out
);

    reg [3:0] keyN;
    wire clk400Hz;

    // clkDivをキャメル記法で呼び出し
    clkDiv clkDivInst (
        .clk(clk),
        .rst(rst),
        .maxCount(24'd29999),
        .tc(clk400Hz)
    );

    always @(posedge clk400Hz or posedge rst) begin
        if (rst == 1'b1) begin
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
