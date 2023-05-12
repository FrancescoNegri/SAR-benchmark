function generateTemplates(tankObj, animalName, blockIdx, channelIdx, maxStimDuration, nTemplates, isBlanked, graphicsObj)
%GENERATETEMPLATES Summary of this function goes here
%   Detailed explanation goes here
    
    %% Check input parameters
    if nargin < 4
        throw(MException('SFA:NotEnoughParameters', 'The parameters tankObj, animalName, blockIdx and channelIdx are required.'));
    end

    if nargin < 5
        maxStimDuration = 25e-3;
    end

    if nargin < 6
        nTemplates = false;
    end

    if nargin < 7
        isBlanked = false;
    end

    if nargin < 8
        graphicsObj = false;
    end

    if ~isgraphics(graphicsObj, 'figure') && ~isgraphics(graphicsObj, 'tiledlayout')  && ~isgraphics(graphicsObj, 'axes') && graphicsObj ~= false && graphicsObj ~= true
        throw(MException('SFA:WrongTypeParameter', 'The parameter graphicsObj is not a figure, a tiledlayout or axes.'));
    end
    
    %% Retrieve Animal, Block and Channel objects
    animalObj = '';

    for idx=1:length(tankObj.Children)
        if strcmp(tankObj.Children(idx).Name, animalName)
            animalObj = tankObj.Children(idx);
        end
    end
    
    if isempty(animalObj)
        throw(MException('SFA:AnimalNotFound', sprintf('No animal with the specified name: %s', animalName)));
    end
    
    blockObj = animalObj.Children(blockIdx);
    
    data = blockObj{'raw', channelIdx, :};
    data = data{1};

    %% Load and process stimulation data
    stimPath = fullfile(blockObj.Output, blockObj.Name, 'StimData', 'Stim_Stim_Events.mat');
    stim = load(stimPath);
    stim = stim.data(2:end, :);
    
    blankingNSamples = stim(:, 11);
    stimChannelId = unique(stim(:, 2));
    
    if length(stimChannelId) > 1
        stimChannelId = stimChannelId(1);
        warning('SFA:MultipleStimulatedChannels', 'There are multiple channels which are stimulated. Selected channel: %d', stimChannelId);
    end
    
    IAI = getIEI(stim(stim(:, 2) == stimChannelId, 4));
    
    stim = round(stim(stim(:, 2) == stimChannelId, 4) * blockObj.SampleRate);

    %% Isolate, plot and save templates
    outputPath = fullfile('./templates', strcat(tankObj.Name, '_', animalObj.Name ,'_B', num2str(blockIdx), '_C', num2str(channelIdx)));
    if ~exist(outputPath, 'dir')
        mkdir(outputPath);
    end
    
    save(fullfile(outputPath, 'stim'), 'stim');
    stim = stim(randperm(length(stim)));

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
    end
    
    if nTemplates == false
        nTemplates = length(stim);
    end
    
    for idx=1:nTemplates
        stimDuration = maxStimDuration;
    
        if idx < length(IAI) && IAI(idx) < maxStimDuration
                stimDuration = IAI(idx);
        end

        if isBlanked
            stimSamples = blankingNSamples(idx):round(stimDuration * blockObj.SampleRate);
        else
            stimSamples = 1:round(stimDuration * blockObj.SampleRate);
        end

        template = data(stim(idx) + stimSamples);
        
        if graphicsObj ~= false
            plot(stimSamples ./ blockObj.SampleRate * 1e3, template);
        end

        save(fullfile(outputPath, getRandomFilename(8)), 'template');
    end
end

