setup;

sampleCount = 1e6;
dimensionCount = 4;

%% Generate a correlation matrix.
%
C0 = Utils.generateCorrelation(dimensionCount);

%% Define the marginal distributions.
%
distribution = repmat( ...
  { ProbabilityDistribution.Gaussian }, 1, dimensionCount);

%% Construct a vector of correlated RVs.
%
rvsDependent = RandomVariables( ...
  'distributions', distributions, 'correlation', C0);

%% Transformation without reduction.
%
transformation = ProbabilityTransformation.Gaussian( ...
  'variables', rvsDependent);
data = transformation.sample(sampleCount);
C1 = corr(data);

%% Transformation with reduction.
%
transformation = ProbabilityTransformation.Gaussian( ...
  'variables', rvsDependent, 'reductionThreshold', 0.99);
data = transformation.sample(sampleCount);
C2 = corr(data);

fprintf('Initial dimensions: %d\n', dimensionCount);
fprintf('Reduced dimensions: %d\n', transformation.dimensionCount);

fprintf('Infinity norm without reduction: %e\n', norm(C0 - C1, Inf));
fprintf('Infinity norm with reduction:    %e\n', norm(C0 - C2, Inf));

data = mvnrnd(zeros(dimensionCount, 1), C0, sampleCount);
C3 = corr(data);

fprintf('Infinity norm with empirical:    %e\n', norm(C0 - C3, Inf));
