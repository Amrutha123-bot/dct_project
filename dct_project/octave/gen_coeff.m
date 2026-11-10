% gen_coeff.m - prints the Q2.14 cosine table used in rtl/dct_1d_8pt.v
% Run:  octave --no-gui octave/gen_coeff.m
addpath('octave');
C = dct_matrix();
printf('cos_tab(m) = round(8192*cos(m*pi/16)), m = 0..8 :\n');
printf('  %d', round(8192*cos((0:8)*pi/16))); printf('\n');
printf('row 0 constant = round(16384/sqrt(8)) = %d\n', round(16384/sqrt(8)));
% Rebuild the full 8x8 Q2.14 matrix with the SAME symmetry trick as Verilog
T = round(8192*cos((0:8)*pi/16));
Q = zeros(8,8);
for k = 0:7
  for n = 0:7
    m = mod((2*n+1)*k, 32);
    if k == 0,      v = 5793;
    elseif m <= 8,  v =  T(m+1);
    elseif m <= 16, v = -T(16-m+1);
    elseif m <= 24, v = -T(m-16+1);
    else            v =  T(32-m+1);
    end
    Q(k+1,n+1) = v;
  end
end
disp('Q2.14 coefficient matrix (what the Verilog uses):'); disp(Q);
err = max(max(abs(Q/16384 - C)));
printf('max |Q/16384 - exact C| = %.3e  (<= 2^-15 = %.3e expected)\n', err, 2^-15);
