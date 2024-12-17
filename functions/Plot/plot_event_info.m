function [varargout] = plot_event_info(event_info_struct,varargin)
    % Plot various event properties 
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

    % Parse input arguments using inputParser
    params = parse_inputs(varargin{:});

    if params.save_fig 
        params.save_dir = setup_save_directory(params.save_dir, params.GUIsave);
        if isempty(params.save_dir)
            varargout{1} = '';
            return;
        else
        	varargout{1} = params.save_dir;
        end
    end

    % Remove empty entries
    event_info_struct = remove_empty_entries(event_info_struct);

    % Determine parameter names based on data type
    parNames = determine_par_names(event_info_struct, params.parNames);

    % Generate plots and capture output data
    [bar_data, bar_stat] = plot_bars(event_info_struct, parNames, params);
    plot_cumulative_distributions(event_info_struct, parNames, params);


    % Collect plot data and statistics
    plot_info = collect_plot_info(bar_data, bar_stat);
    varargout{2} = plot_info;

    % Optionally save figures
    if params.save_fig
        save_all_figures(params.save_dir, params.fname_preffix);

        % Save the model comparison table in latex format
        save_all_LLM_modelCompTab(bar_stat, params.fname_preffix, params.save_dir);

        % % Save the fixEffects' values
        % save_all_fixEffectsTab(bar_stat, params.fname_preffix, params.save_dir);

        % Save the mean and sem in latex format
        save_all_mean_sem(bar_data, params.fname_preffix, params.save_dir);
    end
end

function params = parse_inputs(varargin)
    % Define default values
    defaultEntryType = 'event';
    defaultPlotCombinedData = false;
    defaultParNames = {'rise_duration','peak_mag_delta','peak_delta_norm_hpstd',...
        'peak_slope','peak_slope_norm_hpstd','baseDiff','baseDiff_stimWin'}; 
    defaultSaveFig = false;
    defaultSaveDir = '';
    defaultGUIsave = true;
    defaultSavePathNoGui = '';
    defaultFnamePreffix = '';
    defaultMmModel = ''; % '': Do not use MM model for analysis. 'LMM': Linear-Mixed-Model. 'GLMM': Generalized-Mixed_Model
    defaultMmGroup = 'subNuclei'; % Check the input 'hierarchicalVars' input in the function 'mixed_model_analysis' for more details
    defaultMmHierarchicalVars = {'trialName', 'roiName'}; % Check the input 'hierarchicalVars' input in the function 'mixed_model_analysis' for more details
    defaultMmDistribution = 'gamma'; % Check the input 'distribution' input in the function 'mixed_model_analysis' for more details
    defaultMmLink = 'log'; % Check the input 'link' input in the function 'mixed_model_analysis' for more details
    defaultStatFig = 'off';
    defaultColorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
        '#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};
    defaultFontSize = 12;
    defaultTileColNum = 4;
    defaultFontWeight = 'bold';
    defaultTickAngle = 15;

    % Create an input parser object
    p = inputParser;
    addParameter(p, 'entryType', defaultEntryType);
    addParameter(p, 'plot_combined_data', defaultPlotCombinedData);
    addParameter(p, 'parNames', defaultParNames);
    addParameter(p, 'save_fig', defaultSaveFig);
    addParameter(p, 'save_dir', defaultSaveDir);
    addParameter(p, 'GUIsave', defaultGUIsave);
    addParameter(p, 'savepath_nogui', defaultSavePathNoGui);
    addParameter(p, 'fname_preffix', defaultFnamePreffix);
    addParameter(p, 'mmModel', defaultMmModel);
    addParameter(p, 'mmGroup', defaultMmGroup);
    addParameter(p, 'mmHierarchicalVars', defaultMmHierarchicalVars);
    addParameter(p, 'mmDistribution', defaultMmDistribution);
    addParameter(p, 'mmLink', defaultMmLink);
    addParameter(p, 'stat_fig', defaultStatFig);
    addParameter(p, 'colorGroup', defaultColorGroup);
    addParameter(p, 'FontSize', defaultFontSize);
    addParameter(p, 'tileColNum', defaultTileColNum);
    addParameter(p, 'FontWeight', defaultFontWeight);
    addParameter(p, 'TickAngle', defaultTickAngle);
    parse(p, varargin{:});

    % Extract values from the input parser object
    params = p.Results;
