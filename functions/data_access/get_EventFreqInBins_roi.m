function [EventFreqInBins,varargout] = get_EventFreqInBins_roi(EventsPeriStimulus,PeriStimulusRange,varargin)
    % Calculate the event frequency in time bins.
    %
    % [EventFreqInBins] = get_EventFreqInBins_roi(EventsPeriStimulus,PeriStimulusRange)
    % 'EventsPeriStimulus' is a vertical cell array/numerical array. As a cell array, 
    % each cell contains events in the 'PeriStimulusRange'. The number of cells is the repeat number 
    % of stimulation. As a numerical array, the repeat number of stimulation should be specified. 
    %
    % Inputs:
    %   EventsPeriStimulus - Cell array or numerical array of events in the peri-stimulus range.
    %   PeriStimulusRange - Range of time around the stimulus.
    %
    % Optional Parameters:
    %   'binWidth' - Width of each histogram bin (default: 1 second).
    %   'denorm' - Denominator used to normalize the event frequency.
    %   'stimRepeats' - Number of stimulus repetitions.
    %   'plotHisto' - Boolean to plot histogram (default: false).
    %   'binEdges' - Custom bin edges for the histogram.
    %
    % Outputs:
    %   EventFreqInBins - Event frequency in each time bin.
    %   varargout{1} - Histogram edges.

    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'EventsPeriStimulus');
    addRequired(p, 'PeriStimulusRange');

    % Add optional parameters to the parser with default values and comments
    addParameter(p, 'binWidth', 1, @isnumeric); % Width of each histogram bin (default: 1 second)
    addParameter(p, 'denorm', [], @isnumeric); % Denominator used to normalize the event frequency
    addParameter(p, 'stimRepeats', [], @isnumeric); % Number of stimulus repetitions
    addParameter(p, 'plotHisto', false, @islogical); % Boolean to plot histogram (default: false)
    addParameter(p, 'binEdges', [], @isnumeric); % Custom bin edges for the histogram

    % Parse the inputs
    parse(p, EventsPeriStimulus, PeriStimulusRange, varargin{:});

    % Assign parsed values to variables
    EventsPeriStimulus = p.Results.EventsPeriStimulus;
    PeriStimulusRange = p.Results.PeriStimulusRange;
    binWidth = p.Results.binWidth;
    denorm = p.Results.denorm;
    stimRepeats = p.Results.stimRepeats;
    plotHisto = p.Results.plotHisto;
    binEdges = p.Results.binEdges;

    % Determine if 'EventsPeriStimulus' is a cell array or numerical array
    if iscell(EventsPeriStimulus)
        stimRepeats = numel(EventsPeriStimulus); % Get number of stimulus repetitions
        EventsPeriStimulus = cell2mat(EventsPeriStimulus);
    else
        if isempty(stimRepeats)
            error('stimRepeats is needed to run function [get_EventFreqInBins_roi]')
        end
    end

    % Set histogram edges
    if ~isempty(binEdges)
        HistEdges = binEdges;
    else
        HistEdges = [PeriStimulusRange(1):binWidth:PeriStimulusRange(2)];
    end
    binWidths = diff(HistEdges);

    % Calculate event counts in histogram bins
    [eventCounts,HistEdges] = histcounts(EventsPeriStimulus,HistEdges); 
    eventCounts_mean = eventCounts/stimRepeats; % Calculate mean event counts
    EventFreqInBins = eventCounts_mean./binWidths; % Calculate event frequency

    % Normalize event frequency if 'denorm' is provided
    if ~isempty(denorm)
        EventFreqInBins = EventFreqInBins/denorm;
    end

    % Plot histogram if 'plotHisto' is true
    if plotHisto
        histogram(EventFreqInBins,HistEdges);
    end

    varargout{1} = HistEdges; % Return histogram edges
end
