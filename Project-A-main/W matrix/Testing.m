addpath( fullfile(pwd,'matrices') ); % add path to the files that want to recall
% --- Watts-Strogatz ---
n = 10; d = 4; p = 0.5; seed = 123;
W = create_initial_W_matrix(n, d, p, [], seed, 'WS');
plot_network(W, 'network', 'WS', 'd', d, 'p', p, 'seed', seed);

% --- Barabási-Albert ---
n = 10; m = 3; seed = 456;
W = create_initial_W_matrix(n, [], [], m, seed, 'BA');
plot_network(W, 'network', 'BA', 'm', m, 'seed', seed);