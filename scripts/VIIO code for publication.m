% VIIO figure creating script

figFolder = projectSettings.projectFolder;

%% ==========
% Example showing the difference between raw traces and CNMFe-denoised traces
% Note: There must be mat and csv files containing traces data in the 'save_dir'
close all

% Settings for figure
saveFig = false; % true/false

% Setup the folder path to save plots
saveDir = fullfile(projectSettings.projectFolder,'CaImgExample_noStim');

% Setup the path of the CSV file containing raw traces
csvTraceFilePath = fullfile(projectSettings.dataFolder  , '2021-03-29-14-19-43_VIIOdataFig1Example.csv');


close all
saveFig = false; % true/false
saveDir = fullfile(projectSettings.projectFolder,'CaImgExample_noStim');
csvTraceFilePath = fullfile(projectSettings.dataFolder  , '2021-03-29-14-19-43_VIIOdataFig1Example.csv');
[figHandles, processedData] = createCaImgExampleFig(projectSettings.VIIOdataNoStimExample,...
	csvTraceFilePath, saveDir, saveFig);



%% ==========
% Create the mean spontaneous traces in DAO and PO
% Note: Load mat file containing all the recordings 
% Fig2 B

% % Note: 'event_type' for alignedData must be 'detected_events'
save_fig = false; % true/false
save_dir = FolderPathVA.fig;
% at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'. Indicate what value should be used to normalize the traces
% at.stimNames = ''; % If empty, do not screen recordings with stimulation, instead use all of them
% at.eventCat = 'spon'; % options: 'trig','trig-ap','rebound','spon', 'rebound'
% at.subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.
% at.plot_combined_data = true; % mean value and std of all traces
% at.showRawtraces = false; % true/false. true: plot every single trace
% at.showMedian = false; % true/false. plot raw traces having a median value of the properties specified by 'at.medianProp'
% at.medianProp = 'FWHM'; % 
% at.shadeType = 'ste'; % plot the shade using std/ste
% at.y_range = [-10 20]; % [-10 5],[-3 5],[-2 1]

subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.

close all

% Create a cell to store the trace info
traceInfo = cell(1,numel(subNucleiTypes));

% Loop through the subNucleiTypes
for i = 1:numel({'DAO','PO'})
	[~,traceInfo{i}] = AlignedCatTracesSinglePlot(alignedData_allTrials,'','spon',...
		'normMethod','highpassStd','subNucleiType',subNucleiTypes{i},...
		'showRawtraces',false,'showMedian',false,'medianProp','FWHM',...
		'plot_combined_data',true,'shadeType','ste','y_range',[-10 20]);
	% 'sponNorm',at.sponNorm,'normalized',at.normalized,

	if i == 1
		guiSave = 'on';
	else
		guiSave = 'off';
	end
	if save_fig
		save_dir = savePlot(gcf,'guiSave', guiSave, 'save_dir', save_dir, 'fname', traceInfo{i}.fname);
	end
end
traceInfo = [traceInfo{:}];

if save_fig
	save(fullfile(save_dir,'alignedCalTracesInfo'), 'traceInfo');
	FolderPathVA.fig = save_dir;
end




%% ==========

