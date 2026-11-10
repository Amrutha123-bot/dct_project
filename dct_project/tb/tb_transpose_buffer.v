// Testbench for transpose_buffer: write rows, read columns.
// Element [r][c] is loaded with the value r*8+c, so column c must read back
// c, 8+c, 16+c, ... 56+c.
`timescale 1ns/1ps
module tb_transpose_buffer;
    reg         clk = 0;
    reg         wr_en;
    reg  [2:0]  wr_row, rd_col;
    reg  [127:0] wr_data;
    wire [127:0] rd_data;
    integer r, c, errors;

    transpose_buffer #(.W(16)) dut (
        .clk(clk), .wr_en(wr_en), .wr_row(wr_row), .wr_data(wr_data),
        .rd_col(rd_col), .rd_data(rd_data));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/tbuf.vcd");
        $dumpvars(0, tb_transpose_buffer);
        errors = 0; wr_en = 0; wr_row = 0; rd_col = 0; wr_data = 0;
        @(negedge clk);
        for (r = 0; r < 8; r = r + 1) begin
            wr_en = 1; wr_row = r;
            for (c = 0; c < 8; c = c + 1) wr_data[c*16 +: 16] = r*8 + c;
            @(negedge clk);
        end
        wr_en = 0;
        for (c = 0; c < 8; c = c + 1) begin
            rd_col = c; #1;
            $write("column %0d reads:", c);
            for (r = 0; r < 8; r = r + 1) begin
                $write(" %0d", rd_data[r*16 +: 16]);
                if (rd_data[r*16 +: 16] !== r*8 + c) errors = errors + 1;
            end
            $write("\n");
        end
        if (errors == 0) $display("TB_TRANSPOSE: PASS");
        else             $display("TB_TRANSPOSE: FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
