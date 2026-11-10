`timescale 1ns/1ps
//==============================================================================
// Module  : transpose_buffer
// Purpose : 8x8 storage of W-bit words. Written ONE ROW at a time, read ONE
//           COLUMN at a time -> this performs the matrix transpose that
//           connects the row-DCT stage to the column-DCT stage.
//   write : synchronous (on rising clk edge when wr_en = 1)
//   read  : asynchronous (combinational) - rd_data always shows column rd_col
// Element [r][c] is stored at mem[r*8 + c].
//==============================================================================
module transpose_buffer #(
    parameter W = 16
)(
    input  wire             clk,
    input  wire             wr_en,
    input  wire [2:0]       wr_row,
    input  wire [8*W-1:0]   wr_data,   // element c of the row = bits [c*W +: W]
    input  wire [2:0]       rd_col,
    output wire [8*W-1:0]   rd_data    // element r of the column = bits [r*W +: W]
);
    reg [W-1:0] mem [0:63];
    integer i;

    always @(posedge clk) begin
        if (wr_en) begin
            for (i = 0; i < 8; i = i + 1)
                mem[wr_row*8 + i] <= wr_data[i*W +: W];
        end
    end

    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin : rd_col_gen
            assign rd_data[g*W +: W] = mem[g*8 + rd_col];
        end
    endgenerate
endmodule
