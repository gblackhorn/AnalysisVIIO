function [grouped_event_info, varargout] = group_event_info_multi_category(event_info, varargin)
%GROUP_EVENT_INFO_MULTI_CATEGORY Groups event information based on multiple categories.
%   This function organizes a struct array `event_info` into groups based on specified
%   categories. When multiple categories are provided, it performs hierarchical grouping.
%
%   USAGE:
%       [grouped_event_info, options] = group_event_info_multi_category(event_info, ...
%           'category_names', {'mouseID', 'stimID'}, 'filter_field', {'freq'}, 'filter_par', {[0, 10]})
%
%   INPUT:
%       event_info      : Struct array containing event information.
%
%   OPTIONAL PARAMETERS:
%       'category_names': Cell array specifying category names to group by, e.g., {'mouseID', 'stimID'}.
%       'filter_field'  : Cell array of field names to apply filters.
%       'filter_par'    : Cell array of filter thresholds, e.g., {[0, 10]}.
%       'debugMode'     : Logical flag to enable detailed debugging output (default: false).
%
%   OUTPUT:
%       grouped_event_info : Struct array grouped by categories.
%       options            : Struct containing the input parameters for reference.
%
%   EXAMPLE:
%       event_info(1).mouseID = 1; event_info(1).stimID = 'A';
%       event_info(2).mouseID = 2; event_info(2).stimID = 'B';
%       [groups, opts] = group_event_info_multi_category(event_info, 'category_names', {'mouseID'});
%       disp(groups)

    % Create an input parser object
    p = inputParser;
    addRequired(p, 'event_info', @(x) isstruct(x));
    addParameter(p, 'category_names', {}, @iscell);
    addParameter(p, 'filter_field', {}, @iscell);
    addParameter(p, 'filter_par', {}, @iscell);
    addParameter(p, 'debugMode', false, @(x) islogical(x) || isnumeric(x));
    parse(p, event_info, varargin{:});

    % Assign input parameters
    category_names = p.Results.category_names;
    filter_field = p.Results.filter_field;
    filter_par = p.Results.filter_par;
    debugMode = p.Results.debugMode;

    if isempty(category_names)
        error('No category names provided. Specify at least one category for grouping.');
    end

    % Initialize variables for hierarchical grouping
    category_num = numel(category_names);
    grouped_event_info_temp = cell(category_num, 1);

    for cn = 1:category_num
        if debugMode
            fprintf('Processing Category %d/%d: %s\n', cn, category_num, category_names{cn});
        end

        % First-level grouping
        if cn == 1
            grouped_event_info_temp{cn} = group_single_category(event_info, category_names{cn}, filter_field, filter_par, '', debugMode);
        else
            % For subsequent levels, subgroup using the previous group
            prev_group = grouped_event_info_temp{cn-1};
            new_groups = [];
            for i = 1:numel(prev_group)
                name_prefix = prev_group(i).group;
                subgroup_event_info = prev_group(i).event_info;
                new_groups = [new_groups, group_single_category(subgroup_event_info, category_names{cn}, {}, {}, name_prefix, debugMode)];
            end
            grouped_event_info_temp{cn} = new_groups;
        end
    end

    % Final output
    grouped_event_info = grouped_event_info_temp{end};
    varargout{1}.category_names = category_names;
    varargout{1}.filter_field = filter_field;
    varargout{1}.filter_par = filter_par;
end

