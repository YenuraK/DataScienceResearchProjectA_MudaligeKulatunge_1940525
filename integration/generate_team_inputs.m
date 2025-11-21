function sim = generate_team_inputs(userCfg)
%GENERATE_TEAM_INPUTS  Glue code for group modules (X0, W, C).
%   SIM = GENERATE_TEAM_INPUTS(cfg) builds the initial conditions required
%   by the team pipeline by calling:
%       • Yongwen's X0 generator  (FJ_Opinion_Generator-main/src)
%       • Chuafa's W generator    (Project-A-main/W matrix)
%       • This repo's generateC.m (logic matrices)
%
%   INPUT STRUCTURE (all fields optional; sensible defaults supplied):
%       cfg.n        Number of agents (default 100)
%       cfg.m        Number of topics (default 3)
%
%       cfg.x0.mu        1×m vector (defaults to 0.5)
%       cfg.x0.kappa     1×m vector (defaults to 10)
%       cfg.x0.scale     'prob' or 'att' (default 'prob')
%       cfg.x0.corr      Cross-topic correlation in [0,1] (default 0)
%       cfg.x0.seed      Seed for reproducible X0 draw
%
%       cfg.W.type       'WS' or 'BA' (default 'WS')
%       cfg.W.d          Mean degree (even) for WS
%       cfg.W.p          Rewiring probability for WS
%       cfg.W.attach     m parameter for BA
%       cfg.W.seed       Seed for reproducible W draw
%
%       cfg.logic.type      'heterogeneous' or 'homogeneous'
%       cfg.logic.pattern   'random' | 'irreducible' | 'cascade' | 'competing'
%       cfg.logic.blocks    Block sizes for cascade (e.g., [1 2])
%       cfg.logic.signed    Allow negative dependencies (default false)
%       cfg.logic.alpha/beta Shape parameters for random pattern
%       cfg.logic.seed      Seed for reproducible C draw
%
%       cfg.output.save      true/false (default false)
%       cfg.output.folder    target folder (default ./outputs)
%       cfg.output.filename  optional custom filename (.mat)
%
%   OUTPUT STRUCT:
%       sim.X0        Generated X0 matrix
%       sim.W         Generated influence matrix
%       sim.C         Logic matrices (m×m×n)
%       sim.X0_cfg    Effective configuration passed to generate_X0_core
%       sim.W_cfg     Effective W parameters
%       sim.logic_cfg Effective logic parameters
%       sim.meta      Struct with n, m, timestamp
%       sim.output_file Saved .mat path ('' if not saved)
%
%   Example:
%       cfg.n = 80; cfg.m = 4;
%       cfg.W.type = 'WS'; cfg.W.d = 6; cfg.W.p = 0.2; cfg.W.seed = 11;
%       cfg.x0.mu = [0.3 0.5 0.7 0.9]; cfg.x0.seed = 22;
%       cfg.logic.pattern = 'cascade'; cfg.logic.blocks = [1 3];
%       sim = generate_team_inputs(cfg);
%
    if nargin < 1
        userCfg = struct();
    end

    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    add_module_path(repoRoot, fullfile('FJ_Opinion_Generator-main','src'));
    add_module_path(repoRoot, fullfile('Project-A-main','W matrix'));

    defaults.n = 100;
    defaults.m = 3;

    defaults.x0.mu    = [];
    defaults.x0.kappa = [];
    defaults.x0.scale = 'prob';
    defaults.x0.corr  = 0;
    defaults.x0.seed  = [];

    defaults.W.type   = 'WS';
    defaults.W.d      = 6;
    defaults.W.p      = 0.1;
    defaults.W.attach = 3;
    defaults.W.seed   = [];

    defaults.logic.type    = 'heterogeneous';
    defaults.logic.pattern = 'random';
    defaults.logic.blocks  = [];
    defaults.logic.signed  = false;
    defaults.logic.alpha   = 2;
    defaults.logic.beta    = 2;
    defaults.logic.seed    = [];

    defaults.output.save     = false;
    defaults.output.folder   = fullfile(repoRoot, 'outputs');
    defaults.output.filename = '';

    cfg = merge_structs(defaults, userCfg);
    validate_config(cfg);

    % -- fill dependent defaults --
    if isempty(cfg.x0.mu),    cfg.x0.mu    = 0.5 * ones(1, cfg.m); end
    if isempty(cfg.x0.kappa), cfg.x0.kappa = 10  * ones(1, cfg.m); end
    if isempty(cfg.logic.blocks) && strcmpi(cfg.logic.pattern,'cascade')
        cfg.logic.blocks = ones(1, cfg.m);
    end

    % ---------- Generate X0 ----------
    x0cfg.mu    = cfg.x0.mu;
    x0cfg.kappa = cfg.x0.kappa;
    x0cfg.scale = cfg.x0.scale;
    x0cfg.corr  = cfg.x0.corr;
    [X0, x0cfg_used] = call_with_seed(cfg.x0.seed, ...
        @() generate_X0_core(cfg.n, cfg.m, x0cfg));

    % ---------- Generate W ----------
    switch upper(cfg.W.type)
        case 'WS'
            W = call_with_seed(cfg.W.seed, ...
                @() create_initial_W_matrix(cfg.n, cfg.W.d, cfg.W.p, [], [], 'WS'));
        case 'BA'
            W = call_with_seed(cfg.W.seed, ...
                @() create_initial_W_matrix(cfg.n, [], [], cfg.W.attach, [], 'BA'));
        otherwise
            error('Unsupported W.type "%s". Use WS or BA.', cfg.W.type);
    end
    W_cfg = cfg.W;
    W_cfg.type = upper(W_cfg.type);

    % ---------- Generate logic matrices ----------
    logicArgs = {'type', cfg.logic.type, ...
                 'pattern', cfg.logic.pattern, ...
                 'alpha', cfg.logic.alpha, ...
                 'beta', cfg.logic.beta, ...
                 'signed', cfg.logic.signed};
    if ~isempty(cfg.logic.blocks)
        logicArgs = [logicArgs, {'blocks', cfg.logic.blocks}]; %#ok<AGROW>
    end
    if ~isempty(cfg.logic.seed)
        logicArgs = [logicArgs, {'seed', cfg.logic.seed}]; %#ok<AGROW>
    end
    C = generateC(cfg.n, cfg.m, logicArgs{:});

    % ---------- Assemble output ----------
    sim.X0        = X0;
    sim.X0_cfg    = x0cfg_used;
    sim.W         = W;
    sim.W_cfg     = W_cfg;
    sim.C         = C;
    sim.logic_cfg = cfg.logic;
    sim.meta.n    = cfg.n;
    sim.meta.m    = cfg.m;
    sim.meta.timestamp = datetime('now');
    sim.output_file = '';

    % ---------- Optional save ----------
    if cfg.output.save
        if ~exist(cfg.output.folder, 'dir')
            mkdir(cfg.output.folder);
        end
        if isempty(cfg.output.filename)
            stamp = datestr(now, 'yyyymmdd_HHMMss');
            fname = sprintf('team_inputs_%s.mat', stamp);
        else
            fname = cfg.output.filename;
        end
        fpath = fullfile(cfg.output.folder, fname);
        save(fpath, '-struct', 'sim');
        sim.output_file = fpath;
    end
end

% =====================================================================
function add_module_path(repoRoot, relPath)
    fullPath = fullfile(repoRoot, relPath);
    if ~exist(fullPath, 'dir')
        error('Expected folder "%s" is missing. Have you cloned all teammate repos?', fullPath);
    end
    addpath(fullPath);
end

function cfg = merge_structs(base, overrides)
    cfg = base;
    fields = fieldnames(overrides);
    for i = 1:numel(fields)
        f = fields{i};
        val = overrides.(f);
        if isstruct(val)
            if isfield(base, f)
                cfg.(f) = merge_structs(base.(f), val);
            else
                cfg.(f) = val;
            end
        elseif ~isempty(val)
            cfg.(f) = val;
        end
    end
end

function validate_config(cfg)
    if cfg.n <= 0 || cfg.m <= 0
        error('n and m must be positive.');
    end
    if ~isscalar(cfg.n) || ~isscalar(cfg.m)
        error('n and m must be scalars.');
    end
end

function [varargout] = call_with_seed(seed, fn)
    if ~isempty(seed)
        previous = rng;
        rng(seed, 'twister');
    else
        previous = [];
    end
    [varargout{1:nargout}] = fn();
    if ~isempty(previous)
        rng(previous);
    end
end
