addpath('../src')

% Generate small-world network
n = 50; k = 6; beta = 0.2;
G = wattsStrogatz(n, k, beta);
W = full(adjacency(G));

% Normalize rows
W = W ./ max(sum(W,2), 1e-9);

% Initialize beliefs (two camps)
x0 = zeros(n,1);
x0(1:n/2) = 0.7 + 0.15*randn(n/2,1);
x0(n/2+1:end) = -0.7 + 0.15*randn(n/2,1);

% Simple dynamics (DeGroot)
T = 100;
X_series = zeros(n,T); X_series(:,1) = x0;
alpha = 0.3;
for t = 1:T-1
    neigh = W * X_series(:,t);
    X_series(:,t+1) = X_series(:,t) + alpha*(neigh - X_series(:,t));
end

coords = generate_layout(W);
plot_belief_network_evolution(X_series, W, coords, [1 5 100], {'a','b','c'});