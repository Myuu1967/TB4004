module stack (
    input  wire        clk,
    input  wire        rstN,
    input  wire        push,
    input  wire        pop,

    input  wire [11:0] pcIn,     // = 戻り先（JMS時の次アドレス）

    output wire [11:0] pcOut,    // ★ 常にstackトップを即時参照（コンビ）

    output reg  [2:0]  sp,
    output reg         overflow,
    output reg         underflow,

    // ★ POPが成立したサイクルで1クロック立つ（cpuTopでpcLoadとOR）
    output reg         stackPcLoad
);

    (* ram_style="distributed" *) reg [11:0] stackMem [0:7];
    integer i;

    // ★ pcOutはコンビ：今のspをそのまま見せる
    assign pcOut = stackMem[sp];

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            sp           <= 3'd0;
            overflow     <= 1'b0;
            underflow    <= 1'b0;
            stackPcLoad  <= 1'b0;
            for (i=0; i<8; i=i+1) stackMem[i] <= 12'd0;

        end else begin
            stackPcLoad <= 1'b0; // 既定はLow（1クロックパルス）

            // PUSH優先（POP同時のときはここだけ通す）
            if (push) begin
                if (sp >= 3'd7) overflow <= 1'b1;
                else begin
                    stackMem[sp + 3'd1] <= pcIn;
                    sp <= sp + 3'd1;
                end
            end else if (pop) begin
                if (sp == 3'd0) underflow <= 1'b1;
                else begin
                    sp <= sp - 3'd1;
                    stackPcLoad <= 1'b1; // このクロックでpcOut(=旧sp)を使って復帰
                end
            end
        end
    end
endmodule
