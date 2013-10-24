function [ nodesND, weightsND ] = smolyak(rule, order, dimensionCount, varargin)
  %
  % NOTE: The sparse grid will be exact for up to
  % (2 * order - 1)-total-order polynomials.
  %
  level = order - 1;

  epsilon = 1e-8;
  maximalNodeCount = 100 * order * dimensionCount;

  nodesND = zeros(maximalNodeCount, dimensionCount);
  weightsND = zeros(maximalNodeCount, 1);
  nodeCount = 0;

  nodes1D = cell(1, order);
  weights1D = cell(1, order);
  counts1D = zeros(1, order);

  for i = 1:order
    [ nodes1D{i}, weights1D{i} ] = feval(rule, i, varargin{:});
    counts1D(i) = length(weights1D{i});
  end

  for q = max(0, level - dimensionCount + 1):level
    coefficient = (-1)^(level - q) * nchoosek(dimensionCount - 1, level - q);

    indexes = Utils.indexSparseLevel(dimensionCount, q);
    counts = prod(counts1D(indexes), 2);

    addition = nodeCount + sum(counts) - maximalNodeCount;
    if addition > 0
      addition = max(addition, maximalNodeCount);
      nodesND = [ nodesND; zeros(addition, dimensionCount) ];
      weightsND = [ weightsND; zeros(addition, 1) ];
      maximalNodeCount = maximalNodeCount + addition;
    end

    for i = 1:size(indexes, 1)
      range = (nodeCount + 1):(nodeCount + counts(i));

      nodesND(range, :) = Utils.tensor(nodes1D(indexes(i, :)));
      weightsND(range) = coefficient * prod(Utils.tensor(weights1D(indexes(i, :))), 2);

      nodeCount = nodeCount + counts(i);
    end
  end

  nodesND = nodesND(1:nodeCount, :);
  weightsND = weightsND(1:nodeCount);

  I = abs(weightsND) < epsilon;
  nodesND(I, :) = [];
  weightsND(I) = [];

  nodeCount = size(nodesND, 1);

  [ ~, I ] = sortrows(round(nodesND / epsilon) * epsilon);
  nodesND = nodesND(I, :);
  weightsND = weightsND(I);

  I = all(abs(diff(nodesND, 1)) < epsilon, 2);
  J = false(nodeCount, 1);
  J(1) = true;

  k = 1;
  for i = 2:nodeCount
    if I(i - 1)
      weightsND(k) = weightsND(k) + weightsND(i);
    else
      k = i;
      J(i) = true;
    end
  end

  nodesND = nodesND(J, :);
  weightsND = weightsND(J);

  weightsND = weightsND / sum(weightsND);
end