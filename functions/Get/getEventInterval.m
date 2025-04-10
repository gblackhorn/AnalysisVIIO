function [eventIntStruct, varargout] = getEventInterval(alignedData, varargin)
    % Get the time stamps of events in a specific category and the time stamps of their following
    % events. Calculate the time difference between the pairs. Store data in a structVar, eventIntStruct

    % Input parser
    p = inputParser;

    % Required input
    addRequired(p, 'alignedData', @isstruct);

    % Optional inputs
    addOptional(p, 'leadingEventCat', '', @ischar); % category of leading event
    addOptional(p, 'followingEventCat', '', @ischar); % category of following event (after the leading event)

    % Optional name-value-paired parameters with default values
    addParameter(p, 'eventTimeType', 'peak_time', @ischar); % 'peak_time'/'rise_time'. Type of event time
    addParameter(p, 'maxDiff', 5, @isnumeric); % The max difference between leading and following events
                                               % If the diff is longer, the paired data will be discarded

    % Parse inputs
    parse(p, alignedData, varargin{:});

    % Assign parsed values to variables
    alignedData = p.Results.alignedData;
    leadingEventCat = p.Results.leadingEventCat;
    followingEventCat = p.Results.followingEventCat;
    eventTimeType = p.Results.eventTimeType;
    maxDiff = p.Results.maxDiff;


	% Get the recording number
	recNum = numel(alignedData);

	% Create cells to store the event intervals. One cell per recording
	eventIntStructRecCell = cell(recNum, 1);

	% Loop through all the recordings
	for rn = 1:recNum
		% Get the name of the recording
		recName = getShortRecName(alignedData(rn).trialName);

		% Get the number and names of neurons
		neuronNum = numel(alignedData(rn).traces);
		% neuronNames = {alignedData(rn).traces.roi};

		% Get the time stamps and categories of events from neurons
		if neuronNum ~= 0
			eventIntStructNeuronCell = cell(neuronNum, 1);
			if isempty(leadingEventCat) && isempty(followingEventCat)
				for nn = 1:neuronNum
					eventIntStructNeuronCell{nn} = getAllEventIntFromNeuron(alignedData(rn).traces(nn), eventTimeType,...
						maxDiff, recName);
				end
			else
				for nn = 1:neuronNum
					eventIntStructNeuronCell{nn} = getEventIntFromNeuron(alignedData(rn).traces(nn), eventTimeType,...
						leadingEventCat, followingEventCat, maxDiff, recName);
				end
			end
			% Concatenate the data from neurons
			eventIntStructRecCell{rn} = vertcat(eventIntStructNeuronCell{:});
		end
	end

	% Concatenate the data from recordings
	eventIntStruct = vertcat(eventIntStructRecCell{:});
end

function shortRecName = getShortRecName(recName)
	% Get the date-time part from the recording name

	% Find the index of the first underscore
	underscoreIndex = find(recName == '_', 1);

	% Separate the parts of the string
	shortRecName = recName(1:underscoreIndex-1);
end

function eventIntStructNeuron = getEventIntFromNeuron(neuronDataStruct, eventTimeType, leadingEventCat, followingEventCat, maxDiff, recName)
	% Get the time stamps of paired leading and following events from a neuron

	neuronName = neuronDataStruct.roi; % Get neuron name

	% Get the categories of events and the idx of leading events
	eventProps = neuronDataStruct.eventProp;
	eventCats = {eventProps.peak_category}; 
	leadingEventTF = strcmpi(eventCats, leadingEventCat); 
	leadingEventIDX = find(leadingEventTF);


	% Create an empty struct var to store the data
	structLength = sum(leadingEventTF);
	eventIntStructNeuronFields = {'recName', 'roi', 'leadingEventCat', 'leadingEventTime', 'followingEventCat', 'followingEventTime', 'pairCat', 'pairTimeDiff'};
	eventIntStructNeuron = empty_content_struct(eventIntStructNeuronFields, structLength);

	% Loop through eventIntStructNeuron and fill in the data
	if structLength > 0
		[eventIntStructNeuron.recName] = deal(recName);		
		[eventIntStructNeuron.roi] = deal(neuronName);		
		[eventIntStructNeuron.leadingEventCat] = deal(leadingEventCat);		
		[eventIntStructNeuron.followingEventCat] = deal(followingEventCat);		
		[eventIntStructNeuron.pairCat] = deal([leadingEventCat, '-', followingEventCat]);		

		disEntryIDX = []; % Used to store the idx of entry to be discarded
		for sl = 1:structLength 
			if leadingEventIDX(sl) ~= numel(eventCats) % if the leading event is not the last event
				idx = leadingEventIDX(sl);
				% Fill the data for the leading event
				eventIntStructNeuron(sl).leadingEventTime = eventProps(idx).(eventTimeType);

				% Fill the data for the following event
				if strcmpi(eventProps(idx+1).peak_category, followingEventCat)
					eventIntStructNeuron(sl).followingEventTime = eventProps(idx+1).(eventTimeType);

					% Calculate the time diff between the leading and the following events
					eventIntStructNeuron(sl).pairTimeDiff = eventIntStructNeuron(sl).followingEventTime - eventIntStructNeuron(sl).leadingEventTime;
					if eventIntStructNeuron(sl).pairTimeDiff > maxDiff
						disEntryIDX = [disEntryIDX, sl];
					end
				else
					disEntryIDX = [disEntryIDX, sl];
				end
			else
				disEntryIDX = [disEntryIDX, sl];
			end
		end

		% Discard the entries marked by disEntryIDX
		eventIntStructNeuron(disEntryIDX) = [];
	end
