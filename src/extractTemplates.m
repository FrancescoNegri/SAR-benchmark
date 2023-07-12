function extractTemplates(data, stim, sampleRate, graphicsObj)
%GENERATETEMPLATES Summary of this function goes here
%   Detailed explanation goes here

%% Check input parameters
if nargin < 3
    throw(MException('SFA:NotEnoughParameters', 'The parameters data, stim and sampleRate are required.'));
end

if nargin < 4
    graphicsObj = false;
end

if ~isgraphics(graphicsObj, 'figure') && ~isgraphics(graphicsObj, 'tiledlayout')  && ~isgraphics(graphicsObj, 'axes') && graphicsObj ~= false && graphicsObj ~= true
    throw(MException('SFA:WrongTypeParameter', 'The parameter graphicsObj is not a figure, a tiledlayout or axes.'));
end

%% Remove the last artifact to avoid issues
stim.Onset = stim.Onset(1:(end-1));
if isrow(stim.Onset)
    stim.Onset = stim.Onset';
end

%% Compute the Inter-Stimulus-Interval
ISI = getIEI(stim.Onset);
artifactSamples = repmat(1:min(ISI), numel(stim), 1) + stim.Onset - 1;
artifacts = data(artifactSamples);

displayedArtifacts = artifacts(randsample(size(artifacts, 1), 500), :);
figure();
hold('on');
t = repmat(0:1/sampleRate:((size(displayedArtifacts, 2) / sampleRate) - 1/sampleRate), size(displayedArtifacts, 1), 1) .* 1e3;
blankingPeriod = 1e-3;
plot(t', displayedArtifacts');
if ~isempty(blankingPeriod)
    patch(gca(), [0, blankingPeriod, blankingPeriod, 0] * 1e3, [min(gca().YTick), min(gca().YTick), max(gca().YTick), max(gca().YTick)], 'black', 'FaceAlpha', 0.3, 'LineStyle', 'none');
end
set(gcf,'Visible','on');
uiwait(gcf);

choice = questdlg('Do you want to proceed?', 'Templates Extraction', 'Yes', 'No', 'Yes');

if strcmp(choice, 'No')
    fprintf('Aborted.\n');
    return;
end

%% Project to 2D space with t-SNE
clusteringArtifactDuration = 8e-3;
clusteringArtifactNSamples = round(clusteringArtifactDuration * sampleRate);
fprintf('Computing t-SNE...');
rng(24);
features = tsne(artifacts(:, 1:clusteringArtifactNSamples), 'NumDimensions', 2);
fprintf(' Done\n');

%% Cluster with DBSCAN
params = struct();
params.minClusterSize = 50;
params.minpts = 50;
params.epsilon =  3.5;

fprintf('Finding clusters...');
[labels, metrics] = clusterFeatures(features, params);
fprintf('\b Done\n');


%% Extract templates
fprintf('Computing templates...');
groups = cell(metrics.nAcceptedClusters, 1);

for idx = 1:metrics.nAcceptedClusters
    groups{idx} = artifacts(labels.all == labels.accepted(idx), :);
end

medians = arrayfun(@(group) median(group{:}, 1), groups, 'UniformOutput', false);
medians = vertcat(medians{:});
variabilities = arrayfun(@(group) var(group{:}, 1), groups, 'UniformOutput', false);
variabilities = vertcat(variabilities{:});

templates = medians;

for idx = 1:size(templates, 1)
    % LPF median
    paddingNSamples = 50;
    filteredMedian = lowpass([medians(idx, :), flip(medians(idx, (end - paddingNSamples + 1):end))], 0.1, sampleRate);
    filteredMedian = filteredMedian(1:(end - paddingNSamples));

    % Find correctionIdx
    derivative = diff(variabilities(idx, :));
    derivative = smoothdata(derivative, 'SmoothingFactor', 0.9);
    threhsold = mean(abs(derivative));
    derivative(derivative < 0) = 0;
    idxs = find(derivative > threhsold);
    correctionIdx = max(idxs([true, diff(idxs) ~= 1]));

    % Refine correctionIdx to minimize error
    error = abs(medians(idx, :) - filteredMedian);
    correctionIdx = find(error(correctionIdx:end) <= prctile(error(correctionIdx:end), 1), 1) + correctionIdx - 1;

    % Correct template
    templates(idx, correctionIdx:end) = filteredMedian(correctionIdx:end);
    % figure()
    % plot(templates(idx, :));
    % hold('on');
    % plot(templates(idx,:) - medians(idx, :));
    % set(gcf,'Visible','on');
    % uiwait(gcf);
end
fprintf(' Done\n');

%% Plot templates and ask for confirmation
choice = confirmTemplates(templates, features, labels, sampleRate);

%% Plot templates for livescript
if graphicsObj ~= false
    if graphicsObj == true
        figure();
    elseif isgraphics(graphicsObj, 'figure')
        figure(graphicsObj.Number)
    elseif isgraphics(graphicsObj, 'tiledlayout')
        nexttile();
    end
    
   plotTemplates(gca(), templates, labels, sampleRate);
end

%% Save original stimuli and info
if choice
    fprintf('Saving templates...');

    outputPath = fullfile('./dataset/templates');
    if ~exist(outputPath, 'dir')
        mkdir(outputPath);
    end

    fileName =  strcat(string(DataHash(data)), '.mat');

    save(fullfile(outputPath, fileName), 'templates', 'sampleRate', 'stim');

    fprintf(' Done\n');
else
    fprintf('Aborted.\n');
end

rng('default');

end

