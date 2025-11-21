%% run_generate_X0_multi_seed.m
% Author: Yongwen
%
% Purpose:
%   Generate multiple initial opinion matrices X0 for the Friedkin–Johnsen (FJ) model.
%   This script extends the single-seed version by allowing the user to specify
%   an arbitrary number of random seeds ("seed_count").
%
%   For each seed s = 1..seed_count:
%       - A distinct X0^(s) is generated using generate_X0_core.m
%       - All X0^(s) are stored in a cell array for analysis
%
%   When seed_count > 1:
%       - The script performs multi-seed robustness analysis
%       - Provides aggregate summary statistics across seeds
%       - Visualizes the empirical distribution vs theoretical Beta PDFs
%       - Runs KS-tests to evaluate goodness-of-fit
%
%   The script also provides export options for:
%       - Each individual X0^(s)
%       - The aggregated summary statistics across seeds
%
%   When seed_count = 1, the behavior falls back to the original
%   single-seed visualization (plot_X0_distributions.m).

clear; clc; close all;

%% ---------- Parameter Definition Popup ----------
helpMsg = sprintf([ ...
    'Parameter Definitions (Friedkin–Johnsen Model):\n\n', ...
    'n  – Number of individuals (rows of X₀).\n', ...
    'm  – Number of topics (columns of X₀).\n\n', ...
    'μ  (mu) – Expected belief strength for each topic, in [0,1].\n', ...
    '     • μ → 1 : high confidence that the statement is TRUE.\n', ...
    '     • μ → 0 : high confidence that it is FALSE.\n', ...
    '     • μ = 0.5 : uncertainty / neutrality.\n\n', ...
    'κ  (kappa) – Concentration parameter of the Beta distribution.\n', ...
    '     • Higher κ ⇒ opinions become more homogeneous (low variance).\n', ...
    '     • Lower κ ⇒ opinions become more heterogeneous (high variance).\n\n', ...
    'scale – Output range of X₀:\n', ...
    '     • ''prob'' = [0,1]  (default, belief certainty)\n', ...
    '     • ''att''  = [-1,1] (attitude representation)\n\n', ...
    'corr – Cross-topic correlation level (0–1).\n', ...
    '     • 0 = independent topics (default)\n', ...
    '     • 1 = strongly correlated topics\n\n', ...
    'seed_count – Number of X₀ samples to generate.\n', ...
    '     • 1 = single sample (same behavior as the standard script)\n', ...
    '     • >1 = multi-seed robustness analysis\n']);
choice = questdlg('Do you want to view detailed parameter definitions?', ...
                  'Parameter Guide', 'Show definitions','Skip','Show definitions');
if strcmp(choice,'Show definitions')
    msgbox(helpMsg, 'Parameter Definitions', 'help');
end

%% ---------- First dialog: Ask for n and m ----------
prompt_basic = { ...
    'Enter number of individuals  n  (e.g., 100):', ...
    'Enter number of topics       m  (default: 3):' ...
    };
dlgtitle_basic = 'Basic Setup';
dims = [1 60];
definput_basic = {'100','3'};
answer_basic = inputdlg(prompt_basic, dlgtitle_basic, dims, definput_basic);

if isempty(answer_basic)
    disp('⚠️ Operation cancelled by user.');
    return;
end

% Parse n and m
n = str2double(answer_basic{1});
m = str2double(answer_basic{2});

if isnan(n) || isnan(m) || n <= 0 || m <= 0
    error('n and m must be strictly positive numeric values.');
end

%% ---------- Automatically generate default μ and κ ----------
mu_default    = repmat(0.5, 1, m);
kappa_default = repmat(10,  1, m);

mu_str    = sprintf('[%s]', join(string(mu_default), ' '));
kappa_str = sprintf('[%s]', join(string(kappa_default), ' '));

%% ---------- Second dialog: Full parameters + seed_count ----------
prompt = { ...
    sprintf('Enter mean tendencies μ (vector of length %d):', m), ...
    sprintf('Enter concentration κ (vector of length %d):', m), ...
    'Select scale  (prob = [0,1]; att = [-1,1]):', ...
    'Enter correlation corr  (0 = independent, 1 = fully correlated):', ...
    'Enter number of seeds (seed_count, default = 1):' ...
    };

