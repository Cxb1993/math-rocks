function Genz(varargin)
  setup;
  use('Vendor', 'TESTPACK');

  functionNumber = 6;
  dimensionCount = 2;
  alpha = ones(1, dimensionCount);
  beta = ones(1, dimensionCount);

  function y = target(x)
    y = zeros(size(x, 1), 1);
    for i = 1:size(x, 1)
      y(i) = genz_function(functionNumber, ...
        dimensionCount, x(i, :), alpha, beta);
    end
  end

  expectation = genz_integral(functionNumber, ...
    dimensionCount, 0, 1, alpha, beta);

  assess(@target, ...
    'inputCount', dimensionCount, ...
    'exactIntegral', expectation, ...
    'sampleCount', 1e4, ...
    varargin{:});
end
