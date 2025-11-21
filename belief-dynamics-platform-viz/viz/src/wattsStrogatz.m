function G = wattsStrogatz(n,k,beta)
% Generate a Watts–Strogatz small-world network
% N = number of nodes
% K = each node connected to K nearest neighbors (K must be even)
% beta = rewiring probability

if mod(k,2)~=0
    error('k must be even');
end

% Step 1. Create ring lattice
s = repelem((1:n)',1,k/2);
t = s + repmat(1:k/2,n,1);
t = mod(t-1,n)+1;
edges = [s(:) t(:)];

% Step 2. Rewire edges with probability beta
for source = 1:n
    for targetOffset = 1:(k/2)
        if rand < beta
            newTarget = randi(n);
            while newTarget == source || any(edges(:,1)==source & edges(:,2)==newTarget)
                newTarget = randi(n);
            end
            edges(find(edges(:,1)==source,1,'first') + targetOffset - 1,2) = newTarget;
        end
    end
end

% Step 3. Create MATLAB graph object
G = graph(edges(:,1),edges(:,2));
end