dlgtitle = sprintf('X₀ Multi-Seed Setup (m = %d topics)', m);
dims = [1 80];
definput = {mu_str, kappa_str, 'prob', '0', '1'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('⚠️ Operation cancelled by user.');
    return;
end

%% ---------- Parse full parameter input ----------
mu        = str2num(answer{1}); %#ok<ST2NM>
kappa     = str2num(answer{2}); %#ok<ST2NM>
scale     = strtrim(answer{3});
corr      = str2double(answer{4});
seedCount = str2double(answer{5});

%% ---------- Validation ----------
if length(mu) ~= m || length(kappa) ~= m
    error('Length of μ and κ must match the number of topics m.');
end
if any(mu <= 0 | mu >= 1)
    warning('μ should lie strictly in (0,1) to avoid degenerate Beta distributions.');
end
if corr < 0 || corr > 1
    error('corr must be in the range [0, 1].');
end
if isnan(seedCount) || seedCount < 1 || mod(seedCount,1) ~= 0
    error('seed_count must be a positive integer.');
end

fprintf('\n📌 Multi-seed configuration:\n');
fprintf('   n = %d individuals\n', n);
fprintf('   m = %d topics\n', m);
fprintf('   seed_count = %d\n', seedCount);

%% ---------- Build configuration struct ----------
cfg.mu    = mu;
cfg.kappa = kappa;
cfg.scale = scale;
cfg.corr  = corr;
cfg.polar = zeros(1,m);  % Placeholder for future polarized distribution options

%% ---------- Generate X₀ for each seed ----------
X0_all = cell(seedCount,1);

for s = 1:seedCount
    rng(s,'twister');                     % Set deterministic seed
    [X0_s, ~] = generate_X0_core(n, m, cfg);
    X0_all{s} = X0_s;
end

%% ---------- Summary and Visualization ----------
if seedCount == 1
    % Single-seed mode → fallback to original visualization
    X0 = X0_all{1};
    fprintf('\n✅ Generated X₀ (single sample): %d × %d\n', n, m);

    summary.mean        = mean(X0);
    summary.var         = var(X0);
    summary.extreme_hi  = mean(X0 > 0.9);
    summary.extreme_lo  = mean(X0 < 0.1);

    disp(table((1:m)', summary.mean', summary.var', ...
        summary.extreme_hi', summary.extreme_lo', ...
        'VariableNames', {'Topic','Mean','Variance','P(X>0.9)','P(X<0.1)'}));

    plot_X0_distributions(X0, cfg);

else
    % Multi-seed robustness analysis
    fprintf('\n✅ Successfully generated %d X₀ samples (size %d × %d each)\n', ...
        seedCount, n, m);

    stats = plot_X0_multi_seed(X0_all, cfg);

    % Display topic-level summary table
    Tsum = table((1:m)', cfg.mu(:), cfg.kappa(:), ...
        stats.mean_over_seeds(:), stats.std_over_seeds(:), ...
        stats.ks_p(:), stats.ks_h(:), ...
        'VariableNames', {'Topic','mu_theory','kappa', ...
                          'Mean_over_seeds','Std_over_seeds', ...
                          'KS_p_value','KS_reject'});
    fprintf('\n📊 Summary across %d seeds:\n', seedCount);
    disp(Tsum);
end

%% ---------- Export options ----------
choiceX0 = questdlg('Export individual X₀ matrices for each seed?', ...
                    'Export X₀ (per seed)', 'Yes','No','No');

choiceSum = questdlg('Export summary statistics across seeds?', ...
                     'Export Summary','Yes','No','Yes');

if strcmp(choiceX0,'No') && strcmp(choiceSum,'No')
    disp('ℹ️ No export selected.');
    return;
end

% Choose folder
exportDir = uigetdir(pwd, 'Select folder to save files');
if exportDir == 0
    disp('⚠️ Export cancelled by user.');
    return;
end

timestamp = datestr(now,'yyyy-mm-dd_HHMMSS');

%% --- Export individual X₀ matrices ---
if strcmp(choiceX0,'Yes')
    fprintf('\n💾 Exporting %d X₀ matrices to:\n   %s\n', seedCount, exportDir);

    varNames = arrayfun(@(x) sprintf('Topic%d', x), 1:m, 'UniformOutput', false);

    for s = 1:seedCount
        T = array2table(X0_all{s}, 'VariableNames', varNames);
        fname = sprintf('X0_seed_%03d_%s.csv', s, timestamp);
        writetable(T, fullfile(exportDir, fname));
    end

    fprintf('   ✅ Completed exporting all X₀ samples.\n');
end

%% --- Export summary statistics ---
if strcmp(choiceSum,'Yes')
    if seedCount == 1
        % Export single-run summary
        X0 = X0_all{1};
        summary.mean        = mean(X0);
        summary.var         = var(X0);
        summary.extreme_hi  = mean(X0 > 0.9);
        summary.extreme_lo  = mean(X0 < 0.1);

        S = table((1:m)', summary.mean', summary.var', ...
            summary.extreme_hi', summary.extreme_lo', ...
            'VariableNames', {'Topic','Mean','Variance','P(X>0.9)','P(X<0.1)'});

        fnameSum = sprintf('X0_summary_single_%s.csv', timestamp);
        writetable(S, fullfile(exportDir, fnameSum));

        fprintf('   💾 Single-run summary exported:\n   %s\n', fullfile(exportDir,fnameSum));

    else
        % Export multi-seed summary table
        S = table((1:m)', cfg.mu(:), cfg.kappa(:), ...
            stats.mean_over_seeds(:), stats.std_over_seeds(:), ...
            stats.ks_p(:), stats.ks_h(:), ...
            'VariableNames', {'Topic','mu_theory','kappa', ...
                              'Mean_over_seeds','Std_over_seeds', ...
                              'KS_p_value','KS_reject'});

        fnameSum = sprintf('X0_multi_summary_%s.csv', timestamp);
        writetable(S, fullfile(exportDir, fnameSum));

        fprintf('   💾 Multi-seed summary exported:\n   %s\n', fullfile(exportDir,fnameSum));
    end
end
