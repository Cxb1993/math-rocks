function JacobiBeta11
  setup;

  order = 1;
  sampleCount = 1e5;

  f = @(x) x;

  distribution = ProbabilityDistribution.Beta( ...
    'alpha', 2, 'beta', 2, 'a', -1, 'b', 1);

  samples = distribution.sample(sampleCount, 1);

  mcData = f(samples);

  surrogate = PolynomialChaos.Jacobi( ...
    'inputCount', 1, 'outputCount', 1, 'order', order, ...
    'alpha', distribution.alpha - 1, ...
    'beta', distribution.beta - 1, ...
    'a', distribution.a, ...
    'b', distribution.b);

  surrogateOutput = surrogate.expand(f);
  surrogateData = surrogate.evaluate(surrogateOutput, samples);

  assess(mcData, surrogate, surrogateOutput, surrogateData, distribution);
end