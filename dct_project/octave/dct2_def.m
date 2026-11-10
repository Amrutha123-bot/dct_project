function F = dct2_def(X)
% 2-D DCT computed straight from the textbook DOUBLE-SUM definition
% (4 nested loops). Used only to cross-check the matrix form C*X*C'.
%   F(u,v) = a(u) a(v) sum_x sum_y X(x,y) cos((2x+1)u*pi/16) cos((2y+1)v*pi/16)
  F = zeros(8,8);
  for u = 0:7
    for v = 0:7
      if u == 0, au = sqrt(1/8); else, au = sqrt(2/8); end
      if v == 0, av = sqrt(1/8); else, av = sqrt(2/8); end
      s = 0;
      for x = 0:7
        for y = 0:7
          s = s + X(x+1,y+1) * cos((2*x+1)*u*pi/16) * cos((2*y+1)*v*pi/16);
        end
      end
      F(u+1,v+1) = au * av * s;
    end
  end
end
