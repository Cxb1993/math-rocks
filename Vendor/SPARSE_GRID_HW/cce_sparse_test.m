function cce_sparse_test ( )

%*****************************************************************************80
%
%% CCE_SPARSE_TEST uses CCE to build a sparse grid.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    07 May 2012
%
%  Author:
%
%    Original MATLAB version by Florian Heiss, Viktor Winschel.
%    This MATLAB version by John Burkardt.
%
%  Local parameters:
%
%    Local, integer D, the spatial dimension.
%
%    Local, integer MAXK, the maximum level to check.
%
  d = 10;
  maxk = 7;

  trueval = fu_integral ( d );

  fprintf ( 1, '\n' );
  fprintf ( 1, 'CCE_SPARSE_TEST:\n' );
  fprintf ( 1, '  CCE sparse grid:\n' );
  fprintf ( 1, '  Sparse Clenshaw-Curtis Exponential sparse grid.\n' );
  fprintf ( 1, '\n' );
  fprintf ( 1, '   D  Level   Nodes    SG error    MC error\n' );
  fprintf ( 1, '\n' );

  for k = 1 : maxk
%
%  Compute sparse grid estimate.
%
    [ x, w ] = nwspgr ( 'cce', d, k );
    n = length ( w );
    g = fu_value ( d, n, x' );
    SGappr = g' * w;
    SGerror = sqrt ( ( SGappr - trueval )^2 ) / trueval;
%
%  Compute 1000 Monte Carlo estimate with same number of points, and average.
%
    sim = zeros(1000,1);
    for r = 1 : 1000
      x = rand ( n, d );
      g = fu_value ( d, n, x' );
      sim(r) = mean ( g );
    end
    Simerror = sqrt ( mean ( ( sim - trueval ).^2 ) ) / trueval;

    fprintf( '  %2d     %2d  %6d  %10.5g  %10.5g\n', d, k, n, SGerror, Simerror )

  end

  return
end
