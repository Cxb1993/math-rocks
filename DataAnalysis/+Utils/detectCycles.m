function [partitions, fractions, extrema] = detectCycles(data, tolerance)
  if nargin < 2, tolerance = 0; end

  assert(ismatrix(data));
  componentCount = size(data, 1);

  partitions = cell(1, componentCount);
  fractions = cell(1, componentCount);
  extrema = cell(1, componentCount);

  for i = 1:componentCount
    extrema{i} = Utils.detectExtrema(data(i, :), tolerance);
    [J, fractions{i}] = Utils.countCycles(data(i, extrema{i}));
    %
    % NOTE: reshape is to ensure the partitions are given in columns.
    %
    partitions{i} = reshape(extrema{i}(J), 2, []);
  end
end
