function [eventFreqPSTH,varargout] = calcPeriStimEventFreqInROI(eventTimeStamps, periStimBinEdges, binEdgeRefs, varargin)
	% Given event times and periStimBinEdges (Bin edges), return the event frequencies in sections
	%
	% This function calculates the peri-stimulus time histogram (PSTH) of event frequencies
	% within specified time bins around stimulation events. It aligns event timestamps to 
	% the reference time points (usually the start of stimulation) and computes the event 
	% frequencies for each bin across multiple repetitions of the stimulation.
	%
	% Inputs:
	% - eventTimeStamps: a vector of event time points
	% - periStimBinEdges: a matrix whose size is (stimRepeatNum, edgesNum), containing the bin edges for each stimulation repeat
	% - binEdgeRefs: the reference time points to align the events to. These are usually the time points of the stimulation starts
	%
	% Outputs:
	% - eventFreqPSTH: a vector containing the event frequencies for each bin, summed across all stimulation repeats
	% - varargout{1}: binEdgesPSTH, the aligned bin edges for the PSTH
	% - varargout{2}: eventHistCounts, the histogram counts of events for each bin and each stimulation repeat
	% - varargout{3}: sectionsDuration, the duration of each bin for each stimulation repeat
	%
	% Example usage:
	% [eventFreqPSTH, binEdgesPSTH, eventHistCounts, sectionsDuration] = calcPeriStimEventFreqInROI(eventTimeStamps, periStimBinEdges, binEdgeRefs);
	%
	% Note: The function assumes that the input periStimBinEdges and binEdgeRefs are properly aligned and correspond to each other.


	% Defaults
	reoundDigitSig = 2; % round to the Nth significant digit for duration

	% Validate inputs
	if length(binEdgeRefs) ~= size(periStimBinEdges, 1)
		error('The length of binEdgeRefs must be equal to the number of rows in periStimBinEdges.');
	end

	% Calculate the repeat number of the stimulation
	stimRepeatNum = size(periStimBinEdges,1);

	% Create a variable to store the section durations
	sectionsDuration = NaN(stimRepeatNum,size(periStimBinEdges,2)-1);

	% Create a variable to store the histcounts
	eventHistCounts = NaN(stimRepeatNum,size(periStimBinEdges,2)-1);

	% Create a cell variable to store the event time points
	eventsPeriStimulus = cell(stimRepeatNum,1); % Create an empty cell array to store the EventTimeStamps around each stimulation

	% Loop through all repeats and collect events for every stimRepeat
	for n = 1:stimRepeatNum
		% Get the section for a single stim repeat
		sectSingleRepeat = periStimBinEdges(n,:);
		periStimRange = [sectSingleRepeat(1) sectSingleRepeat(end)];

		% Get the events in a peri-stim range
		eventIDX = find(eventTimeStamps>=periStimRange(1) & eventTimeStamps<=periStimRange(2));
		eventsPeriStimulus{n} = eventTimeStamps(eventIDX);

		% Hist-count the events in a single peri-stim range using periStimBinEdges as the edges
		eventHistCounts(n,:) = histcounts(eventsPeriStimulus{n},sectSingleRepeat);
		
		% Calculate the durations of every section
		sectionsDuration(n,:) = diff(sectSingleRepeat);

		% % Change the event time to peri-stim
		% eventsPeriStimulus{n} = eventsPeriStimulus{n}-binEdgeRefs(n);
	end

	% Align the bin edges to the binEdgeRefs. Use the first repeat of stimulation
	binEdgesPSTH = periStimBinEdges(1, :) - binEdgeRefs(1);
	binEdgesPSTH = round(binEdgesPSTH, reoundDigitSig, 'significant');

	% Sum the event counts across all repeats
	eventHistCountsAll = sum(eventHistCounts,1);
	% Sum the section durations across all repeats
	sectionsDurationAll = sum(sectionsDuration,1);

	% Calculate the event frequency by dividing the total event counts by the total section durations
	eventFreqPSTH = eventHistCountsAll./sectionsDurationAll;

	% Assign the output
	varargout{1} = binEdgesPSTH;
	varargout{2} = eventHistCounts;
	varargout{3} = sectionsDuration;
end

