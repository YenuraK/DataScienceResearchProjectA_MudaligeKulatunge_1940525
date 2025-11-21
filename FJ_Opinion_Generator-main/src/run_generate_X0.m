%% run_generate_X0.m
% Author: Yongwen
% Purpose:
%   Interactive generation of the initial opinion matrix X0 (FJ model input)
%   - Dynamic default generation of μ, κ based on user-specified m
%   - Full visualization, summary, and export options

clear; clc; close all;

% ---------- Parameter Definition Popup ----------
helpMsg = sprintf([ ...
    'Parameter Definitions (Friedkin–Johnsen model context):\n\n', ...
    'n  – Number of individuals (rows in X₀).\n', ...
    'm  – Number of topics (columns in X₀).\n\n', ...
    'μ  (mu) – Mean tendency of opinions for each topic, in [0,1].\n', ...
    '     • μ → 1 : strong belief that the statement is TRUE.\n', ...
    '     • μ → 0 : strong belief that it is FALSE.\n', ...
    '     • μ = 0.5 : neutral / uncertain opinions.\n\n', ...
    'κ  (kappa) – Concentration parameter of the Beta distribution.\n', ...
    '     • Higher κ ⇒ opinions are more homogeneous (less variance).\n', ...
    '     • Lower κ ⇒ opinions are more diverse (greater disagreement).\n\n', ...
    'scale – Value range of X₀:\n', ...
    '     • ''prob'' = [0,1]  (default, confidence or belief strength)\n', ...
    '     • ''att''  = [-1,1] (for positive/negative attitudes)\n\n', ...
    'corr – Cross-topic correlation (0–1).\n', ...
    '     • 0 = independent topics (default)\n', ...
    '     • 1 = highly correlated topics.\n\n', ...
    'seed – Random seed for reproducibility (optional).\n\n']);
choice = questdlg('Do you want to view detailed parameter definitions?', ...
                  'Parameter Guide', 'Show definitions','Skip','Show definitions');
if strcmp(choice,'Show definitions')
    msgbox(helpMsg, 'Parameter Definitions', 'help');
end

% ---------- First dialog: ask for n and m only ----------
prompt_basic = { ...
    'Enter number of individuals  n  (e.g. 100):', ...
    'Enter number of topics       m  (default 3):' ...
    };
dlgtitle_basic = 'Basic Setup';
dims = [1 60];
definput_basic = {'100','3'};
answer_basic = inputdlg(prompt_basic, dlgtitle_basic, dims, definput_basic);

if isempty(answer_basic)
    disp('⚠️ Cancelled by user.');
    return;
end

% Parse n and m
n = str2double(answer_basic{1});
m = str2double(answer_basic{2});

% ---------- Dynamically generate μ and κ defaults ----------
mu_default = repmat(0.5, 1, m);
kappa_default = repmat(10, 1, m);
mu_str = sprintf('[%s]', join(string(mu_default), ' '));
kappa_str = sprintf('[%s]', join(string(kappa_default), ' '));

% ---------- Second dialog for full parameters ----------
prompt = { ...
    sprintf('Enter mean tendencies μ for each topic (length = %d):', m), ...
    sprintf('Enter concentration κ for each topic (length = %d):', m), ...
    'Select scale  (prob = [0,1]; att = [-1,1]):', ...
    'Enter correlation level corr  (0 = independent, 1 = fully correlated):', ...
    'Enter random seed (optional, e.g. 123):' ...
    };
dlgtitle = sprintf('X₀ Parameter Setup (m = %d topics)', m);
dims = [1 80];
definput = {mu_str, kappa_str, 'prob', '0', ''};
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('⚠️ Cancelled by user.');
    return;
end

% ---------- Parse user input ----------
mu     = str2num(answer{1}); %#ok<ST2NM>
kappa  = str2num(answer{2}); %#ok<ST2NM>
scale  = strtrim(answer{3});
corr   = str2double(answer{4});
seed   = str2double(answer{5});

% ---------- Validation ----------
if length(mu) ~= m || length(kappa) ~= m
    error('The number of μ and κ values must match m (number of topics).');
end
if any(mu <= 0 | mu >= 1)
    warning('μ values should be within (0,1).');
end
if corr < 0 || corr > 1
    error('corr must be between 0 and 1.');
end

% ---------- Optional: Set random seed ----------
if ~isnan(seed)
    rng(seed,'twister');
    fprintf('🔁 Random seed set to %d\n', seed);
end

% ---------- Build configuration ----------
cfg.mu    = mu;
cfg.kappa = kappa;
cfg.scale = scale;
cfg.corr  = corr;
cfg.polar = zeros(1,m);

% ---------- Generate X₀ ----------
[X0, cfg] = generate_X0_core(n, m, cfg);

% ---------- Print summary ----------
fprintf('\n✅ Successfully generated X₀ matrix (%d × %d)\n', n, m);
summary.mean = mean(X0);
summary.var  = var(X0);
summary.extreme_hi = mean(X0>0.9);
summary.extreme_lo = mean(X0<0.1);
disp(table((1:m)', summary.mean', summary.var', summary.extreme_hi', summary.extreme_lo', ...
    'VariableNames', {'Topic','Mean','Variance','P(X>0.9)','P(X<0.1)'}));

% ---------- Plot distributions ----------
plot_X0_distributions(X0, cfg);

% ---------- Ask to export ----------
saveChoice = questdlg('Do you want to export X₀ and summary to CSV?', ...
                      'Export Option', 'Yes','No','No');
if strcmp(saveChoice,'Yes')
    timestamp = datestr(now,'yyyy-mm-dd_HH-MM');
    dataFile = sprintf('X0_output_%s.csv', timestamp);
    summaryFile = sprintf('X0_summary_%s.csv', timestamp);
    [file,path] = uiputfile(dataFile,'Save X₀ as CSV file');
    if ischar(file)
        % Data export
        varNames = arrayfun(@(x) sprintf('Topic%d', x), 1:m, 'UniformOutput', false);
        T = array2table(X0, 'VariableNames', varNames);
        writetable(T, fullfile(path,file));

        % Summary export
        S = table((1:m)', summary.mean', summary.var', summary.extreme_hi', summary.extreme_lo', ...
            'VariableNames', {'Topic','Mean','Variance','P(X>0.9)','P(X<0.1)'});
        writetable(S, fullfile(path,summaryFile));

        fprintf('💾 Files saved:\n   %s\n   %s\n', ...
            fullfile(path,file), fullfile(path,summaryFile));
    end
end
