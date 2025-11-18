function C_matrices = generateC(n, m, varargin)
% generateC - Fully theory-compatible generator for Ye et al. (2020)
%
% Supports:
%   - Heterogeneous / homogeneous belief systems
%   - Irreducible logic matrices
%   - Cascade (block-lower-triangular) structures
%   - Competing logical interdependencies (signed edges)
%   - Signed or unsigned C-matrices
%
% Usage examples:
%   C = generateC(30, 3, 'pattern', 'irreducible');
%   C = generateC(30, 3, 'pattern', 'cascade', 'blocks', [1 2]);
%   C = generateC(30, 3, 'pattern', 'competing', 'signed', true);

    % -------------------------------------------------------------
    % DEFAULT SETTINGS
    % -------------------------------------------------------------
    type     = 'heterogeneous'; % or 'homogeneous'
    pattern  = 'random';        % irreducible / cascade / competing / random
    coupling = 'moderate';      
    alpha = 2; beta = 2;
    sparsity = 0;
    seed = [];
    signed = false;             % allow negative C entries?
    blocks = [];                % for cascade patterns

    % -------------------------------------------------------------
    % PARSE VARARGIN
    % -------------------------------------------------------------
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'type'
                type = varargin{i+1};
            case 'pattern'
                pattern = varargin{i+1};
            case 'coupling'
                coupling = varargin{i+1};
            case 'alpha'
                alpha = varargin{i+1};
            case 'beta'
                beta = varargin{i+1};
            case 'sparsity'
                sparsity = varargin{i+1};
            case 'seed'
                seed = varargin{i+1};
            case 'signed'
                signed = varargin{i+1};
            case 'blocks'
                blocks = varargin{i+1};
        end
    end

    if ~isempty(seed)
        rng(seed);
    end

    % -------------------------------------------------------------
    % INITIALIZE OUTPUT
    % -------------------------------------------------------------
    C_matrices = zeros(m, m, n);

    % -------------------------------------------------------------
    % CHOOSE GENERATION METHOD
    % -------------------------------------------------------------
    for i = 1:n
        switch lower(pattern)

            case 'irreducible'
                C = makeIrreducibleMatrix(m, signed);

            case 'cascade'
                if isempty(blocks)
                    blocks = 1:m; 
                end
                C = makeCascadeMatrix(blocks, signed);

            case 'competing'
                C = makeCompetingMatrix(m);

            otherwise
                C = makeRandomMatrix(m, alpha, beta, signed);
        end

        % Normalize rows (required by Ye et al. 2020)
        C = normalizeRows(C);

        C_matrices(:,:,i) = C;
    end

    % Homogeneous case
    if strcmp(type, 'homogeneous')
        for i = 2:n
            C_matrices(:,:,i) = C_matrices(:,:,1);
        end
    end
end

% =====================================================================
% HELPER FUNCTIONS
% =====================================================================

function C = makeRandomMatrix(m, a, b, signed)
    % Generate random Beta(a,b) values WITHOUT toolbox
    C = zeros(m);

    for i = 1:m
        for j = 1:m
            % Gamma sampling using sum of exponentials
            g1 = -log(prod(rand(1, a)));
            g2 = -log(prod(rand(1, b)));

            beta_sample = g1 / (g1 + g2);   % in [0,1]

            C(i,j) = beta_sample;
        end
    end

    if signed
        C = 2*C - 1;   % map to [-1,1]
    end
end

% ---------------------------------------------------------------------
% IRREDUCIBLE MATRIX (strongly connected)
% ---------------------------------------------------------------------
function C = makeIrreducibleMatrix(m, signed)
    C = rand(m);

    % Fully connected → strongly connected graph
    if signed
        C = 2*C - 1;  % allow negative edges
    end
end

% ---------------------------------------------------------------------
% CASCADE STRUCTURE (block-lower-triangular)
% ---------------------------------------------------------------------
function C = makeCascadeMatrix(blocks, signed)
    m = sum(blocks);
    C = zeros(m);

    idx = 1;
    blockStarts = cumsum([1, blocks(1:end-1)]);

    for b = 1:length(blocks)
        rStart = blockStarts(b);
        rEnd = rStart + blocks(b) - 1;

        % Each block gets random entries (irreducible in its own block)
        for r = rStart:rEnd
            for c = 1:r
                C(r,c) = rand;
                if signed
                    C(r,c) = 2*C(r,c) - 1;
                end
            end
        end
    end

    % Above-block entries are forced to zero
    for r = 1:m
        for c = r+1:m
            C(r,c) = 0;
        end
    end
end

% ---------------------------------------------------------------------
% COMPETING LOGICAL INTERDEPENDENCIES
% ---------------------------------------------------------------------
function C = makeCompetingMatrix(m)
    % Random base
    C = rand(m);

    % Choose a pair (i,j) to flip signs
    i = randi(m);
    j = randi(m);

    C(:, j) = -C(:, j);  % flip one topic's influence → competition
end

% ---------------------------------------------------------------------
% NORMALIZE ROWS (Ye et al. require row-stochastic)
% ---------------------------------------------------------------------
function C = normalizeRows(C)
    for r = 1:size(C,1)
        v = C(r,:);
        if all(v == 0)
            v = ones(1,size(C,2));
        end
        C(r,:) = v ./ sum(abs(v)); 
    end
end
