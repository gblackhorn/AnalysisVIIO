function [periStimEdges, binNames, varargout] = customizePeriStimBinEdges(stimInfo,varargin)
    % Set the section edges in a peri-stimulation window.
    %
    % This function defines the edges of time sections around a stimulation event.
    % It supports single or composite stimulations where one stimulation is inside another.
    %
    % Inputs:
    %   stimInfo - Content in a single entry of alignedData.stimInfo.
    %
    % Optional Parameters:
    %   'preStimDuration' - Duration before stimulation onset (default: 5 seconds).
    %   'postStimDuration' - Duration after stimulation end (default: 10 seconds).
    %   'PeriBaseRange' - Range for the baseline period (default: [-5 -2] seconds).
    %   'stimEffectDuration' - Duration of the stimulation effect (default: 1 second).
    %   'splitLongStim' - Array to split long stimulations (default: [1]).
    %
    % Outputs:
    %   periStimEdges - Edges of the peri-stimulation sections. Each row corresponds to a repeat.
    %   varargout{1} - Vector. Time of stimulation onsets. Use the earlier one if multiple stimulations exist)
    %   varargout{2} - Number of stimulus repetitions.
    %   varargout{3} - Names of the bins.

    % Defaults
    preStimDuration = 5;
    postStimDuration = 10;
    PeriBaseRange = [-preStimDuration 0];
    stimEffectDuration = 1; % Duration of stimulation effect in seconds
    splitLongStim = [1]; % Split long stimulations

    % Set the bin names and descriptions
    defaultBinNames(1).name = 'baseline';
    defaultBinNames(1).description = 'Baseline at the very beginning';
    defaultBinNames(2).name = 'preStim';
    defaultBinNames(2).description = 'Before stimulation and after baseline';
    defaultBinNames(3).name = 'firstStim';
    defaultBinNames(3).description = 'Start from stimStart and last ''stimEffectDuration''';
    defaultBinNames(4).name = 'secondStim';
    defaultBinNames(4).description = 'Start from the second-stim start and last ''stimEffectDuration''';
    defaultBinNames(5).name = 'firstStimLasting';
    defaultBinNames(5).description = 'After firstStim and before stimEnd';
    defaultBinNames(6).name = 'firstStimPost';
    defaultBinNames(6).description = 'From first-stim end and last ''stimEffectDuration''';
    defaultBinNames(7).name = 'secondStimLasting';
    defaultBinNames(7).description = 'After secondStim and before stimEnd';
    defaultBinNames(8).name = 'secondStimPost';
    defaultBinNames(8).description = 'From first-stim end and last ''stimEffectDuration''';
    defaultBinNames(9).name = 'baselineAfter';
    defaultBinNames(9).description = 'Baseline after the stimulation';

    debugMode = false; % Enable/disable debug mode

    % Initialize input parser
    p = inputParser;

    % Define optional parameters with default values
    addParameter(p, 'preStimDuration', 5, @isnumeric);
    addParameter(p, 'postStimDuration', 10, @isnumeric);
    addParameter(p, 'PeriBaseRange', [-5 -2], @isnumeric);
    addParameter(p, 'stimEffectDuration', 1, @isnumeric);
    addParameter(p, 'splitLongStim', [1], @isnumeric);

    % Parse the inputs
    parse(p, varargin{:});
    pars = p.Results;

    % Assign parsed values to variables
    preStimDuration = pars.preStimDuration;
    postStimDuration = pars.postStimDuration;
    PeriBaseRange = pars.PeriBaseRange;
    stimEffectDuration = pars.stimEffectDuration;
    splitLongStim = pars.splitLongStim;

    % Check the stimulation info and decide the section numbers accordingly
    stimDurationStruct = stimInfo.StimDuration;
    stimRepeatNum = stimInfo.UnifiedStimDuration.repeats;
    stimRangeAlignedAll = vertcat(stimInfo.StimDuration.range_aligned);
    [stimStartSort, stimStartSortIDX] = sort(stimRangeAlignedAll(:,1)); 
    [stimEndSort, stimEndSortIDX] = sort(stimRangeAlignedAll(:,2)); 
    stimStartSecIDX = [];

    % Compose the peri-stimulation edges from the end of the first stimulation to the last edge
    if numel(stimDurationStruct) > 1
        % Multiple stimulations form a composite stimulation
        [periStimEdges, binNames, stimStartSecIDX] = setCompositeStimEdges(stimDurationStruct, stimStartSortIDX, stimEffectDuration, defaultBinNames, stimRepeatNum);
    else
        % Single stimulation
        [periStimEdges, binNames, stimStartSecIDX] = setSingleStimEdges(stimDurationStruct, stimStartSortIDX, stimEffectDuration, splitLongStim, defaultBinNames, stimRepeatNum);
    end

    % Compose the peri-stimulation edges from the baseline start to the beginning of the first stimulation 
    periStimEdges(:,1) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) - preStimDuration;
    binNames{1} = defaultBinNames(1).name;
    periStimEdges(:,2) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) + PeriBaseRange(2);
    binNames{2} = defaultBinNames(2).name;
    periStimEdges(:,3) = stimDurationStruct(stimStartSortIDX(1)).range(:,1);
    binNames{3} = defaultBinNames(3).name;
    periStimEdges(:,end) = stimDurationStruct(stimStartSortIDX(1)).range(:,2) + postStimDuration;
    stimStartSecIDX = [stimStartSecIDX 3];

    % Remove the 'preStim' bin if baseline ends at the beginning of the stimulation
    if isequal(periStimEdges(:,2), periStimEdges(:,3)) % If the baseline end and preStim end are the same
        periStimEdges(:,3) = [];
        binNames(2) = [];
    end

    % Create one row of PSTH bin edges relative to the first stimulation
    periStimEdgesStimRef = periStimEdges(1, :) - stimInfo.UnifiedStimDuration.range(1, 1); 

   % Assign outputs
    varargout{1} = stimInfo.UnifiedStimDuration.range(:, 1); % Time of stimulation onsets. Use the earlier one if multiple stimulations exist)
    varargout{2} = periStimEdgesStimRef;
    varargout{3} = stimRepeatNum;
