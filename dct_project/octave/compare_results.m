% compare_results.m - compares the Verilog output (sim/out_N.txt) against the
% unrounded double-precision reference (vectors/gold_real_N.txt).
% Run from the project root AFTER the 2-D simulation:
%   octave --no-gui octave/compare_results.m
nblocks = 8;  tol = 1.0;   % output is an integer: error must be below 1 LSB
allok = true;
for N = 0:nblocks-1
  hw  = load(sprintf('sim/out_%d.txt', N));
  ref = load(sprintf('vectors/gold_real_%d.txt', N));
  e   = max(max(abs(hw - ref)));
  ok  = e < tol;
  allok = allok && ok;
  if ok, status = 'PASS'; else, status = 'FAIL'; end
  printf('block %d : max |hardware - reference| = %.4f  -> %s\n', N, e, status);
end
if allok
  disp('ALL BLOCKS WITHIN 1 LSB OF THE DOUBLE-PRECISION DCT');
else
  disp('MISMATCH FOUND');
end
