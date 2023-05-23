function generateTemplates(tankObj, animalName, blockIdx, channelIdx, nTemplates, graphicsObj)
%GENERATETEMPLATES Summary of this function goes here
%   Detailed explanation goes here

%% Check input parameters
if nargin < 4
    throw(MException('SFA:NotEnoughParameters', 'The parameters tankObj, animalName, blockIdx and channelIdx are required.'));
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

%% Retrieve Animal, Block and Channel objects
animalObj = getChildObj(tankObj, animalName);
blockObj = getChildObj(animalObj, blockIdx);

data = blockObj{'raw', channelIdx, :};
data = data{1};

%% Load and process stimulation data
[stim, blankingNSamples] = getStim(blockObj);
blankingNSamples = blankingNSamples + 5; % Arbitrary increase in the computed blanking window

stim = round(stim * blockObj.SampleRate);
IAI = getIEI(stim);

%% Compute the baseline
[~, baselinePercentiles] = getBaselineFromStim(data, stim, blockObj.SampleRate, 10e-3, 0.5e-3, [25, 75]);
baselineBottom = baselinePercentiles(1);
baselineTop = baselinePercentiles(end);

%% Compute duration for each stimulus
selectedStim = false(1, length(stim));
stimNSamples = zeros(1, length(stim));

searchingWindow = 3e-3;
searchingSamples = 1:round(searchingWindow * blockObj.SampleRate);

for idx=1:length(stim)-1
    flag = false;
    searchingOffset = blankingNSamples(idx);
    
    while flag == false
        searchingVector = data(stim(idx) + searchingSamples - 1 + searchingOffset);
        
        if median(searchingVector) > baselineBottom && median(searchingVector) < baselineTop
            flag = true;
        else
            searchingOffset = searchingOffset + 1;
        end
    end
    
    searchingOffset = searchingOffset + length(searchingSamples);
    
    if searchingOffset < IAI(idx)
        selectedStim(idx) = true;
        stimNSamples(idx) = searchingOffset;
    end
end

stim = stim(selectedStim);
stimNSamples = stimNSamples(selectedStim);

outputPath = fullfile('./templates');
if ~exist(outputPath, 'dir')
    mkdir(outputPath);
end

outputPath = fullfile('./templates', strcat(tankObj.Name, '_', animalObj.Name ,'_B', num2str(blockIdx), '_C', num2str(channelIdx)));
if ~exist(outputPath, 'dir')
    mkdir(outputPath);
end

save(fullfile(outputPath, '.stim.mat'), 'stim');

%% Isolate, smooth, plot and save templates
paddingBefore = 100;
paddingAfter = 100;
smoothingFrequency = 100;

permIdxs = randperm(length(stim));
stim = stim(permIdxs);
stimNSamples = stimNSamples(permIdxs);

if graphicsObj ~= false
    if graphicsObj == true
        figure();
    elseif isgraphics(graphicsObj, 'figure')
        figure(graphicsObj.Number)
    elseif isgraphics(graphicsObj, 'tiledlayout')
        nexttile();
    end
    
    hold('on');
    title(channelIdx);
    xlabel('Time (ms)');
    ylabel('Voltage (\mu{V})');
end

if nTemplates == false
    nTemplates = length(stim);
end

for idx=1:nTemplates
    stimSamples = (1:(paddingBefore+stimNSamples(idx)+paddingAfter)) - paddingBefore;
    
    stimSamples = stim(idx) + stimSamples - 1;
    template = data(stimSamples);
    template((paddingBefore+stimNSamples(idx))+1:end) = flip(template(((paddingBefore+stimNSamples(idx))+1:end) - paddingAfter));
    
    smoothedTemplate = lowpass(template, smoothingFrequency, blockObj.SampleRate);
    smoothedTemplate = smoothedTemplate((1:stimNSamples(idx)) + paddingBefore);
    
    stimSamples = 1:stimNSamples(idx);
    smoothedTemplate(1:blankingNSamples) = template((1:blankingNSamples) + paddingBefore);    % Restore the stimulation shape, preserving the smoothed artifact
    template = smoothedTemplate;
    
    hm = hamming(2*(length(template) - blankingNSamples(idx)));
    hm = hm((end/2 + 1):end);
    template((blankingNSamples + 1):end) = template((blankingNSamples + 1):end) .* hm';
    
    if graphicsObj ~= false
        plot((0:1/blockObj.SampleRate:(stimSamples(end)/blockObj.SampleRate - 1/blockObj.SampleRate))*1e3, template);
    end
    
    save(fullfile(outputPath, getRandomFilename(8)), 'template');
end

if graphicsObj ~= false
    t0 = 0;
    y = ylim;
    y0 = y(1);
    t1 = max(blankingNSamples) / blockObj.SampleRate * 1e3;
    y1 = y(2);
    patch([t0, t1, t1, t0], [y0, y0, y1, y1], [0.8, 0.8, 0.8], 'FaceAlpha', 0.35, 'LineStyle', 'none');
end
end

