// 库
// 说明：定义把 2 位输入转成 4 路一位有效输出的译码器。
module decoder_2_4(
    // 说明：作为输入端口接收译码器输入值。
    input  wire [ 1:0] in,
    // 说明：作为输出端口送出一位有效的译码器输出。
    output wire [ 3:0] out
// 说明：结束模块端口列表或子模块端口连接。
);

// 说明：声明生成循环使用的编译期下标。
genvar i;
// 说明：在编译时展开4路独立的译码比较电路。
generate for (i=0; i<4; i=i+1) begin : gen_for_dec_2_4
    // 说明：输入等于当前循环编号时，只把对应输出位置为 1。
    assign out[i] = (in == i);
// 说明：结束一位有效译码器的循环生成。
end endgenerate

// 说明：结束译码工具模块定义。
endmodule


// 说明：定义把 4 位输入转成 16 路一位有效输出的译码器。
module decoder_4_16(
    // 说明：作为输入端口接收译码器输入值。
    input  wire [ 3:0] in,
    // 说明：作为输出端口送出一位有效的译码器输出。
    output wire [15:0] out
// 说明：结束模块端口列表或子模块端口连接。
);

// 说明：声明生成循环使用的编译期下标。
genvar i;
// 说明：在编译时展开16路独立的译码比较电路。
generate for (i=0; i<16; i=i+1) begin : gen_for_dec_4_16
    // 说明：输入等于当前循环编号时，只把对应输出位置为 1。
    assign out[i] = (in == i);
// 说明：结束一位有效译码器的循环生成。
end endgenerate

// 说明：结束译码工具模块定义。
endmodule


// 说明：定义把 5 位输入转成 32 路一位有效输出的译码器。
module decoder_5_32(
    // 说明：作为输入端口接收译码器输入值。
    input  wire [ 4:0] in,
    // 说明：作为输出端口送出一位有效的译码器输出。
    output wire [31:0] out
// 说明：结束模块端口列表或子模块端口连接。
);

// 说明：声明生成循环使用的编译期下标。
genvar i;
// 说明：在编译时展开32路独立的译码比较电路。
generate for (i=0; i<32; i=i+1) begin : gen_for_dec_5_32
    // 说明：输入等于当前循环编号时，只把对应输出位置为 1。
    assign out[i] = (in == i);
// 说明：结束一位有效译码器的循环生成。
end endgenerate

// 说明：结束译码工具模块定义。
endmodule


// 说明：定义把 6 位输入转成 64 路一位有效输出的译码器。
module decoder_6_64(
    // 说明：作为输入端口接收译码器输入值。
    input  wire [ 5:0] in,
    // 说明：作为输出端口送出一位有效的译码器输出。
    output wire [63:0] out
// 说明：结束模块端口列表或子模块端口连接。
);

// 说明：声明生成循环使用的编译期下标。
genvar i;
// 说明：在编译时展开64路独立的译码比较电路。
generate for (i=0; i<64; i=i+1) begin : gen_for_dec_6_64
    // 说明：输入等于当前循环编号时，只把对应输出位置为 1。
    assign out[i] = (in == i);
// 说明：结束一位有效译码器的循环生成。
end endgenerate

// 说明：结束译码工具模块定义。
endmodule
