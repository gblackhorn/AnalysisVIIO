function [filteredVIIOdata, varargout] = filterVIIOdataWithStimEffect(VIIOdata, stimEffectFilters, varargin)
%FILTERVIIOdataWITHSTIMEFFECT Filters ROI traces based on stimulation effects across multiple trials.
%   This function filters ROIs in `VIIOdata_allTrials(x).traces` using predefined
%   stimulation effect categories. The categories are specified for excitation, inhibition,
%   rebound, and excitatory AP during N-O.
%
%   The function takes a struct array `VIIOdata` containing multiple trials, each with ROI traces,
%   and a struct array `stimEffectFilters` containing stimulation names and their corresponding filters.
%   It returns a struct array `filteredVIIOdata` with filtered ROI traces, and additional information
%   about the filtering process.
%
%   INPUT:
%       VIIOdata  : Struct array containing multiple trials, each with ROI traces.
%       stimEffectFilters : Struct array containing stimulation names and their corresponding filters.
%                     Each entry should have the fields 'stimName' and 'filters', where 'filters'
%                     is a struct with fields for each effect category (e.g., 'excitation', 'inhibition').
%                     The global variable projCfg.stimEffectFilters can be used for this input.
%                           Example:
%                           stimEffectFilters(1).stimName = 'N-O-5s';
%                           stimEffectFilters(1).filters.excitation = 1;
%                           stimEffectFilters(1).filters.inhibition = NaN;
%                           stimEffectFilters(1).filters.rebound = 0;
%                           stimEffectFilters(1).filters.excitatoryAP = NaN;


%
%   OUTPUT:
%       filteredVIIOdata : Struct array with filtered ROI traces.
%       roiNum           : Struct containing the total number of ROIs before filtering (all),
%                          the number of ROIs kept after filtering (kept), and the number of ROIs
%                          discarded after filtering (discarded).
%
%   EXAMPLE:
%       [filteredVIIOdata, roiNum] = ...
%           filterVIIOdataWithStimEffect(VIIOdata, projCfg.stimEffectFilters);

    % Parse Inputs Using InputParser
    p = inputParser;

    % Required input
    addRequired(p, 'VIIOdata', @(x) isstruct(x) && isfield(x, 'traces'));
    addRequired(p, 'stimEffectFilters', @(x) isstruct(x) && all(isfield(x, {'stimNames', 'filters'})));

    % Optional parameters

    % Parse inputs
    parse(p, VIIOdata, stimEffectFilters, varargin{:});

    % Assign parsed inputs to variables
    VIIOdata = p.Results.VIIOdata;
    stimEffectFilters = p.Results.stimEffectFilters;

    % Extract stimulation names and filters
    stimNames = {stimEffectFilters.stimNames};
    stimFilters = {stimEffectFilters.filters};

    % Initialize output variables
    filteredVIIOdata = VIIOdata;
    roiNumAll = 0;
    roiNumKept = 0;
    roiNumDis = 0;

    % Loop through each trial in VIIOdata
    for trialIdx = 1:numel(VIIOdata)
        roiData = VIIOdata(trialIdx).traces;
        stimName = VIIOdata(trialIdx).stim_name;

        % Initialize logical array to keep all ROIs by default
        roiTF = true(1, numel(roiData));

        % Find the corresponding filter for the current stimulation name
        filterIdx = find(strcmpi(stimNames, stimName), 1);
        if isempty(filterIdx)
            warning('No matching filter found for recording (%d/%d): %s (stimulation name: %s)', trialIdx, numel(VIIOdata), VIIOdata(trialIdx).trialName, stimName);
            roiTF = false(1, numel(roiData));
        else
            filter = stimEffectFilters(filterIdx).filters;
            roiTF = applyStimEffectFilters(roiData, filter);
        end

        % Filter the ROIs based on the logical array roiTF
        filteredVIIOdata(trialIdx).traces = roiData(roiTF);

        % Update the ROI numbers
        roiNumAll = roiNumAll + numel(roiData);
        roiNumKept = roiNumKept + sum(roiTF);
        roiNumDis = roiNumDis + sum(~roiTF);
    end

    % Organize ROI numbers into a struct
    roiNum.all = roiNumAll;
    roiNum.kept = roiNumKept;
    roiNum.discarded = roiNumDis;

    % Assign additional output variables
    varargout{1} = roiNum;
end

function roiTF = applyStimEffectFilters(roiData, filter)
    % Helper function to apply stimulation effect filters to ROI data
    roiTF = true(1, numel(roiData));
    categories = fieldnames(filter);

    for roiIdx = 1:numel(roiData)
        stimEffect = roiData(roiIdx).stimEffect;
        keepROI = true;

        for catIdx = 1:numel(categories)
            category = categories{catIdx};
            filterValue = filter.(category);

            if ~isfield(stimEffect, category)
                warning('Field "%s" is missing in stimEffect.', category);
                continue;
            end

            if ~isnan(filterValue) && stimEffect.(category) ~= filterValue
                keepROI = false;
                break;
            end
        end

        roiTF(roiIdx) = keepROI;
    end
end