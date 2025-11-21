function plot_X0_distributions(X0, cfg)

[n,m] = size(X0);

figure('Name','X₀ Visualizations','NumberTitle','off','Position',[100 100 1400 600]);

%% --- Subplot 1–m: Histograms with theoretical PDF ---
for j = 1:m
    subplot(2,m,j)
    histogram(X0(:,j), 20, 'Normalization','pdf', 'FaceColor',[0.4 0.6 0.9])
    hold on

    % Beta parameters
    alpha_j = cfg.mu(j) * cfg.kappa(j);
    beta_j  = (1 - cfg.mu(j)) * cfg.kappa(j);

    %% --- If scale = prob: use original Beta PDF on [0,1] ---
    if strcmp(cfg.scale, 'prob')
        x = linspace(0, 1, 200);
        y = betapdf(x, alpha_j, beta_j);
        plot(x, y, 'r', 'LineWidth', 1.5);

    %% --- If scale = att: apply variable transform to [-1,1] ---
    elseif strcmp(cfg.scale, 'att')
        a = linspace(-1, 1, 200);          % attitude domain
        x_prob = (a + 1) / 2;              % map back to probability domain
        pdf_att = 0.5 * betapdf(x_prob, alpha_j, beta_j); % Jacobian correction
        plot(a, pdf_att, 'r', 'LineWidth', 1.5);
    end

    hold off
    title(sprintf('Topic %d', j))
    subtitle(sprintf('μ=%.2f, κ=%.1f, σ²=%.3f', mean(X0(:,j)), cfg.kappa(j), var(X0(:,j))))
    xlabel('Opinion Value')
    ylabel('Density')
    grid on
end

%% --- Boxplot overview ---
subplot(2,2,3)
boxchart(X0)
title('Boxplot of All Topics')
xlabel('Topic')
ylabel('Opinion Value')
grid on

%% --- Correlation heatmap ---
subplot(2,2,4)
R = corr(X0);
h = heatmap(R);
h.Title = 'Cross-Topic Correlation';
h.Colormap = turbo;

end
