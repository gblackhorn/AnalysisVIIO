% STARTUP_TEMPLATE.M - General-purpose project initialization script
disp('Running project startup script...');

% Step 1: Dynamically define the project folder and name
projectFolder = pwd; % Current working directory
[~, projectName] = fileparts(projectFolder); % Get project name from folder name
fprintf('Project folder: %s\n', projectFolder);
fprintf('Project name: %s\n', projectName);

% Step 2: Initialize global variables
global projectSettings;
projectSettings = struct(...
    'projectName', projectName, ...
    'projectFolder', projectFolder, ...
    'dataFolder', fullfile(projectFolder, 'data'), ...
    'resultsFolder', fullfile(projectFolder, 'results'), ...
    'startupTime', datestr(now) ...
);
disp('Initialized global project settings.');

% Step 3: Load saved project state (if available)
stateFile = fullfile(projectFolder, 'projectState.mat');
if isfile(stateFile)
    load(stateFile, 'projectState'); % Load 'projectState' variable
    projectSettings.state = projectState; % Attach to global settings
    disp('Loaded saved project state.');
else
    disp('No saved project state found.');
end

% Step 4: Add shared libraries temporarily
% Add shared functions 
addpath(genpath('D:\guoda\Documents\MATLAB\Codes\SharedLibs'));

% Add CNMF-E related libs
addpath(genpath('D:\guoda\Documents\MATLAB\Codes\CNMF_E\ca_source_extraction'));

% Step 5: Load VIIOdata.mat automatically
dataFile = fullfile(projectSettings.dataFolder, 'VIIOdata.mat');
if isfile(dataFile)
    load(dataFile, 'VIIOdata'); % Load 'VIIOdata' variable from the .mat file
    projectSettings.VIIOdata = VIIOdata; % Attach to global settings (optional)
    disp('Loaded VIIOdata.mat successfully.');
else
    disp('VIIOdata.mat not found.');
end

egDataFile = fullfile(projectSettings.dataFolder, 'VIIOdataFig1Example.mat');
if isfile(egDataFile)
    load(egDataFile, 'VIIOdataNoStimExample'); % Load 'VIIOdata' variable from the .mat file
    projectSettings.VIIOdataNoStimExample = VIIOdataNoStimExample; % Attach to global settings (optional)
    disp('Loaded VIIOdataFig1Example.mat successfully.');
else
    disp('VIIOdataFig1Example.mat not found.');
end

% Step 5: Add the settings for ROI filter
% ROIs in the recordings applied with various stimulations were filtered
% depend on how they react to the stimulation.
projectSettings.ROIfilter.StimTags = {'N-O-5s','AP-0.1s','N-O-5s AP-0.1s'}; % 
projectSettings.ROIfilter.StimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApNO]. ex: excitation. in: inhibition. rb: rebound. exApNO: exitatory effect of AP during N-O


disp('Project startup complete.');
