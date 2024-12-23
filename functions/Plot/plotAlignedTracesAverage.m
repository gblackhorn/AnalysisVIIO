function [tracesAverage, tracesShade, varargout] = plotAlignedTracesAverage(plotWhere, tracesData, timeInfo, varargin)
    % Plot the average of aligned traces. Use ste/std values for plotting the shade
    
    % Create an input parser
    p = inputParser;
    
    % Add parameters with default values
    addParameter(p, 'eventsProps', []);
    addParameter(p, 'plot_combined_data', true);
    addParameter(p, 'plot_raw_traces', false);
    addParameter(p, 'plot_median', false);
    addParameter(p, 'medianProp', 'FWHM');
    addParameter(p, 'shadeType', 'ste');
    addParameter(p, 'color', '');
    addParameter(p, 'y_range', []);
    addParameter(p, 'tickInt_time', 1);
    addParameter(p, 'stimName', '');
    addParameter(p, 'eventCat', '');
    addParameter(p, 'yRangeMargin', 0.5);
    addParameter(p, 'titlePrefix', '');
    
    % Parse input arguments
    parse(p, varargin{:});
    
    % Assign parsed input to variables
    eventsProps = p.Results.eventsProps;
    plot_combined_data = p.Results.plot_combined_data;
    plot_raw_traces = p.Results.plot_raw_traces;
    plot_median = p.Results.plot_median;
    medianProp = p.Results.medianProp;
    shadeType = p.Results.shadeType;
    color = p.Results.color;
    y_range = p.Results.y_range;
    tickInt_time = p.Results.tickInt_time;
    stimName = p.Results.stimName;
    eventCat = p.Results.eventCat;
    yRangeMargin = p.Results.yRangeMargin;
    titlePrefix = p.Results.titlePrefix;
    
    tracesAverage = mean(tracesData, 2, 'omitnan');
    stimRepeatNum = size(tracesData, 2);

    % Calculate the number of recordings, the number of dates
    % (animal number), the number of neurons and the number of
    % traces
    if ~isempty(eventsProps)
        [nNum.recNum, nNum.recDateNum, nNum.roiNum, nNum.tracesNum] = calcDataNum(eventsProps);

        % Find the idx of median trace using 'medianProp' if plot_median is true
        if plot_median
            eventFieldNames = fieldnames(eventsProps);
            if ~isempty(find(strcmpi(eventFieldNames, medianProp)))
                propVal = [eventsProps.(medianProp)];
                medianVal = median(propVal, 2, 'omitnan');
                medianDiff = abs(propVal - medianVal);
                [~, medianValIDX] = min(medianDiff);
                medianTrace = tracesData(:, medianValIDX);
            else
                plot_median = false;
            end
        end
    else
        nNum.recNum = NaN;
        nNum.recDateNum = NaN;
        nNum.roiNum = NaN;
        nNum.tracesNum = size(tracesData, 2);
    end

    % Calculate shade values
    switch shadeType
        case 'std'
            tracesShade = std(tracesData, 0, 2, 'omitnan');
        case 'ste'
            tracesShade = std(tracesData, 0, 2, 'omitnan') / sqrt(stimRepeatNum);
        otherwise
            error('Invalid shadeType. It must be either std or ste');
    end

    if ~isempty(tracesData)
        % Use the shade area to decide the y_range
        if isempty(y_range)
            yUpperLim = max(tracesAverage + tracesShade);
            yLowerLim = min(tracesAverage - tracesShade);
            yDiff = yUpperLim - yLowerLim;
            y_range = [yLowerLim - yDiff * yRangeMargin, yUpperLim + yDiff * yRangeMargin];
        end

        plot_trace(timeInfo, tracesData, 'plotWhere', plotWhere,...
            'plot_combined_data', plot_combined_data,...
            'mean_trace', tracesAverage, 'mean_trace_shade', tracesShade,...
            'mean_line_color', color, 'shade_color', color,...
            'plot_raw_traces', plot_raw_traces, 'y_range', y_range, 'tickInt_time', tickInt_time);

        if plot_median
            plot_trace(timeInfo, medianTrace, 'plotWhere', plotWhere,...
                'plot_combined_data', false, 'plot_raw_traces', true, 'tickInt_time', tickInt_time);
        end
    end
    
    % if ~isempty(titlePrefix)
    %     titlePrefix = [titlePrefix, ' '];
    % end
    titleName = sprintf('%s %s [%s] %g-animal %g-rec %g-roi %g-trace',...
        titlePrefix, stimName, eventCat, nNum.recDateNum, nNum.recNum, nNum.roiNum, nNum.tracesNum);
    title(titleName);

    varargout{1} = nNum;
    varargout{2} = titleName;
end

function [recNum, recDateNum, roiNum, tracesNum] = calcDataNum(eventsProps)
    % Calculate the n numbers using the structure var 'eventsProps'
    if ~isempty(eventsProps)
        dateTimeRoiAll = {eventsProps.DateTimeRoi};
        dateTimeAllRec = cellfun(@(x) x(1:15), dateTimeRoiAll, 'UniformOutput', false);
        dateAllRec = cellfun(@(x) x(1:8), dateTimeRoiAll, 'UniformOutput', false);
        dateTimeRoiUnique = unique(dateTimeRoiAll);
        dateTimeUnique = unique(dateTimeAllRec);
        dateUnique = unique(dateAllRec);

        % Get all the n numbers
        recNum = numel(dateTimeUnique);
        recDateNum = numel(dateUnique);
        roiNum = numel(dateTimeRoiUnique);
        tracesNum = numel(dateTimeRoiAll);
    else
        recNum = 0;
        recDateNum = 0;
        roiNum = 0;
        tracesNum = 0;
    end
end


