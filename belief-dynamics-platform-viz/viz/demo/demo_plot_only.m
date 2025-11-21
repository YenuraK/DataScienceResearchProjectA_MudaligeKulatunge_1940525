addpath('../src')

% Load your own data
% Should contain X_series (n×T) and W (n×n)
load('my_sim_result.mat')

% If no layout saved, auto-generate
coords = generate_layout(W);

% Plot evolution
plot_belief_network_evolution(X_series, W, coords, [1 5 100], {'a','b','c'}); % change to other labels if you want (d,e,f)