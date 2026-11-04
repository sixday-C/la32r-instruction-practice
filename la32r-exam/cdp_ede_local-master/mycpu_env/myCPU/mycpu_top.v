/* fs: fetch stage
 * ds: decode stage
 * es: execute stage
 * ms: memory stage
 * ws: write back stage
 */
// 说明：引入各级总线宽度和访存宽度的公共定义。
`include "mycpu_defines.vh"

// 说明：定义处理器顶层模块及其对外接口。
module mycpu_top(
    // 说明：作为输入端口接收时钟信号。
    input  wire        clk,
    // 说明：作为输入端口接收低电平复位输入。
    input  wire        resetn,
    // inst sram interface
    // 说明：作为输出端口送出SRAM_WE的译码标志。
    output wire [3:0]  inst_sram_we,    //指令内存对应字节访问使能
    // 说明：作为输出端口送出SRAM_EN的译码标志。
    output wire        inst_sram_en,    // block Memory 使能
    // 说明：作为输出端口送出SRAM_ADDR的译码标志。
    output wire [31:0] inst_sram_addr,  //访问地址
    // 说明：作为输出端口送出SRAM_WDATA的译码标志。
    output wire [31:0] inst_sram_wdata, //写入数据
    // 说明：作为输入端口接收SRAM_RDATA的译码标志。
    input  wire [31:0] inst_sram_rdata, //读数据
    // data sram interface
    // 说明：作为输出端口送出数据内存的四位字节写使能。
    output wire [3:0]  data_sram_we,
    // 说明：作为输出端口送出数据内存访问使能。
    output wire        data_sram_en,
    // 说明：作为输出端口送出数据内存访问地址。
    output wire [31:0] data_sram_addr,
    // 说明：作为输出端口送出写入数据内存的数据。
    output wire [31:0] data_sram_wdata,
    // 说明：作为输入端口接收从数据内存读到的数据。
    input  wire [31:0] data_sram_rdata,
    // trace debug interface
    // 说明：作为输出端口送出写回级用于调试的 PC。
    output wire [31:0] debug_wb_pc,         //pc值
    // 说明：作为输出端口送出写回级用于调试的写使能。
    output wire [ 3:0] debug_wb_rf_we,      //写寄存器信号
    // 说明：作为输出端口送出写回级用于调试的目标寄存器编号。
    output wire [ 4:0] debug_wb_rf_wnum,    //写入的寄存器号
    // 说明：作为输出端口送出写回级用于调试的写入数据。
    output wire [31:0] debug_wb_rf_wdata    //写入数据
// 说明：结束模块端口列表或子模块端口连接。
);
    // 说明：声明高电平复位信号，供本模块连接或计算。
    wire reset;
    // 说明：外部 resetn 为低电平有效，内部各级改用高电平有效的 reset。
    assign reset = ~resetn; //复位信号
    // 说明：声明译码级可以接收新指令的标志、执行级可接收新指令的标志、访存级可接收新结果的标志、写回级可接收新结果的标志，供本模块连接或计算。
    wire        ds_allowin, es_allowin, ms_allowin, ws_allowin;
    // 说明：声明取指到译码的有效位、译码传给执行级的有效位、执行传给访存级的有效位、访存传给写回级的有效位，供本模块连接或计算。
    wire        fs_to_ds_valid, ds_to_es_valid, es_to_ms_valid, ms_to_ws_valid;

    // 说明：声明跳转标志与目标地址总线，供本模块连接或计算。
    wire [`BR_BUS_WD       -1:0] br_bus;
    // 说明：声明取指传给译码的指令和 PC 总线，供本模块连接或计算。
    wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
    // 说明：声明译码传给执行级的控制和数据总线，供本模块连接或计算。
    wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
    // 说明：声明执行传给访存级的结果总线，供本模块连接或计算。
    wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
    // 说明：声明访存传给写回级的控制和数据总线，供本模块连接或计算。
    wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
    // 说明：声明写回到寄存器堆的数据总线，供本模块连接或计算。
    wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;

    // 取指
    // 说明：实例化取指级，负责选择 PC 并从指令内存取指。
    IF_stage if_stage(
        // 说明：把时钟信号接到子模块的对应端口。
        .clk(clk), //时钟
        // 说明：把高电平复位信号接到子模块的对应端口。
        .reset(reset),   //复位
        // 说明：把译码级可以接收新指令的标志接到子模块的对应端口。
        .ds_allowin(ds_allowin),  //告知是否下个阶段可以接受数据输入
        // 说明：把跳转标志与目标地址总线接到子模块的对应端口。
        .br_bus(br_bus), //
        // 说明：把取指到译码的有效位接到子模块的对应端口。
        .fs_to_ds_valid(fs_to_ds_valid),
        // 说明：把取指传给译码的指令和 PC 总线接到子模块的对应端口。
        .fs_to_ds_bus(fs_to_ds_bus),
        // inst sram interface
        // 说明：把SRAM_EN的译码标志接到子模块的对应端口。
        .inst_sram_en(inst_sram_en),
        // 说明：把SRAM_WE的译码标志接到子模块的对应端口。
        .inst_sram_we(inst_sram_we),
        // 说明：把SRAM_ADDR的译码标志接到子模块的对应端口。
        .inst_sram_addr(inst_sram_addr),
        // 说明：把SRAM_WDATA的译码标志接到子模块的对应端口。
        .inst_sram_wdata(inst_sram_wdata),
        // 说明：把SRAM_RDATA的译码标志接到子模块的对应端口。
        .inst_sram_rdata(inst_sram_rdata)
    // 说明：结束模块端口列表或子模块端口连接。
    );

    // 译码
    // 说明：实例化译码级，负责识别指令、读取寄存器和处理相关。
    ID_stage id_stage(
        // 说明：把时钟信号接到子模块的对应端口。
        .clk(clk),
        // 说明：把高电平复位信号接到子模块的对应端口。
        .reset(reset),
        //allowin
        // 说明：把执行级可接收新指令的标志接到子模块的对应端口。
        .es_allowin(es_allowin),  //握手信号
        // 说明：把译码级可以接收新指令的标志接到子模块的对应端口。
        .ds_allowin(ds_allowin),  //该阶段是否k可以接收数据
        //from if stage
        // 说明：把取指到译码的有效位接到子模块的对应端口。
        .fs_to_ds_valid(fs_to_ds_valid),
        // 说明：把取指传给译码的指令和 PC 总线接到子模块的对应端口。
        .fs_to_ds_bus(fs_to_ds_bus),
        //to ex stage
        // 说明：把译码传给执行级的有效位接到子模块的对应端口。
        .ds_to_es_valid(ds_to_es_valid),
        // 说明：把译码传给执行级的控制和数据总线接到子模块的对应端口。
        .ds_to_es_bus(ds_to_es_bus),
        //to if stage
        // 说明：把跳转标志与目标地址总线接到子模块的对应端口。
        .br_bus(br_bus),
        //to rf :write back
        // 说明：把写回到寄存器堆的数据总线接到子模块的对应端口。
        .ws_to_rf_bus(ws_to_rf_bus),
        // 说明：把执行级结果总线送回译码级，供相关判断使用。
        .es_to_ms_bus(es_to_ms_bus),
        // 说明：把执行级的加载标志、写回目标和值组成前递信息。
        .es_dest({es_to_ms_bus[98],es_to_ms_bus[104:99], es_to_ms_bus[63:32]}),
        // 说明：把访存级的加载标志、写回目标和值组成前递信息。
        .ms_dest({ms_to_ws_bus[71],ms_to_ws_bus[70:65], ms_to_ws_bus[63:32]})
    // 说明：结束模块端口列表或子模块端口连接。
    );

    // 说明：实例化执行级，用 ALU 处理译码后的操作数。
    EX_stage ex_stage(
        // 说明：把时钟信号接到子模块的对应端口。
        .clk(clk),
        // 说明：把高电平复位信号接到子模块的对应端口。
        .reset(reset),
        //allowin
        // 说明：把访存级可接收新结果的标志接到子模块的对应端口。
        .ms_allowin(ms_allowin),  //握手信号
        // 说明：把执行级可接收新指令的标志接到子模块的对应端口。
        .es_allowin(es_allowin),  //该阶段是否k可以接收数据
        //from ds stage
        // 说明：把译码传给执行级的有效位接到子模块的对应端口。
        .ds_to_es_valid(ds_to_es_valid),
        // 说明：把译码传给执行级的控制和数据总线接到子模块的对应端口。
        .ds_to_es_bus(ds_to_es_bus),  //上一级缓冲区
        //to ms stage
        // 说明：把执行传给访存级的有效位接到子模块的对应端口。
        .es_to_ms_valid(es_to_ms_valid),  //告知下一级数据是否有效
        // 说明：把执行传给访存级的结果总线接到子模块的对应端口。
        .es_to_ms_bus(es_to_ms_bus)       //下一级缓冲区
    // 说明：结束模块端口列表或子模块端口连接。
    );

    // 说明：实例化访存级，向数据内存发出读写请求。
    MEM_stage mem_stage(
        // 说明：把时钟信号接到子模块的对应端口。
        .clk(clk),
        // 说明：把高电平复位信号接到子模块的对应端口。
        .reset(reset),
        //allowin
        // 说明：把写回级可接收新结果的标志接到子模块的对应端口。
        .ws_allowin(ws_allowin),  //握手信号
        // 说明：把访存级可接收新结果的标志接到子模块的对应端口。
        .ms_allowin(ms_allowin),  //该阶段是否可以接收数据
        //from es stage
        // 说明：把执行传给访存级的有效位接到子模块的对应端口。
        .es_to_ms_valid(es_to_ms_valid),
        // 说明：把执行传给访存级的结果总线接到子模块的对应端口。
        .es_to_ms_bus(es_to_ms_bus),  //上一级缓冲区
        //to ws stage
        // 说明：把访存传给写回级的有效位接到子模块的对应端口。
        .ms_to_ws_valid(ms_to_ws_valid),  //告知下一级数据是否有效
        // 说明：把访存传给写回级的控制和数据总线接到子模块的对应端口。
        .ms_to_ws_bus(ms_to_ws_bus),   //写回缓冲区
        // data sram interface
        // 说明：把数据内存访问使能接到子模块的对应端口。
        .data_sram_en(data_sram_en),
        // 说明：把数据内存的四位字节写使能接到子模块的对应端口。
        .data_sram_we(data_sram_we),
        // 说明：把数据内存访问地址接到子模块的对应端口。
        .data_sram_addr(data_sram_addr),
        // 说明：把写入数据内存的数据接到子模块的对应端口。
        .data_sram_wdata(data_sram_wdata)
    // 说明：结束模块端口列表或子模块端口连接。
    );

    // 说明：实例化写回级，把 ALU 或内存结果送回寄存器堆。
    WB_stage wb_stage(
        // 说明：把时钟信号接到子模块的对应端口。
        .clk(clk),
        // 说明：把高电平复位信号接到子模块的对应端口。
        .reset(reset),
        //allowin
        // 说明：把写回级可接收新结果的标志接到子模块的对应端口。
        .ws_allowin(ws_allowin),  //该阶段是否k可以接收数据
        //from ms stage
        // 说明：把访存传给写回级的有效位接到子模块的对应端口。
        .ms_to_ws_valid(ms_to_ws_valid),
        // 说明：把访存传给写回级的控制和数据总线接到子模块的对应端口。
        .ms_to_ws_bus(ms_to_ws_bus),  //上一级缓冲区
        //to rf :write back
        // 说明：把写回到寄存器堆的数据总线接到子模块的对应端口。
        .ws_to_rf_bus(ws_to_rf_bus),   //写回缓冲区
        // trace debug interface
        // 说明：把写回级用于调试的 PC接到子模块的对应端口。
        .debug_wb_pc(debug_wb_pc),
        // 说明：把写回级用于调试的写使能接到子模块的对应端口。
        .debug_wb_rf_we(debug_wb_rf_we),
        // 说明：把写回级用于调试的目标寄存器编号接到子模块的对应端口。
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        // 说明：把写回级用于调试的写入数据接到子模块的对应端口。
        .debug_wb_rf_wdata(debug_wb_rf_wdata),
        // 说明：把从数据内存读到的数据接到子模块的对应端口。
        .data_sram_rdata(data_sram_rdata)
    // 说明：结束模块端口列表或子模块端口连接。
    );
// 说明：结束处理器顶层模块定义。
endmodule
