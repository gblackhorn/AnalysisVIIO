% VIIO figure creating script

figFolder = projectSettings.projectFolder;

%% ==========
% Example showing the difference between raw traces and CNMFe-denoised traces
% Fig1 C, Fig2 A, C
close all
saveFig = true; % true/false

% Setup the folder path to save plots
saveDir = fullfile(projectSettings.resultsFolder,'CaImgExample_noStim');

% Setup the path of the CSV file containing raw traces
csvTraceFilePath = fullfile(projectSettings.dataFolder  , '2021-03-29-14-19-43_VIIOdataFig1Example.csv');

% Plot ROIs' traces in the example recording 
csvTraceFilePath = fullfile(projectSettings.dataFolder  , '2021-03-29-14-19-43_VIIOdataFig1Example.csv');
[figHandles, processedData] = createCaImgExampleFig(projectSettings.VIIOdataNoStimExample,...
	csvTraceFilePath, saveDir, saveFig);


%% ==========
% Create the mean spontaneous traces in DAO and PO
% Note: Load mat file containing all the recordings 
% Fig2 B
close all
saveFig = true; % true/false
saveDir = fullfile(projectSettings.resultsFolder,'SponEventExample');
subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.

% Create a cell to store the trace info
traceInfo = cell(1,numel(subNucleiTypes));

% Loop through the subNucleiTypes
for i = 1:numel({'DAO','PO'})
	% Plot the mean trace
	[~,traceInfo{i}] = AlignedCatTracesSinglePlot(projectSettings.VIIOdata,'','spon',...
		'normMethod','highpassStd','subNucleiType',subNucleiTypes{i},...
		'showRawtraces',false,'showMedian',false,'medianProp','FWHM',...
		'plot_combined_data',true,'shadeType','ste','y_range',[-10 20]);

	% Save plots
    if saveFig
	    saveDir = savePlot(gcf,'guiSave', 'off', 'save_dir', saveDir, 'fname', traceInfo{i}.fname);
    end
end


%% ==========
% Extract properties of events, group and analyze them
% Settings for plots
saveFig = true; % true/false
saveDir = fullfile(projectSettings.resultsFolder,'EventProp');
props = {'FWHM','peak_delta_norm_hpstd','rise_duration'}; % Properties to by analyzed
dataDist = 'posSkewed'; % Setup data distribution for GLMM fitting


% Setup the filters to exclude the ROIs showing the excitatory response to optogenetic activation of N-O terminals
filterROIs = true; % true/false. If true, screen ROIs using the settings below
StimTags = {'N-O-5s','AP-0.1s','N-O-5s AP-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
StimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

% Create a dataset only containing the ROIs tagged with cluster info to compare "cluster" and "single" evnets
mustHaveField = 'type'; % Field 'type' contains the cluster information (cluster/sync vs. single/async)
[VIIOdataSynchInfo] = validateAlignedDataStructForEventAnalysis(projectSettings.VIIOdata, mustHaveField);

% Use two ways to group spon events: Separte them using the applied stimulation or not
sponSepTF = [true, false];

% Setup the event property fields used for grouping.
groupFields = {{'peak_category','subNuclei'},... 
	{'peak_category'},...
	{'peak_category','subNuclei','type'},...
	{'peak_category','type'}};

% Grouped events using the settings above will be saved in the fields with following names in 'eventStruct'
% Length of 'eventStructFields' must the same as the length of 'groupFields'
eventStructFields = {'noSyncTag',...
	'noSyncTagMergeSubN',...
	'SyncTag',...
	'SyncTagMergeSubN'};

for m = 1:numel(sponSepTF)
	% Decide the field name based on if spon events are separated using stimulation
	if sponSepTF(m)
		% eventStructFieldName = [eventStructFields{n}, 'SponSep'];
		sponGroupFieldName = 'stimSepratedSpon';
	else
		% eventStructFieldName = eventStructFields{n};
		sponGroupFieldName = 'mergedSpon';
	end

	for n = 1:numel(groupFields)
		close all
		% Check if 'type' is used for grouping
		typeTF = strcmp(groupFields{n}, 'type');
		if isempty(find(typeTF, 1))
			VIIOdata = projectSettings.VIIOdata; % Use all ROIs if 'type' is not used
		else
			VIIOdata = VIIOdataSynchInfo; % Use the 'type' containing ROIs
		end

		% Group events
		[eventStruct.(sponGroupFieldName).(eventStructFields{n})] = extractAndGroupEvents(VIIOdata, groupFields{n},...
			'filterROIs',filterROIs,'filterROIsStimTags',projectSettings.ROIfilter.StimTags,'filterROIsStimEffects',projectSettings.ROIfilter.StimEffects,...
			'entry', 'event', 'separateSpon', sponSepTF(m), 'modifyEventTypeName', true);

		% Setup the comparison types, GLMM parameters for analysis and plots
		[mmModel, mmHierarchicalVars, mmDistribution, mmLink, organizeStruct] =...
		 VIIOinitEventPropAnalysis(groupFields{n}, 'dataDist', dataDist, 'separateSPONT', sponSepTF(m));

		% Analyze and plot eventProp
        subFolder = fullfile(saveDir, sponGroupFieldName, eventStructFields{n});
		[~, ~] = plotEventPropMultiGroups(eventStruct.(sponGroupFieldName).(eventStructFields{n}), props, organizeStruct,...
			'mmModel', mmModel, 'mmHierarchicalVars', mmHierarchicalVars, 'mmDistribution', mmDistribution, 'mmLink', mmLink,...
			'saveFig', saveFig, 'saveDir', subFolder);

	end
end


%% ==========
% Extract frequency and interval of spon events in ROIs and analyze them
% Settings for plots
saveFig = true; % true/false
saveDir = fullfile(projectSettings.resultsFolder,'EventProp');
props = {'sponfq','sponInterval','cv2'}; % Properties to by analyzed
dataDist = 'posSkewed'; % Setup data distribution for GLMM fitting


% Setup the filters to exclude the ROIs showing the excitatory response to optogenetic activation of N-O terminals
filterROIs = true; % true/false. If true, screen ROIs using the settings below
StimTags = {'N-O-5s','AP-0.1s','N-O-5s AP-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
StimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

% b. Create grouped_event for plotting ROI properties
ggSetting.entry = 'roi'; % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated.
ggSetting.separateSpon = false; % true/false. Separated spon using stimualtion
ggSetting.groupField = {'peak_category','subNuclei'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[roiStructForPlot] = getAndGroup_eventsProp(alignedData_allTrials,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',filterROIs,'filterROIsStimTags',StimTags,'filterROIsStimEffects',StimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Group using stim_name: This will be used to calculate the event probability
ggSetting.groupField = {'stim_name'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
ggSetting.dis_spon = true; % true/false. Discard spontaneous events
[roiStructForEventProb] = getAndGroup_eventsProp(alignedData_allTrials,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',filterROIs,'filterROIsStimTags',StimTags,'filterROIsStimEffects',StimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);