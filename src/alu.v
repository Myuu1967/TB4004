// alu.v
// ALU for LEG4

`define NOP     4'b0000
`define JCN     4'b0001         //  2Byte Command

`define B0010   4'b0010
`define FIM     1'b0            //  2Byte Command   
`define SRC     1'b1            

`define B0011   4'b0011
`define FIN     1'b0            
`define JIN     1'b1            

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
`define RAL     4'b0101
`define RAR     4'b0110
`define TCC     4'b0111
`define DAC     4'b1000
`define TCS     4'b1001
`define STC     4'b1010
`define DAA     4'b1011
`define KBP     4'b1100
`define DCL     4'b1101

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
    input  wire [3:0] aluOp,       // decoder からの ALU操作コード
    input  wire [3:0] accIn,       // ACCの値
    input  wire [3:0] tempIn,      // Tempの値
    input  wire [3:0] opa,         // オペランド（ROM下位4bit、またはレジスタ値）
    input  wire       carryIn,     // CCのCarryフラグ（ADD, SUB用）

    output reg  [3:0] aluResult,   // 演算結果（ACCやTempへ）
    output reg        carryOut,    // キャリーフラグ
    output reg        zeroOut      // ゼロ判定
);

    // ALU操作コード定義（簡易版）
    localparam NOP = 4'h0;
    localparam ADD = 4'h8;
    localparam SUB = 4'h9;
    localparam LDM = 4'hD;

    always @(*) begin
        // デフォルト値
        aluResult = 4'h0;
        carryOut  = 1'b0;
        zeroOut   = 1'b0;

        case (aluOp)
            NOP: begin
                aluResult = accIn;   // 何もせずACCを通す
                carryOut  = 1'b0;
            end

            ADD: begin
                {carryOut, aluResult} = accIn + opa + carryIn;
            end

            SUB: begin
                // SUB: ACC - OPA - carry
                // キャリーはボローとして扱う
                {carryOut, aluResult} = {1'b0, accIn} - opa - carryIn;
            end

            LDM: begin
                // LDM: ACCに即値をロード
                aluResult = opa;
                carryOut  = carryIn; // キャリーは変化させない
            end

            default: begin
                aluResult = 4'h0;
            end
        endcase

        // Zeroフラグ設定
        if (aluResult == 4'h0)
            zeroOut = 1'b1;
        else
            zeroOut = 1'b0;
    end

endmodule
