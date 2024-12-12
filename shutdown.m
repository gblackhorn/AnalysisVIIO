% SHUTDOWN_TEMPLATE.M - General-purpose project cleanup script
disp('Running project shutdown script...');

% Step 1: Dynamically define the project folder and name
projectFolder = pwd; % Current working directory
[~, projectName] = fileparts(projectFolder); % Get project name from folder name
fprintf('Project folder: %s\n', projectFolder);
fprintf('Project name: %s\n', projectName);

% Step 2: Save project state (if applicable)
global projectSettings;
if ~isempty(projectSettings) && isfield(projectSettings, 'state')
    projectState = projectSettings.state; %#ok<NASGU> % Save 'state' to file
    save(fullfile(projectFolder, 'projectState.mat'), 'projectState');
    disp('Saved project state.');
else
    disp('No project state to save.');
end

% Step 3: Clear global variables
clear global projectSettings;
disp('Cleared global project settings.');

disp('Project shutdown complete.');
