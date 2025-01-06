function [barStat, varargout] = eventFreqPSTH(VIIOdata, stimulation, varargin)
%Collect the event frequency from recording(s) applied with the same stimulation type and plot the PSTH
% Return the statistics of the event frequency and compare the bins of the PSTH


    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'VIIOdata', @isstruct);

    % Define optional inputs
    % Filters:
    addParameter(p, 'recFilterNames', {}, @iscell); % Name of fields in VIIOdata to filter recordings
    addParameter(p, 'recFilterVals', {}, @(x) iscell(x)); % Values for the recFilterNames, can be logical or character
    addParameter(p, 'roiFilterNames', {}, @iscell); % Name of fields in recording data (VIIOdata.traces) to filter ROIs
    addParameter(p, 'roiFilterVals', {}, @(x) iscell(x)); % Values for the roiFilterNames, can be logical or character

    % addParameter(p, 'StimTags', {'N-O-5s','AP-0.1s','N-O-5s AP-0.1s'}, @iscell); % Names of stimulations to compare
    % addParameter(p, 'StimEffects', {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}, @iscell); % Filters for different stimulations. [excitation inhibition rebound excitationOfAPduringNO]. nan means no filter
    % addParameter(p, 'subNucleiFilter', '', @ischar); % Filter for sub-nuclei: '', 'DAO', 'PO'

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
    
    % Loop through recordings and collect the event frequency
    for i = 1:length(VIIOdata)
        % Get the ranges of stimulations in the current recording
        stimInfo = VIIOdata(i).stimInfo;
        
        % Filter ROIs using roiFilterNames and roiFilterBool if roiFilterNames is not empty 
        if ~isempty(pars.roiFilterNames)
            VIIOdata(i).traces = getFilteredData(VIIOdata(i).traces, pars.roiFilterNames, pars.roiFilterVals);
        end
        roiNum = length(VIIOdata(i).traces);


        % Set up the PSTH bin edges using default bin width or customised bin edges



        % Loop through the ROIs and collect the event frequency


            % Get the event frequency in the current ROI: using customised bin edges


            % Get the event frequency in the current ROI: using default bin width


    end
    
    % Normalize the event frequency to the baseline if normBase is true
        % Discard the roi/stimTrial if the baseline value is zero. Output a warning message



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