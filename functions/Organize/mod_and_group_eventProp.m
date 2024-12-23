function [grouped_event, grouped_event_setting, varargout] = mod_and_group_eventProp(eventProp_all, eventType, adataSetting, varargin)
    % Modify and group event properties from the provided data structure.
    %
    % Inputs:
    %   eventProp_all: Struct array containing event properties.
    %   eventType: 'event' or 'roi'. Specifies the type of event entry.
    %   adataSetting: Struct containing settings for aligned data.
    %
    % Optional Parameters:
    %   - 'separateSpon' (logical): Separate spontaneous events by stimulation. Default: false.
    %   - 'discardSpon' (logical): Discard spontaneous events. Default: false.
    %   - 'modifyEventTypeName' (logical): Modify event type names. Default: true.
    %   - 'groupField' (cell): Fields used for grouping events. Default: {'peak_category'}.
    %   - 'markEXog' (logical): Rename OG stimulation events based on triggering. Default: false.
    %   - 'ogTags' (cell): Tags to identify OG events. Default: {'og', 'og-ap'}.
    %   - 'sortOrder' (cell): Sort order for grouping. Default: {'spon', 'trig', 'rebound', 'delay'}.
    %   - 'sortOrderPlus' (cell): Additional sort keys. Default: {'ap', 'EXopto'}.
    %   - 'debugMode' (logical): Enable debug information. Default: true.
    %
    % Outputs:
    %   grouped_event: Grouped events based on the provided settings.
    %   grouped_event_setting: Settings used for grouping.
    %
    % Example:
    %   [grouped_event, grouped_event_setting] = mod_and_group_eventProp(eventProp, 'event', adataSetting, ...
    %           'groupField', {'stim_name'}, 'debugMode', true);

    %% Input Parsing
    p = inputParser;

    % Define default values for optional inputs
    addParameter(p, 'separateSpon', false, @islogical);
    addParameter(p, 'discardSpon', false, @islogical);
    addParameter(p, 'modifyEventTypeName', true, @islogical);
    addParameter(p, 'groupField', {'peak_category'}, @iscell);
    addParameter(p, 'markEXog', false, @islogical);
    addParameter(p, 'ogTags', {'og', 'og-ap'}, @iscell);
    addParameter(p, 'sortOrder', {'spon', 'trig', 'rebound', 'delay'}, @iscell);
    addParameter(p, 'sortOrderPlus', {'ap', 'EXopto'}, @iscell);
    addParameter(p, 'debugMode', true, @islogical);

    % Parse input arguments
    parse(p, varargin{:});
    
    % Assign parsed inputs to variables
    separateSpon = p.Results.separateSpon;
    discardSpon = p.Results.discardSpon;
    modifyEventTypeName = p.Results.modifyEventTypeName;
    groupField = p.Results.groupField;
    markEXog = p.Results.markEXog;
    ogTags = p.Results.ogTags;
    sortOrder = p.Results.sortOrder;
    sortOrderPlus = p.Results.sortOrderPlus;
    debugMode = p.Results.debugMode;

    %% Main Processing
    % % Filter spontaneous events for 'roi' type if 'sponOnly' is true
    % if strcmp(eventType, 'roi') && discardSpon
    %     eventProp_all = filter_structData(eventProp_all, 'peak_category', 'spon', 0);
    % end

    % Rename OG-triggered events if markEXog is enabled
    if markEXog
        eventProp_all = mark_EXog_events(eventProp_all, ogTags, debugMode);
    end

    % Normalize event properties
    eventProp_all_norm = norm_eventProp_with_spon(eventProp_all, ...
        'entry', eventType, 'discardSpon', discardSpon);

    % Modify event type names if enabled
    if modifyEventTypeName
        eventProp_all_norm = mod_cat_name(eventProp_all_norm, ...
            'dis_extra', true, 'separateSpon', separateSpon);
    end

    % Group events based on specified fields
    [grouped_event, grouped_event_setting] = group_event_info_multi_category(eventProp_all_norm, ...
        'category_names', groupField, 'debugMode', debugMode);

    % Add n numbers
    for gn = 1:numel(grouped_event)
        group_name = grouped_event(gn).group;
        if debugMode
            fprintf('[mod_and_group_eventProp] group (%d/%d): %s\n',gn,numel(grouped_event),group_name);
            if gn == 3
                pause
            end
        end
        % [grouped_event(gn).numTrial,grouped_event(gn).numRoi,grouped_event(gn).numRoiVec] = get_num_fieldUniqueContent(grouped_event(gn).event_info,...
        %     'fn_1', 'trialName', 'fn_2', 'roiName');
        [TrialRoiList,recNum,animalNum,roiNum] = get_roiNum_from_eventProp(grouped_event(gn).event_info);
        grouped_event(gn).animalNum = animalNum;
        grouped_event(gn).recNum = recNum;
        grouped_event(gn).roiNum = roiNum;
        grouped_event(gn).TrialRoiList = TrialRoiList;

        if strcmp(eventType,'roi') && ~contains(group_name,'spon') && ~contains(group_name,'varied')
            [grouped_event(gn).eventPb,grouped_event(gn).eventPbList] = analyze_roi_event_possibility(grouped_event(gn).event_info,'debug_mode',debugMode);
        end
    end

    % Sort groups based on sortOrder and sortOrderPlus
    grouped_event = sort_struct_with_str(grouped_event, 'group', sortOrder, ...
        'strCells_plus', sortOrderPlus);

    grouped_event_setting.event_type = eventType;

    % Include aligned data settings if provided
    if ~isempty(adataSetting)
        grouped_event_setting.traceData_type = adataSetting.traceData_type;
        grouped_event_setting.event_data_group = adataSetting.event_data_group;
        grouped_event_setting.event_filter = adataSetting.event_filter;
        grouped_event_setting.event_align_point = adataSetting.event_align_point;
        grouped_event_setting.cat_keywords = adataSetting.cat_keywords;
    end
end

%% Subfunctions
function [eventProp_all] = mark_EXog_events(eventProp_all, ogTags, debugMode)
    % Rename OG-triggered events based on stimTrig
    idx_check = cell(1, numel(ogTags));
    for n = 1:numel(ogTags)
        [~, idx_check{n}] = filter_structData(eventProp_all, 'stim_name', ogTags{n}, []);
    end
    idxAll_check = [idx_check{:}];
    eventProp_check = eventProp_all(idxAll_check);
    eventProp_uncheck = eventProp_all;
    eventProp_uncheck(idxAll_check) = [];
    [~, idx_ogEx] = filter_structData(eventProp_check, 'stimTrig', 1, []);
    cat_setting.cat_type = 'stim_name';
    cat_setting.cat_names = {'EXog', 'EXog-ap'};
    cat_setting.cat_merge = {{'og'}, {'og-ap'}};
    [eventProp_check(idx_ogEx)] = mod_cat_name(eventProp_check(idx_ogEx), ...
        'cat_setting', cat_setting, 'dis_extra', false, 'stimType', false);
    eventProp_all = [eventProp_uncheck; eventProp_check];
end






