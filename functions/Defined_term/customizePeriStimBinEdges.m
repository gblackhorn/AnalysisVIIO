function [periStimEdges,varargout] = customizePeriStimBinEdges(stimInfo,varargin)
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
    PeriBaseRange = [-preStimDuration -2];
    stimEffectDuration = 1; % Duration of stimulation effect in seconds
    splitLongStim = [1]; % Split long stimulations
    groupName.base = 'baseline'; % Baseline at the very beginning
    groupName.preBase = 'preStim'; % Before stimulation and after baseline
    groupName.firstStim = 'firstStim'; % Start from stimStart and last 'stimEffectDuration'
    groupName.lateFirstStim = 'lateFirstStim'; % After firstStim and before stimEnd
    groupName.postFirstStim = 'postFirstStim'; % From first-stim end and last 'stimEffectDuration'
    groupName.secondStim = 'secondStim'; % Start from the second-stim start and last 'stimEffectDuration'
    groupName.baseAfter = 'baseAfter'; % Baseline after the stimulation
    debugMode = false; % Enable/disable debug mode

    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('preStimDuration', varargin{ii})
            preStimDuration = varargin{ii+1};
        elseif strcmpi('postStimDuration', varargin{ii})
            postStimDuration = varargin{ii+1};
        elseif strcmpi('PeriBaseRange', varargin{ii})
            PeriBaseRange = varargin{ii+1};
        elseif strcmpi('stimEffectDuration', varargin{ii})
            stimEffectDuration = varargin{ii+1};
        elseif strcmpi('splitLongStim', varargin{ii})
            splitLongStim = varargin{ii+1};
        end
    end

    % Check the stimulation info and decide the section numbers accordingly
    stimDurationStruct = stimInfo.StimDuration;
    stimRepeatNum = stimInfo.UnifiedStimDuration.repeats;
    stimRangeAlignedAll = vertcat(stimInfo.StimDuration.range_aligned);
    [stimStartSort, stimStartSortIDX] = sort(stimRangeAlignedAll(:,1)); 
    [stimEndSort, stimEndSortIDX] = sort(stimRangeAlignedAll(:,2)); 
    stimStartSecIDX = [];

    if numel(stimDurationStruct) > 1
        % Multiple stimulations form a composite stimulation
        compStim = true;
        sectionEdgesNum = 8;
        periStimEdges = NaN(stimRepeatNum, sectionEdgesNum);
        binNames = cell(1, (sectionEdgesNum-1));

        % Set edges for composite stimulation
        periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(end)).range(:,1);
        binNames{4} = groupName.secondStim;
        periStimEdges(:,5) = stimDurationStruct(stimStartSortIDX(end)).range(:,1) + stimEffectDuration;
        binNames{5} = groupName.lateFirstStim;
        periStimEdges(:,6) = stimDurationStruct(stimStartSortIDX(1)).range(:,2);
        binNames{6} = groupName.postFirstStim;
        periStimEdges(:,7) = stimDurationStruct(stimStartSortIDX(1)).range(:,2) + stimEffectDuration;
        binNames{7} = groupName.baseAfter;
        stimStartSecIDX = [stimStartSecIDX 4];
    else
        % Single stimulation
        compStim = false;
        if stimDurationStruct.fixed < stimEffectDuration
            sectionEdgesNum = 5;
            periStimEdges = NaN(stimRepeatNum, sectionEdgesNum);
            binNames = cell(1, (sectionEdgesNum-1));
            periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) + stimEffectDuration;
            binNames{4} = groupName.baseAfter;
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
                binNames{4} = sprintf('%s%g', groupName.lateFirstStim, 1);
                for n = 1:lateStimEdgesNum
                    periStimEdges(:,4+n) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) + stimEffectDuration + splitLongStim(n);
                    binNames{4+n} = sprintf('%s%g', groupName.lateFirstStim, n+1);
                end
            end
            periStimEdges(:,sectionEdgesNum-2) = stimDurationStruct(stimStartSortIDX(1)).range(:,2);
            binNames{sectionEdgesNum-2} = groupName.postFirstStim;
            periStimEdges(:,sectionEdgesNum-1) = stimDurationStruct(stimStartSortIDX(1)).range(:,2) + stimEffectDuration;
            binNames{sectionEdgesNum-1} = groupName.baseAfter;
        end
    end

    % Set the first and last edges
    periStimEdges(:,1) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) - preStimDuration;
    binNames{1} = groupName.base;
    periStimEdges(:,2) = stimDurationStruct(stimStartSortIDX(1)).range(:,1) + PeriBaseRange(2);
    binNames{2} = groupName.preBase;
    periStimEdges(:,3) = stimDurationStruct(stimStartSortIDX(1)).range(:,1);
    binNames{3} = groupName.firstStim;
    periStimEdges(:,end) = stimDurationStruct(stimStartSortIDX(1)).range(:,2) + postStimDuration;
    stimStartSecIDX = [stimStartSecIDX 3];

   % Assign outputs
    varargout{1} = stimInfo.UnifiedStimDuration.range(:, 1); % Time of stimulation onsets. Use the earlier one if multiple stimulations exist)
    varargout{2} = stimRepeatNum;
    varargout{2} = binNames;
end

