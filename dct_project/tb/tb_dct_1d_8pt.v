// Testbench for dct_1d_8pt  (integer mode: 8-bit in, SHIFT=14, 12-bit out)
// Expected values were computed independently with scipy.fft.dct(norm='ortho')
// and rounded to the nearest integer. Allowed error: +/-1 (one LSB).
`timescale 1ns/1ps
module tb_dct_1d_8pt;
    reg  [63:0] xf;
    wire [95:0] yf;
    reg  signed [7:0] xin [0:7];
    integer      expv [0:7];
    integer      errors, i, got, diff;

    dct_1d_8pt #(.IN_W(8), .OUT_W(12), .SHIFT(14)) dut (.x_flat(xf), .y_flat(yf));

    task run_case;
        input [8*20-1:0] name;
        begin
            for (i = 0; i < 8; i = i + 1) xf[i*8 +: 8] = xin[i];
            #1;
            $display("--- %0s", name);
            for (i = 0; i < 8; i = i + 1) begin
                got  = $signed(yf[i*12 +: 12]);
                diff = got - expv[i];
                $display("  y[%0d] = %5d   expected %5d   %0s", i, got, expv[i],
                         (diff >= -1 && diff <= 1) ? "ok" : "<-- MISMATCH");
                if (diff < -1 || diff > 1) errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("sim/dct_1d.vcd");
        $dumpvars(0, tb_dct_1d_8pt);
        errors = 0;

        // 1. all zero
        for (i=0;i<8;i=i+1) begin xin[i] = 0; expv[i] = 0; end
        run_case("all zero");

        // 2. constant 100  -> only DC = 100*sqrt(8) = 282.84
        for (i=0;i<8;i=i+1) begin xin[i] = 100; expv[i] = 0; end
        expv[0] = 283;
        run_case("constant 100");

        // 3. simple ramp 0,10,...,70
        for (i=0;i<8;i=i+1) xin[i] = 10*i;
        expv[0]=99; expv[1]=-64; expv[2]=0; expv[3]=-7;
        expv[4]=0;  expv[5]=-2;  expv[6]=0; expv[7]=-1;
        run_case("ramp 0..70");

        // 4. known vector: first row of the JPEG example block, minus 128
        xin[0]=-76; xin[1]=-73; xin[2]=-67; xin[3]=-62;
        xin[4]=-58; xin[5]=-67; xin[6]=-64; xin[7]=-55;
        expv[0]=-185; expv[1]=-14; expv[2]=-6; expv[3]=-7;
        expv[4]=7;    expv[5]=-3;  expv[6]=-1; expv[7]=2;
        run_case("JPEG row 0 (-128)");

        // 5. alternating +100/-100 (highest frequency)
        for (i=0;i<8;i=i+1) xin[i] = (i%2==0) ? 100 : -100;
        expv[0]=0; expv[1]=51; expv[2]=0; expv[3]=60;
        expv[4]=0; expv[5]=90; expv[6]=0; expv[7]=256;
        run_case("alternating +-100");

        // 6. extreme: all -128
        for (i=0;i<8;i=i+1) begin xin[i] = -128; expv[i] = 0; end
        expv[0] = -362;
        run_case("all -128");

        if (errors == 0) $display("\nTB_DCT_1D: PASS (all outputs within +/-1 of reference)");
        else             $display("\nTB_DCT_1D: FAIL (%0d mismatches)", errors);
        $finish;
    end
endmodule
