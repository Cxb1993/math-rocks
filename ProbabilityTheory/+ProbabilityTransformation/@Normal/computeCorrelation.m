function correlation = computeCorrelation(this, rvs)
  dimension = rvs.dimension;

  qd = Quadrature.Tensor(this.quadratureOptions, ...
    'dimension', 2, 'rules', 'ProbabilistGaussHermite');

  nodes = qd.nodes;

  %
  % The weight function of the quadrature rule is equal to e^(-x^2/2);
  % therefore, we should account for the Gauss constant for two dimensions.
  %
  weights = qd.weights / (2 * pi)^(2 / 2);

  distribution = this.distribution;

  correlation = eye(dimension);

  %
  % Just to eliminate unnecessary work if the RVs are independent.
  %
  if dimension == 1 || rvs.isIndependent(), return; end

  for i = 1:dimension
    for j = (i + 1):dimension
      rv1 = rvs{i};
      rv2 = rvs{j};

      mu1 = rv1.expectation;
      mu2 = rv2.expectation;

      sigma1 = sqrt(rv1.variance);
      sigma2 = sqrt(rv2.variance);

      rho0 = rvs.correlation(i, j);

      weightsOne = weights .* (rv1.invert(distribution.apply(nodes(:, 1))) - mu1);
      two = @(rho) rv2.invert(distribution.apply(rho * nodes(:, 1) + sqrt(1 - rho^2) * nodes(:, 2))) - mu2;
      goal = @(rho) abs(rho0 - sum(weightsOne .* two(rho)) / sigma1 / sigma2);

      [ correlation(i, j), ~, ~, out ] = ...
        fminbnd(goal, -1, 1, this.optimizationOptions);

      correlation(j, i) = correlation(i, j);
    end
  end
end
