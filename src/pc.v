// pc.v
// program counter for LEG4

module pc (
    input            clk,
    input            reset,
    input            jump,
    input      [3:0] immidi,
    output reg [3:0] adr
) ;

    always @(posedge reset or posedge clk) begin
        if (reset == 1'b1) begin
            adr <= 4'h0 ;
        end else begin
            if (jump == 1'b1) begin
                adr <= immidi ;
            end else begin
                adr <= adr + 4'd1 ;
            end // if (jump == 1'b1)
        end // if (reset == 1'b1)
    end // always
endmodule // pc