end

function [periStimEdges, binNames, stimStartSecIDX] = setCompositeStimEdges(stimDurationStruct, stimStartSortIDX, stimEffectDuration, defaultBinNames, stimRepeatNum)
    sectionEdgesNum = 8;
    periStimEdges = NaN(stimRepeatNum, sectionEdgesNum);
    binNames = cell(1, (sectionEdgesNum-1));

    % Set edges for composite stimulation
    periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(end)).range(:,1);
    binNames{4} = defaultBinNames(4).name;
    periStimEdges(:,5) = stimDurationStruct(stimStartSortIDX(end)).range(:,1) + stimEffectDuration;
    binNames{5} = defaultBinNames(5).name;
    periStimEdges(:,6) = stimDurationStruct(stimStartSortIDX(1)).range(:,2);
    binNames{6} = defaultBinNames(6).name;
    periStimEdges(:,7) = stimDurationStruct(stimStartSortIDX(1)).range(:,2) + stimEffectDuration;
    binNames{7} = defaultBinNames(7).name;
    stimStartSecIDX = [4];
end

function [periStimEdges, binNames, stimStartSecIDX] = setSingleStimEdges(stimDurationStruct, stimStartSortIDX, stimEffectDuration, splitLongStim, defaultBinNames, stimRepeatNum)
    % Decide the number of bins based on the duration of the stimulation effect
    if stimDurationStruct.fixed < stimEffectDuration
        % Include bins: baseline, preStim, firstStim, baselineAfter
        sectionEdgesNum = 5; 

        % pre-allocation for the edges
        periStimEdges = NaN(stimRepeatNum, sectionEdgesNum);

        % Assign the first three bin names: baseline, preStim, firstStim
        % binNames = cell(1, (sectionEdgesNum-1));
        binNames = defaultBinNames(1:3);

        periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) + stimEffectDuration;
        binNames{4} = defaultBinNames(9).name;
    else
        lateStimEdgesNum = numel(splitLongStim);
        sectionEdgesNum = 7 + lateStimEdgesNum;
        periStimEdges = NaN(stimRepeatNum, sectionEdgesNum);
        binNames = cell(1, (sectionEdgesNum-1));

        if lateStimEdgesNum > 0
            if stimEffectDuration + splitLongStim(end) >= stimDurationStruct.fixed
                error('The last element in splitLongStim is >= stimDuration, stimWindow cannot be further splitted')
            end
            periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) + stimEffectDuration;
            binNames{4} = sprintf('%s%g', defaultBinNames(5).name, 1);
            for n = 1:lateStimEdgesNum
                periStimEdges(:,4+n) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) + stimEffectDuration + splitLongStim(n);
                binNames{4+n} = sprintf('%s%g', defaultBinNames(5).name, n+1);
            end
        end
        periStimEdges(:,sectionEdgesNum-2) = stimDurationStruct(stimStartSortIDX(1)).range(:,2);
        binNames{sectionEdgesNum-2} = defaultBinNames(6).name;
        periStimEdges(:,sectionEdgesNum-1) = stimDurationStruct(stimStartSortIDX(1)).range(:,2) + stimEffectDuration;
        binNames{sectionEdgesNum-1} = defaultBinNames(9).name;
    end
    stimStartSecIDX = [];
end

