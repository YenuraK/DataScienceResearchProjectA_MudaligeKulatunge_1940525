function stats = plot_X0_multi_seed(X0_all, cfg)
% plot_X0_multi_seed
%   Visualize and summarize multiple X₀ samples generated with different seeds.
%
% INPUT:
%   X0_all : cell array, X0_all{s} is n×m X₀ at seed s
%   cfg    : struct with fields mu, kappa, scale, corr (same as generate_X0_core)
%
% OUTPUT:
%   stats  : struct with topic-level statistics across seeds:
%            - nSeeds
%            - topic_means : nSeeds × m matrix of per-seed topic means
%            - mean_over_seeds : 1×m
%            - std_over_seeds  : 1×m
%            - ks_p : 1×m KS-test p-values
%            - ks_h : 1×m KS-test decision (1 = reject, 0 = fail-to-reject)

nSeeds = numel(X0_all);
if nSeeds == 0
    error('X0_all is empty.');
end

[Xn, m] = size(X0_all{1});

% --- Collect per-seed topic means & pooled samples for each topic ---
topic_means = zeros(nSeeds, m);
all_samples = cell(1, m);

for s = 1:nSeeds
    X = X0_all{s};
    if ~isequal(size(X), [Xn, m])
        error('All X0 matrices must have the same size (n × m).');
    end
    topic_means(s,:) = mean(X,1);
    for j = 1:m
        all_samples{j} = [all_samples{j}; X(:,j)];
    end
end

% --- Compute statistics across seeds ---
mean_over_seeds = mean(topic_means, 1);
std_over_seeds  = std(topic_means, 0, 1);

ks_p = nan(1,m);
ks_h = nan(1,m);

% --- Prepare figure ---
fig = figure('Name','X₀ Multi-Seed Analysis', ...
    'NumberTitle','off', 'Position',[100 100 1400 800]);

tiledlayout(3, m, 'TileSpacing','compact', 'Padding','compact');

% --- Row 1: Empirical histograms vs theoretical Beta for each topic ---
for j = 1:m
    nexttile(j);  % first row, column j

    data = all_samples{j};
    % 经验分布
    histogram(data, 30, 'Normalization','pdf', 'FaceColor',[0.4 0.6 0.9]); 
    hold on;

    alpha_j = cfg.mu(j) * cfg.kappa(j);
    beta_j  = (1 - cfg.mu(j)) * cfg.kappa(j);

    if strcmpi(cfg.scale,'prob')
        x = linspace(0,1,400);
        y = betapdf(x, alpha_j, beta_j);
        plot(x, y, 'r', 'LineWidth', 1.5);
        xlabel('Opinion value (probability scale)');
    elseif strcmpi(cfg.scale,'att')
        a = linspace(-1,1,400);
        x_prob = (a + 1) / 2;
        pdf_att = 0.5 * betapdf(x_prob, alpha_j, beta_j);
        plot(a, pdf_att, 'r', 'LineWidth', 1.5);
        xlabel('Opinion value (attitude scale)');
    else
        warning('Unknown cfg.scale = %s. Assuming [0,1].', cfg.scale);
        x = linspace(0,1,400);
        y = betapdf(x, alpha_j, beta_j);
        plot(x, y, 'r', 'LineWidth', 1.5);
        xlabel('Opinion value');
    end

    title(sprintf('Topic %d: empirical vs Beta', j));
    ylabel('Density');
    grid on;

    % --- KS test (only meaningful for prob scale; for att we map back) ---
    try
        if strcmpi(cfg.scale,'att')
            % data is in [-1,1]; map back to [0,1]
            data_prob = (data + 1)/2;
        else
            data_prob = data;
        end
        pd = makedist('Beta','a',alpha_j,'b',beta_j);
        [h,p] = kstest(data_prob,'CDF',pd);
        ks_h(j) = h;
        ks_p(j) = p;
    catch ME
        warning('KS-test failed for topic %d: %s', j, ME.message);
        ks_h(j) = NaN;
        ks_p(j) = NaN;
    end

    hold off;
end

% --- Row 2: boxplot of topic means across seeds (one big tile spanning all columns) ---
nexttile(m+1, [1 m]);  % span full second row

% topic_means: nSeeds × m
% --- Prepare data for boxchart (boxchart requires vector inputs) ---
y  = topic_means(:);                % Flatten each seed's topic means
x  = repmat(1:m, nSeeds, 1);        % Topic indices repeated for each seed
x  = x(:);                          % Flatten to vector

boxchart(x, y, 'JitterOutliers','on');

xlim([0.5, m+0.5]);
xticks(1:m);
xticklabels(arrayfun(@(x) sprintf('Topic %d', x), 1:m, 'UniformOutput', false));
xlabel('Topic');
ylabel('Mean opinion per seed');
title(sprintf('Distribution of per-seed topic means (nSeeds = %d)', nSeeds));
grid on;


% --- Row 3: mean ± std over seeds, with theoretical μ overlay ---
nexttile(2*m+1, [1 m]);  % full third row
xAxis = 1:m;

% --- Convert theoretical μ to the correct scale ---
if strcmpi(cfg.scale, 'att')
    mu_theory = 2 * cfg.mu(:) - 1;   % map probability μ ∈ [0,1] → attitude μ ∈ [-1,1]
else
    mu_theory = cfg.mu(:);          % no change needed
end

% --- Row 3 visualization: empirical mean ± std vs theoretical μ ---
errorbar(xAxis, mean_over_seeds, std_over_seeds, 'o-', ...
    'LineWidth',1.5,'MarkerSize',6,'CapSize',8);
hold on;
plot(xAxis, mu_theory, 'r--', 'LineWidth',1.5);


xlim([0.5, m+0.5]);
xticks(1:m);
xticklabels(arrayfun(@(x) sprintf('Topic %d', x), 1:m, 'UniformOutput', false));
xlabel('Topic');
ylabel('Mean opinion across seeds');
legend({'Empirical mean ± std','Theoretical μ'}, 'Location','best');
if strcmpi(cfg.scale,'att')
    title('Mean opinions across seeds vs theoretical μ (attitude scale)');
else
    title('Mean opinions across seeds vs theoretical μ (probability scale)');
end

grid on;
hold off;

sgtitle(sprintf('X₀ Multi-Seed Analysis (%d individuals, %d topics, %d seeds)', ...
    Xn, m, nSeeds));

% --- Print KS-test summary in command window ---
fprintf('\n🔍 KS-test results (testing empirical vs Beta(μ·κ, (1-μ)·κ)):\n');
for j = 1:m
    fprintf('  Topic %d: h = %d, p = %.4g\n', j, ks_h(j), ks_p(j));
end
fprintf('  (h = 0 → fail to reject, h = 1 → reject Beta hypothesis at default α=0.05)\n\n');

% --- Fill stats output struct ---
stats.nSeeds          = nSeeds;
stats.topic_means     = topic_means;
stats.mean_over_seeds = mean_over_seeds;
stats.std_over_seeds  = std_over_seeds;
stats.ks_p            = ks_p;
stats.ks_h            = ks_h;

end
