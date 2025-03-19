function [stimEffect,varargout] = get_stimEffect(traceTimeInfo,traceData,stimTimeInfo,eventCats,varargin)
	% GET_STIMEFFECT Summarize the effect of stimulation on calcium levels.
	%   [stimEffect, details] = GET_STIMEFFECT(traceTimeInfo, traceData, stimTimeInfo, eventCats)
	%   returns a structure summarizing the effect of stimulation on calcium levels.
	%
	%   Inputs:
	%       traceTimeInfo - Vector containing the full time information of a trial recording.
	%       traceData - Vector containing the calcium level information from a single ROI.
	%       stimTimeInfo - n x 2 array with the start and end times of stimulations.
	%       eventCats - Cell array containing event categories of all events in a single ROI.
	%
	%   Optional Inputs:
	%       'base_timeRange' - Time range for baseline calculation (default: 2 seconds).
	%       'ex_eventCat' - Event categories defining excitation (default: {'trig'}).
	%       'rb_eventCat' - Event categories defining rebound (default: {'rebound'}).
	%       'in_thresh_stdScale' - Threshold for inhibition based on standard deviation (default: 2).
	%       'in_calLength' - Length of time for inhibition calculation (default: 1 second).
	%       'freq_spon_stim' - Frequencies of spontaneous and stimulation events.
	%
	%   Outputs:
	%       stimEffect - Structure summarizing the stimulation effect with fields:
	%           'excitation' - Boolean indicating if excitation was detected.
	%           'exAP_eventCat' - Boolean indicating if excitation caused by airpuff during OG stimulation was detected.
	%           'inhibition' - Boolean indicating if inhibition was detected.
	%           'rebound' - Boolean indicating if rebound was detected.
	%       details - Structure with additional details about the stimulation effect.
	%
	%   Example:
	%       [stimEffect, details] = get_stimEffect(traceTimeInfo, traceData, stimTimeInfo, eventCats, ...
	%           'base_timeRange', 2, 'ex_eventCat', {'trig'}, 'rb_eventCat', {'rebound'});

	% Defaults
	base_timeRange = 2; % default 2 seconds
	ex_eventCat = {'trig'}; % event category string used to define excitation
	exAP_eventCat = {'trig-ap'}; % event category string used to define excitation caused by airpuff during OG stimulation
	rb_eventCat = {'rebound'}; % event category string used to define rebound
	in_thresh_stdScale = 2; % n times of std lower than baseline level
	in_calLength = 1; % calculate the last n seconds trace level during stimulation
	freq_spon_stim = []; % frequencies of spontaneous and stimulation events
	logRatio_threshold = 0; % threshold for log(stimfq/sponfq)
	perc_meanInDiff = 0.25; % percentage of stimulations with significant mean_in_diff to confirm inhibition

	% Parse optional inputs
	for ii = 1:2:(nargin-4)
	    if strcmpi('base_timeRange', varargin{ii})
	        base_timeRange = varargin{ii+1};
        elseif strcmpi('ex_eventCat', varargin{ii})
	        ex_eventCat = varargin{ii+1};
        elseif strcmpi('rb_eventCat', varargin{ii})
	        rb_eventCat = varargin{ii+1};
        elseif strcmpi('in_thresh_stdScale', varargin{ii})
	        in_thresh_stdScale = varargin{ii+1};
        elseif strcmpi('in_calLength', varargin{ii})
	        in_calLength = varargin{ii+1};
        elseif strcmpi('freq_spon_stim', varargin{ii})
	        freq_spon_stim = varargin{ii+1};
	    end
	end	

	% Initialize output
	stimEffect.excitation = false;
	stimEffect.exAP_eventCat = false;
	stimEffect.inhibition = false;
	stimEffect.rebound = false;

	% Initialize additional details
	details.meanIn = NaN;
	details.meanIn_average = NaN;
	details.base_timeLength = base_timeRange;
	details.in_timeLength = in_calLength;
	details.sponStim_logRatio = NaN;

	if ~isempty(stimTimeInfo)
		stim_duration = stimTimeInfo(1,2) - stimTimeInfo(1,1);
		if in_calLength > stim_duration
			in_calLength = stim_duration;
		end

		in_range = stimTimeInfo; % range of time for calculating the inhibition effect
		in_range(:, 1) = in_range(:, 2) - in_calLength; % modify the start of in_range according to in_calLength
		in_range = get_realTime(in_range, traceTimeInfo); % Get the closest time info in traceTimeInfo

		base_range = get_baseline_timeRange(stimTimeInfo(:, 1), traceTimeInfo, 'base_timeRange', base_timeRange);

		[mean_in, std_in] = get_meanVal_in_timeRange(in_range, traceTimeInfo, traceData);
		[mean_base, std_base] = get_meanVal_in_timeRange(base_range, traceTimeInfo, traceData);

		% Check for inhibition
		% Compare the calcium level at baseline (prior to stim) and during stimulation
		repeat_num = numel(mean_in);
		tfRepeat_in = false(size(mean_in));
		mean_in_diff = mean_in - (mean_base - std_base * in_thresh_stdScale);
		in_loc = find(mean_in_diff < 0);
		tfRepeat_in(in_loc) = true;

		% If the calcium level decreases in perc_meanInDiff% of the stimulations, confirm the decrease in calcium level 
		if numel(find(tfRepeat_in)) >= perc_meanInDiff * repeat_num
			stimEffect.inhibition = true;
		end

		% Check the event frequency to confirm the inhibition effect
		if ~isempty(freq_spon_stim) 
			for fn = 1:numel(freq_spon_stim)
				if freq_spon_stim(fn) == 0 % if spontaneous/stimulation event frequency is 0
					freq_spon_stim(fn) = 1e-5;
				end
			end
			logRatio = log(freq_spon_stim(2) / freq_spon_stim(1));
			if logRatio >= logRatio_threshold
				stimEffect.inhibition = false;
			end
			details.sponStim_logRatio = logRatio;
		end

		% Check for excitation
		for n_exCat = 1:numel(ex_eventCat)
			tf = strcmpi(ex_eventCat{n_exCat}, eventCats);
			if ~isempty(find(tf))
				stimEffect.excitation = true;
				break;
			end
		end

		% Check for excitation caused by airpuff during optogenetics stimulation
		for n_exAPCat = 1:numel(exAP_eventCat)
			tf = strcmpi(exAP_eventCat{n_exAPCat}, eventCats);
			if ~isempty(find(tf))
				stimEffect.exAP_eventCat = true;
				break;
			end
		end

		% Check for rebound
		for n_rbCat = 1:numel(rb_eventCat)
			tf = strcmpi(rb_eventCat{n_rbCat}, eventCats);
			if ~isempty(find(tf))
				stimEffect.rebound = true;
				break;
			end
		end

		avg_meanInDiff = mean(mean_in_diff);
		details.meanIn = mean_in_diff;
		details.meanIn_average = avg_meanInDiff;
	else
		stimEffect.excitation = NaN;
		stimEffect.exAP_eventCat = NaN;
		stimEffect.inhibition = NaN;
		stimEffect.rebound = NaN;
	end

	varargout{1} = details;
end