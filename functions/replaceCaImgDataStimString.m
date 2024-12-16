function caImgData = replaceCaImgDataStimString(caImgData, A, B, caseSensitive, exactMatch)
%Replace stimulation strings in nRIM calcium struct data
%   Designed for 'alignedData' structure
%
%   caImgData = replaceCaImgDataStimString(caImgData, A, B, caseSensitive, exactMatch)
%
% Inputs:
%   caImgData     - Structure array containing calcium imaging data (check alignedData)
%   A             - Cell array of strings to search for.
%   B             - Cell array of strings to replace with (same length as A).
%   caseSensitive - Logical flag: true for case-sensitive replacement,
%                   false for case-insensitive.
%   exactMatch    - Logical flag: true for exact match replacement,
%                   false for pattern/substring matching.
%
% Outputs:
%   caImgData - Updated structure array with replaced stimulation strings.

    % Input validation
    if ~isstruct(caImgData)
        error('Input caImgData must be a structure array.');
    end
    if ~iscell(A) || ~iscell(B) || length(A) ~= length(B)
        error('Inputs A and B must be cell arrays of the same length.');
    end
    if nargin < 5
        error('All six inputs, including exactMatch, must be provided.');
    end

    % Replace the strings in "caImgData(n).stim_name"
    caImgData = replaceFieldStrings(caImgData, 'stim_name', A, B, caseSensitive, exactMatch);


    % Replace the strings in "caImgData(n).stimInfo"
    % Loop through all recordings
    for m = 1:numel(caImgData)
        % Replace the strings in "caImgData(n).stimInfo.StimDuration"
        caImgData(m).stimInfo.StimDuration = replaceFieldStrings(caImgData(m).stimInfo.StimDuration,...
        'type', A, B, caseSensitive, exactMatch);

        % Replace the strings in "caImgData(n).stimInfo.UnifiedStimDuration"
        caImgData(m).stimInfo.UnifiedStimDuration = replaceFieldStrings(caImgData(m).stimInfo.UnifiedStimDuration,...
            'type', A, B, caseSensitive, exactMatch);

        % Loop through every ROIs in the current recording
        for n = 1:numel(caImgData(m).traces)
            caImgData(m).traces(n).eventProp = replaceFieldStrings(caImgData(m).traces(n).eventProp,...
                'stim_tags', A, B, caseSensitive, exactMatch);  
        end
    end

end
