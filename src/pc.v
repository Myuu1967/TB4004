module pc (
    input  wire       clk,
    input  wire       rst_n,

    // cycle[2:0] = 0〜7 (A1〜X3)
    input  wire [2:0] cycle,

    // ジャンプ／サブルーチン用（あとで使う）
    input  wire       pc_load,       // PCを書き換える時にHigh
    input  wire [11:0] pc_new,       // 新しいPC値

    // 出力
    output reg  [3:0] pc_low,
    output reg  [3:0] pc_mid,
    output reg  [3:0] pc_high,
    output wire [11:0] pc_addr       // 12bitのフルアドレス
);

    assign pc_addr = {pc_high, pc_mid, pc_low};

    // PCインクリメント用
    reg [11:0] pc_full;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_full <= 12'd0;
        end else begin
            // PC書き換え（ジャンプ命令など）
            if (pc_load) begin
                pc_full <= pc_new;
            end else if (cycle == 3'd2) begin
                // A3サイクル（0:A1,1:A2,2:A3）で PC+1
                pc_full <= pc_full + 12'd1;
            end
        end
    end

    // 4bit分割出力
    always @(*) begin
        pc_low  = pc_full[3:0];
        pc_mid  = pc_full[7:4];
        pc_high = pc_full[11:8];
    end

endmodule
