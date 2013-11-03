function error = computeKLD(P, Q)
  P = P(:);
  Q = Q(:);

  Q = Q ./ sum(Q);
  P = P ./ sum(P);

  error = P .* log(P ./ Q);
  error(isnan(error)) = 0; % 0 * ln(0 / a) := 0 (when P(i) == 0)
  error(isinf(error)) = 0; % a * ln(a / 0) := 0 (when Q(i) == 0)
  error = sum(error);
end
