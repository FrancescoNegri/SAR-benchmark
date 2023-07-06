function extractBaselineSignal(path, baselineDuration, sampleRate, limits, graphicsObj)
%GENERATEBASELINESIGNAL Summary of this function goes here
%   Detailed explanation goes here

%% Check input parameters
if nargin < 4
    throw(MException('SFA:NotEnoughParameters', 'The parameters path, sampleRate, slidingWindowDuration, and limits are required.'));
end

if nargin < 5
    graphicsObj = false;
end

if ~isgraphics(graphicsObj, 'figure') && ~isgraphics(graphicsObj, 'tiledlayout')  && ~isgraphics(graphicsObj, 'axes') && graphicsObj ~= false && graphicsObj ~= true
    throw(MException('SFA:WrongTypeParameter', 'The parameter graphicsObj is not a figure, a tiledlayout or axes.'));
end

load(fullfile(path), 'data');

data = bandpass(data, [300, 7000], sampleRate);

t = 0:1/sampleRate:(length(data)/sampleRate - 1/sampleRate);

choice = 'Retry';

while strcmp(choice, 'Retry')
    prompt = {'Lower Limit', 'Upper Limit'};
    dlgtitle = 'Limits';
    dims = [1, 35];
    definput = {num2str(limits(1)), num2str(limits(2))};
    answer = inputdlg(prompt, dlgtitle, dims, definput);

    if isempty(answer)
        disp('Aborted.');
        return;
    end

    limits(1)   = str2double(answer{1});
    limits(2)   = str2double(answer{2});

    if graphicsObj ~= false
        if graphicsObj == true
            graphicsObj = figure();
        elseif isgraphics(graphicsObj, 'figure')
            figure(graphicsObj.Number)
        elseif isgraphics(graphicsObj, 'tiledlayout')
            nexttile();
        end
        
        cla(gca(), 'reset');
        hold('on');
        xlabel('Time (s)');
        ylabel('Voltage (\mu{V})');
        
        plot(t, data);
        plot(t, limits(1) * ones(size(data)), 'Color', 'r');
        plot(t, limits(2) * ones(size(data)), 'Color', 'r');
        hold('off');
    end
    
    choice = questdlg('Do you want to proceed?', 'Check', 'Yes', 'Retry', 'Exit', 'Exit');

    if strcmp(choice, 'Exit')
        disp('Aborted.');
        return;
    end
end

baselineNSamples = round(baselineDuration * sampleRate);

idxs = 1:length(data);
badIdxs = idxs(data < limits(1) | data > limits(2));
goodIdx = badIdxs(find(diff(badIdxs) >= baselineNSamples, 1)) + 1;

if isempty(goodIdx)
    disp('Not enough good samples found. Aborted.');
    return;
end

baseline = data((1:baselineNSamples) + goodIdx - 1);

if ~isempty(baseline) && graphicsObj ~= false
    x0 = goodIdx/sampleRate;
    x1 = x0 + baselineNSamples/sampleRate;
    y0 = limits(1);
    y1 = limits(2);
    patch([x0, x1, x1, x0], [y0, y0, y1, y1], [0, 0.8, 0], 'FaceAlpha', 0.4, 'LineStyle', 'none');
end

if ~isempty(baseline)
    pars = struct();
    pars.fs = sampleRate;
    pars.FilterLength   = 60;   % [ms] Length of the adaptive filter window
    pars.Polarity       = -1;   % polarity of the detection. If positive looks for positive crossings. Negative otherwise. 
    pars.MinThresh      = 35;   % [uV] Fixed minimum voltage threshold for detection;
    pars.MultCoeff      = 4.5;  % moltiplicative factor for the adaptive threshold (signal absolute median);
    pars.RefrTime       = 2;  % [ms] Refractory time. 
    pars.PeakDur        =  1;   % [ms] Peak duration or pulse lifetime period

    choice = 'Retry';

    while strcmp(choice, 'Retry')
        prompt = {'FilterLength', 'Polarity', 'MinThresh', 'MultCoeff', 'RefrTime', 'PeakDur'};
        dlgtitle = 'SD Parameters';
        dims = [1, 35];
        definput = {num2str(pars.FilterLength), num2str(pars.Polarity),...
            num2str(pars.MinThresh), num2str(pars.MultCoeff),...
            num2str(pars.RefrTime), num2str(pars.PeakDur)};
        answer = inputdlg(prompt, dlgtitle, dims, definput);

        if isempty(answer)
            disp('Aborted.');
            return;
        end

        pars.FilterLength   = str2double(answer{1});
        pars.Polarity       = str2double(answer{2});
        pars.MinThresh      = str2double(answer{3});
        pars.MultCoeff      = str2double(answer{4});
        pars.RefrTime       = str2double(answer{5});
        pars.PeakDur        = str2double(answer{6});

        [baselineSpikesIdxs, ~, ~, ~] = SD_AdaptThresh(baseline, pars);
        baselineSpikes = false(size(baseline));
        baselineSpikes(baselineSpikesIdxs) = true;
        
        figure();
        hold('on');
        xlabel('Time (s)');
        ylabel('Voltage (\mu{V})');
        t = 0:1/sampleRate:(length(baseline)/sampleRate - 1/sampleRate);
        plot(t, baseline);
        scatter(t(baselineSpikesIdxs), baseline(baselineSpikesIdxs));
        set(gcf,'Visible','on');
        uiwait(gcf);

        choice = questdlg('Are you satisfied with the current spike detection?', 'Saving', 'Yes', 'Retry', 'Exit', 'Exit');

        if strcmp(choice, 'Exit')
            disp('Aborted.');
            return;
        end
    end

    choice = questdlg('Do you want to save the current baseline data?', 'Saving', 'Yes', 'No', 'Yes');
    
    if strcmp(choice, 'Yes')
        outputPath = fullfile('./dataset/baselines');
        if ~exist(outputPath, 'dir')
            mkdir(outputPath);
        end

        baseline = struct('data', baseline);
        baseline.sampleRate = sampleRate;
        baseline.SD = struct();
        baseline.SD.spikeTrain = baselineSpikes;
        baseline.SD.params = pars;

        save(fullfile(outputPath, getRandomFilename(8)), 'baseline');
    end
end
end

