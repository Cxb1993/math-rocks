classdef ProcessVariation < handle
  properties (SetAccess = 'private')
    parameters
    parameterCount
    transformations
    dimensions
  end

  methods
    function this = ProcessVariation(varargin)
      options = Options(varargin{:});

      this.parameters = options.parameters;
      this.parameterCount = length(this.parameters);

      this.transformations = cell(1, this.parameterCount);

      this.dimensions = zeros(1, this.parameterCount);
      for i = 1:this.parameterCount
        parameter = this.parameters.get(i);

        correlation = this.correlate(parameter, options);
        this.transformations{i} = this.transform( ...
          parameter, correlation, options);

        this.dimensions(i) = this.transformations{i}.dimensionCount;
      end
    end

    function assignments = assign(this, parameters)
      assignments = struct;
      names = fieldnames(this.parameters);
      for i = 1:this.parameterCount
        assignments.(names{i}) = parameters{i};
      end
    end

    function parameters = partition(this, data)
      parameters = cell(1, this.parameterCount);
      k = 0;
      for i = 1:this.parameterCount
        parameters{i} = data(:, (k + 1):(k + this.dimensions(i)));
        k = k + this.dimensions(i);
      end
    end

    function parameters = evaluate(this, parameters, varargin)
      for i = 1:this.parameterCount
        parameters{i} = this.transformations{i}.evaluate(parameters{i}, varargin{:});
      end
    end

    function parameters = normalize(this, parameters)
      for i = 1:this.parameterCount
        range = this.parameters.get(i).range;
        parameters{i} = (parameters{i} - range(1)) / (range(2) - range(1));
      end
    end

    function parameters = denormalize(this, parameters)
      for i = 1:this.parameterCount
        range = this.parameters.get(i).range;
        parameters{i} = range(1) + (range(2) - range(1)) * parameters{i};
      end
    end

    function parameters = sample(this, sampleCount)
      parameters = cell(1, this.parameterCount);
      for i = 1:this.parameterCount
        parameters{i} = this.transformations{i}.sample(sampleCount);
      end
    end

    function distributions = distributions(this)
      distributions = cell(1, this.parameterCount);
      for i = 1:this.parameterCount
        distributions{i} = this.transformations{i}.distribution;
      end
    end

    function importance = importance(this)
      importance = cell(1, this.parameterCount);
      for i = 1:this.parameterCount
        importance{i} = this.transformations{i}.importance;
      end
    end

    function string = toString(this)
      string = sprintf('%s(%s)', class(this), ...
        String(struct( ...
          'transformations', this.transformations, ...
          'parameterCount', this.parameterCount, ...
          'dimensions', this.dimensions)));
    end
  end

  methods (Access = 'protected')
    transformation = transform(this, parameter, correlation, contribution, options)
    correlation = correlate(this, parameter, options)
  end
end
