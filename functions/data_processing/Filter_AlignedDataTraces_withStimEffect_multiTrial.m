function [alignedData_filtered,varargout] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,varargin)
%FILTER_ALIGNEDDATATRACES_WITHSTIMEFFECT_MULTITRIAL Filters ROI traces based on stimulation effects across multiple trials.
%   This function filters ROIs in `alignedData_allTrials(x).traces` using predefined
%   stimulation effect thresholds. The thresholds are specified for excitation, inhibition,
%   rebound, and excitatory AP during OG.
%
%   USAGE:
%       [alignedData_filtered, roi_idxWithSubNinfo, roiNum_all, roiNum_kept, roiNum_dis] = ...
%           Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData, ...
%           'stim_names', {'N-O-5s', 'AP-0.1s'}, 'filters', {[0 NaN NaN NaN], [0 NaN NaN NaN]});
%
%   INPUT:
%       alignedData  : Struct array containing multiple trials, each with ROI traces.
%
%   OPTIONAL PARAMETERS:
%       'stim_names' : Cell array of stimulation names. Each corresponds to a specific filter.
%                     Default: {'N-O-5s', 'AP-0.1s', 'N-O-5s AP-0.1s'}
%       'filters'    : Cell array of filters for excitation, inhibition, rebound, and exApOg.
%                     Example: {[0 NaN NaN NaN], [0 NaN NaN NaN]}.
%                     Filters must match the number of stim_names.
%
%   OUTPUT:
%       alignedData_filtered : Struct array with filtered ROI traces.
%       roi_idxWithSubNinfo  : Combined ROI indices with sub-information across all trials.
%       roiNum_all           : Total number of ROIs before filtering.
%       roiNum_kept          : Number of ROIs kept after filtering.
%       roiNum_dis           : Number of ROIs discarded after filtering.
%
%   EXAMPLE:
%       [alignedData_filtered, roi_info, total, kept, discarded] = ...
%           Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData, ...
%           'stim_names', {'AP-0.1s'}, 'filters', {[0 NaN NaN NaN]});

    % ====================
    % Parse Inputs Using InputParser
    p = inputParser;

    % Required input
    addRequired(p, 'alignedData', @(x) isstruct(x) && isfield(x, 'traces'));

    % Optional parameters
    addParameter(p, 'stim_names', {'N-O-5s','AP-0.1s','N-O-5s AP-0.1s'}, @(x) iscell(x) && all(cellfun(@ischar, x)));
    addParameter(p, 'filters', {[0 nan nan nan], [0 nan nan nan], [0 nan nan nan]}, @(x) iscell(x) && all(cellfun(@isnumeric, x)));

    % Parse inputs
    parse(p, alignedData, varargin{:});

    % Assign parsed inputs to variables
    stim_names = p.Results.stim_names;
    filters = p.Results.filters;

    % Validate stim_names and filters size consistency
    if numel(stim_names) ~= numel(filters)
        error('The number of elements in stim_names must match the number of filters.');
    end

    % ====================
    % Initialize Variables
    alignedData_filtered = alignedData; % Copy input data for filtering
    trial_num = numel(alignedData_filtered); % Number of trials

    roiNum_all = 0;  % Total ROI count
    roiNum_kept = 0; % ROIs retained after filtering
    roiNum_dis = 0;  % ROIs discarded after filtering
    disTrialIdx = []; % Trials that do not match stim_names
    roi_idxWithSubNinfo_cell = cell(1, trial_num); % Cell to store ROI indices with info

    % ====================
    % Process Trials One by One
    for tn = 1:trial_num
        trialData = alignedData_filtered(tn); % Extract data for the current trial
        if ~isfield(trialData, 'stim_name') || ~isfield(trialData, 'traces')
            error('Each trial in alignedData must contain fields "stim_name" and "traces".');
        end
        roiNum_all = roiNum_all + numel(trialData.traces); % Update total ROI count

        % Determine which filter to use based on stimulation name
        stimName = trialData.stim_name; % Stimulation name for the trial
        filter_idx = find(strcmpi(stim_names, stimName)); % Find matching stimulation filter
        
        if ~isempty(filter_idx)
            filter_chosen = filters{filter_idx}; % Use the corresponding filter
            screen_data_tf = true; % Enable filtering for this trial
        else
            disTrialIdx = [disTrialIdx tn]; % Mark trial for exclusion
            roiNum_dis = roiNum_dis + numel(trialData.traces); % Update discarded ROI count
            screen_data_tf = false; % Skip filtering for this trial
        end

        % ====================
        % Apply Filters to ROIs
        if screen_data_tf
            trialDataFiltered = trialData;
            [trialDataFiltered.traces, roi_idx, roi_idxWithSubNinfo_cell{tn}] = ...
                Filter_AlignedDataTraces_withStimEffect(trialData.traces, ...
                'ex', filter_chosen(1), 'in', filter_chosen(2), 'rb', filter_chosen(3), 'exApOg', filter_chosen(4));

            % Assign filtered traces back to the trial data
            alignedData_filtered(tn) = trialDataFiltered;
            roiNum_kept = roiNum_kept + numel(roi_idx); % Update kept ROI count
            roiNum_dis = roiNum_dis + numel(trialData.traces) - numel(roi_idx); % Update discarded ROI count

            % Ensure the ROI info is horizontal and add stim name
            roi_idxWithSubNinfo_cell{tn} = ensureHorizontal(roi_idxWithSubNinfo_cell{tn});
            [roi_idxWithSubNinfo_cell{tn}.stim] = deal(stimName); % Add stimulation name to ROI info
        end
    end

    % ====================
    % Finalize Outputs
    alignedData_filtered(disTrialIdx) = []; % Remove trials without matching stim_names
    roi_idxWithSubNinfo = [roi_idxWithSubNinfo_cell{:}]; % Combine ROI indices with info

    % Assign outputs
    varargout{1} = roi_idxWithSubNinfo;
    varargout{2} = roiNum_all;
    varargout{3} = roiNum_kept;
    varargout{4} = roiNum_dis;
end
