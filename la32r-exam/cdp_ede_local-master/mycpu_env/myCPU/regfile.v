// 单周期双输出的寄存器组
// 说明：定义寄存器堆模块及其对外接口。
module regfile(
    // 说明：作为输入端口接收时钟信号。
    input  wire        clk,
    // READ PORT 1
    // 说明：作为输入端口接收第一个读寄存器编号。
    input  wire [ 4:0] raddr1,
    // 说明：作为输出端口送出第一个读寄存器值。
    output wire [31:0] rdata1,
    // READ PORT 2
    // 说明：作为输入端口接收第二个读寄存器编号。
    input  wire [ 4:0] raddr2,
    // 说明：作为输出端口送出第二个读寄存器值。
    output wire [31:0] rdata2,
    // WRITE PORT
    // 说明：作为输入端口接收寄存器堆写使能。
    input  wire        we,       //write enable, HIGH valid
    // 说明：作为输入端口接收写寄存器编号。
    input  wire [ 4:0] waddr,
    // 说明：作为输入端口接收写寄存器数据。
    input  wire [31:0] wdata
// 说明：结束模块端口列表或子模块端口连接。
);
// 说明：声明需要随时钟保存的32 个通用寄存器组成的数组。
reg [31:0] rf[31:0];

//WRITE
// 说明：在时钟上升沿按写使能更新寄存器堆。
always @(posedge clk) begin
    // 说明：写使能有效时，把数据写入指定的寄存器编号。
    if (we) rf[waddr] <= wdata;
// 说明：结束当前条件分支或时序代码块。
end

//READ OUT 1
// 说明：读取第一个端口；读零寄存器时固定返回零。
assign rdata1 = (raddr1==5'b0) ? 32'b0 : rf[raddr1];

//READ OUT 2
// 说明：读取第二个端口；读零寄存器时固定返回零。
assign rdata2 = (raddr2==5'b0) ? 32'b0 : rf[raddr2];

// 说明：结束寄存器堆模块定义。
endmodule
