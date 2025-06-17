function [ROIeventProp_new,varargout] = add_tau_for_specificEvents(ROIeventProp,eventCat,stimTime,tauStimIDX,tauVal,varargin)
	% ADD_TAU_FOR_SPECIFICEVENTS Add decay constant (tau) to specific events in ROI event properties.
	%   [ROIeventProp_new, ...] = ADD_TAU_FOR_SPECIFICEVENTS(ROIeventProp, eventCat, stimTime, tauStimIDX, tauVal)
	%   returns a new event property structure with the decay constant (tau) added for specific events.
	%
	%   Inputs:
	%       ROIeventProp - A structure containing event properties for a single ROI.
	%       eventCat - The category of events to which the tau values will be added (e.g., 'rebound').
	%       stimTime - A vector containing the end times of stimulations.
	%       tauStimIDX - A vector containing the indices of stimulations for which tau values are available.
	%       tauVal - A vector containing the tau values corresponding to the stimulations.
	%
	%   Outputs:
	%       ROIeventProp_new - The updated event property structure with the tau values added.
	%
	%   Example:
	%       [ROIeventProp_new] = add_tau_for_specificEvents(ROIeventProp, 'rebound', stimTime, tauStimIDX, tauVal);

	% Initialize the new event property structure
	ROIeventProp_new = ROIeventProp;

	% Add a new field 'decayTau' if it does not exist
	if ~isfield(ROIeventProp_new,'decayTau')
		defaultValue = {[]}; % create a cell array with the default value for the new field
		[ROIeventProp_new(:).decayTau] = deal(defaultValue{:}); % use deal to assign the default value to each structure
	end

	% Find the index for specific type of events (e.g., 'rebound')
	tf_idx_events = strcmpi({ROIeventProp_new.peak_category}, eventCat);
	idx_events = find(tf_idx_events);

	% Find the closest stimulation for each screened event
	[~, idxStim] = find_closest_in_array([ROIeventProp_new(idx_events).rise_time], stimTime);

	% Assign the tau values to the new field
	if ~isempty(idx_events)
		eventNum = numel(idx_events); % number of events with specified category
		for n = 1:eventNum
			idxStim_event = idxStim(n); % stimulation index for this single event
			pos_tauStimIDX = find(tauStimIDX == idxStim_event);
			if ~isempty(pos_tauStimIDX) % if tau value exists for this certain stimulation
				ROIeventProp_new(idx_events(n)).decayTau = tauVal(pos_tauStimIDX);
			end
		end
	end
end