end

function save_dir = setup_save_directory(save_dir, GUIsave)
    if GUIsave
        save_dir = uigetdir(save_dir, 'Choose a folder to save plots');
        if save_dir == 0
            error('Folder for saving plots not chosen. Choose one or set "save_fig" to false');
        end
    end
end

function event_info_struct = remove_empty_entries(event_info_struct)
    tf_empty = cellfun(@isempty, {event_info_struct.event_info});
    event_info_struct(tf_empty) = [];
end

function parNames = determine_par_names(event_info_struct, parNames)
    event_info_fieldnames = fieldnames(event_info_struct(1).event_info);
    mean_val_idx = find(contains(event_info_fieldnames, 'mean'));
    if ~isempty(mean_val_idx)
        for pn = 1:numel(parNames)
            idx_par = find(contains(event_info_fieldnames, parNames{pn})); 
            C = intersect(idx_par, mean_val_idx);
            if ~isempty(C)
                parNames{pn} = event_info_fieldnames{C};
            end
        end
    end
end

function [bar_data, bar_stat] = plot_bars(event_info_struct, parNames, params)
    bar_data = struct();
    bar_stat = struct();

    parNum = numel(parNames);

    [f_bar, f_rowNum, f_colNum] = fig_canvas(parNum, 'fig_name', [params.fname_preffix, ' bar plots']);
    f_stat = fig_canvas(parNum, 'fig_name', [params.fname_preffix, ' bar stat']);
    f_violin = fig_canvas(parNum, 'fig_name', [params.fname_preffix, ' violin plots']);

    tlo_bar = tiledlayout(f_bar, ceil(numel(parNames)/f_colNum), f_colNum);
    tlo_barstat = tiledlayout(f_stat, ceil(numel(parNames)/f_colNum)*2+1, f_colNum);
    tlo_violin = tiledlayout(f_violin, ceil(numel(parNames)/f_colNum), f_colNum);

    groupNames = {event_info_struct.group};

    for pn = 1:parNum
        par = parNames{pn};
        ax_bar = nexttile(tlo_bar);

        statTileLoc1 = floor(pn/f_colNum)*f_colNum+mod(pn,f_colNum)+f_colNum;
        statTileLoc2 = floor(pn/f_colNum)*f_colNum+mod(pn,f_colNum)+f_colNum*2;
        % statTileLoc = floor(pn/params.tileColNum)*params.tileColNum*2+pn+params.tileColNum;
        ax_stat1 = nexttile(tlo_barstat,statTileLoc1);
        ax_stat2 = nexttile(tlo_barstat,statTileLoc2);
        % ax_stat = nexttile(tlo_barstat,params.tileColNum+pn,[2 1]);

        if numel(event_info_struct) > 1
            [bar_data.(par), bar_stat.(par)] = plot_event_info_bar(event_info_struct, par, 'plotWhere', ax_bar,...
                'stat', true, 'stat_fig', params.stat_fig,...
                'mmModel', params.mmModel, 'mmGrouop', params.mmGroup, 'mmHierarchicalVars', params.mmHierarchicalVars,...
                'mmDistribution', params.mmDistribution, 'mmLink', params.mmLink,...
                'FontSize', params.FontSize,...
                'FontWeight', params.FontWeight);
            title(replace(par, '_', '-'));

            % Ensure the stat table is plotted within the correct figure context
            plot_stat_table(ax_stat1, ax_stat2, bar_stat.(par));
        end


        ax_violin = nexttile(tlo_violin);
        plot_violinplot(event_info_struct, par, groupNames, ax_violin, params);
    end

    % Collect the field names of bar_stat
    statParNames = fieldnames(bar_stat);

    % Ensure there are field names to access
    if ~isempty(statParNames)
        % Set the super title of the figure f_stat using the method field of the first bar_stat entry
        if ~isempty(params.mmModel)
            % Replace underscores with spaces
            ParNamesCombined = cellfun(@(x) strrep(x, '_', ' '), statParNames, 'UniformOutput', false);

            % Combine into one line separated with ' | '
            ParNamesCombined = strjoin(ParNamesCombined, ' | ');

            statTitleStr = sprintf('%s\n\n1. %s: Model comparison. no-fixed-effect vs fixed-effects\n[%s]\nVS\n[%s]\n\n2. %s analysis',...
                ParNamesCombined,params.mmModel,char(bar_stat.(statParNames{1}).chiLRT.Formula{1}),char(bar_stat.(statParNames{1}).chiLRT.Formula{2}),params.mmModel);
            statTitleStr = strrep(statTitleStr, '_', ' ');
            sgtitle(f_stat, statTitleStr);
            % sgtitle(f_stat, [params.mmModel, ' ', char(bar_stat.(statParNames{1}).method.Formula)]);
        else
            sgtitle(f_stat, bar_stat.(statParNames{1}).method);
        end
    end
