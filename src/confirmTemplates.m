function choice = confirmTemplates(templates, features, labels, sampleRate)
    global globalChoice;

    globalChoice = false;

    confirmDlg = uifigure('Name', 'Results', 'Position', [200, 500, 1350, 600]);
    set(confirmDlg,'Visible','on');
    
    templatesAxes = uiaxes(confirmDlg, 'Position', [20, 60, 760, 540]);
    clustersAxes = uiaxes(confirmDlg, 'Position', [790, 60, 540, 540]);

    saveBtn = uibutton(confirmDlg, 'Tag', 'save', 'Text', 'Save', 'Position', [20, 20, 640, 30], 'ButtonPushedFcn', @setAnswer);
    discardBtn = uibutton(confirmDlg, 'Tag', 'discard', 'Text', 'Discard', 'Position', [690, 20, 640, 30], 'ButtonPushedFcn', @setAnswer);
    
    progressDlg = uiprogressdlg(confirmDlg, 'Indeterminate', 'on', 'Title', 'Plotting data');
    plotTemplates(templatesAxes, templates, labels, sampleRate);
    plotClusters(clustersAxes, features, labels);
    delete(progressDlg);

    uiwait(confirmDlg);

    choice = globalChoice;

    clear global globalChoice;
end

function setAnswer(src, ~)
    global globalChoice;
    
    if strcmp(src.Tag, 'save')
        globalChoice = true;
    else
        globalChoice = false;
    end

    close(src.Parent);
end