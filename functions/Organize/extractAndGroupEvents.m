function [groupedEvent, varargout] = extractAndGroupEvents(caImgData, groupField, varargin)
%EXTRACTANDGROUPEVENTS Extract and group event properties from ROI trials.
%   This function extracts event properties from caImgData and groups them based on
%   specified fields. It allows filtering of ROIs, normalization, event renaming, and sorting.
%
%   USAGE:
%       [groupedEvent, eventPropAll] = extractAndGroupEvents(caImgData, groupField, ...
%           'filterROIs', true, 'filterROIsStimTags', {'tag1'}, 'filterROIsStimEffects', {filters});
%
%   INPUT:
%       caImgData   : Struct array containing ROI event data.
%       groupField  : Cell array of fields used to group events.
%
%   OPTIONAL PARAMETERS:
%       'filterROIs'            : Logical flag to enable ROI filtering (default: false).
%       'filterROIsStimTags'    : Cell array of stimulation tags for filtering.
%       'filterROIsStimEffects' : Cell array of filters corresponding to stim tags.
%       'entry'                 : String specifying event entry type (default: 'event').
%       'separateSpon'          : Logical flag to separate spontaneous events.
%       'discardSpon'           : Logical flag to discard spontaneous events.
%       'modifyEventTypeName'   : Logical flag to rename event types.
%       'markEXog'              : Logical flag to mark OG-triggered events.
%       'ogTags'                : Cell array of OG tags.
%       'sortOrder'             : Cell array specifying group sort order.
%       'sortOrderPlus'         : Additional sorting fields.
%       'debugMode'             : Logical flag to enable debugging output.
%
%   OUTPUT:
%       groupedEvent : Struct array of grouped events with additional properties.
%       eventPropAll : Struct array of all event properties extracted.
%
%   EXAMPLE:
%       [groupedEvent, eventPropAll] = extractAndGroupEvents(caImgData, {'stim_name'}, ...
%           'filterROIs', true, 'filterROIsStimTags', {'AP'}, 'filterROIsStimEffects', {filters});

    %% Parse Inputs
    p = inputParser;
    addRequired(p, 'caImgData', @isstruct);
    addRequired(p, 'groupField', @iscell);

    % Optional parameters
    addParameter(p, 'filterROIs', false, @islogical);
    addParameter(p, 'filterROIsStimTags', {}, @iscell);
    addParameter(p, 'filterROIsStimEffects', {}, @iscell);
    addParameter(p, 'entry', 'event', @ischar);
    addParameter(p, 'separateSpon', false, @islogical);
    addParameter(p, 'discardSpon', false, @islogical);
    addParameter(p, 'modifyEventTypeName', true, @islogical);
    addParameter(p, 'markEXog', false, @islogical);
    addParameter(p, 'ogTags', {{'N-O', 'N-O&AP'}}, @iscell);
    addParameter(p, 'sortOrder', {{'spon', 'trig', 'rebound', 'delay'}}, @iscell);
    addParameter(p, 'sortOrderPlus', {{'AP', 'EXopto'}}, @iscell);
    addParameter(p, 'debugMode', false, @islogical);

    % Parse inputs
    parse(p, caImgData, groupField, varargin{:});
    params = p.Results;

    %% Filter ROIs (Optional)
    if params.filterROIs
        caImgData = Filter_AlignedDataTraces_withStimEffect_multiTrial(caImgData, ...
            'stim_names', params.filterROIsStimTags, 'filters', params.filterROIsStimEffects);
    end

    %% Extract Event Properties
    eventPropAll = collect_event_prop(caImgData, 'style', params.entry);

    % Mark OG-triggered events if required
    if params.markEXog
        idx_check = cell(1, numel(params.ogTags));
        for n = 1:numel(params.ogTags)
            [~, idx_check{n}] = filter_structData(eventPropAll, 'stim_name', params.ogTags{n}, []);
        end
        idxAll_check = [idx_check{:}];
        eventProp_check = eventPropAll(idxAll_check);
        eventProp_uncheck = eventPropAll;
        eventProp_uncheck(idxAll_check) = [];
        [~, idx_ogEx] = filter_structData(eventProp_check, 'stimTrig', 1, []);
        cat_setting.cat_type = 'stim_name';
        cat_setting.cat_names = {'EXog', 'EXog-ap'};
        cat_setting.cat_merge = {{'og'}, {'og-ap'}};
        [eventProp_check(idx_ogEx)] = mod_cat_name(eventProp_check(idx_ogEx), ...
            'cat_setting', cat_setting, 'dis_extra', false, 'stimType', false);
        eventPropAll = [eventProp_uncheck; eventProp_check];
    end

    % Normalize Event Properties
    eventPropAll = norm_eventProp_with_spon(eventPropAll, 'entry', params.entry, 'discardSpon', params.discardSpon);

    % Modify Event Type Names
    if params.modifyEventTypeName
        eventPropAll = mod_cat_name(eventPropAll, 'dis_extra', true, 'separateSpon', params.separateSpon);
    end

    %% Group Events
    [groupedEvent, groupedEventSetting] = group_event_info_multi_category(eventPropAll, ...
        'category_names', params.groupField, 'debugMode', params.debugMode);

    %% Add Group Metrics
    for gn = 1:numel(groupedEvent)
        groupName = groupedEvent(gn).group;
        if params.debugMode
            fprintf('[addGroupMetrics] group (%d/%d): %s\n', gn, numel(groupedEvent), groupName);
        end
        [TrialRoiList, recNum, animalNum, roiNum, eventNum] = get_roiNum_from_eventProp(groupedEvent(gn).event_info);
        groupedEvent(gn).animalNum = animalNum;
        groupedEvent(gn).recNum = recNum;
        groupedEvent(gn).roiNum = roiNum;
        groupedEvent(gn).eventNum = eventNum;
        groupedEvent(gn).TrialRoiList = TrialRoiList;


        % Add fovCount if entry is 'roi'
        if strcmp(params.entry, 'roi')
            EventInfo = groupedEvent(gn).event_info;
            fovIDs = {EventInfo.fovID};
            roiNum = numel(fovIDs);
            fovIDsUnique = unique(fovIDs);
            fovIDsUniqueNum = numel(fovIDsUnique);

            % Initialize structure for fov counts
            fovIDcountStruct = empty_content_struct({'fovID', 'numROI', 'perc'}, fovIDsUniqueNum);
            [fovIDcountStruct.fovID] = fovIDsUnique{:};
            for fn = 1:fovIDsUniqueNum
                fovIDcountStruct(fn).numROI = numel(find(contains(fovIDs, fovIDcountStruct(fn).fovID)));
                fovIDcountStruct(fn).perc = fovIDcountStruct(fn).numROI / roiNum;
            end
            groupedEvent(gn).fovCount = fovIDcountStruct;

            % if ~contains(groupName, 'spon') && ~contains(groupName, 'varied')
            %     [groupedEvent(gn).eventPb, groupedEvent(gn).eventPbList] = ...
            %         analyze_roi_event_possibility(groupedEvent(gn).event_info, 'debugMode', params.debugMode);
            % end
        end
    end

    %% Sort Groups
    groupedEvent = sort_struct_with_str(groupedEvent, 'group', params.sortOrder, ...
        'strCells_plus', params.sortOrderPlus);

    groupedEventSetting.event_type = params.entry;
    groupedEventSetting.TrialRoiList = get_roiNum_from_eventProp_fieldgroup(eventPropAll, 'stim_name');

    varargout{1} = eventPropAll;
end
