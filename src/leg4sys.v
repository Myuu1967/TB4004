module leg4sys (
    input        clk,
    input        nrst,
    input  [1:0] clk_sel,
    input        clk_btn,
    input  [3:0] in,
    output       bz,
    output [7:0] led,
    output [7:0] seg,
    output [3:0] seg_dig
) ;

parameter MAX1HZ  = 24'd5999999 ;
parameter MAX10HZ =  24'd599999 ;
parameter MAX1KHZ =    24'd5999 ;

    wire       rst ;
    wire       leg4_clk ;
    wire       manual_clk ;
    wire       tc10hz, tc1hz, tc1khz ;
    wire       clk12mhz, clk10hz, clk1hz ;
    wire [7:0] seg_a, seg_b, seg_c, seg_d ;
    wire [3:0] address ;
    wire [7:0] rom_out ;
    wire [3:0] out ;

    function clksel ;
        input [1:0] sw ;
        case (sw)
        2'd3: clksel = clk ;
        2'd2: clksel = clk10hz ;
        2'd1: clksel = clk1hz ;
        2'd0: clksel = manual_clk ;
        endcase
    endfunction

    assign rst = ~nrst ;
    assign clk12mhz = clk ;
    assign led[7]   = co ;
    assign led[6:4] = 3'b000 ;
    assign led[3:0] = out ;

    assign leg4_clk = clksel(clk_sel) ;
    assign bz       = clk1khz & out[3] ; /* buzzer when out[3] == 1 */
        
    debounce inst1  (.clk(clk), .rst(rst), .in(clk_btn),    .out(manual_clk)) ;
    clkdiv   inst2  (.clk(clk), .rst(rst), .max(MAX10HZ), .tc(tc10hz)) ;
    toggle   inst4  (.clk(clk), .rst(rst), .in(tc10hz),   .out(clk10hz)) ;
    clkdiv   inst5  (.clk(clk), .rst(rst), .max(MAX1HZ),  .tc(tc1hz)) ;
    toggle   inst6  (.clk(clk), .rst(rst), .in(tc1hz),    .out(clk1hz)) ;
    leg4     inst7  (.clk(leg4_clk), .rst(rst), .mem(rom_out), .in(in), .out(out), .co(co), .adr(address)) ;

    clkdiv   inst8  (.clk(clk), .rst(rst), .max(MAX1KHZ), .tc(tc1khz)) ;
    toggle   inst9  (.clk(clk), .rst(rst), .in(tc1khz),    .out(clk1khz)) ;

    leg4_rom inst10  (.address(address), .out(rom_out)) ;

    drv7seg  inst11  (.in(address),      .dp(1'b0), .seg(seg_a)) ;
    drv7seg  inst12 (.in(rom_out[7:4]), .dp(1'b0), .seg(seg_b)) ;
    drv7seg  inst13 (.in(rom_out[3:0]), .dp(1'b0), .seg(seg_c)) ;
    drv7seg  inst14 (.in(out),          .dp(co), .seg(seg_d)) ;
    
    mux7seg  inst15 (.clk(clk), .seg_a(seg_a), .seg_b(seg_b), .seg_c(seg_c), .seg_d(seg_d), .seg(seg), .seg_dig(seg_dig)) ;
endmodule 