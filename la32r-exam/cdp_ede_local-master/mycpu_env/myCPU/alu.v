// alu
// 说明：定义算术逻辑单元模块及其对外接口。
module alu(
  // 说明：作为输入端口接收ALU 运算选择位。
  input  wire [11:0] alu_op,
  // 说明：作为输入端口接收ALU 第一个输入数。
  input  wire [31:0] alu_src1,
  // 说明：作为输入端口接收ALU 第二个输入数。
  input  wire [31:0] alu_src2,
  // 说明：作为输出端口送出ALU 最终输出结果。
  output wire [31:0] alu_result
// 说明：结束模块端口列表或子模块端口连接。
);

// 说明：声明加法选择信号，供本模块连接或计算。
wire op_add;   //add operation
// 说明：声明减法选择信号，供本模块连接或计算。
wire op_sub;   //sub operation
// 说明：声明有符号小于比较选择信号，供本模块连接或计算。
wire op_slt;   //signed compared and set less than
// 说明：声明无符号小于比较选择信号，供本模块连接或计算。
wire op_sltu;  //unsigned compared and set less than
// 说明：声明按位与选择信号，供本模块连接或计算。
wire op_and;   //bitwise and
// 说明：声明按位或非选择信号，供本模块连接或计算。
wire op_nor;   //bitwise nor
// 说明：声明按位或选择信号，供本模块连接或计算。
wire op_or;    //bitwise or
// 说明：声明按位异或选择信号，供本模块连接或计算。
wire op_xor;   //bitwise xor
// 说明：声明逻辑左移选择信号，供本模块连接或计算。
wire op_sll;   //logic left shift
// 说明：声明逻辑右移选择信号，供本模块连接或计算。
wire op_srl;   //logic right shift
// 说明：声明算术右移选择信号，供本模块连接或计算。
wire op_sra;   //arithmetic right shift
// 说明：声明高位立即数装入选择信号，供本模块连接或计算。
wire op_lui;   //Load Upper Immediate

// control code decomposition
// 说明：把 ALU 控制字第 0 位解释为加法选择信号。
assign op_add  = alu_op[ 0];
// 说明：把 ALU 控制字第 1 位解释为减法选择信号。
assign op_sub  = alu_op[ 1];
// 说明：把 ALU 控制字第 2 位解释为有符号小于比较选择信号。
assign op_slt  = alu_op[ 2];
// 说明：把 ALU 控制字第 3 位解释为无符号小于比较选择信号。
assign op_sltu = alu_op[ 3];
// 说明：把 ALU 控制字第 4 位解释为按位与选择信号。
assign op_and  = alu_op[ 4];
// 说明：把 ALU 控制字第 5 位解释为按位或非选择信号。
assign op_nor  = alu_op[ 5];
// 说明：把 ALU 控制字第 6 位解释为按位或选择信号。
assign op_or   = alu_op[ 6];
// 说明：把 ALU 控制字第 7 位解释为按位异或选择信号。
assign op_xor  = alu_op[ 7];
// 说明：把 ALU 控制字第 8 位解释为逻辑左移选择信号。
assign op_sll  = alu_op[ 8];
// 说明：把 ALU 控制字第 9 位解释为逻辑右移选择信号。
assign op_srl  = alu_op[ 9];
// 说明：把 ALU 控制字第 10 位解释为算术右移选择信号。
assign op_sra  = alu_op[10];
// 说明：把 ALU 控制字第 11 位解释为高位立即数装入选择信号。
assign op_lui  = alu_op[11];

// 说明：声明加法或减法结果，供本模块连接或计算。
wire [31:0] add_sub_result;
// 说明：声明有符号小于比较结果，供本模块连接或计算。
wire [31:0] slt_result;
// 说明：声明无符号小于比较结果，供本模块连接或计算。
wire [31:0] sltu_result;
// 说明：声明按位与结果，供本模块连接或计算。
wire [31:0] and_result;
// 说明：声明按位或非结果，供本模块连接或计算。
wire [31:0] nor_result;
// 说明：声明按位或结果，供本模块连接或计算。
wire [31:0] or_result;
// 说明：声明按位异或结果，供本模块连接或计算。
wire [31:0] xor_result;
// 说明：声明装入高位立即数的结果，供本模块连接或计算。
wire [31:0] lui_result;
// 说明：声明逻辑左移结果，供本模块连接或计算。
wire [31:0] sll_result;
// 说明：声明带符号扩展的 64 位右移中间值，供本模块连接或计算。
wire [63:0] sr64_result;
// 说明：声明右移后的低 32 位结果，供本模块连接或计算。
wire [31:0] sr_result;


