function [varargout] = eventFreqPSTH(VIIOdata, stimulation, varargin)
%Collect the event frequency from recording(s) applied with the same stimulation type and plot the PSTH
% Return the statistics of the event frequency and compare the bins of the PSTH


    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'VIIOdata', @isstruct);
    addRequired(p, 'stimulation', @ischar);
    
    % Define optional inputs
    % Filters:
    addParameter(p, 'recFilterNames', {}, @iscell); % Name of fields in VIIOdata to filter recordings
    addParameter(p, 'recFilterVals', {}, @(x) iscell(x)); % Values for the recFilterNames, can be logical or character
    addParameter(p, 'roiFilterNames', {}, @iscell); % Name of fields in recording data (VIIOdata.traces) to filter ROIs
    addParameter(p, 'roiFilterVals', {}, @(x) iscell(x)); % Values for the roiFilterNames, can be logical or character

    % PSTH parameters:
    addParameter(p, 'binWidth', 1, @isnumeric); % Width of each histogram bin (s) when not using customized bin edges
    addParameter(p, 'customizeBin', false, @logical); % Boolean to use customized bin edges
    addParameter(p, 'stimEffectDur', 1, @isnumeric); % The duration of the stimulation effect from the start of stimulation
    addParameter(p, 'splitStim', [1], @isnumeric); % Split long stimulations when using customized bin edges. Can be a numeric array when using multiple stimulations
    addParameter(p, 'preStimDur', 6, @isnumeric); % Duration before stimulation onset (s)
    addParameter(p, 'postStimDur', 7, @isnumeric); % Duration after stimulation end (s)
    addParameter(p, 'baseStart', [], @isnumeric); % Start of baseline relative to the stimulation onset
    addParameter(p, 'baseEnd', 0, @isnumeric); % End of baseline baseline relative to the stimulation onset
    addParameter(p, 'normBase', false, @islogical); % Normalize data to baseline if true
    addParameter(p, 'discardZeroBase', true, @islogical); % Discard the roi/stimTrial if the baseline value is zero
    addParameter(p, 'eventTimeField', 'peak_time', @ischar); % Field name for event time stamps in VIIOdata.traces.eventProp

    % Parse the inputs
    parse(p, VIIOdata, stimulation, varargin{:});
    pars = p.Results;

    % Set up the baseline range in the PSTH
    if isempty(pars.baseStart)
        pars.baseStart = -pars.preStimDur;
    end
    baseRange = [pars.baseStart, pars.baseEnd];
   
    % Filter recordings using stimulation name
    stimNameTF = strcmpi({VIIOdata.stim_name}, stimulation);
    VIIOdata = VIIOdata(stimNameTF);

    % Filter recordings using recFilterNames and recFilterBool if recFilterNames is not empty
    if ~isempty(pars.recFilterNames)
        VIIOdata = getFilteredData(VIIOdata, pars.recFilterNames, pars.recFilterVals);
    end

    % Pre-allocate the event frequency data as a cell array
    recNum = length(VIIOdata);
    EventFreqRecCell = cell(1, recNum);
        
    % Loop through recordings and collect the event frequency
    for i = 1:recNum
        % Get the ranges of stimulations in the current recording
        stimInfo = VIIOdata(i).stimInfo;

        % Create 4*2 matrices for plotting stimulation shades. Use the first recording
        if i == 1
            stimInfoSep = stimInfo.StimDuration; % Multi-entry struct if multiple stimulations exist
            stimShadeData = cell(size(stimInfoSep)); % Cell array to store the stimulation shade data
            stimShadeName = cell(size(stimInfoSep)); % Cell array to store the stimulation shade names
            for sn = 1:numel(stimInfoSep) % Go through every stimulation in the recording
                stimShadeData{sn} = stimInfoSep(sn).patch_coor(1:4,1:2); % Get the first 4 rows for the first repeat of stimulation
                stimShadeData{sn}(1:2,1) = stimInfoSep(sn).range_aligned(1); % Replace the first 2 x values (stim GPIO rising) with the 1st element from range_aligned
                stimShadeData{sn}(3:4,1) = stimInfoSep(sn).range_aligned(2); % Replace the last 2 x values (stim GPIO falling) with the 2nd element from range_aligned
                stimShadeName{sn} = stimInfoSep(sn).type; % Get the stimulation type 
            end
        end
        
        % Set up the PSTH bin edges using customised bins or a fixed bin width
        if pars.customizeBin
            % Set the peri-stim sections (edges)
            [periStimEdges, stimOnsetTime, stimRepeatNum, binNames] = customizePeriStimBinEdges(stimInfo,...
                'preStimDuration', pars.preStimDur,'postStimDuration', pars.postStimDur,...
                'PeriBaseRange', baseRange,'stimEffectDuration', pars.stimEffectDur,'splitLongStim', pars.splitStim);
        else
            [periStimEdges, stimOnsetTime, stimRepeatNum, binNames] = setPeriStimBinEdges(stimInfo.UnifiedStimDuration.range, binWidth, ...
                'preStimDur', pars.preStimDur, 'postStimDur', pars.postStimDur);
        end


        % Filter ROIs using roiFilterNames and roiFilterBool if roiFilterNames is not empty 
        if ~isempty(pars.roiFilterNames)
            VIIOdata(i).traces = getFilteredData(VIIOdata(i).traces, pars.roiFilterNames, pars.roiFilterVals);
        end
        roiNum = length(VIIOdata(i).traces);
        
        
        if roiNum ~= 0
            % Pre-allocate the event frequency data in a recording as a structure array
            EventFreqRoiStruct = emptyStruct({'recNames','roiNames','subNuclei','EventFqInBins','stimNum'},[1, roiNum]); % Every entry in the struct array corresponds to an ROI

            % Collect label informations: Recording names, ROI names, and sub-nuclei names
            recNames = repmat({VIIOdata(i).trialName},1, roiNum); % Create a 1*roi_num cell containing the 'recNames' in every element
            roiNames = {VIIOdata(i).traces.roi};
            subNucleiNames = {VIIOdata(i).traces.subNuclei};

            % Fill the label information in the structure
            [EventFreqRoiStruct.recNames] = recNames{:}; % Add trial names in struct EventFreqRoiStruct
            [EventFreqRoiStruct.roiNames] = roiNames{:}; % Add ROI names in struct EventFreqRoiStruct
            [EventFreqRoiStruct.subNuclei] = subNucleiNames{:}; % Add sub-nuclei names in struct EventFreqRoiStruct
            
            % Loop through the ROIs and collect the event frequency
            disRoiIDX = []; % Initialize the index of ROIs to discard
            for j = 1:roiNum
                % Get the event time stamps in the current ROI
                eventTimeStamps = VIIOdata(i).traces(j).eventProp.(eventTimeField);

                % Get the event frequency in the current ROI
                [eventFreqPSTH, binEdgesPSTH, eventHistCounts, sectionsDuration] = calcPeriStimEventFreqInROI(eventTimeStamps, periStimEdges, stimOnsetTime);

                % Fill the event frequency data in the structure
                EventFreqRoiStruct(rn).EventFqInBins = sectEventFreq;
                EventFreqRoiStruct(rn).stimNum = stimRepeatNum;
                
                if discardZeroBase || normBase
                    % Normalize the event frequency to the baseline if normBase is true
                    % Discard the roi/stimTrial if the baseline value is zero. Output a warning message
                    baseFreq = mean(eventFreqPSTH(binEdgesPSTH >= baseRange(1) & binEdgesPSTH <= baseRange(2)));
                    if baseFreq == 0
                        disRoiIDX = [disRoiIDX, j];
                        warning('The baseline value is zero in the recording: %s, ROI: %s', VIIOdata(i).recName, VIIOdata(i).traces(j).roi);
                    end
                    if normBase
                        eventFreqPSTH = eventFreqPSTH / baseFreq;
                    end
                end
            end

            % Remove the ROIs marked for discard
            EventFreqRoiStruct(disRoiIDX) = [];

            % Store the EventFreqRoiStruct in the cell array
            EventFreqRecCell{i} = EventFreqRoiStruct;
        else
            warning('No ROIs found in the recording: %s', VIIOdata(i).recName);
        end
    end

    % Combine the event frequency data from all recordings
    EventFreqAll = [EventFreqRecCell{:}]; % A structure array with all the event frequency data. Each entry corresponds to an ROI


    % Run statistical analysis on the event frequency: Bootstrapping


    % Plot the PSTH: boxplot or bar plot
end


function filteredData = getFilteredData(structData, filterNames, filterVals)
    % Filter VIIOdata based on filterNames and filterVals
    % filterVals can be a logical array or a cell array of strings

    % Initialize filteredData as VIIOdata
    filteredData = structData;

    % Loop through each filter name
    for i = 1:length(filterNames)
        filterName = filterNames{i};
        filterVal = filterVals{i};

        if islogical(filterVal)
            % Apply boolean filter
            filteredData = filteredData([filteredData.(filterName)] == filterVal);
        elseif ischar(filterVal)
            % Apply character filter
            filteredData = filteredData(strcmp({filteredData.(filterName)}, filterVal));
        else
            error('Unsupported filter type. Only logical and character filters are supported.');
        end
    end
end