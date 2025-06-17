% STARTUP_TEMPLATE.M - General-purpose project initialization script
disp('Running project startup script...');

% Step 1: Dynamically define the project folder and name
projectFolder = pwd; % Current working directory
[~, projectName] = fileparts(projectFolder); % Get project name from folder name
fprintf('Project folder: %s\n', projectFolder);
fprintf('Project name: %s\n', projectName);

% Step 2: Initialize global variables
global projCfg;
projCfg = struct(...
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
    projCfg.state = projectState; % Attach to global settings
    disp('Loaded saved project state.');
else
    disp('No saved project state found.');
end

% Step 4: Add shared libraries temporarily
% Add shared functions 
addpath(genpath('D:\guoda\Documents\MATLAB\Codes\SharedLibs'));

% Add CNMF-E related libs
addpath(genpath('D:\guoda\Documents\MATLAB\Codes\CNMF_E\ca_source_extraction'));

% Step 4.1: Add 'functions' folder and its subfolders to the path
functionsPath = fullfile(projectFolder, 'functions');
if isfolder(functionsPath)
    addpath(genpath(functionsPath));
    fprintf('Added to path: %s (and subfolders)\n', functionsPath);
else
    warning('functions folder not found at: %s', functionsPath);
end

% Step 4.2: Remove 'nvoke-analysis' and its subfolders from the path
parentFolder = fileparts(projectFolder); % Go one level up
nvokePath = fullfile(parentFolder, 'nvoke-analysis');
if isfolder(nvokePath)
    rmpath(genpath(nvokePath));
    fprintf('Removed from path: %s (and subfolders)\n', nvokePath);
else
    disp('nvoke-analysis folder not found. Skipping path removal.');
end


% Step 5: Load VIIOdata.mat automatically
dataFile = fullfile(projCfg.dataFolder, 'VIIOdata.mat');
if isfile(dataFile)
    load(dataFile, 'VIIOdata'); % Load 'VIIOdata' variable from the .mat file
    projCfg.VIIOdata = VIIOdata; % Attach to global settings (optional)
    disp('Loaded VIIOdata.mat successfully.');
else
    disp('VIIOdata.mat not found.');
end

egDataFile = fullfile(projCfg.dataFolder, 'VIIOdataFig1Example.mat');
if isfile(egDataFile)
    load(egDataFile, 'VIIOdataNoStimExample'); % Load 'VIIOdata' variable from the .mat file
    projCfg.VIIOdataNoStimExample = VIIOdataNoStimExample; % Attach to global settings (optional)
    disp('Loaded VIIOdataFig1Example.mat successfully.');
else
    disp('VIIOdataFig1Example.mat not found.');
end

% Step 5: Add the settings for ROI filter
% ROIs in the recordings applied with various stimulations were filtered
% depend on how they react to the stimulation.
projCfg.stimEffectFilters(1).stimNames = 'N-O-5s';
projCfg.stimEffectFilters(1).filters.excitation = 0;
projCfg.stimEffectFilters(1).filters.inhibition = nan;
projCfg.stimEffectFilters(1).filters.rebound = nan;
projCfg.stimEffectFilters(1).filters.NOAP = nan;

projCfg.stimEffectFilters(2).stimNames = 'AP-0.1s';
projCfg.stimEffectFilters(2).filters.excitation = nan;
projCfg.stimEffectFilters(2).filters.inhibition = nan;
projCfg.stimEffectFilters(2).filters.rebound = nan;
projCfg.stimEffectFilters(2).filters.NOAP = nan;

projCfg.stimEffectFilters(3).stimNames = 'N-O-5s AP-0.1s';
projCfg.stimEffectFilters(3).filters.excitation = 0;
projCfg.stimEffectFilters(3).filters.inhibition = nan;
projCfg.stimEffectFilters(3).filters.rebound = nan;
projCfg.stimEffectFilters(3).filters.NOAP = nan;

% Step 6: Set up the parameters for (Generalized) Linear Mixed Model
% analysis

% Used GLMM for positively skewed data
projCfg.mm.posSkew.Model = 'GLMM'; % Name of the model
projCfg.mm.posSkew.Distribution = 'gamma'; % Fit to a Gamma distribution
projCfg.mm.posSkew.Link = 'log'; % Link function
projCfg.mm.posSkew.HierarchicalVars = {'trialName', 'roiName'}; % Hierarchical vars for random effects in the model

% Used LMM for normal distribution data
projCfg.mm.norm.Model = 'LMM'; % Name of the model
projCfg.mm.norm.Distribution = ''; % LMM should only used on normal distribution. No need to specify this
projCfg.mm.norm.Link = ''; % N.A. for LMM's normal distribution data
projCfg.mm.norm.HierarchicalVars = {'trialName', 'roiName'}; % Hierarchical vars for random effects in the model

disp('Project startup complete.');
