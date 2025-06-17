function [varargout] = plotEventPropMultiGroups(groupedEventProp, props, organizeStruct, varargin)
    % PLOTEVENTPROPMULTIGROUPS Plots and analyzes event properties for multiple pairs of groups.
    %
    % Inputs:
    %    - groupedEventProp: A structure array output by `extractAndGroupEvents`. Fields include:
    %        * group: String name of the group (e.g., experimental condition).
    %        * event_info: Structure array containing event data for the group.
    %        * animalNum, recNum, roiNum: Numeric fields indicating the number of animals,
    %          recordings, and regions of interest (ROIs), respectively, within each group.
    %    - props: Cell array of strings specifying the names of event properties to analyze.
    %      These correspond to field names within `groupedEventProp(n).event_info`.
    %    - organizeStruct: A structure array containing fields for configuring the analysis:
    %        * title: String used for figure and file naming.
    %        * keepGroups: Cell array of strings. Entries in `groupedEventProp(n).group` that match
    %          any of these strings will be retained for analysis. Recommended to keep two groups
    %          for GLMM analysis.
    %        * mmFixCat: String specifying the category used by GLMM for fixed effects in the model.
    %
    % Outputs:
    %    - saveDir: Directory where figures and tables are saved (if applicable).
    %    - organizeStruct: Updated `organizeStruct` with added data from the analysis.

    % Default parameters
    defaultColorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
                         '#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};
    tableFormatColumnAdjust = 'XXXXX'; % Define table column format string for maintainability.

    % Input parser
    p = inputParser;

    % Required inputs
    addRequired(p, 'groupedEventProp', @(x) isstruct(x) && ~isempty(x)); % Ensure non-empty structure.
    addRequired(p, 'props', @(x) iscell(x) && ~isempty(x)); % Ensure non-empty cell array.
    addRequired(p, 'organizeStruct', @(x) isstruct(x) && ~isempty(x)); % Ensure non-empty structure.

    % Optional parameters with default values
    addParameter(p, 'entryType', 'event', @ischar); % 'event' or 'roi', defining the type of data.
    addParameter(p, 'mmModel', 'GLMM', @ischar); % Mixed model type (e.g., GLMM).
    addParameter(p, 'mmDistribution', 'gamma', @ischar); % Distribution type for GLMM.
    addParameter(p, 'mmLink', 'log', @ischar); % Link function for GLMM.
    addParameter(p, 'mmHierarchicalVars', {'trialName', 'roiName'}, @iscell); % Hierarchical variables for GLMM.
    addParameter(p, 'saveFig', false, @islogical); % Whether to save figures.
    addParameter(p, 'saveDir', '', @ischar); % Directory for saving outputs.
    addParameter(p, 'debugMode', true, @islogical); % Enable debug mode for verbose output.

    % Parse inputs
    parse(p, groupedEventProp, props, organizeStruct, varargin{:});
    pars = p.Results;

    % Number of entries in organizeStruct
    entryNum = numel(pars.organizeStruct);

    % Loop through each entry in organizeStruct
    % This loop processes each group specified in organizeStruct:
    % 1. Filters `groupedEventProp` based on the `keepGroups` field to retain relevant groups for comparison.
    % 2. Assigns the filtered data back to `organizeStruct`.
    % 3. Calls `plotEventProp` to generate statistical analyses and plots (bar plots, violin plots, ECDFs, etc.).
    % 4. Creates and saves figures, tables, and statistical summaries (if saveFig is true).
    % 5. Updates `organizeStruct` with the processed results and data for each group.
    for en = 1:entryNum
        if pars.debugMode
            fprintf('Processing Group %d: %s\n', en, pars.organizeStruct(en).title);
        end

        % Assign color group, falling back to default if not provided
        if ~isfield(pars.organizeStruct, 'colorGroup') || isempty(pars.organizeStruct(en).colorGroup)
            colorGroup = defaultColorGroup;
        else
            colorGroup = pars.organizeStruct(en).colorGroup;
        end

        % Filter groupedEventProp based on keepGroups
        % `filter_entries_in_structure` uses `pars.organizeStruct(en).keepGroups` as keywords to filter and
        % retain specific groups from `pars.groupedEventProp`. The retained groups are then used for comparison and plotting.
        if ~isfield(pars.organizeStruct(en), 'keepGroups') || isempty(pars.organizeStruct(en).keepGroups)
            error('Missing or empty keepGroups field in organizeStruct for entry %d.', en);
        end
        groupedEventPropFiltered = filter_entries_in_structure(pars.groupedEventProp, 'group',...
            'tags_keep', pars.organizeStruct(en).keepGroups);

        % Store filtered data in organizeStruct
        pars.organizeStruct(en).data = groupedEventPropFiltered;

        % Analyze and plot event properties
        % `statInfo` contains the results of statistical analyses and plots generated by `plotEventProp`,
        % including bar plots, violin plots, ECDFs, and GLMM model outputs.
        statInfo = plotEventProp(pars.organizeStruct(en).data, pars.props, 'fnamePrefix', pars.organizeStruct(en).title,...
            'mmModel', pars.mmModel, 'mmGroup', pars.organizeStruct(en).mmFixCat,...
            'mmHierarchicalVars', pars.mmHierarchicalVars, 'mmDistribution', pars.mmDistribution, 'mmLink', pars.mmLink,...
            'saveFig', pars.saveFig, 'saveDir', pars.saveDir);

        % Create a UI table displaying n numbers
        fNumName = [pars.organizeStruct(en).title, ' nNumInfo'];
        [fNum, tabNum] = nNumberTab(pars.organizeStruct(en).data, pars.entryType, 'figName', fNumName);

        % Save outputs if saveFig is enabled
        if pars.saveFig
            % Save figure
            savePlot(fNum, 'guiSave', 'off', 'save_dir', pars.saveDir, 'fname', fNumName);

            % Save table in LaTeX format
            tabNumName = sprintf('%s nNumInfo.tex', pars.organizeStruct(en).title);
            tableToLatex(tabNum, 'saveToFile', true, 'filename',...
                fullfile(pars.saveDir, tabNumName), 'caption', tabNumName, 'columnAdjust', tableFormatColumnAdjust);

            % Save statistical information
            statInfoName = sprintf('%s statInfo', pars.organizeStruct(en).title);
            save(fullfile(pars.saveDir, statInfoName), 'statInfo');
        end
    end

    % Outputs
    varargout{1} = pars.saveDir;
    varargout{2} = pars.organizeStruct;
end
