function VIIOdata = pruneVIIOdataStruct(VIIOdata)
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

    % Define fields to keep in VIIOdata(n)
    topLevelFieldsToKeep = {
        'trialName', 'stim_name', 'stimTrig', 'fovID', 'stimInfo', 'event_type', ...
        'traces', 'time', 'fullTime', 'synchFoldValue'
    };

    % Define fields to keep in VIIOdata(n).traces(m)
    traceFieldsToKeep = {
        'stimEvent_possi', 'sponfq', 'sponInterval', 'cv2', 'peak_category', 'subNuclei', 'type', ...
        'roi', 'value', 'fullTrace', 'fullTraceDecon', 'hpStd', 'sponEventNum', 'eventProp'
    };

    % Define fields to keep in VIIOdata(n).traces(m).eventProp(k)
    eventPropFieldsToKeep = {
        'peak_time', 'rise_time', 'sponnorm_peak_mag_delta', 'FWHM', ...
        'peak_delta_norm_hpstd', 'rise_duration', 'peak_delay', ...
        'rise_loc', 'peak_loc', 'peak_mag_delta', 'peak_category', 'stim_tags', ...
        'rise_delay', 'type', 'spikeClusterGroup', 'roiSynchRatio', 'trialSynchRatio', 'clusterSize'
    };

    % Check for missing top-level fields
    allTopLevelFields = fieldnames(VIIOdata);
    missingTopLevelFields = setdiff(topLevelFieldsToKeep, allTopLevelFields);
    for i = 1:numel(missingTopLevelFields)
        warning('Missing top-level field: %s', missingTopLevelFields{i});
    end

    % Prune top-level fields
    fieldsToRemove = setdiff(allTopLevelFields, topLevelFieldsToKeep);
    for i = 1:numel(fieldsToRemove)
        fieldName = fieldsToRemove{i};
        VIIOdata = rmfield(VIIOdata, fieldName);
        fprintf('Removed top-level field: %s\n', fieldName);
    end

    % Loop through each entry and prune trace and eventProp fields
    for n = 1:numel(VIIOdata)
        if isfield(VIIOdata(n), "traces")
            VIIOdata(n).traces = keepOnlyTracesFields(VIIOdata(n).traces, traceFieldsToKeep, eventPropFieldsToKeep, n);
        end
    end
end

function traces = keepOnlyTracesFields(traces, traceFieldsToKeep, eventPropFieldsToKeep, entryIndex)
    if isstruct(traces)
        for m = 1:numel(traces)
            % Remove unwanted trace fields
            allTraceFields = fieldnames(traces(m));

            % Warn about missing trace fields
            missingTraceFields = setdiff(traceFieldsToKeep, allTraceFields);
            for i = 1:numel(missingTraceFields)
                warning('Missing trace field in VIIOdata(%d).traces(%d): %s', entryIndex, m, missingTraceFields{i});
            end

            traceFieldsToRemove = setdiff(allTraceFields, traceFieldsToKeep);
            for i = 1:numel(traceFieldsToRemove)
                traces(m) = rmfield(traces(m), traceFieldsToRemove{i});
                fprintf('Removed trace field: %s\n', traceFieldsToRemove{i});
            end

            % Handle eventProp
            if isfield(traces(m), "eventProp")
                eventProp = traces(m).eventProp;
                if isstruct(eventProp)
                    for k = 1:numel(eventProp)
                        allEventFields = fieldnames(eventProp(k));

                        % Warn about missing eventProp fields
                        missingEventFields = setdiff(eventPropFieldsToKeep, allEventFields);
                        for j = 1:numel(missingEventFields)
                            warning('Missing eventProp field in VIIOdata(%d).traces(%d).eventProp(%d): %s', entryIndex, m, k, missingEventFields{j});
                        end

                        eventFieldsToRemove = setdiff(allEventFields, eventPropFieldsToKeep);
                        for j = 1:numel(eventFieldsToRemove)
                            eventProp(k) = rmfield(eventProp(k), eventFieldsToRemove{j});
                            fprintf('Removed eventProp field: %s\n', eventFieldsToRemove{j});
                        end
                    end
                    traces(m).eventProp = eventProp;
                end
            end
        end
    end
end
