function compareAnalysisUsingdiffSetting(figFolder, saveFolder, varargin)
    % Compare plots and Latex stat table generated by the same process using different settings.

    % Figures and Latex text file with the same name in 'folder1' and 'folder2' will be combined
    % into a new figure and saved in saveFolder using the same name. Only figures containing a
    % specified 'keyword' in their filename will be combined if the 'keyword' parameter is
    % provided, and files containing and 'ignoreKeyword' in their filename will be excluded.

    % Inputs:
        % figFolder (required): Path to the folder where the original figures and Latex files are stored.
        % saveFolder (required): Path to the folder where the combined figures Latex files will be saved.
        % label1 (optional): Label for the figures and files from folder1. Defaults to 'type1'.
        % label2 (optional): Label for the figures from folder2. Defaults to 'type2'.
        % figExt (optional): File extension for the figure files. Defaults to 'jpg'.
        % tableExt (optional): File extension for the LaTeX files. Defaults to 'tex'.
        % keywordFig (optional): Keyword to filter the figures to be combined. Only figures containing this keyword in their name will be combined.
        % ignoreKeywordFig (optional): Keyword to ignore figures. Figures containing this keyword in their name will be excluded from combining.
        % keywordText (optional): Keyword to filter the text files to be combined. Only files containing this keyword in their name will be combined.
        % ignoreKeywordText (optional): Keyword to ignore text files. Files containing this keyword in their name will be excluded from combining.


    % Outputs:
        % None (the function saves the combined figure files directly in the specified saveFolder).

    % Create an input parser object
    parser = inputParser;

    % Define the required inputs
    addRequired(parser, 'figFolder', @ischar);  % Folder to load original figures
    addRequired(parser, 'saveFolder', @ischar); % Folder to save combined figures

    % Define the optional inputs
    addParameter(parser, 'label1', 'type1', @(x) ischar(x) || isstring(x));  % Label for folder1 figures
    addParameter(parser, 'label2', 'type2', @(x) ischar(x) || isstring(x));  % Label for folder2 figures
    addParameter(parser, 'figExt', 'jpg', @ischar);                         % Figure file extension
    addParameter(parser, 'textExt', 'tex', @ischar);                       % Latex file extension
    addParameter(parser, 'keywordFig', '', @ischar);                           % Keyword to filter figures by name
    addParameter(parser, 'ignoreKeywordFig', '', @ischar);                     % Keyword to ignore figures by name
    addParameter(parser, 'keywordText', '', @ischar);                           % Keyword to filter figures by name
    addParameter(parser, 'ignoreKeywordText', '', @ischar);                     % Keyword to ignore figures by name

    % Parse the inputs
    parse(parser, figFolder, saveFolder, varargin{:});

    % Convert the labels to char arrays to avoid inputParser issues
    label1 = char(parser.Results.label1);
    label2 = char(parser.Results.label2);
    figExt = char(parser.Results.figExt);
    textExt = char(parser.Results.textExt);
    keywordFig = char(parser.Results.keywordFig);
    ignoreKeywordFig = char(parser.Results.ignoreKeywordFig);
    keywordText = char(parser.Results.keywordText);
    ignoreKeywordText = char(parser.Results.ignoreKeywordText);

    % Get the parsed inputs
    figFolder = parser.Results.figFolder;
    saveFolder = parser.Results.saveFolder;

    % Open a GUI to choose folder1 and get the list of figure files with the extension specified by 'figExt'
    folder1 = uigetdir(figFolder, 'Select Folder 1');
    if folder1 == 0
        error('No folder selected for Folder 1.');
    end

    % Open a GUI to choose folder2 and get the list of figure files with the extension specified by 'figExt'
    folder2 = uigetdir(figFolder, 'Select Folder 2');
    if folder2 == 0
        error('No folder selected for Folder 2.');
    end

    % Open a GUI to choose a folder to save the combined figure. Use savePath as a default
    saveFolder = uigetdir(saveFolder, 'Select a folder to save combined figures');
    if saveFolder == 0
        error('No folder selected for saving.');
    end


    % Combine figures from two folders and save them in a new folder
    comparePlotsUsingdiffSetting(folder1, folder2, saveFolder,...
        'label1', label1, 'label2', label2, 'figExt', figExt,...
        'keyword', keywordFig, 'ignoreKeyword', ignoreKeywordFig);


    % Combine figures from two folders and save them in a new folder
    compareLatexTablesUsingDiffSetting(folder1, folder2, saveFolder,...
        'label1', label1, 'label2', label2, 'textExt', textExt,...
        'keyword', keywordText, 'ignoreKeyword', ignoreKeywordText);
end