// 说明：检查头文件保护标记，避免重复包含。
`ifndef MYCPU_DEFINES_VH
// 说明：设置头文件保护标记。
`define MYCPU_DEFINES_VH

    // 说明：规定 BR_BUS_WD 这条流水总线的位宽为 33 位。
    `define BR_BUS_WD       33
    // 说明：规定 FS_TO_DS_BUS_WD 这条流水总线的位宽为 64 位。
    `define FS_TO_DS_BUS_WD 64
    // 说明：规定 DS_TO_ES_BUS_WD 这条流水总线的位宽为 155 位。
    `define DS_TO_ES_BUS_WD 155
    // 说明：规定 ES_TO_MS_BUS_WD 这条流水总线的位宽为 108 位。
    `define ES_TO_MS_BUS_WD 108
    // 说明：规定 MS_TO_WS_BUS_WD 这条流水总线的位宽为 77 位。
    `define MS_TO_WS_BUS_WD 77
    // 说明：规定 WS_TO_RF_BUS_WD 这条流水总线的位宽为 39 位。
    `define WS_TO_RF_BUS_WD 39


    // 说明：把字节访问约定为编码 2'b01。
    `define B 2'b01
    // 说明：把半字访问约定为编码 2'b10。
    `define H 2'b10
    // 说明：把整字访问约定为编码 2'b11。
    `define W 2'b11
// 说明：结束头文件保护范围。
`endif