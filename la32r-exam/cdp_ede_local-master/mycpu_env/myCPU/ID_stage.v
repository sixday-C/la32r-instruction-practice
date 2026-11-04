// 说明：引入各级总线宽度和访存宽度的公共定义。
`include "mycpu_defines.vh"

// 说明：定义译码阶段模块及其对外接口。
module ID_stage(
    // 说明：作为输入端口接收时钟信号。
    input  wire        clk,
    // 说明：作为输入端口接收高电平复位信号。
    input  wire        reset,
    //allowin
    // 说明：作为输入端口接收执行级可接收新指令的标志。
    input  wire        es_allowin,  //握手信号
    // 说明：作为输出端口送出译码级可以接收新指令的标志。
    output wire        ds_allowin,  //该阶段是否k可以接收数据
    //from if stage
    // 说明：作为输入端口接收取指到译码的有效位。
    input  wire        fs_to_ds_valid,
    // 说明：作为输入端口接收取指传给译码的指令和 PC 总线。
    input  wire [`FS_TO_DS_BUS_WD -1 :0] fs_to_ds_bus,  //上一级缓冲区
    //to ex stage
    // 说明：作为输出端口送出译码传给执行级的有效位。
    output wire        ds_to_es_valid,      //告知下一级数据是否有效
    // 说明：作为输出端口送出译码传给执行级的控制和数据总线。
    output wire [`DS_TO_ES_BUS_WD -1 :0] ds_to_es_bus,  //下一级缓冲区
    //to if stage
    // 说明：作为输出端口送出跳转标志与目标地址总线。
    output wire [`BR_BUS_WD -1 : 0 ] br_bus,    //跳转信号
    //to rf :write back
    // 说明：作为输入端口接收写回到寄存器堆的数据总线。
    input  wire [`WS_TO_RF_BUS_WD -1 :0] ws_to_rf_bus,   //写回缓冲区
    //处理冲突
    // 说明：作为输入端口接收执行传给访存级的结果总线。
    input wire  [`ES_TO_MS_BUS_WD -1 :0] es_to_ms_bus,   //来自es阶段的冲突信号
    // 说明：作为输入端口接收es_dest 信号。
    input wire  [38 : 0] es_dest,   //load_op , gr_we , dest[5] , data[32]
    // 说明：作为输入端口接收ms_dest 信号。
    input wire  [38 : 0] ms_dest

// 说明：结束模块端口列表或子模块端口连接。
);

// 说明：声明本拍是否跳转，供本模块连接或计算。
wire br_taken;
// 说明：声明跳转目标地址，供本模块连接或计算。
wire [31:0] br_target;

// 说明：声明当前指令的 PC，供本模块连接或计算。
wire [31:0] ds_pc;
// 说明：声明当前待译码指令字，供本模块连接或计算。
wire [31:0] ds_inst;

// 说明：声明需要随时钟保存的译码级有效位。
reg         ds_valid;
// 说明：声明译码级可以向后传递的标志，供本模块连接或计算。
wire        ds_ready_go;

// 说明：声明ALU 运算选择位，供本模块连接或计算。
wire [11:0] alu_op;

// 说明：声明加载结果需要符号扩展的标志，供本模块连接或计算。
wire load_signed;  //加载的数据是否要进行有符号扩展
// 说明：声明本次访存的数据宽度编码，供本模块连接或计算。
wire [1:0] mem_size;  //内存写入/读取的数据大小
// 说明：声明当前指令是加载指令的标志，供本模块连接或计算。
wire load_op;  //加载信号
// 说明：声明ALU 第一输入选择 PC 的标志，供本模块连接或计算。
wire src1_is_pc; //来自src为pc地址
// 说明：声明ALU 第二输入选择立即数的标志，供本模块连接或计算。
wire src2_is_imm; //src2为imm
// 说明：声明写回数据来自内存的标志，供本模块连接或计算。
wire res_from_mem; //结果来自mem
// 说明：声明目标寄存器改为 r1 的标志，供本模块连接或计算。
wire dst_is_r1;
// 说明：声明通用寄存器写使能，供本模块连接或计算。
wire gr_we;
// 说明：声明数据内存写使能标志，供本模块连接或计算。
wire mem_we;
// 说明：声明第二个读口改读 rd 的标志，供本模块连接或计算。
wire src_reg_is_rd;
// 说明：声明最终要写的寄存器编号，供本模块连接或计算。
wire [4:0]dest;
// 说明：声明两个源操作数相等的比较结果，供本模块连接或计算。
wire rj_eq_rd;
// 说明：声明经过前递选择的 rj 值，供本模块连接或计算。
wire [31:0]rj_value;
// 说明：声明经过前递选择的第二源寄存器值，供本模块连接或计算。
wire [31:0]rkd_value;
// 说明：声明扩展成 32 位的立即数，供本模块连接或计算。
wire [31:0]imm;
// 说明：声明相对 PC 的分支偏移量，供本模块连接或计算。
wire [31:0]br_offs;
// 说明：声明JIRL 使用的地址偏移量，供本模块连接或计算。
wire [31:0]jirl_offs;

