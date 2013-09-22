classdef Fitting < handle
  properties (SetAccess = 'private')
    targetName
    parameterNames
    parameterCount
    parameterSweeps
  end

  properties (Access = 'private')
    output
  end

  methods
    function this = Fitting(varargin)
      options = Options(varargin{:});
      grid = Grid(options);
      this.targetName = grid.targetName;
      this.parameterNames = grid.parameterNames;
      this.parameterCount = grid.parameterCount;
      this.parameterSweeps = grid.parameterSweeps;
      this.output = this.construct(grid, options);
    end

    function target = compute(this, varargin)
      if length(varargin) == 1 && ...
        (isa(varargin{1}, 'struct') || isa(varargin{1}, 'Options'))

        %
        % The parameters are packed into a structured object.
        %
        parameters = cell(1, this.parameterCount);
        for i = 1:this.parameterCount
          parameters{i} = varargin{1}.(this.parameterNames{i});
        end
        target = this.evaluate(this.output, parameters{:});
      else
        %
        % The parameters are given one by one.
        %
        target = this.evaluate(this.output, varargin{:});
      end
    end

    function [ parameters, dimensions, index ] = assign(this, varargin)
      options = Options(varargin{:});

      reference = options.reference;
      assignments = options.get('assignments', struct);
      dimensions = options.get('dimensions', 1);

      parameters = cell(1, this.parameterCount);

      %
      % Fill in with either the specified values or
      % the reference ones.
      %
      for i = 1:this.parameterCount
        name = this.parameterNames{i};
        if isfield(assignments, name)
          parameters{i} = assignments.(name);
        else
          parameters{i} = reference{i};
        end
      end

      %
      % Detect the desired dimensionality.
      %
      for i = 1:length(dimensions)
        if ~isnan(dimensions(i)), continue; end
        for j = 1:this.parameterCount
          if isscalar(parameters{j}) || ...
            ndims(parameters{j}) < i, continue; end
          dimensions(i) = size(parameters{j}, i);
          break;
        end
      end
      dimensions(isnan(dimensions)) = 1;

      %
      % Enforce the desired dimensionality except for those
      % elements that are equal to NaN.
      %
      index = [];
      for i = 1:this.parameterCount
        if isnan(parameters{i})
          index = [ index, i ];
          continue;
        end
        dims = size(parameters{i});
        pattern = dimensions;
        pattern(1:length(dims)) = pattern(1:length(dims)) ./ dims;
        if all(pattern == 1), continue; end
        parameters{i} = repmat(parameters{i}, pattern);
      end
    end
  end

  methods (Abstract, Access = 'protected')
    output = construct(this, grid, options)
    target = evaluate(this, output, varargin)
  end
end
