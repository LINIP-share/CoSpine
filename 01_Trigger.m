%% =========================================================================
%  Script to generate trigger sequences from PMU (pulse and respiration) data
%  and corresponding DICOM files for fMRI analyses, and then plot the results.
%  Author:  Zhaoxing Wei, Yazhuo Kong, Jiyuan Wang and Guangyue Tian
%  Date:  2019.7 version 1.0; 2025.1.30 version 2.0. 
%
%  This script:
%    1) Prompts the user to select a main directory containing subject subfolders.
%    2) Iterates through each subject subfolder to process data files:
%         - Finds DICOM (.IMA), pulse (.puls), and respiration (.resp) files.
%         - Extracts start/end times from PMU files and the DICOM file.
%         - Aligns pulse and respiration data and inserts triggers at each TR.
%         - Saves the trigger data into a text file (trigger.txt).
%    3) After processing all subjects, it loads each trigger file, plots the data,
%       and saves the plot as a PNG image in the main directory.
%
%  Adjustable parameters:
%    TR                - Repetition time in milliseconds.
%    samplingFrequency - Sampling frequency for PMU data (default = 400 Hz).
%    volumeFile        - Name of the text file storing total number of volumes.
%
%  Tested in MATLAB R201x.
%  Modify as needed for your specific dataset.
%% =========================================================================

%% -----------------------
%  User-defined parameters
%% -----------------------
TR = ;                % Repetition Time (in milliseconds)
samplingFrequency = ;  % Sampling frequency for PMU (samples per second)
volumeFile = ;    % File containing the total number of volumes

% Derived parameter: data points per TR.
pointsPerTR = TR / (1000 / samplingFrequency);  
% Explanation:
%   - 1000/samplingFrequency gives the duration (in ms) of one sample.
%   - pointsPerTR indicates how many samples are within one TR.

%% =========================================================================
%  Select the main directory containing subject subfolders
%% =========================================================================
mainPath = uigetdir;
if mainPath == 0
    error('No folder was selected. Script terminated.');
end

% Change to main directory and list subject folders
cd(mainPath);
subjects = dir(mainPath);
% Remove the '.' and '..' entries (if they are the first two entries)
subjects(1:2) = [];

