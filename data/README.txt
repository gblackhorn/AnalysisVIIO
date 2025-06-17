2021-03-29-14-19-43_video_sched_0-PP-crop-BP-MC-IDPS-ROI-traces.csv
	- Exported from the Inscopix Data Processing Software
	- Contains neuropil signals

VIIOdataNoPrune.mat
	- Original Name: ogIn-apEx-ogEX_ProcessedData 1sReboundWin correctRoiLoc.mat

VIIOdata.mat
	- Removed unused fields from VIIOdataNoPrune.mat 


# VIIOdata Overview

This folder stores processed datasets in MATLAB format for the VIIO manuscript. The `VIIOdata.mat` file contains a structure array `VIIOdata` for each trial.

Only a subset of fields are retained in order to keep the repository small. The tables below list these retained fields with short descriptions.

## Fields kept in `VIIOdata(n)`

| Field | Description |
|-------|-------------|
| `trialName` | Recording identifier, derived from the file name containing date and time information |
| `event_type` | How events were collected (e.g. `detected_events` or `stimWin`) |
| `stim_name` | Name of the stimulation protocol used in the trial |
| `stimInfo` | Structure describing stimulation timing and parameters |
| `traces` | Array of ROI–specific data structures (see table below) |
| `time` | Time vector aligned to the extracted events |
| `fullTime` | Absolute time vector of the entire recording |
| `synchFoldValue` | Relative level of synchronous activity in this trial |

## Fields kept in `VIIOdata(n).traces(m)`

| Field | Description |
|-------|-------------|
| `roi` | ROI label or name |
| `value` | Event traces' value for plotting or analysis |
| `subNuclei` | Sub‑nucleus assignment of the ROI |
| `eventProp` | Structure array of event properties for this ROI (see table below) |
| `fullTrace` | Denoised fluorescence trace |
| `fullTraceDecon` | Deconvolved activity trace |
| `hpStd` | High‑pass filtered trace standard deviation |
| `stimEvent_possi` | Stimulation‑related event probability information |
| `stimTrig` | Vector of stimulation onset times |
| `sponfq` | Frequency of spontaneous events (Hz) |
| `sponInterval` | Mean interval between spontaneous events (s) |
| `cv2` | CV2 of consecutive inter‑event intervals |
| `sponEventNum` | Number of spontaneous events detected |

## Fields kept in `VIIOdata(n).traces(m).eventProp(k)`

| Field | Description |
|-------|-------------|
| `rise_time` | Timestamp of event onset (s) |
| `rise_loc` | Index of event onset in the trace |
| `rise_duration` | Time from onset to peak (s) |
| `peak_time` | Timestamp of event peak (s) |
| `peak_loc` | Index of event peak in the trace |
| `FWHM` | Full width at half maximum of the event |
| `peak_mag_delta` | Event amplitude (dF/F) |
| `peak_delta_norm_hpstd` | Amplitude normalised to ROI `hpStd` |
| `peak_category` | Event category label (e.g. spontaneous or triggered) |
| `stim_tags` | Tags linking the event to specific stimuli |
| `rise_delay` | Delay from stimulus onset to event rise |
| `peak_delay` | Delay from stimulus onset to event peak |
| `sponnorm_peak_mag_delta` | Peak amplitude normalised to spontaneous events |
| `type` | `0` for single/asynchronous events, `1` for cluster/synchronous |
| `spikeClusterGroup` | Cluster identifier when the event is part of a spike cluster |
| `roiSynchRatio` | Fraction of spikes from this ROI occurring in clusters |
| `trialSynchRatio` | Overall cluster event ratio for the trial |
| `clusterSize` | Number of ROIs participating in the cluster |

These field lists match those defined in `functions/Organize/pruneVIIOdataStruct.m` which was used to prune the original data structure.





# Data Folder README

This folder contains all datasets related to the **AnalysisVIIO** project. The files are used for analysis, testing, and figure reproduction.

