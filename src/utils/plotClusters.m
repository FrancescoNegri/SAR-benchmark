function plotClusters(varargin)
    if isa(varargin{1},'matlab.graphics.axis.Axes')
        ax = varargin{1};
        features = varargin{2};
        labels = varargin{3};
    else
        figure();
        ax = gca();
        features = varargin{1};
        labels = varargin{2};
    end

    cla(ax, 'reset');
    hold(ax, 'on');
    title(ax, 'Clusters');
    xlabel(ax, 'Feature 1');
    ylabel(ax, 'Feature 2');
    gscatter(ax, features(labels.all == -1, 1), features(labels.all == -1, 2), labels.all(labels.all == -1), [0, 0, 0], 'x');
    gscatter(ax, features(labels.all ~= -1, 1), features(labels.all ~= -1, 2), labels.all(labels.all ~= -1), labels.colors);
    legend(ax, 'off');
end