//分段
// 说明：声明指令最高 6 位主操作码，供本模块连接或计算。
wire [5:0] op_31_26;
// 说明：声明指令的 4 位次操作码，供本模块连接或计算。
wire [3:0] op_25_22;
// 说明：声明指令的 2 位次操作码，供本模块连接或计算。
wire [ 1:0] op_21_20;
// 说明：声明指令的 5 位功能码，供本模块连接或计算。
wire [ 4:0] op_19_15;

// 说明：声明目标寄存器编号，供本模块连接或计算。
wire [ 4:0] rd;
// 说明：声明第一个源寄存器编号，供本模块连接或计算。
wire [ 4:0] rj;
// 说明：声明第二个源寄存器编号，供本模块连接或计算。
wire [ 4:0] rk;

// 说明：声明12 位立即数字段，供本模块连接或计算。
wire [11:0] i12;
// 说明：声明20 位立即数字段，供本模块连接或计算。
wire [19:0] i20;
// 说明：声明16 位立即数字段，供本模块连接或计算。
wire [15:0] i16;
// 说明：声明26 位分支偏移字段，供本模块连接或计算。
wire [25:0] i26;

// 说明：声明主操作码的一位有效译码结果，供本模块连接或计算。
wire [63:0] op_31_26_d;
// 说明：声明4 位次操作码的一位有效译码结果，供本模块连接或计算。
wire [15:0] op_25_22_d;
// 说明：声明2 位次操作码的一位有效译码结果，供本模块连接或计算。
wire [ 3:0] op_21_20_d;
// 说明：声明功能码的一位有效译码结果，供本模块连接或计算。
wire [31:0] op_19_15_d;

// 说明：声明ADD.W 加法的译码标志，供本模块连接或计算。
wire        inst_add_w;
// 说明：声明SUB.W 减法的译码标志，供本模块连接或计算。
wire        inst_sub_w;
// 说明：声明SLT 有符号小于比较的译码标志，供本模块连接或计算。
wire        inst_slt;
// 说明：声明SLTU 无符号小于比较的译码标志，供本模块连接或计算。
wire        inst_sltu;
// 说明：声明NOR 按位或非的译码标志，供本模块连接或计算。
wire        inst_nor;
// 说明：声明AND 按位与的译码标志，供本模块连接或计算。
wire        inst_and;
// 说明：声明OR 按位或的译码标志，供本模块连接或计算。
wire        inst_or;
// 说明：声明XOR 按位异或的译码标志，供本模块连接或计算。
wire        inst_xor;
// 说明：声明SLLI.W 立即数逻辑左移的译码标志，供本模块连接或计算。
wire        inst_slli_w;
// 说明：声明SRLI.W 立即数逻辑右移的译码标志，供本模块连接或计算。
wire        inst_srli_w;
// 说明：声明SRAI.W 立即数算术右移的译码标志，供本模块连接或计算。
wire        inst_srai_w;
// 说明：声明ADDI.W 立即数加法的译码标志，供本模块连接或计算。
wire        inst_addi_w;
// 说明：声明LD.W 读字的译码标志，供本模块连接或计算。
wire        inst_ld_w;
// 说明：声明ST.W 写字的译码标志，供本模块连接或计算。
wire        inst_st_w;
// 说明：声明JIRL 寄存器间接跳转的译码标志，供本模块连接或计算。
wire        inst_jirl;
// 说明：声明B 无条件跳转的译码标志，供本模块连接或计算。
wire        inst_b;
// 说明：声明BL 跳转并保存返回地址的译码标志，供本模块连接或计算。
wire        inst_bl;
// 说明：声明BEQ 相等跳转的译码标志，供本模块连接或计算。
wire        inst_beq;
// 说明：声明BNE 不等跳转的译码标志，供本模块连接或计算。
wire        inst_bne;
// 说明：声明LU12I.W 装入高位立即数的译码标志，供本模块连接或计算。
wire        inst_lu12i_w;
// 说明：声明PCADDU12I 计算 PC 相对地址的译码标志，供本模块连接或计算。
wire        inst_pcaddu12i;
// 说明：声明SLTI 有符号立即数比较的译码标志，供本模块连接或计算。
wire        inst_slti;
// 说明：声明SLTUI 无符号立即数比较的译码标志，供本模块连接或计算。
wire        inst_sltui;
// 说明：声明ANDI 立即数按位与的译码标志，供本模块连接或计算。
wire        inst_andi;
// 说明：声明ORI 立即数按位或的译码标志，供本模块连接或计算。
wire        inst_ori;
// 说明：声明XORI 立即数按位异或的译码标志，供本模块连接或计算。
wire        inst_xori;
// 说明：声明SLL.W 寄存器逻辑左移的译码标志，供本模块连接或计算。
wire        inst_sll_w;
// 说明：声明SRA.W 寄存器算术右移的译码标志，供本模块连接或计算。
wire        inst_sra_w;
// 说明：声明SRL.W 寄存器逻辑右移的译码标志，供本模块连接或计算。
wire        inst_srl_w;
// 说明：声明BLT 有符号小于跳转的译码标志，供本模块连接或计算。
wire        inst_blt;
// 说明：声明BGE 有符号大于等于跳转的译码标志，供本模块连接或计算。
wire        inst_bge;
// 说明：声明BLTU 无符号小于跳转的译码标志，供本模块连接或计算。
wire        inst_bltu;
// 说明：声明BGEU 无符号大于等于跳转的译码标志，供本模块连接或计算。
wire        inst_bgeu;
// 说明：声明LD.B 有符号读字节的译码标志，供本模块连接或计算。
wire        inst_ld_b;
// 说明：声明LD.H 有符号读半字的译码标志，供本模块连接或计算。
wire        inst_ld_h;
// 说明：声明LD.BU 无符号读字节的译码标志，供本模块连接或计算。
wire        inst_ld_bu;
// 说明：声明LD.HU 无符号读半字的译码标志，供本模块连接或计算。
wire        inst_ld_hu;
// 说明：声明ST.B 写字节的译码标志，供本模块连接或计算。
wire        inst_st_b;
// 说明：声明ST.H 写半字的译码标志，供本模块连接或计算。
wire        inst_st_h;

