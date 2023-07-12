function plotTemplates(varargin)
    if isa(varargin{1},'matlab.graphics.axis.Axes')
        ax = varargin{1};
        templates = varargin{2};
        labels = varargin{3};
        sampleRate = varargin{4};
    else
        figure();
        ax = gca();
        templates = varargin{1};
        labels = varargin{2};
        sampleRate = varargin{3};
    end

    blankingPeriod = 1e-3;

    cla(ax, 'reset');
    hold(ax, 'on');
    title(ax, 'Templates')
    xlabel(ax, 'Time (ms)');
    ylabel(ax, 'Voltage (\mu{V})');

    t = 0:1/sampleRate:(size(templates, 2)/sampleRate - 1/sampleRate);

    for idx = 1:size(templates, 1)
        colorIdx = labels.accepted(idx);
        plot(ax, t * 1e3, templates(idx, :), 'Color', labels.colors(colorIdx, :));
    end

    if ~isempty(blankingPeriod)
        patch(ax, [0, blankingPeriod, blankingPeriod, 0] * 1e3, [min(ax.YTick), min(ax.YTick), max(ax.YTick), max(ax.YTick)], [0.8, 0.8, 0.8], 'FaceAlpha', 0.3, 'LineStyle', 'none');
    end
end

