function C = dct_matrix()
% 8x8 orthonormal DCT-II matrix: C(k+1,n+1) = a(k)*cos((2n+1)k*pi/16)
  C = zeros(8,8);
  for k = 0:7
    if k == 0, a = sqrt(1/8); else, a = sqrt(2/8); end
    for n = 0:7
      C(k+1,n+1) = a * cos((2*n+1)*k*pi/16);
    end
  end
end
