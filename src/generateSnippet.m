function generateSnippet(snippetDuration, minIAI, graphicsObj)
%GENERATESNIPPET Summary of this function goes here
%   Detailed explanation goes here

%% Check input parameters
if nargin < 1
    throw(MException('SFA:NotEnoughParameters', 'The parameter snippetDuration is required.'));
end

if nargin < 2
    minIAI = [];
end

if nargin < 3
    graphicsObj = false;
end

if ~isgraphics(graphicsObj, 'figure') && ~isgraphics(graphicsObj, 'tiledlayout')  && ~isgraphics(graphicsObj, 'axes') && graphicsObj ~= false && graphicsObj ~= true
    throw(MException('SFA:WrongTypeParameter', 'The parameter graphicsObj is not a figure, a tiledlayout or axes.'));
end

%% Pick a random template folder and load the stimulation file
filesList = dir(fullfile('./dataset/templates'));
filesList = filesList(3:end);

fileIdx = randi([1, length(filesList)]);
fprintf('Selected templates: %s\n', filesList(fileIdx).name);

load(fullfile(filesList(fileIdx).folder, filesList(fileIdx).name), 'templates', 'sampleRate', 'stim');

if ~iscolumn(stim.Onset)
    stim.Onset = stim.Onset';
end

%% Generate the stimulation train according to the original distribution of stimuli
IAI = getIEI(stim.Onset);
threshold = prctile(IAI, 99.9);
IAI = IAI(IAI <= threshold);

if isempty(minIAI)
    minIAI = min(IAI);
end

t = 1:max(IAI);
cumulativeDistribution = cdf(fitdist(IAI, 'Gamma'), t);
cumulativeDistribution = unique(cumulativeDistribution);

snippet = zeros(1, round(snippetDuration * sampleRate));

meanStimulationRate = length(find(stim.Onset < length(snippet))) / snippetDuration;

snippetStim = NaN;

while sum(isnan(snippetStim)) > 0
    snippetStim = rand(1, round(5 * meanStimulationRate * snippetDuration));
    snippetStim = interp1(cumulativeDistribution, cumulativeDistribution, snippetStim, 'nearest');
end

idxs = arrayfun(@(x)find(cumulativeDistribution==x, 1), snippetStim);
snippetStim = cumsum(t(idxs));

snippetStim = snippetStim(snippetStim < length(snippet));
snippetStim(diff(snippetStim) < minIAI) = [];   % Remove stimuli below minIAI
snippetStim = snippetStim(2:end-1);             % Remove first and last stimuli

%% Load a random template for each stimulus
templateIdxs = randi(size(templates, 1), 1, numel(snippetStim));

startDecayIdxs = randi(round(size(templates, 2) / 3), 1, numel(snippetStim)) + round(sampleRate / 1e3);
endDecayIdxs = randi(round(size(templates, 2) / 3), 1, numel(snippetStim)) + round(size(templates, 2) * 2/3) - 1;
% TODO: valutare se introdurre componenti in bassa frequenza da baseline
% non filtrata

for idx = 1:numel(snippetStim)
    template = templates(templateIdxs(idx), :);
    distortion = horzcat(ones(1, startDecayIdxs(idx) - 1), ...
       linspace(1, 0, endDecayIdxs(idx) - startDecayIdxs(idx) + 1), ...
       zeros(1, length(template) - endDecayIdxs(idx)));

    template = template .* distortion;

    snippet((1:length(template)) + snippetStim(idx) - 1) = template;
end

%% Pick a random baseline signal load it
baselineSampleRate = 0;
baselineList = dir(fullfile('./dataset/baselines'));
baselineList = baselineList(3:end);

while baselineSampleRate ~= sampleRate
    baselineIdx = randi([1, length(baselineList)]);
    load(fullfile(baselineList(baselineIdx).folder, baselineList(baselineIdx).name), 'baseline');
    baselineSampleRate = baseline.sampleRate;
end

fprintf('Selected baseline: %s\n', baselineList(baselineIdx).name);
fprintf('Selected sampling frequency: %d\n', sampleRate);

snippet = snippet + baseline.data;

%% Plot the generated snippet
if graphicsObj ~= false
    if graphicsObj == true
        figure();
    elseif isgraphics(graphicsObj, 'figure')
        figure(graphicsObj.Number)
    elseif isgraphics(graphicsObj, 'tiledlayout')
        nexttile();
    end
    
    hold('on');
    title('Snippet');
    xlabel('Time (s)');
    ylabel('Voltage (\mu{V})');
    
    plot(0:1/sampleRate:(snippetDuration - 1/sampleRate), snippet);
end

%% Save the snippet
choice = questdlg('Do you want to save the current snippet?', 'Saving', 'Yes', 'No', 'Yes');

if strcmp(choice, 'Yes')
    stimDuration = stim.Offset(1) - stim.Onset(1);
    snippetStim = struct('Onset', snippetStim, 'Offset', snippetStim + stimDuration);

    outputPath = fullfile('./dataset/snippets');
    if ~exist(outputPath, 'dir')
        mkdir(outputPath);
    end
    
    snippet = struct('data', snippet);
    snippet.baseline = baseline.data;
    snippet.stim = snippetStim;
    snippet.sampleRate = sampleRate;
    snippet.SD = baseline.SD;
    snippet.BPF = baseline.BPF;

    save(fullfile(outputPath, getRandomFilename(8)), 'snippet');
end

end

