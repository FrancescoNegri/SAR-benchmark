function generateBaselineSignal(path, slidingWindowDuration, sampleRate, percentiles, graphicsObj)
%GENERATEBASELINESIGNAL Summary of this function goes here
%   Detailed explanation goes here

%% Check input parameters
if nargin < 4
    throw(MException('SFA:NotEnoughParameters', 'The parameters path, sampleRate, slidingWindowDuration, and percentiles are required.'));
end

if nargin < 5
    graphicsObj = false;
end

if ~isgraphics(graphicsObj, 'figure') && ~isgraphics(graphicsObj, 'tiledlayout')  && ~isgraphics(graphicsObj, 'axes') && graphicsObj ~= false && graphicsObj ~= true
    throw(MException('SFA:WrongTypeParameter', 'The parameter graphicsObj is not a figure, a tiledlayout or axes.'));
end

load(fullfile(path), 'data');

baselinePrc = prctile(data, percentiles);
t = 0:1/sampleRate:(length(data)/sampleRate - 1/sampleRate);

if graphicsObj ~= false
    if graphicsObj == true
        figure();
    elseif isgraphics(graphicsObj, 'figure')
        figure(graphicsObj.Number)
    elseif isgraphics(graphicsObj, 'tiledlayout')
        nexttile();
    end
    
    hold('on');
    xlabel('Time (s)');
    
    plot(t, data);
    plot(t, baselinePrc(1) * ones(size(data)), 'Color', 'r');
    plot(t, baselinePrc(2) * ones(size(data)), 'Color', 'r');
end

choice = questdlg('Do you want to proceed?', 'Check', 'Yes', 'No', 'Yes');

if strcmp(choice, 'Yes')
    dataFlag = true(size(data));
    dataFlag(data > baselinePrc(1) & data < baselinePrc(2)) = false;
    
    slidingWindow = 1:round(slidingWindowDuration * sampleRate);
    
    slidingOffset = 0;
    
    baseline = [];
    
    while slidingOffset + length(slidingWindow) < length(data)
        if sum(dataFlag(slidingOffset + slidingWindow)) > 0
            slidingOffset = slidingOffset + sampleRate;
        else
            baseline = data(slidingOffset + slidingWindow);
            break;
        end
    end
    
    if ~isempty(baseline) && graphicsObj ~= false
        x0 = slidingOffset/sampleRate;
        x1 = x0 + length(slidingWindow)/sampleRate;
        y0 = baselinePrc(1);
        y1 = baselinePrc(2);
        patch([x0, x1, x1, x0], [y0, y0, y1, y1], [0, 0.8, 0], 'FaceAlpha', 0.4, 'LineStyle', 'none');
    end
    
    if ~isempty(baseline)
        choice = questdlg('Do you want to save the current baseline data?', 'Saving', 'Yes', 'No', 'Yes');
        
        if strcmp(choice, 'Yes')
            outputPath = fullfile('./baselines');
            if ~exist(outputPath, 'dir')
                mkdir(outputPath);
            end
            
            save(fullfile(outputPath, getRandomFilename(8)), 'baseline');
        end
    end
end
end

