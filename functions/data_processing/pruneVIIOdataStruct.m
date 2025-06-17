function VIIOdata = pruneVIIOdataStruct(VIIOdata, showRemoved)
  % pruneVIIOdataStruct - Keep only necessary fields in VIIOdata for data repo
  %
  % This version removes all fields *except* for a specified set to retain.
  % Users can customize the "xxxFieldsToKeep" lists below to control which fields
  % are preserved at each level of the VIIOdata structure.
  %
  % Fields are categorized as follows:
  % - topLevelFieldsToKeep: fields found directly in VIIOdata(n)
  % - traceFieldsToKeep: fields found in VIIOdata(n).traces(m)
  % - eventPropFieldsToKeep: fields found in VIIOdata(n).traces(m).eventProp(k)
  %
  % Field order is preserved based on the original input structure.

    if nargin < 2
        showRemoved = true;
    end

    % Define fields to keep in VIIOdata(n)
    topLevelFieldsToKeep = {
        'trialName', 'event_type', 'stim_name', 'fovID', 'stimInfo', ...
        'traces', 'time', 'fullTime', 'synchFoldValue'
    };

    % Define fields to keep in VIIOdata(n).traces(m)
    traceFieldsToKeep = {
        'roi', 'value', 'subNuclei', 'eventProp', 'fullTrace', 'fullTraceDecon', ...
        'hpStd', 'stimEvent_possi', 'stimTrig', 'sponfq', 'sponInterval', ...
        'cv2', 'sponEventNum'
    };

    % Define fields to keep in VIIOdata(n).traces(m).eventProp(k)
    eventPropFieldsToKeep = {
        'rise_time', 'rise_loc', 'rise_duration', 'peak_time', 'peak_loc', 'FWHM', ...
        'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_category', 'stim_tags', ...
        'rise_delay', 'peak_delay', 'sponnorm_peak_mag_delta', 'type', ...
        'spikeClusterGroup', 'roiSynchRatio', 'trialSynchRatio', 'clusterSize'
    };

    % Determine and print what will be removed at each level (once)
    traceSample = VIIOdata(1).traces;
    eventPropSample = traceSample(1).eventProp;

    traceRemoved = setdiff(fieldnames(traceSample), traceFieldsToKeep);
    eventPropRemoved = setdiff(fieldnames(eventPropSample), eventPropFieldsToKeep);
    topLevelRemoved = setdiff(fieldnames(VIIOdata), topLevelFieldsToKeep);

    if showRemoved
        printFieldList('top-level', topLevelRemoved);
        printFieldList('trace', traceRemoved);
        printFieldList('eventProp', eventPropRemoved);
    end

    % Reconstruct VIIOdata with preserved field order
    originalOrder = fieldnames(VIIOdata);
    keepFlags = ismember(originalOrder, topLevelFieldsToKeep);
    prunedVIIO = struct();

    for i = 1:numel(originalOrder)
        fieldName = originalOrder{i};
        if keepFlags(i) && isfield(VIIOdata, fieldName)
            if strcmp(fieldName, "traces")
                for n = 1:numel(VIIOdata)
                    VIIOdata(n).traces = keepOnlyTracesFields(VIIOdata(n).traces, traceFieldsToKeep, eventPropFieldsToKeep);
                end
            end
            [prunedVIIO(1:numel(VIIOdata)).(fieldName)] = VIIOdata.(fieldName);
        end
    end

    if showRemoved
        fprintf('All fields listed above were successfully removed.\n');
    end

    VIIOdata = prunedVIIO;
end

function printFieldList(level, fieldList)
    if isempty(fieldList)
        return;
    end
    fprintf('To be removed %s fields:\n', level);
    nPerLine = 5;
    for k = 1:nPerLine:length(fieldList)
        lastIdx = min(k+nPerLine-1, length(fieldList));
        fprintf('  %s\n', strjoin(fieldList(k:lastIdx), ', '));
    end
end

function prunedTraces = keepOnlyTracesFields(traces, traceFieldsToKeep, eventPropFieldsToKeep)
    traceCell = cell(1, numel(traces));
    orderedTraceFields = intersect(fieldnames(traces), traceFieldsToKeep, 'stable');

    for m = 1:numel(traces)
        traceIn = traces(m);
        traceOut = struct();
        for i = 1:numel(orderedTraceFields)
            f = orderedTraceFields{i};
            if isfield(traceIn, f)
                traceOut.(f) = traceIn.(f);
            end
        end

        if isfield(traceOut, "eventProp") && isstruct(traceOut.eventProp)
            traceOut.eventProp = keepOnlyEventPropFields(traceOut.eventProp, eventPropFieldsToKeep);
        end
        traceCell{m} = traceOut;
    end

    prunedTraces = [traceCell{:}];
end

function prunedEvent = keepOnlyEventPropFields(eventIn, eventPropFieldsToKeep)
    prunedEvent = repmat(struct(), 1, numel(eventIn));
    orderedFields = intersect(fieldnames(eventIn), eventPropFieldsToKeep, 'stable');

    for k = 1:numel(eventIn)
        for j = 1:numel(orderedFields)
            f = orderedFields{j};
            if isfield(eventIn(k), f)
                prunedEvent(k).(f) = eventIn(k).(f);
            end
        end
    end
end
