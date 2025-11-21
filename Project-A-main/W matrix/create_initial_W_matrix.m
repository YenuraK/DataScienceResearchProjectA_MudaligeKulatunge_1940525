function W = create_initial_W_matrix(n, d, p, m, seed, network)
%CREATE_INITIAL_W_MATRIX  Row-stochastic adjacency matrix for BA or WS networks
%
%   W = create_initial_W_matrix(n, d)                % WS with p = 0.1
%   W = create_initial_W_matrix(n, d, p)             % WS with given p
%   W = create_initial_W_matrix(n, [], [], m)        % BA with given m
%   W = create_initial_W_matrix(..., network)        % 'WS' or 'BA'
%
%   network = 'WS' -> Watts-Strogatz (d = mean degree, p = rewiring prob.)
%   network = 'BA' -> Barabási-Albert (m = edges per new node)


    % ---------- default arguments ----------
    if nargin < 6, network = ''; end
    if nargin < 5, seed = []; end
    if nargin < 4, m = false; end
    if nargin < 3, p = false; end
    if nargin < 2, error('At least n and d must be supplied.'); end

    % ---------- seed ----------
    if ~isempty(seed), rng(seed); end

    % ---------- decide which model ----------
    if isempty(network)
        if ~isequal(m,false)
            network = 'BA';
        elseif ~isequal(p,false)
            network = 'WS';
        else
            error('Supply either p (WS) or m (BA), or specify network.');
        end
    end

    network = upper(network);
    if ~ismember(network, {'WS','BA'})
        error('network must be ''WS'' or ''BA''.');
    end

    % ---------- Watts-Strogatz ----------
    if strcmp(network,'WS')
        if isequal(p,false), p = 0.1; end
        if isempty(d) || mod(d,2)~=0 || d>=n
            error('For WS: d must be even, positive, and < n.');
        end
        W = watts_strogatz_core(n, d, p);

    % ---------- Barabási-Albert ----------
    else  % 'BA'
        if isequal(m,false) || m<1 || m>=n
            error('For BA: m must satisfy 1 <= m < n.');
        end
        W = barabasi_albert_core(n, m);
    end
end

%=====================================================================
function W = watts_strogatz_core(n, d, p)
    if nargin < 3, p = 0.1; end
    k = d;  % k is mean degree, so each node has k/2 neighbors on each side
    if mod(k,2) ~= 0 || k >= n || k <= 0
        error('k must be even, positive, and less than n');
    end
    
    % Create regular ring lattice (undirected)
    A = zeros(n);
    for i = 1:n
        for j = 1:(k/2)
            A(i, mod(i+j-1, n)+1) = 1;
            A(i, mod(i-j-1, n)+1) = 1;
        end
    end
    A = min(A + A', 1);  % make symmetric and remove double edges

    % Rewiring
    for i = 1:n
        for j = 1:(k/2)
            neigh = mod(i + j - 1, n) + 1;
            if neigh <= i, continue; end  % only consider forward edges to avoid double rewiring
            
            if rand >= p, continue; end  % rewire with probability p
            
            % Remove old edge
            A(i, neigh) = 0;
            A(neigh, i) = 0;
            
            % Choose new target (not self, not existing neighbors)
            forbidden = [i, find(A(i,:))];      % one-shot allocation
            candidates = setdiff(1:n, forbidden);
            if isempty(candidates)
                % Rarely happens, just keep original edge
                A(i, neigh) = 1; A(neigh, i) = 1;
                continue;
            end
            
            new_neigh = candidates(randi(numel(candidates)));
            A(i, new_neigh) = 1;
            A(new_neigh, i) = 1;
        end
    end
    
    % Final symmetrization (in case something went wrong)
    A = min(A + A', 1);
    
    % Row-stochastic
    deg = sum(A, 2);
    deg(deg == 0) = 1;
    W = A ./ deg;
    W = round(W, 12);
end

%=====================================================================
function W = barabasi_albert_core(n, m)
    % --- 1. Create initial fully connected clique of size m ---
    A = zeros(n,n);
    A(1:m, 1:m) = 1 - eye(m);    % fully connected seed clique
    
    % Degree vector matches actual adjacency
    degrees = sum(A, 2);
    
    % --- 2. Preferential attachment for new nodes ---
    for newnode = m+1:n
        prob = degrees(1:newnode-1) / sum(degrees(1:newnode-1));
        
        % Choose m distinct existing nodes with probability proportional to degree
        targets = datasample(1:newnode-1, m, ...
                             'Weights', prob, 'Replace', false);
        
        % Add edges (undirected)
        A(newnode, targets) = 1;
        A(targets, newnode) = 1;
        
        % Update degrees
        degrees(targets) = degrees(targets) + 1;
        degrees(newnode) = m;
    end
    
    % --- 3. Row-stochastic adjacency matrix ---
    deg = sum(A,2);
    deg(deg == 0) = 1;
    W = A ./ deg;
    W = full(round(W, 12));
end