end

function eventIntStructNeuron = getAllEventIntFromNeuron(neuronDataStruct, eventTimeType, maxDiff, recName)
	% Get the time stamps of paired leading and following events from a neuron

	neuronName = neuronDataStruct.roi; % Get neuron name

	% Get the categories of events and the idx of leading events
	eventProps = neuronDataStruct.eventProp;
	eventCats = {eventProps.peak_category}; 
	% leadingEventTF = strcmpi(eventCats, leadingEventCat); 
	% leadingEventIDX = find(leadingEventTF);


	% Create an empty struct var to store the data
	structLength = numel(eventProps)-1;
	eventIntStructNeuronFields = {'recName', 'roi', 'leadingEventCat', 'leadingEventTime', 'followingEventCat', 'followingEventTime', 'pairCat', 'pairTimeDiff'};
	eventIntStructNeuron = empty_content_struct(eventIntStructNeuronFields, structLength);

	% Loop through eventIntStructNeuron and fill in the data
	if structLength > 0
		[eventIntStructNeuron.recName] = deal(recName);		
		[eventIntStructNeuron.roi] = deal(neuronName);		
		% [eventIntStructNeuron.leadingEventCat] = deal(leadingEventCat);		
		% [eventIntStructNeuron.followingEventCat] = deal(followingEventCat);		
		% [eventIntStructNeuron.pairCat] = deal([leadingEventCat, '-', followingEventCat]);		

		disEntryIDX = []; % Used to store the idx of entry to be discarded
		for idx = 1:structLength 
			% Fill the data for the leading event
			eventIntStructNeuron(idx).leadingEventTime = eventProps(idx).(eventTimeType);
			eventIntStructNeuron(idx).leadingEventCat = eventProps(idx).peak_category;

			% Fill the data for the following event
			eventIntStructNeuron(idx).followingEventTime = eventProps(idx+1).(eventTimeType);
			eventIntStructNeuron(idx).followingEventCat = eventProps(idx+1).peak_category;

			% Fill the pair category of leading and following events
			eventIntStructNeuron(idx).pairCat = ['genericPre', '-', 'genericPost'];

			% Calculate the time diff between the leading and the following events
			eventIntStructNeuron(idx).pairTimeDiff = eventIntStructNeuron(idx).followingEventTime - eventIntStructNeuron(idx).leadingEventTime;
			if eventIntStructNeuron(idx).pairTimeDiff > maxDiff
				disEntryIDX = [disEntryIDX, idx];
			end



			% if leadingEventIDX(idx) ~= numel(eventCats) % if the leading event is not the last event
			% 	idx = leadingEventIDX(idx);
			% 	% Fill the data for the leading event
			% 	eventIntStructNeuron(idx).leadingEventTime = eventProps(idx).(eventTimeType);

			% 	% Fill the data for the following event
			% 	if strcmpi(eventProps(idx+1).peak_category, followingEventCat)
			% 		eventIntStructNeuron(idx).followingEventTime = eventProps(idx+1).(eventTimeType);

			% 		% Calculate the time diff between the leading and the following events
			% 		eventIntStructNeuron(idx).pairTimeDiff = eventIntStructNeuron(idx).followingEventTime - eventIntStructNeuron(idx).leadingEventTime;
			% 		if eventIntStructNeuron(idx).pairTimeDiff > maxDiff
			% 			disEntryIDX = [disEntryIDX, idx];
			% 		end
			% 	else
			% 		disEntryIDX = [disEntryIDX, idx];
			% 	end
			% else
			% 	disEntryIDX = [disEntryIDX, idx];
			% end
		end

		% Discard the entries marked by disEntryIDX
		eventIntStructNeuron(disEntryIDX) = [];
	end
end