// 说明：声明需要 5 位无符号移位量的标志，供本模块连接或计算。
wire        need_ui5;
// 说明：声明需要 12 位符号扩展立即数的标志，供本模块连接或计算。
wire        need_si12;
// 说明：声明需要 16 位分支偏移的标志，供本模块连接或计算。
wire        need_si16;
// 说明：声明需要 20 位高位立即数的标志，供本模块连接或计算。
wire        need_si20;
// 说明：声明需要 26 位分支偏移的标志，供本模块连接或计算。
wire        need_si26;
// 说明：声明ALU 第二输入需要常数 4 的标志，供本模块连接或计算。
wire        src2_is_4;

// 说明：声明寄存器堆第一个读地址，供本模块连接或计算。
wire [ 4:0] rf_raddr1;
// 说明：声明寄存器堆第一个读值，供本模块连接或计算。
wire [31:0] rf_rdata1;
// 说明：声明寄存器堆第二个读地址，供本模块连接或计算。
wire [ 4:0] rf_raddr2;
// 说明：声明寄存器堆第二个读值，供本模块连接或计算。
wire [31:0] rf_rdata2;

// 说明：声明ALU 第一个输入数，供本模块连接或计算。
wire [31:0] alu_src1 ;
// 说明：声明ALU 第二个输入数，供本模块连接或计算。
wire [31:0] alu_src2;
// 说明：声明ALU 最终输出结果，供本模块连接或计算。
wire [31:0] alu_result;

// 说明：声明mem_result 信号，供本模块连接或计算。
wire [31:0] mem_result;
// 说明：声明final_result 信号，供本模块连接或计算。
wire [31:0] final_result;

// 说明：把指令最高 6 位取出，供主操作码译码。
assign op_31_26  = ds_inst[31:26];
// 说明：取出接下来的 4 位次操作码。
assign op_25_22  = ds_inst[25:22];
// 说明：取出 2 位次操作码。
assign op_21_20  = ds_inst[21:20];
// 说明：取出 5 位功能码，用于区分同类寄存器指令。
assign op_19_15  = ds_inst[19:15];

// 说明：指令最低 5 位指定目标寄存器 rd。
assign rd   = ds_inst[ 4: 0];
// 说明：指令的第 9 到第 5 位指定源寄存器 rj。
assign rj   = ds_inst[ 9: 5];
// 说明：指令的第 14 到第 10 位指定源寄存器 rk。
assign rk   = ds_inst[14:10];

// 说明：截取 12 位立即数，供加法、访存和逻辑立即数指令使用。
assign i12  = ds_inst[21:10];
// 说明：截取 20 位立即数，供构造高位常数和 PC 相对地址使用。
assign i20  = ds_inst[24: 5];
// 说明：截取 16 位分支或 JIRL 偏移字段。
assign i16  = ds_inst[25:10];
// 说明：按指令格式拼接分散的位段，得到 26 位跳转偏移字段。
assign i26  = {ds_inst[ 9: 0], ds_inst[25:10]};

// 说明：把 6 位主操作码译成 64 路一位有效信号。
decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
// 说明：把 4 位次操作码译成 16 路一位有效信号。
decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
// 说明：把 2 位次操作码译成 4 路一位有效信号。
decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
// 说明：把 5 位功能码译成 32 路一位有效信号。
decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

