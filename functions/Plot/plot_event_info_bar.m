function [data_struct,varargout] = plot_event_info_bar(event_info_struct,par_name,varargin)
	% Bar plot to show event info
	% Input: 
	%	- structure array(s) with field "group" and "event_info"  
	%	- "par_name" is one of the fieldnames of "event_info" 
	%		- rise_duration_mean
	%		- peak_mag_mean
	%		- peak_mag_norm_mean
	%		- peak_slope_mean
	% Output:
	%	- bar info including mean value and standard error
	%	- event interval histogram

	% Defaults
	save_fig = false;
	save_dir = '';
	stat = false; % true if want to run stat analysis
	mmModel = ''; % '': Do not use MM model for analysis. 'LMM': Linear-Mixed-Model. 'GLMM': Generalized-Mixed_Model
	mmGrouop = 'subNuclei'; % group data using this field in the event_info_struct.event_info
	mmGroupVarType = 'categorical';
	mmHierarchicalVars = {'trialName', 'roiName'};
	mmType = 'GLMM';
	mmDistribution = 'gamma';
	mmLink = 'log';

	stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not
	TickAngle = 45;
	EdgeColor = 'none';
	FaceColor = '#4D4D4D';
	FontSize = 12;
	FontWeight = 'bold';

	plotWhere = [];

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    elseif strcmpi('stat', varargin{ii})
	        stat = varargin{ii+1};
	    elseif strcmpi('mmModel', varargin{ii})
	        mmModel = varargin{ii+1};
	    elseif strcmpi('mmGrouop', varargin{ii})
	        mmGrouop = varargin{ii+1};
	    elseif strcmpi('mmGroupVarType', varargin{ii})
	        mmGroupVarType = varargin{ii+1};
	    elseif strcmpi('mmHierarchicalVars', varargin{ii})
	        mmHierarchicalVars = varargin{ii+1};
	    elseif strcmpi('mmDistribution', varargin{ii})
	        mmDistribution = varargin{ii+1};
	    elseif strcmpi('mmLink', varargin{ii})
	        mmLink = varargin{ii+1};
	    elseif strcmpi('stat_fig', varargin{ii})
	        stat_fig = varargin{ii+1};
	    elseif strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1};
	    elseif strcmpi('FontSize', varargin{ii})
	        FontSize = varargin{ii+1};
	    elseif strcmpi('FontWeight', varargin{ii})
	        FontWeight = varargin{ii+1};
	    end
	end

	%% ====================
	% Main content
	if save_fig && isempty(save_dir)
		save_dir = uigetdir;
	end

	group_num = numel(event_info_struct);
	struct_length_size = cell(group_num+1, 1);

	data_struct = struct('group', struct_length_size,...
		'mean_value', struct_length_size, 'ste', struct_length_size);


	% all data
	data_cell = cell(1, group_num);
	data_cell_group = cell(1, group_num);
	for n = 1:group_num
		data_cell{n} = [event_info_struct(n).event_info.(par_name)];
		data_cell_group{n} = cell(size(data_cell{n}));
		data_cell_group{n}(:) = {event_info_struct(n).group}; 
	end
	data_all = [data_cell{:}]; % data_all and data_all_group will be used for annova 
	data_all_group = [data_cell_group{:}];
	data_struct(1).group = 'all';
	data_struct(1).mean_value = mean(data_all, 'omitnan');
	data_struct(1).std = std(data_all, 'omitnan');
	data_struct(1).ste = data_struct(1).std/sqrt(numel(data_all));
	data_struct(1).medianVal = median(data_all, "omitmissing");
	data_struct(1).data.val = data_all;
	data_struct(1).data.group = data_all_group;
	data_struct(1).n_num = numel(data_all);

	
	for n = 1:group_num
		group_data = data_cell{n};
		data_struct(n+1).group = event_info_struct(n).group;

		data_struct(n+1).mean_value = mean(group_data, 'omitnan');
		data_struct(n+1).std = std(group_data, 'omitnan');
		data_struct(n+1).ste = data_struct(n+1).std/sqrt(numel(group_data));
		data_struct(n+1).medianVal = median(group_data, "omitmissing");
		data_struct(n+1).n_num = numel(group_data);

		% data_struct(n+1).data = group_data(:);
	end

	if isempty(plotWhere)
    	f = figure;
    else
    	axes(plotWhere)
    	f = gcf;
    end

	group_names = {data_struct(2:end).group};
	x = [1:1:group_num];
	y = cat(2, data_struct(2:end).mean_value);
	y_error = cat(2, data_struct(2:end).ste);
	n_num_str = num2str([data_struct(2:end).n_num]');

	fb = bar(x, y,...
		'EdgeColor', EdgeColor, 'FaceColor', FaceColor);
	hold on

	yl = ylim;
	yloc = yl(1)+0.05*(yl(2)-yl(1));
	yloc_array = repmat(yloc, 1, numel(x));
	text(x,yloc_array,n_num_str,'vert','bottom','horiz','center', 'Color', 'white');

	ax.XTick = x;
	set(gca, 'box', 'off')
	set(gca, 'FontSize', FontSize)
	set(gca, 'FontWeight', FontWeight)
	xtickangle(TickAngle)
	set(gca, 'XTick', [1:1:group_num]);
	set(gca, 'xticklabel', group_names);
	fe = errorbar(x, y, y_error, 'LineStyle', 'None');
	set(fe,'Color', 'k', 'LineWidth', 2, 'CapSize', 10);

	% title(title_str)

	hold off

	if save_fig
		title_str = replace(title_str, ':', '-');
		fig_path = fullfile(save_dir, title_str);
		savefig(gcf, [fig_path, '.fig']);
		saveas(gcf, [fig_path, '.jpg']);
		saveas(gcf, [fig_path, '.svg']);
	end

	if stat && group_num>1 
		if ~isempty(mmModel)
			structData = [event_info_struct(:).event_info];
			[me,fixedEffectsStats,chiLRT,mmPvalue,multiComparisonResults,statInfo]= mixed_model_analysis(structData,...
				par_name, mmGrouop, mmHierarchicalVars, 'groupVarType', mmGroupVarType,...
				'modelType',mmType,'distribution',mmDistribution,'link',mmLink);
			% statInfo.method = me;
			% statInfo.modelInfoStr = me;
			% statInfo.fixedEffectsStats = fixedEffectsStats;
			% statInfo.chiLRT = chiLRT;
			% statInfo.mmPvalue = mmPvalue;
			% statInfo.multCompare = multiComparisonResults;
		else
			% discard groups which sample size is equal or smaller than 3
			lowSizeGroupIDX = find(cellfun(@(x) numel(x)<=3,data_cell));
			statDataCell = data_cell;
			statGroupName = {event_info_struct.group};
			statDataCell(lowSizeGroupIDX) = [];
			statGroupName(lowSizeGroupIDX) = [];

			% [statInfo] = anova1_with_multiComp(data_all,data_all_group,'displayopt',stat_fig);
			[statInfo,~] = ttestOrANOVA(statDataCell,'groupNames',statGroupName);
		end
	else
		statInfo.anova_p = NaN; % p-value of anova test
		statInfo.tbl = NaN; % anova table
		statInfo.stats = NaN; % structure used to perform  multiple comparison test (multcompare)
		statInfo.multCompare = NaN; % result of multiple comparision test.
		statInfo.multCompare_gnames = NaN; % group names. Use this to decode the first two columns of c
		statInfo.c = NaN; % Results of ANOVA with multiple comparison
	end

	varargout{1} = statInfo;
end