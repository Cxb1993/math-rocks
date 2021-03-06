function compare(one, two, varargin)
  setup;

  if nargin < 1, one = {}; end
  if nargin < 2, two = {}; end

  one = Options('surrogate', 'MonteCarlo', one{:});
  two = Options('surrogate', 'PolynomialChaos', two{:});

  options = Configure.systemSimulation(varargin{:});
  options = Configure.deterministicAnalysis(options);

  timeSlice = options.stepCount * options.samplingInterval / 2;
  k = floor(timeSlice / options.samplingInterval);

  options = Configure.stochasticAnalysis(options, one);
  [~, oneStats, oneOutput] = construct(options);

  options = Configure.stochasticAnalysis(options, two);
  [~, twoStats, twoOutput] = construct(options);

  Plot.temperatureVariation( ...
    { oneStats.expectation, twoStats.expectation }, ...
    { oneStats.variance, twoStats.variance }, ...
    'time', options.timeLine, 'names', { one.surrogate, two.surrogate });

  Utils.compareDistributions( ...
    Utils.toCelsius(oneOutput.data(:, :, k)), ...
    Utils.toCelsius(twoOutput.data(:, :, k)), ...
    'method', 'smooth', 'range', 'unbounded', 'layout', 'one', ...
    'names', { one.surrogate, two.surrogate });

  Utils.compareDistributions( ...
    Utils.toCelsius(oneOutput.data), ...
    Utils.toCelsius(twoOutput.data), ...
    'method', 'histogram', 'range', 'unbounded', 'layout', 'separate', ...
    'names', { one.surrogate, two.surrogate });
end
