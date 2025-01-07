function [periStimEdges, varargout] = setPeriStimBinEdges(StimRanges, binWidth, varargin)
    % Return the bin edges for peri-stimulus event frequency calculation.
    %
    % This function defines the edges of time bins around stimulation events.
    %
    % Inputs:
    %   StimRanges - n*2 array of stimulation start and end times. Each row corresponds to a repeat.
    %   binWidth - Width of each histogram bin.
    %
    % Optional Parameters:
    %   'preStimDur' - Duration before stimulation onset (default: 5 seconds).
    %   'postStimDur' - Duration after stimulation end (default: 5 seconds).
    %
    % Outputs:
    %   periStimEdges - Edges of the peri-stimulation sections.
    %   varargout{1} - Time of stimulation onsets. Vector
    %   varargout{2} - Number of stimulus repetitions.
    %   varargout{3} - Names of the bins.

    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'StimRanges', @(x) isnumeric(x) && size(x, 2) == 2);
    addRequired(p, 'binWidth', @isnumeric);

    % Add optional parameters to the parser with default values and comments
    addParameter(p, 'preStimDur', 5, @isnumeric); % Duration before stimulation onset
    addParameter(p, 'postStimDur', 5, @isnumeric); % Duration after stimulation end

    % Parse the inputs
    parse(p, StimRanges, binWidth, varargin{:});

    % Assign parsed values to variables
    StimRanges = p.Results.StimRanges;
    binWidth = p.Results.binWidth;
    preStimDur = p.Results.preStimDur;
    postStimDur = p.Results.postStimDur;

    % Set the start and end of the peri-stimulus range
    periStimRanges = [StimRanges(:,1)-preStimDur, StimRanges(:,2)+postStimDur]; % Add pre- and post-stimulation to the range

    % Get the number of stimulations
    stimRepeatNum = size(StimRanges, 1); % Number of stimulations = number of groups

    % Set the bin edges using the given binWidth
    periStimEdges = [periStimRanges(1):binWidth:periStimRanges(2)]; % PeriStim edges. Stimulation at 0

    % Set the bin names with the center of the bins
    binXcell = num2cell(periStimEdges(1:end-1) + binWidth / 2);
    binNames = cellfun(@num2str, binXcell, 'UniformOutput', false);

    % Assign outputs
    varargout{1} = StimRanges(:, 1); % Time of stimulation onsets.
    varargout{2} = stimRepeatNum;
    varargout{3} = binNames;
end
