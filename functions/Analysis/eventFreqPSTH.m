function [PSTHdata, varargout] = eventFreqPSTH(VIIOdata, stimulation, varargin)
%Collect the event frequency from recording(s) applied with the same stimulation type and plot the PSTH
% Return the statistics of the event frequency and compare the bins of the PSTH


    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'VIIOdata', @isstruct);
    addRequired(p, 'stimulation', @ischar);
    
    % Define optional inputs
    % Filters:
    addParameter(p, 'recFilters', struct('names', {}, 'values', {}), @isstruct); % Struct containing filter names and values for recordings
    addParameter(p, 'roiFilters', struct('names', {}, 'values', {}), @isstruct); % Struct containing filter names and values for ROIs

    % PSTH parameters:
    addParameter(p, 'binWidth', 1, @isnumeric); % Width of each histogram bin (s) when not using customized bin edges
    addParameter(p, 'customizeBin', false, @islogical); % Boolean to use customized bin edges
    addParameter(p, 'stimEffectDur', 1, @isnumeric); % The duration of the stimulation effect from the start of stimulation
    addParameter(p, 'splitStim', [1], @isnumeric); % Split long stimulations when using customized bin edges. Can be a numeric array when using multiple stimulations
    addParameter(p, 'preStimDur', 6, @isnumeric); % Duration before stimulation onset (s)
    addParameter(p, 'postStimDur', 7, @isnumeric); % Duration after stimulation end (s)
    addParameter(p, 'baseStart', [], @isnumeric); % Start of baseline relative to the stimulation onset
    addParameter(p, 'baseEnd', 0, @isnumeric); % End of baseline baseline relative to the stimulation onset
    addParameter(p, 'normBase', false, @islogical); % Normalize data to baseline if true
    addParameter(p, 'discardZeroBase', false, @islogical); % Discard the roi/stimTrial if the baseline value is zero
    addParameter(p, 'eventTimeField', 'peak_time', @ischar); % Field name for event time stamps in VIIOdata.traces.eventProp

    % Plotting parameters:
    addParameter(p, 'plotwhere', gca, @(x) ishandle(x) && strcmp(get(x, 'Type'), 'axes')); % Handle to the axes where the plot will be drawn
    addParameter(p, 'xlabelStr', 'Time (s)', @ischar); % X-axis label
    addParameter(p, 'xTickAngle', 45, @isnumeric); % Angle of X-axis tick labels
    addParameter(p, 'ylimVal', [], @isnumeric); % Angle of X-axis tick labels

    % Parse the inputs
    parse(p, VIIOdata, stimulation, varargin{:});
    pars = p.Results;

    %% Calculate the event frequency in the peri-stimulus time histogram (PSTH)
    % Set up the baseline range in the PSTH
    if isempty(pars.baseStart)
        pars.baseStart = -pars.preStimDur;
    end
    baseRange = [pars.baseStart, pars.baseEnd];
   
    % Filter recordings using stimulation name
    stimNameTF = strcmpi({VIIOdata.stim_name}, stimulation);
    VIIOdata = VIIOdata(stimNameTF);

    % Filter recordings using recFilters if not empty
    if ~isempty(pars.recFilters)
        VIIOdata = getFilteredData(VIIOdata, pars.recFilters);
    end

    % Pre-allocate variables
    recNum = length(VIIOdata);
    eventFreqRecCell = cell(1, recNum);
    PSTHdata = empty_content_struct({'stim','summaryData','dataStruct','binEdges','binNames','baseRange','recNum','recDateNum','roiNum','stimRepeatNum', 'stat'}, 1);
    PSTHdata.stim = stimulation;
        
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
            [binEdges, binNames, stimOnsetTime, binEdgesPSTH, stimRepeatNum] = customizePeriStimBinEdges(stimInfo,...
                'preStimDuration', pars.preStimDur,'postStimDuration', pars.postStimDur,...
                'PeriBaseRange', baseRange,'stimEffectDuration', pars.stimEffectDur,'splitLongStim', pars.splitStim);
        else
            [binEdges, binNames, stimOnsetTime, binEdgesPSTH, stimRepeatNum] = setPeriStimBinEdges(stimInfo.UnifiedStimDuration.range, pars.binWidth, ...
                'preStimDur', pars.preStimDur, 'postStimDur', pars.postStimDur);
        end
        PSTHdata.binEdges = binEdgesPSTH;
        PSTHdata.binNames = binNames;

        % Get the middle position of the bins for plotting
        binX = binEdgesPSTH(1:end-1)+diff(binEdgesPSTH)/2; % Use binEdges and binWidt to create xdata for bar plot

        % Get the baseline index in the PSTH bin edges
        baselineBinIDX = find(binEdgesPSTH >= baseRange(1) & binEdgesPSTH < baseRange(2));


        % Filter ROIs using roiFilters if not empty 
        if ~isempty(pars.roiFilters)
            VIIOdata(i).traces = getFilteredData(VIIOdata(i).traces, pars.roiFilters);
        end
        roiNum = length(VIIOdata(i).traces);
        
        
        if roiNum ~= 0
            % Pre-allocate the event frequency data in a recording as a structure array
            EventFreqRoiStruct = emptyStruct({'recNames','roiNames','subNuclei','EventFqInBins','stimNum'},[1, roiNum]); % Every entry in the struct array corresponds to an ROI

            % Collect label informations: Recording names, ROI names, and sub-nuclei names
            recNames = repmat({VIIOdata(i).trialName},1, roiNum); % Create a 1*roi_num cell containing the 'recNames' in every element1
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
                eventTimeStamps = [VIIOdata(i).traces(j).eventProp.(pars.eventTimeField)];

                % Get the event frequency in the current ROI
                [eventFreqPSTH, binEdgesPSTH, eventHistCounts, sectionsDuration] = calcPeriStimEventFreqInROI(eventTimeStamps, binEdges, stimOnsetTime);
                
                if pars.discardZeroBase || pars.normBase
                    % Normalize the event frequency to the baseline if normBase is true
                    % Discard the roi/stimTrial if the baseline value is zero. Output a warning message
                    baseFreq = mean(eventFreqPSTH(baselineBinIDX));
                    if baseFreq == 0
                        disRoiIDX = [disRoiIDX, j];
                        warning('The baseline value is zero in the recording: %s, ROI: %s', VIIOdata(i).trialName, VIIOdata(i).traces(j).roi);
                    end
                    if pars.normBase
                        eventFreqPSTH = eventFreqPSTH / baseFreq;
                    end
                end
                
                % Fill the event frequency data in the structure
                EventFreqRoiStruct(j).EventFqInBins = eventFreqPSTH;
                EventFreqRoiStruct(j).stimNum = stimRepeatNum;
            end

            % Remove the ROIs marked for discard
            EventFreqRoiStruct(disRoiIDX) = [];

            % Store the EventFreqRoiStruct in the cell array
            eventFreqRecCell{i} = EventFreqRoiStruct;
        else
            warning('No ROIs found in the recording: %s', VIIOdata(i).trialName);
        end
    end

    % Combine the event frequency data from all recordings
    eventFreqAll = [eventFreqRecCell{:}]; % A structure array with all the event frequency data. Each entry corresponds to an ROI
    
    % Calculate the number of animals, recordings, ROIs, and stimulation repeats
    [PSTHdata.recDateNum, PSTHdata.recNum, PSTHdata.roiNum, PSTHdata.stimRepeatNum] = getNnumber(eventFreqAll);

    % Concatenate the event frequency data from all ROIs
    eventFreqCell = {eventFreqAll.EventFqInBins}; % collect EventFqInBins in a cell array
    eventFreqCell = eventFreqCell(:); % make sure that ef_cell is a vertical array
    eventFreqMat = vertcat(eventFreqCell{:}); % concatenate ef_cell contents and create a number array

    %% Run statistical analysis on the event frequency: Bootstrapping
    % Get the baseline event frequency. Calculate the mean event frequency in the baseline range
    baselineArray = mean(eventFreqMat(:, baselineBinIDX), 2);

    % Calculate the difference between every bin after the baseline to baseline
    binIdxAfterBase = [baselineBinIDX(end)+1 : size(eventFreqMat, 2)]; % index of bins from the first one after baseline to the end
    bootStrapTabCell = cell(numel(binIdxAfterBase), 1); % Create an empty cell to store the bootstrap results
    % signRankTabCell = cell(numel(binIdxAfterBase), 1); % Create an empty cell to store the bootstrap results
    for bn = 1:numel(binIdxAfterBase)
        diff2BaseData = eventFreqMat(:, binIdxAfterBase(bn)) - baselineArray;
        diff2BaseStr = sprintf('bin-%d vs. baseline', binIdxAfterBase(bn));

        % Bootstrap
        [~,~,~,~,bootStrapTabCell{bn}]= bootstrapAnalysis(diff2BaseData, 'label', diff2BaseStr);

        % % SignRank
        % [~, ~, signRankTabCell{bn}] = signedRankAnalysis(diff2BaseData, 'label', diff2BaseStr);
    end

    % Concatenate all the bootstrap and signRank results
    PSTHdata.stat = vertcat(bootStrapTabCell{:});
    % PSTHdata.stat = vertcat(signRankTabCell{:});

    %% Plot the PSTH: boxplot or bar plot
    % Create a structure array for the event frequency data
    PSTHdata.dataStruct = efArray2struct(eventFreqMat, eventFreqAll, binX);

    % Box plot of event freq in various time
    PSTHdata.summaryData = boxPlotOfStructData(PSTHdata.dataStruct, 'val', 'xdata', 'plotWhere', pars.plotwhere, 'xtickLabel', binNames);
    xlabel(pars.xlabelStr);
    xtickangle(pars.xTickAngle);

    if pars.normBase
        ylabelStr = 'Normalized event frequency';
    else
        ylabelStr = 'Event frequency';
    end
    ylabel(ylabelStr);
    titleStr = sprintf('%s \n[%g animals %g recordings %g cells %g stims]',...
		stimulation, PSTHdata.recDateNum, PSTHdata.recNum, PSTHdata.roiNum, PSTHdata.stimRepeatNum); % string for the subtitle
    title(titleStr, 'FontSize', 10)
    if ~isempty(pars.ylimVal)
        ylim(pars.ylimVal);
    end

    %% Assign the output variables
    varargout{1} = pars;
