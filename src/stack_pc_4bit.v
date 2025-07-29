module cpu_top (
    input  wire clk,         // toggle.v からのクロック
    input  wire rst_n,       // リセット
    input  wire test_in,     // TESTピン（CC用）

    // デバッグ用（外部へ出す）
    output wire [11:0] pc_addr,
    output wire [3:0]  acc_debug
);

    // ======== 内部配線 ========

    // cycle(0〜7) と sync
    wire [2:0] cycle;
    wire sync;

    // PC関連
    wire [3:0] pc_low, pc_mid, pc_high;

    // ROM関連
    wire [3:0] rom_data;   // 4bit (M1=OPR, M2=OPA)

    // decoder関連
    wire alu_enable;
    wire [3:0] alu_op;
    wire acc_we;
    wire temp_we;

    // ACC & Temp
    wire [3:0] acc_out;
    wire [3:0] temp_out;

    // ALU
    wire [3:0] alu_result;
    wire       carry_out;
    wire       zero_out;

    // CC（decoder内）
    wire carry_flag, zero_flag, cpl_flag, test_flag;

    // Register File
    wire [3:0] reg_dout;

    // ======== モジュール接続 ========

    // 8サイクル生成
    clock_reset u_clock_reset (
        .toggle_clk(clk),
        .rst_n(rst_n),
        .cycle(cycle),
        .sync(sync)
    );

    // PC
    pc u_pc (
        .clk(clk),
        .rst_n(rst_n),
        .cycle(cycle),
        .pc_load(1'b0),        // とりあえず固定（ジャンプ命令は後で）
        .pc_new(12'h000),
        .pc_low(pc_low),
        .pc_mid(pc_mid),
        .pc_high(pc_high),
        .pc_addr(pc_addr)
    );

    // ROM
    rom u_rom (
        .addr(pc_addr),
        .cycle(cycle),
        .nibble(rom_data)
    );

    // decoder（CC統合）
    decoder_with_cc u_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .opr(rom_data),   // 今は簡単のため nibble をそのまま渡す
        .opa(4'h0),       // 後で M2 を正しく opa に
        .cycle(cycle),
        .carry_from_alu(carry_out),
        .zero_from_alu(zero_out),
        .test_in(test_in),

        .alu_enable(alu_enable),
        .alu_op(alu_op),
        .acc_we(acc_we),
        .temp_we(temp_we),

        .carry_flag(carry_flag),
        .zero_flag(zero_flag),
        .cpl_flag(cpl_flag),
        .test_flag(test_flag)
    );

    // ACC & Temp
    acc_temp_regs u_acc_temp (
        .clk(clk),
        .rst_n(rst_n),
        .alu_result(alu_result),
        .acc_we(acc_we),
        .temp_we(temp_we),
        .acc_out(acc_out),
        .temp_out(temp_out)
    );

    // ALU
    alu u_alu (
        .alu_op(alu_op),
        .acc_in(acc_out),
        .temp_in(temp_out),
        .opa(4'h0),          // 後でオペランドを繋ぐ
        .carry_in(carry_flag),
        .alu_result(alu_result),
        .carry_out(carry_out),
        .zero_out(zero_out)
    );

    // Register File（仮・未接続）
    register_file u_registers (
        .clk(clk),
        .rst_n(rst_n),
        .reg_we(1'b0),
        .reg_addr(4'h0),
        .reg_din(4'h0),
        .reg_dout(reg_dout)
    );

    // デバッグ出力
    assign acc_debug = acc_out;

endmodule
