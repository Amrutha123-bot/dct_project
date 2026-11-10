`timescale 1ns/1ps
//==============================================================================
// Module  : dct2d_top
// Purpose : 8x8 2-D DCT using separability:  F = C * X * C^T
//
//   in_row --> [row DCT] --> [transpose buffer] --> [column DCT] --> out_col
//
// Protocol
//   LOAD phase : while in_ready=1, present one row (8 signed 8-bit pixels) per
//                clock with in_valid=1. After 8 rows the block is complete.
//   READ phase : (in_ready=0) the design outputs 8 columns, one per clock,
//                with out_valid=1. out_idx = column number v (0..7);
//                out_col element u (bits [u*12 +: 12]) = F[u][v], signed 12-bit.
//                out_last=1 on the final column. Then in_ready returns to 1.
//
// Fixed-point plan
//   Stage 1 (rows)   : 8-bit in, SHIFT=10 -> 16-bit result with 4 fraction bits
//   Stage 2 (columns): 16-bit in, SHIFT=18 -> 12-bit integer result (saturated)
//==============================================================================
module dct2d_top (
    input  wire         clk,
    input  wire         rst_n,        // active-low asynchronous reset

    // input side
    input  wire         in_valid,
    input  wire [63:0]  in_row,       // 8 x signed 8-bit, pixel c = bits [c*8 +: 8]
    output wire         in_ready,

    // output side
    output reg          out_valid,
    output reg  [2:0]   out_idx,
    output reg          out_last,
    output reg  [95:0]  out_col       // 8 x signed 12-bit, coefficient u = bits [u*12 +: 12]
);

    localparam S_LOAD = 1'b0;
    localparam S_READ = 1'b1;

    reg       state;
    reg [2:0] row_cnt;
    reg [2:0] col_cnt;

    assign in_ready = (state == S_LOAD);

    // ---------------- Stage 1: 1-D DCT on the incoming row ------------------
    wire [127:0] row_dct;    // 8 x 16 bit
    dct_1d_8pt #(.IN_W(8),  .OUT_W(16), .SHIFT(10)) u_row_dct (
        .x_flat(in_row),
        .y_flat(row_dct)
    );

    // ---------------- Transpose buffer --------------------------------------
    wire [127:0] buf_col;    // 8 x 16 bit : one column of the stored block
    transpose_buffer #(.W(16)) u_tbuf (
        .clk    (clk),
        .wr_en  (in_valid & in_ready),
        .wr_row (row_cnt),
        .wr_data(row_dct),
        .rd_col (col_cnt),
        .rd_data(buf_col)
    );

    // ---------------- Stage 2: 1-D DCT on the stored column -----------------
    wire [95:0] col_dct;     // 8 x 12 bit
    dct_1d_8pt #(.IN_W(16), .OUT_W(12), .SHIFT(18)) u_col_dct (
        .x_flat(buf_col),
        .y_flat(col_dct)
    );

    // ---------------- Control FSM + output register -------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_LOAD;
            row_cnt   <= 3'd0;
            col_cnt   <= 3'd0;
            out_valid <= 1'b0;
            out_last  <= 1'b0;
            out_idx   <= 3'd0;
            out_col   <= 96'd0;
        end else begin
            out_valid <= 1'b0;          // default: no output this cycle
            out_last  <= 1'b0;
            case (state)
                S_LOAD: begin
                    if (in_valid) begin
                        row_cnt <= row_cnt + 3'd1;      // wraps 7 -> 0
                        if (row_cnt == 3'd7) begin
                            state    <= S_READ;
                            col_cnt  <= 3'd0;
                        end
                    end
                end
                S_READ: begin
                    out_col   <= col_dct;
                    out_valid <= 1'b1;
                    out_idx   <= col_cnt;
                    out_last  <= (col_cnt == 3'd7);
                    col_cnt   <= col_cnt + 3'd1;         // wraps 7 -> 0
                    if (col_cnt == 3'd7) state <= S_LOAD;
                end
            endcase
        end
    end

endmodule