end


function filteredData = getFilteredData(structData, filters)
    % Filter structData based on filters.names and filters.values
    % filters.values can be a logical array or a cell array of strings

    % Initialize filteredData as structData
    filteredData = structData;

    % Loop through each filter name
    for i = 1:length(filters)
        filterName = filters(i).names;
        filterVal = filters(i).vals;

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


function [animalNum, recNum, roiNum, stimRepeats] = getNnumber(eventFreqAll)
    % Extract the n numbers from the event frequency data
    % eventFreqAll.recNames contains the recording names in the format '(\d{8}-\d{6})'

    % Get the unique recording names
    recNamesAll = {eventFreqAll.recNames};

    % Extract the date and time from the recording names
	recNamesAllDate = cellfun(@(x) x(1:8),recNamesAll,'UniformOutput',false);
	recNamesAllDateTime = cellfun(@(x) x(1:15),recNamesAll,'UniformOutput',false);

    % Get the unique date and date_time names
	recNameUniqueDate = unique(recNamesAllDate);
	recNameUniqueDateTime = unique(recNamesAllDateTime);

    % Get the number of animals, recordings, ROIs, and stimulation repeats
	animalNum = numel(recNameUniqueDate);
	recNum = numel(recNameUniqueDateTime);
	roiNum = numel(eventFreqAll);
	stimRepeats = sum([eventFreqAll.stimNum]);
