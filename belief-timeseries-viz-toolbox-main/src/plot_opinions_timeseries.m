function plot_opinions(X, mode)
% plot_opinions
% Flexible opinion visualisation tool.
%
% INPUT:
%   X    : n x m x T opinion tensor
%   mode : integer selecting visualisation type
%
% Modes:
%   1 – Separate plot for each topic (all agents)
%   2 – Average opinion per topic (all topics on same figure)
%   3 – Average opinion per topic with 95% envelope
%   4 – Random sample of 10 agents per topic, separate plots
%   5 – All trajectories in a single figure; same colour/style per topic

    [n, m, T] = size(X);

    % Consistent topic colours
    topicColors = lines(m);

    switch mode

        %% ------------------------------
        % 1. Each topic on a separate plot
        %% ------------------------------
        case 1
            for j = 1:m
                figure('Name', sprintf('Topic %d', j)); hold on;

                col = topicColors(j,:);
                for i = 1:n
                    plot(squeeze(X(i,j,:)), 'Color', col, 'LineWidth', 0.75);
                end

                title(sprintf('Topic %d Opinion Trajectories', j));
                xlabel('Time step t', 'FontSize', 15);
                ylabel('Opinion $x_{i,j}(t)$', 'Interpreter', 'latex', 'FontSize', 15);
                grid on; hold off;
            end


        %% ----------------------------------------------
        % 2. Average opinion per topic, all topics together
        %% ----------------------------------------------
        case 2
            figure('Name','Average Opinion Per Topic'); hold on;

            for j = 1:m
                avg_j = mean(X(:,j,:), 1);
                avg_j = squeeze(avg_j);

                plot(avg_j, 'LineWidth', 0.75, 'Color', topicColors(j,:));
            end

            xlabel('Time'); ylabel('Opinion');
            title('Average Opinion per Topic');
            legend(arrayfun(@(k) sprintf('Topic %d', k), 1:m, 'UniformOutput', false));
            grid on; hold off;


        %% -----------------------------------------------------
        % 3. Average + 95% envelope (mean ± 1.96 * std/sqrt(n))
        %% -----------------------------------------------------
        case 3
            figure('Name','Topic Averages with 95% Confidence envelope'); hold on;

            for j = 1:m
                mu = squeeze(mean(X(:,j,:), 1));
                sd = squeeze(std(X(:,j,:), [], 1));
                se = sd / sqrt(n);
                hi = mu + 1.96 * se;
                lo = mu - 1.96 * se;

                col = topicColors(j,:);

                % envelope shading
                fill([1:T, fliplr(1:T)], [hi', fliplr(lo')], col, ...
                     'FaceAlpha', 0.2, 'EdgeColor', 'none');

                % mean line
                plot(mu, 'Color', col, 'LineWidth', 0.75);
            end

            xlabel('Time'); ylabel('Opinion');
            title('Average Opinion with 95% Confidence Envelope');
            legend(arrayfun(@(k) sprintf('Topic %d', k), 1:m, 'UniformOutput', false));
            grid on; hold off;


        %% ----------------------------------------------------
        % 4. Random sample of 10 agents, separate plot per topic
        %% ----------------------------------------------------
        case 4
            k = min(10, n);  % sample size = 10 or total agents

            for j = 1:m
                figure('Name', sprintf('Topic %d – Sampled Agents', j)); hold on;

                col = topicColors(j,:);
                idx = randperm(n, k);

                for ii = idx
                    plot(squeeze(X(ii,j,:)), 'Color', col, 'LineWidth', 0.75);
                end

                title(sprintf('Topic %d – Random Sample of %d Agents', j, k));
                xlabel('Time'); ylabel('Opinion');
                grid on; hold off;
            end


        %% -----------------------------------------------------
        % 5. All trajectories together, colour by topic (not agent)
        %% -----------------------------------------------------
        case 5
            figure('Name','All Trajectories – Colour by Topic'); hold on;

            legendHandles = gobjects(m,1); % Pre-allocate for legend entries
            for j = 1:m
                col = topicColors(j,:);

                % --- Plot the first agent of a topic and store the handle
                h = plot(squeeze(X(1,j,:)), 'Color', col, 'LineWidth',0.75);
                legendHandles(j) = h;  %this will be used in the legend

                % --- PLot rest of agents without legend entries 
                for i = 2:n
                    plot(squeeze(X(i,j,:)), 'Color', col, 'LineWidth', 0.75);
                end
            end

            xlabel('Time'); ylabel('Opinion');
            title('All Trajectories – Same Colour per Topic');
            
            % Create legend only from the stored handles
            topicNames = arrayfun(@(k) sprintf('Topic %d', k), 1:m, 'UniformOutput', false);
            legend(legendHandles, topicNames, 'Location','bestoutside');
            
            grid on; hold off;


        otherwise
            error('Invalid mode. Choose an integer 1–5.');
    end
end
