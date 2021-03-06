function HermiteLognormal
  setup;

  distribution = ProbabilityDistribution.Lognormal( ...
    'mu', 0, 'sigma', 0.8);
  variables = RandomVariables( ...
    'distributions', { distribution }, 'correlation', 1);
  transformation = ProbabilityTransformation.Gaussian( ...
    'variables', variables);

  assess(@transformation.evaluate, ...
    'basis', 'Hermite', 'exact', distribution);
end
