% 1. Clear variables and set the default folder for saving figures and vars
clearvars -except recdata_organized alignedData_allTrials seriesData_sync 
PC_name = getenv('COMPUTERNAME'); 
% set folders for different situation
DataFolder = 'G:\Workspace\Inscopix_Seagate';

if strcmp(PC_name, 'GD-AW-OFFICE')
	AnalysisFolder = 'D:\guoda\Documents\Workspace\Analysis\'; % office desktop
elseif strcmp(PC_name, 'LAPTOP-84IERS3H')
	AnalysisFolder = 'C:\Users\guoda\Documents\Workspace\Analysis'; % laptop
end

[FolderPathVA] = set_folder_path_ventral_approach(DataFolder,AnalysisFolder);

%% ====================
% Get recData for series recordings (recording sharing the same ROI sets but using different stimulations)

%% ====================
% 2.1 Examine peak detection with plots 
close all
SavePlot = true; % true or false
PauseTrial = false; % true or false
traceNum_perFig = 10; % number of traces/ROIs per figure
SaveTo = FolderPathVA.fig;
vis = 'off'; % on/off. set the 'visible' of figures
decon = true; % true/false plot decon trace
marker = true; % true/false plot markers

[SaveTo] = plotTracesFromAllTrials(recdata_organized_series,...
	'PauseTrial', PauseTrial,...
	'traceNum_perFig', traceNum_perFig, 'decon', decon, 'marker', marker,...
	'SavePlot', SavePlot, 'SaveTo', SaveTo,...
	'vis', vis);


[SaveTo] = plot_ROIevent_scatter_from_trial_all(recdata_organized_series,...
	'plotInterval',5,'sz',10,'save_fig',SavePlot,'save_dir',SaveTo);
if SaveTo~=0
	FolderPathVA.fig = SaveTo;
end

