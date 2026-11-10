`timescale 1ns/1ps
//==============================================================================
// Module  : dct_1d_8pt
// Purpose : 8-point 1-D DCT-II (orthonormal), purely COMBINATIONAL.
//           y[k] = sum_{n=0..7} C[k][n] * x[n]
//           C[k][n] = a(k)*cos((2n+1)*k*pi/16),  a(0)=sqrt(1/8), a(k>0)=1/2
// Number format:
//   * coefficients are signed Q2.14  (real value = integer / 16384)
//   * inputs  are signed integers, IN_W bits each
//   * outputs are signed integers, OUT_W bits each, after
//        round-half-up, arithmetic right shift by SHIFT, then saturation
//   * SHIFT = 14 gives a plain integer output.  A larger/smaller SHIFT moves
//     the binary point of the output (used to keep extra fraction bits
//     between the row pass and the column pass of the 2-D DCT).
// Ports are "flattened": element n of a vector lives in bits [n*W +: W].
//==============================================================================
module dct_1d_8pt #(
    parameter IN_W  = 8,     // bits per input sample  (signed)
    parameter OUT_W = 12,    // bits per output sample (signed)
    parameter SHIFT = 14,    // right shift applied to the accumulator
    parameter ACC_W = 40     // accumulator width (big enough for all cases)
)(
    input  wire [8*IN_W-1:0]  x_flat,   // x[0] is bits [IN_W-1:0]
    output reg  [8*OUT_W-1:0] y_flat    // y[0] is bits [OUT_W-1:0]
);

    //--------------------------------------------------------------------------
    // Cosine table: round(8192*cos(m*pi/16)), m = 0..8   (Q2.14 of 0.5*cos)
    //--------------------------------------------------------------------------
    function signed [15:0] cos_tab;
        input [3:0] m;
        begin
            case (m)
                4'd0:    cos_tab = 16'sd8192;
                4'd1:    cos_tab = 16'sd8035;
                4'd2:    cos_tab = 16'sd7568;
                4'd3:    cos_tab = 16'sd6811;
                4'd4:    cos_tab = 16'sd5793;
                4'd5:    cos_tab = 16'sd4551;
                4'd6:    cos_tab = 16'sd3135;
                4'd7:    cos_tab = 16'sd1598;
                4'd8:    cos_tab = 16'sd0;
                default: cos_tab = 16'sd0;
            endcase
        end
    endfunction

    //--------------------------------------------------------------------------
    // coef(k,n) = Q2.14 value of C[k][n].
    // Angle index m = ((2n+1)*k) mod 32 stands for the angle m*pi/16.
    // Quadrant symmetry of cosine lets us use the 9-entry table above.
    //--------------------------------------------------------------------------
    function signed [15:0] coef;
        input [2:0] k;
        input [2:0] n;
        integer m;
        begin
            m = ((2*n + 1) * k) % 32;
            if (k == 0)       coef =  16'sd5793;               // 1/sqrt(8)
            else if (m <= 8)  coef =  cos_tab(m);
            else if (m <= 16) coef = -cos_tab(16 - m);
            else if (m <= 24) coef = -cos_tab(m - 16);
            else              coef =  cos_tab(32 - m);
        end
    endfunction

    //--------------------------------------------------------------------------
    // Constants for rounding and saturation
    //--------------------------------------------------------------------------
    localparam signed [ACC_W-1:0] ROUND = (1 <<< (SHIFT - 1));
    localparam signed [ACC_W-1:0] MAXV  =  (1 <<< (OUT_W - 1)) - 1;
    localparam signed [ACC_W-1:0] MINV  = -(1 <<< (OUT_W - 1));

    integer k, n;
    reg signed [IN_W-1:0]  xs;
    reg signed [ACC_W-1:0] acc;
    reg signed [ACC_W-1:0] res;

    always @* begin
        y_flat = {8*OUT_W{1'b0}};
        for (k = 0; k < 8; k = k + 1) begin
            acc = 0;
            for (n = 0; n < 8; n = n + 1) begin
                xs  = x_flat[n*IN_W +: IN_W];
                acc = acc + xs * coef(k[2:0], n[2:0]);   // multiply-accumulate
            end
            res = (acc + ROUND) >>> SHIFT;               // round + scale
            if (res > MAXV)      res = MAXV;             // saturate high
            else if (res < MINV) res = MINV;             // saturate low
            y_flat[k*OUT_W +: OUT_W] = res[OUT_W-1:0];
        end
    end

endmodule
