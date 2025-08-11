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

    reg [11:0] stackMem [0:7];
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
            if (push && !pop) begin
                if (sp >= 3'd7) begin
                    overflow <= 1'b1;              // 8段超過
                end else begin
                    stackMem[sp + 3'd1] <= pcIn;   // 次段に書き込んで
                    sp <= sp + 3'd1;               // SPを進める
                end
            end

            // POP（pushは同時でない前提）
            if (pop && !push) begin
                if (sp == 3'd0) begin
                    underflow <= 1'b1;             // 空のPOP
                    // pcOutはassignのまま（stackMem[0]）を見せる
                end else begin
                    // ★ このサイクルのpcOutは「pop前」のstackMem[sp]
                    //    次サイクルから使う値も同じになるようspを1減らす
                    sp <= sp - 3'd1;
                    stackPcLoad <= 1'b1;           // ★ X3で帰還パルス
                end
            end
        end
    end
endmodule
