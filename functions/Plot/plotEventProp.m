function [varargout] = plotEventProp(eventPropStruct, propNames, varargin)
    %PLOTEVENTPROP creates bar, violin, and cumulative distribution plot showing the difference
    % between/among various groups of events
    % Input: 
    %    - structure array including one or more event_info structures {event_info1, event_info2,...}
    % Output:
    %    - event frequency histogram
    %    - event interval variance histogram
    %    - event rise_time bar
    %    - event peak amplitude bar
    %    - event rise_time/peak scatter and correlation
    %    - event peak-slope scatter and correlation
    %    - event slope bar

    % Initialize input parser
    p = inputParser;
    addRequired(p, 'eventPropStruct', @(x) isstruct(x) || iscell(x));
    addRequired(p, 'propNames', @(x) iscell(x) && all(cellfun(@ischar, x)));
    addParameter(p, 'fnamePrefix', '', @(x) ischar(x) || isstring(x));
    addParameter(p, 'groupFieldName', 'groupTag', @(x) ischar(x) || isstring(x));
    addParameter(p, 'mmModel', '', @(x) any(validatestring(x, {'', 'LMM', 'GLMM'}))); % '': No MM model. 'LMM': Linear-Mixed-Model. 'GLMM': Generalized-Mixed_Model
    addParameter(p, 'mmGroup', 'subNuclei', @(x) ischar(x) || isstring(x)); % Input validation for mmGroup
    addParameter(p, 'mmHierarchicalVars', {'trialName', 'roiName'}, @(x) iscell(x) && all(cellfun(@ischar, x)));
    addParameter(p, 'mmDistribution', 'gamma', @(x) any(validatestring(x, {'gamma', 'normal', 'poisson'})));
    addParameter(p, 'mmLink', 'log', @(x) any(validatestring(x, {'log', 'identity', 'inverse'})));
    addParameter(p, 'saveFig', false, @(x) islogical(x));
    addParameter(p, 'saveDir', '', @(x) ischar(x) || isstring(x));
    % addParameter(p, 'GUIsave', true, @(x) islogical(x));
    addParameter(p, 'colorGroup', {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
        '#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'}, @(x) iscell(x) && all(cellfun(@ischar, x)));
    addParameter(p, 'CDlineWidth', 2, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'FontSize', 12, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'tileColNum', 4, @(x) isnumeric(x) && isscalar(x) && x > 0);
    addParameter(p, 'FontWeight', 'bold', @(x) any(validatestring(x, {'normal', 'bold', 'light'})));
    addParameter(p, 'TickAngle', 15, @(x) isnumeric(x) && isscalar(x));
    parse(p, eventPropStruct, propNames, varargin{:});

    % Extract values from the input parser object
    pars = p.Results;


    %% Setup figures for plotting
    propNum = numel(propNames); % Numbers of properties will be analyzed
    plotTypes = {'bars', 'violins', 'ECDFs'};
    figures = struct();
    tiledLayouts = struct();

    for i = 1:numel(plotTypes)
        plotType = plotTypes{i};
        figName = [pars.fnamePrefix, ' ', plotType];
        [figures.(plotType), fRowNum, fColNum] = fig_canvas(propNum, 'fig_name', figName);
        tiledLayouts.(plotType) = tiledlayout(figures.(plotType), ceil(propNum / fColNum), fColNum);
    end


    %% Loop through properties and plot
    % Concatenate the data from entries in eventPropStruct
    dataStruct = cat(1, [eventPropStruct.event_info]); % This can be used for barPlot directly
    dataGroupLabel = {dataStruct.(pars.groupFieldName)}; % Extract the group labels for every event
    stat.groups = {[eventPropStruct.group]}; % Record the group names for statistical comparison

    for i = 1:propNum
        for j = 1:numel(plotTypes)
            % Activate a bar ax 
            ax = nexttile(tiledLayouts.(plotTypes{j}));

            if strcmpi(plotTypes{j}, 'bars')
                % Create a bar plot
                barInfo = barPlotOfStructData(dataStruct, propNames{i}, pars.groupFieldName,...
                    'plotWhere', ax, 'titleStr', propNames{i});

                % Run Gerneralized Linear Mixed Model
                [~, ~, ~, ~, ~, stat.mixedModel.(propNames{i})] =...
                    mixed_model_analysis(dataStruct, propNames{i}, pars.mmGroup, pars.mmHierarchicalVars,...
                    'modelType', pars.mmModel,'distribution', pars.mmDistribution,'link', pars.mmLink,...
                    'groupVarType', 'categorical');

                % Save statatistic info: summary stat, GLMM results
                if pars.saveFig
                    % Create and save a latex table file for the (generalized) linear mixed model results
                    texFilenameLMM = sprintf('%s %s LMMmodelCompTab.tex',pars.fnamePrefix, propNames{i});
                    captionStrLMM = sprintf('%s %s %s', pars.fnamePrefix, propNames{i}, stat.mixedModel.(propNames{i}).modelInfoStr);
                    tableToLatex(stat.mixedModel.(propNames{i}).chiLRT, 'saveToFile',true,...
                        'filename', fullfile(pars.saveDir,texFilenameLMM), 'caption', captionStrLMM,...
                        'columnAdjust', 'cXccccccc');

                    % Create and save a latex table file for the summary stat
                    summaryStat = barInfo; % Assign the barInfo to a new var before modificaiton
                    fieldsToRemove = {'groupIDX', 'groupData', 'nNum'}; % Fields to be removed
                    summaryStat = rmfield(summaryStat, fieldsToRemove); % Remove the unwanted fields
                    summaryStatTab = struct2table(summaryStat); % Convert the structure to a table
                    texFilenameSummaryStat = sprintf('%s %s meanSemTab.tex', pars.fnamePrefix, propNames{i});
                    tableToLatex(summaryStatTab, 'saveToFile',true,'filename',...
                        fullfile(pars.saveDir,texFilenameSummaryStat), 'caption', texFilenameSummaryStat,...
                        'columnAdjust', 'XXXXX');
                end

            elseif strcmpi(plotTypes{j}, 'violins')
                % Collect data for the specified property
                dataArray = [dataStruct.(propNames{i})];

                % Create a violin plot
                violinplot(dataArray, dataGroupLabel);
                title(strrep(propNames{i}, '_', '-'));
            elseif strcmpi(plotTypes{j}, 'ECDFs')
                % Calculate and plot the empirical cumulative distribution function for every group
                hold on
                    for m = 1:numel(eventPropStruct)
                        stat.ecdf(m).group = eventPropStruct(m).group;
                        [stat.ecdf(m).function, stat.ecdf(m).x, stat.ecdf(m).confLow, stat.ecdf(m).confUp] = ...
                            ecdf([eventPropStruct(m).event_info.(propNames{i})]);

                        % Create CD plot
                        hStair(m) = stairs(ax, stat.ecdf(m).x, stat.ecdf(m).function,...
                        'color', pars.colorGroup{m}, 'LineWidth', pars.CDlineWidth);
                        labelsStair{m} = strrep(stat.ecdf(m).group, '_', '-');
                    end
                hold off
                legend(hStair, labelsStair, 'Location', 'best', 'FontSize', 10, 'FontWeight', 'bold');
                title(strrep(propNames{i}, '_', '-'));
            end

            % Stylize the ax
            set(ax, 'box', 'off', 'TickDir', 'out', 'FontSize', pars.FontSize, 'FontWeight', pars.FontWeight);
            xtickangle(pars.TickAngle);
        end
    end

    if pars.saveFig
        for i = 1:numel(plotTypes)
            saveDir = savePlot(figures.(plotTypes{i}),'guiSave', 'off', 'save_dir', pars.saveDir,...
                'fname', figures.(plotTypes{i}).Name);
        end
    end

    varargout{1} = stat;
end


