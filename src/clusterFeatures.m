function [labels, varargout] = clusterFeatures(features, params)
    global globalParams;
    global globalLabels;
    global globalMetrics;
    global globalAxes;

    globalParams = params;

    clusterDlg = uifigure('Name', 'DBSCAN Clustering Parameters', 'Position', [200, 500, 1350, 600]);
    set(clusterDlg,'Visible','on');
    
    kDAxes = uiaxes(clusterDlg, 'Position', [240, 60, 540, 540]);
    clustersAxes = uiaxes(clusterDlg, 'Position', [790, 60, 540, 540]);
    globalAxes = struct('kD', kDAxes, 'clusters', clustersAxes);
    
    uilabel(clusterDlg, 'Text', 'MinPts:', 'Position', [20, 550, 125, 22]);
    uieditfield(clusterDlg, 'numeric', 'Tag', 'minpts', 'Value', globalParams.minpts, 'Position', [150, 546, 75, 30], 'ValueChangedFcn', {@updateParam, features});
    
    uilabel(clusterDlg, 'Text', 'Epsilon:', 'Position', [20, 500, 125, 22]);
    uieditfield(clusterDlg, 'numeric', 'Tag', 'epsilon', 'Value', globalParams.epsilon, 'Position', [150, 496, 75, 30], 'ValueChangedFcn', {@updateParam});

    uilabel(clusterDlg, 'Text', 'MinClusterSize:', 'Position', [20, 450, 125, 22]);
    uieditfield(clusterDlg, 'numeric', 'Tag', 'minClusterSize', 'Value', globalParams.minClusterSize, 'Position', [150, 446, 75, 30], 'ValueChangedFcn', {@updateParam});
    
    metricsPanel = uipanel(clusterDlg, 'Title', 'Metrics', 'Position', [20, 60, 205, 330]);
    uilabel(metricsPanel, 'Text', sprintf('Accepted clusters:\t-'), 'Position', [5, 280, 150, 22]);
    uilabel(metricsPanel, 'Text', sprintf('Rejected clusters:\t-'), 'Position', [5, 250, 150, 22]);
    uilabel(metricsPanel, 'Text', sprintf('Outliers:\t-'), 'Position', [5, 220, 150, 22]);

    clustersBtn = uibutton(clusterDlg, 'Tag', 'clustersBtn', 'Text', 'Cluster Data', 'Position', [20, 400, 205, 30], 'ButtonPushedFcn', {@clusterData, features, metricsPanel});
    okBtn = uibutton(clusterDlg, 'Tag', 'okBtn', 'Text', 'Ok', 'Position', [20, 20, 1310, 30], 'ButtonPushedFcn', @closeDialog);
    
    plotkD(features);
    clusterData(clustersBtn, [], features, false);
    set(clustersBtn, 'Enable', 'on');

    uiwait(clusterDlg);

    labels = globalLabels;
    varargout{1} = globalMetrics;
    varargout{2} = globalParams;

    clear global globalParams;
    clear global globalLabels;
    clear global globalMetrics;
    clear global globalAxes;
end

function updateParam(src, evt, varargin)
    global globalParams;
    globalParams.(evt.Source.Tag) = evt.Value;
    
    if strcmp(evt.Source.Tag, 'minpts')
        plotkD(varargin{1});
    end

    clustersBtn = src.Parent.Children(arrayfun(@(child) strcmp(child.Tag, 'clustersBtn'), src.Parent.Children));
    set(clustersBtn, 'Enable', 'on');
end

function closeDialog(src, ~)
    close(src.Parent);
end

function clusterData(src, ~, features, varargin)
    global globalParams;
    global globalLabels;
    global globalMetrics;
    global globalAxes;

    % Disable UI controls
    set(src, 'Enable', 'off');
    progressDlg = uiprogressdlg(src.Parent, 'Indeterminate', 'on', 'Title', 'Finding clusters');

    % Compute clusters
    globalLabels = struct();
    if varargin{1} ~= false
        globalLabels.all = dbscan(features, globalParams.epsilon, globalParams.minpts);
    else
        globalLabels.all = ones(size(features, 1), 1);
    end
    globalLabels.unique = unique(globalLabels.all(globalLabels.all ~= -1));
       
    % Compute metrics
    globalMetrics = struct();
    globalMetrics.nClusters = sum(globalLabels.unique ~= -1);
    globalMetrics.nArtifacts = size(features, 1);
    globalMetrics.nOutliers = sum(globalLabels.all == -1);

    globalLabels.accepted = arrayfun(@(label) logical(sum(globalLabels.all == label) >= globalParams.minClusterSize), globalLabels.unique);

    globalLabels.rejected = globalLabels.unique(~globalLabels.accepted); 
    globalLabels.accepted = globalLabels.unique(globalLabels.accepted);

    globalMetrics.nAcceptedClusters = numel(globalLabels.accepted);
    globalMetrics.nRejectedClusters = numel(globalLabels.rejected);

    if varargin{1} ~= false
        metricsPanel = varargin{1};

        metricsPanel.Children(3).Text = sprintf('Accepted clusters:\t%d/%d', globalMetrics.nAcceptedClusters, globalMetrics.nClusters);
        metricsPanel.Children(2).Text = sprintf('Rejected clusters:\t%d/%d', globalMetrics.nRejectedClusters, globalMetrics.nClusters);
        metricsPanel.Children(1).Text = sprintf('Outliers:\t%d/%d', globalMetrics.nOutliers, globalMetrics.nArtifacts);
    end

    % Plot clusters
    ax = globalAxes.clusters;
    [globalLabels.colors, ~, ~] = maxdistcolor(globalMetrics.nClusters, @sRGB_to_OKLab);
    
    plotClusters(ax, features, globalLabels);

    % Re-enable UI controls
    delete(progressDlg);
end

function plotkD(features)
    global globalParams;
    global globalAxes;

    kD = pdist2(features, features, 'euc','Smallest', globalParams.minpts);
    ax = globalAxes.kD;

    cla(ax, 'reset');
    plot(ax, sort(kD(end,:)));
    title(ax, 'k-distance Graph');
    xlabel(ax, sprintf('Points sorted with %d-th nearest distances', globalParams.minpts));
    ylabel(ax, sprintf('%d-th nearest distances', globalParams.minpts));
    grid(ax, 'on');
end

