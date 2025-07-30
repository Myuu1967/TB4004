module register_file (
    input  wire        clk,
    input  wire        rst_n,

    // 書き込み制御
    input  wire        reg_we,       // 書き込みイネーブル
    input  wire [3:0]  reg_addr,     // 書き込み/読み出しアドレス (0〜15)
    input  wire [3:0]  reg_din,      // 書き込みデータ

    // 読み出し
    output wire [3:0]  reg_dout      // 読み出しデータ
);

    // 16本の4bitレジスタ
    reg [3:0] regs [0:15];
    integer i;

    // リセット時は全部0に
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 16; i = i + 1) begin
                regs[i] <= 4'd0;
            end
        end else begin
            if (reg_we) begin
                regs[reg_addr] <= reg_din;
            end
        end
    end

    // 常時読み出し（コンビネーション）
    assign reg_dout = regs[reg_addr];

endmodule