end


function f = create_figure(name)
    f = figure('Name', name);
    fig_position = [0.1 0.1 0.8 0.4];
    set(f, 'Units', 'normalized', 'Position', fig_position);
end


function plot_stat_table(ax_stat1, ax_stat2, bar_stat)
    % Set the current figure to the one containing ax_stat1
    figure(ax_stat1.Parent.Parent);

    set(ax_stat1, 'XTickLabel', []);
    set(ax_stat1, 'YTickLabel', []);
    set(ax_stat2, 'XTickLabel', []);
    set(ax_stat2, 'YTickLabel', []);
    
    uit_pos1 = get(ax_stat1, 'Position');
    uit_unit1 = get(ax_stat1, 'Units');
    uit_pos2 = get(ax_stat2, 'Position');
    uit_unit2 = get(ax_stat2, 'Units');

    % Create the table in the correct figure and context
    if isfield(bar_stat, 'c')
        MultCom_stat = bar_stat.c(:, ["g1", "g2", "p", "h"]);
        uit = uitable('Data', table2cell(MultCom_stat), 'ColumnName', MultCom_stat.Properties.VariableNames,...
            'Units', uit_unit1, 'Position', uit_pos1);
    elseif isfield(bar_stat, 'fixedEffectsStats') && ~isempty(bar_stat.method) % if LMM or GLMM (mixed models) are used
        chiLRTCell = table2cell(bar_stat.chiLRT);
        chiLRTCell = convertCategoricalToChar(chiLRTCell);
        uit = uitable('Data', chiLRTCell, 'ColumnName', bar_stat.chiLRT.Properties.VariableNames,...
                    'Units', uit_unit1, 'Position', uit_pos1);

        fixedEffectsStatsCell = table2cell(bar_stat.fixedEffectsStats);
        fixedEffectsStatsCell = convertCategoricalToChar(fixedEffectsStatsCell);
        uit = uitable('Data', fixedEffectsStatsCell, 'ColumnName', bar_stat.fixedEffectsStats.Properties.VariableNames,...
                    'Units', uit_unit2, 'Position', uit_pos2);
    else
        uit = uitable('Data', ensureHorizontal(struct2cell(bar_stat)), 'ColumnName', fieldnames(bar_stat),...
            'Units', uit_unit1, 'Position', uit_pos1);
    end
    
    % Adjust table appearance
    jScroll = findjobj(uit);
    jTable = jScroll.getViewport.getView;
    jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
    drawnow;
end


function convertedCellArray = convertCategoricalToChar(cellArray)
    % Check and convert categorical or nominal data to char in a cell array
    convertedCellArray = cellArray;  % Copy the input cell array
    
    % Iterate through each element in the cell array
    for i = 1:numel(cellArray)
        % Check if the current element is categorical or nominal
        if iscategorical(cellArray{i}) || isa(cellArray{i}, 'nominal')
            % Convert to char
            convertedCellArray{i} = char(cellArray{i});
        end
    end
end


function plot_boxplot(event_info_struct, par, groupNames, ax_box, params)
    event_info_cell = cell(1, numel(event_info_struct));
    for gn = 1:numel(event_info_struct)
        event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
    end
    boxPlot_with_scatter(event_info_cell, 'groupNames', groupNames, 'plotWhere', ax_box, 'stat', true,...
        'FontSize', params.FontSize, 'FontWeight', params.FontWeight);
    title(replace(par, '_', '-'));
end

