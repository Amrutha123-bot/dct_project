// Testbench for dct2d_top (full 8x8 2-D DCT).
// Input blocks  : vectors/in_N.hex    (made by octave/gen_vectors.m)
// Golden results: vectors/gold_N.hex  (rounded double-precision DCT)
// Outputs       : sim/out_N.txt       (read by octave/compare_results.m)
// Pass criterion here: every coefficient within +/-1 of the rounded golden value.
`timescale 1ns/1ps
module tb_dct2d_top;
    localparam NBLOCKS = 8;

    reg         clk = 0;
    reg         rst_n;
    reg         in_valid;
    reg  [63:0] in_row;
    wire        in_ready;
    wire        out_valid, out_last;
    wire [2:0]  out_idx;
    wire [95:0] out_col;

    dct2d_top dut (.clk(clk), .rst_n(rst_n), .in_valid(in_valid), .in_row(in_row),
                   .in_ready(in_ready), .out_valid(out_valid), .out_idx(out_idx),
                   .out_last(out_last), .out_col(out_col));

    always #5 clk = ~clk;                      // 100 MHz clock

    reg [7:0]  in_mem   [0:63];
    reg [11:0] gold_mem [0:63];
    integer    result   [0:63];
    reg [8*40-1:0] fname;
    integer b, r, c, u, v, got, diff, cols_seen, timeout;
    integer total_errors, blk_errors, fd;
    integer protocol_errors, expected_idx;
    initial begin
        $dumpfile("sim/dct2d.vcd");
        $dumpvars(0, tb_dct2d_top);
        total_errors = 0;
        protocol_errors = 0;
        rst_n = 0; in_valid = 0; in_row = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;
        @(negedge clk);

        for (b = 0; b < NBLOCKS; b = b + 1) begin
            $sformat(fname, "vectors/in_%0d.hex", b);   $readmemh(fname, in_mem);
            $sformat(fname, "vectors/gold_%0d.hex", b); $readmemh(fname, gold_mem);

            // ---- drive 8 rows, one per clock --------------------------------
            for (r = 0; r < 8; r = r + 1) begin
                for (c = 0; c < 8; c = c + 1) in_row[c*8 +: 8] = in_mem[r*8 + c];
                in_valid = 1;
                @(negedge clk);
            end
            in_valid = 0; in_row = 0;

            // ---- collect 8 output columns -----------------------------------
            cols_seen = 0; timeout = 0;
            while (cols_seen < 8 && timeout < 50) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
                if (out_valid) begin

                    // Check output column ordering
                    if (out_idx != cols_seen) begin
                        $display("ERROR: Wrong output index. Expected %0d, got %0d",
                                cols_seen, out_idx);
                        protocol_errors = protocol_errors + 1;
                    end

                    // Check final-column signal
                    if (out_last !== (out_idx == 3'd7)) begin
                        $display("ERROR: Incorrect out_last at index %0d", out_idx);
                        protocol_errors = protocol_errors + 1;
                    end

                    // Check in_ready on non-final output columns
                    if (out_idx != 3'd7 && in_ready !== 1'b0) begin
                        $display("ERROR: in_ready asserted during output");
                        protocol_errors = protocol_errors + 1;
                    end

                    for (u = 0; u < 8; u = u + 1)
                        result[u*8 + out_idx] = $signed(out_col[u*12 +: 12]);

                    cols_seen = cols_seen + 1;
                end
            end
            @(negedge clk);

            // ---- compare + print + save -------------------------------------
            blk_errors = 0;
            $sformat(fname, "sim/out_%0d.txt", b);
            fd = $fopen(fname, "w");
            $display("=== block %0d : output F[u][v] (rows u, columns v)", b);
            for (u = 0; u < 8; u = u + 1) begin
                for (v = 0; v < 8; v = v + 1) begin
                    got  = result[u*8 + v];
                    diff = got - $signed(gold_mem[u*8 + v]);
                    if (diff < -1 || diff > 1) blk_errors = blk_errors + 1;
                    $write("%6d", got);
                    $fwrite(fd, "%d ", got);
                end
                $write("\n");
                $fwrite(fd, "\n");
            end
            $fclose(fd);
            if (cols_seen != 8) blk_errors = blk_errors + 100;   // missing outputs
            $display("    block %0d: %0s (%0d coefficients off by more than 1)\n",
                     b, (blk_errors == 0) ? "PASS" : "FAIL", blk_errors);
            total_errors = total_errors + blk_errors;
        end

        if (total_errors == 0 && protocol_errors == 0)
            $display("TB_DCT2D: PASS (all %0d blocks, protocol checks passed)", NBLOCKS);
        else
            $display("TB_DCT2D: FAIL. Numerical errors=%0d, Protocol errors=%0d",
                    total_errors, protocol_errors);
        $finish;
    end
endmodule
