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
end

