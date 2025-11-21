%% demo_generate_team_inputs.m
% Minimal example showing how to call generate_team_inputs and inspect the
% combined outputs from all team modules.

cfg.n = 60;
cfg.m = 3;

% --- W module (Chuafa) ---
cfg.W.type = 'WS';
cfg.W.d = 6;
cfg.W.p = 0.15;
cfg.W.seed = 101;

% --- X0 module (Yongwen) ---
cfg.x0.mu = [0.35 0.55 0.75];
cfg.x0.kappa = [8 12 15];
cfg.x0.scale = 'att';
cfg.x0.corr = 0.2;
cfg.x0.seed = 202;

% --- Logic module (this repo) ---
cfg.logic.pattern = 'cascade';
cfg.logic.blocks = [1 2];
cfg.logic.signed = true;
cfg.logic.seed = 303;

sim = generate_team_inputs(cfg);

fprintf('\n--- Integrated Setup Summary ---\n');
fprintf('Agents (n): %d | Topics (m): %d\n', sim.meta.n, sim.meta.m);
fprintf('X0 size: %d x %d\n', size(sim.X0,1), size(sim.X0,2));
fprintf('W size : %d x %d | type: %s\n', size(sim.W,1), size(sim.W,2), sim.W_cfg.type);
fprintf('C size : %d x %d x %d | pattern: %s\n', size(sim.C,1), size(sim.C,2), size(sim.C,3), sim.logic_cfg.pattern);
fprintf('First-row W row-sum: %.3f\n', sum(sim.W(1,:)));
fprintf('First-agent C row sums: '); disp(sum(abs(sim.C(:,:,1)),2)');

if ~isempty(sim.output_file)
    fprintf('Saved combined inputs to %s\n', sim.output_file);
end