%% =========================================================================
%  Process each subject folder to generate trigger file
%% =========================================================================
for subjIdx = 1:length(subjects)
    
    % Move into the subject’s folder
    subjPath = fullfile(mainPath, subjects(subjIdx).name);
    cd(subjPath);

    %% -------------------------------------------------------------
    %  Locate DICOM (.IMA), pulse (.puls), and respiration (.resp) files
    %% -------------------------------------------------------------
    fileFolder = pwd;
    
    % Find DICOM file(s)
    imaFiles = dir(fullfile(fileFolder, '*.IMA'));
    if isempty(imaFiles)
        warning('No .IMA file found in %s. Skipping this folder.', fileFolder);
        cd(mainPath);
        continue;
    end
    dicomName = imaFiles(1).name;

    % Find pulse file(s)
    pulsFiles = dir(fullfile(fileFolder, '*.puls'));
    if isempty(pulsFiles)
        warning('No .puls file found in %s. Skipping this folder.', fileFolder);
        cd(mainPath);
        continue;
    end
    pulsName = pulsFiles(1).name;

    % Find respiration file(s)
    respFiles = dir(fullfile(fileFolder, '*.resp'));
    if isempty(respFiles)
        warning('No .resp file found in %s. Skipping this folder.', fileFolder);
        cd(mainPath);
        continue;
    end
    respName = respFiles(1).name;

    %% -------------------------------------------------------------
    %  Read DICOM acquisition time (in milliseconds)
    %% -------------------------------------------------------------
    info = dicominfo(dicomName);
    acquisition = getfield(info, 'AcquisitionTime'); 
    % Format assumed: HHMMSS.SSS (e.g., '134512.125')
    
    acqHour   = str2double(acquisition(1:2));
    acqMinute = str2double(acquisition(3:4));
    acqSecond = str2double(acquisition(5:end));
    
    % Convert DICOM acquisition time to milliseconds from 00:00:00
    acqTimeMs = (acqHour * 3600 + acqMinute * 60 + acqSecond) * 1000;

    %% -------------------------------------------------------------
    %  Extract numeric data from the first line of the .puls file
    %% -------------------------------------------------------------
    importPuls = importdata(pulsName);
    firstRowPulsStr = importPuls.textdata{1,1}; 
    puls1num = [];
    tempStr = '';
    for kk = 1:length(firstRowPulsStr)
        if firstRowPulsStr(kk) ~= ' '
            tempStr = [tempStr, firstRowPulsStr(kk)];
        else
            if ~isempty(tempStr)
                puls1num = [puls1num, str2double(tempStr)];
                tempStr = '';
            end
        end
    end
    if ~isempty(tempStr)
        puls1num = [puls1num, str2double(tempStr)];
    end

    %% -------------------------------------------------------------
    %  Extract numeric data from the first line of the .resp file
    %% -------------------------------------------------------------
    importResp = importdata(respName);
    firstRowRespStr = importResp.textdata{1,1};
    resp1num = [];
    tempStr = '';
    for kk = 1:length(firstRowRespStr)
        if firstRowRespStr(kk) ~= ' '
            tempStr = [tempStr, firstRowRespStr(kk)];
        else
            if ~isempty(tempStr)
                resp1num = [resp1num, str2double(tempStr)];
                tempStr = '';
            end
        end
    end
    if ~isempty(tempStr)
        resp1num = [resp1num, str2double(tempStr)];
    end

    %% -------------------------------------------------------------
    %  Remove unwanted records from pulse data
    %% -------------------------------------------------------------
    puls_num = puls1num;
    if length(puls_num) >= 7
        puls_num(1:7) = [];
    end
    puls_num(puls_num == 5000) = [];
    puls_num(puls_num == 5003) = [];
    puls_num(puls_num == 6000) = [];
    
    idx5002 = find(puls_num == 5002, 1);
    idx6002 = find(puls_num == 6002, 1);
    if ~isempty(idx5002) && ~isempty(idx6002) && (idx6002 > idx5002)
        puls_num(idx5002:idx6002) = [];
    end

    %% -------------------------------------------------------------
    %  Remove unwanted records from respiration data
    %% -------------------------------------------------------------
    resp_num = resp1num;
    if length(resp_num) >= 7
        resp_num(1:7) = [];
    end
    resp_num(resp_num == 5000) = [];
    resp_num(resp_num == 5003) = [];
    resp_num(resp_num == 6000) = [];
    
    idx5002 = find(resp_num == 5002, 1);
    idx6002 = find(resp_num == 6002, 1);
    if ~isempty(idx5002) && ~isempty(idx6002) && (idx6002 > idx5002)
        resp_num(idx5002:idx6002) = [];
    end

    %% -------------------------------------------------------------
    %  Get pulse start and stop times (in ms)
    %% -------------------------------------------------------------
    pulsStartStr = importPuls.textdata{13,1};
    pulsStopStr  = importPuls.textdata{14,1};
    pulsStart    = str2double(regexp(pulsStartStr, '\d+', 'match'));
    pulsStop     = str2double(regexp(pulsStopStr,  '\d+', 'match'));

    %% -------------------------------------------------------------
    %  Get respiration start and stop times (in ms)
    %% -------------------------------------------------------------
    respStartStr = importResp.textdata{13,1};
    respStopStr  = importResp.textdata{14,1};
    respStart    = str2double(regexp(respStartStr, '\d+', 'match'));
    respStop     = str2double(regexp(respStopStr,  '\d+', 'match'));

    %% -------------------------------------------------------------
    %  Align the start of pulse and respiration recordings
    %% -------------------------------------------------------------
    st = pulsStart - respStart;   
    absSt = round(abs(st) / (1000 / samplingFrequency));
    if st > 0
        % Respiration started first; remove extra initial points from resp data
        if absSt < length(resp_num)
            resp_num(1:absSt) = [];
        else
            warning('absSt >= length(resp_num). Check data alignment.');
        end
        inter = acqTimeMs - pulsStart; % Gap between scan start and pulse start
    else
        % Pulse started first; remove extra initial points from pulse data
        if absSt < length(puls_num)
            puls_num(1:absSt) = [];
        else
            warning('absSt >= length(puls_num). Check data alignment.');
        end
        inter = acqTimeMs - respStart; % Gap between scan start and respiration start
    end
    inter = round(inter / (1000 / samplingFrequency)); % Convert gap to data points

    %% -------------------------------------------------------------
    %  Align the end of the recordings
    %% -------------------------------------------------------------
    stopVs = pulsStop - respStop;
    if stopVs > 0
        if length(resp_num) < length(puls_num)
            puls_num((length(resp_num)+1):end) = [];
        end
    else
        if length(puls_num) < length(resp_num)
            resp_num((length(puls_num)+1):end) = [];
        end
    end

    %% -------------------------------------------------------------
    %  Determine the number of triggers based on volumeFile (e.g., nt.txt)
    %% -------------------------------------------------------------
    if ~exist(volumeFile, 'file')
        warning('%s not found. No triggers will be inserted.', volumeFile);
        T = 0;
    else
        totalVolumes = importdata(volumeFile);
        T = totalVolumes - 1;  % T = volume count - 1
    end

    %% -------------------------------------------------------------
    %  Create the trigger array
    %% -------------------------------------------------------------
    if length(puls_num) ~= length(resp_num)
        warning('Pulse and respiration data lengths differ for %s. Using the shorter length.', subjPath);
    end
    dataLength = min(length(puls_num), length(resp_num));
    triggerpoint = zeros(1, dataLength);
    for x = 0:T
        pos = inter + 1 + round(pointsPerTR * x);
        if pos > 0 && pos <= dataLength
            triggerpoint(pos) = 5000; 
        end
    end
    % Combine the data into a single matrix: [pulse, respiration, trigger]
    triggerMatrix = [puls_num(1:dataLength); resp_num(1:dataLength); triggerpoint(1:dataLength)]';
                 
    %% -------------------------------------------------------------
    %  Write the trigger matrix to trigger.txt
    %% -------------------------------------------------------------
    txtFileID = fopen('trigger.txt','w');
    if txtFileID == -1
        error('Cannot create or open trigger.txt in %s', subjPath);
    end
    [numRows, numCols] = size(triggerMatrix);
    for row = 1:numRows
        for col = 1:numCols
            if col == numCols
                fprintf(txtFileID, '%g\n', triggerMatrix(row,col));
            else
                fprintf(txtFileID, '%g\t', triggerMatrix(row,col));
            end
        end
    end
    fclose(txtFileID);
    
    % Optional: Use dlmwrite for a simpler file write:
    % dlmwrite('trigger.txt', triggerMatrix, 'delimiter', '\t', 'newline','pc');

    % Return to the main directory before processing the next subject
    cd(mainPath);
end

%% =========================================================================
%  Plotting: Load each subject's trigger.txt, plot the trigger data,
%  and save the plot as a PNG image.
%% =========================================================================
% Create a cell array of subject names
SubName = cell(1, length(subjects));
for i = 1:length(subjects)
    SubName{i} = subjects(i).name;
end

for i = 1:length(subjects)
    triggerPath = fullfile(mainPath, SubName{i}, 'trigger.txt');
    if exist(triggerPath, 'file')
        % Load the trigger data (assumes the file is a numeric matrix)
        trigger = load(triggerPath);
        
        % Plot the trigger data
        figure;
        plot(trigger);
        title(['Trigger Data for Subject: ', SubName{i}]);
        xlabel('Sample Index');
        ylabel('Trigger Value');
        
        % Save the figure as a PNG in the main directory
        saveas(gcf, fullfile(mainPath, [SubName{i}, '.png']));
        close(gcf);
    else
        warning('trigger.txt not found for subject: %s', SubName{i});
    end
end

% End of script