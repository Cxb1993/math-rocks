function [ sparse_order, sparse_index ] = sgmga_index ( dim_num, ...
  level_weight, level_max, rule, growth, point_num, point_total_num, ...
  sparse_unique_index )

%*****************************************************************************80
%
%% SGMGA_INDEX indexes the unique points in an SGMGA grid.
%
%  Discussion:
%
%    For each "unique" point in the sparse grid, we return its INDEX and ORDER.
%
%    That is, for the I-th unique point P, we determine the product grid which
%    first generated this point, and we return in SPARSE_ORDER the orders of
%    the 1D rules in that grid, and in SPARSE_INDEX the component indexes in
%    those rules that generated this specific point.
%
%    For instance, say P was first generated by a rule which was a 3D product
%    of a 9th order CC rule and a 15th order GL rule, and that to generate P,
%    we used the 7-th point of the CC rule and the 3rd point of the GL rule.
%    Then the SPARSE_ORDER information would be (9,15) and the SPARSE_INDEX
%    information would be (7,3).  This, combined with the information in RULE,
%    is enough to regenerate the value of P.
%
%  Licensing:
%
%    This code is distributed under the GNU LGPL license.
%
%  Modified:
%
%    25 April 2011
%
%  Author:
%
%    John Burkardt
%
%  Reference:
%
%    Fabio Nobile, Raul Tempone, Clayton Webster,
%    A Sparse Grid Stochastic Collocation Method for Partial Differential
%    Equations with Random Input Data,
%    SIAM Journal on Numerical Analysis,
%    Volume 46, Number 5, 2008, pages 2309-2345.
%
%    Fabio Nobile, Raul Tempone, Clayton Webster,
%    An Anisotropic Sparse Grid Stochastic Collocation Method for Partial 
%    Differential Equations with Random Input Data,
%    SIAM Journal on Numerical Analysis,
%    Volume 46, Number 5, 2008, pages 2411-2442.
%
%  Parameters:
%
%    Input, integer DIM_NUM, the spatial dimension.
%
%    Input, real LEVEL_WEIGHT(DIM_NUM), the anisotropic weights.
%
%    Input, integer LEVEL_MAX, the maximum value of LEVEL.
%
%    Input, integer RULE(DIM_NUM), the rule in each dimension.
%     1, "CC",  Clenshaw Curtis, Closed Fully Nested.
%     2, "F2",  Fejer Type 2, Open Fully Nested.
%     3, "GP",  Gauss Patterson, Open Fully Nested.
%     4, "GL",  Gauss Legendre, Open Weakly Nested.
%     5, "GH",  Gauss Hermite, Open Weakly Nested.
%     6, "GGH", Generalized Gauss Hermite, Open Weakly Nested.
%     7, "LG",  Gauss Laguerre, Open Non Nested.
%     8, "GLG", Generalized Gauss Laguerre, Open Non Nested.
%     9, "GJ",  Gauss Jacobi, Open Non Nested.
%    10, "HGK", Hermite Genz-Keister, Open Fully Nested.
%    11, "UO",  User supplied Open, presumably Non Nested.
%    12, "UC",  User supplied Closed, presumably Non Nested.
%
%    Input, integer GROWTH(DIM_NUM), the growth in each dimension.
%    0, "DF", default growth associated with this quadrature rule;
%    1, "SL", slow linear, L+1;
%    2  "SO", slow linear odd, O=1+2((L+1)/2)
%    3, "ML", moderate linear, 2L+1;
%    4, "SE", slow exponential;
%    5, "ME", moderate exponential;
%    6, "FE", full exponential.
%
%    Input, integer POINT_NUM, the number of unique points
%    in the grid.
%
%    Input, integer POINT_TOTAL_NUM, the total number of points
%    in the grid.
%
%    Input, integer SPARSE_UNIQUE_INDEX(POINT_TOTAL_NUM),
%    associates each point in the grid with its unique representative.
%
%    Output, integer SPARSE_ORDER(DIM_NUM,POINT_NUM), lists,
%    for each point, the order of the 1D rules used in the grid that
%    generated it.
%
%    Output, integer SPARSE_INDEX(DIM_NUM,POINT_NUM), lists, for
%    each point, its index in each of the 1D rules in the grid that generated
%    it.  The indices are 1-based.
%

%
%  Special cases.
%
  if ( level_max < 0 )
    return
  end

  if ( level_max == 0 )
    sparse_order(1:dim_num,1) = 1;
    sparse_index(1:dim_num,1) = 1;
    return
  end
%
%  Initialize the INDEX and ORDER arrays to -1 to help catch errors.
%
  sparse_order(1:dim_num,1:point_num) = -1;
  sparse_index(1:dim_num,1:point_num) = -1;

  point_count = 0;
%
%  Initialization for SGMGA_VCN_ORDERED.
%
  level_weight_min_pos = r8vec_min_pos ( dim_num, level_weight );
  q_min = level_max * level_weight_min_pos - sum ( level_weight(1:dim_num) );
  q_max = level_max * level_weight_min_pos;
  level_1d_max = zeros ( dim_num, 1 );
  for dim = 1 : dim_num
    if ( 0.0 < level_weight(dim) )
      level_1d_max(dim) = floor ( q_max / level_weight(dim) ) + 1;
      if ( q_max <= ( level_1d_max(dim) - 1 ) * level_weight(dim) )
        level_1d_max(dim) = level_1d_max(dim) - 1;
      end
    else
      level_1d_max(dim) = 0;
    end
  end
  more_grids = 0;
  level_1d = zeros ( dim_num, 1 );
%
%  Seek all vectors LEVEL_1D which satisfy the constraint:
%
%    LEVEL_MAX * LEVEL_WEIGHT_MIN_POS - sum ( LEVEL_WEIGHT ) 
%      < sum ( 1 <= I <= DIM_NUM ) LEVEL_WEIGHT(I) * LEVEL_1D(I)
%      <= LEVEL_MAX * LEVEL_WEIGHT_MIN_POS.
%
  while ( 1 )

    [ level_1d, more_grids ] = sgmga_vcn_ordered ( dim_num, level_weight, ...
      level_1d_max, level_1d, q_min, q_max, more_grids );

    if ( ~more_grids )
      break
    end
%
%  Compute the combinatorial coefficient.
%
    coef = sgmga_vcn_coef ( dim_num, level_weight, level_1d, q_max );

    if ( coef == 0.0 )
      continue
    end
%
%  Transform each 1D level to a corresponding 1D order.
%
    order_1d = level_growth_to_order ( dim_num, level_1d, rule, growth );
%
%  The inner loop generates a POINT of the GRID of the LEVEL.
%
    point_index = zeros ( dim_num, 1 );
    more_points = 0;

    while ( 1 )

      [ point_index, more_points ] = vec_colex_next3 ( dim_num, order_1d, ...
        point_index, more_points );

      if ( ~more_points )
        break
      end

      point_count = point_count + 1;
      point_unique = sparse_unique_index(point_count);
      sparse_order(1:dim_num,point_unique) = order_1d(1:dim_num);
      sparse_index(1:dim_num,point_unique) = point_index(1:dim_num);

    end

  end

  return
end