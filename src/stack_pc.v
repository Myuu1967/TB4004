module stack_pc_4bit (
    input  wire        clk,
    input  wire        reset,
    input  wire        push,       // PCをスタックに退避
    input  wire        pop,        // スタックから復帰
    input  wire        pc_inc,     // PCインクリメント
    input  wire        pc_load,    // PC書き込み
    input  wire [1:0]  pc_sel,     // 00=low, 01=mid, 10=high を選択
    input  wire [3:0]  data_in,    // 内部4ビットバス
    output reg  [3:0]  data_out    // 内部4ビットバス（読み出し用）
);

    // PCを3段に分けて保持
    reg [3:0] pc_low;
    reg [3:0] pc_mid;
    reg [3:0] pc_high;

    // スタックも3段に分けて保持
    reg [3:0] stack_low  [0:7];
    reg [3:0] stack_mid  [0:7];
    reg [3:0] stack_high [0:7];

    // スタックポインタ（0～7）
    reg [2:0] sp;

    integer i;

    // 読み出しはpc_selで選択
    always @(*) begin
        case (pc_sel)
            2'b00: data_out = pc_low;
            2'b01: data_out = pc_mid;
            2'b10: data_out = pc_high;
            default: data_out = 4'h0;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_low  <= 4'h0;
            pc_mid  <= 4'h0;
            pc_high <= 4'h0;
            sp <= 0;
            for (i = 0; i < 8; i = i + 1) begin
                stack_low[i]  <= 4'h0;
                stack_mid[i]  <= 4'h0;
                stack_high[i] <= 4'h0;
            end

        end else begin
            // PC書き込み（選択段のみ書き換え）
            if (pc_load) begin
                case (pc_sel)
                    2'b00: pc_low  <= data_in;
                    2'b01: pc_mid  <= data_in;
                    2'b10: pc_high <= data_in;
                endcase

            // PUSH：PCをスタックに退避
            end else if (push && sp < 7) begin
                stack_low[sp]  <= pc_low;
                stack_mid[sp]  <= pc_mid;
                stack_high[sp] <= pc_high;
                sp <= sp + 1;

            // POP：スタックからPCを復帰
            end else if (pop && sp > 0) begin
                sp <= sp - 1;
                pc_low  <= stack_low[sp-1];
                pc_mid  <= stack_mid[sp-1];
                pc_high <= stack_high[sp-1];

            // PCインクリメント（低位からキャリー）
            end else if (pc_inc) begin
                if (pc_low == 4'hF) begin
                    pc_low <= 4'h0;
                    if (pc_mid == 4'hF) begin
                        pc_mid <= 4'h0;
                        pc_high <= pc_high + 1;
                    end else begin
                        pc_mid <= pc_mid + 1;
                    end
                end else begin
                    pc_low <= pc_low + 1;
                end
            end
        end
    end

endmodule