function plot_violinplot(event_info_struct, par, groupNames, ax_violin, params)
    event_info_cell = cell(1, numel(event_info_struct));
    for gn = 1:numel(event_info_struct)
        event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
    end
    [violinData, violinGroups] = createDataAndGroupNameArray(event_info_cell, groupNames);
    if ~isempty(violinData)
        violinplot(violinData, violinGroups);
        set(ax_violin, 'box', 'off', 'TickDir', 'out', 'FontSize', params.FontSize, 'FontWeight', params.FontWeight);
        xtickangle(params.TickAngle);
        title(replace(par, '_', '-'));
    end
end

function plot_cumulative_distributions(event_info_struct, parNames, params)
    figNameStr = sprintf('%s cumulative distribution plots', params.fname_preffix);
    [f_cd, f_rowNum, f_colNum] = fig_canvas(numel(parNames), 'fig_name', figNameStr);

    % f_cd = create_figure(figNameStr);
    tlo = tiledlayout(f_cd, ceil(numel(parNames)/f_colNum), f_colNum);

    for pn = 1:numel(parNames)
        par = parNames{pn};
        ax = nexttile(tlo);
        event_info_cell = cell(1, numel(event_info_struct));
        for gn = 1:numel(event_info_struct)
            event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
        end
        cumulative_distr_plot(event_info_cell, 'groupNames', {event_info_struct.group}, 'plotWhere', ax,...
            'plotCombine',false,'stat', true, 'colorGroup', params.colorGroup,...
            'FontSize', params.FontSize, 'FontWeight', params.FontWeight);
        title(replace(par, '_', '-'));
    end
end



function plot_info = collect_plot_info(bar_data, bar_stat)
    % Initialize plot_info struct
    plot_info = struct();

    if exist('bar_data', 'var')
        plot_info.dataStruct = bar_data;
        plot_info.statStruct= bar_stat;
    end
end


function save_all_figures(save_dir, fname_preffix)
    figs = findall(0, 'Type', 'figure');
    for i = 1:length(figs)
        fname = sprintf('%s', figs(i).Name);
        savePlot(figs(i), 'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);
    end
end

function save_all_LLM_modelCompTab(bar_stat, namePrefix, saveDir)
    paramNames = fieldnames(bar_stat);

    for n = 1:numel(paramNames)
        texFilename = sprintf('%s %s modelCompTab.tex',namePrefix, paramNames{n});
        captionStr = sprintf('%s %s %s', namePrefix, paramNames{n}, bar_stat.(paramNames{n}).modelInfoStr);

        tableToLatex(bar_stat.(paramNames{n}).chiLRT, 'saveToFile',true,'filename',...
            fullfile(saveDir,texFilename), 'caption', captionStr,...
            'columnAdjust', 'cXccccccc');
    end
end

function save_all_fixEffectsTab(bar_stat, namePrefix, saveDir)
    paramNames = fieldnames(bar_stat);

    for n = 1:numel(paramNames)
        texFilename = sprintf('%s %s fullModelFixEffectsTab.tex', namePrefix, paramNames{n});
        tableToLatex(bar_stat.(paramNames{n}).fixedEffectsStats, 'saveToFile',true,'filename',...
            fullfile(saveDir,texFilename), 'caption', texFilename);
    end
end

function save_all_mean_sem(bar_data, namePrefix, saveDir);
    paramNames = fieldnames(bar_data);

    for n = 1:numel(paramNames)
        dataStruct = bar_data.(paramNames{n});

        % Extract the fields from the structure
        groupData = {dataStruct.group}';  % Transpose to make it a column vector
        meanData = [dataStruct.mean_value]';
        medianData = [dataStruct.medianVal]';
        stdData = [dataStruct.std]';
        steData = [dataStruct.ste]';

        % Create a table
        T = table(groupData, meanData, medianData, stdData, steData, ...
                  'VariableNames', {'Group', 'Mean', 'Median', 'STD', 'SEM'});

        texFilename = sprintf('%s %s meanSemTab.tex', namePrefix, paramNames{n});
        tableToLatex(T, 'saveToFile',true,'filename',...
            fullfile(saveDir,texFilename), 'caption', texFilename,...
            'columnAdjust', 'XXXXX');
    end
end

