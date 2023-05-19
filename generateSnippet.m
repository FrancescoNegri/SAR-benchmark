function generateSnippet(snippetDuration, sampleRate, graphicsObj)
%GENERATESNIPPET Summary of this function goes here
%   Detailed explanation goes here

%% Check input parameters
if nargin < 2
    throw(MException('SFA:NotEnoughParameters', 'The parameters snippetDuration and sampleRate are required.'));
end

if nargin < 3
    graphicsObj = false;
end

if ~isgraphics(graphicsObj, 'figure') && ~isgraphics(graphicsObj, 'tiledlayout')  && ~isgraphics(graphicsObj, 'axes') && graphicsObj ~= false && graphicsObj ~= true
    throw(MException('SFA:WrongTypeParameter', 'The parameter graphicsObj is not a figure, a tiledlayout or axes.'));
end

%% Pick a random template folder and load the stimulation file
dirList = dir(fullfile('./templates'));
dirList = dirList(3:end);

dirIdx = randi([1, length(dirList)]);
folder = fullfile(dirList(dirIdx).folder, dirList(dirIdx).name);
fprintf('Selected templates folder: %s\n', dirList(dirIdx).name);

templateList = dir(fullfile(folder));
templateList = templateList(4:end);     % Avoid .stim.mat file as well

load(fullfile(folder, '.stim.mat'), 'stim');

%% Generate the stimulation train according to the original distribution of stimuli
IAI = getIEI(stim);

t = 1:max(IAI);
cumulativeDistribution = cdf(fitdist(IAI, 'Gamma'), t);

snippet = zeros(1, round(snippetDuration * sampleRate));

meanStimulationRate = length(find(stim < length(snippet))) / snippetDuration;
snippetStim = rand(1, round(2 * meanStimulationRate * snippetDuration));
snippetStim = interp1(cumulativeDistribution, cumulativeDistribution, snippetStim, 'nearest');
idxs = arrayfun(@(x)find(cumulativeDistribution==x, 1), snippetStim);
snippetStim = cumsum(t(idxs));

snippetStim = snippetStim(snippetStim < length(snippet));
snippetStim = snippetStim(1:end-1);

%% Load a random template for each stimulus
for idx = 1:length(snippetStim)
    templateIdx = randi([1, length(templateList)]);
    load(fullfile(folder, templateList(templateIdx).name), 'template');
    
    snippet((1:length(template)) + snippetStim(idx)) = template;
end

%% Pick a random baseline signal load it
baselineList = dir(fullfile('./baselines'));
baselineList = baselineList(3:end);

baselineIdx = randi([1, length(baselineList)]);
fprintf('Selected baseline: %s\n', baselineList(baselineIdx).name);

load(fullfile(baselineList(baselineIdx).folder, baselineList(baselineIdx).name), 'baseline');

snippet = snippet + baseline;

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
    
    plot(0:1/sampleRate:(snippetDuration - 1/sampleRate), snippet);
end

outputPath = fullfile('./snippets');
if ~exist(outputPath, 'dir')
    mkdir(outputPath);
end

%% Save the snippet
snippet = struct('data', snippet, 'baseline', baseline, 'stim', snippetStim);

choice = questdlg('Do you want to save the current snippet?', 'Saving', 'Yes', 'No', 'Yes');

if strcmp(choice, 'Yes')
    outputPath = fullfile('./snippets');
    if ~exist(outputPath, 'dir')
        mkdir(outputPath);
    end
    
    save(fullfile(outputPath, getRandomFilename(8)), 'snippet');
end

end