%% ====================
% 2.2 Discard rois (in recdata_organized) if they are lack of certain types of events
stims = {'ap-0.1s', 'og-5s', 'og-5s ap-0.1s'};
% stims = {'GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
eventCats = {{'trigger'},...
		{'trigger', 'rebound'},...
		{'trigger-beforeStim', 'trigger-interval', 'delay-trigger', 'rebound-interval'}};
debug_mode = false; % true/false
% recdata_organized_series = recdata_organized;
[recdata_organized_series] = discard_recData_roi(recdata_organized_series,'stims',stims,'eventCats',eventCats,'debug_mode',debug_mode);

%% ====================
% Get the alignedData from the recdata_organized after tidying up
% 2.3 Align traces from all trials. Also collect the properties of events
ad.event_type = 'stimWin'; % options: 'detected_events', 'stimWin'
ad.traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
ad.event_data_group = 'peak_lowpass';
ad.event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
ad.event_align_point = 'rise'; % options: 'rise', 'peak'
ad.rebound_duration = 1; % time duration after stimulation to form a window for rebound spikes
ad.cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
%					find a way to combine categories, such as 'nostim' and 'nostimfar'
ad.pre_event_time = 5; % unit: s. event trace starts at 1s before event onset
ad.post_event_time = 10; % unit: s. event trace ends at 2s after event onset
ad.stim_section = true; % true: use a specific section of stimulation to calculate the calcium level delta. For example the last 1s
ad.ss_range = 1; % single number (last n second) or a 2-element array (start and end. 0s is stimulation onset)
ad.stim_time_error = 0.2; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
ad.mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
% filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types
ad.debug_mode = false; % true/false
ad.caDeclineOnly = false; % true/false. Only keep the calcium decline trials (og group)

[alignedData_series] = get_event_trace_allTrials(recdata_organized_series,'event_type', ad.event_type,...
	'traceData_type', ad.traceData_type, 'event_data_group', ad.event_data_group,...
	'event_filter', ad.event_filter, 'event_align_point', ad.event_align_point, 'cat_keywords', ad.cat_keywords,...
	'pre_event_time', ad.pre_event_time, 'post_event_time', ad.post_event_time,...
	'stim_section',ad.stim_section,'ss_range',ad.ss_range,...
	'stim_time_error',ad.stim_time_error,'rebound_duration',ad.rebound_duration,...
	'mod_pcn', ad.mod_pcn,'debug_mode',ad.debug_mode);

if ad.caDeclineOnly % Keep the trials in which og-led can induce the calcium decline, and discard others
	stimNames = {alignedData_series.stim_name};
	[ogIDX] = judge_array_content(stimNames,{'OG-LED'},'IgnoreCase',true); % index of trials using optogenetics stimulation 
	caDe_og = [alignedData_series(ogIDX).CaDecline]; % calcium decaline logical value of og trials
	[disIDX_og] = judge_array_content(caDe_og,false); % og trials without significant calcium decline
	disIDX = ogIDX(disIDX_og); 
	alignedData_series(disIDX) = [];
end 

%% ====================
% 3.1 Sync ROIs across trials in the same series (same FOV, same ROI set) 
% Note: ad.event_type must be "detected_events"
sd.ref_stim = 'ap-0.1s'; % ROIs are synced to the trial applied with this stimulation
sd.ref_SpikeCat = {'spon','trig'}; % {'spon','trig'}. spike/peak/event categories kept during the syncing in ref trials
sd.nonref_SpikeCat = {'spon','rebound'}; % {'spon','rebound','trig-AP'}. spike/peak/event categories kept during the syncing in non-ref trials
[seriesData_sync] = sync_rois_multiseries(alignedData_series,...
	'ref_stim',sd.ref_stim,'ref_SpikeCat',sd.ref_SpikeCat,'nonref_SpikeCat',sd.nonref_SpikeCat);

%% ====================
% 3.2 Group series data using ROI. Each ROI group contains events from trials using various stimulation
ngd.ref_stim = 'ap'; % 'ap'. reference stimulation
ngd.ref_SpikeCat = 'trig'; % 'trig','spon'. reference spike/peak/event category 
ngd.other_SpikeCat = 'rebound'; % 'rebound','spon'. spike/peak/event category in other trial will be plot
ngd.ref_norm = true; % true/false. normalized data with ref_spike values
ngd.exclude_stim = {'og-5s ap-0.1s'};
ngd.contain_ref = true; % true/false
ngd.debug_mode = false;

series_num = numel(seriesData_sync);
for sn = 1:series_num
	alignedData_series = seriesData_sync(sn).SeriesData;
	[seriesData_sync(sn).NeuronGroup_data] = group_aligned_trace_series_ROIpaired(alignedData_series,...
		'ref_stim',ngd.ref_stim,'ref_SpikeCat',ngd.ref_SpikeCat,'other_SpikeCat',ngd.other_SpikeCat,'ref_norm',ngd.ref_norm,...
		'exclude_stim',ngd.exclude_stim,'contain_ref',ngd.contain_ref,'debug_mode', ngd.debug_mode);
end


%% ====================
% 3.3 Plot traces, aligned traces and roi map 
% Set ad.event_type to 'stimWin' when creating alignedData_series.
alignedData_allTrials=alignedData_series;
% Go to section 9.2.0.3 in workflow_ventral_approach_analysis_2 to plot all the traces


%% ====================
% 4.1 Plot spikes of each ROI recorded in trials received various stimulation
close all
psnt.save_fig = true; % true/false
psnt.plot_raw = true; % true/false.
psnt.plot_norm = true; % true/false. plot the ref_trial normalized data
psnt.plot_mean = true; % true/false. plot a mean trace on top of raw traces
psnt.plot_std = true; % true/false. plot the std as a shade on top of raw traces. If this is true, "plot_mean" will be turn on automatically
psnt.y_range = [-5 12];
psnt.tickInt_time = 1; % interval of tick for timeInfo (x axis)
psnt.fig_row_num = 3; % number of rows (ROIs) in each figure
psnt.fig_position = [0.1 0.1 0.5 0.85]; % [left bottom width height]
psnt.FontSize = 20;
psnt.FontWeight = 'bold';
debug_mode = true; % true/false

if psnt.save_fig
	psnt.save_path = uigetdir(FolderPathVA.fig,'Choose a folder to save spikes from series trials');
	if psnt.save_path~=0
		FolderPathVA.fig = psnt.save_path;
	end 
else
	psnt.save_path = '';
end

series_num = numel(seriesData_sync);
for sn = 1:series_num
	series_name = seriesData_sync(sn).seriesName;
	fprintf('Plotting spike/event waveforms. Series %d/%d: %s\n', sn, series_num, series_name)
	% NeuronGroup_data = seriesData_sync(sn).NeuronGroup_data;
	plot_series_neuron_paired_trace(seriesData_sync(sn).NeuronGroup_data,'plot_raw',psnt.plot_raw,'plot_norm',psnt.plot_norm,...
		'plot_mean',psnt.plot_mean,'plot_std',psnt.plot_std,'y_range',psnt.y_range,'tickInt_time',psnt.tickInt_time,...
		'fig_row_num',psnt.fig_row_num,'fig_position',psnt.fig_position,'series_name',series_name,...
		'FontSize',psnt.FontSize,'FontWeight',psnt.FontWeight,...
		'save_fig',psnt.save_path,'debug_mode',debug_mode);
end

%% ====================
% 4.2 Plot the spike/event properties for each neuron
close all
pei.plot_combined_data = true;
pei.parNames = {'rise_duration','peak_mag_delta',...
    'sponnorm_rise_duration','sponnorm_peak_mag_delta'}; % entry: event
% {'rise_duration_refNorm','peak_mag_delta_refNorm','rise_delay'}
% 					
pei.save_fig = false; % true/false
pei.save_dir = FolderPathVA.fig;
pei.stat = true; % true if want to run anova when plotting bars
pei.FontSize = 22;
pei.FontWeight = 'bold';

% stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

if pei.save_fig
	pei.savepath_nogui = uigetdir(FolderPathVA.fig,'Choose a folder to save plot for spike/event prop analysis');
	if pei.savepath_nogui~=0
		FolderPathVA.fig = pei.savepath_nogui;
	else
		error('pei.savepath_nogui for saving plots is not selected')
	end 
else
	pei.savepath_nogui = '';
end

series_num = numel(seriesData_sync);
for sn = 1:series_num
	series_name = seriesData_sync(sn).seriesName;
	% NeuronGroup_data = seriesData_sync(sn).NeuronGroup_data;
	roi_num = numel(seriesData_sync(sn).NeuronGroup_data);
	for rn = 1:roi_num
		close all
		fname_suffix = sprintf('%s-%s', series_name, seriesData_sync(sn).NeuronGroup_data(rn).roi);
		[~, plot_info] = plot_event_info(seriesData_sync(sn).NeuronGroup_data(rn).eventPropData,...
			'plot_combined_data',pei.plot_combined_data,'parNames',pei.parNames,'stat',pei.stat,...
			'save_fig',pei.save_fig,'save_dir',pei.save_dir,'savepath_nogui',pei.savepath_nogui,'fname_suffix',fname_suffix,...
			'FontSize',pei.FontSize,'FontWeight',pei.FontWeight);
		seriesData_sync(sn).NeuronGroup_data(rn).stat = plot_info;
		fprintf('Spike/event properties are from %s - %s\n', series_name, seriesData_sync(sn).NeuronGroup_data(rn).roi);
	end
end

%% ====================
% 5.1 Collect all events from series and plot their REFnorm data
[all_series_eventProp] = collect_AllEventProp_from_seriesData(seriesData_sync);
[grouped_all_series_eventProp] = group_event_info_multi_category(all_series_eventProp,...
	'category_names', {'peak_category'}); % 'group'(event[trial_stim]), 'peak_category'(event)

sort_keywords = {'[ap-0.1s]','[og-5s]','trig','rebound'};
[grouped_all_series_eventProp] = sort_struct_with_str(grouped_all_series_eventProp,...
	'group',sort_keywords); % sort the entries in grouped_all_series_eventProp

close all
pgase.plot_combined_data = true;
pgase.parNames = {'rise_duration','peak_mag_delta','rise_duration_refNorm','peak_mag_delta_refNorm',...
'sponnorm_rise_duration','sponnorm_peak_mag_delta'}; % entry: event
% {'rise_duration_refNorm','peak_mag_delta_refNorm','rise_delay'}
pgase.save_fig = true; % true/false
pgase.save_dir = FolderPathVA.fig;
pgase.stat = true; % true if want to run anova when plotting bars
pgase.stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not
pgase.FontSize = 22;
pgase.FontWeight = 'bold';


% grouped_event_info = grouped_event_info_bk;
[pgase.save_dir, pgase.plot_info] = plot_event_info(grouped_all_series_eventProp,...
	'plot_combined_data', pgase.plot_combined_data, 'parNames', pgase.parNames, 'stat', pgase.stat,...
	'save_fig', pgase.save_fig, 'save_dir', pgase.save_dir,...
	'FontSize',pgase.FontSize,'FontWeight',pgase.FontWeight);
if pgase.save_dir~=0
	FolderPathVA.fig = pgase.save_dir;
end

if pgase.save_fig
	plot_stat_info.grouped_event_info_filtered = grouped_all_series_eventProp;
	plot_stat_info.plot_info = pgase.plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(pgase.save_dir, [dt, '_plot_stat_info']), 'plot_stat_info');
end

%% ====================
% 5.2 paired ttest of rise duration
% averaged rise durations of trig[ap] and of 'rebound[og]' from the same neurons are paired
neuronTags = {'trial','roi'};
groupfield = 'group';
groups = {'trig[ap-0.1s]','rebound[og-5s]'};
parName = 'rise_duration';
[pttest] = pairedtest_eventStruct(all_series_eventProp,...
	neuronTags,groupfield,groups,parName);

%% ====================
% Save processed data
save_dir = uigetdir(FolderPathVA.analysis);
dt = datestr(now, 'yyyymmdd');
save(fullfile(save_dir, [dt, '_seriesData_sync']), 'seriesData_sync','recdata_organized_series','alignedData_series');








