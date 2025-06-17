function [figHandles, processedData] = createCaImgExampleFig(VIIOdata, csvFilePath, saveDir, saveFig, varargin)
% CREATECALCIUMFIGURES - Generate and save figures from calcium imaging data
%
% INPUTS:
%   - VIIOdata: Struct containing data for the recording (e.g., ROI traces, FOV matrix).
%   - csvFilePath: Path to the CSV file with raw dF/F data.
%   - saveDir: Directory where figures will be saved.
%   - saveFig: Boolean flag (true/false) to enable saving of figures.
%   - varargin: Optional key-value pairs for additional configurations (e.g., Y-tick display).
%
% OUTPUTS:
%   - figHandles: Struct containing handles to all generated figures.
%   - processedData: Struct containing intermediate processed data (e.g., event times, traces).
%
% EXAMPLE USAGE:
%   [figHandles, processedData] = createCalciumFigures(VIIOdata, csvFilePath, saveDir, true);

% Parse optional inputs
p = inputParser;
addParameter(p, 'showYtickRight', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'colorRepresent', 'peak_delta_norm_hpstd', @ischar);
addParameter(p, 'unitWidth', 0.4, @(x) isnumeric(x) && x > 0);
addParameter(p, 'unitHeight', 0.4, @(x) isnumeric(x) && x > 0);
parse(p, varargin{:});
opts = p.Results;

% Initialize outputs
figHandles = struct();
processedData = struct();

% Create save directory if it doesn't exist
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

% Extract useful data from VIIOdata
shortRecName = extractDateTimeFromFileName(VIIOdata.trialName); % e.g., "2021-03-29-14-19-43"
roiNames = {VIIOdata.traces.roi}; % ROI names
shortRoiNames = cellfun(@(x) x(7:end), roiNames, 'UniformOutput', false); % Trim prefix "neuron"
processedData.roiNames = roiNames;

% Plot 1: FOV with ROI labels
imageMatrix = VIIOdata.roi_map; % 2D matrix for FOV
roiBoundaries = {VIIOdata.traces.roiEdge}; % ROI edges
nameExampleRecFOV = [shortRecName, ' FOV'];
figHandles.FOV = fig_canvas(1, 'unit_width', opts.unitWidth, 'unit_height', opts.unitHeight, 'fig_name', nameExampleRecFOV);
plotCalciumImagingWithROIs(imageMatrix, roiBoundaries, shortRoiNames, ...
    'Title', nameExampleRecFOV, 'AxesHandle', gca);

% Plot 2: Raw dF/F data from CSV
nameIDPStrace = [shortRecName, ' RAW with noise'];
figHandles.RawTrace = fig_canvas(1, 'unit_width', opts.unitWidth, 'unit_height', opts.unitHeight, 'fig_name', nameIDPStrace);
[csvTraceTitle, csvFolder] = plotCalciumTracesFromIDPScsv('AxesHandle', gca, 'folderPath', saveDir, ...
    'showYtickRight', opts.showYtickRight, 'Title', nameIDPStrace, 'filePath', csvFilePath);
set(gcf, 'Renderer', 'painters'); % Better vector graphics for saving

% Plot 3: Denoised dF/F traces
nameCNMFeTrace = [shortRecName, ' denoised by CNMFe'];
timeData = VIIOdata.fullTime; % Time vector
tracesData = [VIIOdata.traces.fullTrace]; % Denoised traces
eventTime = get_TrialEvents_from_alignedData(VIIOdata, 'peak_time'); % Peak event times
figHandles.DenoisedTrace = fig_canvas(1, 'unit_width', opts.unitWidth, 'unit_height', opts.unitHeight, 'fig_name', nameCNMFeTrace);
plot_TemporalData_Trace(gca, timeData, tracesData, 'ylabels', shortRoiNames, ...
    'showYtickRight', opts.showYtickRight, 'titleStr', nameCNMFeTrace, ...
    'plot_marker', true, 'marker1_xData', eventTime);
set(gcf, 'Renderer', 'painters');
processedData.eventTimes = eventTime;

% Plot 4: Calcium events scatter plot
nameEventScatter = sprintf('%s eventScatter', shortRecName);
colorData = get_TrialEvents_from_alignedData(VIIOdata, opts.colorRepresent); % Scatter colors
trace_xlim = xlim; % Use x-limits from denoised trace plot
figHandles.EventScatter = fig_canvas(1, 'unit_width', opts.unitWidth, 'unit_height', opts.unitHeight, 'fig_name', nameEventScatter);
plot_TemporalRaster(eventTime, 'plotWhere', gca, 'colorData', colorData, ...
    'norm2roi', true, 'rowNames', shortRoiNames, 'x_window', trace_xlim, ...
    'xtickInt', 25, 'yInterval', 5, 'sz', 20);
set(gcf, 'Renderer', 'painters');

% Save figures if saveFig is true
if saveFig
    savePlot(figHandles.FOV, 'guiSave', 'off', 'save_dir', saveDir, 'fname', nameExampleRecFOV);
    savePlot(figHandles.RawTrace, 'guiSave', 'off', 'save_dir', saveDir, 'fname', nameIDPStrace);
    savePlot(figHandles.DenoisedTrace, 'guiSave', 'off', 'save_dir', saveDir, 'fname', nameCNMFeTrace);
    savePlot(figHandles.EventScatter, 'guiSave', 'off', 'save_dir', saveDir, 'fname', nameEventScatter);
    disp('Figures saved successfully.');
end
end
