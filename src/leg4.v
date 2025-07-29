// leg4.v
// LEG4 (Logically Elegant Gene 4bit)

module leg4 (
    input            clk,
    input            rst,
    input      [7:0] mem,
    input      [3:0] in,
    output reg [3:0] a, b, out,
    output reg       co,
    output     [3:0] adr
) ;

    reg  [3:0] in_r ;
    wire [3:0] data ;
    wire       wa, wb, wo, jmp ;
    wire       alu_co ;

    always @(posedge rst or posedge clk) begin
        if (rst == 1'b1) begin
            a    <= 4'd0 ;
            b    <= 4'd0 ;
            out  <= 4'd0 ;
            co   <= 4'd0 ;
            in_r <= 4'd0 ;
        end else begin
            if (wa == 1'b1) a   <= data ; else a   <= a ; 
            if (wb == 1'b1) b   <= data ; else b   <= b ;
            if (wo == 1'b1) out <= data ; else out <= out ;
            co <= alu_co ;
            in_r <= in ;
        end // if (rst == 1'b1)
    end // always

    pc  inst1 (.clk(clk), .reset(rst), .jump(jmp), .immid(mem[3:0]), .adr(adr)) ;

    alu inst2 (
        .reset(rst),
        .command(mem[7:4]),
        .carry_in(co),
        .immediate(mem[3:0]),
        .a(a),
        .b(b),
        .in(in_r),
        .write_a(wa),
        .write_b(wb),
        .write_out(wo),
        .jump(jmp),
        .carry_out(alu_co),
        .data(data)) ;

endmodule // leg4