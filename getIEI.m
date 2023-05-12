function IEI = getIEI(data, graphicsObj, nbins)
%GETIAI Summary of this function goes here
%   Detailed explanation goes here

    %% Check input parameters
    if nargin < 1
        throw(MException('SFA:NotEnoughParameters', 'The parameter data is required.'));
    end

    if nargin < 2
        graphicsObj = false;
    end

    if nargin < 3
        nbins = 100;
    end

    if ~isgraphics(graphicsObj, 'figure') && ~isgraphics(graphicsObj, 'tiledlayout')  && ~isgraphics(graphicsObj, 'axes') && graphicsObj ~= false && graphicsObj ~= true
        throw(MException('SFA:WrongTypeParameter', 'The parameter graphicsObj is not a figure, a tiledlayout or axes.'));
    end

    %% Compute IEI
    IEI = diff(data);
    
    %% Plot IEI
    if graphicsObj ~= false
        if graphicsObj == true
            figure();
        elseif isgraphics(graphicsObj, 'figure')
            figure(graphicsObj.Number)
        elseif isgraphics(graphicsObj, 'tiledlayout')
            nexttile();
        end

        histogram(IEI, nbins);
        title('Inter-Event-Interval');
        xlabel('Time between successive events (ms)');
        ylabel('# Events');
        box('off');
    end
end

