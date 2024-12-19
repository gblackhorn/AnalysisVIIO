function [mmModel, mmHierarchicalVars, mmDistribution, mmLink, organizeStruct] = VIIOinitEventPropAnalysis(groupSettingsType, varargin)
    % Initialize the settings for func 'plotEventPropMultiGroups' to plot and analyze the eventProp 

    % me: The output of mixed-model, such as fitglme
    %   - me = fitglme(...)

    % groupVar: The name of the fixed effect in the formula
    %    - Data in it must be numeric or categorical


    % Parse optional parameters
    p = inputParser;
    addParameter(p, 'separateSPONT', false, @islogical);
    addParameter(p, 'dataDist', 'posSkewed', @ischar); % 'posSkewed', 'norm'
    % addParameter(p, 'figName', 'OriginalData vs fitData', @ischar);

    parse(p, varargin{:});
    separateSPONT = p.Results.separateSPONT;
    dataDist = p.Results.dataDist;
    % figName = p.Results.figName;


    % Mixed model used for the analysis
    mmHierarchicalVars = {'trialName', 'roiName'};
    switch dataDist
        case 'posSkewed'
            mmModel = 'GLMM'; 
            mmDistribution = 'gamma'; % For continuous, positively skewed data
            mmLink = 'log'; % For continuous, positively skewed data
        case 'norm'
            mmModel = 'LMM'; 
            mmDistribution = ''; % LMM works on normal distribution data on default. Dist is not required
            mmLink = ''; % LMM works on normal distribution data on default. Link function is not required
    end

    % Set up the title stem, group key words and the fixed effects for MM analysis
    if ~separateSPONT % When SPONT are from all the neurons: Not separated by the stimulations applied to recordings

        % Compare the properties of events grouped using their stim-related categories and subNuclei location
        if isequal(groupSettingsType, {'peak_category','subNuclei'})
            organizeStruct(1).title = '[SPONT] PO2DAO';
            organizeStruct(1).keepGroups = {'spon'};
            organizeStruct(1).mmFixCat = 'subNuclei';

            organizeStruct(2).title = '[OG-SPONT] PO2DAO';
            organizeStruct(2).keepGroups = {'opto-delay [N-O-5s]'};
            organizeStruct(2).mmFixCat = 'subNuclei';

            organizeStruct(3).title = '[OG-SPONT]2[SPONT] DAO';
            organizeStruct(3).keepGroups = {'opto-delay [N-O-5s]-DAO', 'spon-DAO'};
            organizeStruct(3).mmFixCat = 'peak_category';

            organizeStruct(4).title = '[OG-SPONT]2[SPONT] PO';
            organizeStruct(4).keepGroups = {'opto-delay [N-O-5s]-PO', 'spon-PO'};
            organizeStruct(4).mmFixCat = 'peak_category';

            organizeStruct(5).title = '[N-O-REBOUND] PO2DAO';
            organizeStruct(5).keepGroups = {'rebound [N-O-5s]'};
            organizeStruct(5).mmFixCat = 'subNuclei';

            organizeStruct(6).title = '[N-O-REBOUND]2[SPONT] DAO';
            organizeStruct(6).keepGroups = {'rebound [N-O-5s]-DAO', 'spon-DAO'};
            organizeStruct(6).mmFixCat = 'peak_category';

            organizeStruct(7).title = '[N-O-REBOUND]2[SPONT] PO';
            organizeStruct(7).keepGroups = {'rebound [N-O-5s]-PO', 'spon-PO'};
            organizeStruct(7).mmFixCat = 'peak_category';

            organizeStruct(8).title = '[AP-TRIG] PO2DAO';
            organizeStruct(8).keepGroups = {'trig [AP-0.1s]'};
            organizeStruct(8).mmFixCat = 'subNuclei';

            organizeStruct(9).title = '[AP-TRIG]2[SPONT] DAO';
            organizeStruct(9).keepGroups = {'trig [AP-0.1s]-DAO', 'spon-DAO'};
            organizeStruct(9).mmFixCat = 'peak_category';

            organizeStruct(10).title = '[AP-TRIG]2[SPONT] PO';
            organizeStruct(10).keepGroups = {'trig [AP-0.1s]-PO', 'spon-PO'};
            organizeStruct(10).mmFixCat = 'peak_category';

            organizeStruct(11).title = '[AP-TRIG]2[N-O&AP-TRIG] PO';
            organizeStruct(11).keepGroups = {'trig [AP-0.1s]-PO', 'trig-ap [N-O-5s AP-0.1s]-PO'};
            organizeStruct(11).mmFixCat = 'peak_category';

            organizeStruct(12).title = '[N-O&AP-TRIG]2[SPONT] PO';
            organizeStruct(12).keepGroups = {'trig-ap [N-O-5s AP-0.1s]-PO', 'spon-PO'};
            organizeStruct(12).mmFixCat = 'peak_category';

        % Compare properties of events grouped only using peak_category
        elseif isequal(groupSettingsType, {'peak_category'})
            organizeStruct(1).title = '[OG-SPONT]2[SPONT] ALLsubN';
            organizeStruct(1).keepGroups = {'opto-delay [N-O-5s]', 'spon'};
            organizeStruct(1).mmFixCat = 'peak_category';

            organizeStruct(2).title = '[N-O-REBOUND]2[SPONT] ALLsubN';
            organizeStruct(2).keepGroups = {'rebound [N-O-5s]', 'spon'};
            organizeStruct(2).mmFixCat = 'peak_category';

        % Events were grouped using category, subnuclei location and cluster/single type
        elseif isequal(groupSettingsType, {'peak_category','subNuclei','type'})
            % SPONT 
            organizeStruct(1).title = '[SPONT] cluster2single PO';
            organizeStruct(1).keepGroups = {'spon-PO'};
            organizeStruct(1).mmFixCat = 'type'; % For sync vs async
            organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(2).title = '[SPONT] cluster2single DAO';
            organizeStruct(2).keepGroups = {'spon-DAO'};
            organizeStruct(2).mmFixCat = 'type';
            organizeStruct(2).colorGroup = {'#003264', '#00AAD4'};

            organizeStruct(3).title = '[SPONT] PO2DAO cluster';
            organizeStruct(3).keepGroups = {'spon-PO-cluster', 'spon-DAO-cluster'};
            organizeStruct(3).mmFixCat = 'subNuclei';
            organizeStruct(3).colorGroup = {'#00AAD4', '#FF00CC'};

            organizeStruct(4).title = '[SPONT] PO2DAO single';
            organizeStruct(4).keepGroups = {'spon-PO-single', 'spon-DAO-single'};
            organizeStruct(4).mmFixCat = 'subNuclei';
            organizeStruct(4).colorGroup = {'#003264', '#8C0383'};

            % AP-TRIG: sync vs async
            organizeStruct(5).title = '[AP-TRIG] cluster2single PO';
            organizeStruct(5).keepGroups = {'trig [AP-0.1s]-PO'};
            organizeStruct(5).mmFixCat = 'type';
            organizeStruct(5).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(6).title = '[AP-TRIG] cluster2single DAO';
            organizeStruct(6).keepGroups = {'trig [AP-0.1s]-DAO'};
            organizeStruct(6).mmFixCat = 'type';
            organizeStruct(6).colorGroup = {'#003264', '#00AAD4'};

            organizeStruct(7).title = '[AP-TRIG]2[SPONT] cluster PO';
            organizeStruct(7).keepGroups = {'trig [AP-0.1s]-PO-cluster', 'spon-PO-cluster'};
            organizeStruct(7).mmFixCat = 'peak_category';
            organizeStruct(7).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(8).title = '[AP-TRIG]2[SPONT] single PO';
            organizeStruct(8).keepGroups = {'trig [AP-0.1s]-PO-single', 'spon-PO-single'};
            organizeStruct(8).mmFixCat = 'peak_category';
            organizeStruct(8).colorGroup = {'#003264', '#00AAD4'};

            % N-O&AP-TRIG 
            organizeStruct(9).title = '[N-O&AP-TRIG] cluster2single PO';
            organizeStruct(9).keepGroups = {'trig-ap [N-O-5s AP-0.1s]-PO'};
            organizeStruct(9).mmFixCat = 'type';
            organizeStruct(9).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(10).title = '[N-O&AP-TRIG]2[AP-TRIG] cluster PO';
            organizeStruct(10).keepGroups = {'trig-ap [N-O-5s AP-0.1s]-PO-cluster', 'trig [AP-0.1s]-PO-cluster'};
            organizeStruct(10).mmFixCat = 'peak_category';
            organizeStruct(10).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(11).title = '[N-O&AP-TRIG]2[AP-TRIG] single PO';
            organizeStruct(11).keepGroups = {'trig-ap [N-O-5s AP-0.1s]-PO-single', 'trig [AP-0.1s]-PO-single'};
            organizeStruct(11).mmFixCat = 'peak_category';
            organizeStruct(11).colorGroup = {'#8C0383', '#FF00CC'};


        % Group events using category and cluster/single type
        elseif isequal(groupSettingsType, {'peak_category','type'})
            % OG-SPONT (Combine subN for bigger nNum)
            organizeStruct(1).title = '[OG-SPONT] cluster2single ALLsubN';
            organizeStruct(1).keepGroups = {'opto-delay [N-O-5s]'};
            organizeStruct(1).mmFixCat = 'type';
            organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(2).title = '[OG-SPONT]2[SPONT] cluster ALLsubN';
            organizeStruct(2).keepGroups = {'opto-delay [N-O-5s]-cluster', 'spon-cluster'};
            organizeStruct(2).mmFixCat = 'peak_category';
            organizeStruct(2).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(3).title = '[OG-SPONT]2[SPONT] single ALLsubN';
            organizeStruct(3).keepGroups = {'opto-delay [N-O-5s]-single', 'spon-single'};
            organizeStruct(3).mmFixCat = 'peak_category';
            organizeStruct(3).colorGroup = {'#8C0383', '#FF00CC'};

            % N-O-REBOUND (Combine subN for bigger nNum)
            organizeStruct(4).title = '[N-O-REBOUND] cluster2single ALLsubN';
            organizeStruct(4).keepGroups = {'rebound [N-O-5s]'};
            organizeStruct(4).mmFixCat = 'type';
            organizeStruct(3).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(5).title = '[N-O-REBOUND]2[SPONT] cluster ALLsubN';
            organizeStruct(5).keepGroups = {'rebound [N-O-5s]-cluster', 'spon-cluster'};
            organizeStruct(5).mmFixCat = 'peak_category';
            organizeStruct(5).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(6).title = '[N-O-REBOUND]2[SPONT] single ALLsubN';
            organizeStruct(6).keepGroups = {'rebound [N-O-5s]-single', 'spon-single'};
            organizeStruct(6).mmFixCat = 'peak_category';
            organizeStruct(6).colorGroup = {'#8C0383', '#FF00CC'};
        end

    elseif separateSPONT
        % Compare the properties of events grouped using their stim-related categories and subNuclei location
        if isequal(groupSettingsType, {'peak_category','subNuclei'})
            % Compare stimEvents and SPONT from same ROI groups. 
            organizeStruct(1).title = '[OG-SPONT]2[SPONT] DAO';
            organizeStruct(1).keepGroups = {'spon [N-O-5s]-DAO', 'opto-delay [N-O-5s]-DAO'};
            organizeStruct(1).mmFixCat = 'peak_category';

            organizeStruct(2).title = '[OG-SPONT]2[SPONT] PO';
            organizeStruct(2).keepGroups = {'spon [N-O-5s]-PO', 'opto-delay [N-O-5s]-PO'};
            organizeStruct(2).mmFixCat = 'peak_category';

            organizeStruct(3).title = '[N-O-REBOUND]2[SPONT] DAO';
            organizeStruct(3).keepGroups = {'spon [N-O-5s]-DAO', 'rebound [N-O-5s]-DAO'};
            organizeStruct(3).mmFixCat = 'peak_category';

            organizeStruct(4).title = '[N-O-REBOUND]2[SPONT] PO';
            organizeStruct(4).keepGroups = {'spon [N-O-5s]-PO', 'rebound [N-O-5s]-PO'};
            organizeStruct(4).mmFixCat = 'peak_category';

            organizeStruct(5).title = '[AP-TRIG]2[SPONT] DAO';
            organizeStruct(5).keepGroups = {'spon [AP-0.1s]-DAO', 'trig [AP-0.1s]-DAO'};
            organizeStruct(5).mmFixCat = 'peak_category';

            organizeStruct(6).title = '[AP-TRIG]2[SPONT] PO';
            organizeStruct(6).keepGroups = {'spon [AP-0.1s]-PO', 'trig [AP-0.1s]-PO'};
            organizeStruct(6).mmFixCat = 'peak_category';

            organizeStruct(7).title = '[N-O&AP-TRIG]2[SPONT] PO';
            organizeStruct(7).keepGroups = {'trig-ap [N-O-5s AP-0.1s]-PO', 'spon [N-O-5s AP-0.1s]-PO'};
            organizeStruct(7).mmFixCat = 'peak_category';

        % Compare properties of events grouped only using peak_category
        elseif isequal(groupSettingsType, {'peak_category'})
            % Compare the difference between N-O events and SPONT. Combine the subN to increase nNum
            % Use SPONT from the N-O recordings
            organizeStruct(1).title = '[OG-SPONT]2[SPONT] ALL';
            organizeStruct(1).keepGroups = {'opto-delay [N-O-5s]', 'spon [N-O-5s]'};
            organizeStruct(1).mmFixCat = 'peak_category';

            organizeStruct(2).title = '[N-O-REBOUND]2[SPONT] ALL';
            organizeStruct(2).keepGroups = {'rebound [N-O-5s]', 'spon [N-O-5s]'};
            organizeStruct(2).mmFixCat = 'peak_category';

        % Events were grouped using category, subnuclei location and cluster/single type
        elseif isequal(groupSettingsType, {'peak_category','subNuclei','type'})
            % AP-TRIG
            organizeStruct(1).title = '[AP-TRIG]2[SPONT] cluster PO';
            organizeStruct(1).keepGroups = {'trig [AP-0.1s]-PO-cluster', 'spon [AP-0.1s]-PO-cluster'};
            organizeStruct(1).mmFixCat = 'peak_category';
            organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(2).title = '[AP-TRIG]2[SPONT] single PO';
            organizeStruct(2).keepGroups = {'trig [AP-0.1s]-PO-single', 'spon [AP-0.1s]-PO-single'};
            organizeStruct(2).mmFixCat = 'peak_category';
            organizeStruct(2).colorGroup = {'#003264', '#00AAD4'};

            % N-O&AP-TRIG
            organizeStruct(3).title = '[N-O&AP-TRIG]2[SPONT] cluster PO';
            organizeStruct(3).keepGroups = {'trig-ap [N-O-5s AP-0.1s]-PO-cluster', 'spon [N-O-5s AP-0.1s]-PO-cluster'};
            organizeStruct(3).mmFixCat = 'peak_category';
            organizeStruct(3).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(4).title = '[N-O&AP-TRIG]2[SPONT] single PO';
            organizeStruct(4).keepGroups = {'trig-ap [N-O-5s AP-0.1s]-PO-single', 'spon [N-O-5s AP-0.1s]-PO-single'};
            organizeStruct(4).mmFixCat = 'peak_category';
            organizeStruct(4).colorGroup = {'#8C0383', '#FF00CC'};

            % % OG-SPONT
            % organizeStruct(5).title = '[OG-SPONT]2[SPONT] cluster PO';
            % organizeStruct(5).keepGroups = {'opto-delay [N-O-5s]-PO-cluster', 'spon [N-O-5s]-PO-cluster'};
            % organizeStruct(5).mmFixCat = 'type';
            % organizeStruct(5).colorGroup = {'#8C0383', '#FF00CC'};

            % organizeStruct(6).title = '[OG-SPONT]2[SPONT] single PO';
            % organizeStruct(6).keepGroups = {'opto-delay [N-O-5s]-PO-single', 'spon [N-O-5s]-PO-single'};
            % organizeStruct(6).mmFixCat = 'type';
            % organizeStruct(6).colorGroup = {'#8C0383', '#FF00CC'};

            % organizeStruct(7).title = '[OG-SPONT]2[SPONT] cluster DAO';
            % organizeStruct(7).keepGroups = {'opto-delay [N-O-5s]-DAO-cluster', 'spon [N-O-5s]-DAO-cluster'};
            % organizeStruct(7).mmFixCat = 'type';
            % organizeStruct(7).colorGroup = {'#8C0383', '#FF00CC'};

            % organizeStruct(8).title = '[OG-SPONT]2[SPONT] single DAO';
            % organizeStruct(8).keepGroups = {'opto-delay [N-O-5s]-DAO-single', 'spon [N-O-5s]-DAO-single'};
            % organizeStruct(8).mmFixCat = 'type';
            % organizeStruct(8).colorGroup = {'#8C0383', '#FF00CC'};

        % Group events using category and cluster/single type
        elseif isequal(groupSettingsType, {'peak_category','type'})
            % OG-SPONT (Combine subN for bigger nNum)
            organizeStruct(1).title = '[OG-SPONT]2[SPONT] cluster ALLsubN';
            organizeStruct(1).keepGroups = {'opto-delay [N-O-5s]-cluster', 'spon [N-O-5s]-cluster'};
            organizeStruct(1).mmFixCat = 'peak_category';
            organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(2).title = '[OG-SPONT]2[SPONT] single ALLsubN';
            organizeStruct(2).keepGroups = {'opto-delay [N-O-5s]-single', 'spon [N-O-5s]-single'};
            organizeStruct(2).mmFixCat = 'peak_category';
            organizeStruct(2).colorGroup = {'#8C0383', '#FF00CC'};

            % N-O-REBOUND (Combine subN for bigger nNum)
            organizeStruct(3).title = '[N-O-REBOUND]2[SPONT] cluster ALLsubN';
            organizeStruct(3).keepGroups = {'rebound [N-O-5s]-cluster', 'spon [N-O-5s]-cluster'};
            organizeStruct(3).mmFixCat = 'peak_category';
            organizeStruct(3).colorGroup = {'#8C0383', '#FF00CC'};

            organizeStruct(4).title = '[N-O-REBOUND]2[SPONT] single ALLsubN';
            organizeStruct(4).keepGroups = {'rebound [N-O-5s]-single', 'spon [N-O-5s]-single'};
            organizeStruct(4).mmFixCat = 'peak_category';
            organizeStruct(4).colorGroup = {'#8C0383', '#FF00CC'};
        end
    end
end