// 说明：逐字段核对操作码，识别当前指令是否为ADD.W 加法。
assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
// 说明：逐字段核对操作码，识别当前指令是否为SUB.W 减法。
assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
// 说明：逐字段核对操作码，识别当前指令是否为SLT 有符号小于比较。
assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
// 说明：逐字段核对操作码，识别当前指令是否为SLTU 无符号小于比较。
assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
// 说明：逐字段核对操作码，识别当前指令是否为NOR 按位或非。
assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
// 说明：逐字段核对操作码，识别当前指令是否为AND 按位与。
assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
// 说明：逐字段核对操作码，识别当前指令是否为OR 按位或。
assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
// 说明：逐字段核对操作码，识别当前指令是否为XOR 按位异或。
assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
// 说明：逐字段核对操作码，识别当前指令是否为SLLI.W 立即数逻辑左移。
assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
// 说明：逐字段核对操作码，识别当前指令是否为SRLI.W 立即数逻辑右移。
assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
// 说明：逐字段核对操作码，识别当前指令是否为SRAI.W 立即数算术右移。
assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
// 说明：逐字段核对操作码，识别当前指令是否为ADDI.W 立即数加法。
assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];
// 说明：逐字段核对操作码，识别当前指令是否为LD.W 读字。
assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
// 说明：逐字段核对操作码，识别当前指令是否为ST.W 写字。
assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
// 说明：逐字段核对操作码，识别当前指令是否为JIRL 寄存器间接跳转。
assign inst_jirl   = op_31_26_d[6'h13];
// 说明：逐字段核对操作码，识别当前指令是否为B 无条件跳转。
assign inst_b      = op_31_26_d[6'h14];
// 说明：逐字段核对操作码，识别当前指令是否为BL 跳转并保存返回地址。
assign inst_bl     = op_31_26_d[6'h15];
// 说明：逐字段核对操作码，识别当前指令是否为BEQ 相等跳转。
assign inst_beq    = op_31_26_d[6'h16];
// 说明：逐字段核对操作码，识别当前指令是否为BNE 不等跳转。
assign inst_bne    = op_31_26_d[6'h17];
// 说明：逐字段核对操作码，识别当前指令是否为LU12I.W 装入高位立即数。
assign inst_lu12i_w= op_31_26_d[6'h05] & ~ds_inst[25];
// 说明：逐字段核对操作码，识别当前指令是否为PCADDU12I 计算 PC 相对地址。
assign inst_pcaddu12i = op_31_26_d[6'h07] & ~ds_inst[25];
// 说明：逐字段核对操作码，识别当前指令是否为SLTI 有符号立即数比较。
assign inst_slti = op_31_26_d[6'h00] & op_25_22_d[4'h8];
// 说明：逐字段核对操作码，识别当前指令是否为SLTUI 无符号立即数比较。
assign inst_sltui = op_31_26_d[6'h00] & op_25_22_d[4'h9];
// 说明：逐字段核对操作码，识别当前指令是否为ANDI 立即数按位与。
assign inst_andi = op_31_26_d[6'h00] & op_25_22_d[4'hd];
// 说明：逐字段核对操作码，识别当前指令是否为ORI 立即数按位或。
assign inst_ori = op_31_26_d[6'h00] & op_25_22_d[4'he];
// 说明：逐字段核对操作码，识别当前指令是否为XORI 立即数按位异或。
assign inst_xori = op_31_26_d[6'h00] & op_25_22_d[4'hf];
// 说明：逐字段核对操作码，识别当前指令是否为SLL.W 寄存器逻辑左移。
assign inst_sll_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'he];
// 说明：逐字段核对操作码，识别当前指令是否为SRA.W 寄存器算术右移。
assign inst_sra_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
// 说明：逐字段核对操作码，识别当前指令是否为SRL.W 寄存器逻辑右移。
assign inst_srl_w = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0f];
// 说明：逐字段核对操作码，识别当前指令是否为BLT 有符号小于跳转。
assign inst_blt = op_31_26_d[6'h18];
// 说明：逐字段核对操作码，识别当前指令是否为BGE 有符号大于等于跳转。
assign inst_bge = op_31_26_d[6'h19];
// 说明：逐字段核对操作码，识别当前指令是否为BLTU 无符号小于跳转。
assign inst_bltu   = op_31_26_d[6'h1a];
// 说明：逐字段核对操作码，识别当前指令是否为BGEU 无符号大于等于跳转。
assign inst_bgeu   = op_31_26_d[6'h1b];
// 说明：逐字段核对操作码，识别当前指令是否为LD.B 有符号读字节。
assign inst_ld_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
// 说明：逐字段核对操作码，识别当前指令是否为LD.H 有符号读半字。
assign inst_ld_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
// 说明：逐字段核对操作码，识别当前指令是否为LD.BU 无符号读字节。
assign inst_ld_bu  = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
// 说明：逐字段核对操作码，识别当前指令是否为LD.HU 无符号读半字。
assign inst_ld_hu  = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
// 说明：逐字段核对操作码，识别当前指令是否为ST.B 写字节。
assign inst_st_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
// 说明：逐字段核对操作码，识别当前指令是否为ST.H 写半字。
assign inst_st_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h5];

// 说明：加法、地址计算和链接地址计算都使用 ALU 的加法功能。
assign alu_op[ 0] = inst_add_w | inst_addi_w | inst_ld_w | inst_ld_b | inst_st_w | inst_st_b | inst_st_h
                    // 说明：加载、跳转链接等其余需要加法的指令也归入同一控制位。
                    | inst_jirl | inst_bl | inst_pcaddu12i | inst_ld_h | inst_ld_bu | inst_ld_hu;
// 说明：遇到对应指令时，置位 ALU 的减法控制位。
assign alu_op[ 1] = inst_sub_w;
// 说明：遇到对应指令时，置位 ALU 的有符号小于比较控制位。
assign alu_op[ 2] = inst_slt | inst_slti;
// 说明：遇到对应指令时，置位 ALU 的无符号小于比较控制位。
assign alu_op[ 3] = inst_sltu | inst_sltui;
// 说明：遇到对应指令时，置位 ALU 的按位与控制位。
assign alu_op[ 4] = inst_and | inst_andi;
// 说明：遇到对应指令时，置位 ALU 的按位或非控制位。
assign alu_op[ 5] = inst_nor;
// 说明：遇到对应指令时，置位 ALU 的按位或控制位。
assign alu_op[ 6] = inst_or | inst_ori;
// 说明：遇到对应指令时，置位 ALU 的按位异或控制位。
assign alu_op[ 7] = inst_xor | inst_xori;
// 说明：遇到对应指令时，置位 ALU 的逻辑左移控制位。
assign alu_op[ 8] = inst_slli_w | inst_sll_w ;
// 说明：遇到对应指令时，置位 ALU 的逻辑右移控制位。
assign alu_op[ 9] = inst_srli_w | inst_srl_w;
// 说明：遇到对应指令时，置位 ALU 的算术右移控制位。
assign alu_op[10] = inst_srai_w | inst_sra_w ;
// 说明：遇到对应指令时，置位 ALU 的装入高位立即数控制位。
assign alu_op[11] = inst_lu12i_w;

//信号
// 说明：计算需要 5 位无符号移位量的标志，供后续数据通路或控制逻辑使用。
assign need_ui5  = inst_slli_w | inst_srli_w | inst_srai_w;
// 说明：计算需要 12 位零扩展立即数的标志，供后续数据通路或控制逻辑使用。
assign need_u12  = inst_andi | inst_ori | inst_xori;
// 说明：计算需要 12 位符号扩展立即数的标志，供后续数据通路或控制逻辑使用。
assign need_si12 = inst_addi_w | inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu | inst_st_w | inst_st_b | inst_st_h 
                                // 说明：把SLTI 有符号立即数比较、SLTUI 无符号立即数比较也归入当前运算或控制类别。
                                | inst_slti | inst_sltui ;
// 说明：计算需要 16 位分支偏移的标志，供后续数据通路或控制逻辑使用。
assign need_si16 = inst_jirl | inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu;
// 说明：计算需要 20 位高位立即数的标志，供后续数据通路或控制逻辑使用。
assign need_si20 = inst_lu12i_w | inst_pcaddu12i;
// 说明：计算需要 26 位分支偏移的标志，供后续数据通路或控制逻辑使用。
assign need_si26 = inst_b | inst_bl;
// 说明：计算ALU 第二输入需要常数 4 的标志，供后续数据通路或控制逻辑使用。
assign src2_is_4 = inst_jirl | inst_bl;

// 说明：JIRL 和 BL 需要把 PC 加 4，所以立即数优先选常数 4。
assign imm = src2_is_4 ? 32'h4
            // 说明：高位立即数类指令把 20 位字段放到结果高位，低 12 位补 0。
            : need_si20 ? {i20[19:0], 12'b0}
            // 说明：逻辑立即数指令把 12 位字段零扩展到 32 位。
            : need_u12 ? i12[11:0]
            // 说明：立即数移位指令直接使用 rk 位段作为 5 位移位量。
            : need_ui5 ? rk
            // 说明：其他 12 位立即数按最高位进行符号扩展。
            : {{20{i12[11]}}, i12[11:0]} ;

// 说明：B 和 BL 的 26 位偏移先符号扩展，再左移两位得到字节偏移。
assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
                            // 说明：其他分支的 16 位偏移同样符号扩展并左移两位。
                            {{14{i16[15]}}, i16[15:0], 2'b0} ;

// 说明：JIRL 的 16 位偏移符号扩展后左移两位。
assign jirl_offs = {{14{i16[15]}}, i16[15:0], 2'b0};

// 说明：分支比较和存储指令用 rd 位段作为第二个源寄存器编号。
assign src_reg_is_rd = inst_beq | inst_bne | inst_st_w | inst_st_b | inst_st_h | inst_blt | inst_bge | inst_bltu | inst_bgeu;
// 说明：JIRL、BL 和 PCADDU12I 让 ALU 第一个输入改取 PC。
assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

// 说明：立即数移位指令使用指令中的移位量，不读第二个寄存器值。
assign src2_is_imm   = inst_slli_w |
                       // 说明：SRLI.W 也从指令字段取得右移位数。
                       inst_srli_w |
                       // 说明：SRAI.W 也从指令字段取得算术右移位数。
                       inst_srai_w |
                       // 说明：ADDI.W 的第二个 ALU 输入来自立即数。
                       inst_addi_w |
                       // 说明：LD.W 用基址加立即数算出内存地址。
                       inst_ld_w   |
                       // 说明：LD.B 用基址加立即数算出字节地址。
                       inst_ld_b   |
                       // 说明：LD.H 用基址加立即数算出半字地址。
                       inst_ld_h   |
                       // 说明：LD.BU 同样用立即数参与地址计算。
                       inst_ld_bu   |
                       // 说明：LD.HU 同样用立即数参与地址计算。
                       inst_ld_hu   |
                       // 说明：ST.W 用立即数作为地址偏移。
                       inst_st_w   |
                       // 说明：ST.B 用立即数作为地址偏移。
                       inst_st_b   |
                       // 说明：ST.H 用立即数作为地址偏移。
                       inst_st_h   |
                       // 说明：LU12I.W 直接使用移到高位的立即数。
                       inst_lu12i_w|
                       // 说明：PCADDU12I 把高位立即数加到 PC 上。
                       inst_pcaddu12i |
                       // 说明：SLTI 把立即数作为比较的第二个操作数。
                       inst_slti   |
                       // 说明：SLTUI 把立即数作为无符号比较的第二个操作数。
                       inst_sltui   |
                       // 说明：ANDI 把零扩展立即数用于按位与。
                       inst_andi   |
                       // 说明：ORI 把零扩展立即数用于按位或。
                       inst_ori   |
                       // 说明：XORI 把零扩展立即数用于按位异或。
                       inst_xori   |
                       // 说明：JIRL 用立即数形式的常数 4 计算返回地址。
                       inst_jirl   |
                       // 说明：BL 也用常数 4 计算返回地址。
                       inst_bl     ;

// 说明：加载指令的写回值来自数据内存，而非 ALU 结果。
assign res_from_mem  = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;   //备战未来（？
// 说明：这些指令需要从数据内存读取。
assign load_op       = inst_ld_w | inst_ld_b | inst_ld_h | inst_ld_bu | inst_ld_hu;   //加载指令标志
// 说明：带符号的字节和半字加载需要符号扩展；字加载也置此标志。
assign load_signed = inst_ld_b | inst_ld_w | inst_ld_h ;
// 说明：LD.B 读取一个字节，所以访问宽度选 B。
assign mem_size = inst_ld_b ? `B :
                  // 说明：LD.W 读取一个整字，所以访问宽度选 W。
                  inst_ld_w ? `W :
                  // 说明：ST.W 写入一个整字，所以访问宽度选 W。
                  inst_st_w ? `W :
                  // 说明：ST.B 写入一个字节，所以访问宽度选 B。
                  inst_st_b ? `B :
                  // 说明：ST.H 写入一个半字，所以访问宽度选 H。
                  inst_st_h ? `H :
                  // 说明：LD.H 读取一个半字，所以访问宽度选 H。
                  inst_ld_h ? `H :
                  // 说明：LD.HU 同样只读取一个半字。
                  inst_ld_hu ? `H :
                  // 说明：LD.BU 同样只读取一个字节。
                  inst_ld_bu ? `B :
                  // 说明：不属于这些访存指令时，宽度编码默认清零。
                  0;
// 说明：BL 的目标寄存器固定为 r1，用来保存返回地址。
assign dst_is_r1     = inst_bl;
// 说明：存储和不写寄存器的分支关闭写使能，其余指令允许写通用寄存器。
assign gr_we         = ~inst_st_w & ~inst_st_b & ~inst_st_h & ~inst_beq & ~inst_bne & ~inst_b & ~inst_blt & ~inst_bge & ~inst_bltu & ~inst_bgeu;
// 说明：只有存储指令向数据内存发出写请求。
assign mem_we        = inst_st_w | inst_st_b | inst_st_h;
// 说明：BL 写入 r1，其他写寄存器的指令使用 rd 字段。
assign dest          = dst_is_r1 ? 5'd1 : rd;

// 说明：寄存器堆第一个读口始终按 rj 字段取数。
assign rf_raddr1 = rj;
// 说明：分支和存储读 rd 字段，其余双源指令读 rk 字段。
assign rf_raddr2 = src_reg_is_rd ? rd :rk;

// 说明：声明寄存器堆实际写使能，供本模块连接或计算。
wire rf_we ; //写使能
// 说明：声明寄存器堆写地址，供本模块连接或计算。
wire [4:0] rf_waddr;
// 说明：声明寄存器堆写数据，供本模块连接或计算。
wire [31:0] rf_wdata;

// 说明：写回级有效且未复位时，允许更新寄存器堆。
assign rf_we = !reset && ws_to_rf_bus[37];
// 说明：从写回总线取出要写的寄存器编号。
assign rf_waddr = ws_to_rf_bus[36:32];
// 说明：从写回总线取出要写入的 32 位数据。
assign rf_wdata = ws_to_rf_bus[31:0];

// 说明：实例化 32 个通用寄存器的读写模块。
regfile u_regfile(
    // 说明：把时钟信号接到子模块的对应端口。
    .clk    (clk    ),
    // 说明：把第一个读寄存器编号接到子模块的对应端口。
    .raddr1 (rf_raddr1),
    // 说明：把第一个读寄存器值接到子模块的对应端口。
    .rdata1 (rf_rdata1),
    // 说明：把第二个读寄存器编号接到子模块的对应端口。
    .raddr2 (rf_raddr2),
    // 说明：把第二个读寄存器值接到子模块的对应端口。
    .rdata2 (rf_rdata2),
    // 说明：把寄存器堆写使能接到子模块的对应端口。
    .we     (rf_we    ),
    // 说明：把写寄存器编号接到子模块的对应端口。
    .waddr  (rf_waddr ),
    // 说明：把写寄存器数据接到子模块的对应端口。
    .wdata  (rf_wdata )
// 说明：结束模块端口列表或子模块端口连接。
);

//冲突信号
// 说明：执行级即将写的寄存器与 rj 相同，且 rj 不是零寄存器时命中。
wire es_match_rj = es_dest[37] && (es_dest[36:32] == rf_raddr1) && (rf_raddr1 != 5'd0);
// 说明：执行级即将写的寄存器与第二源寄存器相同时命中。
wire es_match_rkd = es_dest[37] && (es_dest[36:32] == rf_raddr2) && (rf_raddr2 != 5'd0);
// 说明：访存级即将写的寄存器与 rj 相同时命中。
wire ms_match_rj = ms_dest[37] && (ms_dest[36:32] == rf_raddr1) && (rf_raddr1 != 5'd0);
// 说明：访存级即将写的寄存器与第二源寄存器相同时命中。
wire ms_match_rkd = ms_dest[37] && (ms_dest[36:32] == rf_raddr2) && (rf_raddr2 != 5'd0);
// 说明：写回级目标寄存器与 rj 相同时命中。
wire ws_match_rj = ws_to_rf_bus[37] && (ws_to_rf_bus[36:32] == rf_raddr1) && (rf_raddr1 != 5'd0);
// 说明：写回级目标寄存器与第二源寄存器相同时命中。
wire ws_match_rkd = ws_to_rf_bus[37] && (ws_to_rf_bus[36:32] == rf_raddr2) && (rf_raddr2 != 5'd0);

// 说明：优先从执行级前递尚未写回的 rj 值，但加载结果此时不可用。
assign rj_value = (es_match_rj && !es_dest[38]) ? es_dest[31:0] :
                  // 说明：执行级不能前递时，尝试从访存级前递 rj 值。
                  (ms_match_rj && !ms_dest[38]) ? ms_dest[31:0] :
                  // 说明：再尝试写回级前递；都不匹配才读取寄存器堆。
                  ws_match_rj ? ws_to_rf_bus[31:0] : rf_rdata1;
// 说明：第二源操作数也优先使用执行级前递的值。
assign rkd_value = (es_match_rkd && !es_dest[38]) ? es_dest[31:0] :
                   // 说明：执行级无可用值时，尝试访存级前递。
                   (ms_match_rkd && !ms_dest[38]) ? ms_dest[31:0] :
                   // 说明：再尝试写回级前递，最后才读寄存器堆第二读口。
                   ws_match_rkd ? ws_to_rf_bus[31:0] : rf_rdata2;

// 说明：比较两个源操作数是否相等，供 BEQ 和 BNE 使用。
assign rj_eq_rd = (rj_value == rkd_value);
// 说明：把两个源值当作有符号数比较，供 BLT 和 BGE 使用。
assign rj_lt_rd = ($signed(rj_value) < $signed(rkd_value));
// 说明：把两个源值当作无符号数比较，供 BLTU 和 BGEU 使用。
assign rj_ltu_rd = ($unsigned(rj_value) < $unsigned(rkd_value));
// 说明：BEQ 在两个寄存器相等时请求跳转。
assign br_taken = (  inst_beq  &&  rj_eq_rd
                  // 说明：BNE 在两个寄存器不相等时请求跳转。
                  || inst_bne  && !rj_eq_rd
                  // 说明：BLT 在有符号比较结果为小于时请求跳转。
                  || inst_blt  &&  rj_lt_rd
                  // 说明：BGE 在有符号比较结果为大于等于时请求跳转。
                  || inst_bge  && !rj_lt_rd
                  // 说明：BLTU 在无符号比较结果为小于时请求跳转。
                  || inst_bltu &&  rj_ltu_rd
                  // 说明：BGEU 在无符号比较结果为大于等于时请求跳转。
                  || inst_bgeu && !rj_ltu_rd
                  // 说明：JIRL 无条件按寄存器和偏移量跳转。
                  || inst_jirl
                  // 说明：BL 无条件跳转并留下返回地址。
                  || inst_bl
                  // 说明：B 无条件跳转。
                  || inst_b
                  // 说明：只有译码级有效且未因数据相关停顿时，才真正发出跳转。
                  ) && ds_valid && ds_ready_go;
// 说明：普通分支按当前 PC 加偏移计算目标地址。
assign br_target = (inst_beq || inst_bne || inst_blt || inst_bl || inst_b || inst_bge || inst_bltu || inst_bgeu) ? (ds_pc + br_offs) :
                                                   // 说明：JIRL 则按 rj 的值加偏移计算目标地址。
                                                   /*inst_jirl*/ (rj_value + jirl_offs);

// 说明：把跳转标志和目标地址一起送回取指级。
assign br_bus = {br_taken , br_target};

// 说明：保存从取指级收到的指令字和 PC。
reg [`FS_TO_DS_BUS_WD -1 :0] fs_to_ds_bus_r;
// 说明：开始把取指总线拆成当前指令和当前 PC。
assign {ds_inst,
        // 说明：PC 取自取指总线低 32 位。
        ds_pc} = fs_to_ds_bus_r;

/*assign {rf_we, //37:37
        rf_waddr, //36:32
        rf_wdata //31:0
       } = ws_to_rf_bus;*/

// ds_to_es_bus 总位宽 = 1+2+12+1+1+1+1+1+1+5+32+32+32+32+1 = 155 bit
// 说明：开始按约定顺序打包译码结果，供执行级使用。
assign ds_to_es_bus = {
                        // 说明：把加载结果需要符号扩展的标志放入当前总线字段或选择条件。
                        load_signed,  //[154]     1  bit
                        // 说明：把本次访存的数据宽度编码放入当前总线字段或选择条件。
                        mem_size     ,  //[153:152] 2  bit
                        // 说明：把ALU 运算选择位放入当前总线字段或选择条件。
                        alu_op       ,  //[151:140] 12 bit
                        // 说明：把当前指令是加载指令的标志放入当前总线字段或选择条件。
                        load_op      ,  //[139]      1 bit
                        // 说明：把ALU 第一输入选择 PC 的标志放入当前总线字段或选择条件。
                        src1_is_pc   ,  //[138]      1 bit
                        // 说明：把ALU 第二输入选择立即数的标志放入当前总线字段或选择条件。
                        src2_is_imm  ,  //[137]      1 bit
                        // 说明：把ALU 第二输入需要常数 4 的标志放入当前总线字段或选择条件。
                        src2_is_4    ,  //[136]      1 bit
                        // 说明：把通用寄存器写使能放入当前总线字段或选择条件。
                        gr_we        ,  //[135]      1 bit
                        // 说明：把数据内存写使能标志放入当前总线字段或选择条件。
                        mem_we       ,  //[134]      1 bit
                        // 说明：把最终要写的寄存器编号放入当前总线字段或选择条件。
                        dest         ,  //[133:129]  5 bit
                        // 说明：把扩展成 32 位的立即数放入当前总线字段或选择条件。
                        imm          ,  //[128: 97] 32 bit
                        // 说明：把经过前递选择的 rj 值放入当前总线字段或选择条件。
                        rj_value     ,  //[ 96: 65] 32 bit
                        // 说明：把经过前递选择的第二源寄存器值放入当前总线字段或选择条件。
                        rkd_value    ,  //[ 64: 33] 32 bit
                        // 说明：把当前指令的 PC放入当前总线字段或选择条件。
                        ds_pc        ,  //[ 32:  1] 32 bit
                        // 说明：把写回数据来自内存的标志放入当前总线字段或选择条件。
                        res_from_mem    //[  0]      1 bit
                      // 说明：完成译码到执行总线的字段拼接。
                      };

// 说明：执行级若是加载指令，且目标命中当前源寄存器，就必须等待数据。
wire es_load_hazard = es_dest[38] && (es_match_rj || es_match_rkd);
// 说明：访存级若是加载指令，且目标命中当前源寄存器，也必须等待数据。
wire ms_load_hazard = ms_dest[38] && (ms_match_rj || ms_match_rkd);
// 说明：任一前级存在尚不可用的加载结果时，译码级需要停顿。
wire load_data_hazard = es_load_hazard || ms_load_hazard;
// 说明：复位时允许清空流水级；正常运行时只有无加载相关才能继续。
assign ds_ready_go = reset || !load_data_hazard;
// 是否是写指令，且是否寄存器值相等
// 说明：译码级空闲，或本条可完成且执行级可接收时，允许新指令进入。
assign ds_allowin      = !ds_valid || ds_ready_go && es_allowin;
// 说明：只有译码级持有有效指令且准备好时，才向执行级送出有效标志。
assign ds_to_es_valid  = ds_valid && ds_ready_go;
// 说明：在时钟上升沿更新本级保存的有效位和数据。
always @(posedge clk) begin
    // 说明：复位有效时清空本级状态，使旧指令不再有效。
    if (reset) begin
        // 说明：更新译码级有效位，控制该级数据是否被下游采纳。
        ds_valid <= 1'b0;
    // 说明：结束当前条件分支或时序代码块。
    end
    // 说明：只有括号里的条件成立，才执行这一分支的状态更新。
    else if (ds_allowin) begin
        // 说明：更新译码级有效位，控制该级数据是否被下游采纳。
        ds_valid <= fs_to_ds_valid;
    // 说明：结束当前条件分支或时序代码块。
    end

    // 说明：检查括号里的握手或控制条件，决定是否更新寄存器。
    if (fs_to_ds_valid && ds_allowin) begin
        // 说明：上游有有效指令且本级可接收时，锁存指令和 PC。
        fs_to_ds_bus_r <= fs_to_ds_bus;
    // 说明：结束当前条件分支或时序代码块。
    end
// 说明：结束当前条件分支或时序代码块。
end

// 说明：结束译码阶段模块定义。
endmodule