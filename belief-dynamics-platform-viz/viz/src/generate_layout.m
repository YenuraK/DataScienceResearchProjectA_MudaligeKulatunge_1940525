function coords = generate_layout(W, seed)
%GENERATE_LAYOUT  Stable force-directed layout for given adjacency matrix.
%
% Input:  W (n×n adjacency matrix)
% Output: coords (n×2 positions for consistent node placement)

if nargin < 2, seed = 42; end
rng(seed);
G = graph(W>0);
p = plot(G);
layout(p,'force');
coords = [p.XData(:), p.YData(:)];
close(gcf);
end
