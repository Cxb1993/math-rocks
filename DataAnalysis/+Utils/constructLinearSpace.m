function x = constructLinearSpace(varargin)
  [ ~, options ] = Options.extract(varargin{:});
  [ left, right ] = Utils.detectBounds(varargin{:});
  if left == right
    x = [ left ];
  else
    points = options.get('points', max((right - left) / 0.1, 100));
    x = linspace(left, right, points);
  end
end
