function [groupedEvent,varargout] = extractAndGroupEvents(caImgData, groupField, varargin)
    % Get eventProp from every ROI and every trials in caImgData, and group them accroding to settings

    % Create an instance of the inputParser
    p = inputParser;

    % Required input
    addRequired(p, 'caImgData', @isstruct);
    addRequired(p, 'groupField', @iscell);

    % Add optional parameters to the input parser
    addParameter(p, 'filterROIs', false, @islogical);
    addParameter(p, 'filterROIsStimTags', {}, @iscell);
    addParameter(p, 'filterROIsStimEffects', {}, @iscell);
    addParameter(p, 'entry', 'event', @ischar);
    addParameter(p, 'separateSpon', false, @islogical); % Separate the spon events using stimulation tags
    addParameter(p, 'discardSpon', false, @islogical); 
    addParameter(p, 'modifyEventTypeName', true, @islogical); 
    addParameter(p, 'markEXog', false, @islogical); 
    addParameter(p, 'ogTags', {{'N-O', 'N-O&AP'}}, @iscell); 
    addParameter(p, 'sortOrder', {{'spon', 'trig', 'rebound', 'delay'}}, @iscell); 
    addParameter(p, 'sortOrderPlus', {{'AP', 'EXopto'}}, @iscell); 
    addParameter(p, 'debugMode', false, @islogical);

    % Parse inputs
    parse(p, caImgData, groupField, varargin{:});

    % Retrieve parsed values
    filterROIs = p.Results.filterROIs;
    filterROIsStimTags = p.Results.filterROIsStimTags;
    filterROIsStimEffects = p.Results.filterROIsStimEffects;
    entry = p.Results.entry;
    separateSpon = p.Results.separateSpon;
    discardSpon = p.Results.discardSpon;
    modifyEventTypeName = p.Results.modifyEventTypeName;
    markEXog = p.Results.markEXog;
    ogTags = p.Results.ogTags;
    sortOrder = p.Results.sortOrder;
    sortOrderPlus = p.Results.sortOrderPlus;
    debugMode = p.Results.debugMode;


    if filterROIs
        [caImgData,tfIdxWithSubNucleiInfo,roiNumAll,roiNumKep,roiNumDis] = Filter_AlignedDataTraces_withStimEffect_multiTrial(caImgData,...
            'stim_names',filterROIsStimTags,'filters',filterROIsStimEffects);
    end


    % Collect eventProp
    eventPropAll = collect_event_prop(caImgData, 'style', entry); % Use 'event' for 'style'

    % Group eventProp according to the 'mgSetting.groupField' and add more information
    % Rename OG-triggered events if markEXog is enabled
    if markEXog
        eventPropAll = mark_EXog_events(eventPropAll, ogTags, debugMode);
    end

    % Normalize event properties
    eventPropAllNorm = norm_eventProp_with_spon(eventPropAll, ...
        'entry', entry, 'discardSpon', discardSpon);

    % Modify event type names if enabled
    if modifyEventTypeName
        eventPropAllNorm = mod_cat_name(eventPropAllNorm, ...
            'dis_extra', true, 'separateSpon', separateSpon);
    end

    % Group events based on specified fields
    [groupedEvent, groupedEventSetting] = group_event_info_multi_category(eventPropAllNorm, ...
        'category_names', groupField, 'debugMode', debugMode);

    % Add n numbers
    for gn = 1:numel(groupedEvent)
        groupName = groupedEvent(gn).group;
        if debugMode
            fprintf('[mod_and_group_eventProp] group (%d/%d): %s\n',gn,numel(groupedEvent),groupName);
            if gn == 3
                pause
            end
        end
        % [groupedEvent(gn).numTrial,groupedEvent(gn).numRoi,groupedEvent(gn).numRoiVec] = get_num_fieldUniqueContent(groupedEvent(gn).event_info,...
        %     'fn_1', 'trialName', 'fn_2', 'roiName');
        [TrialRoiList,recNum,animalNum,roiNum] = get_roiNum_from_eventProp(groupedEvent(gn).event_info);
        groupedEvent(gn).animalNum = animalNum;
        groupedEvent(gn).recNum = recNum;
        groupedEvent(gn).roiNum = roiNum;
        groupedEvent(gn).TrialRoiList = TrialRoiList;

        if strcmp(entry,'roi') && ~contains(groupName,'spon') && ~contains(groupName,'varied')
            [groupedEvent(gn).eventPb,groupedEvent(gn).eventPbList] = analyze_roi_event_possibility(groupedEvent(gn).event_info,'debugMode',debugMode);
        end
    end

    % Sort groups based on sortOrder and sortOrderPlus
    groupedEvent = sort_struct_with_str(groupedEvent, 'group', sortOrder, ...
        'strCells_plus', sortOrderPlus);

    groupedEventSetting.event_type = entry;

    % % Include aligned data settings if provided
    % if ~isempty(adataSetting)
    %     groupedEventSetting.traceData_type = adataSetting.traceData_type;
    %     groupedEventSetting.event_data_group = adataSetting.event_data_group;
    %     groupedEventSetting.event_filter = adataSetting.event_filter;
    %     groupedEventSetting.event_align_point = adataSetting.event_align_point;
    %     groupedEventSetting.cat_keywords = adataSetting.cat_keywords;
    % end


    % [groupedEvent,groupedEventSetting] = mod_and_group_eventProp(eventPropAll,entry,adata,...
    %     'mgSetting',ggSetting,'debugMode',debugMode);
    
    [groupedEventSetting.TrialRoiList] = get_roiNum_from_eventProp_fieldgroup(eventPropAll,'stim_name'); % calculate all roi number
    if strcmpi(entry,'roi')
        GroupNum = numel(groupedEvent);
        % GroupName = {groupedEvent.group};
        for gn = 1:GroupNum
            EventInfo = groupedEvent(gn).event_info;
            fovIDs = {EventInfo.fovID};
            roi_num = numel(fovIDs);
            fovIDs_unique = unique(fovIDs);
            fovIDs_unique_num = numel(fovIDs_unique);
            fovID_count_struct = empty_content_struct({'fovID','numROI','perc'},fovIDs_unique_num);
            [fovID_count_struct.fovID] = fovIDs_unique{:};
            for fn = 1:fovIDs_unique_num
                fovID_count_struct(fn).numROI = numel(find(contains(fovIDs,fovID_count_struct(fn).fovID)));
                fovID_count_struct(fn).perc = fovID_count_struct(fn).numROI/roi_num;
            end
            groupedEvent(gn).fovCount = fovID_count_struct;
        end
    end

    varargout{1} = eventPropAll;
end

%% Subfunctions
function [eventPropAll] = mark_EXog_events(eventPropAll, ogTags, debugMode)
    % Rename OG-triggered events based on stimTrig
    idx_check = cell(1, numel(ogTags));
    for n = 1:numel(ogTags)
        [~, idx_check{n}] = filter_structData(eventPropAll, 'stim_name', ogTags{n}, []);
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