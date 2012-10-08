function varargout = getCoefficients(varargin)
  warning('The code has not been compiled yet. Trying to do so...');

  mex = sprintf('%s%sbin%smex', matlabroot, filesep, filesep);

  if system(sprintf('cd %s; MEX="%s" make getCoefficients', traceLocation, mex)) ~= 0
    error('Cannot compile the HotSpot interface.');
  end

  clear all;
  [ varargout{1:nargout} ] = HotSpot.getCoefficients(varargin{:});
end