// 32-bit adder
// 说明：声明加减法器第一个加数，供本模块连接或计算。
wire [31:0] adder_a;
// 说明：声明加减法器第二个加数，供本模块连接或计算。
wire [31:0] adder_b;
// 说明：声明加减法器的进位输入，供本模块连接或计算。
wire        adder_cin;
// 说明：声明加减法器的低 32 位结果，供本模块连接或计算。
wire [31:0] adder_result;
// 说明：声明加减法器的最高位进位，供本模块连接或计算。
wire        adder_cout;

// 说明：加减法器左输入始终取第一个 ALU 操作数。
assign adder_a   = alu_src1;
// 说明：减法和两种小于比较要对第二操作数逐位取反；其他运算直接使用原值。
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk
// 说明：减法使用 A 加上 B 的反码再加 1，完成二进制补码减法。
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
// 说明：把两个加数和进位输入相加，同时得到 32 位结果与最高位进位。
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
// 说明：加法或减法直接采用共享加减法器算出的低 32 位。
assign add_sub_result = adder_result;

// SLT result
// 说明：小于比较的结果只有最低位可能为 1，其余 31 位全部清零。
assign slt_result[31:1] = 31'b0;   //rj < rk 1
// 说明：如果两数符号不同，直接用符号位判断第一个数是否更小。
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        // 说明：如果两数符号相同，再看相减结果的符号位完成有符号比较。
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
// 说明：无符号小于比较同样只把真假结果放在最低位。
assign sltu_result[31:1] = 31'b0;
// 说明：无符号相减若没有最高位进位，说明发生借位，即第一个数小于第二个数。
assign sltu_result[0]    = ~adder_cout; //是否发生借位

// bitwise operation
// 说明：两个输入逐位相与：只有两位都为 1，结果位才为 1。
assign and_result = alu_src1 & alu_src2;
// 说明：两个输入逐位相或：至少有一位为 1，结果位就是 1。
assign or_result  = alu_src1 | alu_src2;
// 说明：把按位或的结果逐位取反，得到 NOR 结果。
assign nor_result = ~or_result;
// 说明：两个输入逐位异或：两位不同时结果位为 1。
assign xor_result = alu_src1 ^ alu_src2;
// 说明：装入高位立即数时，立即数已经由译码级放在第二输入，直接输出它。
assign lui_result = alu_src2;

// SLL result
// 说明：把第一个输入逻辑左移第二输入低 5 位指定的位数，移出的高位丢弃。
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << ui5

// SRL, SRA result
// 说明：算术右移时在左边复制符号位；逻辑右移时补 0，再按低 5 位移位。
assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; //rj >> ui5

// 说明：从 64 位右移中间值取低 32 位，作为最终右移结果。
assign sr_result   = sr64_result[31:0];

// final result mux
// 说明：开始按运算选择位合并结果；加法或减法有效时保留加减结果。
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  // 说明：选择有符号小于比较的结果。
                  | ({32{op_slt       }} & slt_result)
                  // 说明：选择无符号小于比较的结果。
                  | ({32{op_sltu      }} & sltu_result)
                  // 说明：选择按位与的结果。
                  | ({32{op_and       }} & and_result)
                  // 说明：选择按位或非的结果。
                  | ({32{op_nor       }} & nor_result)
                  // 说明：选择按位或的结果。
                  | ({32{op_or        }} & or_result)
                  // 说明：选择按位异或的结果。
                  | ({32{op_xor       }} & xor_result)
                  // 说明：选择装入高位立即数的结果。
                  | ({32{op_lui       }} & lui_result)
                  // 说明：选择逻辑左移的结果。
                  | ({32{op_sll       }} & sll_result)
                  // 说明：选择逻辑右移或算术右移的结果，并完成结果合并。
                  | ({32{op_srl|op_sra}} & sr_result);

// 说明：结束算术逻辑单元模块定义。
endmodule