function grouped_event_info = group_single_category(event_info, category_name, filter_field, filter_par, groupname_prefix, debugMode)
%GROUP_SINGLE_CATEGORY Filters and groups event_info by a single category.
    
    % Apply filters if specified
    if ~isempty(filter_field)
        event_info = filter_struct(event_info, filter_field, filter_par);
    end

    % Extract unique category values
    catContent = {event_info.(category_name)};
    if isCellArrayNumericOrLogical(catContent)
        catContent = cellfun(@(x) num2str(x), catContent, 'UniformOutput', false);
    end

    % Handle 'type' field conversion from '0'/'1' to 'asynch'/'synch'
    if strcmp(category_name, 'type')
        catContent = strrep(catContent, '0', 'single');
        catContent = strrep(catContent, '1', 'cluster');
    end

    % Sort unique values numerically or lexicographically
    catContentUnique = unique(catContent);
    if all(cellfun(@(x) ~isnan(str2double(x)), catContentUnique))
        % Sort numerically if all values can be converted to numbers
        [~, sortIdx] = sort(str2double(catContentUnique));
        catContentUnique = catContentUnique(sortIdx);
    else
        % Lexicographical sorting for strings
        catContentUnique = sort(catContentUnique);
    end

    % Initialize grouped structure
    grouped_event_info = struct([]);

    % Group data by unique category values
    for n = 1:numel(catContentUnique)
        groupChar = catContentUnique{n};
        if isempty(groupname_prefix)
            groupname = groupChar;
        else
            groupname = [groupname_prefix, '-', groupChar];
        end

        idx = strcmpi(catContent, groupChar);
        grouped_event_info(n).group = groupname;
        grouped_event_info(n).event_info = event_info(idx);
        grouped_event_info(n).tag = groupChar;

        if debugMode
            fprintf('  Group: %s, Events: %d\n', groupname, sum(idx));
        end
    end
end


% function [grouped_event_info, varargout] = group_event_info_multi_category(event_info, varargin)
%     % Group event info with given category_names.
%     % For example: fovID, mouseID, stim, etc.
%     % Note: when multiple category_names are given, event_info will be sorted in a nested way according to
%     % the order of category_names.

%     % Create an input parser object
%     p = inputParser;

%     % Required input validation
%     addRequired(p, 'event_info', @(x) isstruct(x));

%     % Add optional parameters with default values and validation
%     addParameter(p, 'category_names', {}, @iscell);  % Default: empty cell array
%     addParameter(p, 'filter_field', {}, @iscell);    % Default: empty cell array
%     addParameter(p, 'filter_par', {}, @iscell);                   % Default: empty cell array
%     addParameter(p, 'debugMode', false, @(x) islogical(x) || isnumeric(x)); % Default: false

%     % Parse the inputs
%     parse(p, event_info, varargin{:});

%     % Assign the parsed inputs to variables
%     event_info = p.Results.event_info;
%     category_names = p.Results.category_names;
%     filter_field = p.Results.filter_field;
%     filter_par = p.Results.filter_par;
%     debugMode = p.Results.debugMode;



%     %% Main content
%     % filter data

%     event_info_fieldnames = fieldnames(event_info);

    
%     if ~isempty(category_names)
%         category_num = numel(category_names);
%     	% group_cat_info = struct('g_name', cell(category_num, 1), 'g_content_unique', cell(category_num, 1);

%         grouped_event_info_temp = cell(category_num, 1); % each cell contains grouped info using "cn" categories  
%         group_tags = cell(category_num, 1);
%     	for cn = 1:category_num 
%             if debugMode
%                 fprintf('Category %d/%d\n', cn, category_num)
%                 if cn == 3
%                     pause
%                 end
%             end
%     		if cn == 1 % first level group
%     			[grouped_event_info_temp{cn},~,group_tags{cn}] = group_event_info_single_category(event_info, category_names{cn},...
%     				'filter_field', filter_field, 'filter_par', filter_par);
%             else % for the 2nd and more levels of group. Visit parent group and creat new groups from there
%                 % group_names_prev = fieldnames(grouped_event_info_temp{cn-1});
%                 group_num_prev = numel(grouped_event_info_temp{cn-1});

%                 new_group_cell = cell(group_num_prev, 1);
%                 for np = 1:group_num_prev
%                     group = grouped_event_info_temp{cn-1};
%                     name_prefix = group(np).group;
%                     event_info = group(np).event_info;
%                     % group_event_info = grouped_event_info_temp{cn-1}.(group_names_prev{np});
%                     [new_group_cell{np},~,tags] = group_event_info_single_category(event_info, category_names{cn},...
%                         'groupname_prefix', name_prefix);
%                 end
%                 grouped_event_info_temp{cn} = [new_group_cell{:}];
%                 group_tags{cn} = tags;
%             end
%     	end
%         grouped_event_info = grouped_event_info_temp{category_num};
%         grouped_event_info_option.category_names = category_names;
%         grouped_event_info_option.filter_field = filter_field;
%         grouped_event_info_option.filter_par = filter_par;

%         varargout{1} = grouped_event_info_option;
%     end
% end
