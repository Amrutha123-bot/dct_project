# 8x8 2-D DCT in Verilog (row DCT -> transpose buffer -> column DCT)

Folders
  rtl/      synthesizable design : dct_1d_8pt.v, transpose_buffer.v, dct2d_top.v
  tb/       testbenches          : tb_dct_1d_8pt.v, tb_transpose_buffer.v, tb_dct2d_top.v
  octave/   reference scripts    : dct_matrix.m, dct2_def.m, gen_coeff.m, gen_vectors.m, compare_results.m
  vectors/  test blocks + golden results (already generated; regenerate with gen_vectors.m)
  sim/      simulation outputs (.vcd waveforms, out_N.txt)
  run_sim.bat  runs all three simulations on Windows

Run (from this folder, in a Windows terminal):
  run_sim.bat
  octave --no-gui octave\gen_coeff.m
  octave --no-gui octave\gen_vectors.m      (optional: regenerates vectors\)
  octave --no-gui octave\compare_results.m  (after run_sim.bat)
  gtkwave sim\dct2d.vcd
