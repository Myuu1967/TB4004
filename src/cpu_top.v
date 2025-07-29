module cpu_top (
    input  wire clk,
    input  wire rst,
    output reg [3:0] ADDlow,
    output reg [3:0] ADDmid,
    output reg [3:0] ADDhigh
);

    // ===== microcycle =====
    wire [2:0] cycle;
    wire fetch_phase;
    wire read_phase;
    wire exec_phase;

    cpu_microcycle u_cycle (
        .clk(clk),
        .rst(rst),
        .cycle(cycle),
        .fetch_phase(fetch_phase),
        .read_phase(read_phase),
        .exec_phase(exec_phase)
    );

    // ===== PC & スタック =====
    wire [3:0] pc_low;
    wire [3:0] pc_mid;
    wire [3:0] pc_high;

    stack_pc_4bit u_pc (
        .clk(clk),
        .reset(rst),
        .push(1'b0),
        .pop(1'b0),
        .pc_inc(1'b1),      // 今は毎クロックインクリメント（テスト用）
        .pc_load(1'b0),
        .pc_sel(2'b00),     // 今はdata_outは未使用
        .data_in(4'b0000),
        .data_out(),
        .pc_low(pc_low),
        .pc_mid(pc_mid),
        .pc_high(pc_high)
    );

    // ===== フェッチ動作（T0-T2だけ） =====
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ADDlow  <= 4'd0;
            ADDmid  <= 4'd0;
            ADDhigh <= 4'd0;
        end else begin
            case (cycle)
                3'd0: ADDlow  <= pc_low;
                3'd1: ADDmid  <= pc_mid;
                3'd2: ADDhigh <= pc_high;
                default: ; // T3以降は何も出さない（後でREAD/EXECを追加）
            endcase
        end
    end
endmodule
