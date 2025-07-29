module cpu_top_with_7seg (
    input  wire clk,
    input  wire rst_n,
    input  wire test_in,

    // 7セグ出力
    output wire [7:0] seg,
    output wire [3:0] seg_dig
);

    // ===== CPU内部信号 =====
    wire [11:0] pc_addr;
    wire [3:0]  acc_debug;

    // CPUコア
    cpu_top u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .test_in(test_in),
        .pc_addr(pc_addr),
        .acc_debug(acc_debug)
    );

    // ===== 7セグ用信号 =====
    wire [7:0] seg_a, seg_b, seg_c, seg_d;

    // PCとACCを各drv7segに渡す
    drv7seg u_drv_a (
        .in(pc_addr[11:8]),
        .dp(1'b0),
        .seg(seg_a)
    );

    drv7seg u_drv_b (
        .in(pc_addr[7:4]),
        .dp(1'b0),
        .seg(seg_b)
    );

    drv7seg u_drv_c (
        .in(pc_addr[3:0]),
        .dp(1'b0),
        .seg(seg_c)
    );

    drv7seg u_drv_d (
        .in(acc_debug[3:0]),
        .dp(1'b0),
        .seg(seg_d)
    );

    // 4桁を切り替えて出力
    mux7seg u_mux (
        .clk(clk),
        .seg_a(seg_a),
        .seg_b(seg_b),
        .seg_c(seg_c),
        .seg_d(seg_d),
        .seg(seg),
        .seg_dig(seg_dig)
    );

endmodule
