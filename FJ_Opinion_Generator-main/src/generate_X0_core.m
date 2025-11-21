%% generate_X0_core.m
% Purpose:
%   Generate an initial opinion matrix X0 (n × m) using Beta distributions.
%   Each column = one topic; each row = one individual.

function [X0, cfg] = generate_X0_core(n, m, cfg)

% --- Defaults ---
if ~isfield(cfg,'mu'),    cfg.mu    = 0.5*ones(1,m); end
if ~isfield(cfg,'kappa'), cfg.kappa = 10*ones(1,m); end
if ~isfield(cfg,'scale'), cfg.scale = 'prob'; end
if ~isfield(cfg,'corr'),  cfg.corr  = 0; end

alpha = cfg.mu .* cfg.kappa;
beta  = (1 - cfg.mu) .* cfg.kappa;

% --- Independent sampling ---
if cfg.corr == 0
    X0 = zeros(n,m);
    for j = 1:m
        X0(:,j) = betarnd(alpha(j), beta(j), n, 1);
    end
else
    % --- Simple correlated sampling ---
    base = randn(n,1);
    X0 = zeros(n,m);
    for j = 1:m
        mix = cfg.corr * base + sqrt(1 - cfg.corr^2) * randn(n,1);
        U = normcdf(mix);
        X0(:,j) = betainv(U, alpha(j), beta(j));
    end
end

% --- Value scaling ---
switch lower(cfg.scale)
    case 'att'
        X0 = 2*X0 - 1; % [-1,1]
    case 'prob'
        % keep [0,1]
    otherwise
        warning('Unknown scale option, using [0,1].');
end

end