## File Descriptions

- **2021-03-29-14-19-43_VIIOdataFig1Example.csv**: CSV version of the VIIOdataFig1Example dataset for cross-platform plotting or external analysis.
- **VIIOdata.mat**: Main dataset for VIIO analysis, typically pruned for efficient processing.
- **VIIOdataFig1Example.mat**: Compact dataset used to generate Figure 1 in the project or publication.
- **VIIOdataNoPrune.mat**: Unpruned version of the dataset containing all original fields, useful for pruning comparisons or backup.

## Notes

- Use `VIIOdata.mat` for most analysis scripts.
- `VIIOdataNoPrune.mat` is useful for testing pruning operations.
- Figure 1 can be reproduced using `VIIOdataFig1Example.mat` or the corresponding CSV.


# VIIOdata Overview

The `VIIOdata.mat` file contains a structure array `VIIOdata` for each trial/recording.
The tables below list the fields with short descriptions.

## Fields kept in `VIIOdata(n)`

| Field | Description |
|-------|-------------|
| `trialName` | Recording identifier, derived from the file name containing date and time information |
| `event_type` | How events were collected (e.g. `detected_events` or `stimWin`) |
| `stim_name` | Name of the stimulation protocol used in the trial |
| `stimInfo` | Structure describing stimulation timing and parameters |
| `traces` | Array of ROI–specific data structures (see table below) |
| `time` | Time vector aligned to the extracted events |
| `fullTime` | Absolute time vector of the entire recording |
| `synchFoldValue` | Relative level of synchronous activity in this trial |

## Fields kept in `VIIOdata(n).traces(m)`

| Field | Description |
|-------|-------------|
| `roi` | ROI label or name |
| `value` | Event traces' value for plotting or analysis |
| `subNuclei` | Sub‑nucleus assignment of the ROI |
| `eventProp` | Structure array of event properties for this ROI (see table below) |
| `fullTrace` | Denoised fluorescence trace |
| `fullTraceDecon` | Deconvolved activity trace |
| `hpStd` | High‑pass filtered trace standard deviation |
| `stimEvent_possi` | Stimulation‑related event probability information |
| `stimTrig` | Vector of stimulation onset times |
| `sponfq` | Frequency of spontaneous events (Hz) |
| `sponInterval` | Mean interval between spontaneous events (s) |
| `cv2` | CV2 of consecutive inter‑event intervals |
| `sponEventNum` | Number of spontaneous events detected |

## Fields kept in `VIIOdata(n).traces(m).eventProp(k)`

| Field | Description |
|-------|-------------|
| `rise_time` | Timestamp of event onset (s) |
| `rise_loc` | Index of event onset in the trace |
| `rise_duration` | Time from onset to peak (s) |
| `peak_time` | Timestamp of event peak (s) |
| `peak_loc` | Index of event peak in the trace |
| `FWHM` | Full width at half maximum of the event |
| `peak_mag_delta` | Event amplitude (dF/F) |
| `peak_delta_norm_hpstd` | Amplitude normalised to ROI `hpStd` |
| `peak_category` | Event category label (e.g. spontaneous or triggered) |
| `stim_tags` | Tags linking the event to specific stimuli |
| `rise_delay` | Delay from stimulus onset to event rise |
| `peak_delay` | Delay from stimulus onset to event peak |
| `sponnorm_peak_mag_delta` | Peak amplitude normalised to spontaneous events |
| `type` | `0` for single/asynchronous events, `1` for cluster/synchronous |
| `spikeClusterGroup` | Cluster identifier when the event is part of a spike cluster |
| `roiSynchRatio` | Fraction of spikes from this ROI occurring in clusters |
| `trialSynchRatio` | Overall cluster event ratio for the trial |
| `clusterSize` | Number of ROIs participating in the cluster |

These field lists match those defined in `functions/Organize/pruneVIIOdataStruct.m` which was used to prune the original data structure.
