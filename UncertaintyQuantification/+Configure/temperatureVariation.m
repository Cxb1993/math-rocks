function options = temperatureVariation(varargin)
  options = Options(varargin{:});

  switch options.ensure('surrogate', 'PolynomialChaos')
  case 'PolynomialChaos'
    options.surrogateOptions = Options('order', 3, ...
      'quadratureOptions', Options('method', 'adaptive'), ...
      options.get('surrogateOptions', []));
  case 'StochasticCollocation'
    options.surrogateOptions = Options( ...
      'method', 'Global', ...
      'basis', 'ChebyshevLagrange', ...
      'absoluteTolerance', 1e-3, ...
      'relativeTolerance', 1e-2, ...
      'maximalLevel', 5, ...
      'maximalNodeCount', 1e3, ...
      'verbose', true, ...
      options.get('surrogateOptions', []));
  otherwise
    assert(false);
  end
end
