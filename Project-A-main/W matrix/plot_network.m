function plot_network(W, varargin)
%PLOT_NETWORK Visualise a row-stochastic adjacency matrix
%   plot_network(W, 'network', 'WS', 'd', 4, 'p', 0.4, 'seed', 123)
%   plot_network(W, 'network', 'BA', 'm', 3, 'seed', 456)

p = inputParser;
addRequired(p, 'W', @(x) ismatrix(x) && size(x,1)==size(x,2));
addParameter(p, 'network', '', @(x) ismember(upper(x), {'WS','BA'}));
addParameter(p, 'd', [], @isscalar);
addParameter(p, 'p', [], @isscalar);
addParameter(p, 'm', [], @isscalar);
addParameter(p, 'seed', [], @isscalar);
parse(p, W, varargin{:});

network = upper(p.Results.network);
if isempty(network)
    error('network must be ''WS'' or ''BA''');
end

n = size(W,1);
A = (W > 0); A = A | A.'; A = A - diag(diag(A));
[I,J] = find(triu(A,1));
G = graph(I,J,[],n);
deg = degree(G);
maxDeg = max(deg); if maxDeg==0, maxDeg=1; end
nodeSize = 8 + 45 * (deg / maxDeg).^0.9;

figure('Color','w','Position',[200 100 950 900]);
h = plot(G,'Layout','circle');
h.LineWidth = 1.5; h.EdgeColor = [0.4 0.4 0.4]; h.EdgeAlpha = 0.8;
h.MarkerSize = nodeSize; h.NodeColor = [0.95 0.15 0.15]; h.NodeLabel = {};

if strcmp(network,'WS')
    d_val = p.Results.d; if isempty(d_val), d_val = round(mean(deg)); end
    p_val = p.Results.p; if isempty(p_val), p_val = 0.1; end
    titleStr = sprintf('Watts-Strogatz (n=%d, d=%d, p=%.2f)', n, d_val, p_val);
    fprintf('d (mean degree): %g\n', d_val);
    fprintf('p (rewiring) : %.2f\n', p_val);
else % 'BA'
    m_val = p.Results.m; if isempty(m_val), m_val = round(mean(deg)/2); end
    titleStr = sprintf('Barabási–Albert (n=%d, m=%d)', n, m_val);
    fprintf('m (BA) : %g\n', m_val);
end

title(titleStr,'FontSize',18,'FontWeight','bold');
axis equal tight off; set(gca,'Color','none','XColor','none','YColor','none');

fprintf('\n=== %s Network ===\n', network);
fprintf('Nodes : %d\n', n);
fprintf('Edges : %d\n', numel(I));
fprintf('Average degree : %.2f\n', mean(deg));
if ~isempty(p.Results.seed), fprintf('Seed : %g\n', p.Results.seed); end
fprintf('-------------------------------------\n\n');
end
