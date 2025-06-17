function [eventProp_new,varargout] = add_tfTag_to_eventProp(eventProp,fieldName,targetContent,varargin)
	% ADD_TFTAG_TO_EVENTPROP Add a boolean tag field to event properties.
	%   [eventProp_new, newFieldName, tagField] = ADD_TFTAG_TO_EVENTPROP(eventProp, fieldName, targetContent)
	%   returns a new event property structure with an additional boolean tag field.
	%
	%   Inputs:
	%       eventProp - A structure containing event properties for a single ROI.
	%       fieldName - The name of the field to search for the target content.
	%       targetContent - The content to search for in the specified field.
	%
	%   Optional Inputs:
	%       'newFieldName' - The name of the new tag field to be added (default: 'tag').
	%
	%   Outputs:
	%       eventProp_new - The updated event property structure with the new tag field.
	%       newFieldName - The name of the new tag field.
	%       tagField - The boolean tag field added to the event properties.

	% Define default value for the new field name
	newFieldName = 'tag';

	% Parse optional inputs
	for ii = 1:2:(nargin-3)
	    if strcmpi('newFieldName', varargin{ii})
	        newFieldName = varargin{ii+1};
	    end
	end	

	% Initialize the new event property structure
	eventProp_new = eventProp;
	fieldContent = {eventProp(:).(fieldName)};
	structSize = size(fieldContent);

	% Create the boolean tag field based on the presence of target content
	tf_content = strcmpi(targetContent, fieldContent);
	if ~isempty(find(tf_content))
		tagField = num2cell(logical(ones(structSize)));
	else
		tagField = num2cell(logical(zeros(structSize)));
	end

	% Check if the new field name already exists in the structure
	if isfield(eventProp_new, newFieldName)
		error('Error in func [add_tfTag_to_eventProp]. \n - field %s exists. Use another one for newFieldName', newFieldName);
	else
		[eventProp_new.(newFieldName)] = tagField{:};
	end

	% Return the new field name and tag field as additional outputs
	varargout{1} = newFieldName;
	varargout{2} = tagField{1};
end