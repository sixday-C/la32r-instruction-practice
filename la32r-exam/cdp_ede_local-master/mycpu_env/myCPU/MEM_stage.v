// 说明：引入各级总线宽度和访存宽度的公共定义。
`include "mycpu_defines.vh"

// 说明：定义访存阶段模块及其对外接口。
module MEM_stage(
    // 说明：作为输入端口接收时钟信号。
    input  wire        clk,
    // 说明：作为输入端口接收高电平复位信号。
    input  wire        reset,
    //allowin
    // 说明：作为输入端口接收写回级可接收新结果的标志。
    input  wire        ws_allowin,  //握手信号(来自 ws 级)
    // 说明：作为输出端口送出访存级可接收新结果的标志。
    output wire        ms_allowin,  //该阶段是否可以接收数据
    //from es stage
    // 说明：作为输入端口接收执行传给访存级的有效位。
    input  wire        es_to_ms_valid,
    // 说明：作为输入端口接收执行传给访存级的结果总线。
    input  wire [`ES_TO_MS_BUS_WD -1 :0] es_to_ms_bus,  //上一级缓冲区
    //to rf :write back
    // 说明：作为输出端口送出访存传给写回级的有效位。
    output wire        ms_to_ws_valid,  //告知下一级数据是否有效
    // 说明：作为输出端口送出访存传给写回级的控制和数据总线。
    output wire [`MS_TO_WS_BUS_WD -1 :0] ms_to_ws_bus,  //写回缓冲区
    //内存访问端口
    // 说明：作为输出端口送出数据内存的四位字节写使能。
    output wire [3:0]  data_sram_we,    //数据内存对应字节访问使能
    // 说明：作为输出端口送出数据内存访问使能。
    output wire        data_sram_en,    //数据内存使能
    // 说明：作为输出端口送出数据内存访问地址。
    output wire [31:0] data_sram_addr,  //访问地址
    // 说明：作为输出端口送出写入数据内存的数据。
    output wire [31:0] data_sram_wdata //写入数据
// 说明：结束模块端口列表或子模块端口连接。
);
    // 说明：声明需要随时钟保存的访存级有效位。
    reg mem_valid;
    // 说明：声明需要随时钟保存的访存级保存的执行结果总线。
    reg [`ES_TO_MS_BUS_WD -1 :0] es_to_ms_bus_r;
    // 说明：声明访存级已准备好的标志，供本模块连接或计算。
    wire ms_ready_go;
    /*assign es_to_mem_bus = {gr_we,  //写寄存器使能
                            dest,  //写寄存器地址
                            
                            load_op,  //load指令
                            res_from_mem,  //结果是否来自内存

                            mem_we,  //写内存使能
                            rkd_value,  //写内存数据
                            alu_result,  //alu计算结果
                            ds_pc  //当前指令的pc,用于debug
                            };*/
    // 说明：当前内存接口按本拍完成处理，本级始终准备好。
    assign ms_ready_go     = 1'b1;
    // 说明：本级空闲，或结果可送写回级时，允许新结果进入。
    assign ms_allowin      = !mem_valid || ms_ready_go && ws_allowin;
    // 说明：本级有有效指令时才向写回级送出有效标志。
    assign ms_to_ws_valid  = mem_valid && ms_ready_go;
    // 说明：在时钟上升沿更新本级保存的有效位和数据。
    always @(posedge clk) begin
        // 说明：复位有效时清空本级状态，使旧指令不再有效。
        if (reset) begin
            // 说明：更新访存级有效位，控制该级数据是否被下游采纳。
            mem_valid <= 1'b0;
            // 说明：把上一级总线内容暂存为访存级保存的执行结果总线。
            es_to_ms_bus_r <= 0;
        // 说明：结束当前条件分支或时序代码块。
        end
        // 说明：只有括号里的条件成立，才执行这一分支的状态更新。
        else if (ms_allowin) begin
            // 说明：更新访存级有效位，控制该级数据是否被下游采纳。
            mem_valid <= es_to_ms_valid;
        // 说明：结束当前条件分支或时序代码块。
        end

        // 说明：执行级送来有效结果且本级可接收时，锁存该结果。
        if (es_to_ms_valid && ms_allowin) begin
            // 说明：把上一级总线内容暂存为访存级保存的执行结果总线。
            es_to_ms_bus_r <= es_to_ms_bus;
        // 说明：结束当前条件分支或时序代码块。
        end
        // 说明：进入前一个条件不成立时的处理分支。
        else begin
            // 说明：把上一级总线内容暂存为访存级保存的执行结果总线。
            es_to_ms_bus_r <= 0;
        // 说明：结束当前条件分支或时序代码块。
        end
    // 说明：结束当前条件分支或时序代码块。
    end
    // 说明：声明数据内存写使能标志、通用寄存器写使能、写回数据来自内存的标志、当前指令是加载指令的标志、加载结果需要符号扩展的标志，供本模块连接或计算。
    wire         mem_we, gr_we,res_from_mem, load_op, load_signed;
    // 说明：声明本次访存的数据宽度编码、访存地址在字内的偏移，供本模块连接或计算。
    wire [1:0] mem_size ,mem_addr_offset;
    // 说明：声明最终要写的寄存器编号，供本模块连接或计算。
    wire [4:0] dest;
    // 说明：声明经过前递选择的第二源寄存器值、ALU 最终输出结果、当前指令的 PC、对齐到内存字宽的待写数据，供本模块连接或计算。
    wire [31:0] rkd_value, alu_result, ds_pc, sram_wdata;
    // 说明：声明按访问宽度选出的字节写掩码，供本模块连接或计算。
    wire [3:0] sram_we;
    // 说明：按执行级总线规定的顺序拆出访存和写回所需字段。
    assign {
            // 说明：把加载结果需要符号扩展的标志放入当前总线字段或选择条件。
            load_signed,  //load指令
            // 说明：把本次访存的数据宽度编码放入当前总线字段或选择条件。
            mem_size,
            // 说明：把通用寄存器写使能放入当前总线字段或选择条件。
            gr_we,  //写寄存器使能
            // 说明：把最终要写的寄存器编号放入当前总线字段或选择条件。
            dest,  //写寄存器地址
            
            // 说明：把当前指令是加载指令的标志放入当前总线字段或选择条件。
            load_op,  //load指令
            // 说明：把写回数据来自内存的标志放入当前总线字段或选择条件。
            res_from_mem,  //结果是否来自内存

            // 说明：把数据内存写使能标志放入当前总线字段或选择条件。
            mem_we,  //写内存使能
            // 说明：把经过前递选择的第二源寄存器值放入当前总线字段或选择条件。
            rkd_value,  //写内存数据
            // 说明：把ALU 最终输出结果放入当前总线字段或选择条件。
            alu_result,  //alu计算结果
            // 说明：把当前指令的 PC放入当前总线字段或选择条件。
            ds_pc  //当前指令的pc,用于debug
            // 说明：拆出最后的 PC 字段，完成执行结果总线解包。
            } = es_to_ms_bus_r;

    //访存请求只在本级有效时才发出
    // 说明：仅对有效的读或写指令使能数据内存。
    assign data_sram_en    = mem_valid && (mem_we | res_from_mem | load_op);

    // 说明：写字节时，把低 8 位复制到四个字节位置。
    assign sram_wdata = mem_size == `B ? {4{rkd_value[7:0]}} :
                        // 说明：写半字时，把低 16 位复制到两个半字位置。
                        mem_size == `H ? {2{rkd_value[15:0]}} :
                        // 说明：写整字时直接使用原始 32 位寄存器数据。
                        rkd_value;
    // 说明：字节写入时先按地址最低两位挑选目标字节。
    assign sram_we    = mem_size == `B ? (alu_result[1:0] == 2'b00 ? 4'b0001 :
                                         // 说明：地址偏移为 1 时，选择第二个字节写使能。
                                         alu_result[1:0] == 2'b01 ? 4'b0010 :
                                         // 说明：地址偏移为 2 时，选择第三个字节写使能。
                                         alu_result[1:0] == 2'b10 ? 4'b0100 :
                                         // 说明：其余偏移选择第四个字节写使能。
                                         4'b1000) :
                        // 说明：半字写入按地址第 1 位选择低半字或高半字。
                        mem_size == `H ? (alu_result[1] == 1'b0 ? 4'b0011 : 4'b1100):
                        // 说明：整字访问使能全部四个字节。
                        4'b1111;
    // 说明：ALU 算出的地址直接送到数据内存接口。
    assign data_sram_addr  = alu_result;
    // 说明：将按访存宽度复制好的数据送到内存接口。
    assign data_sram_wdata = sram_wdata;
    // 说明：只有有效存储指令才输出选好的字节写掩码。
    assign data_sram_we    = (mem_valid & mem_we) ? sram_we : 4'b0;

    // 说明：取地址最低两位，供写回级选择读取的字节或半字。
    assign mem_addr_offset = alu_result[1:0];   //内存地址的偏移量
    // ms_to_ws_bus 总位宽 = 1+5+32+32 = 70 bit
    // 说明：开始打包访存结果、目标寄存器和调试 PC。
    assign ms_to_ws_bus = {
                            // 说明：把访存地址在字内的偏移放入当前总线字段或选择条件。
                            mem_addr_offset ,  //[76:75]  内存地址的偏移量
                            // 说明：把加载结果需要符号扩展的标志放入当前总线字段或选择条件。
                            load_signed  ,  //[74]     load指令是否有符号扩展
                            // 说明：把本次访存的数据宽度编码放入当前总线字段或选择条件。
                            mem_size     ,  //[73:72]
                            // 说明：把当前指令是加载指令的标志放入当前总线字段或选择条件。
                            load_op      ,  //[71]     load标志
                            // 说明：把通用寄存器写使能放入当前总线字段或选择条件。
                            gr_we        ,  //[70]     写寄存器使能
                            // 说明：把最终要写的寄存器编号放入当前总线字段或选择条件。
                            dest         ,  //[69:65]  写寄存器地址
                            // 说明：把写回数据来自内存的标志放入当前总线字段或选择条件。
                            res_from_mem ,
                            // 说明：把ALU 最终输出结果放入当前总线字段或选择条件。
                            alu_result ,  //[63:32]  写回数据(load/alu 已 mux)
                            // 说明：把当前指令的 PC放入当前总线字段或选择条件。
                            ds_pc           //[31: 0]  当前指令的pc, 用于debug
                          // 说明：完成访存到写回级的字段拼接。
                          };
// 说明：结束访存阶段模块定义。
endmodule