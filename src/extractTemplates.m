function extractTemplates(data, stim, sampleRate, blankingNSamples, nTemplates, graphicsObj)
%GENERATETEMPLATES Summary of this function goes here
%   Detailed explanation goes here

%% Check input parameters
if nargin < 3
    throw(MException('SFA:NotEnoughParameters', 'The parameters data, stim and sampleRate are required.'));
end

if nargin < 4
    blankingNSamples = ones(size(stim.Onset)) * (sampleRate * 1e-3);
end

if nargin < 5
    nTemplates = false;
end

if nargin < 6
    graphicsObj = false;
end

if ~isgraphics(graphicsObj, 'figure') && ~isgraphics(graphicsObj, 'tiledlayout')  && ~isgraphics(graphicsObj, 'axes') && graphicsObj ~= false && graphicsObj ~= true
    throw(MException('SFA:WrongTypeParameter', 'The parameter graphicsObj is not a figure, a tiledlayout or axes.'));
end

%% Compute the baseline
[~, baselinePercentiles] = getBaselineFromStim(data, stim.Onset, sampleRate, 10e-3, 0.5e-3, [25, 75]);
baselineBottom = baselinePercentiles(1);
baselineTop = baselinePercentiles(end);

%% Compute the Inter-Stimulus-Interval
ISI = getIEI(stim.Onset);

%% Save original stimuli and info
outputPath = fullfile('./dataset/templates', string(DataHash(data)));
if ~exist(outputPath, 'dir')
    mkdir(outputPath);
end

if iscolumn(stim.Onset)
    stim.Onset = stim.Onset';
end
save(fullfile(outputPath, '.stim.mat'), 'stim');

info = struct('sampleRate', sampleRate);
save(fullfile(outputPath, '.info.mat'), 'info');

%% Perform random stimuli permutation
stim.Onset = stim.Onset(1:(end-1)); % Remove the last stimulus as it has no ISI
permIdxs = randperm(length(stim.Onset));

%% Compute duration for each stimulus
stimNSamples = zeros(1, length(stim.Onset));
selectedIdxs = false(1, length(stim.Onset));

searchingWindow = 3e-3;
searchingSamples = 1:round(searchingWindow * sampleRate);

idx = 1;

while length(selectedIdxs(selectedIdxs ~= 0)) < nTemplates
    flag = false;
    searchingOffset = blankingNSamples(permIdxs(idx));
    
    while flag == false
        searchingVector = data(stim.Onset(permIdxs(idx)) + searchingSamples - 1 + searchingOffset);
        
        if median(searchingVector) > baselineBottom && median(searchingVector) < baselineTop
            flag = true;
        else
            searchingOffset = searchingOffset + 1;
        end
    end
    
    searchingOffset = searchingOffset + length(searchingSamples);
    
    if searchingOffset < ISI(permIdxs(idx))
        stimNSamples(idx) = searchingOffset;
        selectedIdxs(idx) = true;
    end

    idx = idx + 1;
end

stim.Onset = stim.Onset(permIdxs(selectedIdxs));
stimNSamples = stimNSamples(selectedIdxs);
ISI = ISI(permIdxs(selectedIdxs));

%% Isolate, smooth, plot and save templates
paddingBefore = 100;
paddingAfter = 25;
smoothingFrequency = 0.1;

if graphicsObj ~= false
    if graphicsObj == true
        figure();
    elseif isgraphics(graphicsObj, 'figure')
        figure(graphicsObj.Number)
    elseif isgraphics(graphicsObj, 'tiledlayout')
        nexttile();
    end
    
    hold('on');
    xlabel('Time (ms)');
    ylabel('Voltage (\mu{V})');
end

if nTemplates == false
    nTemplates = length(stim.Onset);
end

for idx=1:nTemplates
    stimSamples = (1:(paddingBefore+stimNSamples(idx)+paddingAfter)) - paddingBefore;
    
    stimSamples = stim.Onset(idx) + stimSamples - 1;
    template = data(stimSamples);
    template((paddingBefore+stimNSamples(idx))+1:end) = flip(template(((paddingBefore+stimNSamples(idx))+1:end) - paddingAfter));
    
    smoothedTemplate = lowpass(template, smoothingFrequency, sampleRate);
    smoothedTemplate = smoothedTemplate((1:stimNSamples(idx)) + paddingBefore);
    
    stimSamples = 1:stimNSamples(idx);
    smoothedTemplate(1:blankingNSamples) = template((1:blankingNSamples) + paddingBefore);    % Restore the stimulation shape, preserving the smoothed artifact
    template = smoothedTemplate;
    
    hm = hamming(2*(length(template) - blankingNSamples(idx)));
    hm = hm((end/2 + 1):end);
    template((blankingNSamples + 1):end) = template((blankingNSamples + 1):end) .* hm';
    
    if graphicsObj ~= false
        plot((0:1/sampleRate:(stimSamples(end)/sampleRate - 1/sampleRate))*1e3, template);
    end
    
    save(fullfile(outputPath, getRandomFilename(8)), 'template');
end

if graphicsObj ~= false
    t0 = 0;
    y = ylim;
    y0 = y(1);
    t1 = max(blankingNSamples) / sampleRate * 1e3;
    y1 = y(2);
    patch([t0, t1, t1, t0], [y0, y0, y1, y1], [0.8, 0.8, 0.8], 'FaceAlpha', 0.35, 'LineStyle', 'none');
end
end

