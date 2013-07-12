function [ T, output ] = condensedEquation(this, Pdyn, options)
  if isempty(options.get('leakage', this.leakage))
    T = computeWithoutLeakage(this, Pdyn);
    output = struct;
  else
    [ T, output ] = computeWithLeakage(this, Pdyn, options);
  end
end

function T = computeWithoutLeakage(this, Pdyn)
  nodeCount = this.nodeCount;
  stepCount = size(Pdyn, 2);

  E = this.E;
  D = this.D;

  Q = D * Pdyn;
  W = Q(:, 1);

  for i = 2:stepCount
    W = E * W + Q(:, i);
  end

  X = zeros(nodeCount, stepCount);
  X(:, 1) = this.U * diag(1 ./ (1 - exp(this.samplingInterval * ...
    stepCount * this.L))) * this.UT * W;

  for i = 2:stepCount
    X(:, i) = E * X(:, i - 1) + Q(:, i - 1);
  end

  T = this.BT * X + this.ambientTemperature;
end

function [ T, output ] = computeWithLeakage(this, Pdyn, options)
  iterationLimit   = options.get('iterationLimit', 20);
  temperatureLimit = options.get('temperatureLimit', Utils.toKelvin(1e3));
  tolerance        = options.get('tolerance', 0.5);

  nodeCount = this.nodeCount;
  [ processorCount, stepCount ] = size(Pdyn);

  E = this.E;
  D = this.D;
  BT = this.BT;
  U = this.U;
  UT = this.UT;
  Lambda = this.L;

  Tamb = this.ambientTemperature;
  dt = this.samplingInterval;

  leakage = this.leakage;
  L = options.get('L', leakage.Lnom * ones(processorCount, 1));

  sampleCount = size(L, 2);

  iterationCount = zeros(1, sampleCount);

  switch options.get('version', 1)
  case 1 % Slower but more memory efficient
    T = Tamb * ones(processorCount, stepCount, sampleCount);
    P = zeros(processorCount, stepCount, sampleCount);

    X = zeros(nodeCount, stepCount);

    for i = 1:sampleCount
      l = Utils.replicate(L(:, i), 1, stepCount);

      Tlast = Tamb;

      for j = 1:iterationLimit
        P(:, :, i) = Pdyn + leakage.evaluate(l, T(:, :, i));

        Q = D * P(:, :, i);
        W = Q(:, 1);

        for k = 2:stepCount
          W = E * W + Q(:, k);
        end

        X(:, 1) = U * diag(1 ./ (1 - exp(dt * ...
          stepCount * Lambda))) * UT * W;

        for k = 2:stepCount
          X(:, k) = E * X(:, k - 1) + Q(:, k - 1);
        end

        Tcurrent = BT * X + Tamb;
        T(:, :, i) = Tcurrent;

        if max(max(Tcurrent)) > temperatureLimit
          %
          % Thermal runaway
          %
          j = Inf;
          break;
        end

        if max(max(abs(Tcurrent - Tlast))) < tolerance
          %
          % Successful convergence
          %
          break;
        end

        Tlast = Tcurrent;
      end

      iterationCount(i) = j;
    end

    output.P = P;
  case 2 % Faster but less memory efficient
    L = repmat(L, [ 1, 1, stepCount ]);

    T = Tamb * ones(processorCount, sampleCount, stepCount);
    P = permute(repmat(Pdyn, [ 1, 1, sampleCount ]), [ 1 3 2 ]);

    Q = zeros(nodeCount, sampleCount, stepCount);
    W = zeros(nodeCount, sampleCount);

    PleakLast = 0;
    Tlast = Tamb;
    I = 1:sampleCount;

    for i = 1:iterationLimit
      PleakCurrent = leakage.evaluate(L(:, I, :), T(:, I, :));
      P(:, I, :) = P(:, I, :) - PleakLast + PleakCurrent;

      Q(:, I, 1) = D * P(:, I, 1);
      W(:, I) = Q(:, I, 1);

      for j = 2:stepCount
        Q(:, I, j) = D * P(:, I, j);
        W(:, I) = E * W(:, I) + Q(:, I, j);
      end

      X = U * diag(1 ./ (1 - exp(dt * ...
        stepCount * Lambda))) * UT * W(:, I);
      T(:, I, 1) = BT * X + Tamb;

      for j = 2:stepCount
        X = E * X + Q(:, I, j - 1);
        T(:, I, j) = BT * X + Tamb;
      end

      Tcurrent = T(:, I, :);

      %
      % Thermal runaway
      %
      J = find(max(max(Tcurrent, [], 1), [], 3) > temperatureLimit);
      iterationCount(I(J)) = Inf;

      %
      % Successful convergence
      %
      K = find(max(max(abs(Tcurrent - Tlast), [], 1), [], 3) < tolerance);
      iterationCount(I(K)) = i;

      M = union(J, K);
      I(M) = [];

      if isempty(I), break; end

      PleakLast = PleakCurrent;
      PleakLast(:, M, :) = [];

      Tlast = Tcurrent;
      Tlast(:, M, :) = [];
    end

    T = permute(T, [ 1, 3, 2 ]);
    output.P = permute(P, [ 1, 3, 2 ]);
  otherwise
    assert(false);
  end

  output.iterationCount = iterationCount;
end