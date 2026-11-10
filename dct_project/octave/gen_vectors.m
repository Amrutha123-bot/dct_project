% gen_vectors.m - creates test blocks + golden results for the testbench
% Run from the project root:   octave --no-gui octave/gen_vectors.m
% Files written into vectors/ :
%   in_N.hex        64 lines, 2 hex digits  (signed 8-bit, row-major)
%   gold_N.hex      64 lines, 3 hex digits  (signed 12-bit, row-major, rounded)
%   gold_real_N.txt 8x8 unrounded double-precision DCT (for compare_results.m)
addpath('octave');
C = dct_matrix();

jpeg = [52 55 61 66 70 61 64 73;
        63 59 55 90 109 85 69 72;
        62 59 68 113 144 104 66 73;
        63 58 71 122 154 106 70 69;
        67 61 68 104 126 88 68 70;
        79 65 60 70 77 68 58 75;
        85 71 64 59 55 61 65 83;
        87 79 69 68 65 76 78 94] - 128;       % classic JPEG example, level shifted

[cc, rr] = meshgrid(0:7, 0:7);                 % rr = row index, cc = column index
blocks = {};  names = {};
blocks{1} = zeros(8,8);                        names{1} = 'all zero';
blocks{2} = 50*ones(8,8);                      names{2} = 'constant 50';
blocks{3} = 10*cc - 35;                        names{3} = 'horizontal ramp (non-uniform)';
blocks{4} = jpeg;                              names{4} = 'JPEG known block (minus 128)';
blocks{5} = -128*ones(8,8);                    names{5} = 'extreme: all -128';
blocks{6} = 127*(2*mod(rr+cc,2)-1);            names{6} = 'extreme: checkerboard +127/-127';
blocks{7} = mod(73*(rr*8+cc) + 11, 256) - 128; names{7} = 'pseudo-random (formula)';
blocks{8} = 127*ones(8,8); names{8} = 'extreme: all +127';

if ~exist('vectors','dir'), mkdir('vectors'); end
fid = fopen('vectors/block_names.txt','w');
for b = 1:numel(blocks)
  X  = blocks{b};
  F1 = C * X * C';                 % matrix form  C X C^T
  F2 = dct2_def(X);                % double-sum textbook definition
  assert(max(max(abs(F1-F2))) < 1e-9, 'matrix form and definition disagree');
  Fr = round(F1);                  % ideal integer result

  N = b-1;
  f = fopen(sprintf('vectors/in_%d.hex', N), 'w');
  fprintf(f, '%02X\n', mod(reshape(X.',1,[]), 256));  fclose(f);
  f = fopen(sprintf('vectors/gold_%d.hex', N), 'w');
  fprintf(f, '%03X\n', mod(reshape(Fr.',1,[]), 4096)); fclose(f);
  f = fopen(sprintf('vectors/gold_real_%d.txt', N), 'w');
  for r = 1:8, fprintf(f, '%.6f ', F1(r,:)); fprintf(f, '\n'); end
  fclose(f);
  fprintf(fid, '%d %s\n', N, names{b});
  printf('block %d (%s): max|F| = %.2f\n', N, names{b}, max(max(abs(F1))));
end
fclose(fid);
printf('Wrote %d blocks. Matrix form == double-sum definition for all blocks.\n', numel(blocks));
