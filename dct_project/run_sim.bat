@echo off
REM Run from the project root folder:  run_sim.bat
if not exist sim mkdir sim
echo === 1. transpose buffer ===
iverilog -g2012 -Wall -o sim\tbuf.vvp rtl\transpose_buffer.v tb\tb_transpose_buffer.v || goto :err
vvp sim\tbuf.vvp
echo === 2. 1-D DCT ===
iverilog -g2012 -Wall -o sim\dct1d.vvp rtl\dct_1d_8pt.v tb\tb_dct_1d_8pt.v || goto :err
vvp sim\dct1d.vvp
echo === 3. 2-D DCT (needs vectors\ from Octave) ===
iverilog -g2012 -Wall -o sim\dct2d.vvp rtl\dct_1d_8pt.v rtl\transpose_buffer.v rtl\dct2d_top.v tb\tb_dct2d_top.v || goto :err
vvp sim\dct2d.vvp
goto :eof
:err
echo COMPILE ERROR
