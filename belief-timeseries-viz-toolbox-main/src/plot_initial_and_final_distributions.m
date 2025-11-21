function plot_initial_and_final_distributions(X)

    [n, m, T] = size(X);

    t0 = 1;
    tF = T;

    % Choose consistent bins across plots (optional but better visually)
    commonBins = linspace(-1, 1, 25);   % change as needed

    for j = 1:m
        figure('Name', sprintf('Topic %d – Distribution Comparison', j));
        hold on;

        % Extract initial + final
        x0 = squeeze(X(:, j, t0));
        xF = squeeze(X(:, j, tF));

        % --- HISTOGRAMS (PDF-normalized) ---
        h1 = histogram(x0, commonBins, ...
            'Normalization', 'pdf', ...
            'FaceColor', [0.1 0.4 0.8], ...
            'FaceAlpha', 0.5, ...
            'EdgeAlpha', 0.2);

        h2 = histogram(xF, commonBins, ...
            'Normalization', 'pdf', ...
            'FaceColor', [0.8 0.2 0.2], ...
            'FaceAlpha', 0.5, ...
            'EdgeAlpha', 0.2);

        % Labels & formatting
        xlabel('Opinion');
        ylabel('Density');
        title(sprintf('Topic %d – Initial vs Final Distribution', j));
        legend({'t = 0', 't = T'}, 'Location', 'best');
        grid on;
        hold off;
    end
end


