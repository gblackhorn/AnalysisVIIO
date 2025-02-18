function [varargout] = sumSponDurationAllNeurons(VIIOdata, varargin)
    %Sum the duration without any stimulation for all neurons across all recordings

    %Input: VIIOdata - the data structure containing recordings

    %Output: varargout - the sum of the duration without any stimulation for all neurons across all recordings

    % Initialize input parser
    p = inputParser;

    % Define optional parameters with default values
    addParameter(p, 'durationFieldName', 'UnifiedStimDuration', @ischar); % Field in VIIOdata.stimInfo
    addParameter(p, 'fullTimeFieldName', 'fullTime', @ischar); % Field in VIIOdata
    addParameter(p, 'postStimDuration', 0, @isnumeric); % Duration after the end of the stimulation to exclude from the spontaneous activity

    % Parse input arguments
    parse(p, varargin{:});
    pars = p.Results;

    % Initialize totalSponDuration
    totalSponDuration.PO = 0;
    totalSponDuration.DAO = 0;
    
    % Loop through all recordings
    for i = 1:length(VIIOdata)
        % Check if neuron data is present in the current recording
        if isempty(VIIOdata(i).traces)
            continue;
        end

        % Get the full duration of the current recording
        fullDuration = VIIOdata(i).(pars.fullTimeFieldName)(end) - VIIOdata(i).(pars.fullTimeFieldName)(1); 

        % Get the stimulation duration information for the current recording
        stimDurationInfo = VIIOdata(i).stimInfo.(pars.durationFieldName);

        % Calculate the non-spontaneous duration for the current recording
        nonSponDuration = sum(stimDurationInfo.range(:, 2) - stimDurationInfo.range(:, 1)) + pars.postStimDuration * size(stimDurationInfo, 1);

        % Calculate the spontaneous duration for the current recording
        sponDuration = fullDuration - nonSponDuration;

        % Calculate the number of neurons in the subnuclei PO and DAO
        subNs = {VIIOdata(i).traces.subNuclei};
        nPO = sum(strcmp(subNs, 'PO'));
        nDAO = sum(strcmp(subNs, 'DAO'));

        % Add the spontaneous duration for the current recording to totalSponDuration
        totalSponDuration.PO = totalSponDuration.PO + sponDuration * nPO; % Multiply by the number of PO neurons in the current recording
        totalSponDuration.DAO = totalSponDuration.DAO + sponDuration * nDAO; % Multiply by the number of DAO neurons in the current recording
    end

    varargout{1} = totalSponDuration;
end