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
    input  wire [3:0] alu_op,       // decoder からの ALU操作コード
    input  wire [3:0] acc_in,       // ACCの値
    input  wire [3:0] temp_in,      // Tempの値
    input  wire [3:0] opa,          // オペランド（ROM下位4bit、またはレジスタ値）
    input  wire       carry_in,     // CCのCarryフラグ（ADD, SUB用）

    output reg  [3:0] alu_result,   // 演算結果（ACCやTempへ）
    output reg        carry_out,    // キャリーフラグ
    output reg        zero_out      // ゼロ判定
);

    // ALU操作コード定義（簡易版）
    localparam NOP = 4'h0;
    localparam ADD = 4'h8;
    localparam SUB = 4'h9;
    localparam LDM = 4'hD;

    always @(*) begin
        // デフォルト値
        alu_result = 4'h0;
        carry_out  = 1'b0;
        zero_out   = 1'b0;

        case (alu_op)
            NOP: begin
                alu_result = acc_in;   // 何もせずACCを通す
                carry_out  = 1'b0;
            end

            ADD: begin
                {carry_out, alu_result} = acc_in + opa + carry_in;
            end

            SUB: begin
                // SUB: ACC - OPA - carry
                // キャリーはボローとして扱う
                {carry_out, alu_result} = {1'b0, acc_in} - opa - carry_in;
            end

            LDM: begin
                // LDM: ACCに即値をロード
                alu_result = opa;
                carry_out  = carry_in; // キャリーは変化させない
            end

            default: begin
                alu_result = 4'h0;
            end
        endcase

        // Zeroフラグ設定
        if (alu_result == 4'h0)
            zero_out = 1'b1;
        else
            zero_out = 1'b0;
    end

endmodule
