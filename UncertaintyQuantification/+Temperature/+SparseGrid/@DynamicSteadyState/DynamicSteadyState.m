classdef DynamicSteadyState < ...
  Temperature.Analytical.DynamicSteadyState & ...
  Temperature.SparseGrid.Base

  methods
    function this = DynamicSteadyState(varargin)
      options = Options(varargin{:});
      this = this@Temperature.Analytical.DynamicSteadyState(options);
      this = this@Temperature.SparseGrid.Base(options);
    end

    function output = compute(this, varargin)
      output = this.interpolate(varargin{:});
    end

    function plot(this, varargin)
      if this.surrogate.inputCount > 3, return; end
      this.surrogate.plot(varargin{:});
    end
  end
end
