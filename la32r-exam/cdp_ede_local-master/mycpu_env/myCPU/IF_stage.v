// 说明：引入各级总线宽度和访存宽度的公共定义。
`include "mycpu_defines.vh"

// 说明：定义取指阶段模块及其对外接口。
module IF_stage(
    // 说明：作为输入端口接收时钟信号。
    input wire clk, //时钟
    // 说明：作为输入端口接收高电平复位信号。
    input wire reset,   //复位
    // 说明：作为输入端口接收译码级可以接收新指令的标志。
    input wire ds_allowin,  //告知是否下个阶段可以接受数据输入
    // 说明：作为输入端口接收跳转标志与目标地址总线。
    input wire [`BR_BUS_WD -1 :0] br_bus, //跳转信号
    // 说明：作为输出端口送出取指到译码的有效位。
    output wire fs_to_ds_valid,     //告知下个阶段数据是否有效
    // 说明：作为输出端口送出取指传给译码的指令和 PC 总线。
    output wire [`FS_TO_DS_BUS_WD-1 :0] fs_to_ds_bus,   //传递给下一级的缓冲区
    // inst sram interface
    // 说明：作为输出端口送出SRAM_EN的译码标志。
    output wire inst_sram_en,
    // 说明：作为输出端口送出SRAM_WE的译码标志。
    output wire [3:0] inst_sram_we,
    // 说明：作为输出端口送出SRAM_ADDR的译码标志。
    output wire [31:0] inst_sram_addr,
    // 说明：作为输出端口送出SRAM_WDATA的译码标志。
    output wire [31:0] inst_sram_wdata,
    // 说明：作为输入端口接收SRAM_RDATA的译码标志。
    input  wire [31:0] inst_sram_rdata
// 说明：结束模块端口列表或子模块端口连接。
);

    //if级握手信号
    // 说明：声明需要随时钟保存的取指级有效位。
    reg         fs_valid;
    // 说明：声明取指级已准备好标志，供本模块连接或计算。
    wire        fs_ready_go;
    // 说明：声明取指级可接收下一条指令的标志，供本模块连接或计算。
    wire        fs_allowin;
    // 说明：声明准备送入取指级的有效标志，供本模块连接或计算。
    wire        to_fs_valid;

    // 说明：声明顺序执行时的下一 PC，供本模块连接或计算。
    wire [31:0] seq_pc; //顺序的地址
    // 说明：声明实际选择的下一 PC，供本模块连接或计算。
    wire [31:0] next_pc; //下一个执行的地址，可能会跳转

    // 说明：声明本拍是否跳转，供本模块连接或计算。
    wire br_taken; //跳转信号
    // 说明：声明跳转目标地址，供本模块连接或计算。
    wire [31:0] br_target;//跳转地址

    // 说明：把跳转总线拆成是否跳转和跳转目标地址。
    assign {br_taken,br_target} = br_bus; //跳转信号传递

    // 说明：声明取出的指令字，供本模块连接或计算。
    wire [31:0] fs_inst; //fs阶段的inst和pc,往后传递
    // 说明：声明需要随时钟保存的取指级当前 PC。
    reg [31:0] fs_pc;

    //if向id传递的bus
    // 说明：把取出的指令字和取指 PC 一起送给译码级。
    assign fs_to_ds_bus = {fs_inst,fs_pc};

    //pre-if stage
    // 说明：离开复位后，取指级才开始产生有效取指请求。
    assign to_fs_valid = ~reset;
    // 说明：顺序执行时，下一条指令地址是当前 PC 加 4。
    assign seq_pc = fs_pc + 3'h4; //顺序
    // 说明：发生跳转就取跳转目标，否则沿顺序地址取指。
    assign next_pc = (br_taken == 1 ) ? br_target :seq_pc;

    //IF stage
    // 说明：这里的取指数据不需额外等待，本级始终准备好。
    assign fs_ready_go = 1'b1; //可以传输
    // 说明：本级空闲或译码级能接收时，可以接收下一次取指。
    assign fs_allowin = !fs_valid || fs_ready_go && ds_allowin; 
    //允许进入，需要了解下一级是否可以进入目的是可以实现保持停顿
    //br_taken 有效时, 本拍正要送往 ds 的那条指令属于跳转后的顺序路径(错误路径), 必须作废
    // 说明：跳转发生时丢弃错误路径上的指令，避免送入译码级。
    assign fs_to_ds_valid = fs_valid && fs_ready_go && !br_taken;

    // 说明：在时钟上升沿更新取指级有效位。
    always@(posedge clk)begin
        // 说明：复位有效时清空本级状态，使旧指令不再有效。
        if(reset)begin
            // 说明：更新取指级有效位，控制该级数据是否被下游采纳。
            fs_valid <= 1'b0;
        // 说明：进入前一个条件不成立时的处理分支。
        end else if(fs_allowin)begin
            // 说明：更新取指级有效位，控制该级数据是否被下游采纳。
            fs_valid <= to_fs_valid;
        // 说明：结束当前条件分支或时序代码块。
        end
    // 说明：结束当前条件分支或时序代码块。
    end

    // 说明：在时钟上升沿更新取指 PC。
    always@(posedge clk)begin
        // 说明：复位有效时清空本级状态，使旧指令不再有效。
        if(reset)begin
            // 说明：复位时把 PC 放在程序起始地址前一个字的位置。
            fs_pc <= 32'h1bfffffc;
        // 说明：进入前一个条件不成立时的处理分支。
        end else if(to_fs_valid && fs_allowin)begin
            // 说明：允许取指时，把选择后的下一 PC 保存为当前 PC。
            fs_pc <= next_pc;
        // 说明：结束当前条件分支或时序代码块。
        end
    // 说明：结束当前条件分支或时序代码块。
    end

    // 说明：处理器运行且本级可前进时，向指令内存发出读请求。
    assign inst_sram_en = to_fs_valid && fs_allowin;
    // 说明：取指始终只读不写，因此字节写使能为零。
    assign inst_sram_we = 4'h0;
    // 说明：用选择后的下一 PC 作为本次取指地址。
    assign inst_sram_addr = next_pc;
    // 说明：取指不需要写数据，所以写数据线固定为零。
    assign inst_sram_wdata = 32'b0;

    // 说明：从指令内存读回本拍的 32 位指令。
    assign fs_inst = inst_sram_rdata;

// 说明：结束取指阶段模块定义。
endmodule