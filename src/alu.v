// alu.v
// ALU for LEG4
`define NOP     4'b0000
`define JCN     4'b0001         //  2Byte Command


`define B0010   4'b0010
`define FIM     1'b0            //  2Byte Command   //
`define SRC     1'b1            //

`define B0011   4'b0011
`define FIN     1'b0            //
`define JIN     1'b1            //

`define JUN     4'b0100         //  2Byte Command
`define JMS     4'b0101         //  2Byte Command
`define INC     4'b0110
`define ISZ     4'b0111         //  2Byte Command 
`define ADD     4'b1000
`define SUB     4'b1001
`define LD      4'b1010
`define XCH     4'b1011
`define BBL     4'b1100
`define LDM     4'b1101

`define F*      4'b1111

`define CLB     4'b0000
`define CLC     4'b0001
`define IAC     4'b0010
`define CMC     4'b0011
//`define UNDEFINE1 4'b0100
`define RAL     4'b0101
`define RAR     4'b0110
`define TCC     4'b0111
`define DAC     4'b1000
`define TCS     4'b1001
`define STC     4'b1010
`define DAA     4'b1011
`define KBP     4'b1100
`define DCL     4'b1101
//`define UNDEFINE2     4'b110
//`define UNDEFINE3     4'b1111


`define E*      4'b1110

`define WRM     4'b0000
`define WMP     4'b0001
`define WRR     4'b0010
`define WPM     4'b0011
`define WR0     4'b0100
`define WR1     4'b0101
`define WR2     4'b0110
`define WR3     4'b0111
`define SBM     4'b1000
`define RDM     4'b1001
`define RDR     4'b1010
`define ADM     4'b1011
`define RD0     4'b1100
`define RD1     4'b1101
`define RD2     4'b1110
`define RD3     4'b1111

module alu (
    input            reset,     // Async reset
    input      [3:0] command,   // Mnemonic
    input            carry_in,  // Carry in from the previous command
    input      [3:0] immediate, // Immediate input (4bit LSB of memory out)
    input      [3:0] a,         // Value of register A
    input      [3:0] b,         // Value of register B
    input      [3:0] in,        // External input
    output reg       write_a,   // Write to Register A
    output reg       write_b,   // Write to Register B
    output reg       write_out, // Write to External Output
    output reg       jump,      // Jump (Write to PC)
    output reg       carry_out, // Carry Out
    output reg [3:0] data       // Result of calcuration
) ;

    always @(reset or command or carry_in or immediate or a or b or in) begin
        if (reset == 1'b1) begin
            write_a   <= 1'b0 ;
            write_b   <= 1'b0 ;
            write_out <= 1'b0 ;
            jump      <= 1'b0 ;
            carry_out <= 1'b0 ;
            data      <= 4'd0 ;
        end else begin
            case (command)
            `NOP   : begin                  ; end
            `JCN   : begin  ; end
            `INA   : begin  ; end
            `B0010 : begin case(immediate[0])
                        `FIM  : begin ; end
                        `SRC  : begin ; end
                     endcase
            `B0011 : begin case(immediate[0])
                        `FIN  : begin ; end
                        `JIN  : begin ; end
                     endcase
            `JUN   : begin data              <= a             ; carry_out <= 1'b0 ; end
            `JMS   : begin data              <= in            ; carry_out <= 1'b0 ; end
            `INC   : begin data              <= immediate     ; carry_out <= 1'b0 ; end
            `ISZ   : begin data              <= b             ; carry_out <= 1'b0 ; end
            `ADD   : begin data              <= immediate     ; carry_out <= 1'b0 ; end
            `SUB   : begin data              <= immediate     ; carry_out <= 1'b0 ; end
            `LD    : begin data              <= immediate     ; carry_out <= 1'b0 ; end
            `XCH   : begin data              <= immediate     ; carry_out <= 1'b0 ; end
            `BBL   : begin data              <= immediate     ; carry_out <= 1'b0 ; end
            `LDM   : begin data              <= immediate     ; carry_out <= 1'b0 ; end
            `F*    : begin case(immediate)
                        `CLB  : begin ; end
                        `CLC  : begin ; end
                        `IAC  : begin ; end
                        `CMC  : begin ; end
                        `RAL  : begin ; end
                        `RAR  : begin ; end
                        `TCC  : begin ; end
                        `DAC  : begin ; end
                        `TCS  : begin ; end
                        `STC  : begin ; end
                        `DAA  : begin ; end
                        `KBP  : begin ; end
                        `DCL  : begin ; end
                     endcase
            `E*    :  begin case(immediate)
                        `WRM  : begin ; end
                        `WMP  : begin ; end
                        `WRR  : begin ; end
                        `WPM  : begin ; end
                        `WR0  : begin ; end
                        `WR1  : begin ; end
                        `WR2  : begin ; end
                        `WR3  : begin ; end
                        `SBM  : begin ; end
                        `RDM  : begin ; end
                        `RDR  : begin ; end
                        `ADM  : begin ; end
                        `RD0  : begin ; end
                        `RD1  : begin ; end
                        `RD2  : begin ; end
                        `RD3  : begin ; end
                     endcase
                default : begin ; end
            endcase
            write_a   <= (command == `ADAI) | (command == `MVAB) | (command == `INA) | (command == `MVAI) ;
            write_b   <= (command == `ADBI) | (command == `MVBA) | (command == `INB) | (command == `MVBI) ;
            write_out <= (command == `OUTB) | (command == `OUTI) ;
            jump      <= (command == `JMPI) | ((carry_in == 1'b0) && (command == `JNCI)) ;
        end // if (reset == 1'b1)
    end // always
endmodule // alu