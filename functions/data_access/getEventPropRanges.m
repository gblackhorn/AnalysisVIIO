function valueRanges = getEventPropRanges(eventStruct, varargin)
% GETEVENTPROPRANGES Get the min and max values of specified event properties.
%   valueRanges = GETEVENTPROPRANGES(eventStruct) returns a structure array
%   containing the minimum and maximum values of specified properties in the
%   input event structure array eventStruct.
%
%   Input:
%       eventStruct - A structure array containing event data.
%
%   Output:
%       valueRanges - A structure array with fields 'propName', 'min', and 'max'
%                     representing the property name, minimum value, and maximum
%                     value of each specified property.
%
%   Example:
%       eventStruct(1).rise_duration = 1.2;
%       eventStruct(1).FWHM = 2.3;
%       eventStruct(1).peak_delta_norm_hpstd = 0.5;
%       eventStruct(2).rise_duration = 1.5;
%       eventStruct(2).FWHM = 2.1;
%       eventStruct(2).peak_delta_norm_hpstd = 0.7;
%       valueRanges = getEventPropRanges(eventStruct);

    % Input parser
    p = inputParser;

    % Define required and optional parameters with default values
    addRequired(p, 'eventStruct', @isstruct);
    addParameter(p, 'propNames', {'rise_duration', 'FWHM', 'peak_delta_norm_hpstd'}, @iscell);

    % Parse the inputs
    parse(p, eventStruct, varargin{:});
    pars = p.Results;

    % Initialize the output structure array
    propNum = length(pars.propNames);
    valueRanges = empty_content_struct({'propName', 'min', 'max'}, propNum);

    % Iterate over each property name to compute min and max values
    for i = 1:propNum
        % Check if the property exists in the eventStruct
        if isfield(eventStruct, pars.propNames{i})
            % Get the array of the property values
            propValues = {eventStruct.(pars.propNames{i})};
            
            % Check if all values are numeric
            if all(cellfun(@isnumeric, propValues))
                % Convert to numeric array
                propValArray = cell2mat(propValues);
                
                % Store the property name, min value, and max value in the output structure
                valueRanges(i).propName = pars.propNames{i};
                valueRanges(i).min = min(propValArray);
                valueRanges(i).max = max(propValArray);
            else
                % Issue a warning if non-numeric values are found and skip the property
                warning('Property %s contains non-numeric values. Skipping...', pars.propNames{i});
            end
        else
            % Issue a warning and skip the property
            warning('Property %s does not exist in the eventStruct. Skipping...', pars.propNames{i});
        end
    end

end