// 说明：定义基础 RAM 接口模块及其对外接口。
module BaseRAM_control(
    // 说明：作为输入端口接收时钟信号。
    input  wire        clk,
    // 说明：作为输入端口接收高电平复位信号。
    input  wire        reset,
    // from cpu
    // 说明：作为输入端口接收数据内存访问使能。
    input  wire        data_sram_en,
    // 说明：作为输入端口接收数据内存访问地址。
    input  wire [31:0] data_sram_addr,
    // 说明：作为输入端口接收写入数据内存的数据。
    input  wire [31:0] data_sram_wdata,
    // 说明：作为输出端口送出从数据内存读到的数据。
    output reg  [31:0] data_sram_rdata,
    // 说明：作为输入端口接收数据内存的四位字节写使能。
    input  wire [ 3:0] data_sram_we,

    // to base ram
    // 说明：作为双向端口连接外部基础 RAM 双向数据线。
    inout  wire [31:0] base_ram_data,
    // 说明：作为输出端口送出外部基础 RAM 字地址。
    output wire [19:0] base_ram_addr,
    // 说明：作为输出端口送出低电平有效的 RAM 字节使能。
    output wire [ 3:0] base_ram_be_n,
    // 说明：作为输出端口送出低电平有效的 RAM 片选。
    output wire        base_ram_ce_n,
    // 说明：作为输出端口送出低电平有效的 RAM 输出使能。
    output wire        base_ram_oe_n,
    // 说明：作为输出端口送出低电平有效的 RAM 写使能。
    output wire        base_ram_we_n
// 说明：结束模块端口列表或子模块端口连接。
);

// 说明：RAM 字节使能为低电平有效：写入时按写掩码取反，否则全部关闭。
assign base_ram_be_n = (|data_sram_we && data_sram_en) ? ~data_sram_we : 4'hf
    // 说明：结束跨行的字节使能赋值。
    ;
// 说明：数据内存未启用时关闭外部 RAM 片选。
assign base_ram_ce_n = ~data_sram_en;
// 说明：有有效写请求时拉低外部 RAM 写使能。
assign base_ram_we_n = ~( | data_sram_we && data_sram_en);
// 说明：未启用或正在写时关闭 RAM 输出使能。
assign base_ram_oe_n = ~data_sram_en | (|data_sram_we);

// 说明：内存按字寻址，因此去掉字节地址最低两位。
assign base_ram_addr = data_sram_addr[21:2];

// 说明：写入时驱动双向数据线，其他时候释放为高阻态。
assign base_ram_data = ~base_ram_we_n ? data_sram_wdata : 32'hz;

// 说明：在时钟上升沿保存外部 RAM 读取的数据。
always @(posedge clk) begin
    // 说明：复位有效时清空本级状态，使旧指令不再有效。
    if (reset) begin
        // 说明：复位时清空返回给 CPU 的内存读值。
        data_sram_rdata <= 32'b0;
    // 说明：进入前一个条件不成立时的处理分支。
    end else if (data_sram_en && !(|data_sram_we)) begin
        // 说明：有效读请求时，把 RAM 数据线上的值送给 CPU。
        data_sram_rdata <= base_ram_data;
    // 说明：结束当前条件分支或时序代码块。
    end
// 说明：结束当前条件分支或时序代码块。
end

// 说明：结束基础 RAM 接口模块定义。
endmodule