end


function efStruct = efArray2struct(ef, EventFreqInBins, xdata)
	% Convert the ef double array to a structure var for GLMM analysis and plot
	% Borrow 'TrialNames', 'roiNames', 'subNuclei', and 'stimNum' from struct var 'EventFreqInBins'
	% xdata is used to tag various columns of ef data

	% Get the ROI number and the bin number
	roiNum = size(ef, 1);
	binNum = size(ef, 2);

	% Create an empty cell to pre-allocate RAM
	efStructCell = cell(1, binNum);
	% efStructFieldNames = {'val', 'xdata', 'trialNames', 'roiNames', 'subNuclei', 'stimNum'};

	% Extract the fields' content from EventFreqInBins
	trialNames = {EventFreqInBins.recNames};
	roiNames = {EventFreqInBins.roiNames};
	subNuclei = {EventFreqInBins.subNuclei};
	stimNum = [EventFreqInBins.stimNum];

	% Loop through the columns of ef
	for i = 1:binNum
		efDataCell = ensureHorizontal(num2cell(ef(:, i)));
		xdataCell = num2cell(repmat(xdata(i), 1, roiNum));
		efStructCell{i} = struct('val', efDataCell, 'xdata', xdataCell,...
			'trialNames', trialNames, 'roiNames', roiNames, 'subNuclei', subNuclei, 'stimNum', stimNum);
	end

	% Concatenate the cell
	efStruct = horzcat(efStructCell{:});
end