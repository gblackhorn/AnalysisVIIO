function [barStat, varargout] = eventFreqPSTH(VIIOdata, stimulation, varargin)
%Collect the event frequency from recording(s) applied with the same stimulation type and plot the PSTH
% Return the statistics of the event frequency and compare the bins of the PSTH


    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'VIIOdata', @isstruct);

    % Define optional inputs
    % Filters:
    addParameter(p, 'recFilterNames', {}, @iscell); % Name of fields in VIIOdata to filter recordings
    addParameter(p, 'recFilterBool', [], @(x) islogical(x) && isvector(x)); % Boolean values for the recFilterNames
    addParameter(p, 'roiFilterNames', {}, @iscell); % Name of fields in recording data (VIIOdata.traces) to filter ROIs
    addParameter(p, 'roiFilterBool', [], @(x) islogical(x) && isvector(x)); % Boolean values for the roiFilterNames

    % addParameter(p, 'StimTags', {'N-O-5s','AP-0.1s','N-O-5s AP-0.1s'}, @iscell); % Names of stimulations to compare
    % addParameter(p, 'StimEffects', {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}, @iscell); % Filters for different         stimulations. [excitation inhibition rebound excitationOfAPduringNO]. nan means no filter
    % addParameter(p, 'subNucleiFilter', '', @ischar); % Filter for sub-nuclei: '', 'DAO', 'PO'

   % PSTH parameters:
   addParameter(p, 'preStimDur', 6, @isnumeric); % Duration before stimulation onset (s)
   addParameter(p, 'postStimDur', 7, @isnumeric); % Duration after stimulation end (s)
   addParameter(p, 'baseBinStart', -1, @isnumeric); % Start of baseline bin
   addParameter(p, 'baseBinEnd', 0, @isnumeric); % End of baseline bin
   addParameter(p, 'splitStim', [1], @isnumeric); % Split long stimulations
   addParameter(p, 'normBase', false, @islogical); % Normalize data to baseline if true
   addParameter(p, 'discardZeroBase', true, @islogical); % Discard the roi/stimTrial if the baseline value is zero

    
end