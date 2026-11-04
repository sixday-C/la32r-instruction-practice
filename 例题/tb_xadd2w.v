`timescale 1ns / 1ps
`include "mycpu_defines.vh"

// Directed ID -> EX test. Keep this file outside myCPU for exam submission.
module tb_xadd2w;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg reset = 1'b1;
    reg fs_to_ds_valid = 1'b0;
    reg [`FS_TO_DS_BUS_WD-1:0] fs_to_ds_bus = 0;
    reg [`WS_TO_RF_BUS_WD-1:0] ws_to_rf_bus = 0;

    wire ds_allowin;
    wire ds_to_es_valid;
    wire [`DS_TO_ES_BUS_WD-1:0] ds_to_es_bus;
    wire [`BR_BUS_WD-1:0] br_bus;
    wire es_allowin;
    wire es_to_ms_valid;
    wire [`ES_TO_MS_BUS_WD-1:0] es_to_ms_bus;

    ID_stage u_id (
        .clk(clk), .reset(reset), .es_allowin(es_allowin),
        .ds_allowin(ds_allowin), .fs_to_ds_valid(fs_to_ds_valid),
        .fs_to_ds_bus(fs_to_ds_bus), .ds_to_es_valid(ds_to_es_valid),
        .ds_to_es_bus(ds_to_es_bus), .br_bus(br_bus),
        .ws_to_rf_bus(ws_to_rf_bus), .es_to_ms_bus(108'b0),
        .es_dest(39'b0), .ms_dest(39'b0)
    );

    EX_stage u_ex (
        .clk(clk), .reset(reset), .ms_allowin(1'b1),
        .es_allowin(es_allowin), .ds_to_es_valid(ds_to_es_valid),
        .ds_to_es_bus(ds_to_es_bus), .es_to_ms_valid(es_to_ms_valid),
        .es_to_ms_bus(es_to_ms_bus)
    );

    function [31:0] xadd2w_inst;
        input [4:0] rd, rj, rk;
        begin
            xadd2w_inst = {6'h3f, 4'h0, 2'h0, 5'h01, rk, rj, rd};
        end
    endfunction

    function [31:0] and_inst;
        input [4:0] rd, rj, rk;
        begin
            and_inst = {6'h00, 4'h0, 2'h1, 5'h09, rk, rj, rd};
        end
    endfunction

    task write_reg;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            ws_to_rf_bus = {1'b0, 1'b1, addr, data};
            @(negedge clk);
            ws_to_rf_bus = 0;
        end
    endtask

    integer passed = 0;
    integer failed = 0;

    task run_case;
        input [127:0] label;
        input [31:0] instruction;
        input [4:0] expected_rd;
        input [31:0] expected_data;
        begin
            @(negedge clk);
            fs_to_ds_valid = 1'b1;
            fs_to_ds_bus = {instruction, 32'h1c000000};
            @(negedge clk);
            fs_to_ds_valid = 1'b0;
            @(posedge clk);
            #1;
            if (es_to_ms_valid !== 1'b1 ||
                es_to_ms_bus[104] !== 1'b1 ||
                es_to_ms_bus[103:99] !== expected_rd ||
                es_to_ms_bus[63:32] !== expected_data) begin
                failed = failed + 1;
                $display("FAIL %-16s valid=%b we=%b rd=%0d data=%08h expected=%08h",
                         label, es_to_ms_valid, es_to_ms_bus[104],
                         es_to_ms_bus[103:99], es_to_ms_bus[63:32], expected_data);
            end else begin
                passed = passed + 1;
                $display("PASS %-16s rd=%0d data=%08h",
                         label, expected_rd, expected_data);
            end
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        reset = 1'b0;

        write_reg(5'd1, 32'h00000003);
        write_reg(5'd2, 32'h00000005);
        run_case("T01-basic", xadd2w_inst(5'd3, 5'd1, 5'd2), 5'd3, 32'h0000000d);

        write_reg(5'd1, 32'hffffffff);
        write_reg(5'd2, 32'h00000001);
        run_case("T02-wrap", xadd2w_inst(5'd3, 5'd1, 5'd2), 5'd3, 32'h00000001);

        write_reg(5'd2, 32'h80000000);
        run_case("T03-top-bit", xadd2w_inst(5'd3, 5'd0, 5'd2), 5'd3, 32'h00000000);

        write_reg(5'd1, 32'h12345678);
        write_reg(5'd2, 32'h00000000);
        run_case("T04-rk-zero", xadd2w_inst(5'd3, 5'd1, 5'd2), 5'd3, 32'h12345678);

        write_reg(5'd1, 32'h00000001);
        write_reg(5'd2, 32'hffffffff);
        run_case("T05-rk-all1", xadd2w_inst(5'd3, 5'd1, 5'd2), 5'd3, 32'hffffffff);

        write_reg(5'd1, 32'hf0f0f0f0);
        write_reg(5'd2, 32'h0ff00ff0);
        run_case("T06-and", and_inst(5'd3, 5'd1, 5'd2), 5'd3, 32'h00f000f0);

        $display("SUMMARY passed=%0d failed=%0d", passed, failed);
        if (failed != 0) $fatal(1, "Directed tests failed");
        $finish;
    end
endmodule
