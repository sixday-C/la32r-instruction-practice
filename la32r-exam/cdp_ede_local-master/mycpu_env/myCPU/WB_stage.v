// 说明：引入各级总线宽度和访存宽度的公共定义。
`include "mycpu_defines.vh"

// 说明：定义写回阶段模块及其对外接口。
module WB_stage(
    // 说明：作为输入端口接收时钟信号。
    input  wire        clk,
    // 说明：作为输入端口接收高电平复位信号。
    input  wire        reset,
    //allowin
    // 说明：作为输出端口送出写回级可接收新结果的标志。
    output wire        ws_allowin,  //该阶段是否可以接收数据(最后一级, 恒为1)
    //from ms stage
    // 说明：作为输入端口接收访存传给写回级的有效位。
    input  wire        ms_to_ws_valid,
    // 说明：作为输入端口接收访存传给写回级的控制和数据总线。
    input  wire [`MS_TO_WS_BUS_WD -1 :0] ms_to_ws_bus,  //上一级缓冲区
    //to rf :write back
    // 说明：作为输出端口送出写回到寄存器堆的数据总线。
    output wire [`WS_TO_RF_BUS_WD -1 :0] ws_to_rf_bus,  //写回缓冲区
    // trace debug interface
    // 说明：作为输出端口送出写回级用于调试的 PC。
    output wire [31:0] debug_wb_pc,
    // 说明：作为输出端口送出写回级用于调试的写使能。
    output wire [ 3:0] debug_wb_rf_we,
    // 说明：作为输出端口送出写回级用于调试的目标寄存器编号。
    output wire [ 4:0] debug_wb_rf_wnum,
    // 说明：作为输出端口送出写回级用于调试的写入数据。
    output wire [31:0] debug_wb_rf_wdata,
    // 说明：作为输入端口接收从数据内存读到的数据。
    input  wire [31:0] data_sram_rdata  //访存数据
// 说明：结束模块端口列表或子模块端口连接。
);
    // 说明：声明需要随时钟保存的写回级有效位。
    reg ws_valid;
    // 说明：声明需要随时钟保存的写回级保存的访存结果总线。
    reg [`MS_TO_WS_BUS_WD -1 :0] ms_to_ws_bus_r;
    // 说明：声明写回级已准备好的标志，供本模块连接或计算。
    wire ws_ready_go;
    /*assign es_to_mem_bus = {gr_we,  //写寄存器使能
                            dest,  //写寄存器地址
                            
                            load_op,  //load指令
                            res_from_mem,  //结果是否来自内存

                            mem_we,  //写内存使能
                            rkd_value,  //写内存数据
                            alu_result,  //alu计算结果
                            ds_pc  //当前指令的pc,用于debug
                            };*/
    // 说明：写回级没有下游计算等待，始终准备好。
    assign ws_ready_go     = 1'b1;
    //最后一级, 没有下游 allowin
    // 说明：写回级为空或本拍可完成时，允许访存结果进入。
    assign ws_allowin      = !ws_valid || ws_ready_go;

    // 说明：声明内存读数中的第 0 个字节、内存读数中的第 1 个字节、内存读数中的第 2 个字节、内存读数中的第 3 个字节，供本模块连接或计算。
    wire [7:0] sram_rdata_byte0, sram_rdata_byte1, sram_rdata_byte2, sram_rdata_byte3;  //字节选
    // 说明：声明内存读数中的第 0 个半字、内存读数中的第 1 个半字，供本模块连接或计算。
    wire [15:0] sram_rdata_half0, sram_rdata_half1;  //半字选
    // 说明：声明按地址选中的一个字节，供本模块连接或计算。
    wire [7:0] sram_rdata_byte;
    // 说明：声明按地址选中的一个半字，供本模块连接或计算。
    wire [15:0] sram_rdata_half;
    // 说明：声明本次访存的数据宽度编码、访存地址在字内的偏移，供本模块连接或计算。
    wire [1:0] mem_size , mem_addr_offset;  //内存访问的大小和地址偏移量
    // 说明：从访存总线取出访问宽度编码。
    assign mem_size = ms_to_ws_bus_r[73:72];
    // 说明：从访存总线取出字内地址偏移。
    assign mem_addr_offset = ms_to_ws_bus_r[76:75];

    // 说明：声明加载结果需要符号扩展的标志，供本模块连接或计算。
    wire load_signed;   //是否要符号扩展
    // 说明：从访存总线读出是否需要符号扩展。
    assign load_signed = ms_to_ws_bus_r[74];

    // 说明：把内存返回值的最低 8 位单独取出。
    assign sram_rdata_byte0 = data_sram_rdata[7:0];
    // 说明：取出内存返回值的第二个字节。
    assign sram_rdata_byte1 = data_sram_rdata[15:8];
    // 说明：取出内存返回值的第三个字节。
    assign sram_rdata_byte2 = data_sram_rdata[23:16];
    // 说明：取出内存返回值的最高字节。
    assign sram_rdata_byte3 = data_sram_rdata[31:24];
    // 说明：取出内存返回值的低 16 位半字。
    assign sram_rdata_half0 = data_sram_rdata[15:0];
    // 说明：取出内存返回值的高 16 位半字。
    assign sram_rdata_half1 = data_sram_rdata[31:16];

    // 说明：字内偏移为 0 时读取最低字节。
    assign sram_rdata_byte = mem_addr_offset == 2'b00 ? sram_rdata_byte0 :
                             // 说明：字内偏移为 1 时读取第二字节。
                             mem_addr_offset == 2'b01 ? sram_rdata_byte1 :
                             // 说明：字内偏移为 2 时读取第三字节。
                             mem_addr_offset == 2'b10 ? sram_rdata_byte2 :
                             // 说明：其余偏移读取最高字节。
                             sram_rdata_byte3;
    // 说明：地址第 1 位为零时读取低半字。
    assign sram_rdata_half = mem_addr_offset[1] == 1'b0 ? sram_rdata_half0 :
                             // 说明：地址第 1 位为一时读取高半字。
                             sram_rdata_half1;

    // 说明：声明经宽度和符号处理的加载数据，供本模块连接或计算。
    wire [31:0] sram_rdata;
    // 说明：读字节时根据符号位决定做符号扩展还是补零。
    assign sram_rdata = (mem_size == `B) ? (load_signed ? {{24{sram_rdata_byte[7]}}, sram_rdata_byte} : {24'b0, sram_rdata_byte}) :
                        // 说明：读半字时同样根据符号位决定符号扩展或补零。
                        (mem_size == `H) ? (load_signed ? {{16{sram_rdata_half[15]}}, sram_rdata_half} : {16'b0, sram_rdata_half}) :
                        // 说明：读整字时直接保留内存返回的 32 位数据。
                        data_sram_rdata;

    // 说明：把有效的加载标志放在写回总线最高位。
    assign ws_to_rf_bus = {ws_valid && ms_to_ws_bus_r[71],  //[38]    load标志
                           // 说明：只有本级有效且需要写寄存器时才开启写回。
                           ws_valid && ms_to_ws_bus_r[70],  //[37]    写寄存器使能
                           // 说明：从访存总线取出写回目标寄存器编号。
                           ms_to_ws_bus_r[69:65],           //[36:32] 写寄存器地址
                           // 说明：加载指令写回内存结果，其他指令写回 ALU 结果。
                           ms_to_ws_bus_r[64] ? sram_rdata : ms_to_ws_bus_r[63:32]//[31: 0] 写回数据
                          // 说明：完成写回到寄存器堆的数据总线拼接。
                          };

    // debug info generate
    // 说明：仅在写回级有效时输出写回级用于调试的 PC，供测试与跟踪。
    assign debug_wb_pc       = ws_valid ? ms_to_ws_bus_r[31:0] : 32'b0;
    // 说明：仅在写回级有效时输出写回级用于调试的写使能，供测试与跟踪。
    assign debug_wb_rf_we    = {4{ws_valid && ms_to_ws_bus_r[70]}};
    // 说明：仅在写回级有效时输出写回级用于调试的目标寄存器编号，供测试与跟踪。
    assign debug_wb_rf_wnum  = ws_valid ? ms_to_ws_bus_r[69:65] : 5'b0;
    // 说明：仅在写回级有效时输出写回级用于调试的写入数据，供测试与跟踪。
    assign debug_wb_rf_wdata = ws_valid ? ws_to_rf_bus[31:0] : 32'b0;
    // 说明：在时钟上升沿更新本级保存的有效位和数据。
    always @(posedge clk) begin
        // 说明：复位有效时清空本级状态，使旧指令不再有效。
        if (reset) begin
            // 说明：更新写回级有效位，控制该级数据是否被下游采纳。
            ws_valid <= 1'b0;
            // 说明：把上一级总线内容暂存为写回级保存的访存结果总线。
            ms_to_ws_bus_r <= 0;
        // 说明：结束当前条件分支或时序代码块。
        end
        // 说明：只有括号里的条件成立，才执行这一分支的状态更新。
        else if (ws_allowin) begin
            // 说明：更新写回级有效位，控制该级数据是否被下游采纳。
            ws_valid <= ms_to_ws_valid;
        // 说明：结束当前条件分支或时序代码块。
        end

        // 说明：检查括号里的握手或控制条件，决定是否更新寄存器。
        if (ms_to_ws_valid && ws_allowin) begin
            // 说明：把上一级总线内容暂存为写回级保存的访存结果总线。
            ms_to_ws_bus_r <= ms_to_ws_bus;
        // 说明：结束当前条件分支或时序代码块。
        end
        // 说明：进入前一个条件不成立时的处理分支。
        else begin
            // 说明：把上一级总线内容暂存为写回级保存的访存结果总线。
            ms_to_ws_bus_r <= 0;
        // 说明：结束当前条件分支或时序代码块。
        end
    // 说明：结束当前条件分支或时序代码块。
    end
// 说明：结束写回阶段模块定义。
endmodule